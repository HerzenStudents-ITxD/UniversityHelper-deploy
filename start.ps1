# Определяем операционную систему
$os = [System.Environment]::OSVersion.Platform

if ($os -eq "Win32NT") {
    # Windows
    Write-Host "Обнаружена Windows. Запускаем setup.ps1..."
    
    # Получаем полный путь к setup.ps1
    $setupScript = Join-Path $PSScriptRoot "setup.ps1"
    
    # Проверяем, что файл существует
    if (Test-Path $setupScript) {
        # Запускаем скрипт в текущем процессе
        & $setupScript
    } else {
        Write-Host "Ошибка: Файл setup.ps1 не найден"
        exit 1
    }
} elseif ($os -eq "Unix") {
    # Unix-like системы (macOS или Linux)
    $setupScript = Join-Path $PSScriptRoot "setup.sh"
    if (Test-Path $setupScript) {
        Write-Host "Обнаружена Unix-подобная система. Запускаем setup.sh..."
        bash $setupScript
    } else {
        Write-Host "Ошибка: Файл setup.sh не найден"
        exit 1
    }
} else {
    Write-Host "Неподдерживаемая операционная система"
    exit 1
} 