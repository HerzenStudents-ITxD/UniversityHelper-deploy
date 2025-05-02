@echo off
echo Launching CommunityDb database fill script...
setlocal enabledelayedexpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=CommunityDB
set USER_ID=11111111-1111-1111-1111-111111111111

echo Checking existing CommunityDB tables...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; SELECT 'Communities' as TableName, COUNT(*) as Count FROM Communities UNION ALL SELECT 'Agents', COUNT(*) FROM Agents UNION ALL SELECT 'HiddenCommunities', COUNT(*) FROM HiddenCommunities UNION ALL SELECT 'News', COUNT(*) FROM News UNION ALL SELECT 'NewsPhoto', COUNT(*) FROM NewsPhoto UNION ALL SELECT 'Participating', COUNT(*) FROM Participating;"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to check existing CommunityDB tables.
    pause
    exit /b 1
)

echo.
echo Cleaning up existing data...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM Participating WHERE UserId = '%USER_ID%'; DELETE FROM News WHERE AuthorId = '%USER_ID%'; DELETE FROM Agents WHERE AgentId = '%USER_ID%'; DELETE FROM HiddenCommunities WHERE UserId = '%USER_ID%'; DELETE FROM Communities WHERE CreatedBy = '%USER_ID%';"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to clean up existing data.
    pause
    exit /b 1
)

echo.
echo Copying SQL script to container...
if not exist .\sql\CommunityDb\06_setup_community_data.sql (
    echo ERROR: SQL script .\sql\CommunityDb\06_setup_community_data.sql not found.
    pause
    exit /b 1
)
docker cp .\sql\CommunityDb\06_setup_community_data.sql %CONTAINER%:/tmp/06_setup_community_data.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy SQL script to container.
    pause
    exit /b 1
)

echo Executing SQL script...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/06_setup_community_data.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to execute SQL script.
    pause
    exit /b 1
)

echo.
echo Verifying CommunityDB tables...
if exist .\sql\CommunityDb\check_CommunityDB_tables.bat (
    call .\sql\CommunityDb\check_CommunityDB_tables.bat
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Verification script check_CommunityDB_tables.bat failed.
        pause
        exit /b 1
    )
) else (
    echo WARNING: Verification script .\sql\CommunityDb\check_CommunityDB_tables.bat not found.
    :: Uncomment the following block if check_CommunityDB_tables.bat is in check_tables folder
    :: if exist .\check_tables\check_CommunityDB_tables.bat (
    ::     call .\check_tables\check_CommunityDB_tables.bat
    ::     if %ERRORLEVEL% neq 0 (
    ::         echo ERROR: Verification script check_CommunityDB_tables.bat failed.
    ::         pause
    ::         exit /b 1
    ::     )
    :: ) else (
    ::     echo WARNING: Verification script .\check_tables\check_CommunityDB_tables.bat not found.
    :: )
)

echo Done ✅
pause