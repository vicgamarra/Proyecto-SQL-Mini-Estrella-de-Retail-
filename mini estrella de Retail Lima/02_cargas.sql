/*
  Parte B - Cargas idempotentes INSERT...SELECT.
  IMPORTANTE: los nombres de columnas de OLTP se han supuesto a partir del enunciado.
  Si el resultado de 00_inspeccion_esquema.sql difiere, ajustar las columnas de origen.
*/
USE RetailLimaOLTP;
GO
SET NOCOUNT ON;
SET DATEFIRST 1;
GO

/* 1. DimTienda */
INSERT INTO dwh.DimTienda (tienda_id, nombre_tienda, distrito)
SELECT t.tienda_id, t.nombre_tienda, t.Distrito
FROM oltp.Tiendas AS t
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.DimTienda AS d WHERE d.tienda_id = t.tienda_id
);
GO

/* 2. DimProducto: nombre de categoría y razón social del proveedor */
INSERT INTO dwh.DimProducto (producto_id, nombre_producto, categoria, proveedor)
SELECT p.producto_id, p.nombre_producto, c.nombre_categoria, pr.razon_social
FROM oltp.Productos AS p
LEFT JOIN oltp.Categorias AS c ON c.categoria_id = p.categoria_id
LEFT JOIN oltp.Proveedores AS pr ON pr.proveedor_id = p.proveedor_id
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.DimProducto AS d WHERE d.producto_id = p.producto_id
);
GO

/* 3. DimCliente */
INSERT INTO dwh.DimCliente (cliente_id, nombres, apellidos, distrito)
SELECT c.cliente_id, c.Nombres, c.Apellidos, c.Distrito
FROM oltp.Clientes AS c
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.DimCliente AS d WHERE d.cliente_id = c.cliente_id
);
GO

/* 4. DimFecha: una fila por cada fecha distinta que tenga ventas.
   Se asume Ventas.FechaVenta. La clave es yyyymmdd. */
INSERT INTO dwh.DimFecha (fecha_sk, fecha, anio, mes, nombre_mes, dia, dia_semana)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), CAST(v.fecha_venta AS DATE), 112)),
    CAST(v.fecha_venta AS DATE),
    YEAR(v.fecha_venta),
    MONTH(v.fecha_venta),
    DATENAME(MONTH, v.fecha_venta),
    DAY(v.fecha_venta),
    DATENAME(WEEKDAY, v.fecha_venta)
FROM oltp.Ventas AS v
WHERE v.fecha_venta IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dwh.DimFecha AS d
      WHERE d.fecha = CAST(v.fecha_venta AS DATE)
  )
GROUP BY CAST(v.fecha_venta AS DATE), YEAR(v.fecha_venta),
         MONTH(v.fecha_venta), DATENAME(MONTH, v.fecha_venta),
         DAY(v.fecha_venta), DATENAME(WEEKDAY, v.fecha_venta);
GO

/* 5. FactVentas: grano = una línea de DetalleVenta.
   Se asume DetalleVenta(IdDetalleVenta, IdVenta, IdProducto, Cantidad, PrecioUnitario)
   y Ventas(IdVenta, FechaVenta, IdTienda, IdCliente). */

INSERT INTO dwh.FactVentas 
    (detalle_id,venta_id,fecha_sk,tienda_sk,
    producto_sk,cliente_sk,cantidad,precio_unitario,importe)
SELECT
    dv.detalle_id,
    v.venta_id,
    df.fecha_sk,
    dt.tienda_sk,
    dp.producto_sk,
    dc.cliente_sk,
    CAST(dv.cantidad AS DECIMAL(18,4)),
    CAST(dv.precio_unitario AS DECIMAL(18,4)),
    CAST(
        dv.cantidad * dv.precio_unitario
        AS DECIMAL(19,4)
    )
FROM oltp.DetalleVenta AS dv
INNER JOIN oltp.Ventas AS v
    ON v.venta_id = dv.venta_id
INNER JOIN dwh.DimFecha AS df
    ON df.fecha = CAST(v.fecha_venta AS DATE)
INNER JOIN dwh.DimTienda AS dt
    ON dt.tienda_id = v.tienda_id
INNER JOIN dwh.DimProducto AS dp
    ON dp.producto_id = dv.producto_id
LEFT JOIN dwh.DimCliente AS dc
    ON dc.cliente_id = v.cliente_id
WHERE NOT EXISTS (
    SELECT 1
    FROM dwh.FactVentas AS f
    WHERE f.detalle_id = dv.detalle_id
);
GO


/*
  6. La carga incremental se demuestra en 06_pruebas.sql:
  insertar una venta y dos líneas en OLTP, y volver a ejecutar esta carga.
  Esta carga no genera duplicados porque controla detalle_venta_id.
*/
