@echo off
setlocal

REM Variables
set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=CommunityDB
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

REM Check existing tables
echo Checking existing CommunityDB tables...

echo Communities:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, Name, Avatar, CreatedBy, CreatedAtUtc FROM Communities"

echo.
echo Agents:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, AgentId, CommunityId FROM Agents"

echo.
echo HiddenCommunities:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, UserId, CommunityId FROM HiddenCommunities"

echo.
echo News:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, Title, Text, AuthorId, CommunityId FROM News"

echo.
echo NewsPhoto:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, Photo, NewsId FROM NewsPhoto"

echo.
echo Participating:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, UserId, NewsId FROM Participating"

REM Copy SQL script to container
echo.
echo Copying SQL script to container...
docker cp %SQL_SCRIPT% %CONTAINER%:/setup_community_data.sql

REM Execute SQL script
echo Executing SQL script...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /setup_community_data.sql

REM Verify tables after update
echo.
echo Verifying CommunityDB tables after update...
call .\check_tables\check_CommunityDB_tables.bat

echo Community data installation completed! ✅
pause 