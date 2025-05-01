#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="FeedbackDB"

echo "Copying Feedback SQL scripts to container..."
docker cp ./sql/FeedbackDb/07_setup_feedback_data.sql $CONTAINER:/tmp/

echo "Setting up Feedback tables and data..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/07_setup_feedback_data.sql

echo "Verifying Feedback tables..."
# Add verification script here if needed

echo "Done ✅"