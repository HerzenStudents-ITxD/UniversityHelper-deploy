# PowerShell Core скрипт для настройки базы данных RightsDB
Write-Host "Запуск скрипта заполнения базы данных RightsDB..."

# Загрузка переменных окружения из файла .env в директории скрипта
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "ОШИБКА: Файл .env не найден по пути $envFile"
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
$database = $env:RIGHTSDB_DB_NAME
$adminUserId = $env:RIGHTSDB_ADMIN_USER_ID
$adminRoleId = $env:RIGHTSDB_ADMIN_ROLE_ID

# Проверка корректности переменных окружения
$requiredVars = @("DB_CONTAINER", "SA_PASSWORD", "RIGHTSDB_DB_NAME", "RIGHTSDB_ADMIN_USER_ID", "RIGHTSDB_ADMIN_ROLE_ID")
foreach ($var in $requiredVars) {
    if (-not [System.Environment]::GetEnvironmentVariable($var)) {
        Write-Error "ОШИБКА: Переменная окружения $var не установлена."
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
}

# Проверка, что имя базы данных корректно
if ($database -ne "RightsDB") {
    Write-Error "ОШИБКА: Имя базы данных ($database) не соответствует ожидаемому 'RightsDB'."
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
Write-Host "Проверка, запущен ли контейнер $container..."
$containerStatus = docker inspect $container 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Контейнер $container не запущен."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Функция для выполнения SQL-команд
function Invoke-SqlCmd {
    param($Query, $Database = $database)
    $sqlcmd = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$password' -d $Database -Q `"$Query`" -s','"
    Write-Host "Выполнение SQL: $Query"
    $result = docker exec -it $container bash -c $sqlcmd 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ОШИБКА: Не удалось выполнить SQL-команду. Подробности: $result"
        return $false
    }
    return $result
}

# Проверка подключения к SQL Server
Write-Host "Проверка подключения к SQL Server..."
$testQuery = "SELECT 1 AS Test"
if (-not (Invoke-SqlCmd -Query $testQuery -Database "master")) {
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка существования базы данных
Write-Host "Проверка существования базы данных $database..."
$checkDbQuery = "IF DB_ID('$database') IS NOT NULL SELECT 1 AS DbExists ELSE SELECT 0 AS DbExists"
$dbExists = Invoke-SqlCmd -Query $checkDbQuery -Database "master"
if ($dbExists -notmatch "1") {
    Write-Error "ОШИБКА: База данных $database не существует."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка существующих таблиц
Write-Host "Проверка существующих таблиц в базе $database..."
$checkTablesQuery = "USE $database; SELECT 'Roles' AS TableName, COUNT(*) AS Count FROM sys.tables WHERE name = 'Roles' UNION ALL SELECT 'RolesLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RolesLocalizations' UNION ALL SELECT 'Rights', COUNT(*) FROM sys.tables WHERE name = 'Rights' UNION ALL SELECT 'RightsLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RightsLocalizations' UNION ALL SELECT 'RolesRights', COUNT(*) FROM sys.tables WHERE name = 'RolesRights' UNION ALL SELECT 'UsersRoles', COUNT(*) FROM sys.tables WHERE name = 'UsersRoles';"
if (-not (Invoke-SqlCmd $checkTablesQuery)) {
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка структуры таблиц
Write-Host "Проверка структуры таблиц..."
$checkStructureQuery = "USE $database; SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'Rights', 'RightsLocalizations', 'RolesRights', 'UsersRoles') ORDER BY TABLE_NAME, ORDINAL_POSITION;"
if (-not (Invoke-SqlCmd $checkStructureQuery)) {
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Создание таблиц, если они не существуют
Write-Host "Создание таблиц, если они не существуют..."
$createTablesQuery = @"
USE $database;
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Rights')
    CREATE TABLE Rights (RightId int PRIMARY KEY, CreatedBy uniqueidentifier NOT NULL);
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
    CREATE TABLE Roles (Id uniqueidentifier PRIMARY KEY, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesHistory));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations')
    CREATE TABLE RolesLocalizations (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, Locale char(2) NOT NULL, Name nvarchar(max) NOT NULL, Description nvarchar(max) NOT NULL, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, CreatedAtUtc datetime2 NOT NULL, ModifiedBy uniqueidentifier, ModifiedAtUtc datetime2, CONSTRAINT FK_RolesLocalizations_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations')
    CREATE TABLE RightsLocalizations (Id uniqueidentifier PRIMARY KEY, RightId int NOT NULL, Locale char(2) NOT NULL, Name nvarchar(max) NOT NULL, Description nvarchar(max) NOT NULL, CONSTRAINT FK_RightsLocalizations_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights')
    CREATE TABLE RolesRights (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, RightId int NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), CONSTRAINT FK_RolesRights_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id), CONSTRAINT FK_RolesRights_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesRightsHistory));
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles')
    CREATE TABLE UsersRoles (Id uniqueidentifier PRIMARY KEY, UserId uniqueidentifier NOT NULL, RoleId uniqueidentifier NOT NULL, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), CONSTRAINT FK_UsersRoles_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.UsersRolesHistory));
"@
if (-not (Invoke-SqlCmd $createTablesQuery)) {
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Вывод текущего содержимого таблиц
$tables = @("Rights", "Roles", "RolesLocalizations", "RightsLocalizations", "RolesRights", "UsersRoles")
foreach ($table in $tables) {
    Write-Host "Таблица $table:"
    $query = "USE $database; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;"
    if (-not (Invoke-SqlCmd $query)) {
        Write-Error "ОШИБКА: Не удалось вывести таблицу $table."
    }
}

# Очистка существующих данных
Write-Host "Очистка существующих данных..."
$cleanupQuery = @"
USE $database;
IF OBJECT_ID('UsersRoles') IS NOT NULL DELETE FROM UsersRoles WHERE RoleId = '$adminRoleId';
IF OBJECT_ID('RolesRights') IS NOT NULL DELETE FROM RolesRights WHERE RoleId = '$adminRoleId';
IF OBJECT_ID('RolesLocalizations') IS NOT NULL DELETE FROM RolesLocalizations WHERE RoleId = '$adminRoleId';
IF OBJECT_ID('Roles') IS NOT NULL DELETE FROM Roles WHERE Id = '$adminRoleId';
IF OBJECT_ID('RightsLocalizations') IS NOT NULL DELETE FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '$adminUserId');
IF OBJECT_ID('Rights') IS NOT NULL DELETE FROM Rights WHERE CreatedBy = '$adminUserId';
"@
if (-not (Invoke-SqlCmd $cleanupQuery)) {
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Копирование SQL-скрипта в контейнер
Write-Host "Копирование SQL-скрипта в контейнер..."
$sqlScriptPath = Join-Path $scriptDir "sql\RightsDB\05_setup_admin_rights.sql"
if (-not (Test-Path $sqlScriptPath)) {
    Write-Error "ОШИБКА: SQL-скрипт $sqlScriptPath не найден."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}
docker cp $sqlScriptPath "$container:/tmp/05_setup_admin_rights.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Не удалось скопировать SQL-скрипт в контейнер."
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Настройка прав администратора
Write-Host "Настройка прав администратора..."
$setupAdminQuery = "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '$password' -d $database -i /tmp/05_setup_admin_rights.sql"
$result = docker exec -it $container bash -c $setupAdminQuery 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ОШИБКА: Не удалось настроить права администратора. Подробности: $result"
    Read-Host "Нажмите Enter для продолжения..."
    exit 1
}

# Проверка настройки прав администратора
Write-Host "Проверка настройки прав администратора..."
$verifyAdminQuery = @"
USE $database;
IF OBJECT_ID('Roles') IS NOT NULL AND OBJECT_ID('RolesLocalizations') IS NOT NULL
SELECT r.Id AS RoleId, rl.Name AS RoleName, r.IsActive AS RoleIsActive, COUNT(DISTINCT rr.RightId) AS AssignedRightsCount, COUNT(DISTINCT ur.UserId) AS AssignedUsersCount
FROM Roles r
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en'
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId
WHERE r.Id = '$adminRoleId'
GROUP BY r.Id, rl.Name, r.IsActive;
"@
if (-not (Invoke-SqlCmd $verifyAdminQuery)) {
    Write-Error "ОШИБКА: Не удалось проверить настройку прав администратора."
}

# Проверка целостности данных
Write-Host "Проверка целостности данных..."
$verifyIntegrityQuery = @"
USE $database;
SELECT 'Roles' AS TableName, CASE WHEN OBJECT_ID('Roles') IS NOT NULL THEN (SELECT COUNT(*) FROM Roles WHERE Id = '$adminRoleId') ELSE 0 END AS Count UNION ALL
SELECT 'RolesLocalizations', CASE WHEN OBJECT_ID('RolesLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesLocalizations WHERE RoleId = '$adminRoleId') ELSE 0 END UNION ALL
SELECT 'Rights', CASE WHEN OBJECT_ID('Rights') IS NOT NULL THEN (SELECT COUNT(*) FROM Rights WHERE CreatedBy = '$adminUserId') ELSE 0 END UNION ALL
SELECT 'RightsLocalizations', CASE WHEN OBJECT_ID('RightsLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '$adminUserId')) ELSE 0 END UNION ALL
SELECT 'RolesRights', CASE WHEN OBJECT_ID('RolesRights') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesRights WHERE RoleId = '$adminRoleId') ELSE 0 END UNION ALL
SELECT 'UsersRoles', CASE WHEN OBJECT_ID('UsersRoles') IS NOT NULL THEN (SELECT COUNT(*) FROM UsersRoles WHERE RoleId = '$adminRoleId') ELSE 0 END;
"@
if (-not (Invoke-SqlCmd $verifyIntegrityQuery)) {
    Write-Error "ОШИБКА: Не удалось проверить целостность данных."
}

# Вывод финального содержимого таблиц
Write-Host "Вывод финального содержимого таблиц..."
foreach ($table in $tables) {
    Write-Host "Таблица $table:"
    $query = "USE $database; IF OBJECT_ID('$table') IS NOT NULL SELECT * FROM $table;"
    if (-not (Invoke-SqlCmd $query)) {
        Write-Error "ОШИБКА: Не удалось вывести финальное содержимое таблицы $table."
    }
}

# Выполнение внешнего скрипта проверки, если он существует
$verifyScriptPath = Join-Path $scriptDir "sql\RightsDB\check_RightsDB_tables.ps1"
if (Test-Path $verifyScriptPath) {
    Write-Host "Выполнение внешнего скрипта проверки..."
    & $verifyScriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ОШИБКА: Внешний скрипт проверки завершился с ошибкой."
        Read-Host "Нажмите Enter для продолжения..."
        exit 1
    }
} else {
    Write-Warning "ПРЕДУПРЕЖДЕНИЕ: Внешний скрипт проверки $verifyScriptPath не найден."
}

Write-Host "Готово ✅"
Read-Host "Нажмите Enter для продолжения..."
exit 0