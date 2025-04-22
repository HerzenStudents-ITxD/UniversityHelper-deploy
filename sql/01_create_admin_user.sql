USE UserDB;

-- Create admin user with complete profile
INSERT INTO Users (Id, FirstName, LastName, MiddleName, Email, PhoneNumber, CreatedAt, UpdatedAt, IsActive)
VALUES ('11111111-1111-1111-1111-111111111111', 'Admin', 'User', 'System', 'admin@universityhelper.com', '+1234567890', GETDATE(), GETDATE(), 1);

-- Create admin profile
INSERT INTO UserProfiles (UserId, Bio, BirthDate, Gender, Address, UniversityId, FacultyId, DepartmentId, GroupId, StudentId, EmployeeId)
VALUES ('11111111-1111-1111-1111-111111111111', 'System Administrator', '1990-01-01', 'M', 'System Address', NULL, NULL, NULL, NULL, NULL, NULL);

-- Create admin settings
INSERT INTO UserSettings (UserId, Language, Theme, NotificationsEnabled, EmailNotifications, PushNotifications)
VALUES ('11111111-1111-1111-1111-111111111111', 'en', 'light', 1, 1, 1);

-- Create admin avatar
INSERT INTO UserAvatars (UserId, AvatarUrl, ThumbnailUrl, CreatedAt)
VALUES ('11111111-1111-1111-1111-111111111111', '/avatars/admin.png', '/avatars/admin_thumb.png', GETDATE());
