# PowerShell Core script for populating all databases
Write-Host "Starting script to populate all databases..."

# Load environment variables from .env file in the script's directory
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

# Debug information about encoding
Write-Host "[Debug] Script directory: $scriptDir"
Write-Host "[Debug] Current console output encoding: $([Console]::OutputEncoding.BodyName)"

# List of PowerShell scripts to execute
$scripts = @(
    "1_fill_UserDB.ps1",
    "2_fill_RightsDB.ps1",
    "3_fill_CommunityDB.ps1",
    "4_fill_FeedbackDB.ps1"
)

# Function to run a single script
function Run-Script {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    $scriptPath = Join-Path $scriptDir $ScriptName

    Write-Host "[Executing] $scriptPath"
    if (-not (Test-Path $scriptPath)) {
        Write-Error "[Error] Script '$scriptPath' not found!"
        Write-Host "[Debug] Current directory: $(Get-Location)"
        Write-Host "[Debug] Script directory: $scriptDir"
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