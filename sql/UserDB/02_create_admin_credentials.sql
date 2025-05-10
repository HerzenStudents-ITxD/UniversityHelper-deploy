USE UserDB;
DECLARE @Now DATETIME2 = GETUTCDATE();
INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)
VALUES (
  NEWID(),
  '11111111-1111-1111-1111-111111111111',
  'adminlogin',
  '9LpqjwFggNlzxIpXdouqAL8HgJvFSsEVhNNx891zEPKZD+Pvbib8gfVUGNeCw5/MDQX15wDT62xl+f7U7wGHkw==',
  'Random_Salt',
  1,
  @Now
);
PRINT 'Created admin credentials for login: adminlogin';
