/* ============================================================
   PA2 - Esquema base: NovaMarket
   Curso: Programación Avanzada de Base de Datos (30627)
   Motor: SQL Server | Autenticación de Windows | instancia local


   ============================================================ */

-- 1. Creación base de datos.
CREATE DATABASE PA2_NovaMarket;
GO

USE PA2_NovaMarket;
GO

-- 2. Limpieza de tablas.
IF OBJECT_ID('dbo.DetallePedido', 'U') IS NOT NULL DROP TABLE dbo.DetallePedido;
IF OBJECT_ID('dbo.Pedido', 'U')        IS NOT NULL DROP TABLE dbo.Pedido;
IF OBJECT_ID('dbo.Producto', 'U')      IS NOT NULL DROP TABLE dbo.Producto;
IF OBJECT_ID('dbo.Categoria', 'U')     IS NOT NULL DROP TABLE dbo.Categoria;
IF OBJECT_ID('dbo.Cliente', 'U')       IS NOT NULL DROP TABLE dbo.Cliente;
GO

-- 3. Tabla Cliente
CREATE TABLE dbo.Cliente (
    ClienteID  INT IDENTITY(1,1) NOT NULL,
    Documento  VARCHAR(15)  NOT NULL,
    Nombre     VARCHAR(100) NOT NULL,
    Ciudad     VARCHAR(50)  NOT NULL,
    Activo     BIT          NOT NULL CONSTRAINT DF_Cliente_Activo DEFAULT 1,
    CONSTRAINT PK_Cliente PRIMARY KEY (ClienteID),
    CONSTRAINT UQ_Cliente_Documento UNIQUE (Documento)
);
GO

-- 4. Tabla Categoria
CREATE TABLE dbo.Categoria (
    CategoriaID  INT IDENTITY(1,1) NOT NULL,
    Nombre       VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Categoria PRIMARY KEY (CategoriaID),
    CONSTRAINT UQ_Categoria_Nombre UNIQUE (Nombre)
);
GO

-- 5. Tabla Producto
--    PrecioOferta admite NULL (producto sin oferta). Si tiene valor, debe ser
--    positivo y no mayor al PrecioLista.
CREATE TABLE dbo.Producto (
    ProductoID    INT IDENTITY(1,1) NOT NULL,
    CategoriaID   INT            NOT NULL,
    Nombre        VARCHAR(100)   NOT NULL,
    PrecioLista   DECIMAL(10,2)  NOT NULL,
    PrecioOferta  DECIMAL(10,2)  NULL,
    Stock         INT            NOT NULL CONSTRAINT DF_Producto_Stock DEFAULT 0,
    Activo        BIT            NOT NULL CONSTRAINT DF_Producto_Activo DEFAULT 1,
    CONSTRAINT PK_Producto PRIMARY KEY (ProductoID),
    CONSTRAINT FK_Producto_Categoria FOREIGN KEY (CategoriaID)
        REFERENCES dbo.Categoria(CategoriaID),
    CONSTRAINT CK_Producto_PrecioLista CHECK (PrecioLista > 0),
    CONSTRAINT CK_Producto_PrecioOferta CHECK (PrecioOferta IS NULL
        OR (PrecioOferta > 0 AND PrecioOferta <= PrecioLista)),
    CONSTRAINT CK_Producto_Stock CHECK (Stock >= 0)
);
GO

-- 6. Tabla Pedido (cabecera)
--    Estados permitidos: CONFIRMADO, PENDIENTE, ANULADO y BORRADOR.
CREATE TABLE dbo.Pedido (
    PedidoID     INT IDENTITY(1,1) NOT NULL,
    ClienteID    INT         NOT NULL,
    FechaPedido  DATE        NOT NULL CONSTRAINT DF_Pedido_Fecha DEFAULT (CAST(GETDATE() AS DATE)),
    Estado       VARCHAR(15) NOT NULL CONSTRAINT DF_Pedido_Estado DEFAULT 'BORRADOR',
    Canal        VARCHAR(30) NOT NULL,
    CONSTRAINT PK_Pedido PRIMARY KEY (PedidoID),
    CONSTRAINT FK_Pedido_Cliente FOREIGN KEY (ClienteID)
        REFERENCES dbo.Cliente(ClienteID),
    CONSTRAINT CK_Pedido_Estado CHECK (Estado IN ('CONFIRMADO','PENDIENTE','ANULADO','BORRADOR'))
);
GO

-- 7. Tabla DetallePedido
--    El importe de cada línea es Cantidad * PrecioUnitario. PrecioUnitario guarda
--    el precio histórico de la venta, no el precio actual de Producto.
CREATE TABLE dbo.DetallePedido (
    DetalleID       INT IDENTITY(1,1) NOT NULL,
    PedidoID        INT           NOT NULL,
    ProductoID      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    PrecioUnitario  DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_DetallePedido PRIMARY KEY (DetalleID),
    CONSTRAINT FK_Detalle_Pedido FOREIGN KEY (PedidoID)
        REFERENCES dbo.Pedido(PedidoID),
    CONSTRAINT FK_Detalle_Producto FOREIGN KEY (ProductoID)
        REFERENCES dbo.Producto(ProductoID),
    CONSTRAINT CK_Detalle_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_Detalle_PrecioUnitario CHECK (PrecioUnitario > 0)
);
GO

-- 8. Categorías fijas del caso (forman parte del esquema)
INSERT INTO dbo.Categoria (Nombre) VALUES
('Redes'),
('Seguridad'),
('Accesorios');
GO

-- 9. Clientes (16: 14 activos y 2 inactivos)
--    Los ClienteID salen en orden: 1 = Ana ... 16 = Pablo.
INSERT INTO dbo.Cliente (Documento, Nombre, Ciudad, Activo) VALUES
('70100001', 'Ana Ramírez Torres', 'Lima', 1),
('70100002', 'Carlos Flores Medina', 'Arequipa', 1),
('70100003', 'Bertha Quispe Huamán', 'Cusco', 1),
('70100004', 'Diego Salazar Vega', 'Lima', 1),
('70100005', 'Elena Torres Paredes', 'Trujillo', 1),
('70100006', 'Fabricio Mendoza Rojas', 'Piura', 1),
('70100007', 'Gabriela Ríos Campos', 'Lima', 1),
('70100008', 'Hugo Castillo Salas', 'Arequipa', 1),
('70100009', 'Isabel Vargas León', 'Chiclayo', 1),
('70100010', 'Jorge Palomino Cruz', 'Lima', 1),
('70100011', 'Karla Núñez Delgado', 'Cusco', 1),
('70100012', 'Luis Herrera Ponce', 'Trujillo', 1),
('70100013', 'Marta Chávez Ibáñez', 'Lima', 1),
('70100014', 'Néstor Aguilar Bravo', 'Piura', 1),
('70100015', 'Olga Paredes Rivas', 'Arequipa', 0),
('70100016', 'Pablo Ruiz Zevallos', 'Lima', 0);
GO

-- 10. Productos (12). Los ProductoID salen en orden de la lista.
--     1 Router, 2 Switch, 3 Access Point, 4 Cable UTP, 5 Repetidor (inactivo),
--     6 Cámara IP, 7 Firewall, 8 Kit CCTV (ya trae oferta), 9 Cerradura,
--     10 Patch cord, 11 Organizador, 12 Tester.
--     Todos los PrecioOferta quedan en NULL salvo el Kit CCTV. 

INSERT INTO dbo.Producto (CategoriaID, Nombre, PrecioLista, PrecioOferta, Stock, Activo) VALUES
(1, 'Router WiFi 6 AX1800', 289.90, NULL, 40, 1),
(1, 'Switch Gigabit 8 puertos', 119.90, NULL, 10, 1),
(1, 'Access Point empresarial', 459.00, NULL, 15, 1),
(1, 'Cable UTP Cat6 caja 305 m', 389.00, NULL, 9, 1),
(1, 'Repetidor WiFi doble banda', 99.90, NULL, 30, 0),
(2, 'Cámara IP 2MP', 189.00, NULL, 35, 1),
(2, 'Firewall UTM', 1890.00, NULL, 6, 1),
(2, 'Kit 4 cámaras CCTV', 899.00, 849.00, 12, 1),
(2, 'Cerradura biométrica', 349.00, NULL, 20, 1),
(3, 'Patch cord Cat6 2 m', 12.90, NULL, 300, 1),
(3, 'Organizador de cables', 24.90, NULL, 150, 1),
(3, 'Tester de red RJ45', 79.90, NULL, 10, 1);
GO

-- 11. Pedidos (40). Los PedidoID salen en orden: 1 a 40.
--     1-7   CONFIRMADO 2025 (el 7 es del 31/12/2025, límite del corte histórico)
--     8-25  CONFIRMADO 2026 (el 8 es del 01/01/2026, límite del otro lado)
--     26-30 PENDIENTE | 31-33 ANULADO
--     34-38 BORRADOR sin detalle | 39-40 BORRADOR con detalle
INSERT INTO dbo.Pedido (ClienteID, FechaPedido, Estado, Canal) VALUES
(11, '2025-03-14', 'CONFIRMADO', 'Web'),
(4, '2025-05-20', 'CONFIRMADO', 'Tienda'),
(1, '2025-07-02', 'CONFIRMADO', 'Web'),
(15, '2025-08-18', 'CONFIRMADO', 'WhatsApp'),
(8, '2025-09-09', 'CONFIRMADO', 'Tienda'),
(2, '2025-11-25', 'CONFIRMADO', 'Web'),
(7, '2025-12-31', 'CONFIRMADO', 'Teléfono'),
(1, '2026-01-01', 'CONFIRMADO', 'Web'),
(1, '2026-03-12', 'CONFIRMADO', 'Tienda'),
(2, '2026-02-05', 'CONFIRMADO', 'WhatsApp'),
(3, '2026-02-18', 'CONFIRMADO', 'Web'),
(3, '2026-04-22', 'CONFIRMADO', 'Web'),
(4, '2026-03-03', 'CONFIRMADO', 'Tienda'),
(5, '2026-01-20', 'CONFIRMADO', 'Web'),
(5, '2026-05-14', 'CONFIRMADO', 'Web'),
(6, '2026-02-27', 'CONFIRMADO', 'Teléfono'),
(6, '2026-06-08', 'CONFIRMADO', 'Tienda'),
(7, '2026-04-04', 'CONFIRMADO', 'Web'),
(7, '2026-07-19', 'CONFIRMADO', 'WhatsApp'),
(8, '2026-03-30', 'CONFIRMADO', 'Tienda'),
(9, '2026-05-25', 'CONFIRMADO', 'Web'),
(12, '2026-06-17', 'CONFIRMADO', 'Web'),
(10, '2026-08-02', 'CONFIRMADO', 'Web'),
(2, '2026-09-15', 'CONFIRMADO', 'Web'),
(1, '2026-10-10', 'CONFIRMADO', 'Web'),
(10, '2026-07-07', 'PENDIENTE', 'Web'),
(5, '2026-09-01', 'PENDIENTE', 'WhatsApp'),
(3, '2026-10-05', 'PENDIENTE', 'Tienda'),
(13, '2026-08-20', 'PENDIENTE', 'Teléfono'),
(11, '2026-10-01', 'PENDIENTE', 'Web'),
(12, '2026-07-30', 'ANULADO', 'Web'),
(6, '2026-04-15', 'ANULADO', 'Tienda'),
(9, '2026-02-11', 'ANULADO', 'WhatsApp'),
(13, '2026-05-02', 'BORRADOR', 'Web'),
(13, '2026-08-10', 'BORRADOR', 'Tienda'),
(1, '2026-09-28', 'BORRADOR', 'Web'),
(8, '2025-10-12', 'BORRADOR', 'WhatsApp'),
(4, '2026-06-30', 'BORRADOR', 'Teléfono'),
(2, '2026-10-08', 'BORRADOR', 'Web'),
(7, '2026-09-30', 'BORRADOR', 'Tienda');
GO

-- 12. DetallePedido. PrecioUnitario es el precio histórico de la venta:
--     en 2025 se vendió 5 % más barato que el PrecioLista actual.
--     Los borradores 34 a 38 no tienen ninguna línea a propósito.
INSERT INTO dbo.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario) VALUES
(1, 1, 1, 275.40),
(1, 4, 2, 369.55),
(1, 10, 4, 12.25),
(2, 6, 2, 179.55),
(2, 10, 5, 12.25),
(2, 11, 2, 23.65),
(3, 2, 2, 113.91),
(3, 10, 4, 12.25),
(3, 12, 1, 75.91),
(4, 12, 1, 75.91),
(4, 11, 3, 23.65),
(5, 9, 1, 331.55),
(5, 10, 2, 12.25),
(6, 3, 1, 436.05),
(6, 1, 1, 275.40),
(6, 10, 2, 12.25),
(7, 8, 1, 854.05),
(7, 6, 1, 179.55),
(7, 11, 2, 23.65),
(8, 1, 1, 289.90),
(8, 2, 1, 119.90),
(8, 10, 4, 12.90),
(9, 4, 1, 389.00),
(9, 11, 2, 24.90),
(9, 10, 2, 12.90),
(10, 3, 1, 459.00),
(10, 10, 3, 12.90),
(11, 1, 2, 289.90),
(11, 11, 1, 24.90),
(12, 2, 3, 119.90),
(12, 12, 1, 79.90),
(12, 10, 5, 12.90),
(13, 2, 1, 119.90),
(13, 4, 1, 389.00),
(13, 10, 6, 12.90),
(14, 1, 1, 289.90),
(14, 10, 2, 12.90),
(15, 6, 2, 189.00),
(15, 10, 2, 12.90),
(15, 11, 1, 24.90),
(16, 3, 1, 459.00),
(16, 2, 2, 119.90),
(16, 10, 3, 12.90),
(17, 7, 1, 1890.00),
(17, 9, 1, 349.00),
(18, 5, 2, 99.90),
(18, 10, 3, 12.90),
(19, 8, 1, 899.00),
(19, 11, 2, 24.90),
(20, 9, 2, 349.00),
(20, 6, 1, 189.00),
(20, 10, 2, 12.90),
(21, 8, 1, 899.00),
(21, 11, 4, 24.90),
(22, 1, 1, 289.90),
(22, 2, 1, 119.90),
(22, 10, 2, 12.90),
(23, 12, 1, 79.90),
(23, 10, 8, 12.90),
(24, 1, 1, 289.90),
(24, 4, 2, 389.00),
(24, 10, 4, 12.90),
(25, 2, 2, 119.90),
(25, 1, 1, 289.90),
(25, 11, 3, 24.90),
(26, 3, 1, 459.00),
(26, 2, 1, 119.90),
(27, 6, 1, 189.00),
(27, 10, 2, 12.90),
(28, 8, 1, 899.00),
(28, 10, 2, 12.90),
(29, 1, 1, 289.90),
(29, 11, 1, 24.90),
(30, 4, 1, 389.00),
(30, 11, 2, 24.90),
(31, 7, 1, 1890.00),
(31, 6, 2, 189.00),
(31, 10, 1, 12.90),
(32, 2, 1, 119.90),
(32, 10, 2, 12.90),
(33, 1, 1, 289.90),
(33, 10, 2, 12.90),
(39, 2, 1, 119.90),
(39, 10, 2, 12.90),
(40, 12, 2, 79.90),
(40, 11, 1, 24.90);
GO

-- 13. Verificación de la carga
SELECT 'Cliente' AS Tabla, COUNT(*) AS Filas FROM dbo.Cliente
UNION ALL SELECT 'Categoria',     COUNT(*) FROM dbo.Categoria
UNION ALL SELECT 'Producto',      COUNT(*) FROM dbo.Producto
UNION ALL SELECT 'Pedido',        COUNT(*) FROM dbo.Pedido
UNION ALL SELECT 'DetallePedido', COUNT(*) FROM dbo.DetallePedido;

SELECT YEAR(FechaPedido) AS Anio, Estado, COUNT(*) AS Pedidos
FROM dbo.Pedido
GROUP BY YEAR(FechaPedido), Estado
ORDER BY Anio, Estado;

-- Debe devolver 0 filas (detalles o pedidos huérfanos)
SELECT d.DetalleID FROM dbo.DetallePedido d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pedido p WHERE p.PedidoID = d.PedidoID)
   OR NOT EXISTS (SELECT 1 FROM dbo.Producto pr WHERE pr.ProductoID = d.ProductoID);
GO



/* ===================================================================
   ACTIVIDAD 01 | SESIÓN 04 
   ================================================================= */

 ---- A. Segmentación con EXISTS y NOT EXISTS -----
/***    Para listar los clientes que tengan al menos un pedido CONFIRMADO de productos de Redes 
        durante 2026 y que NO tengan pedidos CONFIRMADO de productos de Seguridad durante 2026 
        (evitando duplicados mediante EXISTS y NOT EXISTS), se utiliza la siguiente consulta:  ***/

SELECT DISTINCT c.ClienteID, c.Nombre, c.Ciudad
FROM dbo.Cliente c
WHERE EXISTS (

    -- Al menos un pedido CONFIRMADO de Redes en 2026
    SELECT 1 
    FROM dbo.Pedido p
    JOIN dbo.DetallePedido d ON p.PedidoID = d.PedidoID
    JOIN dbo.Producto pr ON d.ProductoID = pr.ProductoID
    WHERE p.ClienteID = c.ClienteID
      AND p.Estado = 'CONFIRMADO'
      AND YEAR(p.FechaPedido) = 2026
      AND pr.CategoriaID = 1 -- Categoría Redes
)
AND NOT EXISTS (

    -- Sin pedidos CONFIRMADO de Seguridad en 2026
    SELECT 1 
    FROM dbo.Pedido p
    JOIN dbo.DetallePedido d ON p.PedidoID = d.PedidoID
    JOIN dbo.Producto pr ON d.ProductoID = pr.ProductoID
    WHERE p.ClienteID = c.ClienteID
      AND p.Estado = 'CONFIRMADO'
      AND YEAR(p.FechaPedido) = 2026
      AND pr.CategoriaID = 2 -- Categoría Seguridad
);

---- B. Subconsulta correlacionada ----
/***    Para listar los productos (ProductoID, Nombre, categoría, PrecioLista) junto con 
        el promedio de precio de su propia categoría, filtrando únicamente aquellos cuyo 
        PrecioLista sea estrictamente superior a dicho promedio:    ***/

SELECT 
    pr.ProductoID, 
    pr.Nombre, 
    cat.Nombre AS Categoria, 
    pr.PrecioLista,
    (
        SELECT AVG(p_sub.PrecioLista) 
        FROM dbo.Producto p_sub 
        WHERE p_sub.CategoriaID = pr.CategoriaID
    ) AS PromedioCategoria
FROM dbo.Producto pr
JOIN dbo.Categoria cat ON pr.CategoriaID = cat.CategoriaID
WHERE pr.PrecioLista > (
    SELECT AVG(p_sub.PrecioLista) 
    FROM dbo.Producto p_sub 
    WHERE p_sub.CategoriaID = pr.CategoriaID
);

    /** Criterio empleado para calcular el promedio: Se utiliza una subconsulta correlacionada 
        que calcula la función de agregación AVG(PrecioLista) agrupando internamente por la tabla 
        CategoriaID de cada producto evaluado en la consulta principal (p_sub.CategoriaID = pr.CategoriaID). 
        Esto permite comparar el precio de lista de cada producto de manera dinámica contra la media 
        aritmética exacta de su respectiva categoría.   **/

---- C. Justificación: uso de EXISTS/NOT EXISTS frente a IN/NOT IN -----

/***    Eficiencia y Evaluación de Cortocircuito: EXISTS evalúa la subconsulta devolviendo un valor booleano 
        (TRUE o FALSE) y se detiene (hace cortocircuito) en cuanto encuentra la primera coincidencia, optimizando 
        el rendimiento.

        Manejo seguro de valores nulos: A diferencia de NOT IN —el cual falla o no devuelve registros si la 
        subconsulta interna llega a arrojar al menos un valor NULL (debido a la lógica ternaria de SQL donde 
        NOT (X IN (NULL)) se evalúa como UNKNOWN)—, NOT EXISTS evalúa de forma robusta la no existencia de filas 
        sin verse afectado por la presencia de nulos.

----    Cliente incluido: usaremos como ejemplo al ClienteID 1 - Ana Ramírez Torres
        Cuenta con pedidos confirmados de Redes en 2026 (ej. el pedido con ID 8 del 01/01/2026 contiene productos 
        de Redes). Al verificaer sus compras en Seguridad durante 2026, no registra ningún pedido confirmado en dicha 
        categoría, cumpliendo ambas condiciones de la consulta.
        
        Cliente excluido: usaremos como ejemplo al ClienteID 5 - Elena Torres Paredes
        Aunque cumple la primera condición al registrar compras de Redes confirmadas en 2026 (ej. pedido 15), es excluido 
        porque la base de datos demuestra que también compró y confirmó productos de la categoría Seguridad durante 2026, 
        violando la restricción del NOT EXISTS.
***/

