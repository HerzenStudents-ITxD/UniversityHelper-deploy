@echo off

set RIGHTS_DB_PASSWORD=User_1234
set CONTAINER=sqlserver_db
set DATABASE=RightsDB
set USER_ID=11111111-1111-1111-1111-111111111111

echo Copying SQL script to container...
docker cp ./sql/05_setup_admin_rights.sql %CONTAINER%:/tmp/

echo Setting up admin rights...
docker exec -it %CONTAINER% /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P %RIGHTS_DB_PASSWORD% -d %DATABASE% -Q "USE %DATABASE%; 
-- Clean up existing data
DELETE FROM UsersRoles WHERE UserId = '%USER_ID%';
DELETE FROM RolesRights WHERE RoleId = '%USER_ID%';
DELETE FROM RolesLocalizations WHERE RoleId = '%USER_ID%';
DELETE FROM Roles WHERE Id = '%USER_ID%';

-- Insert admin role
INSERT INTO Roles (Id, CreatedBy, IsActive)
VALUES ('%USER_ID%', '%USER_ID%', 1);

-- Insert admin role localizations
INSERT INTO RolesLocalizations (Id, RoleId, Locale, Name, IsActive, CreatedBy)
VALUES 
    (NEWID(), '%USER_ID%', 'en', 'System Administrator', 1, '%USER_ID%'),
    (NEWID(), '%USER_ID%', 'ru', 'Системный администратор', 1, '%USER_ID%');

-- Define all service rights
DECLARE @Rights TABLE (RightId INT, NameEn NVARCHAR(100), NameRu NVARCHAR(100));
INSERT INTO @Rights (RightId, NameEn, NameRu) VALUES 
    (1000, 'User Service Admin', 'Администратор сервиса пользователей'),
    (2000, 'Auth Service Admin', 'Администратор сервиса аутентификации'),
    (3000, 'University Service Admin', 'Администратор сервиса университета'),
    (4000, 'Rights Service Admin', 'Администратор сервиса прав'),
    (5000, 'Analytics Service Admin', 'Администратор сервиса аналитики'),
    (6000, 'Email Service Admin', 'Администратор сервиса email'),
    (7000, 'Feedback Service Admin', 'Администратор сервиса обратной связи'),
    (800, 'Map Service Admin', 'Администратор сервиса карт'),
    (900, 'Community Service Admin', 'Администратор сервиса сообществ'),
    (1100, 'Post Service Admin', 'Администратор сервиса постов'),
    (1200, 'Group Service Admin', 'Администратор сервиса групп'),
    (1300, 'Timetable Service Admin', 'Администратор сервиса расписания'),
    (1400, 'Note Service Admin', 'Администратор сервиса заметок'),
    (1500, 'Wiki Service Admin', 'Администратор сервиса вики'),
    (1600, 'News Service Admin', 'Администратор сервиса новостей'),
    (1700, 'Event Service Admin', 'Администратор сервиса событий');

-- Insert rights localizations
INSERT INTO RightsLocalizations (Id, RightId, Locale, Name)
SELECT NEWID(), RightId, 'en', NameEn FROM @Rights
UNION ALL
SELECT NEWID(), RightId, 'ru', NameRu FROM @Rights;

-- Assign rights to admin role
INSERT INTO RolesRights (Id, RoleId, RightId, CreatedBy)
SELECT NEWID(), '%USER_ID%', RightId, '%USER_ID%'
FROM @Rights;

-- Assign admin role to user
INSERT INTO UsersRoles (Id, UserId, RoleId, IsActive, CreatedBy)
VALUES (NEWID(), '%USER_ID%', '%USER_ID%', 1, '%USER_ID%');"

echo Verifying RightsDB tables...
call .\check_tables\check_RightsDB_tables.bat

echo Done ✅
pause 