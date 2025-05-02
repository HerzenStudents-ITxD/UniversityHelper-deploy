#!/bin/bash

RIGHTS_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="RightsDB"
USER_ID="11111111-1111-1111-1111-111111111111"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "\nChecking existing RightsDB tables..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT 'Roles' as TableName, COUNT(*) as Count FROM Roles UNION ALL SELECT 'RolesLocalizations', COUNT(*) FROM RolesLocalizations UNION ALL SELECT 'RightsLocalizations', COUNT(*) FROM RightsLocalizations UNION ALL SELECT 'RolesRights', COUNT(*) FROM RolesRights UNION ALL SELECT 'UsersRoles', COUNT(*) FROM UsersRoles;"

echo -e "\nChecking table structure..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'RightsLocalizations', 'RolesRights', 'UsersRoles') ORDER BY TABLE_NAME, ORDINAL_POSITION;"

echo -e "\nCreating tables if they don't exist..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles') 
  CREATE TABLE Roles (Id uniqueidentifier PRIMARY KEY, IsActive bit NOT NULL); 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations') 
  CREATE TABLE RolesLocalizations (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, Locale nvarchar(10) NOT NULL, Name nvarchar(100) NOT NULL, CreatedBy uniqueidentifier NOT NULL); 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations') 
  CREATE TABLE RightsLocalizations (Id uniqueidentifier PRIMARY KEY, RightId int NOT NULL, Locale nvarchar(10) NOT NULL, Name nvarchar(100) NOT NULL, Description nvarchar(255) NULL); 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights') 
  CREATE TABLE RolesRights (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, RightId int NOT NULL, CreatedBy uniqueidentifier NOT NULL); 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles') 
  CREATE TABLE UsersRoles (Id uniqueidentifier PRIMARY KEY, UserId uniqueidentifier NOT NULL, RoleId uniqueidentifier NOT NULL, IsActive bit NOT NULL);"

echo -e "\nPrinting current table contents..."
echo -e "\nRoles table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM Roles;"

echo -e "\nRolesLocalizations table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM RolesLocalizations;"

echo -e "\nRightsLocalizations table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM RightsLocalizations;"

echo -e "\nRolesRights table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM RolesRights;"

echo -e "\nUsersRoles table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM UsersRoles;"

echo -e "\nCleaning up existing data..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; 
DELETE FROM UsersRoles WHERE UserId = '$USER_ID'; 
DELETE FROM RolesRights WHERE RoleId = '$USER_ID'; 
DELETE FROM RolesLocalizations WHERE RoleId = '$USER_ID'; 
DELETE FROM Roles WHERE Id = '$USER_ID';"

echo -e "\nCopying SQL script to container..."
docker cp "$PROJECT_ROOT/RightsDb/05_setup_admin_rights.sql" $CONTAINER:/tmp/

echo "Setting up admin rights..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -i /tmp/05_setup_admin_rights.sql

echo -e "\nVerifying RightsDB tables..."
"$PROJECT_ROOT/check_tables/check_RightsDB_tables.sh"

echo -e "\nVerifying admin rights setup..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; 
SELECT r.Id as RoleId, rl.Name as RoleName, r.IsActive as RoleIsActive, 
COUNT(DISTINCT rr.RightId) as AssignedRightsCount, 
COUNT(DISTINCT ur.UserId) as AssignedUsersCount 
FROM Roles r 
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en' 
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId 
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId 
WHERE r.Id = '$USER_ID' 
GROUP BY r.Id, rl.Name, r.IsActive;"

echo -e "\nVerifying data integrity..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; 
SELECT 'Roles' as TableName, COUNT(*) as Count FROM Roles WHERE Id = '$USER_ID' 
UNION ALL SELECT 'RolesLocalizations', COUNT(*) FROM RolesLocalizations WHERE RoleId = '$USER_ID' 
UNION ALL SELECT 'RolesRights', COUNT(*) FROM RolesRights WHERE RoleId = '$USER_ID' 
UNION ALL SELECT 'UsersRoles', COUNT(*) FROM UsersRoles WHERE UserId = '$USER_ID';"

echo -e "\nPrinting final table contents..."
echo -e "\nRoles table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM Roles;"

echo -e "\nRolesLocalizations table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM RolesLocalizations;"

echo -e "\nRightsLocalizations table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM RightsLocalizations;"

echo -e "\nRolesRights table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM RolesRights;"

echo -e "\nUsersRoles table:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; SELECT * FROM UsersRoles;"

echo "Done ✅"