# PowerShell Core скрипт для очистки всех баз данных
Write-Host "Запуск скрипта очистки всех баз данных..."

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

# Проверка корректности переменных окружения
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ОШИБКА: Переменная окружения ${var} не установлена."
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
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

# Ожидание готовности SQL Server
Write-Host "Ожидание готовности SQL Server..."
$maxAttempts = 12
$attempt = 1
while ($attempt -le $maxAttempts) {
    $result = docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -Q "SELECT 1" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SQL Server готов!"
        break
    }
    Write-Host "SQL Server пока не готов... (Попытка ${attempt}/${maxAttempts})"
    Start-Sleep -Seconds 5
    $attempt++
}
if ($attempt -gt $maxAttempts) {
    Write-Error "ОШИБКА: SQL Server не стал готов после ${maxAttempts} попыток."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Выполнение скриптов очистки для каждой базы данных
$cleanScripts = @(
    "UserDB\00_clean_UserDB.sql",
    "CommunityDB\00_clean_CommunityDB.sql",
    "RightsDB\00_clean_RightsDB.sql",
    "FeedbackDB\00_clean_FeedbackDB.sql",
    "MapDB\00_clean_MapDB.sql"
)

Write-Host "Очистка всех баз данных..."
foreach ($script in $cleanScripts) {
    $success = Execute-CleanScript -RelativePath $script
    if (-not $success) {
        Write-Error "ОШИБКА: Не удалось выполнить скрипт очистки ${script}"
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
}

Write-Host "Очистка всех баз данных завершена! ✅"
Read-Host "Нажмите Enter для продолжения..."
exit 0

function Execute-CleanScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $sqlScript = Join-Path $scriptDir $RelativePath

    if (-not (Test-Path $sqlScript)) {
        Write-Error "ОШИБКА: Скрипт очистки не найден по пути: ${sqlScript}"
        return $false
    }

    Write-Host "Обработка ${RelativePath}..."

    docker cp $sqlScript "${container}:/temp_clean_script.sql"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ОШИБКА: Не удалось скопировать SQL-скрипт в контейнер"
        return $false
    }

    docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $password -i /temp_clean_script.sql
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ОШИБКА: Не удалось выполнить скрипт очистки"
        return $false
    }

    docker exec $container rm -f /temp_clean_script.sql | Out-Null
    return $true
}