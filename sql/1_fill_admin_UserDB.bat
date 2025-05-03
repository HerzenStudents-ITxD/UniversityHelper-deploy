@echo off
echo [DEBUG] Launching UserDB database fill script...
setlocal enabledelayedexpansion

:: Конфигурационные параметры
set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=UserDB
set LOGIN=adminlogin
set PASSWORD=Admin_1234
set SALT=Random_Salt
set USER_ID=11111111-1111-1111-1111-111111111111
set INTERNAL_SALT=UniversityHelper.SALT3

echo [DEBUG] 1. Generating SHA512 hash...
:: Генерация хеша с сохранением во временный файл
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); [Convert]::ToBase64String($hash) | Out-File 'hash.txt' -Encoding ASCII"
set /p HASH=<hash.txt
del hash.txt
echo [DEBUG] Generated hash: %HASH%

echo [DEBUG] 2. Preparing SQL content...
:: Создаем временный файл с SQL-запросом
echo USE UserDB;> temp.sql
echo DECLARE @Now DATETIME2 = GETUTCDATE();>> temp.sql
echo INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)>> temp.sql
echo VALUES (>> temp.sql
echo   NEWID(),>> temp.sql
echo   '11111111-1111-1111-1111-111111111111',>> temp.sql
echo   'adminlogin',>> temp.sql
echo   '%HASH%',>> temp.sql
echo   'Random_Salt',>> temp.sql
echo   1,>> temp.sql
echo   @Now>> temp.sql
echo );>> temp.sql
echo PRINT 'Created admin credentials for login: adminlogin';>> temp.sql

:: Конвертируем в UTF-8 без BOM
powershell -Command "[System.IO.File]::WriteAllText('.\sql\UserDB\02_create_admin_credentials.sql', [System.IO.File]::ReadAllText('temp.sql'), [System.Text.Encoding]::UTF8)"
del temp.sql

echo [DEBUG] 3. Verifying generated SQL file...
type ".\sql\UserDB\02_create_admin_credentials.sql"

echo [DEBUG] 4. Checking file encoding...
powershell -Command "$bytes = [System.IO.File]::ReadAllBytes('.\sql\UserDB\02_create_admin_credentials.sql'); 'First 3 bytes (BOM): ' + $bytes[0] + ' ' + $bytes[1] + ' ' + $bytes[2]"

echo [DEBUG] 5. Copying SQL scripts to container...
docker cp ".\sql\UserDB\01_create_admin_user.sql" %CONTAINER%:/tmp/01_create_admin_user.sql
docker cp ".\sql\UserDB\02_create_admin_credentials.sql" %CONTAINER%:/tmp/02_create_admin_credentials.sql
docker cp ".\sql\UserDB\04_setup_admin_user_data.sql" %CONTAINER%:/tmp/04_setup_admin_user_data.sql

echo [DEBUG] 6. Executing SQL scripts...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; DELETE FROM UsersAdditions WHERE UserId = '%USER_ID%'; DELETE FROM UsersCommunications WHERE UserId = '%USER_ID%';"
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_user_data.sql

echo [SUCCESS] Script completed successfully ✅
pause