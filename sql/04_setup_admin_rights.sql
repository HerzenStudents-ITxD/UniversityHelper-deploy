USE RightsDB;

-- Create Rights table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Rights')
BEGIN
    CREATE TABLE Rights (
        Id INT PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX),
        IsActive BIT DEFAULT 1,
        CreatedBy UNIQUEIDENTIFIER,
        CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE()
    );
END

-- Create Roles table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
BEGIN
    CREATE TABLE Roles (
        Id UNIQUEIDENTIFIER PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX),
        IsSystem BIT DEFAULT 0,
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        UpdatedAt DATETIME2 DEFAULT GETDATE()
    );
END

-- Create RolesRights table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights')
BEGIN
    CREATE TABLE RolesRights (
        RoleId UNIQUEIDENTIFIER NOT NULL,
        RightId INT NOT NULL,
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        PRIMARY KEY (RoleId, RightId),
        FOREIGN KEY (RoleId) REFERENCES Roles(Id),
        FOREIGN KEY (RightId) REFERENCES Rights(Id)
    );
END

-- Create UsersRoles table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles')
BEGIN
    CREATE TABLE UsersRoles (
        UserId UNIQUEIDENTIFIER NOT NULL,
        RoleId UNIQUEIDENTIFIER NOT NULL,
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        PRIMARY KEY (UserId, RoleId),
        FOREIGN KEY (RoleId) REFERENCES Roles(Id)
    );
END

-- Insert admin rights if they don't exist
MERGE INTO Rights AS target
USING (VALUES 
    (1000, 'UserServiceAdmin', 'Administrator of User Service'),
    (2000, 'AuthServiceAdmin', 'Administrator of Auth Service'),
    (3000, 'UniversityServiceAdmin', 'Administrator of University Service'),
    (4000, 'RightsServiceAdmin', 'Administrator of Rights Service'),
    (5000, 'AnalyticsServiceAdmin', 'Administrator of Analytics Service'),
    (6000, 'EmailServiceAdmin', 'Administrator of Email Service'),
    (7000, 'FeedbackServiceAdmin', 'Administrator of Feedback Service'),
    (1600, 'NotificationServiceAdmin', 'Administrator of Notification Service'),
    (800, 'MapServiceAdmin', 'Administrator of Map Service'),
    (900, 'CommunityServiceAdmin', 'Administrator of Community Service'),
    (1000, 'EventServiceAdmin', 'Administrator of Event Service'),
    (1100, 'PostServiceAdmin', 'Administrator of Post Service'),
    (1200, 'GroupServiceAdmin', 'Administrator of Group Service'),
    (1300, 'TimetableServiceAdmin', 'Administrator of Timetable Service'),
    (1400, 'NoteServiceAdmin', 'Administrator of Note Service'),
    (1500, 'WikiServiceAdmin', 'Administrator of Wiki Service'),
    (1600, 'NewsServiceAdmin', 'Administrator of News Service')
) AS source (Id, Name, Description)
ON target.Id = source.Id
WHEN NOT MATCHED THEN
    INSERT (Id, Name, Description, IsActive)
    VALUES (source.Id, source.Name, source.Description, 1);

-- Create or update admin role
DECLARE @AdminRoleId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';

IF NOT EXISTS (SELECT 1 FROM Roles WHERE Id = @AdminRoleId)
BEGIN
    INSERT INTO Roles (Id, Name, Description, IsSystem, CreatedAt, UpdatedAt)
    VALUES (@AdminRoleId, 'SystemAdmin', 'System Administrator', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE Roles
    SET Name = 'SystemAdmin',
        Description = 'System Administrator',
        IsSystem = 1,
        UpdatedAt = GETDATE()
    WHERE Id = @AdminRoleId;
END

-- Assign all admin rights to the role
INSERT INTO RolesRights (RoleId, RightId)
SELECT @AdminRoleId, Id
FROM Rights
WHERE Id IN (1000, 2000, 3000, 4000, 5000, 6000, 7000, 1600, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600)
AND NOT EXISTS (
    SELECT 1 FROM RolesRights 
    WHERE RoleId = @AdminRoleId 
    AND RightId = Rights.Id
);

-- Assign role to user
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';

IF NOT EXISTS (SELECT 1 FROM UsersRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId)
BEGIN
    INSERT INTO UsersRoles (UserId, RoleId)
    VALUES (@AdminUserId, @AdminRoleId);
END

-- Verify the setup
SELECT 'Roles' as TableName, COUNT(*) as Count FROM Roles
UNION ALL
SELECT 'Rights', COUNT(*) FROM Rights
UNION ALL
SELECT 'RolesRights', COUNT(*) FROM RolesRights
UNION ALL
SELECT 'UsersRoles', COUNT(*) FROM UsersRoles; 