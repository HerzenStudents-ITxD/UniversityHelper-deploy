# Проверяем, запущен ли скрипт от имени администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Скрипт требует прав администратора. Запускаем с повышенными правами..."
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    exit
}

# Функция для проверки наличия команды
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

# Проверяем наличие Chocolatey
if (-not (Test-CommandExists "choco")) {
    Write-Host "Chocolatey не установлен. Устанавливаем..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    # Обновляем переменные окружения
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Проверяем наличие make
if (-not (Test-CommandExists "make")) {
    Write-Host "Make не установлен. Устанавливаем через Chocolatey..."
    choco install make -y
    # Обновляем переменные окружения
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Проверяем наличие make после установки
if (Test-CommandExists "make") {
    Write-Host "Make успешно установлен. Запускаем make..."
    make
} else {
    Write-Host "Ошибка: Не удалось установить make. Пожалуйста, установите его вручную."
    exit 1
} 