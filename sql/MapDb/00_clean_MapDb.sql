-- Clean MapDB
USE MapDB;

PRINT 'Cleaning MapDB...';

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables (order matters due to FK constraints)
DELETE FROM PointTypeRectangularParallelepipeds;
DELETE FROM PointTypeAssociations;
DELETE FROM PointAssociations;
DELETE FROM PointLabels;
DELETE FROM PointPhotos;
DELETE FROM PointTypes;
DELETE FROM Relations;
DELETE FROM Points;
DELETE FROM Labels;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

PRINT 'MapDB cleaned successfully!';
GO