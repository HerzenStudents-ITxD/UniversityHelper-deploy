@echo off
setlocal

REM Variables
set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set SQL_SCRIPT=sql\06_setup_community_data.sql

echo Installing community data...

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
docker cp %SQL_SCRIPT% %CONTAINER%:/setup_community_data.sql

REM Execute SQL script
echo Executing SQL script...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -i /setup_community_data.sql

echo Community data installation completed! ✅
pause 