USE RightsDB;

-- Create Roles table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
BEGIN
    CREATE TABLE Roles (
        Id UNIQUEIDENTIFIER PRIMARY KEY,
        CreatedBy UNIQUEIDENTIFIER,
        IsActive BIT DEFAULT 1,
        CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE()
    );
END

-- Create RolesLocalizations table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations')
BEGIN
    CREATE TABLE RolesLocalizations (
        Id UNIQUEIDENTIFIER PRIMARY KEY,
        RoleId UNIQUEIDENTIFIER NOT NULL,
        Locale NVARCHAR(10) NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        FOREIGN KEY (RoleId) REFERENCES Roles(Id)
    );
END

-- Create RightsLocalizations table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations')
BEGIN
    CREATE TABLE RightsLocalizations (
        Id UNIQUEIDENTIFIER PRIMARY KEY,
        RightId INT NOT NULL,
        Locale NVARCHAR(10) NOT NULL,
        Name NVARCHAR(100) NOT NULL
    );
END

-- Create RolesRights table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights')
BEGIN
    CREATE TABLE RolesRights (
        Id UNIQUEIDENTIFIER PRIMARY KEY,
        RoleId UNIQUEIDENTIFIER NOT NULL,
        RightId INT NOT NULL,
        CreatedBy UNIQUEIDENTIFIER,
        CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE(),
        FOREIGN KEY (RoleId) REFERENCES Roles(Id)
    );
END

-- Create UsersRoles table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles')
BEGIN
    CREATE TABLE UsersRoles (
        Id UNIQUEIDENTIFIER PRIMARY KEY,
        UserId UNIQUEIDENTIFIER NOT NULL,
        RoleId UNIQUEIDENTIFIER NOT NULL,
        IsActive BIT DEFAULT 1,
        CreatedAtUtc DATETIME2 DEFAULT GETUTCDATE(),
        FOREIGN KEY (RoleId) REFERENCES Roles(Id)
    );
END

-- Insert admin role if it doesn't exist
DECLARE @AdminRoleId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';

IF NOT EXISTS (SELECT 1 FROM Roles WHERE Id = @AdminRoleId)
BEGIN
    INSERT INTO Roles (Id, CreatedBy, IsActive)
    VALUES (@AdminRoleId, @AdminUserId, 1);
END

-- Insert admin role localization
IF NOT EXISTS (SELECT 1 FROM RolesLocalizations WHERE RoleId = @AdminRoleId AND Locale = 'en')
BEGIN
    INSERT INTO RolesLocalizations (Id, RoleId, Locale, Name)
    VALUES (NEWID(), @AdminRoleId, 'en', 'System Administrator');
END

-- Insert admin rights
DECLARE @Rights TABLE (RightId INT);
INSERT INTO @Rights (RightId) VALUES (1000), (2000), (3000), (4000), (5000), (6000), (7000), (800), (900), (1000), (1100), (1200), (1300), (1400), (1500), (1600);

-- Insert rights localizations
MERGE INTO RightsLocalizations AS target
USING (SELECT RightId, 'en' AS Locale, 
    CASE RightId
        WHEN 1000 THEN 'User Service Admin'
        WHEN 2000 THEN 'Auth Service Admin'
        WHEN 3000 THEN 'University Service Admin'
        WHEN 4000 THEN 'Rights Service Admin'
        WHEN 5000 THEN 'Analytics Service Admin'
        WHEN 6000 THEN 'Email Service Admin'
        WHEN 7000 THEN 'Feedback Service Admin'
        WHEN 800 THEN 'Map Service Admin'
        WHEN 900 THEN 'Community Service Admin'
        WHEN 1000 THEN 'Event Service Admin'
        WHEN 1100 THEN 'Post Service Admin'
        WHEN 1200 THEN 'Group Service Admin'
        WHEN 1300 THEN 'Timetable Service Admin'
        WHEN 1400 THEN 'Note Service Admin'
        WHEN 1500 THEN 'Wiki Service Admin'
        WHEN 1600 THEN 'News Service Admin'
    END AS Name
FROM @Rights) AS source
ON target.RightId = source.RightId AND target.Locale = source.Locale
WHEN NOT MATCHED THEN
    INSERT (Id, RightId, Locale, Name)
    VALUES (NEWID(), source.RightId, source.Locale, source.Name);

-- Assign rights to admin role
INSERT INTO RolesRights (Id, RoleId, RightId, CreatedBy)
SELECT NEWID(), @AdminRoleId, RightId, @AdminUserId
FROM @Rights r
WHERE NOT EXISTS (
    SELECT 1 FROM RolesRights 
    WHERE RoleId = @AdminRoleId 
    AND RightId = r.RightId
);

-- Assign admin role to user
IF NOT EXISTS (SELECT 1 FROM UsersRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId)
BEGIN
    INSERT INTO UsersRoles (Id, UserId, RoleId, IsActive)
    VALUES (NEWID(), @AdminUserId, @AdminRoleId, 1);
END

-- Verify the setup
SELECT 'Roles' as TableName, COUNT(*) as Count FROM Roles
UNION ALL
SELECT 'RolesLocalizations', COUNT(*) FROM RolesLocalizations
UNION ALL
SELECT 'RightsLocalizations', COUNT(*) FROM RightsLocalizations
UNION ALL
SELECT 'RolesRights', COUNT(*) FROM RolesRights
UNION ALL
SELECT 'UsersRoles', COUNT(*) FROM UsersRoles; 