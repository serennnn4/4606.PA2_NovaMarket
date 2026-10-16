/* ============================================================
   PA2 - Esquema base: NovaMarket
   Actividad 3: Vistas SQL y reutilización de consultas
   Problema: La dirección requiere reportes reutilizables que muestren 
   ventas confirmadas por categoría e identifiquen clientes sin actividad 
   comercial válida.
   ============================================================ */

USE PA2_NovaMarket
GO

-- A) Vista de consolidación : Crear vw_VentasCategoriaMes con las columnas Anio, Mes, CategoriaID, 
-- NombreCategoria, TotalUnidades y MontoTotal. Considerar únicamente pedidos CONFIRMADO, agrupar 
-- por año, mes y categoría y utilizar Cantidad × PrecioUnitario. Consultar la vista para 2026, 
-- ordenando por mes y monto. 

CREATE OR ALTER VIEW dbo.vw_VentasCategoriaMes
AS
SELECT
YEAR(p.FechaPedido) AS Anio,
MONTH(p.FechaPedido) AS Mes,
c.CategoriaID,
c.Nombre AS NombreCategoria,
SUM(dp.Cantidad) AS TotalUnidades,
SUM(dp.Cantidad * dp.PrecioUnitario) AS MontoTotal
FROM dbo.Pedido AS p
INNER JOIN dbo.DetallePedido AS dp ON p.PedidoID = dp.PedidoID
INNER JOIN dbo.Producto AS pr ON dp.ProductoID = pr.ProductoID
INNER JOIN dbo.Categoria AS c ON pr.CategoriaID = c.CategoriaID
WHERE p.Estado = 'CONFIRMADO'
GROUP BY 
    YEAR(p.FechaPedido), 
    MONTH(p.FechaPedido), 
    c.CategoriaID, 
    c.Nombre;

SELECT Anio, Mes, CategoriaID, NombreCategoria, TotalUnidades, MontoTotal
FROM dbo.vw_VentasCategoriaMes
WHERE Anio = '2026'
ORDER BY Mes, MontoTotal DESC;

-- B) Vista para detectar ausencia de compras : Crear vw_ClientesSinCompra2026 que muestre ClienteID, 
-- Nombre y Ciudad de los clientes sin pedidos CONFIRMADO durante 2026, aunque tengan pedidos de otro estado. 
-- Evitar duplicados y comprobar el resultado mediante una consulta alternativa sobre las tablas originales. 

CREATE OR ALTER VIEW dbo.vw_ClientesSinCompra2026
AS
SELECT
c.ClienteID,
c.Nombre,
c.Ciudad
FROM dbo.Cliente AS c
WHERE NOT EXISTS (
    SELECT 1 
    FROM dbo.Pedido AS p
    WHERE p.ClienteID = c.ClienteID 
      AND p.Estado = 'CONFIRMADO'
      AND YEAR(p.FechaPedido) = '2026'
);

SELECT ClienteID, Nombre, Ciudad
FROM dbo.vw_ClientesSinCompra2026;

-- Comprobación alternativa sobre las tablas originales (sin usar la vista).
-- Debe devolver los mismos clientes que la vista: 11, 13, 14, 15 y 16.
SELECT c.ClienteID, c.Nombre, c.Ciudad
FROM dbo.Cliente AS c
WHERE c.ClienteID NOT IN (
    SELECT p.ClienteID
    FROM dbo.Pedido AS p
    WHERE p.Estado = 'CONFIRMADO'
      AND YEAR(p.FechaPedido) = 2026
);

-- C) Consumo y verificación : Ejecutar SELECT sobre ambas vistas, contrastar al menos dos totales mensuales 
-- con sus registros de origen y explicar qué beneficio funcional aporta centralizar esta lógica en vistas.

/* VISTA --> vw_VentasCategoriaMes */
SELECT Anio, Mes, CategoriaID, NombreCategoria, TotalUnidades, MontoTotal
FROM dbo.vw_VentasCategoriaMes
WHERE Anio = '2026'
ORDER BY Mes, MontoTotal DESC;

-- contraste 1: Febrero 2026 (Mes 2) - Redes (Categoría 1)
-- debe devolver el monto total de 1737.60
SELECT SUM(dp.Cantidad * dp.PrecioUnitario) AS MontoTotal
FROM dbo.Pedido p
JOIN dbo.DetallePedido dp ON dp.PedidoID = p.PedidoID
JOIN dbo.Producto pr ON pr.ProductoID = dp.ProductoID
WHERE p.Estado = 'CONFIRMADO'
  AND YEAR(p.FechaPedido) = 2026
  AND MONTH(p.FechaPedido) = 2
  AND pr.CategoriaID = 1;
GO

-- contraste 2: Mayo 2026 (Mes 5) - Accesorios (Categoría 3)
-- debe devolver el monto total de 150.30
SELECT SUM(dp.Cantidad * dp.PrecioUnitario) AS MontoTotal
FROM dbo.Pedido p
JOIN dbo.DetallePedido dp ON dp.PedidoID = p.PedidoID
JOIN dbo.Producto pr ON pr.ProductoID = dp.ProductoID
WHERE p.Estado = 'CONFIRMADO'
  AND YEAR(p.FechaPedido) = 2026
  AND MONTH(p.FechaPedido) = 5
  AND pr.CategoriaID = 3;
GO

/* ============================================================
El beneficio funcional de centralizar esta lógica en vistas es 
garantizar la consistencia de las reglas de negocio en toda la 
empresa mediante un código simplificado, reutilizable y de fácil 
mantenimiento ante futuros cambios.
============================================================ */ 
