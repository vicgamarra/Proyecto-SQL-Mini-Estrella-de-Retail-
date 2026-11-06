/*
  SCRIPT PREVIO: inspección de la estructura real de RetailLimaOLTP.
  Ejecutar después de restaurar el .bak en SQL Server.
*/
USE RetailLimaOLTP;
GO

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

SELECT
    c.TABLE_SCHEMA AS Esquema,
    c.TABLE_NAME AS Tabla,
    c.COLUMN_NAME AS Columna,
    c.DATA_TYPE AS TipoDato,
    c.IS_NULLABLE AS PermiteNulos,
    c.ORDINAL_POSITION AS Posicion
FROM INFORMATION_SCHEMA.COLUMNS AS c
WHERE c.TABLE_SCHEMA = 'oltp'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;
GO

SELECT
    fk.name AS ForeignKey,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS EsquemaOrigen,
    OBJECT_NAME(fk.parent_object_id) AS TablaOrigen,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnaOrigen,
    OBJECT_NAME(fk.referenced_object_id) AS TablaDestino,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ColumnaDestino
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) = 'oltp'
ORDER BY TablaOrigen, ForeignKey;
GO
