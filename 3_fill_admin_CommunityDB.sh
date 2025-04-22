#!/bin/bash

# Variables
USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="CommunityDB"
SQL_SCRIPT="sql/06_setup_community_data.sql"

echo "Installing community data..."

# Check if SQL Server is ready
echo "Waiting for SQL Server to be ready..."
while ! docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -Q "SELECT 1" > /dev/null 2>&1; do
    echo "SQL Server is not ready yet..."
    sleep 5
done
echo "SQL Server is ready!"

# Check existing tables
echo "Checking existing CommunityDB tables..."

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

# Copy SQL script to container
echo -e "\nCopying SQL script to container..."
docker cp $SQL_SCRIPT $CONTAINER:/setup_community_data.sql

# Execute SQL script
echo "Executing SQL script..."
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /setup_community_data.sql

# Verify tables after update
echo -e "\nVerifying CommunityDB tables after update..."
./check_tables/check_CommunityDB_tables.sh

echo "Community data installation completed! ✅" 