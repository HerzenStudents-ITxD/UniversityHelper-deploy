@echo off
echo Launching CommunityDb database fill script...
echo.

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=CommunityDB
set USER_ID=11111111-1111-1111-1111-111111111111

echo Checking existing CommunityDB tables...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; SELECT 'Communities' as TableName, COUNT(*) as Count FROM Communities UNION ALL SELECT 'Agents', COUNT(*) FROM Agents UNION ALL SELECT 'HiddenCommunities', COUNT(*) FROM HiddenCommunities UNION ALL SELECT 'News', COUNT(*) FROM News UNION ALL SELECT 'NewsPhoto', COUNT(*) FROM NewsPhoto UNION ALL SELECT 'Participating', COUNT(*) FROM Participating;"

echo.
echo Cleaning up existing data...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM Participating WHERE UserId = '%USER_ID%'; DELETE FROM News WHERE AuthorId = '%USER_ID%'; DELETE FROM Agents WHERE AgentId = '%USER_ID%'; DELETE FROM HiddenCommunities WHERE UserId = '%USER_ID%'; DELETE FROM Communities WHERE CreatedBy = '%USER_ID%';"

echo.
echo Copying SQL script to container...
docker cp ./CommunityDb/06_setup_community_data.sql %CONTAINER%:/tmp/

echo Executing SQL script...
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/06_setup_community_data.sql

echo.
echo Verifying CommunityDB tables...
call .\check_tables\check_CommunityDB_tables.bat

echo Done ✅