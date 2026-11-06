/* Parte D - Consultas analíticas sobre el modelo estrella */
USE RetailLimaOLTP;
GO

/* 1. Top 3 productos por categoría según importe vendido.
   DENSE_RANK conserva empates en el puesto. */
WITH VentasProducto AS (
    SELECT
        p.categoria,
        p.nombre_producto,
        SUM(f.importe) AS importe_vendido
    FROM dwh.FactVentas AS f
    JOIN dwh.DimProducto AS p ON p.producto_sk = f.producto_sk
    GROUP BY p.categoria, p.nombre_producto
),
Ranking AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY categoria
            ORDER BY importe_vendido DESC
        ) AS ranking
    FROM VentasProducto
)
SELECT categoria, nombre_producto, importe_vendido, ranking
FROM Ranking
WHERE ranking <= 3
ORDER BY categoria, ranking, nombre_producto;
GO

/* 2. Ventas acumuladas por tienda a través del tiempo */
WITH VentasDia AS (
    SELECT
        t.tienda_sk,
        t.nombre_tienda,
        df.fecha,
        SUM(f.importe) AS venta_dia
    FROM dwh.FactVentas AS f
    JOIN dwh.DimTienda AS t ON t.tienda_sk = f.tienda_sk
    JOIN dwh.DimFecha AS df ON df.fecha_sk = f.fecha_sk
    GROUP BY t.tienda_sk, t.nombre_tienda, df.fecha
)
SELECT *,
    SUM(venta_dia) OVER (
        PARTITION BY tienda_sk
        ORDER BY fecha
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS venta_acumulada
FROM VentasDia
ORDER BY nombre_tienda, fecha;
GO

/* 3. Variación mensual de ventas: diferencia y porcentaje frente al mes anterior */
WITH VentasMes AS (
    SELECT
        t.tienda_sk,
        t.nombre_tienda,
        df.anio,
        df.mes,
        SUM(f.importe) AS importe_mes
    FROM dwh.FactVentas AS f
    JOIN dwh.DimTienda AS t ON t.tienda_sk = f.tienda_sk
    JOIN dwh.DimFecha AS df ON df.fecha_sk = f.fecha_sk
    GROUP BY t.tienda_sk, t.nombre_tienda, df.anio, df.mes
),
ConAnterior AS (
    SELECT *,
        LAG(importe_mes) OVER (
            PARTITION BY tienda_sk ORDER BY anio, mes
        ) AS importe_mes_anterior
    FROM VentasMes
)
SELECT *,
    importe_mes - importe_mes_anterior AS variacion_importe,
    100.0 * (importe_mes - importe_mes_anterior)
        / NULLIF(importe_mes_anterior, 0) AS variacion_porcentual
FROM ConAnterior
ORDER BY nombre_tienda, anio, mes;
GO

/* 4. Ticket promedio por tienda.
   Primero se calcula el total de cada venta, luego se promedia el ticket. */
WITH Tickets AS (
    SELECT
        t.tienda_sk,
        t.nombre_tienda,
        f.venta_id,
        SUM(f.importe) AS total_venta
    FROM dwh.FactVentas AS f
    JOIN dwh.DimTienda AS t ON t.tienda_sk = f.tienda_sk
    GROUP BY t.tienda_sk, t.nombre_tienda, f.venta_id
)
SELECT
    tienda_sk,
    nombre_tienda,
    COUNT(*) AS cantidad_tickets,
    SUM(total_venta) AS ventas_totales,
    SUM(total_venta) / NULLIF(COUNT(*), 0) AS ticket_promedio
FROM Tickets
GROUP BY tienda_sk, nombre_tienda
ORDER BY ticket_promedio DESC;
GO
