#!/usr/bin/env pwsh

# UserDB checker script (PowerShell version)

# Read .env file located one directory above
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path (Split-Path -Parent $scriptDir) ".env"

Write-Host "Checking .env file at: $envFile"

if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at path $envFile"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Parse .env file
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Set variables from .env with defaults
$USER_DB_PASSWORD = $envVars['SA_PASSWORD'] ?? 'User_1234'
$CONTAINER = $envVars['DB_CONTAINER'] ?? 'sqlserver_db'
$DATABASE = $envVars['USERDB_DB_NAME'] ?? 'UserDB'

Write-Host "Checking UserDB tables..."

# Проверка существования базы данных
Write-Host "`nChecking if database exists..."
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -Q "IF DB_ID('$DATABASE') IS NOT NULL SELECT 'Database exists' AS message ELSE SELECT 'Database does not exist' AS message"

# Проверка существования таблиц
Write-Host "`nChecking tables existence..."
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q @"
SELECT 
    t.name AS table_name,
    CASE WHEN t.name IS NOT NULL THEN 'Exists' ELSE 'Does not exist' END AS status
FROM 
    sys.tables t
WHERE 
    t.name IN ('Users', 'UsersCredentials', 'UsersAvatars', 'UsersAdditions', 'UsersCommunications', 'PendingUsers')
"@

# Проверка содержимого таблиц
function Check-Table {
    param($TableName)
    Write-Host "`n$TableName`:"
    docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q @"
IF EXISTS (SELECT * FROM sys.tables WHERE name = '$TableName')
    SELECT * FROM $TableName
ELSE
    SELECT 'Table $TableName does not exist' AS message
"@
}

Check-Table "Users"
Check-Table "UsersCredentials"
Check-Table "UsersAvatars"
Check-Table "UsersAdditions"
Check-Table "UsersCommunications"
Check-Table "PendingUsers"

Write-Host "`nDone ✅"
Read-Host "Press Enter to continue"
exit 0