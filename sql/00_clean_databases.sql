-- Clean UserDB
USE UserDB;

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables
DELETE FROM UsersAdditions;
DELETE FROM UsersCommunications;
DELETE FROM UsersAvatars;
DELETE FROM UsersCredentials;
DELETE FROM Users;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Clean CommunityDB
USE CommunityDB;

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables
DELETE FROM Participating;
DELETE FROM NewsPhoto;
DELETE FROM News;
DELETE FROM HiddenCommunities;
DELETE FROM Agents;
DELETE FROM Communities;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Clean RightsDB
USE RightsDB;

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables
DELETE FROM UsersRoles;
DELETE FROM RolesRights;
DELETE FROM RightsLocalizations;
DELETE FROM RolesLocalizations;
DELETE FROM Roles;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

PRINT 'All databases have been cleaned successfully!'; 