@echo off
setlocal enabledelayedexpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=UserDB
set LOGIN=adminlogin
set PASSWORD=Admin_1234
set SALT=Random_Salt
set USER_ID=11111111-1111-1111-1111-111111111111
set INTERNAL_SALT=UniversityHelper.SALT3

echo Генерация хеша...
powershell -Command "$hash = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%SALT%%LOGIN%%PASSWORD%%INTERNAL_SALT%')); $base64 = [Convert]::ToBase64String($hash); Set-Content -Path 'hash.txt' -Value $base64"
set /p HASH=<hash.txt
del hash.txt

echo Сгенерирован хеш: %HASH%

echo Подстановка хеша в итоговый SQL...
powershell -Command "(Get-Content './sql/02_create_admin_credentials_template.sql') -replace 'СЮДА_ТВОЙ_BASE64_ХЕШ', '%HASH%' | Set-Content './sql/02_create_admin_credentials.sql'"

echo Финальный SQL:
type ./sql/02_create_admin_credentials.sql

echo Копируем SQL-скрипты в контейнер...
docker cp ./sql/01_create_admin_user.sql %CONTAINER%:/tmp/
docker cp ./sql/02_create_admin_credentials.sql %CONTAINER%:/tmp/
docker cp ./sql/03_check_users.sql %CONTAINER%:/tmp/

echo Создаём админ-пользователя...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/01_create_admin_user.sql

echo Создаём учётные данные админа...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/02_create_admin_credentials.sql

echo Проверяем таблицы...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/03_check_users.sql

echo Готово ✅
