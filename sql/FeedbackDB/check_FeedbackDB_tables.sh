#!/bin/bash

FEEDBACK_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="FeedbackDB"

echo "Checking Feedback Service tables..."

echo "Feedback:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Feedback"

echo "Images:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Images"

echo "Types:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Types"

echo "FeedbackTypes:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM FeedbackTypes"

echo "Done ✅"