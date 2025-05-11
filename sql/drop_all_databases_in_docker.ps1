# PowerShell Core script for dropping all tables in databases
Write-Host "Starting the script to drop all tables..."

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

# Check database connection
Write-Host "Testing database connection with SA credentials..."
$testQuery = "SELECT name FROM sys.databases"
$result = docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "$testQuery"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to connect to SQL Server with provided SA credentials"
    exit 1
}

# Function to execute drop scripts
function Execute-DropScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    $sqlScript = Join-Path $scriptDir $ScriptPath

    if (-not (Test-Path $sqlScript)) {
        Write-Error "ERROR: Drop script not found at path: ${sqlScript}"
        return $false
    }

    Write-Host "Dropping tables in ${DatabaseName}..."

    # Copy script to container
    docker cp $sqlScript "${container}:/temp_drop_script.sql"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to copy SQL script to container"
        return $false
    }

    # Execute script against specific database
    docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -d $DatabaseName -i /temp_drop_script.sql
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to execute drop script in ${DatabaseName}"
        return $false
    }

    # Cleanup
    docker exec $container rm -f /temp_drop_script.sql | Out-Null
    return $true
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

# Execute drop scripts for each database
$databases = @(
    @{ Name = "UserDB"; Script = "UserDB\drop_tables.sql" },
    @{ Name = "CommunityDB"; Script = "CommunityDB\drop_tables.sql" },
    @{ Name = "RightsDB"; Script = "RightsDB\drop_tables.sql" },
    @{ Name = "FeedbackDB"; Script = "FeedbackDB\drop_tables.sql" },
    @{ Name = "MapDB"; Script = "MapDB\drop_tables.sql" }
)

Write-Host "Dropping tables in all databases..."
foreach ($db in $databases) {
    $success = Execute-DropScript -DatabaseName $db.Name -ScriptPath $db.Script
    if (-not $success) {
        Write-Error "ERROR: Failed to execute drop script for ${$db.Name}"
        Read-Host "Press Enter to continue..."
        exit 1
    }
}

Write-Host "All tables dropped successfully! ✅"
Read-Host "Press Enter to continue..."
exit 0