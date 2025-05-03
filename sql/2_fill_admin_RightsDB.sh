#!/bin/bash

RIGHTS_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="RightsDB"
ADMIN_USER_ID="11111111-1111-1111-1111-111111111111"
ADMIN_ROLE_ID="11111111-1111-1111-1111-111111111111"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[DEBUG] Launching RightsDB database fill script..."

echo "[DEBUG] 1. Checking if container $CONTAINER is running..."
if ! docker inspect $CONTAINER >/dev/null 2>&1; then
    echo "ERROR: Container $CONTAINER is not running."
    exit 1
fi

echo "[DEBUG] 2. Checking existing $DATABASE tables..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q \
"USE $DATABASE; \
SELECT 'Roles' AS TableName, COUNT(*) AS Count FROM sys.tables WHERE name = 'Roles' UNION ALL \
SELECT 'RolesLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RolesLocalizations' UNION ALL \
SELECT 'Rights', COUNT(*) FROM sys.tables WHERE name = 'Rights' UNION ALL \
SELECT 'RightsLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RightsLocalizations' UNION ALL \
SELECT 'RolesRights', COUNT(*) FROM sys.tables WHERE name = 'RolesRights' UNION ALL \
SELECT 'UsersRoles', COUNT(*) FROM sys.tables WHERE name = 'UsersRoles';" -s","

echo "[DEBUG] 3. Checking table structure..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q \
"USE $DATABASE; \
SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE \
FROM INFORMATION_SCHEMA.COLUMNS \
WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'Rights', 'RightsLocalizations', 'RolesRights', 'UsersRoles') \
ORDER BY TABLE_NAME, ORDINAL_POSITION;" -s","

echo "[DEBUG] 4. Printing current table contents..."
for table in Rights Roles RolesLocalizations RightsLocalizations RolesRights UsersRoles; do
    echo "[DEBUG] $table table:"
    docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;" -s","
done

echo "[DEBUG] 5. Cleaning up existing data..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q \
"USE $DATABASE; \
IF OBJECT_ID('UsersRoles') IS NOT NULL DELETE FROM UsersRoles WHERE RoleId = '$ADMIN_ROLE_ID'; \
IF OBJECT_ID('RolesRights') IS NOT NULL DELETE FROM RolesRights WHERE RoleId = '$ADMIN_ROLE_ID'; \
IF OBJECT_ID('RolesLocalizations') IS NOT NULL DELETE FROM RolesLocalizations WHERE RoleId = '$ADMIN_ROLE_ID'; \
IF OBJECT_ID('Roles') IS NOT NULL DELETE FROM Roles WHERE Id = '$ADMIN_ROLE_ID'; \
IF OBJECT_ID('RightsLocalizations') IS NOT NULL DELETE FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID'); \
IF OBJECT_ID('Rights') IS NOT NULL DELETE FROM Rights WHERE CreatedBy = '$ADMIN_USER_ID';"

echo "[DEBUG] 6. Copying SQL script to container..."
docker cp "$PROJECT_ROOT/sql/RightsDB/05_setup_admin_rights.sql" $CONTAINER:/tmp/
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy SQL script to container."
    exit 1
fi

echo "[DEBUG] 7. Setting up admin rights..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -i /tmp/05_setup_admin_rights.sql
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set up admin rights."
    exit 1
fi

echo "[DEBUG] 8. Verifying admin rights setup..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q \
"USE $DATABASE; \
IF OBJECT_ID('Roles') IS NOT NULL AND OBJECT_ID('RolesLocalizations') IS NOT NULL \
SELECT r.Id AS RoleId, rl.Name AS RoleName, r.IsActive AS RoleIsActive, COUNT(DISTINCT rr.RightId) AS AssignedRightsCount, COUNT(DISTINCT ur.UserId) AS AssignedUsersCount \
FROM Roles r \
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en' \
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId \
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId \
WHERE r.Id = '$ADMIN_ROLE_ID' \
GROUP BY r.Id, rl.Name, r.IsActive;" -s","

echo "[DEBUG] 9. Printing final table contents..."
for table in Rights Roles RolesLocalizations RightsLocalizations RolesRights UsersRoles; do
    echo "[DEBUG] $table table:"
    docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $RIGHTS_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;" -s","
done

echo "[DEBUG] 10. Running external verification script..."
if [ -f "$PROJECT_ROOT/check_tables/check_RightsDB_tables.sh" ]; then
    "$PROJECT_ROOT/check_tables/check_RightsDB_tables.sh"
else
    echo "WARNING: External verification script not found."
fi

echo "[SUCCESS] Script completed successfully ✅"