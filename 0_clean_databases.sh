#!/bin/bash

# Variables
USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
SQL_SCRIPT="UniversityHelper-deploy/sql/00_clean_databases.sql"

echo "Cleaning all databases..."

# Check if SQL Server is ready
echo "Waiting for SQL Server to be ready..."
while ! docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -Q "SELECT 1" > /dev/null 2>&1; do
    echo "SQL Server is not ready yet..."
    sleep 5
done
echo "SQL Server is ready!"

# Copy SQL script to container
echo "Copying SQL script to container..."
docker cp $SQL_SCRIPT $CONTAINER:/clean_databases.sql

# Execute SQL script
echo "Executing SQL script..."
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -i /clean_databases.sql

echo "Database cleaning completed! ✅" 