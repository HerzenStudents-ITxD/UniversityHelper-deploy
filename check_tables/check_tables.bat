$container = "sqlserver_db"
$user = "SA"
$password = "User_1234"
$database = "UserDB"

# Получаем список таблиц
$tables = docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U $user -P $password -d $database -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -h-1

foreach ($table in $tables) {
  Write-Host "Таблица: $table"
  docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U $user -P $password -d $database -Q "SELECT * FROM $table"
  Write-Host "------------------------"
}