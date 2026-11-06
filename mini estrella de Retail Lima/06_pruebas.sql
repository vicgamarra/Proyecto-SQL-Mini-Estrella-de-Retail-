/*
  Parte F - Pruebas exigidas.
  Ejecutar en una copia de trabajo de la base restaurada.
  La prueba incremental requiere adaptar las columnas obligatorias de Ventas
  y DetalleVenta a la estructura real de la base.
*/
USE RetailLimaOLTP;
GO

/* PRUEBA 1: primera carga y comparación de conteos/importes */
SELECT
    (SELECT COUNT_BIG(*) FROM oltp.DetalleVenta) AS origen_detalles,
    (SELECT COUNT_BIG(*) FROM dwh.FactVentas) AS dwh_hechos,
    (SELECT SUM(CAST(Cantidad * precio_unitario AS DECIMAL(19,4)))
     FROM oltp.DetalleVenta) AS importe_origen,
    (SELECT SUM(importe) FROM dwh.FactVentas) AS importe_dwh;
GO

/* PRUEBA 2: re-ejecución.
   Ejecutar dos veces; la segunda debe insertar 0 hechos nuevos. */
EXEC dwh.usp_CargarDWH;
EXEC dwh.usp_CargarDWH;
SELECT TOP (10) * FROM dwh.LogCarga ORDER BY log_id DESC;
GO

/* PRUEBA 3: carga incremental.
   Antes de ejecutar, completar las columnas obligatorias de origen según el esquema.
   Ejemplo ilustrativo; NO ejecutar sin verificar columnas y valores requeridos.

   BEGIN TRANSACTION;
   DECLARE @nuevoIdVenta INT, @nuevoIdDetalle1 INT, @nuevoIdDetalle2 INT;

   INSERT INTO oltp.Ventas (FechaVenta, IdTienda, IdCliente)
   VALUES (GETDATE(), <IdTiendaExistente>, NULL);
   SET @nuevoIdVenta = SCOPE_IDENTITY();

   INSERT INTO oltp.DetalleVenta (IdVenta, IdProducto, Cantidad, PrecioUnitario)
   VALUES (@nuevoIdVenta, <IdProducto1>, 1, 10.00),
          (@nuevoIdVenta, <IdProducto2>, 2, 15.00);

   COMMIT TRANSACTION;

   DECLARE @antes BIGINT = (SELECT COUNT_BIG(*) FROM dwh.FactVentas);
   EXEC dwh.usp_CargarDWH;
   DECLARE @despues BIGINT = (SELECT COUNT_BIG(*) FROM dwh.FactVentas);
   SELECT @despues - @antes AS filas_nuevas_esperadas_2;
*/

/* PRUEBA 4: discrepancia.
   Borrar temporalmente un hecho, ejecutar validaciones y comprobar que se detecta.
   Registrar el ID para restaurarlo desde OLTP y luego recargarlo. */
DECLARE @detalle_faltante INT;

SELECT TOP (1) @detalle_faltante = detalle_id
FROM dwh.FactVentas
ORDER BY venta_detalle_sk;

IF @detalle_faltante IS NOT NULL
BEGIN
    DELETE FROM dwh.FactVentas
    WHERE detalle_id = @detalle_faltante;

    SELECT @detalle_faltante AS detalle_borrado_para_prueba;

    SELECT dv.*
    FROM oltp.DetalleVenta dv
    LEFT JOIN dwh.FactVentas f ON f.detalle_id = dv.detalle_id
    WHERE f.detalle_id IS NULL;

    /* Restaurar el hecho faltante con la carga incremental */
    EXEC dwh.usp_CargarDWH;
END;
GO

/* PRUEBA 5: fallo controlado.
   El error debe regresar al llamador y quedar registrado en LogCarga.
   Ejecutar en una ventana aparte si se desea ver claramente el error. */
BEGIN TRY
    EXEC dwh.usp_CargarDWH @forzar_error = 1;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_error,
           ERROR_MESSAGE() AS mensaje_error_capturado;
END CATCH;

SELECT TOP (10) *
FROM dwh.LogCarga
ORDER BY log_id DESC;
GO
