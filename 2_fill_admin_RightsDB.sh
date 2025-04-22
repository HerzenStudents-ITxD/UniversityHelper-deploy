#!/bin/bash

RIGHTS_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="RightsDB"

echo "Checking existing RightsDB tables..."

echo "Roles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, Description, IsSystem, CreatedAt, UpdatedAt FROM Roles"

echo -e "\nRights:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, Description, IsActive FROM Rights"

echo -e "\nRolesRights:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT RoleId, RightId, CreatedAt FROM RolesRights"

echo -e "\nUsersRoles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "SELECT UserId, RoleId, CreatedAt FROM UsersRoles"

echo -e "\nCopying SQL script to container..."
docker cp UniversityHelper-deploy/sql/04_setup_admin_rights.sql $CONTAINER:/tmp/

echo "Setting up admin rights..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -i /tmp/04_setup_admin_rights.sql

echo "Verifying RightsDB tables..."
./UniversityHelper-deploy/check_tables/check_RightsDB_tables.sh

echo "Done ✅" 