#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="CommunityDB"

echo "Checking CommunityDB tables..."

echo "Communities:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, Avatar, CreatedBy, CreatedAtUtc FROM Communities"

echo -e "\nAgents:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, AgentId, CommunityId FROM Agents"

echo -e "\nHiddenCommunities:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, UserId, CommunityId FROM HiddenCommunities"

echo -e "\nNews:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Title, Text, AuthorId, CommunityId FROM News"

echo -e "\nNewsPhoto:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Photo, NewsId FROM NewsPhoto"

echo -e "\nParticipating:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, UserId, NewsId FROM Participating"

echo -e "\nDone ✅" 