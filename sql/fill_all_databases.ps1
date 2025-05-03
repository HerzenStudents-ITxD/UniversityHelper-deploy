# PowerShell Core скрипт для заполнения всех баз данных
# Установка кодировки UTF-8 для корректного отображения русских символов
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "Запуск скрипта заполнения всех баз данных..."

# Загрузка переменных окружения из файла .env в директории скрипта
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "ОШИБКА: Файл .env не найден по пути ${envFile}"
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Отладочная информация о кодировке
Write-Host "[Debug] Script directory: $scriptDir"
Write-Host "[Debug] Current console output encoding: $([Console]::OutputEncoding.BodyName)"

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

    $scriptPath = Join-Path $scriptDir $ScriptName

    Write-Host "[Executing] $scriptPath"
    if (-not (Test-Path $scriptPath)) {
        Write-Error "[Error] Script '$scriptPath' not found!"
        Write-Host "[Debug] Current directory: $(Get-Location)"
        Write-Host "[Debug] Script directory: $scriptDir"
        Read-Host "Press Enter to continue..."
        exit 1
    }

    # Прямой запуск скрипта в текущей сессии для сохранения кодировки
    & $scriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[Error] Script '$scriptPath' failed with code $LASTEXITCODE"
        Read-Host "Press Enter to continue..."
        exit $LASTEXITCODE
    }

    Write-Host "[Success] $scriptPath completed"
    Write-Host ""
}

# Последовательное выполнение скриптов
foreach ($script in $scripts) {
    Run-Script -ScriptName $script
}

Write-Host ""
Write-Host "Все базы данных успешно заполнены! ✅"
Read-Host "Нажмите Enter для выхода"
exit 0