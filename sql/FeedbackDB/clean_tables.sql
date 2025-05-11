-- Clean FeedbackDB
USE FeedbackDB;

PRINT 'Cleaning FeedbackDB...';

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables (order matters due to FK constraints)
DELETE FROM Images;
DELETE FROM FeedbackTypes;
DELETE FROM Feedbacks;
DELETE FROM Types;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

PRINT 'FeedbackDB cleaned successfully!';
GO