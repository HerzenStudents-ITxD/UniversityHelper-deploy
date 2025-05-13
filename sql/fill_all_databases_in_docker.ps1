#!/usr/bin/env pwsh

# PowerShell Core script for populating all databases
Write-Host "Starting script to populate all databases..."

# Load environment variables from .env file in the script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path -Path $scriptDir -ChildPath ".env"

# Debug path information
Write-Host "[DEBUG] Script directory: $scriptDir"
Write-Host "[DEBUG] .env file path: $envFile"

if (-not (Test-Path $envFile)) {
    Write-Error "ERROR: .env file not found at $envFile"
    Write-Host "[DEBUG] Current directory contents:"
    Get-ChildItem -Path $scriptDir | Select-Object Name | Format-Table -AutoSize
    Read-Host "Press Enter to continue..."
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Debug information about encoding
Write-Host "[DEBUG] Current console output encoding: $([Console]::OutputEncoding.BodyName)"

# List of PowerShell scripts to execute
$scripts = @(
    "1_fill_UserDB_in_docker.ps1",
    "2_fill_RightsDB_in_docker.ps1",
    "3_fill_CommunityDB_in_docker.ps1",
    "4_fill_FeedbackDB_in_docker.ps1",
    "5_fill_MapDB_in_docker.ps1",
    "6_fill_UserDB_add_users_in_docker.ps1"
)

# Function to run a single script
function Run-Script {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    $scriptPath = Join-Path -Path $scriptDir -ChildPath $ScriptName

    Write-Host "[Executing] $scriptPath"
    
    # Additional debug info
    Write-Host "[DEBUG] Full script path: $((Get-Item $scriptPath).FullName)"
    Write-Host "[DEBUG] Script exists: $(Test-Path $scriptPath)"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Error "[Error] Script '$scriptPath' not found!"
        Write-Host "[DEBUG] Current directory contents:"
        Get-ChildItem -Path $scriptDir | Select-Object Name | Format-Table -AutoSize
        Read-Host "Press Enter to continue..."
        exit 1
    }

    # Run script in current session to preserve encoding
    try {
        & $scriptPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[Error] Script '$scriptPath' failed with exit code $LASTEXITCODE"
            Read-Host "Press Enter to continue..."
            exit $LASTEXITCODE
        }
        Write-Host "[Success] $scriptPath completed"
    } catch {
        Write-Error "[Error] Exception occurred while running '$scriptPath': $_"
        Write-Host "[DEBUG] Exception details: $($_.Exception | Format-List * -Force | Out-String)"
        Read-Host "Press Enter to continue..."
        exit 1
    }
    Write-Host ""
}

# Execute scripts sequentially
foreach ($script in $scripts) {
    Run-Script -ScriptName $script
}

Write-Host ""
Write-Host "All databases successfully populated! ✅"
Read-Host "Press Enter to exit"
exit 0