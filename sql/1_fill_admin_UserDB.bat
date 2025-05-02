@echo off
echo Launching UserDb database fill script...
setlocal enabledelayedexpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=UserDB
set LOGIN=adminlogin
set PASSWORD=Admin_1234
set SALT=Random_Salt
set USER_ID=11111111-1111-1111-1111-111111111111
set INTERNAL_SALT=UniversityHelper.SALT3

echo Checking for PowerShell...
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: PowerShell is not installed or not found in PATH. Please install PowerShell or add it to PATH.
    exit /b 1
)

echo Generating hash...
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); $base64 = [Convert]::ToBase64String($hash); Set-Content -Path 'hash.txt' -Value $base64"
if not exist hash.txt (
    echo Error: Failed to generate hash.txt
    exit /b 1
)
set /p HASH=<hash.txt
del hash.txt

echo Generated hash: %HASH%

echo Substituting hash into final SQL...
powershell -Command "(Get-Content './UserDb/02_create_admin_credentials_template.sql') -replace 'СЮДА_ТВОЙ_BASE64_ХЕШ', '%HASH%' | Set-Content './UserDb/02_create_admin_credentials.sql'"
if not exist .\UserDb\02_create_admin_credentials.sql (
    echo Error: Failed to create 02_create_admin_credentials.sql
    exit /b 1
)

echo Copying SQL scripts to container...
docker cp .\UserDb\01_create_admin_user.sql %CONTAINER%:/tmp/01_create_admin_user.sql
docker cp .\UserDb\02_create_admin_credentials.sql %CONTAINER%:/tmp/02_create_admin_credentials.sql
docker cp .\UserDb\04_setup_admin_user_data.sql %CONTAINER%:/tmp/04_setup_admin_user_data.sql

echo Creating admin user...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql

echo Creating admin credentials...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql

echo Setting up admin user data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM UsersAdditions WHERE UserId = '%USER_ID%'; DELETE FROM UsersCommunications WHERE UserId = '%USER_ID%';"
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_user_data.sql

echo Verifying UserDB tables...
if exist .\UserDb\check_UserDB_tables.bat (
    call .\UserDb\check_UserDB_tables.bat
) else (
    echo Error: check_UserDB_tables.bat not found in UserDb folder
    exit /b 1
)

echo Done ✅
pause