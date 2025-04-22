#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="CommunityDB"

echo "Checking CommunityDB tables..."

echo "Communities:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Communities"

echo "CommunityAvatars:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM CommunityAvatars"

echo "CommunityAgents:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM CommunityAgents"

echo "Posts:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Posts"

echo "PostAttachments:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM PostAttachments"

echo "PostParticipants:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM PostParticipants"

echo "PostLocations:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM PostLocations"

echo "HiddenCommunities:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM HiddenCommunities"

echo "Done ✅" 