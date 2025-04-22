USE RightsDB;

-- Drop existing tables if they exist
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles')
    DROP TABLE UsersRoles;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights')
    DROP TABLE RolesRights;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations')
    DROP TABLE RolesLocalizations;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations')
    DROP TABLE RightsLocalizations;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
    DROP TABLE Roles;

-- Create Roles table
CREATE TABLE Roles (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    CreatedBy UNIQUEIDENTIFIER,
    IsActive BIT DEFAULT 1,
    CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE()
);

-- Create RolesLocalizations table
CREATE TABLE RolesLocalizations (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    RoleId UNIQUEIDENTIFIER NOT NULL,
    Locale NVARCHAR(10) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedBy UNIQUEIDENTIFIER,
    CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (RoleId) REFERENCES Roles(Id)
);

-- Create RightsLocalizations table
CREATE TABLE RightsLocalizations (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    RightId INT NOT NULL,
    Locale NVARCHAR(10) NOT NULL,
    Name NVARCHAR(100) NOT NULL
);

-- Create RolesRights table
CREATE TABLE RolesRights (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    RoleId UNIQUEIDENTIFIER NOT NULL,
    RightId INT NOT NULL,
    CreatedBy UNIQUEIDENTIFIER,
    CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (RoleId) REFERENCES Roles(Id)
);

-- Create UsersRoles table
CREATE TABLE UsersRoles (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    RoleId UNIQUEIDENTIFIER NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedBy UNIQUEIDENTIFIER,
    CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (RoleId) REFERENCES Roles(Id)
);

-- Insert admin role
DECLARE @AdminRoleId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';

INSERT INTO Roles (Id, CreatedBy, IsActive)
VALUES (@AdminRoleId, @AdminUserId, 1);

-- Insert admin role localizations
INSERT INTO RolesLocalizations (Id, RoleId, Locale, Name, IsActive, CreatedBy)
VALUES 
    (NEWID(), @AdminRoleId, 'en', 'System Administrator', 1, @AdminUserId),
    (NEWID(), @AdminRoleId, 'ru', 'Системный администратор', 1, @AdminUserId);

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
SELECT NEWID(), @AdminRoleId, RightId, @AdminUserId
FROM @Rights;

-- Assign admin role to user
INSERT INTO UsersRoles (Id, UserId, RoleId, IsActive, CreatedBy)
VALUES (NEWID(), @AdminUserId, @AdminRoleId, 1, @AdminUserId);

-- Verify setup
PRINT 'Verifying admin rights setup...';

-- Check table counts
SELECT 'Roles' as TableName, COUNT(*) as Count FROM Roles
UNION ALL
SELECT 'RolesLocalizations', COUNT(*) FROM RolesLocalizations
UNION ALL
SELECT 'RightsLocalizations', COUNT(*) FROM RightsLocalizations
UNION ALL
SELECT 'RolesRights', COUNT(*) FROM RolesRights
UNION ALL
SELECT 'UsersRoles', COUNT(*) FROM UsersRoles;

-- Check Roles table
PRINT 'Roles table details:';
SELECT 
    Id,
    CreatedBy,
    IsActive,
    CreatedAtUtc
FROM Roles 
WHERE Id = @AdminRoleId;

-- Check RolesLocalizations table
PRINT 'RolesLocalizations table details:';
SELECT 
    Id,
    RoleId,
    Locale,
    Name,
    IsActive,
    CreatedBy,
    CreatedAtUtc
FROM RolesLocalizations 
WHERE RoleId = @AdminRoleId
ORDER BY Locale;

-- Check RightsLocalizations table
PRINT 'RightsLocalizations table details:';
SELECT 
    Id,
    RightId,
    Locale,
    Name
FROM RightsLocalizations 
ORDER BY RightId, Locale;

-- Check RolesRights table
PRINT 'RolesRights table details:';
SELECT 
    rr.Id,
    rr.RoleId,
    rr.RightId,
    rl.Name as RightName,
    rr.CreatedBy,
    rr.CreatedAtUtc
FROM RolesRights rr
JOIN RightsLocalizations rl ON rr.RightId = rl.RightId AND rl.Locale = 'en'
WHERE rr.RoleId = @AdminRoleId
ORDER BY rr.RightId;

-- Check UsersRoles table
PRINT 'UsersRoles table details:';
SELECT 
    ur.Id,
    ur.UserId,
    ur.RoleId,
    rl.Name as RoleName,
    ur.IsActive,
    ur.CreatedBy,
    ur.CreatedAtUtc
FROM UsersRoles ur
JOIN RolesLocalizations rl ON ur.RoleId = rl.RoleId AND rl.Locale = 'en'
WHERE ur.UserId = @AdminUserId;

-- Final verification summary
SELECT 
    r.Id as RoleId,
    rl.Name as RoleName,
    r.IsActive as RoleIsActive,
    COUNT(DISTINCT rr.RightId) as AssignedRightsCount,
    STRING_AGG(CAST(rr.RightId as NVARCHAR(10)) + ': ' + rln.Name, '; ') as AssignedRights,
    COUNT(DISTINCT ur.UserId) as AssignedUsersCount
FROM Roles r
JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en'
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId
LEFT JOIN RightsLocalizations rln ON rr.RightId = rln.RightId AND rln.Locale = 'en'
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId
WHERE r.Id = @AdminRoleId
GROUP BY r.Id, rl.Name, r.IsActive; 