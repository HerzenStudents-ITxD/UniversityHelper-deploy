# clean_all_databases.ps1
Write-Host "Launching all database clean script..."

# Variables
$USER_DB_PASSWORD = "User_1234"
$CONTAINER = "sqlserver_db"

# Get the directory where this script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Cleaning all databases..."

# Wait for SQL Server to be ready
Write-Host "Waiting for SQL Server to be ready..."
while (-not (docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -Q "SELECT 1" 2>$null)) {
    Write-Host "SQL Server is not ready yet..."
    Start-Sleep -Seconds 5
}
Write-Host "SQL Server is ready!"

# Execute clean scripts for each database
$cleanScripts = @(
    "UserDB\00_clean_UserDB.sql",
    "CommunityDB\00_clean_CommunityDB.sql",
    "RightsDB\00_clean_RightsDB.sql",
    "FeedbackDB\00_clean_FeedbackDB.sql",
    "MapDB\00_clean_MapDB.sql"
)

foreach ($script in $cleanScripts) {
    Execute-CleanScript -RelativePath $script
}

Write-Host "All databases cleaning completed! ✅"
Read-Host "Press Enter to exit"
exit 0

function Execute-CleanScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $SQL_SCRIPT = Join-Path $SCRIPT_DIR $RelativePath

    if (-not (Test-Path $SQL_SCRIPT)) {
        Write-Error "Error: Clean script not found at: $SQL_SCRIPT"
        exit 1
    }

    Write-Host "Processing $RelativePath..."

    docker cp $SQL_SCRIPT "$CONTAINER:/temp_clean_script.sql"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to copy SQL script to container"
        exit 1
    }

    docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -i /temp_clean_script.sql
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to execute clean script"
        exit 1
    }

    docker exec $CONTAINER rm -f /temp_clean_script.sql | Out-Null
}
