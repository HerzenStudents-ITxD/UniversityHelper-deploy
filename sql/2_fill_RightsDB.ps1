Write-Host "Launching RightsDB database fill script..."

# [DEBUG] Load .env from same directory as this script
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $scriptDirectory ".env"
Write-Host "[DEBUG] Loading environment variables from .env file..."
if (-Not (Test-Path $envPath)) {
    Write-Error "[ERROR] .env file not found in script directory: $envPath"
    exit 1
}

# Load .env key-value pairs
Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*#') { return } # Ignore comments
    if ($_ -match '^\s*$') { return } # Ignore empty lines
    if ($_ -match '^\s*(\w+)\s*=\s*(.+?)\s*$') {
        $name, $value = $matches[1], $matches[2]
        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

# Config from env
$CONTAINER = $env:DB_CONTAINER
$RIGHTS_DB_PASSWORD = $env:SA_PASSWORD
$DATABASE = $env:RIGHTSDB_DB_NAME
$ADMIN_USER_ID = $env:RIGHTSDB_ADMIN_USER_ID
$ADMIN_ROLE_ID = $env:RIGHTSDB_ADMIN_ROLE_ID

function ExitWithError($message) {
    Write-Error $message
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if container is running
Write-Host "Checking if container $CONTAINER is running..."
$containerStatus = docker inspect -f '{{.State.Running}}' $CONTAINER 2>$null
if ($containerStatus -ne "true") {
    ExitWithError "ERROR: Container $CONTAINER is not running."
}

# Check existing tables
Write-Host "Checking existing $DATABASE tables..."
docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q @"
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
"@ -s "," -ErrorAction Stop || ExitWithError "ERROR: Failed to check existing tables."

# Check table structure
Write-Host "Checking table structure..."
docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q @"
USE $DATABASE;
SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'Rights', 'RightsLocalizations', 'RolesRights', 'UsersRoles')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
"@ -s "," -ErrorAction Stop || ExitWithError "ERROR: Failed to check table structure."

# Print current table contents
Write-Host "Printing current table contents..."
$tables = @("Rights", "Roles", "RolesLocalizations", "RightsLocalizations", "RolesRights", "UsersRoles")
foreach ($table in $tables) {
    Write-Host "$table table:"
    docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;" -s "," -ErrorAction SilentlyContinue
}

# Clean up existing data
Write-Host "Cleaning up existing data..."
docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q @"
USE $DATABASE;
IF OBJECT_ID('UsersRoles') IS NOT NULL DELETE FROM UsersRoles WHERE RoleId = '$ADMIN_ROLE_ID';
IF OBJECT_ID('RolesRights') IS NOT NULL DELETE FROM RolesRights WHERE RoleId = '$ADMIN_ROLE_ID';
IF OBJECT_ID('RolesLocalizations') IS NOT NULL DELETE FROM RolesLocalizations WHERE RoleId = '$ADMIN_ROLE_ID';
IF OBJECT_ID('Roles') IS NOT NULL DELETE FROM Roles WHERE Id = '$ADMIN_ROLE_ID';
IF OBJECT_ID('RightsLocalizations') IS NOT NULL DELETE FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID');
IF OBJECT_ID('Rights') IS NOT NULL DELETE FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID';
"@ -ErrorAction Stop || ExitWithError "ERROR: Failed to clean up existing data."

# Copy SQL script to container
Write-Host "Copying SQL script to container..."
$sqlPath = Join-Path $scriptDirectory "RightsDB\05_setup_admin_rights.sql"
if (-not (Test-Path $sqlPath)) {
    ExitWithError "ERROR: SQL script $sqlPath not found."
}
docker cp $sqlPath "${CONTAINER}:/tmp/05_setup_admin_rights.sql" `
    || ExitWithError "ERROR: Failed to copy SQL script to container."

# Set up admin rights
Write-Host "Setting up admin rights..."
docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -i /tmp/05_setup_admin_rights.sql `
    || ExitWithError "ERROR: Failed to set up admin rights."

# Verify admin rights setup
Write-Host "Verifying admin rights setup..."
docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q @"
USE $DATABASE;
IF OBJECT_ID('Roles') IS NOT NULL AND OBJECT_ID('RolesLocalizations') IS NOT NULL
SELECT r.Id AS RoleId, rl.Name AS RoleName, r.IsActive AS RoleIsActive, COUNT(DISTINCT rr.RightId) AS AssignedRightsCount, COUNT(DISTINCT ur.UserId) AS AssignedUsersCount
FROM Roles r
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en'
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId
WHERE r.Id = '$ADMIN_ROLE_ID'
GROUP BY r.Id, rl.Name, r.IsActive;
"@ -s "," -ErrorAction SilentlyContinue

# Verify data integrity
Write-Host "Verifying data integrity..."
docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q @"
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
"@ -s "," -ErrorAction SilentlyContinue

# Print final table contents
Write-Host "Printing final table contents..."
foreach ($table in $tables) {
    Write-Host "$table table:"
    docker exec -i $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;" -s "," -ErrorAction SilentlyContinue
}

# Run external verification script if exists
$checkScript = Join-Path $scriptDirectory "RightsDB\check_RightsDB_tables.bat"
if (Test-Path $checkScript) {
    Write-Host "Running external verification script..."
    cmd /c $checkScript || ExitWithError "ERROR: External verification script failed."
} else {
    Write-Warning "WARNING: External verification script $checkScript not found."
}

Write-Host "Done ✅"
Read-Host "Press Enter to exit"
