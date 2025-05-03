# fill_all_databases.ps1
Write-Host "Launching all database fill scripts..."

# Получаем путь к директории текущего скрипта
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "[Debug] Script directory: $SCRIPT_DIR"

# Список PowerShell-скриптов для выполнения
$scripts = @(
    "1_fill_UserDB.ps1",
    "2_fill_RightsDB.ps1",
    "3_fill_CommunityDB.ps1",
    "4_fill_FeedbackDB.ps1"
)

# Функция для выполнения одного скрипта
function Run-Script {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    $ScriptPath = Join-Path $SCRIPT_DIR $ScriptName

    Write-Host "[Executing] $ScriptPath"
    if (-not (Test-Path $ScriptPath)) {
        Write-Error "[Error] Script '$ScriptPath' not found!"
        Write-Host "[Debug] Current directory: $(Get-Location)"
        Write-Host "[Debug] Script directory: $SCRIPT_DIR"
        exit 1
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[Error] Script '$ScriptPath' failed with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }

    Write-Host "[Success] $ScriptPath completed"
    Write-Host ""
}

# Последовательное выполнение скриптов
foreach ($script in $scripts) {
    Run-Script -ScriptName $script
}

Write-Host ""
Write-Host "All databases filled successfully! ✅"
Read-Host "Press Enter to exit"
exit 0
