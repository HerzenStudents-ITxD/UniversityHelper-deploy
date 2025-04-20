USE UserDB;

DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @UserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';

INSERT INTO Users (Id, FirstName, LastName, MiddleName, IsAdmin, IsActive, CreatedBy)
VALUES (
  @UserId,
  'Admin',
  'System',
  'Adminovich',
  1,
  1,
  @UserId
);

PRINT 'Created admin user with Id: 11111111-1111-1111-1111-111111111111';
