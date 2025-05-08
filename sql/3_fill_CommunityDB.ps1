# PowerShell Core script for configuring the CommunityDB database
Write-Host "Starting the CommunityDB database population script..."

# Loading environment variables from the .env file in the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir ".env"
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
$database = $env:COMMUNITYDB_DB_NAME
$userId = $env:COMMUNITYDB_ADMIN_USER_ID

# Validating environment variables
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "COMMUNITYDB_DB_NAME", "COMMUNITYDB_ADMIN_USER_ID")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ERROR: Environment variable ${var} is not set."
        Read-Host "Press Enter to continue..."
        exit 1
    }
}

# Validating database name
if ($database -ne "CommunityDB") {
    Write-Error "ERROR: Database name (${database}) does not match expected 'CommunityDB'."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Checking Docker availability
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: Docker is not installed or missing from PATH."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Checking if container is running
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

# Testing SQL Server connection
Write-Host "Testing SQL Server connection..."
$testQuery = "SELECT 1 AS Test"
if (-not (Invoke-SqlCmd -Query $testQuery -Database "master")) {
    Read-Host "Press Enter to continue..."
    exit 1
}

# Checking if database exists
Write-Host "Checking if database ${database} exists..."
$checkDbQuery = "SELECT name FROM sys.databases WHERE name = '${database}'"
$dbExists = Invoke-SqlCmd -Query $checkDbQuery -Database "master"
if ($dbExists -notmatch "CommunityDB") {
    Write-Error "ERROR: Database ${database} not found. Cleaned database list: ${dbExists}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Checking existing tables
Write-Host "Checking existing tables in database ${database}..."
$checkTablesQuery = "USE ${database}; SELECT 'Communities' AS TableName, COUNT(*) AS Count FROM Communities UNION ALL SELECT 'Agents', COUNT(*) FROM Agents UNION ALL SELECT 'HiddenCommunities', COUNT(*) FROM HiddenCommunities UNION ALL SELECT 'News', COUNT(*) FROM News UNION ALL SELECT 'NewsPhoto', COUNT(*) FROM NewsPhoto UNION ALL SELECT 'Participating', COUNT(*) FROM Participating;"
if (-not (Invoke-SqlCmd $checkTablesQuery)) {
    Write-Error "ERROR: Failed to check existing CommunityDB tables."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Cleaning up existing data
Write-Host "Cleaning up existing data..."
$cleanupQuery = "USE ${database}; DELETE FROM Participating WHERE UserId = '${userId}'; DELETE FROM News WHERE AuthorId = '${userId}'; DELETE FROM Agents WHERE AgentId = '${userId}'; DELETE FROM HiddenCommunities WHERE UserId = '${userId}'; DELETE FROM Communities WHERE CreatedBy = '${userId}';"
if (-not (Invoke-SqlCmd $cleanupQuery)) {
    Write-Error "ERROR: Failed to clean up existing data."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Copying SQL script to container
Write-Host "Copying SQL script to container..."
$sqlScriptPath = Join-Path $scriptDir "CommunityDB\06_setup_community_data.sql"
if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ERROR: SQL script ${sqlScriptPath} not found."
    Read-Host "Press Enter to continue..."
    exit 1
}
docker cp $sqlScriptPath "${container}:/tmp/06_setup_community_data.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to copy SQL script to container."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Executing SQL script
Write-Host "Executing SQL script..."
$setupQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${database} -i /tmp/06_setup_community_data.sql"
$result = docker exec -it $container bash -c $setupQuery 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to execute SQL script. Details: ${result}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Verifying CommunityDB tables
Write-Host "Verifying CommunityDB tables..."
$verifyScriptPath = Join-Path $scriptDir "sql\CommunityDB\check_CommunityDB_tables.bat"
if (Test-Path $verifyScriptPath) {
    Write-Host "Executing external verification script..."
    # Running BAT script via cmd
    cmd /c $verifyScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Verification script check_CommunityDB_tables.bat failed."
        Read-Host "Press Enter to continue..."
        exit 1
    }
} else {
    Write-Warning "WARNING: Verification script ${verifyScriptPath} not found."
}

Write-Host "Done ✅"
Read-Host "Press Enter to continue..."
exit 0