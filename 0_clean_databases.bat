@echo off
setlocal

REM Variables
set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set SQL_SCRIPT=sql\00_clean_databases.sql

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

REM Copy SQL script to container
echo Copying SQL script to container...
docker cp %SQL_SCRIPT% %CONTAINER%:/clean_databases.sql

REM Execute SQL script
echo Executing SQL script...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -i /clean_databases.sql

echo Database cleaning completed! ✅
pause 