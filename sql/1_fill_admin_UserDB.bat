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
:: Используем старый проверенный метод генерации хеша
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); $base64 = [Convert]::ToBase64String($hash); Set-Content -Path 'hash.txt' -Value $base64"
set /p HASH=<hash.txt
del hash.txt

echo Generated hash: %HASH%

echo Substituting hash into final SQL...
:: Проверяем содержимое HASH переменной
echo HASH variable content: "%HASH%"

:: Проверяем существование шаблона
if not exist ".\sql\UserDb\02_create_admin_credentials_template.sql" (
    echo Error: Template file not found at .\sql\UserDb\02_create_admin_credentials_template.sql
    pause
    exit /b 1
)

:: Заменяем хеш в шаблоне (используем абсолютные пути для надежности)
powershell -Command "$templatePath = Join-Path -Path (Get-Location) -ChildPath '.\sql\UserDb\02_create_admin_credentials_template.sql'; $outputPath = Join-Path -Path (Get-Location) -ChildPath '.\sql\UserDb\02_create_admin_credentials.sql'; (Get-Content $templatePath -Raw) -replace 'СЮДА_ТВОЙ_BASE64_ХЕШ', '%HASH%' | Set-Content $outputPath"

if not exist ".\sql\UserDb\02_create_admin_credentials.sql" (
    echo Error: Failed to create 02_create_admin_credentials.sql
    pause
    exit /b 1
)

echo Verifying generated SQL file...
type ".\sql\UserDb\02_create_admin_credentials.sql"

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

echo Verifying UserDB tables...
if exist ".\sql\UserDb\check_UserDB_tables.bat" (
    call ".\sql\UserDb\check_UserDB_tables.bat"
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Verification script check_UserDB_tables.bat failed.
        pause
        exit /b 1
    )
) else (
    echo Warning: check_UserDB_tables.bat not found in sql\UserDb folder
)

echo Done ✅
pause