@echo off

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=RightsDB

echo Checking RightsDB tables...

echo Roles:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, CreatedBy, IsActive FROM Roles"

echo.
echo RolesLocalizations:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, RoleId, Locale, Name FROM RolesLocalizations"

echo.
echo RightsLocalizations:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, RightId, Locale, Name FROM RightsLocalizations"

echo.
echo RolesRights:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, RoleId, RightId, CreatedBy FROM RolesRights"

echo.
echo UsersRoles:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, UserId, RoleId, IsActive FROM UsersRoles"

echo.
echo Done ✅
pause 