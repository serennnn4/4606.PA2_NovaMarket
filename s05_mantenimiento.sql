        USE PA2_NovaMarket;
GO

/* ===================================================================
   ACTIVIDAD 02 | SESIÓN 05  - Mantenimiento DML
   ================================================================= */
   
 /* PRIMERA TAREA: Insert & Select  
 (Corte histórico a PedidoHistorico2025) */


-- 1. Creación de la tabla histórica

IF OBJECT_ID('dbo.PedidoHistorico2025', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PedidoHistorico2025 (
        PedidoID     INT         NOT NULL,
        ClienteID    INT         NOT NULL,
        FechaPedido  DATE        NOT NULL,
        Estado       VARCHAR(15) NOT NULL,
        Canal        VARCHAR(30) NOT NULL,
        CONSTRAINT PK_PedidoHistorico2025 PRIMARY KEY (PedidoID));
END
GO

-- Comprobación previa: Pedidos que cumplen el criterio histórico
SELECT PedidoID, ClienteID, FechaPedido, Estado, Canal
FROM dbo.Pedido
WHERE Estado = 'CONFIRMADO'
  AND FechaPedido < '2026-01-01';

-- Carga controlada: Solo inserta los registros que aún no estén en la tabla destino
INSERT INTO dbo.PedidoHistorico2025 (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado, p.Canal
FROM dbo.Pedido p
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido < '2026-01-01'
  AND NOT EXISTS (
      SELECT 1 
      FROM dbo.PedidoHistorico2025 h 
      WHERE h.PedidoID = p.PedidoID);
GO

-- Verificación origen vs destino
SELECT 
    (SELECT COUNT(*) 
     FROM dbo.Pedido 
     WHERE Estado = 'CONFIRMADO' AND FechaPedido < '2026-01-01') AS TotalEsperadoOrigen,
    (SELECT COUNT(*) 
     FROM dbo.PedidoHistorico2025) AS TotalCargadoDestino;

-- ========================================================
/* SEGUNDA TAREA: UPDATE CONDICIONADO
(Oferta en Redes con Stock >= 10) */


-- 1. Comprobación ANTES: Ver productos de Redes y su estado actual
SELECT 
    pr.ProductoID,
    pr.Nombre,
    cat.Nombre AS Categoria,
    pr.PrecioLista,
    pr.PrecioOferta AS PrecioOfertaActual,
    pr.Stock,
    pr.Activo,
    CASE 
        WHEN cat.Nombre = 'Redes' AND pr.Activo = 1 AND pr.Stock >= 10 THEN 'SI'
        ELSE 'NO'
    END AS DebeAplicarOferta
FROM dbo.Producto pr
JOIN dbo.Categoria cat ON pr.CategoriaID = cat.CategoriaID
ORDER BY cat.CategoriaID, pr.ProductoID;


-- 2. Ejecución del UPDATE condicionado
UPDATE pr
SET pr.PrecioOferta = ROUND(pr.PrecioLista * 0.90, 2)
OUTPUT 
    inserted.ProductoID,
    inserted.Nombre,
    deleted.PrecioOferta AS PrecioOferta_Anterior,
    inserted.PrecioOferta AS PrecioOferta_Nuevo,
    inserted.PrecioLista,
    inserted.Stock
FROM dbo.Producto pr
JOIN dbo.Categoria cat ON pr.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes'
  AND pr.Activo = 1
  AND pr.Stock >= 10;
GO


-- 3. Comprobación: 
-- Verificamos que solo Redes seleccionadas tienen la nueva oferta --*

SELECT 
    pr.ProductoID, 
    pr.Nombre, 
    cat.Nombre AS Categoria, 
    pr.PrecioLista, 
    pr.PrecioOferta, 
    pr.Stock, 
    pr.Activo
FROM dbo.Producto pr
JOIN dbo.Categoria cat ON pr.CategoriaID = cat.CategoriaID
ORDER BY cat.CategoriaID, pr.ProductoID;

-- 4. Comprobación de no alteración en otras categorías:
--    Debe retornar solo el producto 8 (Kit CCTV que ya traía 849.00) 
-- y ningún otro con oferta en Seg/Acc.
SELECT ProductoID, CategoriaID, Nombre, PrecioOferta
FROM dbo.Producto
WHERE CategoriaID <> 1 AND PrecioOferta IS NOT NULL;

-- ========================================================
/* TERCERA TAREA: DELETE PROTEGIDO 
(Depuración de BORRADOR sin detalle) */


-- 1. Comprobación ANTES: Listar todos los borradores y marcar cuáles tienen detalle
SELECT 
    p.PedidoID,
    p.ClienteID,
    p.FechaPedido,
    p.Estado,
    COUNT(d.DetalleID) AS CantidadLineasDetalle,
    CASE 
        WHEN p.Estado = 'BORRADOR' AND COUNT(d.DetalleID) = 0 THEN 'ELIMINAR'
        ELSE 'CONSERVAR'
    END AS AccionEsperada
FROM dbo.Pedido p
LEFT JOIN dbo.DetallePedido d ON p.PedidoID = d.PedidoID
WHERE p.Estado = 'BORRADOR'
GROUP BY p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado
ORDER BY p.PedidoID;

-- 2. Ejecución del DELETE protegido
DELETE FROM dbo.Pedido
OUTPUT 
    deleted.PedidoID,
    deleted.ClienteID,
    deleted.FechaPedido,
    deleted.Estado,
    deleted.Canal
WHERE Estado = 'BORRADOR'
  AND NOT EXISTS (
      -- Comprueba que NO exista ninguna fila hija en DetallePedido
      SELECT 1 
      FROM dbo.DetallePedido d 
      WHERE d.PedidoID = dbo.Pedido.PedidoID
  );
GO


-- 3. Comprobación DESPUÉS: Verificar que los únicos borradores que quedan son los que tienen detalle
SELECT 
    p.PedidoID,
    p.ClienteID,
    p.FechaPedido,
    p.Estado,
    COUNT(d.DetalleID) AS LineasDetalle
FROM dbo.Pedido p
JOIN dbo.DetallePedido d ON p.PedidoID = d.PedidoID
WHERE p.Estado = 'BORRADOR'
GROUP BY p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado;

-- 4. Verificación de conteo general por estado (Demostrar que pedidos válidos no se tocaron)
SELECT Estado, COUNT(*) AS TotalPedidosRestantes
FROM dbo.Pedido
GROUP BY Estado
ORDER BY Estado;