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

echo Generating hash...
:: Используем более надежный метод генерации хеша
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); $base64 = [Convert]::ToBase64String($hash); Write-Output $base64" > hash.txt
set /p HASH=<hash.txt
del hash.txt

echo Generated hash: %HASH%

echo Verifying template file exists...
if not exist ".\sql\UserDb\02_create_admin_credentials_template.sql" (
    echo Error: Template file not found at .\sql\UserDb\02_create_admin_credentials_template.sql
    pause
    exit /b 1
)

echo Substituting hash into final SQL...
:: Используем более надежный метод замены с явным указанием кодировки
powershell -Command "$template = Get-Content -Path '.\sql\UserDb\02_create_admin_credentials_template.sql' -Raw; $template = $template -replace 'СЮДА_ТВОЙ_BASE64_ХЕШ', '%HASH%'; Set-Content -Path '.\sql\UserDb\02_create_admin_credentials.sql' -Value $template -Encoding UTF8 -NoNewline"

echo Verifying generated SQL file...
if not exist ".\sql\UserDb\02_create_admin_credentials.sql" (
    echo Error: Failed to create credentials SQL file
    pause
    exit /b 1
)

type ".\sql\UserDb\02_create_admin_credentials.sql"

:: Остальная часть скрипта остается без изменений
echo Copying SQL scripts to container...
docker cp ".\sql\UserDb\01_create_admin_user.sql" %CONTAINER%:/tmp/01_create_admin_user.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy 01_create_admin_user.sql to container.
    pause
    exit /b 1
)
docker cp ".\sql\UserDb\02_create_admin_credentials.sql" %CONTAINER%:/tmp/02_create_admin_credentials.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy 02_create_admin_credentials.sql to container.
    pause
    exit /b 1
)
docker cp ".\sql\UserDb\04_setup_admin_user_data.sql" %CONTAINER%:/tmp/04_setup_admin_user_data.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy 04_setup_admin_user_data.sql to container.
    pause
    exit /b 1
)

echo Creating admin user...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create admin user.
    pause
    exit /b 1
)

echo Creating admin credentials...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create admin credentials.
    pause
    exit /b 1
)

echo Setting up admin user data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM UsersAdditions WHERE UserId = '%USER_ID%'; DELETE FROM UsersCommunications WHERE UserId = '%USER_ID%';"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to clean up existing user data.
    pause
    exit /b 1
)
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_user_data.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to set up admin user data.
    pause
    exit /b 1
)

echo Done ✅
pause