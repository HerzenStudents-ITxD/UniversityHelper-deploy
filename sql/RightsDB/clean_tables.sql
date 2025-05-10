-- Clean RightsDB
USE RightsDB;

PRINT 'Cleaning RightsDB...';

-- Disable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Delete data from all tables (order matters due to FK constraints)
DELETE FROM UsersRoles;
DELETE FROM RolesRights;
DELETE FROM RightsLocalizations;
DELETE FROM RolesLocalizations;
DELETE FROM Roles;
DELETE FROM Rights;

-- Enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

PRINT 'RightsDB cleaned successfully!';
GO