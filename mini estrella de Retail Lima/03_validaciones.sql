/* Parte C - Validaciones entre OLTP y DWH */
USE RetailLimaOLTP;
GO

/* ---------- 1. Resumen de conteos y sumas ---------- */
/* Comparación de conteos */
SELECT
    (SELECT COUNT_BIG(*) FROM oltp.DetalleVenta) AS filas_origen,
    (SELECT COUNT_BIG(*) FROM dwh.FactVentas) AS filas_dwh,
    (SELECT COUNT_BIG(*) FROM oltp.DetalleVenta)
      - (SELECT COUNT_BIG(*) FROM dwh.FactVentas) AS diferencia_filas;
GO

/* Comparación de importes */
SELECT
    (SELECT SUM(CAST(dv.Cantidad * dv.precio_unitario AS DECIMAL(19,4)))
     FROM oltp.DetalleVenta AS dv) AS importe_origen,
    (SELECT SUM(importe) FROM dwh.FactVentas) AS importe_dwh,
    (SELECT SUM(CAST(dv.Cantidad * dv.precio_unitario AS DECIMAL(19,4)))
     FROM oltp.DetalleVenta AS dv)
      - (SELECT SUM(importe) FROM dwh.FactVentas) AS diferencia_importe;
GO

/* ---------- 2. Filas que no llegaron (LEFT JOIN) ---------- */
SELECT 'NO LLEGÓ AL DWH (LEFT JOIN)' AS hallazgo,
        dv.detalle_id, dv.venta_id, CAST(v.fecha_venta AS DATE) AS fecha,
        v.tienda_id, dv.producto_id, v.cliente_id,
        dv.cantidad, dv.precio_unitario,
        dv.cantidad * dv.precio_unitario AS importe
FROM oltp.DetalleVenta AS dv
JOIN oltp.Ventas       AS v ON v.venta_id = dv.venta_id
LEFT JOIN dwh.FactVentas AS f ON f.detalle_id = dv.detalle_id
WHERE f.detalle_id IS NULL
ORDER BY dv.detalle_id;

/* ---------- 3. Faltantes o con valores distintos (EXCEPT) ---------- */
SELECT 'EN OLTP Y NO IGUAL EN DWH (EXCEPT)' AS hallazgo, x.*
FROM (
    SELECT detalle_id, venta_id, cantidad,
            CAST(cantidad * precio_unitario AS DECIMAL(19,4)) AS importe
    FROM oltp.DetalleVenta
    EXCEPT
    SELECT detalle_id, venta_id, cantidad, importe
    FROM dwh.FactVentas
) AS x
ORDER BY x.detalle_id;

/* ---------- 4. Sobrantes en el DWH (EXCEPT inverso) ---------- */
SELECT 'EN DWH Y NO EN OLTP (EXCEPT)' AS hallazgo, x.*
FROM (
    SELECT detalle_id FROM dwh.FactVentas
    EXCEPT
    SELECT detalle_id FROM oltp.DetalleVenta
) AS x
ORDER BY x.detalle_id;