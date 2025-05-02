@echo off
echo Launching all database fill scripts...
echo.

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

:: List of scripts to execute (in order)
set SCRIPT1=%SCRIPT_DIR%1_fill_admin_UserDB.bat
set SCRIPT2=%SCRIPT_DIR%2_fill_admin_RightsDB.bat
set SCRIPT3=%SCRIPT_DIR%3_fill_admin_CommunityDB.bat
set SCRIPT4=%SCRIPT_DIR%4_fill_FeedbackDB.bat

:: Function to run each script
call :run_script "%SCRIPT1%"
call :run_script "%SCRIPT2%"
call :run_script "%SCRIPT3%"
call :run_script "%SCRIPT4%"

echo.
echo All databases filled successfully!
pause
exit /b 0

:run_script
echo [Executing] %~1
if not exist "%~1" (
    echo [Error] Script "%~1" not found!
    echo [Debug] Current directory: %cd%
    echo [Debug] Script directory: %SCRIPT_DIR%
    exit /b 1
)
pushd "%SCRIPT_DIR%"
call "%~1"
if %errorlevel% neq 0 (
    echo [Error] Script "%~1" failed with code %errorlevel%
    popd
    exit /b %errorlevel%
)
popd
echo [Success] %~1 completed
echo.
goto :eof