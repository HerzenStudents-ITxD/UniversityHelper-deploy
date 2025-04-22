#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="UserDB"

echo "Checking UserDB tables..."

echo "Users:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Users"

echo "UserCredentials:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM UserCredentials"

echo "UserAvatars:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM UserAvatars"

echo "UserProfiles:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM UserProfiles"

echo "UserSettings:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM UserSettings"

echo "Done ✅"