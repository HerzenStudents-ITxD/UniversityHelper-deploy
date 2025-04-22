#!/bin/bash

RIGHTS_DB_PASSWORD="Rights_1234"
CONTAINER="sqlserver_db"
DATABASE="RightsDB"
USER_ID="11111111-1111-1111-1111-111111111111"

echo -e "\nChecking existing RightsDB tables..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT 'Roles' as TableName, COUNT(*) as Count FROM Roles UNION ALL SELECT 'RolesLocalizations', COUNT(*) FROM RolesLocalizations UNION ALL SELECT 'RightsLocalizations', COUNT(*) FROM RightsLocalizations UNION ALL SELECT 'RolesRights', COUNT(*) FROM RolesRights UNION ALL SELECT 'UsersRoles', COUNT(*) FROM UsersRoles;"

echo -e "\nCleaning up existing data..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; DELETE FROM UsersRoles WHERE UserId = '$USER_ID'; DELETE FROM RolesRights WHERE RoleId = '$USER_ID'; DELETE FROM RolesLocalizations WHERE RoleId = '$USER_ID'; DELETE FROM Roles WHERE Id = '$USER_ID';"

echo -e "\nCopying SQL script to container..."
docker cp ./sql/05_setup_admin_rights.sql $CONTAINER:/tmp/

echo "Setting up admin rights..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -i /tmp/05_setup_admin_rights.sql

echo "Verifying RightsDB tables..."
./check_tables/check_RightsDB_tables.sh

echo "Done ✅" 