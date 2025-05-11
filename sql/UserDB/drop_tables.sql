USE UserDB;
GO

PRINT 'Dropping all tables in UserDB...';

-- Отключаем ограничения внешних ключей
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Удаление таблиц в правильном порядке (сначала зависимые)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersAdditions')
    DROP TABLE UsersAdditions;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersCommunications')
    DROP TABLE UsersCommunications;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersAvatars')
    DROP TABLE UsersAvatars;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersCredentials')
    DROP TABLE UsersCredentials;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PendingUsers')
    DROP TABLE PendingUsers;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
    DROP TABLE Users;
GO

PRINT 'All tables in UserDB dropped successfully!';
GO