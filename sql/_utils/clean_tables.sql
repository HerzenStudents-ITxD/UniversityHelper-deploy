SET NOCOUNT ON;
GO

PRINT '=== Database Cleanup ===';
PRINT 'Cleaning database: ' + DB_NAME();
GO

-- Проверка существования БД
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME())
BEGIN
    PRINT 'ERROR: Database ' + DB_NAME() + ' does not exist';
    SELECT name AS 'Available databases' FROM sys.databases;
    RAISERROR('Database not found', 16, 1);
    RETURN;
END
GO

-- Отключение ограничений внешнего ключа
PRINT CHAR(10) + 'Disabling foreign key constraints...';
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Очистка таблиц с учетом зависимостей
PRINT CHAR(10) + 'Cleaning tables...';
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @TableName NVARCHAR(128);
DECLARE @SchemaName NVARCHAR(128);

-- Создаем временную таблицу для хранения информации о таблицах и их зависимостях
IF OBJECT_ID('tempdb..#TablesToDelete') IS NOT NULL
    DROP TABLE #TablesToDelete;

CREATE TABLE #TablesToDelete (
    TableName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    HasDependencies BIT,
    Processed BIT DEFAULT 0,
    DeleteOrder INT NULL
);

-- Заполняем временную таблицу всеми таблицами из текущей БД
INSERT INTO #TablesToDelete (TableName, SchemaName, HasDependencies)
SELECT 
    t.name AS TableName,
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    CASE WHEN EXISTS (
        SELECT 1 
        FROM sys.foreign_keys fk 
        WHERE fk.parent_object_id = t.object_id
    ) THEN 1 ELSE 0 END AS HasDependencies
FROM sys.tables t
WHERE t.is_ms_shipped = 0;

-- Определяем порядок удаления данных (сначала таблицы без зависимостей)
DECLARE @CurrentOrder INT = 1;
WHILE EXISTS (SELECT 1 FROM #TablesToDelete WHERE Processed = 0)
BEGIN
    -- Находим таблицы без зависимостей или те, от которых уже ничего не зависит
    UPDATE #TablesToDelete
    SET DeleteOrder = @CurrentOrder,
        Processed = 1
    WHERE TableName IN (
        SELECT t.TableName
        FROM #TablesToDelete t
        WHERE t.Processed = 0
        AND NOT EXISTS (
            SELECT 1
            FROM sys.foreign_keys fk
            JOIN sys.tables rt ON fk.referenced_object_id = rt.object_id
            JOIN #TablesToDelete d ON rt.name = d.TableName AND SCHEMA_NAME(rt.schema_id) = d.SchemaName
            WHERE fk.parent_object_id = OBJECT_ID(QUOTENAME(t.SchemaName) + '.' + QUOTENAME(t.TableName))
            AND d.Processed = 0
        )
    );
    
    IF @@ROWCOUNT = 0
    BEGIN
        -- Если не удалось найти независимые таблицы, но есть необработанные,
        -- принудительно обрабатываем оставшиеся (возможны циклические зависимости)
        UPDATE TOP(1) #TablesToDelete
        SET DeleteOrder = @CurrentOrder,
            Processed = 1
        WHERE Processed = 0;
    END
    
    SET @CurrentOrder = @CurrentOrder + 1;
END

-- Выполняем удаление данных в правильном порядке
DECLARE TableCursor CURSOR FOR 
SELECT SchemaName, TableName 
FROM #TablesToDelete 
ORDER BY DeleteOrder;

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Deleting from: ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);
    
    SET @SQL = 'DELETE FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);
    EXEC sp_executesql @SQL;
    
    PRINT '  Rows affected: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
    
    FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;
END

CLOSE TableCursor;
DEALLOCATE TableCursor;

DROP TABLE #TablesToDelete;
GO

-- Включение ограничений внешнего ключа
PRINT CHAR(10) + 'Enabling foreign key constraints...';
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';
GO

PRINT CHAR(10) + '=== Cleanup Completed ===';
PRINT 'All tables cleaned in database: ' + DB_NAME();
PRINT 'Execution time: ' + CONVERT(VARCHAR, GETDATE(), 120);
GO