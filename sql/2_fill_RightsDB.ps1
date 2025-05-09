#!/usr/bin/env pwsh

# PowerShell Core script for setting up the RightsDB database
Write-Host "Starting the RightsDB database population script..."

# Load environment variables from the .env file in the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path -Path $scriptDir -ChildPath ".env"

Write-Host "[DEBUG] Script directory: $scriptDir"
Write-Host "[DEBUG] .env file path: $envFile"

if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at $envFile"
    Write-Host "[DEBUG] Current directory contents:"
    Get-ChildItem -Path $scriptDir | Select-Object Name | Format-Table -AutoSize
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Configuration from .env
$container = [System.Environment]::GetEnvironmentVariable("DB_CONTAINER")
$password = [System.Environment]::GetEnvironmentVariable("SA_PASSWORD")
$database = [System.Environment]::GetEnvironmentVariable("RIGHTSDB_DB_NAME")
$adminUserId = [System.Environment]::GetEnvironmentVariable("RIGHTSDB_ADMIN_USER_ID")
$adminRoleId = [System.Environment]::GetEnvironmentVariable("RIGHTSDB_ADMIN_ROLE_ID")

# Validate environment variables
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "RIGHTSDB_DB_NAME", "RIGHTSDB_ADMIN_USER_ID", "RIGHTSDB_ADMIN_ROLE_ID")
$missingVars = @()
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Error "ERROR: Missing required environment variables: $($missingVars -join ', ')"
    exit 1
}

# Verify database name
if ($database -ne "RightsDB") {
    Write-Error "ERROR: Database name ($database) does not match expected 'RightsDB'."
    exit 1
}

# Check for Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: Docker is not installed or not in PATH."
    exit 1
}

# Check if container is running
Write-Host "Checking if container $container is running..."
try {
    $containerStatus = docker inspect $container 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Container $container is not running"
    }
} catch {
    Write-Error "ERROR: $_"
    exit 1
}

# Function to execute SQL commands
function Invoke-SqlCmd {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        
        [string]$Database = $database
    )

    $escapedPassword = $password -replace "'", "''"
    $sqlcmd = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$escapedPassword' -d $Database -Q `"$Query`" -s',' -W"
    
    Write-Host "[SQL] Executing: $Query"
    
    try {
        $result = docker exec $container bash -c $sqlcmd 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[SQL ERROR] Failed to execute command. Details: $result"
            return $false
        }

        # Clean result
        $cleanResult = ($result -split "`n" | Where-Object { 
            $_ -notmatch "^\s*(\(|\-\-|$)" -and 
            $_ -notmatch "rows affected" -and 
            $_ -notmatch "^name\s*$" 
        } | ForEach-Object { $_.Trim() }) -join "`n"
        
        return $cleanResult
    } catch {
        Write-Error "[SQL EXCEPTION] $_"
        return $false
    }
}

# Check existing tables
Write-Host "Checking existing tables in database $database..."
$checkTablesQuery = @"
USE $database;
SELECT 
    'Roles' AS TableName, 
    COUNT(*) AS Count 
FROM sys.tables 
WHERE name = 'Roles' 
UNION ALL 
SELECT 
    'RolesLocalizations', 
    COUNT(*) 
FROM sys.tables 
WHERE name = 'RolesLocalizations' 
UNION ALL 
SELECT 
    'Rights', 
    COUNT(*) 
FROM sys.tables 
WHERE name = 'Rights' 
UNION ALL 
SELECT 
    'RightsLocalizations', 
    COUNT(*) 
FROM sys.tables 
WHERE name = 'RightsLocalizations' 
UNION ALL 
SELECT 
    'RolesRights', 
    COUNT(*) 
FROM sys.tables 
WHERE name = 'RolesRights' 
UNION ALL 
SELECT 
    'UsersRoles', 
    COUNT(*) 
FROM sys.tables 
WHERE name = 'UsersRoles';
"@

$tablesCheck = Invoke-SqlCmd $checkTablesQuery
if (-not $tablesCheck) {
    exit 1
}

# Create tables if they don't exist
Write-Host "Creating tables if they don't exist..."
$createTablesQuery = @"
USE $database;
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Rights')
    CREATE TABLE Rights (
        RightId int PRIMARY KEY, 
        CreatedBy uniqueidentifier NOT NULL
    );

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
    CREATE TABLE Roles (
        Id uniqueidentifier PRIMARY KEY, 
        IsActive bit NOT NULL, 
        CreatedBy uniqueidentifier NOT NULL, 
        PeriodStart datetime2 GENERATED ALWAYS AS ROW START, 
        PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, 
        PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd)
    ) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesHistory));

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations')
    CREATE TABLE RolesLocalizations (
        Id uniqueidentifier PRIMARY KEY, 
        RoleId uniqueidentifier NOT NULL, 
        Locale char(2) NOT NULL, 
        Name nvarchar(max) NOT NULL, 
        Description nvarchar(max) NOT NULL, 
        IsActive bit NOT NULL, 
        CreatedBy uniqueidentifier NOT NULL, 
        CreatedAtUtc datetime2 NOT NULL, 
        ModifiedBy uniqueidentifier, 
        ModifiedAtUtc datetime2, 
        CONSTRAINT FK_RolesLocalizations_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)
    );

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations')
    CREATE TABLE RightsLocalizations (
        Id uniqueidentifier PRIMARY KEY, 
        RightId int NOT NULL, 
        Locale char(2) NOT NULL, 
        Name nvarchar(max) NOT NULL, 
        Description nvarchar(max) NOT NULL, 
        CONSTRAINT FK_RightsLocalizations_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId)
    );

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights')
    CREATE TABLE RolesRights (
        Id uniqueidentifier PRIMARY KEY, 
        RoleId uniqueidentifier NOT NULL, 
        RightId int NOT NULL, 
        CreatedBy uniqueidentifier NOT NULL, 
        PeriodStart datetime2 GENERATED ALWAYS AS ROW START, 
        PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, 
        PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), 
        CONSTRAINT FK_RolesRights_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id), 
        CONSTRAINT FK_RolesRights_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId)
    ) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesRightsHistory));

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles')
    CREATE TABLE UsersRoles (
        Id uniqueidentifier PRIMARY KEY, 
        UserId uniqueidentifier NOT NULL, 
        RoleId uniqueidentifier NOT NULL, 
        IsActive bit NOT NULL, 
        CreatedBy uniqueidentifier NOT NULL, 
        PeriodStart datetime2 GENERATED ALWAYS AS ROW START, 
        PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, 
        PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), 
        CONSTRAINT FK_UsersRoles_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)
    ) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.UsersRolesHistory));
"@

if (-not (Invoke-SqlCmd $createTablesQuery)) {
    exit 1
}

# Copy SQL script to container
Write-Host "Copying SQL script to container..."
$sqlScriptPath = Join-Path -Path $scriptDir -ChildPath "RightsDB/05_setup_admin_rights.sql"

if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ERROR: SQL script $sqlScriptPath not found."
    exit 1
}

try {
    docker cp $sqlScriptPath "${container}:/tmp/05_setup_admin_rights.sql"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy SQL script to container"
    }
} catch {
    Write-Error "ERROR: $_"
    exit 1
}

# Set up admin rights
Write-Host "Setting up admin rights..."
$setupAdminQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$($password -replace "'", "''")' -d $database -i /tmp/05_setup_admin_rights.sql"

try {
    $result = docker exec $container bash -c $setupAdminQuery 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set up admin rights. Details: $result"
    }
} catch {
    Write-Error "ERROR: $_"
    exit 1
}

Write-Host "RightsDB setup completed successfully ✅"
exit 0