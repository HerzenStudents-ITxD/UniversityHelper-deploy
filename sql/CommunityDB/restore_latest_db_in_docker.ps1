#!/usr/bin/env pwsh

# PowerShell Core script for restoring the latest backup of CommunityDB
Write-Host "Starting the script to restore the latest backup for CommunityDB..."

# Get the script and parent directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentDir = Split-Path -Parent $scriptDir
$envFile = Join-Path -Path $parentDir -ChildPath ".env"
$backupDir = Join-Path -Path $parentDir -ChildPath "backups"

# Check if .env file exists
if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at path ${envFile}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Load environment variables from .env
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Configuration from .env
$container = $env:DB_CONTAINER
$password = $env:SA_PASSWORD
$database = "CommunityDB"

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

# Check if backup directory exists
if (-not (Test-Path $backupDir)) {
    Write-Error "ERROR: Backup directory not found at ${backupDir}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Find the latest backup file for CommunityDB
Write-Host "Searching for the latest CommunityDB backup..."
$backupFiles = Get-ChildItem -Path $backupDir -Filter "CommunityDB_*.bak" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $backupFiles) {
    Write-Error "ERROR: No backup files found for CommunityDB in ${backupDir}"
    Read-Host "Press Enter to continue..."
    exit 1
}

$backupFile = $backupFiles.FullName
$backupFileName = $backupFiles.Name
Write-Host "Found latest backup: ${backupFile}"

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

# Copy backup file to container
$containerBackupPath = "/var/opt/mssql/backups/${backupFileName}"
Write-Host "Copying backup file to container..."
docker cp $backupFile "${container}:${containerBackupPath}"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to copy backup file to container"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Set database to single-user mode to allow restore
Write-Host "Setting ${database} to single-user mode..."
$singleUserQuery = @"
IF EXISTS (SELECT * FROM sys.databases WHERE name = '${database}')
BEGIN
    ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
END
"@
docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$singleUserQuery"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to set ${database} to single-user mode"
    docker exec $container rm -f $containerBackupPath | Out-Null
    Read-Host "Press Enter to continue..."
    exit 1
}

# Restore the database
Write-Host "Restoring database ${database} from ${backupFileName}..."
$restoreQuery = @"
RESTORE DATABASE [${database}] 
FROM DISK = N'${containerBackupPath}' 
WITH REPLACE, RECOVERY, STATS = 10
"@
docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$restoreQuery"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to restore database ${database}"
    docker exec $container rm -f $containerBackupPath | Out-Null
    Read-Host "Press Enter to continue..."
    exit 1
}

# Set database back to multi-user mode
Write-Host "Setting ${database} back to multi-user mode..."
$multiUserQuery = @"
IF EXISTS (SELECT * FROM sys.databases WHERE name = '${database}')
BEGIN
    ALTER DATABASE [${database}] SET MULTI_USER
END
"@
docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$multiUserQuery"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to set ${database} to multi-user mode"
    docker exec $container rm -f $containerBackupPath | Out-Null
    Read-Host "Press Enter to continue..."
    exit 1
}

# Clean up backup file from container
Write-Host "Cleaning up backup file from container..."
docker exec $container rm -f $containerBackupPath | Out-Null

Write-Host "Successfully restored ${database} from ${backupFileName}! ✅"
Write-Host "Backup file: ${backupFile}"
Read-Host "Press Enter to continue..."
exit 0