#!/bin/bash

execute_sql_file() {
  local container="$1"
  local db="$2"
  local file="$3"
  
  docker exec -i "$container" /opt/mssql-tools/bin/sqlcmd \
    -S localhost -U SA -P "$DB_PASSWORD" \
    -d "$db" -i "$file"
  
  [ $? -ne 0 ] && fail "Failed to execute SQL file: $file"
}

start_transaction() {
  echo "BEGIN TRANSACTION;"
}

commit_transaction() {
  echo "COMMIT;"
}

rollback_on_error() {
  echo "IF @@TRANCOUNT > 0 ROLLBACK;"
}

sql_cleanup() {
  docker exec "$DB_CONTAINER" /bin/bash -c "rm -f /tmp/*.sql"
}