#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="RightsDB"

echo "Checking RightsDB tables..."

echo "Roles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, CreatedBy, IsActive FROM Roles"

echo -e "\nRolesLocalizations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RoleId, Locale, Name FROM RolesLocalizations"

echo -e "\nRightsLocalizations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RightId, Locale, Name FROM RightsLocalizations"

echo -e "\nRolesRights:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RoleId, RightId, CreatedBy FROM RolesRights"

echo -e "\nUsersRoles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, UserId, RoleId, IsActive FROM UsersRoles"

echo -e "\nDone ✅" 