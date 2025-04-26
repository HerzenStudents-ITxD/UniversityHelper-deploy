@echo off
setlocal EnableDelayedExpansion

:: Configuration
set RIGHTS_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=RightsDB
set ADMIN_USER_ID=11111111-1111-1111-1111-111111111111
set ADMIN_ROLE_ID=11111111-1111-1111-1111-111111111111

:: Check if container is running
echo Checking if container %CONTAINER% is running...
docker inspect %CONTAINER% >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Container %CONTAINER% is not running.
    pause
    exit /b 1
)

:: Check existing tables
echo Checking existing %DATABASE% tables...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; SELECT 'Roles' as TableName, COUNT(*) as Count FROM Roles UNION ALL SELECT 'RolesLocalizations', COUNT(*) FROM RolesLocalizations UNION ALL SELECT 'Rights', COUNT(*) FROM Rights UNION ALL SELECT 'RightsLocalizations', COUNT(*) FROM RightsLocalizations UNION ALL SELECT 'RolesRights', COUNT(*) FROM RolesRights UNION ALL SELECT 'UsersRoles', COUNT(*) FROM UsersRoles;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to check existing tables.
    pause
    exit /b 1
)

:: Check table structure
echo Checking table structure...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'Rights', 'RightsLocalizations', 'RolesRights', 'UsersRoles') ORDER BY TABLE_NAME, ORDINAL_POSITION;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to check table structure.
    pause
    exit /b 1
)

:: Create tables if they don't exist
echo Creating tables if they don't exist...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q ^
"USE %DATABASE%; ^
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Rights') ^
    CREATE TABLE Rights (RightId int PRIMARY KEY, CreatedBy uniqueidentifier NOT NULL); ^
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles') ^
    CREATE TABLE Roles (Id uniqueidentifier PRIMARY KEY, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesHistory)); ^
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations') ^
    CREATE TABLE RolesLocalizations (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, Locale char(2) NOT NULL, Name nvarchar(max) NOT NULL, Description nvarchar(max) NOT NULL, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, CreatedAtUtc datetime2 NOT NULL, ModifiedBy uniqueidentifier, ModifiedAtUtc datetime2, CONSTRAINT FK_RolesLocalizations_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)); ^
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations') ^
    CREATE TABLE RightsLocalizations (Id uniqueidentifier PRIMARY KEY, RightId int NOT NULL, Locale char(2) NOT NULL, Name nvarchar(max) NOT NULL, Description nvarchar(max) NOT NULL, CONSTRAINT FK_RightsLocalizations_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId)); ^
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights') ^
    CREATE TABLE RolesRights (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier NOT NULL, RightId int NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), CONSTRAINT FK_RolesRights_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id), CONSTRAINT FK_RolesRights_Rights FOREIGN KEY (RightId) REFERENCES Rights(RightId)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.RolesRightsHistory)); ^
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles') ^    
    CREATE TABLE UsersRoles (Id uniqueidentifier PRIMARY KEY, UserId uniqueidentifier NOT NULL, RoleId uniqueidentifier NOT NULL, IsActive bit NOT NULL, CreatedBy uniqueidentifier NOT NULL, PeriodStart datetime2 GENERATED ALWAYS AS ROW START, PeriodEnd datetime2 GENERATED ALWAYS AS ROW END, PERIOD FOR SYSTEM_TIME (PeriodStart, PeriodEnd), CONSTRAINT FK_UsersRoles_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.UsersRolesHistory));"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create tables.
    pause
    exit /b 1
)

:: Print current table contents
echo