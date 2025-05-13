#!/usr/bin/env pwsh

# PowerShell Core script for restoring all databases from their latest backups
Write-Host "Starting the script to restore all databases from their latest backups..."

# Load environment variables from the .env file in the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path -Path $scriptDir -ChildPath ".env"
$backupDir = Join-Path -Path $scriptDir -ChildPath "backups"

# Check if .env file exists
if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at path ${envFile}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Load environment variables
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Configuration from .env
$container = $env:DB_CONTAINER
$password = $env:SA_PASSWORD

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

# Get list of all backup files grouped by database
Write-Host "Searching for database backups..."
$backupGroups = Get-ChildItem -Path $backupDir -Filter "*.bak" | 
    Group-Object { ($_.Name -split "_")[0] } |
    ForEach-Object {
        $latestBackup = $_.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        [PSCustomObject]@{
            Database = $_.Name
            BackupFile = $latestBackup.FullName
            BackupFileName = $latestBackup.Name
        }
    }

if (-not $backupGroups) {
    Write-Error "ERROR: No backup files found in ${backupDir}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Restore each database
foreach ($backup in $backupGroups) {
    $db = $backup.Database
    $backupFile = $backup.BackupFile
    $backupFileName = $backup.BackupFileName
    $containerBackupPath = "/var/opt/mssql/backups/${backupFileName}"

    Write-Host "`nProcessing database ${db}..."
    Write-Host "Using backup file: ${backupFile}"

    # Copy backup file to container
    Write-Host "Copying backup file to container..."
    docker cp $backupFile "${container}:${containerBackupPath}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to copy backup file to container for database ${db}"
        continue
    }

    # Set database to single-user mode to allow restore
    Write-Host "Setting ${db} to single-user mode..."
    $singleUserQuery = @"
IF EXISTS (SELECT * FROM sys.databases WHERE name = '${db}')
BEGIN
    ALTER DATABASE [${db}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
END
"@
    docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$singleUserQuery"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to set ${db} to single-user mode"
        docker exec $container rm -f $containerBackupPath | Out-Null
        continue
    }

    # Restore the database
    Write-Host "Restoring database ${db}..."
    $restoreQuery = @"
RESTORE DATABASE [${db}] 
FROM DISK = N'${containerBackupPath}' 
WITH REPLACE, RECOVERY, STATS = 10
"@
    docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$restoreQuery"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to restore database ${db}"
        docker exec $container rm -f $containerBackupPath | Out-Null
        continue
    }

    # Set database back to multi-user mode
    Write-Host "Setting ${db} back to multi-user mode..."
    $multiUserQuery = @"
IF EXISTS (SELECT * FROM sys.databases WHERE name = '${db}')
BEGIN
    ALTER DATABASE [${db}] SET MULTI_USER
END
"@
    docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$multiUserQuery"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to set ${db} to multi-user mode"
        docker exec $container rm -f $containerBackupPath | Out-Null
        continue
    }

    # Clean up backup file from container
    Write-Host "Cleaning up backup file from container..."
    docker exec $container rm -f $containerBackupPath | Out-Null

    Write-Host "Successfully restored ${db} from ${backupFileName} ✅"
}

Write-Host "`nAll databases restoration completed! ✅"
Write-Host "Restored databases: $($backupGroups.Database -join ', ')"
Read-Host "Press Enter to continue..."
exit 0