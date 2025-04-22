@echo off

set RIGHTS_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=RightsDB
set USER_ID=11111111-1111-1111-1111-111111111111

echo Copying SQL script to container...
docker cp ./sql/05_setup_admin_rights.sql %CONTAINER%:/tmp/

echo Setting up admin rights...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -i /tmp/05_setup_admin_rights.sql

echo Verifying RightsDB tables...
call .\check_tables\check_RightsDB_tables.bat

echo Done ✅
pause 