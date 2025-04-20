@echo off
setlocal EnableDelayedExpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=UserDB
set LOGIN=adminlogin
set PASSWORD=Admin_1234
set SALT=Random_Salt
set USER_ID=11111111-1111-1111-1111-111111111111

:: Генерация base64-хеша (требуется установленный openssl)
for /f "tokens=*" %%i in ('echo|set /p="!LOGIN!!SALT!!PASSWORD!" ^| openssl dgst -sha512 -binary ^| openssl base64') do set HASH=%%i

echo Сгенерирован хеш: %HASH%

:: Подставляем хеш в шаблон
powershell -Command "(Get-Content ./sql/02_create_admin_credentials_template.sql) -replace 'СЮДА_ТВОЙ_BASE64_ХЕШ', '%HASH%' | Set-Content ./sql/02_create_admin_credentials.sql"

echo Копируем SQL-скрипты в контейнер...
docker cp sql/01_create_admin_user.sql %CONTAINER%:/tmp/
docker cp sql/02_create_admin_credentials.sql %CONTAINER%:/tmp/
docker cp sql/03_check_users.sql %CONTAINER%:/tmp/

echo Создаём админ-пользователя...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql

echo Создаём учётные данные админа...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql

echo Проверяем таблицы...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/03_check_users.sql

echo Готово ✅
pause
