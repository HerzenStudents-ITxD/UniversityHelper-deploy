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

echo [DEBUG] Generating hash...
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); $base64 = [Convert]::ToBase64String($hash); $base64" > hash.txt
set /p HASH=<hash.txt
del hash.txt

echo [DEBUG] Generated hash: %HASH%

echo [DEBUG] Creating new SQL file with hash...
powershell -Command @"
$hash = '%HASH%'
$sql = @"
USE UserDB;

DECLARE @Now DATETIME2 = GETUTCDATE();

INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)
VALUES (
  NEWID(),
  '11111111-1111-1111-1111-111111111111',
  'adminlogin',
  '$hash',
  'Random_Salt',
  1,
  @Now
);

PRINT 'Created admin credentials for login: adminlogin';
"@
[System.IO.File]::WriteAllText('.\sql\UserDb\02_create_admin_credentials.sql', $sql, [System.Text.Encoding]::UTF8)
"@

echo [DEBUG] Final SQL file content:
type ".\sql\UserDb\02_create_admin_credentials.sql"

echo [DEBUG] Copying SQL scripts to container...
docker cp ".\sql\UserDb\01_create_admin_user.sql" %CONTAINER%:/tmp/01_create_admin_user.sql
docker cp ".\sql\UserDb\02_create_admin_credentials.sql" %CONTAINER%:/tmp/02_create_admin_credentials.sql
docker cp ".\sql\UserDb\04_setup_admin_user_data.sql" %CONTAINER%:/tmp/04_setup_admin_user_data.sql

echo [DEBUG] Executing SQL scripts...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM UsersAdditions WHERE UserId = '%USER_ID%'; DELETE FROM UsersCommunications WHERE UserId = '%USER_ID%';"
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_user_data.sql

echo [SUCCESS] Script completed successfully ✅
pause