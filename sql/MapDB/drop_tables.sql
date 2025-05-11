USE MapDB;
GO

PRINT 'Dropping all tables in MapDB...';

-- Отключаем ограничения внешних ключей
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Удаление таблиц
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PointTypeRectangularParallelepipeds')
    DROP TABLE PointTypeRectangularParallelepipeds;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PointTypeAssociations')
    DROP TABLE PointTypeAssociations;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PointAssociations')
    DROP TABLE PointAssociations;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PointLabels')
    DROP TABLE PointLabels;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PointPhotos')
    DROP TABLE PointPhotos;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PointTypes')
    DROP TABLE PointTypes;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Relations')
    DROP TABLE Relations;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Points')
    DROP TABLE Points;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Labels')
    DROP TABLE Labels;
GO

PRINT 'All tables in MapDB dropped successfully!';
GO