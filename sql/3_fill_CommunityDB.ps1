# PowerShell Core скрипт для настройки базы данных CommunityDB
Write-Host "Запуск скрипта заполнения базы данных CommunityDB..."

# Загрузка переменных окружения из файла .env в директории скрипта
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "ОШИБКА: Файл .env не найден по пути ${envFile}"
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)\s*=\s*(.+?)\s*$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Конфигурация из .env
$container = $env:DB_CONTAINER
$password = $env:SA_PASSWORD
$database = $env:COMMUNITYDB_DB_NAME
$userId = $env:COMMUNITYDB_ADMIN_USER_ID

# Проверка корректности переменных окружения
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "COMMUNITYDB_DB_NAME", "COMMUNITYDB_ADMIN_USER_ID")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ОШИБКА: Переменная окружения ${var} не установлена."
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
}

# Проверка, что имя базы данных корректно
if ($database -ne "CommunityDB") {
    Write-Error "ОШИБКА: Имя базы данных (${database}) не соответствует ожидаемому 'CommunityDB'."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка наличия Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "ОШИБКА: Docker не установлен или отсутствует в PATH."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка, что контейнер запущен
Write-Host "Проверка, запущен ли контейнер ${container}..."
$containerStatus = docker inspect $container 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Контейнер ${container} не запущен."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Функция для выполнения SQL-команд
function Invoke-SqlCmd {
    param($Query, $Database = $database)
    $sqlcmd = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${Database} -Q `"${Query}`" -s',' -W"
    Write-Host "Выполнение SQL: ${Query}"
    $result = docker exec -it $container bash -c $sqlcmd 2>&1
    Write-Host "Результат SQL: ${result}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ОШИБКА: Не удалось выполнить SQL-команду. Подробности: ${result}"
        return $false
    }
    # Очистка результата от заголовков, разделителей и лишних строк
    $cleanResult = ($result -split "`n" | Where-Object { 
        $_ -notmatch "^\s*(\(|\-\-|$)" -and 
        $_ -notmatch "rows affected" -and 
        $_ -notmatch "^(TableName|Count|name)\s*$" 
    } | ForEach-Object { $_.Trim() }) -join "`n"
    Write-Host "Очищенный результат SQL: ${cleanResult}"
    return $cleanResult
}

# Проверка подключения к SQL Server
Write-Host "Проверка подключения к SQL Server..."
$testQuery = "SELECT 1 AS Test"
if (-not (Invoke-SqlCmd -Query $testQuery -Database "master")) {
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка существования базы данных
Write-Host "Проверка существования базы данных ${database}..."
$checkDbQuery = "SELECT name FROM sys.databases WHERE name = '${database}'"
$dbExists = Invoke-SqlCmd -Query $checkDbQuery -Database "master"
if ($dbExists -notmatch "CommunityDB") {
    Write-Error "ОШИБКА: База данных ${database} не найдена. Очищенный список баз данных: ${dbExists}"
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка существующих таблиц
Write-Host "Проверка существующих таблиц в базе ${database}..."
$checkTablesQuery = "USE ${database}; SELECT 'Communities' AS TableName, COUNT(*) AS Count FROM Communities UNION ALL SELECT 'Agents', COUNT(*) FROM Agents UNION ALL SELECT 'HiddenCommunities', COUNT(*) FROM HiddenCommunities UNION ALL SELECT 'News', COUNT(*) FROM News UNION ALL SELECT 'NewsPhoto', COUNT(*) FROM NewsPhoto UNION ALL SELECT 'Participating', COUNT(*) FROM Participating;"
if (-not (Invoke-SqlCmd $checkTablesQuery)) {
    Write-Error "ОШИБКА: Не удалось проверить существующие таблицы CommunityDB."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Очистка существующих данных
Write-Host "Очистка существующих данных..."
$cleanupQuery = "USE ${database}; DELETE FROM Participating WHERE UserId = '${userId}'; DELETE FROM News WHERE AuthorId = '${userId}'; DELETE FROM Agents WHERE AgentId = '${userId}'; DELETE FROM HiddenCommunities WHERE UserId = '${userId}'; DELETE FROM Communities WHERE CreatedBy = '${userId}';"
if (-not (Invoke-SqlCmd $cleanupQuery)) {
    Write-Error "ОШИБКА: Не удалось очистить существующие данные."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Копирование SQL-скрипта в контейнер
Write-Host "Копирование SQL-скрипта в контейнер..."
$sqlScriptPath = Join-Path $scriptDir "CommunityDB\06_setup_community_data.sql"
if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ОШИБКА: SQL-скрипт ${sqlScriptPath} не найден."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}
docker cp $sqlScriptPath "${container}:/tmp/06_setup_community_data.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Не удалось скопировать SQL-скрипт в контейнер."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Выполнение SQL-скрипта
Write-Host "Выполнение SQL-скрипта..."
$setupQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${database} -i /tmp/06_setup_community_data.sql"
$result = docker exec -it $container bash -c $setupQuery 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Не удалось выполнить SQL-скрипт. Подробности: ${result}"
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка таблиц CommunityDB
Write-Host "Проверка таблиц CommunityDB..."
$verifyScriptPath = Join-Path $scriptDir "sql\CommunityDB\check_CommunityDB_tables.bat"
if (Test-Path $verifyScriptPath) {
    Write-Host "Выполнение внешнего скрипта проверки..."
    # Запуск BAT-скрипта через cmd
    cmd /c $verifyScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ОШИБКА: Скрипт проверки check_CommunityDB_tables.bat завершился с ошибкой."
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
} else {
    Write-Warning "ПРЕДУПРЕЖДЕНИЕ: Скрипт проверки ${verifyScriptPath} не найден."
}

Write-Host "Готово ✅"
Read-Host "Нажмите Enter для продолжения..."
exit 0