@echo off
echo Launching all database clean script...
setlocal enabledelayedexpansion

REM Variables
set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

echo Cleaning all databases...

REM Check if SQL Server is ready
echo Waiting for SQL Server to be ready...
:wait_loop
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -Q "SELECT 1" > nul 2>&1
if %errorlevel% neq 0 (
    echo SQL Server is not ready yet...
    timeout /t 5 > nul
    goto wait_loop
)
echo SQL Server is ready!

REM Execute clean scripts for each database
call :execute_clean_script "UserDb\00_clean_UserDb.sql"
call :execute_clean_script "CommunityDb\00_clean_CommunityDb.sql"
call :execute_clean_script "RightsDb\00_clean_RightsDb.sql"
call :execute_clean_script "FeedbackDb\00_clean_FeedbackDb.sql"
call :execute_clean_script "MapDb\00_clean_MapDb.sql"

echo All databases cleaning completed! ✅
pause
exit /b 0

:execute_clean_script
set "SQL_SCRIPT=%SCRIPT_DIR%%~1"

REM Verify SQL script exists
if not exist "%SQL_SCRIPT%" (
    echo Error: Clean script not found at: %SQL_SCRIPT%
    exit /b 1
)

echo Processing %~1...

REM Copy SQL script to container
docker cp "%SQL_SCRIPT%" %CONTAINER%:/temp_clean_script.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy SQL script to container
    exit /b 1
)

REM Execute SQL script
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -i /temp_clean_script.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to execute clean script
    exit /b 1
)

REM Clean up
docker exec %CONTAINER% rm -f /temp_clean_script.sql

exit /b 0