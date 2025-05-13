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
        Write-Output "Copying script to Docker container..."
        docker cp $ScriptPath "${Container}:/tmp/script.sql"
        
        Write-Output "Executing SQL script on database '$Database'..."
        $result = docker exec $Container /opt/mssql-tools/bin/sqlcmd `
            -S localhost -U SA -P $Password -d $Database `
            -i "/tmp/script.sql" -W -w 1024 -s "|" 2>&1
        
        docker exec $Container rm -f "/tmp/script.sql" | Out-Null
        
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

function Test-SqlServerAvailability {
    <#
    .SYNOPSIS
        Проверяет доступность SQL Server в контейнере
    #>
    param(
        [string]$Container,
        [string]$Password
    )
    
    Write-Output "Checking SQL Server availability in container '$Container'..."
    $serverCheck = docker exec $Container /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U SA -P $Password -d "master" `
        -Q "SELECT @@VERSION AS 'SQL Server Version'" -W

    if (-not $serverCheck -or $LASTEXITCODE -ne 0) {
        Write-Output "SQL Server is not responding in container '$Container'"
        Write-Output "Check if container is running: docker ps -a"
        return $false
    }
    
    Write-Output "SQL Server version:"
    Write-Output $serverCheck
    Write-Output "SQL Server is available and responding"
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
    
    Write-Output "Locating SQL script '$ScriptName'..."
    $sqlScriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path $sqlScriptPath)) {
        Write-Output "SQL script '$ScriptName' not found in: $PSScriptRoot"
        Write-Output "Expected path: $sqlScriptPath"
        return $false
    }
    Write-Output "Script found at: $sqlScriptPath"
    return $sqlScriptPath
}

Export-ModuleMember -Function *