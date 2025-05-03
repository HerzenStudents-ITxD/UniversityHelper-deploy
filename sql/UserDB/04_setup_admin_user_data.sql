USE UserDB;

-- Declare variables
DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @AdminAvatarId UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @AdminCommunicationId UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444444';

-- Update user with additional information
UPDATE Users
SET 
    FirstName = 'System',
    LastName = 'Administrator',
    MiddleName = 'Admin',
    IsAdmin = 1,
    IsActive = 1,
    CreatedBy = @AdminUserId
WHERE Id = @AdminUserId;

-- Add user addition information
INSERT INTO UsersAdditions (Id, UserId, About, DateOfBirth, ModifiedBy, ModifiedAtUtc)
VALUES (
    NEWID(),
    @AdminUserId,
    'System administrator with full access to all features and settings',
    '1990-01-01',
    @AdminUserId,
    @Now
);

-- Add user communications
INSERT INTO UsersCommunications (Id, UserId, Type, Value, IsConfirmed, CreatedBy, CreatedAtUtc)
VALUES 
    (NEWID(), @AdminUserId, 1, 'admin@universityhelper.com', 1, @AdminUserId, @Now), -- Email
    (NEWID(), @AdminUserId, 2, '+1234567890', 1, @AdminUserId, @Now), -- Phone
    (NEWID(), @AdminUserId, 3, 'admin@universityhelper.com', 1, @AdminUserId, @Now); -- Base Email

-- Add user avatar
INSERT INTO UsersAvatars (Id, UserId, AvatarId, IsCurrentAvatar)
VALUES (
    NEWID(),
    @AdminUserId,
    @AdminAvatarId,
    1
);

-- Verify setup
PRINT 'Verifying admin user setup...';

-- Check table counts
SELECT 'Users' as TableName, COUNT(*) as Count FROM Users WHERE Id = @AdminUserId
UNION ALL
SELECT 'UsersAdditions', COUNT(*) FROM UsersAdditions WHERE UserId = @AdminUserId
UNION ALL
SELECT 'UsersCommunications', COUNT(*) FROM UsersCommunications WHERE UserId = @AdminUserId
UNION ALL
SELECT 'UsersAvatars', COUNT(*) FROM UsersAvatars WHERE UserId = @AdminUserId;

-- Check Users table
PRINT 'Users table details:';
SELECT 
    Id,
    FirstName,
    LastName,
    MiddleName,
    IsAdmin,
    IsActive,
    CreatedBy
    -- CreatedAtUtc
FROM Users 
WHERE Id = @AdminUserId;

-- Check UsersAdditions table
PRINT 'UsersAdditions table details:';
SELECT 
    Id,
    UserId,
    About,
    DateOfBirth,
    ModifiedBy,
    ModifiedAtUtc
FROM UsersAdditions 
WHERE UserId = @AdminUserId;

-- Check UsersCommunications table
PRINT 'UsersCommunications table details:';
SELECT 
    Id,
    UserId,
    Type,
    Value,
    IsConfirmed,
    CreatedBy,
    CreatedAtUtc
FROM UsersCommunications 
WHERE UserId = @AdminUserId
ORDER BY Type;

-- Check UsersAvatars table
PRINT 'UsersAvatars table details:';
SELECT 
    Id,
    UserId,
    AvatarId,
    IsCurrentAvatar
FROM UsersAvatars 
WHERE UserId = @AdminUserId;

-- Final verification summary
SELECT 
    u.Id as UserId,
    u.FirstName + ' ' + u.LastName as FullName,
    u.IsAdmin,
    ua.About,
    STRING_AGG(CASE uc.Type 
        WHEN 1 THEN 'Email: ' + uc.Value
        WHEN 2 THEN 'Phone: ' + uc.Value
        WHEN 3 THEN 'Base Email: ' + uc.Value
    END, '; ') as Communications,
    uav.AvatarId
FROM Users u
LEFT JOIN UsersAdditions ua ON u.Id = ua.UserId
LEFT JOIN UsersCommunications uc ON u.Id = uc.UserId
LEFT JOIN UsersAvatars uav ON u.Id = uav.UserId AND uav.IsCurrentAvatar = 1
WHERE u.Id = @AdminUserId
GROUP BY u.Id, u.FirstName, u.LastName, u.IsAdmin, ua.About, uav.AvatarId; 