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

echo -e "\nUsers:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "SELECT Id, UserName, Email, IsActive FROM Users"

echo -e "\nUsersCredentials:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "SELECT UserId, PasswordHash, SecurityStamp FROM UsersCredentials"

echo -e "\nUsersAvatars:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "SELECT UserId, AvatarUrl, ThumbnailUrl FROM UsersAvatars"

echo -e "\nUsersAdditions:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "SELECT UserId, FirstName, LastName, BirthDate FROM UsersAdditions"

echo -e "\nUsersCommunications:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "SELECT Id, UserId, Type, Value, IsConfirmed FROM UsersCommunications"

echo -e "\nPendingUsers:"
docker exec "$CONTAINER" /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$USER_DB_PASSWORD" -d "$DATABASE" -Q "SELECT Id, Email, ConfirmationCode, ExpirationDate FROM PendingUsers"

echo -e "\nDone ✅"
read -rp "Press Enter to continue"