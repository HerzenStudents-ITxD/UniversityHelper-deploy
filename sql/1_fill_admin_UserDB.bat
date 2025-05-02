@echo off
echo [DEBUG] Launching UserDb database fill script...
setlocal enabledelayedexpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=UserDB
set LOGIN=adminlogin
set PASSWORD=Admin_1234
set SALT=Random_Salt
set USER_ID=11111111-1111-1111-1111-111111111111
set INTERNAL_SALT=UniversityHelper.SALT3

echo [DEBUG] Current variables:
echo USER_DB_PASSWORD=%USER_DB_PASSWORD%
echo CONTAINER=%CONTAINER%
echo DATABASE=%DATABASE%
echo LOGIN=%LOGIN%
echo PASSWORD=%PASSWORD%
echo SALT=%SALT%
echo USER_ID=%USER_ID%
echo INTERNAL_SALT=%INTERNAL_SALT%

echo [DEBUG] Generating hash...
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); $base64 = [Convert]::ToBase64String($hash); $base64" > hash.txt
set /p HASH=<hash.txt
del hash.txt

echo [DEBUG] Generated hash: %HASH%
echo [DEBUG] Hash length: %HASH:~0,50%... (truncated)

echo [DEBUG] Verifying template file...
if not exist ".\sql\UserDb\02_create_admin_credentials_template.sql" (
    echo [ERROR] Template file not found at: .\sql\UserDb\02_create_admin_credentials_template.sql
    dir ".\sql\UserDb\"
    pause
    exit /b 1
)

echo [DEBUG] Template file content:
type ".\sql\UserDb\02_create_admin_credentials_template.sql"

echo [DEBUG] Substituting hash into final SQL...
powershell -Command "$templatePath = '.\sql\UserDb\02_create_admin_credentials_template.sql'; $outputPath = '.\sql\UserDb\02_create_admin_credentials.sql'; $content = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8); echo '[DEBUG] Before replace:'; echo $content; $newContent = $content -replace 'СЮДА_ТВОЙ_BASE64_ХЕШ', '%HASH%'; echo '[DEBUG] After replace:'; echo $newContent; [System.IO.File]::WriteAllText($outputPath, $newContent, [System.Text.Encoding]::UTF8)"

if not exist ".\sql\UserDb\02_create_admin_credentials.sql" (
    echo [ERROR] Failed to create output SQL file
    pause
    exit /b 1
)

echo [DEBUG] Final SQL file content:
type ".\sql\UserDb\02_create_admin_credentials.sql"

echo [DEBUG] Checking file encoding...
powershell -Command "$path = '.\sql\UserDb\02_create_admin_credentials.sql'; $content = [System.IO.File]::ReadAllBytes($path); echo 'First 3 bytes (BOM):'; $content[0..2]"

echo [DEBUG] Copying SQL scripts to container...
docker cp ".\sql\UserDb\01_create_admin_user.sql" %CONTAINER%:/tmp/01_create_admin_user.sql
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to copy 01_create_admin_user.sql
    pause
    exit /b 1
)

docker cp ".\sql\UserDb\02_create_admin_credentials.sql" %CONTAINER%:/tmp/02_create_admin_credentials.sql
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to copy 02_create_admin_credentials.sql
    pause
    exit /b 1
)

docker cp ".\sql\UserDb\04_setup_admin_user_data.sql" %CONTAINER%:/tmp/04_setup_admin_user_data.sql
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to copy 04_setup_admin_user_data.sql
    pause
    exit /b 1
)

echo [DEBUG] Executing SQL scripts...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql
if %ERRORLEVEL% neq 0 (
    echo [WARNING] Admin user creation returned error (might already exist)
)

docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql
if %ERRORLEVEL% neq 0 (
    echo [WARNING] Admin credentials creation returned error (might already exist)
)

echo [DEBUG] Cleaning up existing user data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM UsersAdditions WHERE UserId = '%USER_ID%'; DELETE FROM UsersCommunications WHERE UserId = '%USER_ID%';"

echo [DEBUG] Setting up admin user data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_user_data.sql
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to set up admin user data
    pause
    exit /b 1
)

echo [SUCCESS] Script completed successfully ✅
pause