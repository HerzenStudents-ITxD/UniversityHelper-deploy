@echo off
echo Launching UserDb database fill script...
echo.

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=UserDB
set LOGIN=adminlogin
set PASSWORD=Admin_1234
set SALT=Random_Salt
set USER_ID=11111111-1111-1111-1111-111111111111
set INTERNAL_SALT=UniversityHelper.SALT3

echo Generating hash...
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); $base64 = [Convert]::ToBase64String($hash); Set-Content -Path 'hash.txt' -Value $base64"
set /p HASH=<hash.txt
del hash.txt

echo Generated hash: %HASH%

echo Substituting hash into final SQL...
powershell -Command "(Get-Content './UserDb/02_create_admin_credentials_template.sql') -replace 'СЮДА_ТВОЙ_BASE64_ХЕШ', '%HASH%' | Set-Content './UserDb/02_create_admin_credentials.sql'"

echo Copying SQL scripts to container...
docker cp ./UserDb/01_create_admin_user.sql %CONTAINER%:/tmp/
docker cp ./UserDb/02_create_admin_credentials.sql %CONTAINER%:/tmp/
docker cp ./UserDb/04_setup_admin_user_data.sql %CONTAINER%:/tmp/

echo Creating admin user...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql

echo Creating admin credentials...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql

echo Setting up admin user data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM UsersAdditions WHERE UserId = '%USER_ID%'; DELETE FROM UsersCommunications WHERE UserId = '%USER_ID%';"
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_user_data.sql

echo Verifying UserDB tables...
call .\check_tables\check_UserDB_tables.bat

echo Done ✅