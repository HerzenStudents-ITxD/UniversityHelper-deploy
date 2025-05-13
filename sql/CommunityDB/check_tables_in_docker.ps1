#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Проверяет структуру базы данных CommunityDB
#>

# Импорт утилит
$utilsPath = Join-Path (Split-Path -Parent $PSScriptRoot) "_utils/SqlDockerUtils.ps1"
if (-not (Test-Path $utilsPath)) {
    Write-Output "ERROR: Utility script not found at: $utilsPath"
    exit 1
}
. $utilsPath

# Диагностика PSScriptRoot
Write-Output "PSScriptRoot: $PSScriptRoot"

# Загрузка переменных окружения
Write-Output "Attempting to load environment variables..."
$envVars = Get-EnvVariables -PSScriptRoot $PSScriptRoot
if (-not $envVars) {
    Write-Output "ERROR: Failed to load environment variables: Get-EnvVariables returned null"
    exit 1
}

$DB_PASSWORD = $envVars['SA_PASSWORD']
$CONTAINER = $envVars['DB_CONTAINER']
$DATABASE = $envVars['COMMUNITYDB_DB_NAME']
$SQL_SCRIPT_NAME = "check_tables.sql"

# Проверка обязательных переменных окружения
Write-Output "Checking required environment variables..."
$requiredVars = @('SA_PASSWORD', 'DB_CONTAINER', 'COMMUNITYDB_DB_NAME')
foreach ($var in $requiredVars) {
    Write-Output "Checking variable: $var = $($envVars[$var])"
    if (-not $envVars[$var]) {
        Write-Error "Missing required environment variable: $var"
        exit 1
    }
}

# Проверка доступности SQL Server
Write-Output "`n[1/3] Checking SQL Server availability in container '$CONTAINER'..."
$serverCheck = Test-SqlServerAvailability -Container $CONTAINER -Password $DB_PASSWORD
if (-not $serverCheck) {
    Write-Output "SQL Server is not responding in container '$CONTAINER'"
    Write-Output "Check if container is running: docker ps -a"
    exit 1
}
Write-Output "SQL Server version:"
Write-Output $serverCheck
Write-Output "SQL Server is available and responding"

# Проверка существования SQL скрипта
Write-Output "`n[2/3] Locating SQL script '$SQL_SCRIPT_NAME'..."
# Измененный путь к SQL скрипту - поднимаемся на уровень выше и идем в _utils
$sqlScriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) "_utils\$SQL_SCRIPT_NAME"
if (-not (Test-Path $sqlScriptPath)) {
    Write-Output "ERROR: SQL script '$SQL_SCRIPT_NAME' not found in: $sqlScriptPath"
    exit 1
}
Write-Output "Script found at: $sqlScriptPath"

# Выполнение SQL скрипта
Write-Output "`n[3/3] Executing SQL script on database '$DATABASE'..."
$scriptResult = Invoke-SqlScript -ScriptPath $sqlScriptPath -Database $DATABASE -Container $CONTAINER -Password $DB_PASSWORD
if ($scriptResult -eq $false) {
    Write-Output "ERROR: Database check failed"
    exit 1
}

Write-Output "`nSQL Script Output:"
Write-Output $scriptResult

Write-Output "`nDatabase check completed successfully"
exit 0