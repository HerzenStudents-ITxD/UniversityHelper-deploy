USE UserDB;

-- Create admin user
INSERT INTO Users (Id, FirstName, LastName, MiddleName, IsAdmin, IsActive, CreatedBy)
VALUES ('11111111-1111-1111-1111-111111111111', 'Admin', 'User', 'System', 1, 1, '11111111-1111-1111-1111-111111111111');

-- Create admin user additions
INSERT INTO UsersAdditions (Id, UserId, About, DateOfBirth, ModifiedBy, ModifiedAtUtc)
VALUES (NEWID(), '11111111-1111-1111-1111-111111111111', 'System Administrator', '1990-01-01', '11111111-1111-1111-1111-111111111111', GETUTCDATE());

-- Create admin user communications
INSERT INTO UsersCommunications (Id, UserId, Type, Value, IsConfirmed, CreatedBy, CreatedAtUtc)
VALUES 
(NEWID(), '11111111-1111-1111-1111-111111111111', 1, 'admin@universityhelper.com', 1, '11111111-1111-1111-1111-111111111111', GETUTCDATE()),
(NEWID(), '11111111-1111-1111-1111-111111111111', 2, '+1234567890', 1, '11111111-1111-1111-1111-111111111111', GETUTCDATE()),
(NEWID(), '11111111-1111-1111-1111-111111111111', 3, 'admin@universityhelper.com', 1, '11111111-1111-1111-1111-111111111111', GETUTCDATE());

-- Create admin user avatar
INSERT INTO UsersAvatars (Id, UserId, AvatarId, IsCurrentAvatar)
VALUES (NEWID(), '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 1);
