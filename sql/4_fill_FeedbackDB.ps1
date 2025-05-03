# PowerShell Core скрипт для настройки базы данных FeedbackDB
Write-Host "Запуск скрипта заполнения базы данных FeedbackDB..."

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
$database = $env:FEEDBACKDB_DB_NAME

# Проверка корректности переменных окружения
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "FEEDBACKDB_DB_NAME")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ОШИБКА: Переменная окружения ${var} не установлена."
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
}

# Проверка, что имя базы данных корректно
if ($database -ne "FeedbackDB") {
    Write-Error "ОШИБКА: Имя базы данных (${database}) не соответствует ожидаемому 'FeedbackDB'."
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
        $_ -notmatch "^(name)\s*$" 
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
if ($dbExists -notmatch "FeedbackDB") {
    Write-Error "ОШИБКА: База данных ${database} не найдена. Очищенный список баз данных: ${dbExists}"
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Копирование SQL-скрипта в контейнер
Write-Host "Копирование SQL-скрипта в контейнер..."
$sqlScriptPath = Join-Path $scriptDir "sql\FeedbackDB\07_setup_feedback_data.sql"
if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ОШИБКА: SQL-скрипт ${sqlScriptPath} не найден."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}
docker cp $sqlScriptPath "${container}:/tmp/07_setup_feedback_data.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Не удалось скопировать SQL-скрипт в контейнер."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Выполнение SQL-скрипта
Write-Host "Настройка таблиц и данных FeedbackDB..."
$setupQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '${password}' -d ${database} -i /tmp/07_setup_feedback_data.sql"
$result = docker exec -it $container bash -c $setupQuery 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Не удалось выполнить SQL-скрипт. Подробности: ${result}"
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка таблиц FeedbackDB
Write-Host "Проверка таблиц FeedbackDB..."
$verifyScriptPath = Join-Path $scriptDir "sql\FeedbackDB\check_FeedbackDB_tables.bat"
if (Test-Path $verifyScriptPath) {
    Write-Host "Выполнение внешнего скрипта проверки..."
    # Запуск BAT-скрипта через cmd
    cmd /c $verifyScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ОШИБКА: Скрипт проверки check_FeedbackDB_tables.bat завершился с ошибкой."
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
} else {
    Write-Warning "ПРЕДУПРЕЖДЕНИЕ: Скрипт проверки ${verifyScriptPath} не найден."
}

Write-Host "Готово ✅"
Read-Host "Нажмите Enter для продолжения..."
exit 0