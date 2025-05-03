@echo off
setlocal enabledelayedexpansion

:: Цвета (только для Windows 10+)
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)
echo off

set "RED=!DEL![91m"
set "GREEN=!DEL![92m"
set "YELLOW=!DEL![93m"
set "NC=!DEL![0m"

:fail
  echo [ERROR] %~1
  exit /b 1
goto :eof

:warn
  echo [WARN] %~1
goto :eof

:check_dependency
  where %1 >nul 2>&1
  if %ERRORLEVEL% neq 0 (
    call :fail "Dependency %1 not found. Please install it first."
  )
goto :eof

:validate_env
  if not defined %~1 (
    call :fail "Environment variable %~1 is not set"
  )
goto :eof