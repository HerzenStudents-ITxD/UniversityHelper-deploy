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
PRINT 'Admin user data setup completed';
PRINT 'Checking user data:';
SELECT 
    u.Id,
    u.FirstName,
    u.LastName,
    u.MiddleName,
    u.IsAdmin,
    u.IsActive,
    ua.About,
    ua.DateOfBirth,
    uc.Value as Email,
    ua2.Value as Phone,
    ua3.Value as BaseEmail
FROM Users u
LEFT JOIN UsersAdditions ua ON u.Id = ua.UserId
LEFT JOIN UsersCommunications uc ON u.Id = uc.UserId AND uc.Type = 1
LEFT JOIN UsersCommunications ua2 ON u.Id = ua2.UserId AND ua2.Type = 2
LEFT JOIN UsersCommunications ua3 ON u.Id = ua3.UserId AND ua3.Type = 3
WHERE u.Id = @AdminUserId; 