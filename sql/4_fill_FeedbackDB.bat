@echo off
echo Launching FeedbackDB database fill script...
setlocal enabledelayedexpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=FeedbackDB

echo Copying Feedback SQL scripts to container...
if not exist .\sql\FeedbackDB\07_setup_feedback_data.sql (
    echo ERROR: SQL script .\sql\FeedbackDB\07_setup_feedback_data.sql not found.
    pause
    exit /b 1
)
docker cp .\sql\FeedbackDB\07_setup_feedback_data.sql %CONTAINER%:/tmp/07_setup_feedback_data.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy SQL script to container.
    pause
    exit /b 1
)

echo Setting up Feedback tables and data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/07_setup_feedback_data.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to execute SQL script.
    pause
    exit /b 1
)

echo Verifying Feedback tables...
if exist .\sql\FeedbackDB\check_FeedbackDB_tables.bat (
    echo Running verification script...
    call .\sql\FeedbackDB\check_FeedbackDB_tables.bat
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Verification script check_FeedbackDB_tables.bat failed.
        pause
        exit /b 1
    )
) else (
    echo WARNING: Verification script .\sql\FeedbackDB\check_FeedbackDB_tables.bat not found.
)

:: Note: If check_FeedbackDB_tables.bat is in check_tables folder, replace the above block with:
:: if exist .\check_tables\check_FeedbackDB_tables.bat (
::     echo Running verification script...
::     call .\check_tables\check_FeedbackDB_tables.bat
::     if %ERRORLEVEL% neq 0 (
::         echo ERROR: Verification script check_FeedbackDB_tables.bat failed.
::         pause
::         exit /b 1
::     )
:: ) else (
::     echo WARNING: Verification script .\check_tables\check_FeedbackDB_tables.bat not found.
:: )

echo Done ✅
pause