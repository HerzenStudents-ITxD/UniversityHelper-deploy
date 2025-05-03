@echo off

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=CommunityDB

echo Checking CommunityDB tables...

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

echo.
echo Done ✅
pause 