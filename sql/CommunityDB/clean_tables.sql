-- Clean CommunityDB
USE CommunityDB;

PRINT 'Cleaning CommunityDB...';

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables (order matters due to FK constraints)
DELETE FROM Participating;
DELETE FROM NewsPhoto;
DELETE FROM News;
DELETE FROM HiddenCommunities;
DELETE FROM Agents;
DELETE FROM Communities;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

PRINT 'CommunityDB cleaned successfully!';
GO