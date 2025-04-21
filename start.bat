@echo off
setlocal enabledelayedexpansion

echo Проверка наличия PowerShell...

:: Проверяем наличие PowerShell в стандартных местах
set "PS_PATH="
if exist "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_PATH=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
) else if exist "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_PATH=C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
)

:: Если PowerShell не найден, пытаемся установить его
if "%PS_PATH%"=="" (
    echo PowerShell не найден. Пытаемся установить...
    
    :: Проверяем, является ли система 64-битной
    if exist "%ProgramFiles(x86)%" (
        set "ARCH=x64"
    ) else (
        set "ARCH=x86"
    )
    
    :: Скачиваем установщик PowerShell
    echo Скачивание установщика PowerShell...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-%ARCH%.msi' -OutFile 'PowerShell.msi'"
    
    :: Устанавливаем PowerShell
    echo Установка PowerShell...
    msiexec /i PowerShell.msi /quiet /norestart
    
    :: Ждем завершения установки
    timeout /t 30
    
    :: Устанавливаем путь к PowerShell
    set "PS_PATH=C:\Program Files\PowerShell\7\pwsh.exe"
)

:: Если PowerShell все еще не найден, выводим сообщение об ошибке
if "%PS_PATH%"=="" (
    echo Ошибка: Не удалось установить PowerShell. Пожалуйста, установите его вручную.
    echo Скачайте и установите PowerShell с сайта: https://aka.ms/install-powershell
    pause
    exit /b 1
)

:: Запускаем скрипт через найденный PowerShell
echo Запуск скрипта через PowerShell...
"%PS_PATH%" -ExecutionPolicy Bypass -File "%~dp0start.ps1"

:: Если произошла ошибка, выводим сообщение
if errorlevel 1 (
    echo Произошла ошибка при выполнении скрипта.
    echo Проверьте, что у вас есть права администратора.
    pause
    exit /b 1
)

pause 