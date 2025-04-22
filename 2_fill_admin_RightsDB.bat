@echo off

set RIGHTS_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=RightsDB

echo Checking existing RightsDB tables...

echo Roles:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, Name, Description, IsSystem, CreatedAt, UpdatedAt FROM Roles"

echo.
echo Rights:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "SELECT Id, Name, Description, IsActive FROM Rights"

echo.
echo RolesRights:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "SELECT RoleId, RightId, CreatedAt FROM RolesRights"

echo.
echo UsersRoles:
docker exec %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "SELECT UserId, RoleId, CreatedAt FROM UsersRoles"

echo.
echo Copying SQL script to container...
docker cp ./sql/04_setup_admin_rights.sql %CONTAINER%:/tmp/

echo Setting up admin rights...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_rights.sql

echo Verifying RightsDB tables...
call .\check_tables\check_RightsDB_tables.bat

echo Done ✅
pause 