-- Clean UserDB
USE UserDB;

PRINT 'Cleaning UserDB...';

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables (order matters due to FK constraints)
DELETE FROM UsersAdditions;
DELETE FROM UsersCommunications;
DELETE FROM UsersAvatars;
DELETE FROM UsersCredentials;
DELETE FROM Users;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

PRINT 'UserDB cleaned successfully!';
GO