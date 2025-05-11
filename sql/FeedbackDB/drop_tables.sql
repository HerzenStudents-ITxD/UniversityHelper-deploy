USE FeedbackDB;
GO

PRINT 'Dropping all tables in FeedbackDB...';

-- Отключаем ограничения внешних ключей
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Удаление таблиц
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Images')
    DROP TABLE Images;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'FeedbackTypes')
    DROP TABLE FeedbackTypes;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Feedbacks')
    DROP TABLE Feedbacks;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Types')
    DROP TABLE Types;
GO

PRINT 'All tables in FeedbackDB dropped successfully!';
GO