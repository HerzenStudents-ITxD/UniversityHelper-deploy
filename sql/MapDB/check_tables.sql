SET NOCOUNT ON;
GO

PRINT '=== Database Check ===';
PRINT 'Checking database: ' + DB_NAME();
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

-- Получение списка таблиц
PRINT CHAR(10) + '=== Tables in ' + DB_NAME() + ' ===';
SELECT 
    t.name AS 'Table',
    SCHEMA_NAME(t.schema_id) AS 'Schema',
    p.rows AS 'RowCount'
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
GROUP BY t.name, SCHEMA_NAME(t.schema_id), p.rows
ORDER BY t.name;
GO

-- Проверка содержимого таблиц
DECLARE @TableName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnList NVARCHAR(MAX);

PRINT CHAR(10) + '=== Table Contents ===';

DECLARE TableCursor CURSOR FOR 
SELECT name FROM sys.tables ORDER BY name;

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Получаем список колонок
    SET @ColumnList = '';
    SELECT @ColumnList = @ColumnList + COLUMN_NAME + ', '
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @TableName
    ORDER BY ORDINAL_POSITION;
    
    SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 1);
    
    PRINT CHAR(10) + 'Table: ' + @TableName;
    PRINT 'Columns: ' + @ColumnList;
    PRINT REPLICATE('-', 60);
    
    -- Получаем данные
    SET @SQL = 'SELECT TOP 3 * FROM [' + @TableName + ']';
    EXEC sp_executesql @SQL;
    
    FETCH NEXT FROM TableCursor INTO @TableName;
END

CLOSE TableCursor;
DEALLOCATE TableCursor;
GO

PRINT CHAR(10) + '=== Check Completed ===';
PRINT 'All tables verified in database: ' + DB_NAME();
PRINT 'Execution time: ' + CONVERT(VARCHAR, GETDATE(), 120);
GO