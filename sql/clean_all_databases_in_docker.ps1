# PowerShell Core script for cleaning all databases
Write-Host "Starting the script to clean all databases..."

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

# Function to execute cleanup scripts
function Execute-CleanScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $sqlScript = Join-Path $scriptDir $RelativePath

    if (-not (Test-Path $sqlScript)) {
        Write-Error "ERROR: Cleanup script not found at path: ${sqlScript}"
        return $false
    }

    Write-Host "Processing ${RelativePath}..."

    docker cp $sqlScript "${container}:/temp_clean_script.sql"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to copy SQL script to container"
        return $false
    }

    docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -i /temp_clean_script.sql
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to execute cleanup script"
        return $false
    }

    docker exec $container rm -f /temp_clean_script.sql | Out-Null
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

# Execute cleanup scripts for each database
$cleanScripts = @(
    "UserDB\clean_tables.sql",
    "CommunityDB\clean_tables.sql",
    "RightsDB\clean_tables.sql",
    "FeedbackDB\clean_tables.sql",
    "MapDB\clean_tables.sql"
)

Write-Host "Cleaning all databases..."
foreach ($script in $cleanScripts) {
    $success = Execute-CleanScript -RelativePath $script
    if (-not $success) {
        Write-Error "ERROR: Failed to execute cleanup script ${script}"
        Read-Host "Press Enter to continue..."
        exit 1
    }
}

Write-Host "All databases cleaned successfully! ✅"
Read-Host "Press Enter to continue..."
exit 0