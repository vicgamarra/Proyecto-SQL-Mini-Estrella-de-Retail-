# 🚀 Retail Lima | Data Warehouse & ETL con SQL Server

## 📊 Descripción del proyecto

Proyecto desarrollado como parte del **Diploma Data Engineer – Edición 18**, enfocado en la construcción de un Data Warehouse dimensional a partir de una base de datos transaccional de ventas.

El objetivo principal fue transformar los datos operacionales de Retail Lima en una estructura analítica optimizada, aplicando buenas prácticas de modelado, integración, procesamiento y validación de datos.

## 🛠️ Tecnologías utilizadas

- **SQL Server** – Gestión y procesamiento de datos.
- **T-SQL** – Desarrollo de consultas, transformaciones y procedimientos almacenados.
- **Data Warehouse** – Diseño de modelo dimensional tipo estrella.
- **ETL** – Extracción, transformación y carga incremental de datos.

## 🏗️ Arquitectura del proyecto

Se implementó un modelo dimensional tipo estrella compuesto por:

- **DimFecha** 📅
- **DimTienda** 🏪
- **DimProducto** 📦
- **DimCliente** 👥
- **FactVentas** 💰

## ⚙️ Principales funcionalidades

- Diseño e implementación de un modelo dimensional para análisis de ventas.
- Desarrollo de procesos de carga de dimensiones y tabla de hechos.
- Implementación de cargas incrementales evitando registros duplicados.
- Validación de integridad y consistencia entre el origen y el Data Warehouse.
- Desarrollo de consultas analíticas utilizando `DENSE_RANK`, `SUM() OVER`, `LAG` y otras funciones SQL.
- Implementación de procedimientos almacenados con manejo de errores mediante `TRY/CATCH`, `ROLLBACK` y `THROW`.
- Registro y seguimiento de ejecuciones mediante una tabla de log de carga.

## 📈 Análisis desarrollados

- Top 3 productos por categoría.
- Ventas acumuladas.
- Variación mensual de ventas.
- Ticket promedio.
- Validación de cantidades e importes entre origen y destino.

## 🎯 Conocimientos demostrados

Este proyecto evidencia conocimientos prácticos en:

`SQL Server` · `T-SQL` · `Data Warehousing` · `Modelado Dimensional` · `ETL` · `Carga Incremental` · `Data Quality` · `Stored Procedures` · `Window Functions` · `Control de Errores`

## 👨‍💻 Autor

**Victor Gamarra**

Diploma Data Engineer – Edición 18

Proyecto académico orientado al desarrollo de competencias prácticas en ingeniería de datos.
