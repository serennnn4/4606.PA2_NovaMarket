USE master;
GO
IF DB_ID('NovaMarket') IS NOT NULL
    DROP DATABASE NovaMarket;
GO
CREATE DATABASE NovaMarket;
GO
USE NovaMarket;
GO

CREATE TABLE Cliente (
    ClienteID  INT IDENTITY(1,1) PRIMARY KEY,
    Documento  VARCHAR(15)  NOT NULL UNIQUE,
    Nombre     VARCHAR(100) NOT NULL,
    Ciudad     VARCHAR(50)  NOT NULL,
    Activo     BIT          NOT NULL DEFAULT 1
);

CREATE TABLE Categoria (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre      VARCHAR(30) NOT NULL UNIQUE
        CHECK (Nombre IN ('Redes','Seguridad','Accesorios'))
);

CREATE TABLE Producto (
    ProductoID   INT IDENTITY(1,1) PRIMARY KEY,
    CategoriaID  INT NOT NULL FOREIGN KEY REFERENCES Categoria(CategoriaID),
    Nombre       VARCHAR(100) NOT NULL,
    PrecioLista  DECIMAL(10,2) NOT NULL CHECK (PrecioLista > 0),
    PrecioOferta DECIMAL(10,2) NULL,
    Stock        INT NOT NULL DEFAULT 0 CHECK (Stock >= 0),
    Activo       BIT NOT NULL DEFAULT 1
);

CREATE TABLE Pedido (
    PedidoID    INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID   INT NOT NULL FOREIGN KEY REFERENCES Cliente(ClienteID),
    FechaPedido DATE NOT NULL,
    Estado      VARCHAR(15) NOT NULL
        CHECK (Estado IN ('CONFIRMADO','PENDIENTE','ANULADO','BORRADOR')),
    Canal       VARCHAR(20) NOT NULL
);

CREATE TABLE DetallePedido (
    DetalleID      INT IDENTITY(1,1) PRIMARY KEY,
    PedidoID       INT NOT NULL FOREIGN KEY REFERENCES Pedido(PedidoID),
    ProductoID     INT NOT NULL FOREIGN KEY REFERENCES Producto(ProductoID),
    Cantidad       INT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(10,2) NOT NULL CHECK (PrecioUnitario >= 0)
);
GO

INSERT INTO Categoria (Nombre) VALUES ('Redes'),('Seguridad'),('Accesorios');
GO

INSERT INTO Cliente (Documento, Nombre, Ciudad, Activo) VALUES
('70000001','Ana Torres',      'Lima',     1),
('70000002','Bruno Salas',     'Arequipa', 1),
('70000003','Carla Mendoza',   'Trujillo', 1),
('70000004','Diego Ramírez',   'Lima',     1),
('70000005','Elena Paredes',   'Cusco',    1),
('70000006','Fernando Quispe', 'Lima',     1),
('70000007','Gabriela Rojas',  'Piura',    1),
('70000008','Hugo Castillo',   'Lima',     0),
('70000009','Irene Vásquez',   'Arequipa', 1),
('70000010','Jorge Huamán',    'Lima',     1),
('70000011','Karla Núñez',     'Trujillo', 1),
('70000012','Luis Farfán',     'Lima',     1),
('70000013','María Lozano',    'Cusco',    1),
('70000014','Nicolás Bravo',   'Piura',    1),
('70000015','Olga Chávez',     'Lima',     1);
GO

INSERT INTO Producto (CategoriaID, Nombre, PrecioLista, PrecioOferta, Stock, Activo) VALUES
(1,'Router AX3000',        350.00, NULL, 25, 1),
(1,'Switch 24 puertos',    780.00, NULL, 12, 1),
(1,'Access Point WiFi 6',  520.00, NULL, 18, 1),
(1,'Cable UTP Cat6 x305m', 430.00, NULL,  8, 1),
(2,'Firewall UTM',        1850.00, NULL, 10, 1),
(2,'Cámara IP 4MP',        320.00, NULL, 30, 1),
(2,'NVR 8 canales',        690.00, NULL, 15, 1),
(2,'Kit alarma 8 zonas',   450.00, NULL, 22, 1),
(3,'Mouse inalámbrico',     65.00, NULL, 50, 1),
(3,'Teclado mecánico',     189.00, NULL, 40, 1),
(3,'Hub USB-C 7 en 1',     120.00, NULL,  5, 1),
(3,'Mochila notebook',     149.00, NULL, 35, 1);
GO

INSERT INTO Pedido (ClienteID, FechaPedido, Estado, Canal) VALUES
(1,'2025-03-10','CONFIRMADO','WEB'),
(2,'2025-05-22','CONFIRMADO','TIENDA'),
(3,'2025-08-14','CONFIRMADO','WEB'),
(4,'2025-11-30','CONFIRMADO','TIENDA'),
(5,'2025-12-15','CONFIRMADO','WEB'),
(6,'2025-06-01','PENDIENTE','WEB'),
(7,'2025-07-07','ANULADO','TIENDA'),
(1,'2026-01-15','CONFIRMADO','WEB'),    
(2,'2026-02-10','CONFIRMADO','TIENDA'), 
(3,'2026-02-20','CONFIRMADO','WEB'),    
(4,'2026-03-05','CONFIRMADO','WEB'),    
(5,'2026-03-18','CONFIRMADO','TIENDA'), 
(6,'2026-04-01','CONFIRMADO','WEB'),    
(9,'2026-04-12','CONFIRMADO','WEB'),    
(10,'2026-05-02','CONFIRMADO','TIENDA'),
(11,'2026-05-20','CONFIRMADO','WEB'),
(12,'2026-06-08','CONFIRMADO','WEB'),
(13,'2026-06-25','CONFIRMADO','TIENDA'),
(14,'2026-07-11','CONFIRMADO','WEB'),
(15,'2026-07-29','CONFIRMADO','WEB'),
(1,'2026-08-05','PENDIENTE','WEB'),
(2,'2026-08-15','ANULADO','TIENDA'),
(3,'2026-09-01','PENDIENTE','WEB'),
(4,'2026-09-10','BORRADOR','WEB'),  
(5,'2026-09-20','BORRADOR','TIENDA'),
(6,'2026-10-01','CONFIRMADO','WEB'),
(7,'2026-10-05','CONFIRMADO','TIENDA'),
(9,'2026-10-15','CONFIRMADO','WEB'),
(10,'2026-10-20','CONFIRMADO','WEB'),
(11,'2026-11-01','PENDIENTE','TIENDA'),
(12,'2026-11-10','CONFIRMADO','WEB'),
(13,'2026-11-18','CONFIRMADO','TIENDA'),
(14,'2026-11-25','ANULADO','WEB'),
(15,'2026-12-01','CONFIRMADO','WEB'),
(1,'2026-12-10','CONFIRMADO','TIENDA'),
(2,'2026-12-15','CONFIRMADO','WEB'),
(3,'2026-12-20','BORRADOR','WEB'),
(4,'2026-12-22','BORRADOR','TIENDA'),
(5,'2026-12-23','BORRADOR','WEB'),
(6,'2026-12-24','BORRADOR','TIENDA');
GO

INSERT INTO DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario) VALUES
(1,1,3,350.00),(1,9,5,65.00),
(2,5,2,1850.00),(2,6,4,320.00),
(3,2,1,780.00),(3,10,3,189.00),
(4,3,2,520.00),(4,11,6,120.00),
(5,7,2,690.00),(5,12,4,149.00),
(6,1,1,350.00),(7,8,2,450.00),
(8,1,2,350.00),(8,3,1,520.00),
(9,2,1,780.00),(9,4,2,430.00),
(10,5,1,1850.00),(10,6,3,320.00),
(11,1,1,350.00),(11,5,1,1850.00),
(12,7,1,690.00),(12,8,2,450.00),
(13,2,2,780.00),(13,3,1,520.00),
(14,4,3,430.00),(14,6,2,320.00),
(15,9,10,65.00),(15,10,5,189.00),
(16,11,4,120.00),(16,12,3,149.00),
(17,1,2,350.00),(17,9,4,65.00),
(18,5,1,1850.00),(18,7,2,690.00),
(19,2,1,780.00),(19,6,3,320.00),
(20,3,2,520.00),(20,10,2,189.00),
(26,8,5,450.00),(26,12,2,149.00),
(27,1,1,350.00),(27,11,3,120.00),
(28,4,2,430.00),(28,9,6,65.00),
(29,5,1,1850.00),(29,10,2,189.00),
(30,2,1,780.00),(30,6,4,320.00),
(31,3,3,520.00),(31,12,2,149.00),
(32,7,1,690.00),(32,11,5,120.00),
(33,1,2,350.00),(33,8,2,450.00),
(34,4,1,430.00),(34,9,8,65.00),
(35,5,2,1850.00),(35,10,3,189.00),
(36,2,1,780.00),(36,6,2,320.00),
(25,1,1,350.00),(25,9,2,65.00),
(26,3,1,520.00),(26,10,1,189.00);
GO

SELECT 'Cliente' AS Tabla, COUNT(*) AS Filas FROM Cliente
UNION ALL SELECT 'Categoria', COUNT(*) FROM Categoria
UNION ALL SELECT 'Producto',  COUNT(*) FROM Producto
UNION ALL SELECT 'Pedido',    COUNT(*) FROM Pedido
UNION ALL SELECT 'Detalle',   COUNT(*) FROM DetallePedido;
GO

USE NovaMarket;
GO
SET NOCOUNT ON;

DECLARE @i INT = 1;
DECLARE @total INT = 220;       
DECLARE @cliente INT, @prod INT, @fecha DATE, @estado VARCHAR(15), @canal VARCHAR(20);
DECLARE @estados TABLE (id INT IDENTITY, valor VARCHAR(15));
INSERT INTO @estados (valor) VALUES ('CONFIRMADO'),('PENDIENTE'),('ANULADO'),('BORRADOR');

WHILE @i <= @total
BEGIN
    SET @cliente = 1 + ABS(CHECKSUM(NEWID())) % 15;
    SET @fecha   = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 730, '2025-01-01');
    SET @canal   = CASE ABS(CHECKSUM(NEWID())) % 2 WHEN 0 THEN 'WEB' ELSE 'TIENDA' END;
    SET @estado  = (SELECT valor FROM @estados
                    WHERE id = 1 + ABS(CHECKSUM(NEWID())) % 4);

    INSERT INTO Pedido (ClienteID, FechaPedido, Estado, Canal)
    VALUES (@cliente, @fecha, @estado, @canal);

    DECLARE @nuevoPedido INT = SCOPE_IDENTITY();

    IF @estado <> 'BORRADOR' OR ABS(CHECKSUM(NEWID())) % 2 = 0
    BEGIN
        DECLARE @k INT = 1, @lineas INT = 2;
        WHILE @k <= @lineas
        BEGIN
            SET @prod = 1 + ABS(CHECKSUM(NEWID())) % 12;
            INSERT INTO DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
            SELECT @nuevoPedido,
                   @prod,
                   1 + ABS(CHECKSUM(NEWID())) % 5,
                   pr.PrecioLista
            FROM   Producto pr WHERE pr.ProductoID = @prod;
            SET @k = @k + 1;
        END
    END
    SET @i = @i + 1;
END
GO

SELECT 'Pedido'  AS Tabla, COUNT(*) AS Total FROM Pedido
UNION ALL SELECT 'DetallePedido', COUNT(*) FROM DetallePedido;
GO

SELECT Estado, YEAR(FechaPedido) AS Anio, COUNT(*) AS Total
FROM   Pedido
GROUP BY Estado, YEAR(FechaPedido)
ORDER BY Anio, Estado;
GO


SELECT TOP 5 PedidoID, COUNT(*) AS Lineas
FROM DetallePedido GROUP BY PedidoID HAVING COUNT(*)>1 ORDER BY Lineas DESC;

SELECT ClienteID, Nombre FROM dbo.vw_ClientesSinCompra2026;

SELECT TOP 5 PedidoID, Estado, FechaPedido FROM Pedido
WHERE Estado IN ('PENDIENTE','ANULADO') ORDER BY PedidoID;

USE NovaMarket;
GO
SELECT  c.ClienteID,
        c.Nombre,
        ISNULL(x.TotalPedidos2026, 0)   AS TotalPedidos2026,
        ISNULL(x.MontoVendido2026, 0)   AS MontoVendido2026
FROM    Cliente c
OUTER APPLY (
    SELECT  COUNT(DISTINCT p.PedidoID) AS TotalPedidos2026,
            SUM(d.Cantidad * d.PrecioUnitario) AS MontoVendido2026
    FROM    Pedido p
    JOIN    DetallePedido d ON d.PedidoID = p.PedidoID
    WHERE   p.ClienteID   = c.ClienteID
      AND   p.Estado      = 'CONFIRMADO'
      AND   p.FechaPedido BETWEEN '2026-01-01' AND '2026-12-31'
) x
WHERE   c.Activo = 1
ORDER BY c.ClienteID;

USE NovaMarket;
GO

IF OBJECT_ID('tempdb..#ReporteBase') IS NOT NULL DROP TABLE #ReporteBase;

SELECT  c.ClienteID,
        c.Nombre,
        ISNULL(x.TotalPedidos2026, 0)   AS TotalPedidos2026,
        ISNULL(x.MontoVendido2026, 0)   AS MontoVendido2026
INTO    #ReporteBase
FROM    Cliente c
OUTER APPLY (
    SELECT  COUNT(DISTINCT p.PedidoID) AS TotalPedidos2026,
            SUM(d.Cantidad * d.PrecioUnitario) AS MontoVendido2026
    FROM    Pedido p
    JOIN    DetallePedido d ON d.PedidoID = p.PedidoID
    WHERE   p.ClienteID   = c.ClienteID
      AND   p.Estado      = 'CONFIRMADO'
      AND   p.FechaPedido BETWEEN '2026-01-01' AND '2026-12-31'
) x
WHERE   c.Activo = 1;

SELECT * FROM #ReporteBase ORDER BY ClienteID;
GO