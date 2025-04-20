#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="UserDB"
LOGIN="adminlogin"
PASSWORD="Admin_1234"
SALT="Random_Salt"
USER_ID="11111111-1111-1111-1111-111111111111"

# Генерация base64-хеша (Linux: sha512sum)
HASH=$(echo -n "$LOGIN$SALT$PASSWORD" | sha512sum | awk '{print $1}' | xxd -r -p | base64)

echo "Сгенерирован хеш: $HASH"

# Подстановка хеша в итоговый SQL
sed "s|СЮДА_ТВОЙ_BASE64_ХЕШ|$HASH|g" ./sql/02_create_admin_credentials_template.sql > ./sql/02_create_admin_credentials.sql

echo "Финальный SQL:"
cat ./sql/02_create_admin_credentials.sql

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
