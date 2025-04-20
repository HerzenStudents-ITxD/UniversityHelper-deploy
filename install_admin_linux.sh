#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="UserDB"

echo "Копируем SQL-скрипты в контейнер..."
docker cp ./sql/01_create_admin_user.sql $CONTAINER:/tmp/
docker cp ./sql/02_create_admin_credentials.sql $CONTAINER:/tmp/
docker cp ./sql/03_check_users.sql $CONTAINER:/tmp/

echo "Создаём админ-пользователя..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/01_create_admin_user.sql

echo "Создаём учётные данные админа..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/02_create_admin_credentials.sql

echo "Проверяем таблицы..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/03_check_users.sql

echo "Готово ✅"
