USE UserDB;

-- Добавление пользователя с ID 22222222-2222-2222-2222-222222222222
INSERT INTO Users (Id, FirstName, LastName, MiddleName, IsAdmin, IsActive, CreatedBy)
VALUES ('22222222-2222-2222-2222-222222222222', 'Regular', 'User1', 'Middle', 0, 1, '11111111-1111-1111-1111-111111111111');

-- Добавление пользователя с ID 33333333-3333-3333-3333-333333333333
INSERT INTO Users (Id, FirstName, LastName, MiddleName, IsAdmin, IsActive, CreatedBy)
VALUES ('33333333-3333-3333-3333-333333333333', 'Regular', 'User2', 'Middle', 0, 1, '11111111-1111-1111-1111-111111111111');

-- Добавление учетных данных для пользователя 22222222-2222-2222-2222-222222222222
DECLARE @Now DATETIME2 = GETUTCDATE();
INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)
VALUES (
  NEWID(),
  '22222222-2222-2222-2222-222222222222',
  'user1login',
  '9LpqjwFggNlzxIpXdouqAL8HgJvFSsEVhNNx891zEPKZD+Pvbib8gfVUGNeCw5/MDQX15wDT62xl+f7U7wGHkw==',
  'Random_Salt',
  1,
  @Now
);
PRINT 'Created credentials for login: user1login';

-- Добавление учетных данных для пользователя 33333333-3333-3333-3333-333333333333
INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)
VALUES (
  NEWID(),
  '33333333-3333-3333-3333-333333333333',
  'user2login',
  '9LpqjwFggNlzxIpXdouqAL8HgJvFSsEVhNNx891zEPKZD+Pvbib8gfVUGNeCw5/MDQX15wDT62xl+f7U7wGHkw==',
  'Random_Salt',
  1,
  @Now
);
PRINT 'Created credentials for login: user2login';