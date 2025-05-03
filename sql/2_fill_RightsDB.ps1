Write-Host "Launching RightsDB database fill script..."

function ExitWithError($message) {
    Write-Error $message
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Загрузка переменных из .env в той же папке, где скрипт ---
Write-Host "[DEBUG] Loading environment variables from .env file..."
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$envPath = Join-Path $scriptDir ".env"
if (-not (Test-Path $envPath)) {
    ExitWithError "[ERROR] .env file not found at $envPath"
}

Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
        $key = $matches[1]
        $value = $matches[2] -replace '^"|"$', ''
        Set-Variable -Name $key -Value $value -Scope Script
    }
}

# --- Переменные ---
$CONTAINER = $DB_CONTAINER
$DATABASE = $RIGHTSDB_DB_NAME
$RIGHTS_DB_PASSWORD = $SA_PASSWORD
$ADMIN_USER_ID = $RIGHTSDB_ADMIN_USER_ID
$ADMIN_ROLE_ID = $RIGHTSDB_ADMIN_ROLE_ID

# --- Проверка контейнера ---
Write-Host "Checking if container $CONTAINER is running..."
$containerInfo = docker inspect $CONTAINER 2>$null
if (-not $containerInfo) {
    ExitWithError "ERROR: Container $CONTAINER is not running."
}

# --- Проверка существующих таблиц ---
Write-Host "Checking existing $DATABASE tables..."
$sqlQuery = @"
USE $DATABASE;
SELECT 'Roles' AS TableName, COUNT(*) AS Count FROM sys.tables WHERE name = 'Roles'
UNION ALL
SELECT 'RolesLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RolesLocalizations'
UNION ALL
SELECT 'Rights', COUNT(*) FROM sys.tables WHERE name = 'Rights'
UNION ALL
SELECT 'RightsLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RightsLocalizations'
UNION ALL
SELECT 'RolesRights', COUNT(*) FROM sys.tables WHERE name = 'RolesRights'
UNION ALL
SELECT 'UsersRoles', COUNT(*) FROM sys.tables WHERE name = 'UsersRoles';
"@

docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q $sqlQuery -s "," `
    || ExitWithError "ERROR: Failed to check existing tables."

# --- Проверка структуры таблиц ---
Write-Host "Checking table structure..."
$structureQuery = @"
USE $DATABASE;
SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'Rights', 'RightsLocalizations', 'RolesRights', 'UsersRoles')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
"@

docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q $structureQuery -s "," `
    || ExitWithError "ERROR: Failed to check table structure."

# --- Вывод текущих данных ---
Write-Host "Printing current table contents..."
$tables = @("Rights", "Roles", "RolesLocalizations", "RightsLocalizations", "RolesRights", "UsersRoles")
foreach ($table in $tables) {
    Write-Host "$table table:"
    docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE `
        -Q "USE $DATABASE; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;" -s "," -W 2>$null
}

# --- Очистка существующих данных ---
Write-Host "Cleaning up existing data..."
$cleanupQuery = @"
USE $DATABASE;
IF OBJECT_ID('UsersRoles') IS NOT NULL DELETE FROM UsersRoles WHERE RoleId = '$ADMIN_ROLE_ID';
IF OBJECT_ID('RolesRights') IS NOT NULL DELETE FROM RolesRights WHERE RoleId = '$ADMIN_ROLE_ID';
IF OBJECT_ID('RolesLocalizations') IS NOT NULL DELETE FROM RolesLocalizations WHERE RoleId = '$ADMIN_ROLE_ID';
IF OBJECT_ID('Roles') IS NOT NULL DELETE FROM Roles WHERE Id = '$ADMIN_ROLE_ID';
IF OBJECT_ID('RightsLocalizations') IS NOT NULL DELETE FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID');
IF OBJECT_ID('Rights') IS NOT NULL DELETE FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID';
"@

docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q $cleanupQuery `
    || ExitWithError "ERROR: Failed to clean up existing data."

# --- Копирование и выполнение SQL скрипта ---
Write-Host "Copying SQL script to container..."
$sqlPath = Join-Path $scriptDir "RightsDB\05_setup_admin_rights.sql"
if (-not (Test-Path $sqlPath)) {
    ExitWithError "ERROR: SQL script not found: $sqlPath"
}
docker cp $sqlPath "$CONTAINER:/tmp/05_setup_admin_rights.sql" `
    || ExitWithError "ERROR: Failed to copy SQL script to container."

Write-Host "Setting up admin rights..."
docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -i /tmp/05_setup_admin_rights.sql `
    || ExitWithError "ERROR: Failed to set up admin rights."

# --- Проверка ---
Write-Host "Verifying admin rights setup..."
$verifyQuery = @"
USE $DATABASE;
IF OBJECT_ID('Roles') IS NOT NULL AND OBJECT_ID('RolesLocalizations') IS NOT NULL
SELECT r.Id AS RoleId, rl.Name AS RoleName, r.IsActive AS RoleIsActive,
       COUNT(DISTINCT rr.RightId) AS AssignedRightsCount, COUNT(DISTINCT ur.UserId) AS AssignedUsersCount
FROM Roles r
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en'
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId
WHERE r.Id = '$ADMIN_ROLE_ID'
GROUP BY r.Id, rl.Name, r.IsActive;
"@

docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q $verifyQuery -s "," -W 2>$null

# --- Проверка целостности ---
Write-Host "Verifying data integrity..."
$integrityQuery = @"
USE $DATABASE;
SELECT 'Roles' AS TableName, CASE WHEN OBJECT_ID('Roles') IS NOT NULL THEN (SELECT COUNT(*) FROM Roles WHERE Id = '$ADMIN_ROLE_ID') ELSE 0 END AS Count
UNION ALL
SELECT 'RolesLocalizations', CASE WHEN OBJECT_ID('RolesLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesLocalizations WHERE RoleId = '$ADMIN_ROLE_ID') ELSE 0 END
UNION ALL
SELECT 'Rights', CASE WHEN OBJECT_ID('Rights') IS NOT NULL THEN (SELECT COUNT(*) FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID') ELSE 0 END
UNION ALL
SELECT 'RightsLocalizations', CASE WHEN OBJECT_ID('RightsLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID')) ELSE 0 END
UNION ALL
SELECT 'RolesRights', CASE WHEN OBJECT_ID('RolesRights') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesRights WHERE RoleId = '$ADMIN_ROLE_ID') ELSE 0 END
UNION ALL
SELECT 'UsersRoles', CASE WHEN OBJECT_ID('UsersRoles') IS NOT NULL THEN (SELECT COUNT(*) FROM UsersRoles WHERE RoleId = '$ADMIN_ROLE_ID') ELSE 0 END;
"@

docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q $integrityQuery -s "," -W 2>$null

# --- Финальный вывод ---
Write-Host "Printing final table contents..."
foreach ($table in $tables) {
    Write-Host "$table table:"
    docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE `
        -Q "USE $DATABASE; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;" -s "," -W 2>$null
}

# --- Внешний скрипт проверки ---
$checkScript = Join-Path $scriptDir "RightsDB\check_RightsDB_tables.bat"
if (Test-Path $checkScript) {
    Write-Host "Running external verification script..."
    cmd /c $checkScript || ExitWithError "ERROR: External verification script failed."
} else {
    Write-Warning "WARNING: External verification script $checkScript not found."
}

Write-Host "Done ✅"
Read-Host "Press Enter to exit"
