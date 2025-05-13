<#
.SYNOPSIS
    Утилиты для работы с SQL Server в Docker
#>

function Get-EnvVariables {
    <#
    .SYNOPSIS
        Загружает переменные окружения из .env файла
    #>
    param(
        [string]$PSScriptRoot
    )
    
    Write-Host "Entering Get-EnvVariables with PSScriptRoot: $PSScriptRoot"
    $envFile = Join-Path (Split-Path -Parent $PSScriptRoot) ".env"
    Write-Host "Computed env file path: $envFile"
    
    # Проверка существования файла
    Write-Host "Checking if .env file exists..."
    if (-not (Test-Path $envFile)) {
        Write-Error "ERROR: .env file not found at $envFile"
        return $null
    }
    Write-Host ".env file found"

    # Парсинг файла
    Write-Host "Parsing .env file..."
    $envVars = @{}
    $lines = Get-Content $envFile
    Write-Host "Total lines in .env file: $($lines.Count)"
    foreach ($line in $lines) {
        # Write-Host "Processing line: '$line'"
        if ($line -match '^\s*([^#]\w+)\s*=\s*(.*)\s*$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $envVars[$key] = $value
            # Write-Host "Loaded variable: $key=$value"
        }
        # else {
        #     Write-Host "Line skipped (does not match pattern): '$line'"
        # }
    }

    if ($envVars.Count -eq 0) {
        Write-Error "No valid environment variables loaded from $envFile"
        return $null
    }

    # Write-Host "Environment variables loaded: $($envVars.Keys -join ', ')"
    return $envVars
}

function Invoke-SqlScript {
    <#
    .SYNOPSIS
        Выполняет SQL скрипт в контейнере Docker
    #>
    param(
        [string]$ScriptPath,
        [string]$Database,
        [string]$Container,
        [string]$Password
    )
    
    try {
        Write-Host "Copying script to Docker container..."
        docker cp $ScriptPath "${Container}:/tmp/script.sql"
        
        Write-Host "Executing SQL script on database '$Database'..."
        $result = docker exec $Container /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U SA -P $Password -d $Database `
            -i "/tmp/script.sql" -W -w 1024 -s "|" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "SQL Error (Code $LASTEXITCODE): $result"
            return $false
        }
        return $result
    }
    catch {
        Write-Error "Failed to execute SQL script: $_"
        return $false
    }
    finally {
        docker exec $Container rm -f "/tmp/script.sql" | Out-Null
    }
}

function Test-SqlServerAvailability {
    <#
    .SYNOPSIS
        Проверяет доступность SQL Server в контейнере
    #>
    param(
        [string]$Container,
        [string]$Password
    )
    
    Write-Host "Checking SQL Server availability in container '$Container'..."
    $serverCheck = docker exec $Container /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U SA -P $Password -d "master" `
        -Q "SELECT @@VERSION AS 'SQL Server Version'" -W 2>&1

    if (-not $serverCheck -or $LASTEXITCODE -ne 0) {
        Write-Error "SQL Server is not responding in container '$Container': $serverCheck"
        Write-Host "Check if container is running: docker ps -a"
        return $false
    }
    
    Write-Host "SQL Server version:"
    Write-Host $serverCheck
    Write-Host "SQL Server is available and responding"
    return $true
}

function Test-SqlScriptExists {
    <#
    .SYNOPSIS
        Проверяет существование SQL скрипта
    #>
    param(
        [string]$PSScriptRoot,
        [string]$ScriptName
    )
    
    Write-Host "Locating SQL script '$ScriptName'..."
    $sqlScriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path $sqlScriptPath)) {
        Write-Error "SQL script '$ScriptName' not found in: $PSScriptRoot"
        Write-Host "Expected path: $sqlScriptPath"
        return $false
    }
    Write-Host "Script found at: $sqlScriptPath"
    return $sqlScriptPath
}