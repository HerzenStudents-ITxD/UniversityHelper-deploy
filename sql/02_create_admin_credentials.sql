USE UserDB;

DECLARE @Now DATETIME2 = GETUTCDATE();

INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)
VALUES (
  NEWID(),
  '11111111-1111-1111-1111-111111111111',
  'adminlogin',
  'UpaFBBf5SnN2ZbD7sDDjeLCkDNHGM/4X5FerZVSb5vcVUtMrKjZ81OTj4FqqhYQerMCXOckFV1ELw+i3Aq/NlA==',
  'Random_Salt',
  1,
  @Now
);

PRINT 'Created admin credentials for login: adminlogin';
