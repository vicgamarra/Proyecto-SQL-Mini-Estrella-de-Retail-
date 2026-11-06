/* Parte E - Procedimiento con transacción, TRY/CATCH, log y THROW */
USE RetailLimaOLTP;
GO

IF OBJECT_ID('dwh.LogCarga', 'U') IS NULL
BEGIN
    CREATE TABLE dwh.LogCarga (
        log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        fecha_inicio DATETIME2(0) NOT NULL,
        fecha_fin DATETIME2(0) NULL,
        estado VARCHAR(20) NOT NULL,
        mensaje NVARCHAR(4000) NULL,
        filas_fact_insertadas BIGINT NULL,
        usuario_sql SYSNAME NOT NULL DEFAULT SUSER_SNAME()
    );
END;
GO

CREATE OR ALTER PROCEDURE dwh.usp_CargarDWH
    @forzar_error BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @log_id BIGINT,
            @fecha_inicio DATETIME2(0) = SYSDATETIME(),
            @filas_antes BIGINT,
            @filas_despues BIGINT;

    INSERT INTO dwh.LogCarga (fecha_inicio, estado, mensaje)
    VALUES (@fecha_inicio, 'INICIADO', N'Inicio de carga DWH');
    SET @log_id = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @forzar_error = 1
            THROW 51000, 'Error de prueba solicitado por @forzar_error.', 1;

        SET @filas_antes = (SELECT COUNT_BIG(*) FROM dwh.FactVentas);

        /* Dimensión tienda */
        INSERT INTO dwh.DimTienda (tienda_id, nombre_tienda, distrito)
        SELECT t.tienda_id, t.nombre_tienda, t.Distrito
        FROM oltp.Tiendas AS t
        WHERE NOT EXISTS (
            SELECT 1 FROM dwh.DimTienda d WHERE d.tienda_id = t.tienda_id
        );

        /* Dimensión producto */
        INSERT INTO dwh.DimProducto (producto_id, nombre_producto, categoria, proveedor)
        SELECT p.producto_id, p.nombre_producto, c.nombre_categoria, pr.razon_social
        FROM oltp.Productos p
        LEFT JOIN oltp.Categorias c ON c.categoria_id = p.categoria_id
        LEFT JOIN oltp.Proveedores pr ON pr.proveedor_id = p.proveedor_id
        WHERE NOT EXISTS (
            SELECT 1 FROM dwh.DimProducto d WHERE d.producto_id = p.producto_id
        );

        /* Dimensión cliente */
        INSERT INTO dwh.DimCliente (cliente_id, nombres, apellidos, distrito)
        SELECT c.cliente_id, c.Nombres, c.Apellidos, c.Distrito
        FROM oltp.Clientes c
        WHERE NOT EXISTS (
            SELECT 1 FROM dwh.DimCliente d WHERE d.cliente_id = c.cliente_id
        );

        /* Dimensión fecha */
        SET DATEFIRST 1;
        INSERT INTO dwh.DimFecha
            (fecha_sk, fecha, anio, mes, nombre_mes, dia, dia_semana)
        SELECT
            CONVERT(INT, CONVERT(CHAR(8), CAST(v.fecha_venta AS DATE), 112)),
            CAST(v.fecha_venta AS DATE), YEAR(v.fecha_venta), MONTH(v.fecha_venta),
            DATENAME(MONTH, v.fecha_venta), DAY(v.fecha_venta), DATENAME(WEEKDAY, v.fecha_venta)
        FROM oltp.Ventas v
        WHERE v.fecha_venta IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM dwh.DimFecha d WHERE d.fecha = CAST(v.fecha_venta AS DATE)
          )
        GROUP BY CAST(v.fecha_venta AS DATE), YEAR(v.fecha_venta), MONTH(v.fecha_venta),
                 DATENAME(MONTH, v.fecha_venta), DAY(v.fecha_venta),
                 DATENAME(WEEKDAY, v.fecha_venta);

        /* Hechos */
        INSERT INTO dwh.FactVentas
            (detalle_id, venta_id, fecha_sk, tienda_sk, producto_sk,
             cliente_sk, cantidad, precio_unitario, importe)
        SELECT dv.detalle_id, v.venta_id, df.fecha_sk, dt.tienda_sk, dp.producto_sk,
               dc.cliente_sk, CAST(dv.Cantidad AS DECIMAL(18,4)),
               CAST(dv.precio_unitario AS DECIMAL(18,4)),
               CAST(dv.Cantidad * dv.precio_unitario AS DECIMAL(19,4))
        FROM oltp.DetalleVenta dv
        JOIN oltp.Ventas v ON v.venta_id = dv.venta_id
        JOIN dwh.DimFecha df ON df.fecha = CAST(v.fecha_venta AS DATE)
        JOIN dwh.DimTienda dt ON dt.tienda_id = v.tienda_id
        JOIN dwh.DimProducto dp ON dp.producto_id = dv.producto_id
        LEFT JOIN dwh.DimCliente dc ON dc.cliente_id = v.cliente_id
        WHERE NOT EXISTS (
            SELECT 1 FROM dwh.FactVentas f
            WHERE f.detalle_id = dv.detalle_id
        );

        SET @filas_despues = (SELECT COUNT_BIG(*) FROM dwh.FactVentas);

        COMMIT TRANSACTION;

        UPDATE dwh.LogCarga
        SET fecha_fin = SYSDATETIME(),
            estado = 'OK',
            mensaje = N'Carga finalizada correctamente.',
            filas_fact_insertadas = @filas_despues - @filas_antes
        WHERE log_id = @log_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        UPDATE dwh.LogCarga
        SET fecha_fin = SYSDATETIME(),
            estado = 'ERROR',
            mensaje = CONCAT(N'Error ', ERROR_NUMBER(), N': ', ERROR_MESSAGE())
        WHERE log_id = @log_id;

        THROW;
    END CATCH;
END;
GO

/* Ejecución normal:
EXEC dwh.usp_CargarDWH;

Prueba de error controlado:
EXEC dwh.usp_CargarDWH @forzar_error = 1;

Consultar log:
SELECT * FROM dwh.LogCarga ORDER BY log_id DESC;
*/
