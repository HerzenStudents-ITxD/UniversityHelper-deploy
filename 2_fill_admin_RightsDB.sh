#!/bin/bash

RIGHTS_DB_PASSWORD="Rights_1234"
CONTAINER="sqlserver_db"
DATABASE="RightsDB"

echo "Checking existing RightsDB tables..."

echo "Roles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT Id, CreatedBy, IsActive FROM Roles"

echo -e "\nRolesLocalizations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RoleId, Locale, Name FROM RolesLocalizations"

echo -e "\nRightsLocalizations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RightId, Locale, Name FROM RightsLocalizations"

echo -e "\nRolesRights:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RoleId, RightId, CreatedBy FROM RolesRights"

echo -e "\nUsersRoles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT Id, UserId, RoleId, IsActive FROM UsersRoles"

echo -e "\nCopying SQL scripts to container..."
docker cp ./sql/04_setup_admin_rights.sql $CONTAINER:/tmp/

echo "Setting up admin rights..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -i /tmp/04_setup_admin_rights.sql

echo "Verifying RightsDB tables..."
./check_tables/check_RightsDB_tables.sh

echo "Done ✅" 