USE CommunityDB;
GO

PRINT 'Dropping all tables in CommunityDB...';

-- Отключаем ограничения внешних ключей
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Удаление таблиц
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Participating')
    DROP TABLE Participating;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'NewsPhoto')
    DROP TABLE NewsPhoto;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'News')
    DROP TABLE News;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'HiddenCommunities')
    DROP TABLE HiddenCommunities;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Agents')
    DROP TABLE Agents;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Communities')
    DROP TABLE Communities;
GO

PRINT 'All tables in CommunityDB dropped successfully!';
GO