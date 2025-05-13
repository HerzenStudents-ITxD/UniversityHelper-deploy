#!/usr/bin/env pwsh

# PowerShell Core script for backing up all databases
Write-Host "Starting the script to backup all databases..."

# Load environment variables from the .env file in the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path -Path $scriptDir -ChildPath ".env"

if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at path ${envFile}"
    Read-Host "Press Enter to continue..."
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Configuration from .env
$container = $env:DB_CONTAINER
$password = $env:SA_PASSWORD
$backupDir = Join-Path -Path $scriptDir -ChildPath "backups"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Validate environment variables
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ERROR: Environment variable ${var} is not set."
        Read-Host "Press Enter to continue..."
        exit 1
    }
}

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: Docker is not installed or missing from PATH."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Check if the container is running
Write-Host "Checking if container ${container} is running..."
$containerStatus = docker inspect $container 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Container ${container} is not running."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "Created backup directory at ${backupDir}"
}

# Wait for SQL Server to be ready
Write-Host "Waiting for SQL Server to be ready..."
$maxAttempts = 12
$attempt = 1
while ($attempt -le $maxAttempts) {
    $result = docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "SELECT 1" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SQL Server is ready!"
        break
    }
    Write-Host "SQL Server is not ready yet... (Attempt ${attempt}/${maxAttempts})"
    Start-Sleep -Seconds 5
    $attempt++
}
if ($attempt -gt $maxAttempts) {
    Write-Error "ERROR: SQL Server did not become ready after ${maxAttempts} attempts."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Get list of all databases (excluding system databases)
Write-Host "Getting list of databases..."
$query = @"
SELECT name 
FROM master.sys.databases 
WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')
"@

$databases = docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$query" -h-1 -W -s"|" | Where-Object { $_ -notmatch "rows affected" -and $_.Trim() }
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to get list of databases"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Backup each database
foreach ($db in $databases) {
    $db = $db.Trim()
    if ([string]::IsNullOrEmpty($db)) { continue }

    $backupFileName = "${db}_${timestamp}.bak"
    $backupPath = "/var/opt/mssql/backups/${backupFileName}"
    $localBackupPath = Join-Path -Path $backupDir -ChildPath $backupFileName

    Write-Host "Backing up database ${db}..."

    # Execute backup command
    $backupQuery = @"
BACKUP DATABASE [${db}] 
TO DISK = N'${backupPath}' 
WITH NOFORMAT, INIT, NAME = N'${db}-Full Database Backup', 
SKIP, NOREWIND, NOUNLOAD, STATS = 10
"@

    docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$backupQuery"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to backup database ${db}"
        continue
    }

    # Copy backup file from container to host
    docker cp "${container}:${backupPath}" $localBackupPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to copy backup file for database ${db}"
        continue
    }

    # Remove backup file from container to save space
    docker exec $container rm -f $backupPath | Out-Null

    Write-Host "Successfully backed up ${db} to ${localBackupPath}"
}

Write-Host "All databases backup completed! ✅"
Write-Host "Backups saved to: ${backupDir}"
Read-Host "Press Enter to continue..."
exit 0