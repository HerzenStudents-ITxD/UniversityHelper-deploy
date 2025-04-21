#!/bin/bash

# Параметры
USER="SA"
PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="UserDB"

# Получаем список таблиц
TABLES=$(docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U $USER -P $PASSWORD -d $DATABASE -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -h-1)

# Для каждой таблицы выводим данные
for TABLE in $TABLES; do
  echo "Таблица: $TABLE"
  docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U $USER -P $PASSWORD -d $DATABASE -Q "SELECT * FROM $TABLE"
  echo "------------------------"
done