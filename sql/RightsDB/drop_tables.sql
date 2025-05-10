USE RightsDB;
GO

PRINT 'Dropping all tables in RightsDB...';

-- Отключаем ограничения внешних ключей
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Удаление таблиц
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'UsersRoles')
    DROP TABLE UsersRoles;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesRights')
    DROP TABLE RolesRights;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RightsLocalizations')
    DROP TABLE RightsLocalizations;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RolesLocalizations')
    DROP TABLE RolesLocalizations;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
    DROP TABLE Roles;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Rights')
    DROP TABLE Rights;
GO

PRINT 'All tables in RightsDB dropped successfully!';
GO