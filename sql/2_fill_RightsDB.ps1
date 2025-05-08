# PowerShell Core script for setting up the RightsDB database
Write-Host "Starting the RightsDB database population script..."

# Load environment variables from the .env file in the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at ${envFile}"
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
$database = $env:RIGHTSDB_DB_NAME
$adminUserId = $env:RIGHTSDB_ADMIN_USER_ID
$adminRoleId = $env:RIGHTSDB_ADMIN_ROLE_ID

# Validate environment variables
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "RIGHTSDB_DB_NAME", "RIGHTSDB_ADMIN_USER_ID", "RIGHTSDB_ADMIN_ROLE_ID")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ERROR: Environment variable ${var} is not set."
        Read-Host "Press Enter to continue..."
        exit 1
    }
}

# Verify database name
if ($database -ne "RightsDB") {
    Write-Error "ERROR: Database name (${database}) does not match expected 'RightsDB'."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Check for Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: Docker is not installed or not in PATH."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Check if container is running
Write-Host "Checking if container ${container} is running..."
$containerStatus = docker inspect $container 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Container ${container} is not running."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Function to execute SQL commands
function Invoke-SqlCmd {
    param($Query, $Database = $database)
    $sqlcmd = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${Database} -Q `"${Query}`" -s',' -W"
    Write-Host "Executing SQL: ${Query}"
    $result = docker exec -it $container bash -c $sqlcmd 2>&1
    Write-Host "SQL Result: ${result}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to execute SQL command. Details: ${result}"
        return $false
    }
    # Clean result from headers, separators, and empty lines
    $cleanResult = ($result -split "`n" | Where-Object { 
        $_ -notmatch "^\s*(\(|\-\-|$)" -and 
        $_ -notmatch "rows affected" -and 
        $_ -notmatch "^name\s*$" 
    } | ForEach-Object { $_.Trim() }) -join "`n"
    Write-Host "Cleaned SQL Result: ${cleanResult}"
    return $cleanResult
}

# Test SQL Server connection
Write-Host "Testing SQL Server connection..."
$testQuery = "SELECT 1 AS Test"
if (-not (Invoke-SqlCmd -Query $testQuery -Database "master")) {
    Read-Host "Press Enter to continue..."
    exit 1
}

# Check if database exists
Write-Host "Checking if database ${database} exists..."
$checkDbQuery = "SELECT name FROM sys.databases WHERE name = '${database}'"
$dbExists = Invoke-SqlCmd -Query $checkDbQuery -Database "master"
if ($dbExists -notmatch "RightsDB") {
    Write-Error "ERROR: Database ${database} not found. Cleaned database list: ${dbExists}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Check existing tables
Write-Host "Checking existing tables in database ${database}..."
$checkTablesQuery = "USE ${database}; SELECT 'Roles' AS TableName, COUNT(*) AS Count FROM sys.tables WHERE name = 'Roles' UNION ALL SELECT 'RolesLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RolesLocalizations' UNION ALL SELECT 'Rights', COUNT(*) FROM sys.tables WHERE name = 'Rights' UNION ALL SELECT 'RightsLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RightsLocalizations' UNION ALL SELECT 'RolesRights', COUNT(*) FROM sys.tables WHERE name = 'RolesRights' UNION ALL SELECT 'UsersRoles', COUNT(*) FROM sys.tables WHERE name = 'UsersRoles';"
if (-not (Invoke-SqlCmd $checkTablesQuery)) {
    Read-Host "Press Enter to continue..."
    exit 1
}

# Check table structure
Write-Host "Checking table structure..."
$checkStructureQuery = "USE ${database}; SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'Rights', 'RightsLocalizations', 'RolesRights', 'UsersRoles') ORDER BY TABLE_NAME, ORDINAL_POSITION;"
if (-not (Invoke-SqlCmd $checkStructureQuery)) {
    Read-Host "Press Enter to continue..."
    exit 1
}

# Create tables if they don't exist
Write-Host "Creating tables if they don't exist..."
$createTablesQuery = @"
USE ${database};
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Rights')
    CREATE TABLE Rights (RightId int PRIMARY KEY, CreatedBy uniqueidentifier NOT NULL);
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
    CREATE TABLE Roles (Id uniqueidentifier PRIMARY KEY, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesHistory));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations')
    CREATE TABLE RolesLocalizations (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, Locale char(2) NOT NULL, Name nvarchar(max) NOT NULL, Description nvarchar(max) NOT NULL, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, CreatedAtUtc datetime2 NOT NULL, ModifiedBy uniqueidentifier, ModifiedAtUtc datetime2, CONSTRAINT FK_RolesLocalizations_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations')
    CREATE TABLE RightsLocalizations (Id uniqueidentifier PRIMARY KEY, RightId int NOT NULL, Locale char(2) NOT NULL, Name nvarchar(max) NOT NULL, Description nvarchar(max) NOT NULL, CONSTRAINT FK_RightsLocalizations_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights')
    CREATE TABLE RolesRights (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, RightId int NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), CONSTRAINT FK_RolesRights_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id), CONSTRAINT FK_RolesRights_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesRightsHistory));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles')
    CREATE TABLE UsersRoles (Id uniqueidentifier PRIMARY KEY, UserId uniqueidentifier NOT NULL, RoleId uniqueidentifier NOT NULL, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), CONSTRAINT FK_UsersRoles_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.UsersRolesHistory));
"@
if (-not (Invoke-SqlCmd $createTablesQuery)) {
    Read-Host "Press Enter to continue..."
    exit 1
}

# Display current table contents
$tables = @("Rights", "Roles", "RolesLocalizations", "RightsLocalizations", "RolesRights", "UsersRoles")
foreach ($table in $tables) {
    Write-Host "Table ${table}:"
    $query = "USE ${database}; IF OBJECT_ID('${table}') IS NOT NULL SELECT * FROM ${table};"
    if (-not (Invoke-SqlCmd $query)) {
        Write-Error "ERROR: Failed to display table ${table}."
    }
}

# Clean existing data
Write-Host "Cleaning existing data..."
$cleanupQuery = @"
USE ${database};
IF OBJECT_ID('UsersRoles') IS NOT NULL DELETE FROM UsersRoles WHERE RoleId = '${adminRoleId}';
IF OBJECT_ID('RolesRights') IS NOT NULL DELETE FROM RolesRights WHERE RoleId = '${adminRoleId}';
IF OBJECT_ID('RolesLocalizations') IS NOT NULL DELETE FROM RolesLocalizations WHERE RoleId = '${adminRoleId}';
IF OBJECT_ID('Roles') IS NOT NULL DELETE FROM Roles WHERE Id = '${adminRoleId}';
IF OBJECT_ID('RightsLocalizations') IS NOT NULL DELETE FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '${adminUserId}');
IF OBJECT_ID('Rights') IS NOT NULL DELETE FROM Rights WHERE CreatedBy = '${adminUserId}';
"@
if (-not (Invoke-SqlCmd $cleanupQuery)) {
    Read-Host "Press Enter to continue..."
    exit 1
}

# Copy SQL script to container
Write-Host "Copying SQL script to container..."
$sqlScriptPath = Join-Path $scriptDir "RightsDB\05_setup_admin_rights.sql"
if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ERROR: SQL script ${sqlScriptPath} not found."
    Read-Host "Press Enter to continue..."
    exit 1
}
docker cp $sqlScriptPath "${container}:/tmp/05_setup_admin_rights.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to copy SQL script to container."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Set up admin rights
Write-Host "Setting up admin rights..."
$setupAdminQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${database} -i /tmp/05_setup_admin_rights.sql"
$result = docker exec -it $container bash -c $setupAdminQuery 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to set up admin rights. Details: ${result}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Verify admin rights setup
Write-Host "Verifying admin rights setup..."
$verifyAdminQuery = @"
USE ${database};
IF OBJECT_ID('Roles') IS NOT NULL AND OBJECT_ID('RolesLocalizations') IS NOT NULL
SELECT r.Id AS RoleId, rl.Name AS RoleName, r.IsActive AS RoleIsActive, COUNT(DISTINCT rr.RightId) AS AssignedRightsCount, COUNT(DISTINCT ur.UserId) AS AssignedUsersCount
FROM Roles r
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en'
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId
WHERE r.Id = '${adminRoleId}'
GROUP BY r.Id, rl.Name, r.IsActive;
"@
if (-not (Invoke-SqlCmd $verifyAdminQuery)) {
    Write-Error "ERROR: Failed to verify admin rights setup."
}

# Verify data integrity
Write-Host "Verifying data integrity..."
$verifyIntegrityQuery = @"
USE ${database};
SELECT 'Roles' AS TableName, CASE WHEN OBJECT_ID('Roles') IS NOT NULL THEN (SELECT COUNT(*) FROM Roles WHERE Id = '${adminRoleId}') ELSE 0 END AS Count UNION ALL
SELECT 'RolesLocalizations', CASE WHEN OBJECT_ID('RolesLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesLocalizations WHERE RoleId = '${adminRoleId}') ELSE 0 END UNION ALL
SELECT 'Rights', CASE WHEN OBJECT_ID('Rights') IS NOT NULL THEN (SELECT COUNT(*) FROM Rights WHERE CreatedBy = '${adminUserId}') ELSE 0 END UNION ALL
SELECT 'RightsLocalizations', CASE WHEN OBJECT_ID('RightsLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '${adminUserId}')) ELSE 0 END UNION ALL
SELECT 'RolesRights', CASE WHEN OBJECT_ID('RolesRights') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesRights WHERE RoleId = '${adminRoleId}') ELSE 0 END UNION ALL
SELECT 'UsersRoles', CASE WHEN OBJECT_ID('UsersRoles') IS NOT NULL THEN (SELECT COUNT(*) FROM UsersRoles WHERE RoleId = '${adminRoleId}') ELSE 0 jejune ELSE 0 END;
"@
if (-not (Invoke-SqlCmd $verifyIntegrityQuery)) {
    Write-Error "ERROR: Failed to verify data integrity."
}

# Display final table contents
Write-Host "Displaying final table contents..."
foreach ($table in $tables) {
    Write-Host "Table ${table}:"
    $query = "USE ${database}; IF OBJECT_ID('${table}') IS NOT NULL SELECT * FROM ${table};"
    if (-not (Invoke-SqlCmd $query)) {
        Write-Error "ERROR: Failed to display final contents of table ${table}."
    }
}

# Execute external verification script if it exists
$verifyScriptPath = Join-Path $scriptDir "sql\RightsDB\check_RightsDB_tables.ps1"
if (Test-Path $verifyScriptPath) {
    Write-Host "Executing external verification script..."
    & $verifyScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: External verification script failed."
        Read-Hos
t "Press Enter to continue..."
        exit 1
    }
} else {
    Write-Warning "WARNING: External verification script ${verifyScriptPath} not found."
}

Write-Host "Done ✅"
Read-Host "Press Enter to continue..."
exit 0