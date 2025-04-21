@echo off
setlocal enabledelayedexpansion

set USER_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=UserDB
set USER_ID=11111111-1111-1111-1111-111111111111

echo Копируем SQL-скрипты в контейнер...
docker cp ./sql/04_setup_admin_rights.sql %CONTAINER%:/tmp/
docker cp ./sql/05_setup_admin_user_data.sql %CONTAINER%:/tmp/
docker cp ./sql/03_check_users.sql %CONTAINER%:/tmp/

echo Настраиваем права администратора...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/04_setup_admin_rights.sql

echo Обновляем данные администратора...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/05_setup_admin_user_data.sql

echo Проверяем таблицы...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %USER_DB_PASSWORD% -d %DATABASE% -i /tmp/03_check_users.sql

echo Готово ✅ 