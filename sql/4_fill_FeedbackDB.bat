@echo off
echo Launching FeedbackDb database fill script...
setlocal enabledelayedexpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=FeedbackDB

echo Copying Feedback SQL scripts to container...
docker cp ./FeedbackDb/07_setup_feedback_data.sql %CONTAINER%:/tmp/

echo Setting up Feedback tables and data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/07_setup_feedback_data.sql

echo Verifying Feedback tables...
REM Add verification script here if needed

echo Done ✅