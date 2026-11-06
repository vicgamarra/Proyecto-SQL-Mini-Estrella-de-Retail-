/*
  Parte A - Modelo dimensional en estrella.
  Suposición de nombres de origen: oltp.Tienda, Producto, Categoria,
  Proveedor, Cliente, Ventas y DetalleVenta. Revisar 00_inspeccion_esquema.sql.
*/
USE RetailLimaOLTP;
GO

IF SCHEMA_ID('dwh') IS NULL
    EXEC('CREATE SCHEMA dwh');
GO

IF OBJECT_ID('dwh.FactVentas', 'U') IS NULL
BEGIN
    CREATE TABLE dwh.FactVentas (
        venta_detalle_sk BIGINT IDENTITY(1,1) PRIMARY KEY,
        detalle_id INT NOT NULL UNIQUE,
        venta_id INT NOT NULL,
        fecha_sk INT NOT NULL,
        tienda_sk INT NOT NULL,
        producto_sk INT NOT NULL,
        cliente_sk INT NULL,
        cantidad INT NOT NULL,
        precio_unitario DECIMAL(10,2) NOT NULL,
        importe DECIMAL(19,4) NOT NULL,
        fecha_carga DATETIME2(0) DEFAULT SYSDATETIME()
    );
END;
GO

IF OBJECT_ID('dwh.DimFecha', 'U') IS NULL
BEGIN
    CREATE TABLE dwh.DimFecha (
        fecha_sk INT NOT NULL CONSTRAINT PK_DimFecha PRIMARY KEY,
        fecha DATE NOT NULL CONSTRAINT UQ_DimFecha_fecha UNIQUE,
        anio SMALLINT NOT NULL,
        mes TINYINT NOT NULL,
        nombre_mes NVARCHAR(20) NOT NULL,
        dia TINYINT NOT NULL,
        dia_semana NVARCHAR(20) NOT NULL
    );
END;
GO

IF OBJECT_ID('dwh.DimTienda', 'U') IS NULL
BEGIN
    CREATE TABLE dwh.DimTienda (
        tienda_sk INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_DimTienda PRIMARY KEY,
        tienda_id INT NOT NULL,
        nombre_tienda NVARCHAR(200) NOT NULL,
        distrito NVARCHAR(100) NULL,
        CONSTRAINT UQ_DimTienda_tienda_id UNIQUE (tienda_id)
    );
END;
GO

IF OBJECT_ID('dwh.DimProducto', 'U') IS NULL
BEGIN
    CREATE TABLE dwh.DimProducto (
        producto_sk INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_DimProducto PRIMARY KEY,
        producto_id INT NOT NULL,
        nombre_producto NVARCHAR(200) NOT NULL,
        categoria NVARCHAR(150) NULL,
        proveedor NVARCHAR(200) NULL,
        CONSTRAINT UQ_DimProducto_producto_id UNIQUE (producto_id)
    );
END;
GO

IF OBJECT_ID('dwh.DimCliente', 'U') IS NULL
BEGIN
    CREATE TABLE dwh.DimCliente (
        cliente_sk INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_DimCliente PRIMARY KEY,
        cliente_id INT NOT NULL,
        nombres NVARCHAR(150) NULL,
        apellidos NVARCHAR(150) NULL,
        distrito NVARCHAR(100) NULL,
        CONSTRAINT UQ_DimCliente_cliente_id UNIQUE (cliente_id)
    );
END;
GO

/* Las FK se crean después de las tablas. */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentas_DimFecha')
    ALTER TABLE dwh.FactVentas ADD CONSTRAINT FK_FactVentas_DimFecha
    FOREIGN KEY (fecha_sk) REFERENCES dwh.DimFecha(fecha_sk);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentas_DimTienda')
    ALTER TABLE dwh.FactVentas ADD CONSTRAINT FK_FactVentas_DimTienda
    FOREIGN KEY (tienda_sk) REFERENCES dwh.DimTienda(tienda_sk);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentas_DimProducto')
    ALTER TABLE dwh.FactVentas ADD CONSTRAINT FK_FactVentas_DimProducto
    FOREIGN KEY (producto_sk) REFERENCES dwh.DimProducto(producto_sk);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FactVentas_DimCliente')
    ALTER TABLE dwh.FactVentas ADD CONSTRAINT FK_FactVentas_DimCliente
    FOREIGN KEY (cliente_sk) REFERENCES dwh.DimCliente(cliente_sk);
GO
