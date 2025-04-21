# Определяем операционную систему
$os = [System.Environment]::OSVersion.Platform

if ($os -eq "Win32NT") {
    # Windows
    Write-Host "Обнаружена Windows. Запускаем setup.ps1..."
    powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\setup.ps1"
} elseif ($os -eq "Unix") {
    # Unix-like системы (macOS или Linux)
    if (Test-Path "$PSScriptRoot/setup.sh") {
        Write-Host "Обнаружена Unix-подобная система. Запускаем setup.sh..."
        bash "$PSScriptRoot/setup.sh"
    } else {
        Write-Host "Ошибка: Файл setup.sh не найден"
        exit 1
    }
} else {
    Write-Host "Неподдерживаемая операционная система"
    exit 1
} 