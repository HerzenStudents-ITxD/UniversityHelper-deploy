#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Проверяет структуру базы данных MapDB
#>

# Загрузка переменных окружения
$envFile = Join-Path (Split-Path -Parent $PSScriptRoot) ".env"
if (-not (Test-Path $envFile)) {
    Write-Output "ERROR: .env file not found at $envFile"
    exit 1
}

Write-Output "Loading environment variables from $envFile"
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#]\w+)\s*=\s*(.*)\s*$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

$DB_PASSWORD = $envVars['SA_PASSWORD']
$CONTAINER = $envVars['DB_CONTAINER']
$DATABASE = $envVars['MAPDB_DB_NAME']
$SQL_SCRIPT_NAME = "check_tables.sql"

function Invoke-SqlScript {
    param(
        [string]$ScriptPath,
        [string]$Database = "master"
    )
    
    try {
        Write-Output "Copying script to Docker container..."
        docker cp $ScriptPath "${CONTAINER}:/tmp/script.sql"
        
        Write-Output "Executing SQL script on database '$Database'..."
        $result = docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U SA -P $DB_PASSWORD -d $Database `
            -i "/tmp/script.sql" -W -w 1024 -s "|" 2>&1
        
        docker exec $CONTAINER rm -f "/tmp/script.sql" | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Output "SQL Error (Code $LASTEXITCODE)"
            Write-Output $result
            return $false
        }
        return $result
    }
    catch {
        Write-Output "Failed to execute SQL script: $_"
        return $false
    }
}

# Проверка доступности SQL Server
Write-Output "`n[1/3] Checking SQL Server availability in container '$CONTAINER'..."
$serverCheck = docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd `
    -S localhost -U SA -P $DB_PASSWORD -d "master" `
    -Q "SELECT @@VERSION AS 'SQL Server Version'" -W

if (-not $serverCheck -or $LASTEXITCODE -ne 0) {
    Write-Output "SQL Server is not responding in container '$CONTAINER'"
    Write-Output "Check if container is running: docker ps -a"
    exit 1
}
Write-Output "SQL Server version:"
Write-Output $serverCheck
Write-Output "SQL Server is available and responding"

# Проверка существования SQL скрипта
Write-Output "`n[2/3] Locating SQL script '$SQL_SCRIPT_NAME'..."
$sqlScriptPath = Join-Path $PSScriptRoot $SQL_SCRIPT_NAME
if (-not (Test-Path $sqlScriptPath)) {
    Write-Output "SQL script '$SQL_SCRIPT_NAME' not found in: $PSScriptRoot"
    Write-Output "Expected path: $sqlScriptPath"
    exit 1
}
Write-Output "Script found at: $sqlScriptPath"

# Выполнение SQL скрипта
Write-Output "`n[3/3] Executing SQL script on database '$DATABASE'..."
$scriptResult = Invoke-SqlScript -ScriptPath $sqlScriptPath -Database $DATABASE

if ($scriptResult -eq $false) {
    Write-Output "Database check failed"
    exit 1
}

Write-Output "`nSQL Script Output:"
Write-Output $scriptResult

Write-Output "`nDatabase check completed successfully"
exit 0