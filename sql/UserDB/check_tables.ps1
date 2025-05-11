#!/bin/bash

# UserDB checker script (Bash version)

# Read .env file located one directory above
ENV_FILE="$(dirname "$0")/../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Could not find .env file at $ENV_FILE" >&2
    exit 1
fi

# Parse .env file
while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip comments and empty lines
    [[ $key =~ ^# ]] || [[ -z $key ]] && continue
    # Remove quotes if present
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    export "$key=$value"
done < "$ENV_FILE"

# Set variables from .env with defaults
USER_DB_PASSWORD="${SA_PASSWORD:-User_1234}"
CONTAINER="${DB_CONTAINER:-sqlserver_db}"
DATABASE="${USERDB_DB_NAME:-UserDB}"

echo "Checking UserDB tables..."

# Проверка существования базы данных
echo -e "\nChecking if database exists..."
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -Q "IF DB_ID('$DATABASE') IS NOT NULL SELECT 'Database exists' AS message ELSE SELECT 'Database does not exist' AS message"

# Проверка существования таблиц
echo -e "\nChecking tables existence..."
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "
SELECT 
    t.name AS table_name,
    CASE WHEN t.name IS NOT NULL THEN 'Exists' ELSE 'Does not exist' END AS status
FROM 
    sys.tables t
WHERE 
    t.name IN ('Users', 'UsersCredentials', 'UsersAvatars', 'UsersAdditions', 'UsersCommunications', 'PendingUsers')
"

# Проверка содержимого таблиц (только если они существуют)
echo -e "\nUsers:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
    SELECT * FROM Users
ELSE
    SELECT 'Table Users does not exist' AS message
"

echo -e "\nUsersCredentials:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersCredentials')
    SELECT * FROM UsersCredentials
ELSE
    SELECT 'Table UsersCredentials does not exist' AS message
"

echo -e "\nUsersAvatars:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersAvatars')
    SELECT * FROM UsersAvatars
ELSE
    SELECT 'Table UsersAvatars does not exist' AS message
"

echo -e "\nUsersAdditions:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersAdditions')
    SELECT * FROM UsersAdditions
ELSE
    SELECT 'Table UsersAdditions does not exist' AS message
"

echo -e "\nUsersCommunications:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersCommunications')
    SELECT * FROM UsersCommunications
ELSE
    SELECT 'Table UsersCommunications does not exist' AS message
"

echo -e "\nPendingUsers:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PendingUsers')
    SELECT * FROM PendingUsers
ELSE
    SELECT 'Table PendingUsers does not exist' AS message
"

echo -e "\nDone ✅"
read -rp "Press Enter to continue"