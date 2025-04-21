USE UserDB;

-- Declare variables
DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @AdminRoleId UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';

-- Create admin role
INSERT INTO Roles (Id, Name, IsActive, CreatedBy, CreatedAtUtc)
VALUES (
    @AdminRoleId,
    'System Administrator',
    1,
    @AdminUserId,
    @Now
);

-- Create role localization
INSERT INTO RolesLocalizations (Id, RoleId, Name, Locale, IsActive, CreatedBy, CreatedAtUtc)
VALUES (
    NEWID(),
    @AdminRoleId,
    'System Administrator',
    'en-US',
    1,
    @AdminUserId,
    @Now
);

-- Create rights
DECLARE @Rights TABLE (Id INT, Name NVARCHAR(100));
INSERT INTO @Rights (Id, Name)
VALUES 
    (1, 'UserManagement'),
    (2, 'RoleManagement'),
    (3, 'RightsManagement'),
    (4, 'SystemConfiguration');

-- Insert rights
INSERT INTO Rights (Id, Name, IsActive, CreatedBy, CreatedAtUtc)
SELECT Id, Name, 1, @AdminUserId, @Now
FROM @Rights;

-- Create rights localizations
INSERT INTO RightsLocalizations (Id, RightId, Name, Locale, IsActive, CreatedBy, CreatedAtUtc)
SELECT 
    NEWID(),
    Id,
    Name,
    'en-US',
    1,
    @AdminUserId,
    @Now
FROM @Rights;

-- Assign rights to admin role
INSERT INTO RolesRights (Id, RoleId, RightId, CreatedBy, CreatedAtUtc)
SELECT 
    NEWID(),
    @AdminRoleId,
    Id,
    @AdminUserId,
    @Now
FROM @Rights;

-- Assign admin role to admin user
INSERT INTO UsersRoles (Id, UserId, RoleId, IsActive, CreatedBy, CreatedAtUtc)
VALUES (
    NEWID(),
    @AdminUserId,
    @AdminRoleId,
    1,
    @AdminUserId,
    @Now
);

-- Verify setup
PRINT 'Admin rights setup completed';
PRINT 'Checking roles and rights:';
SELECT r.Name as RoleName, rl.Name as LocalizedRoleName, rl.Locale
FROM Roles r
JOIN RolesLocalizations rl ON r.Id = rl.RoleId
WHERE r.Id = @AdminRoleId;

PRINT 'Checking assigned rights:';
SELECT r.Name as RightName, rl.Name as LocalizedRightName, rl.Locale
FROM RolesRights rr
JOIN Rights r ON rr.RightId = r.Id
JOIN RightsLocalizations rl ON r.Id = rl.RightId
WHERE rr.RoleId = @AdminRoleId; 