#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Проверяет структуру базы данных MapDB
#>

# Импорт утилит
$utilsPath = Join-Path (Split-Path -Parent $PSScriptRoot) "_utils/SqlDockerUtils.ps1"
. $utilsPath

# Загрузка переменных окружения
$envVars = Get-EnvVariables -PSScriptRoot $PSScriptRoot

$DB_PASSWORD = $envVars['SA_PASSWORD']
$CONTAINER = $envVars['DB_CONTAINER']
$DATABASE = $envVars['MAPDB_DB_NAME']
$SQL_SCRIPT_NAME = "check_tables.sql"

# Проверка доступности SQL Server
if (-not (Test-SqlServerAvailability -Container $CONTAINER -Password $DB_PASSWORD)) {
    exit 1
}

# Проверка существования SQL скрипта
$sqlScriptPath = Test-SqlScriptExists -PSScriptRoot $PSScriptRoot -ScriptName $SQL_SCRIPT_NAME
if (-not $sqlScriptPath) {
    exit 1
}

# Выполнение SQL скрипта
Write-Output "`nExecuting SQL script on database '$DATABASE'..."
$scriptResult = Invoke-SqlScript -ScriptPath $sqlScriptPath -Database $DATABASE -Container $CONTAINER -Password $DB_PASSWORD

if ($scriptResult -eq $false) {
    Write-Output "Database check failed"
    exit 1
}

Write-Output "`nSQL Script Output:"
Write-Output $scriptResult

Write-Output "`nDatabase check completed successfully"
exit 0