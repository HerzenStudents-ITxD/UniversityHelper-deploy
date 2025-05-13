#!/usr/bin/env pwsh

# PowerShell Core script for configuring the MapDB database
Write-Host "Starting the MapDB database population script..."

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
$database = [System.Environment]::GetEnvironmentVariable("MAPDB_DB_NAME")

# Validate environment variables
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "MAPDB_DB_NAME")
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

# Validate database name
if ($database -ne "MapDB") {
    Write-Error "ERROR: Database name ($database) does not match expected 'MapDB'."
    exit 1
}

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: Docker is not installed or missing from PATH."
    exit 1
}

# Check if the container is running
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

# Copy SQL script to container
Write-Host "Copying SQL script to container..."
$sqlScriptPath = Join-Path -Path $scriptDir -ChildPath "MapDB/08_setup_MapDB.sql"

if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ERROR: SQL script $sqlScriptPath not found."
    exit 1
}

try {
    docker cp $sqlScriptPath "${container}:/tmp/08_setup_MapDB.sql"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy SQL script to container"
    }
} catch {
    Write-Error "ERROR: $_"
    exit 1
}

# Execute SQL script
Write-Host "Configuring MapDB tables and data..."
$setupQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$($password -replace "'", "''")' -d $database -i /tmp/08_setup_MapDB.sql"

try {
    $result = docker exec $container bash -c $setupQuery 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to execute SQL script. Details: $result"
    }
} catch {
    Write-Error "ERROR: $_"
    exit 1
}

# Verify MapDB tables
Write-Host "Verifying MapDB tables..."
$verifyScriptPath = Join-Path -Path $scriptDir -ChildPath "MapDB/check_tables_in_docker.ps1"

if (Test-Path $verifyScriptPath) {
    Write-Host "Executing external verification script..."
    & $verifyScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Verification script failed with exit code $LASTEXITCODE"
        exit 1
    }
} else {
    Write-Warning "WARNING: Verification script $verifyScriptPath not found."
}

# Basic verification of tables - updated to match actual table names
Write-Host "Performing basic table verification..."
$tablesToCheck = @("Points", "PointTypes", "Photos", "LabelPoints", "PointTypePoints")

foreach ($table in $tablesToCheck) {
    $result = Invoke-SqlCmd -Query "SELECT COUNT(*) FROM $table"
    if ($result -is [string] -and $result -match "^\d+$") {
        Write-Host "[VERIFICATION] Table $table contains $result records"
    } else {
        Write-Warning "[VERIFICATION WARNING] Could not verify table $table"
    }
}

Write-Host "MapDB setup completed successfully ✅"
exit 0