#!/usr/bin/env pwsh

# Получаем путь к папке, где лежит сам скрипт
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFilePath = Join-Path -Path $scriptDir -ChildPath ".env"

# Debug информация
Write-Host "[DEBUG] Script directory: $scriptDir"
Write-Host "[DEBUG] .env file path: $envFilePath"

# Проверяем, существует ли файл .env
if (Test-Path $envFilePath) {
    Write-Host "[DEBUG] Loading environment variables from .env file..."
    $envVars = Get-Content $envFilePath | Where-Object {$_ -match "^\s*[^#].*=\s*.*$"}

    foreach ($envVar in $envVars) {
        $key, $value = $envVar -split "=", 2
        [System.Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim(), [System.EnvironmentVariableTarget]::Process)
    }
} else {
    Write-Host "[ERROR] .env file not found at $envFilePath!"
    Write-Host "[DEBUG] Current directory contents:"
    Get-ChildItem -Path $scriptDir | Select-Object Name | Format-Table -AutoSize
    exit 1
}

Write-Host "[DEBUG] Launching UserDB database fill script..."

# Конфигурационные параметры из переменных окружения
$requiredVars = @(
    "SA_PASSWORD",
    "DB_CONTAINER",
    "USERDB_DB_NAME",
    "USERDB_ADMIN_LOGIN",
    "USERDB_ADMIN_PASSWORD",
    "USERDB_SALT",
    "USERDB_ADMIN_USER_ID",
    "USERDB_INTERNAL_SALT"
)

# Исправленный способ проверки переменных окружения
$missingVars = @()
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Host "[ERROR] Missing required environment variables: $($missingVars -join ', ')"
    exit 1
}

$USER_DB_PASSWORD = [System.Environment]::GetEnvironmentVariable("SA_PASSWORD")
$CONTAINER = [System.Environment]::GetEnvironmentVariable("DB_CONTAINER")
$DATABASE = [System.Environment]::GetEnvironmentVariable("USERDB_DB_NAME")
$LOGIN = [System.Environment]::GetEnvironmentVariable("USERDB_ADMIN_LOGIN")
$PASSWORD = [System.Environment]::GetEnvironmentVariable("USERDB_ADMIN_PASSWORD")
$SALT = [System.Environment]::GetEnvironmentVariable("USERDB_SALT")
$USER_ID = [System.Environment]::GetEnvironmentVariable("USERDB_ADMIN_USER_ID")
$INTERNAL_SALT = [System.Environment]::GetEnvironmentVariable("USERDB_INTERNAL_SALT")

Write-Host "[DEBUG] 1. Generating SHA512 hash..."

# Генерация SHA512 хэша
$plain = "$SALT$LOGIN$PASSWORD$INTERNAL_SALT"
$hashBytes = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($plain))
$HASH = [Convert]::ToBase64String($hashBytes)

Write-Host "[DEBUG] Generated hash: $HASH"

Write-Host "[DEBUG] 2. Preparing SQL content..."

# Генерация SQL-запроса
$sqlContent = @"
USE $DATABASE;
DECLARE @Now DATETIME2 = GETUTCDATE();
INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)
VALUES (
  NEWID(),
  '$USER_ID',
  '$LOGIN',
  '$HASH',
  '$SALT',
  1,
  @Now
);
PRINT 'Created admin credentials for login: $LOGIN';
"@

# Создаем папку для SQL файлов, если ее нет
$sqlDir = Join-Path -Path $scriptDir -ChildPath "UserDB"
if (-not (Test-Path $sqlDir)) {
    New-Item -ItemType Directory -Path $sqlDir | Out-Null
}

$tempPath = Join-Path -Path $scriptDir -ChildPath "temp.sql"
$outPath = Join-Path -Path $sqlDir -ChildPath "02_create_admin_credentials.sql"

# Запись в файл (UTF-8 без BOM)
$sqlContent | Set-Content -Path $tempPath -Encoding UTF8 -NoNewline
Get-Content -Path $tempPath | Set-Content -Path $outPath -Encoding UTF8
Remove-Item -Path $tempPath -Force

Write-Host "[DEBUG] 3. Verifying generated SQL file..."
Get-Content -Path $outPath | ForEach-Object { Write-Host $_ }

Write-Host "[DEBUG] 4. Checking file encoding..."
$bytes = [System.IO.File]::ReadAllBytes($outPath)
Write-Host "First 3 bytes (BOM): $($bytes[0]) $($bytes[1]) $($bytes[2])"

# Пути к SQL файлам
$sqlFile1 = Join-Path -Path $sqlDir -ChildPath "01_create_admin_user.sql"
$sqlFile2 = $outPath
$sqlFile3 = Join-Path -Path $sqlDir -ChildPath "04_setup_admin_user_data.sql"

Write-Host "[DEBUG] 5. Copying SQL scripts to container..."
docker cp $sqlFile1 "${CONTAINER}:/tmp/01_create_admin_user.sql"
docker cp $sqlFile2 "${CONTAINER}:/tmp/02_create_admin_credentials.sql"
docker cp $sqlFile3 "${CONTAINER}:/tmp/04_setup_admin_user_data.sql"

Write-Host "[DEBUG] 6. Executing SQL scripts..."
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/01_create_admin_user.sql
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/02_create_admin_credentials.sql
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; DELETE FROM UsersAdditions WHERE UserId = '$USER_ID'; DELETE FROM UsersCommunications WHERE UserId = '$USER_ID';"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/04_setup_admin_user_data.sql

Write-Host "[SUCCESS] Script completed successfully ✅"
exit 0