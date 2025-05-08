# PowerShell Core script for configuring the FeedbackDB database
Write-Host "Starting the FeedbackDB database population script..."

# Load environment variables from the .env file in the script directory
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
$database = $env:FEEDBACKDB_DB_NAME

# Validate environment variables
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "FEEDBACKDB_DB_NAME")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ERROR: Environment variable ${var} is not set."
        Read-Host "Press Enter to continue..."
        exit 1
    }
}

# Validate database name
if ($database -ne "FeedbackDB") {
    Write-Error "ERROR: Database name (${database}) does not match the expected 'FeedbackDB'."
    Read-Host "Press Enter to continue..."
    exit 1
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

# Function to execute SQL commands
function Invoke-SqlCmd {
    param($Query, $Database = $database)
    $sqlcmd = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${Database} -Q `"${Query}`" -s',' -W"
    Write-Host "Executing SQL: ${Query}"
    $result = docker exec -it $container bash -c $sqlcmd 2>&1
    Write-Host "SQL result: ${result}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to execute SQL command. Details: ${result}"
        return $false
    }
    # Clean the result by removing headers, separators, and empty lines
    $cleanResult = ($result -split "`n" | Where-Object { 
        $_ -notmatch "^\s*(\(|\-\-|$)" -and 
        $_ -notmatch "rows affected" -and 
        $_ -notmatch "^(name)\s*$" 
    } | ForEach-Object { $_.Trim() }) -join "`n"
    Write-Host "Cleaned SQL result: ${cleanResult}"
    return $cleanResult
}

# Test SQL Server connection
Write-Host "Testing SQL Server connection..."
$testQuery = "SELECT 1 AS Test"
if (-not (Invoke-SqlCmd -Query $testQuery -Database "master")) {
    Read-Host "Press Enter to continue..."
    exit 1
}

# Check if the database exists
Write-Host "Checking if database ${database} exists..."
$checkDbQuery = "SELECT name FROM sys.databases WHERE name = '${database}'"
$dbExists = Invoke-SqlCmd -Query $checkDbQuery -Database "master"
if ($dbExists -notmatch "FeedbackDB") {
    Write-Error "ERROR: Database ${database} not found. Cleaned list of databases: ${dbExists}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Copy SQL script to container
Write-Host "Copying SQL script to container..."
$sqlScriptPath = Join-Path $scriptDir "FeedbackDB\07_setup_feedback_data.sql"
if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ERROR: SQL script ${sqlScriptPath} not found."
    Read-Host "Press Enter to continue..."
    exit 1
}
docker cp $sqlScriptPath "${container}:/tmp/07_setup_feedback_data.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to copy SQL script to container."
    Read-Host "Press Enter to continue..."
    exit 1
}

# Execute SQL script
Write-Host "Configuring FeedbackDB tables and data..."
$setupQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${database} -i /tmp/07_setup_feedback_data.sql"
$result = docker exec -it $container bash -c $setupQuery 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to execute SQL script. Details: ${result}"
    Read-Host "Press Enter to continue..."
    exit 1
}

# Verify FeedbackDB tables
Write-Host "Verifying FeedbackDB tables..."
$verifyScriptPath = Join-Path $scriptDir "sql\FeedbackDB\check_FeedbackDB_tables.bat"
if (Test-Path $verifyScriptPath)) {
    Write-Host "Executing external verification script..."
    # Run BAT script via cmd
    cmd /c $verifyScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Verification script check_FeedbackDB_tables.bat failed."
        Read-Host "Press Enter to continue..."
        exit 1
    }
} else {
    Write-Warning "WARNING: Verification script ${verifyScriptPath} not found."
}

Write-Host "Done ✅"
Read-Host "Press Enter to continue..."
exit 0