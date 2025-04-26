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
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q ^
"USE %DATABASE%; ^
SELECT 'Roles' AS TableName, COUNT(*) AS Count FROM sys.tables WHERE name = 'Roles' UNION ALL ^
SELECT 'RolesLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RolesLocalizations' UNION ALL ^
SELECT 'Rights', COUNT(*) FROM sys.tables WHERE name = 'Rights' UNION ALL ^
SELECT 'RightsLocalizations', COUNT(*) FROM sys.tables WHERE name = 'RightsLocalizations' UNION ALL ^
SELECT 'RolesRights', COUNT(*) FROM sys.tables WHERE name = 'RolesRights' UNION ALL ^
SELECT 'UsersRoles', COUNT(*) FROM sys.tables WHERE name = 'UsersRoles';" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to check existing tables.
    pause
    exit /b 1
)

:: Check table structure
echo Checking table structure...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q ^
"USE %DATABASE%; ^
SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE ^
FROM INFORMATION_SCHEMA.COLUMNS ^
WHERE TABLE_NAME IN ('Roles', 'RolesLocalizations', 'Rights', 'RightsLocalizations', 'RolesRights', 'UsersRoles') ^
ORDER BY TABLE_NAME, ORDINAL_POSITION;" -s","
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
echo Printing current table contents...
echo Rights table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('Rights') IS NOT NULL SELECT * FROM Rights;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print Rights table.
)

echo Roles table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('Roles') IS NOT NULL SELECT * FROM Roles;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print Roles table.
)

echo RolesLocalizations table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('RolesLocalizations') IS NOT NULL SELECT * FROM RolesLocalizations;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print RolesLocalizations table.
)

echo RightsLocalizations table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('RightsLocalizations') IS NOT NULL SELECT * FROM RightsLocalizations;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print RightsLocalizations table.
)

echo RolesRights table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('RolesRights') IS NOT NULL SELECT * FROM RolesRights;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print RolesRights table.
)

echo UsersRoles table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('UsersRoles') IS NOT NULL SELECT * FROM UsersRoles;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print UsersRoles table.
)

:: Clean up existing data
echo Cleaning up existing data...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q ^
"USE %DATABASE%; ^
IF OBJECT_ID('UsersRoles') IS NOT NULL DELETE FROM UsersRoles WHERE RoleId = '%ADMIN_ROLE_ID%'; ^
IF OBJECT_ID('RolesRights') IS NOT NULL DELETE FROM RolesRights WHERE RoleId = '%ADMIN_ROLE_ID%'; ^
IF OBJECT_ID('RolesLocalizations') IS NOT NULL DELETE FROM RolesLocalizations WHERE RoleId = '%ADMIN_ROLE_ID%'; ^
IF OBJECT_ID('Roles') IS NOT NULL DELETE FROM Roles WHERE Id = '%ADMIN_ROLE_ID%'; ^
IF OBJECT_ID('RightsLocalizations') IS NOT NULL DELETE FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '%ADMIN_USER_ID%'); ^
IF OBJECT_ID('Rights') IS NOT NULL DELETE FROM Rights WHERE CreatedBy = '%ADMIN_USER_ID%';"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to clean up existing data.
    pause
    exit /b 1
)

:: Copy SQL script to container
echo Copying SQL script to container...
if not exist .\sql\05_setup_admin_rights.sql (
    echo ERROR: SQL script .\sql\05_setup_admin_rights.sql not found.
    pause
    exit /b 1
)
docker cp .\sql\05_setup_admin_rights.sql %CONTAINER%:/tmp/
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy SQL script to container.
    pause
    exit /b 1
)

:: Set up admin rights
echo Setting up admin rights...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -i /tmp/05_setup_admin_rights.sql
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to set up admin rights.
    pause
    exit /b 1
)

:: Verify admin rights setup
echo Verifying admin rights setup...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q ^
"USE %DATABASE%; ^
IF OBJECT_ID('Roles') IS NOT NULL AND OBJECT_ID('RolesLocalizations') IS NOT NULL ^
SELECT r.Id AS RoleId, rl.Name AS RoleName, r.IsActive AS RoleIsActive, COUNT(DISTINCT rr.RightId) AS AssignedRightsCount, COUNT(DISTINCT ur.UserId) AS AssignedUsersCount ^
FROM Roles r ^
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en' ^
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId ^
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId ^
WHERE r.Id = '%ADMIN_ROLE_ID%' ^
GROUP BY r.Id, rl.Name, r.IsActive;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to verify admin rights setup.
)

:: Verify data integrity
echo Verifying data integrity...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q ^
"USE %DATABASE%; ^
SELECT 'Roles' AS TableName, CASE WHEN OBJECT_ID('Roles') IS NOT NULL THEN (SELECT COUNT(*) FROM Roles WHERE Id = '%ADMIN_ROLE_ID%') ELSE 0 END AS Count UNION ALL ^
SELECT 'RolesLocalizations', CASE WHEN OBJECT_ID('RolesLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesLocalizations WHERE RoleId = '%ADMIN_ROLE_ID%') ELSE 0 END UNION ALL ^
SELECT 'Rights', CASE WHEN OBJECT_ID('Rights') IS NOT NULL THEN (SELECT COUNT(*) FROM Rights WHERE CreatedBy = '%ADMIN_USER_ID%') ELSE 0 END UNION ALL ^
SELECT 'RightsLocalizations', CASE WHEN OBJECT_ID('RightsLocalizations') IS NOT NULL THEN (SELECT COUNT(*) FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM Rights WHERE CreatedBy = '%ADMIN_USER_ID%')) ELSE 0 END UNION ALL ^
SELECT 'RolesRights', CASE WHEN OBJECT_ID('RolesRights') IS NOT NULL THEN (SELECT COUNT(*) FROM RolesRights WHERE RoleId = '%ADMIN_ROLE_ID%') ELSE 0 END UNION ALL ^
SELECT 'UsersRoles', CASE WHEN OBJECT_ID('UsersRoles') IS NOT NULL THEN (SELECT COUNT(*) FROM UsersRoles WHERE RoleId = '%ADMIN_ROLE_ID%') ELSE 0 END;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to verify data integrity.
)

:: Print final table contents
echo Printing final table contents...
echo Rights table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('Rights') IS NOT NULL SELECT * FROM Rights;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print final Rights table.
)

echo Roles table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('Roles') IS NOT NULL SELECT * FROM Roles;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print final Roles table.
)

echo RolesLocalizations table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('RolesLocalizations') IS NOT NULL SELECT * FROM RolesLocalizations;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print final RolesLocalizations table.
)

echo RightsLocalizations table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('RightsLocalizations') IS NOT NULL SELECT * FROM RightsLocalizations;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print final RightsLocalizations table.
)

echo RolesRights table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('RolesRights') IS NOT NULL SELECT * FROM RolesRights;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print final RolesRights table.
)

echo UsersRoles table:
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; IF OBJECT_ID('UsersRoles') IS NOT NULL SELECT * FROM UsersRoles;" -s","
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to print final UsersRoles table.
)

:: Run external verification script if exists
if exist .\check_tables\check_RightsDB_tables.bat (
    echo Running external verification script...
    call .\check_tables\check_RightsDB_tables.bat
    if %ERRORLEVEL% neq 0 (
        echo ERROR: External verification script failed.
    )
) else (
    echo WARNING: External verification script .\check_tables\check_RightsDB_tables.bat not found.
)

echo Done ✅
pause
exit /b 0