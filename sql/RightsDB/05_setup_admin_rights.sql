USE RightsDB;

-- Declare variables
DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @AdminRoleId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';

-- Check if admin role already exists to avoid duplicates
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Id = @AdminRoleId)
BEGIN
    -- Insert admin role
    INSERT INTO Roles (Id, IsActive, CreatedBy)
    VALUES (@AdminRoleId, 1, @AdminUserId);
END;

-- Insert admin role localizations
IF NOT EXISTS (SELECT 1 FROM RolesLocalizations WHERE RoleId = @AdminRoleId)
BEGIN
    INSERT INTO RolesLocalizations (Id, RoleId, Locale, Name, Description, IsActive, CreatedBy, CreatedAtUtc)
    VALUES 
        (NEWID(), @AdminRoleId, 'en', 'System Administrator', 'Full access to all system services', 1, @AdminUserId, @Now),
        (NEWID(), @AdminRoleId, 'ru', 'Системный администратор', 'Полный доступ ко всем сервисам системы', 1, @AdminUserId, @Now);
END;

-- Define all service rights
DECLARE @Rights TABLE (
    RightId INT,
    NameEn NVARCHAR(100),
    NameRu NVARCHAR(100),
    DescriptionEn NVARCHAR(255),
    DescriptionRu NVARCHAR(255)
);

INSERT INTO @Rights (RightId, NameEn, NameRu, DescriptionEn, DescriptionRu) VALUES 
    (1000, 'User Service Admin', 'Администратор сервиса пользователей', 'Manage user accounts and profiles', 'Управление учетными записями и профилями пользователей'),
    (2000, 'Auth Service Admin', 'Администратор сервиса аутентификации', 'Manage authentication and authorization', 'Управление аутентификацией и авторизацией'),
    (3000, 'University Service Admin', 'Администратор сервиса университета', 'Manage university-related data', 'Управление данными университета'),
    (4000, 'Rights Service Admin', 'Администратор сервиса прав', 'Manage roles and permissions', 'Управление ролями и правами'),
    (5000, 'Analytics Service Admin', 'Администратор сервиса аналитики', 'Access and manage analytics data', 'Доступ и управление данными аналитики'),
    (6000, 'Email Service Admin', 'Администратор сервиса email', 'Manage email communications', 'Управление email-коммуникациями'),
    (7000, 'Feedback Service Admin', 'Администратор сервиса обратной связи', 'Manage user feedback', 'Управление обратной связью пользователей'),
    (800, 'Map Service Admin', 'Администратор сервиса карт', 'Manage map-related features', 'Управление функциями карт'),
    (900, 'Community Service Admin', 'Администратор сервиса сообществ', 'Manage community features', 'Управление функциями сообществ'),
    (1100, 'Post Service Admin', 'Администратор сервиса постов', 'Manage posts and content', 'Управление постами и контентом'),
    (1200, 'Group Service Admin', 'Администратор сервиса групп', 'Manage group functionalities', 'Управление функциями групп'),
    (1300, 'Timetable Service Admin', 'Администратор сервиса расписания', 'Manage schedules and timetables', 'Управление расписаниями'),
    (1400, 'Note Service Admin', 'Администратор сервиса заметок', 'Manage user notes', 'Управление заметками пользователей'),
    (1500, 'Wiki Service Admin', 'Администратор сервиса вики', 'Manage wiki content', 'Управление контентом вики'),
    (1600, 'News Service Admin', 'Администратор сервиса новостей', 'Manage news updates', 'Управление новостями'),
    (1700, 'Event Service Admin', 'Администратор сервиса событий', 'Manage events and activities', 'Управление событиями и мероприятиями');

-- Insert rights (assuming Rights table exists)
IF NOT EXISTS (SELECT 1 FROM Rights WHERE RightId IN (SELECT RightId FROM @Rights))
BEGIN
    INSERT INTO Rights (RightId, CreatedBy)
    SELECT RightId, @AdminUserId
    FROM @Rights;
END;

-- Insert rights localizations
IF NOT EXISTS (SELECT 1 FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM @Rights))
BEGIN
    INSERT INTO RightsLocalizations (Id, RightId, Locale, Name, Description)
    SELECT NEWID(), RightId, 'en', NameEn, DescriptionEn FROM @Rights
    UNION ALL
    SELECT NEWID(), RightId, 'ru', NameRu, DescriptionRu FROM @Rights;
END;

-- Assign rights to admin role
IF NOT EXISTS (SELECT 1 FROM RolesRights WHERE RoleId = @AdminRoleId)
BEGIN
    INSERT INTO RolesRights (Id, RoleId, RightId, CreatedBy)
    SELECT NEWID(), @AdminRoleId, RightId, @AdminUserId
    FROM @Rights;
END;

-- Assign admin role to user
IF NOT EXISTS (SELECT 1 FROM UsersRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId)
BEGIN
    INSERT INTO UsersRoles (Id, UserId, RoleId, IsActive, CreatedBy)
    VALUES (NEWID(), @AdminUserId, @AdminRoleId, 1, @AdminUserId);
END;

-- Verify setup
PRINT 'Verifying admin role and rights setup...';

-- Check table counts
SELECT 'Roles' AS TableName, COUNT(*) AS Count FROM Roles WHERE Id = @AdminRoleId
UNION ALL
SELECT 'RolesLocalizations', COUNT(*) FROM RolesLocalizations WHERE RoleId = @AdminRoleId
UNION ALL
SELECT 'Rights', COUNT(*) FROM Rights WHERE RightId IN (SELECT RightId FROM @Rights)
UNION ALL
SELECT 'RightsLocalizations', COUNT(*) FROM RightsLocalizations WHERE RightId IN (SELECT RightId FROM @Rights)
UNION ALL
SELECT 'RolesRights', COUNT(*) FROM RolesRights WHERE RoleId = @AdminRoleId
UNION ALL
SELECT 'UsersRoles', COUNT(*) FROM UsersRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId;

-- Check Roles table
PRINT 'Roles table details:';
SELECT Id, IsActive, CreatedBy
FROM Roles 
WHERE Id = @AdminRoleId;

-- Check RolesLocalizations table
PRINT 'RolesLocalizations table details:';
SELECT Id, RoleId, Locale, Name, Description, IsActive, CreatedBy, CreatedAtUtc
FROM RolesLocalizations 
WHERE RoleId = @AdminRoleId;

-- Check Rights table
PRINT 'Rights table details:';
SELECT RightId, CreatedBy
FROM Rights 
WHERE RightId IN (SELECT RightId FROM @Rights);

-- Check RightsLocalizations table
PRINT 'RightsLocalizations table details:';
SELECT Id, RightId, Locale, Name, Description
FROM RightsLocalizations 
WHERE RightId IN (SELECT RightId FROM @Rights)
ORDER BY RightId, Locale;

-- Check RolesRights table
PRINT 'RolesRights table details:';
SELECT Id, RoleId, RightId, CreatedBy
FROM RolesRights 
WHERE RoleId = @AdminRoleId
ORDER BY RightId;

-- Check UsersRoles table
PRINT 'UsersRoles table details:';
SELECT Id, UserId, RoleId, IsActive, CreatedBy
FROM UsersRoles 
WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId;

-- Final verification summary
PRINT 'Final verification summary:';
SELECT 
    r.Id AS RoleId,
    rl.Name AS RoleName,
    STRING_AGG(rloc.Name, '; ') AS RightNames,
    ur.UserId
FROM Roles r
LEFT JOIN RolesLocalizations rl ON r.Id = rl.RoleId AND rl.Locale = 'en'
LEFT JOIN RolesRights rr ON r.Id = rr.RoleId
LEFT JOIN RightsLocalizations rloc ON rr.RightId = rloc.RightId AND rloc.Locale = 'en'
LEFT JOIN UsersRoles ur ON r.Id = ur.RoleId
WHERE r.Id = @AdminRoleId
GROUP BY r.Id, rl.Name, ur.UserId;