USE PA2_NovaMarket;
GO

/* ===================================================================
   ACTIVIDAD 02 | SESIÓN 05  - Mantenimiento DML
   ================================================================= */
   
 /* PRIMERA TAREA: Insert & Select  
 (Corte histórico a PedidoHistorico2025) */


-- 1. Creación de la tabla histórica: 
-- Omitimos IDENTITY para mantener el ID original del pedido.

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

-- 2.Comprobación previa: Pedidos que cumplen el criterio histórico:

SELECT PedidoID, ClienteID, FechaPedido, Estado, Canal
FROM dbo.Pedido
WHERE Estado = 'CONFIRMADO'
  AND FechaPedido < '2026-01-01'
ORDER BY PedidoID;

-- Contamos los registros que deberían estar en el histórico
SELECT COUNT(*) AS TotalEsperadoOrigen
FROM dbo.Pedido
WHERE Estado = 'CONFIRMADO'
  AND FechaPedido < '2026-01-01';



-- 3.Carga controlada con NOT EXISTS para evitar duplicados si se repite la ejecución

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


-- 4. Comprobación: Comparamos la cantidad esperada con la cargada
-- Objetivo: Ambas cant. deben coincidir. (Verificación origen vs destino)
SELECT 
    (SELECT COUNT(*) 
     FROM dbo.Pedido 
     WHERE Estado = 'CONFIRMADO' AND FechaPedido < '2026-01-01') AS TotalEsperadoOrigen,
    (SELECT COUNT(*) 
     FROM dbo.PedidoHistorico2025) AS TotalCargadoDestino;


-- 5. Comprobación DESPUÉS: validar que no falte ningún pedido en el histórico 
-- (esperado: 0 filas)

SELECT p.PedidoID
FROM dbo.Pedido AS p
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido < '2026-01-01'
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.PedidoHistorico2025 AS h
      WHERE h.PedidoID = p.PedidoID);

  -- 6. Comprobación DESPUÉS: buscar registros históricos que no cumplan el criterio.
--    Se espera como resultado: 0 filas.

SELECT h.PedidoID
FROM dbo.PedidoHistorico2025 AS h
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Pedido AS p
    WHERE p.PedidoID = h.PedidoID
      AND p.Estado = 'CONFIRMADO'
      AND p.FechaPedido < '2026-01-01');

-- 7. Prueba de repetición: ejecutar nuevamente el INSERT anterior y repetir
--    las comprobaciones. La cantidad del histórico no debe aumentar.


INSERT INTO dbo.PedidoHistorico2025
    (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT
    p.PedidoID,
    p.ClienteID,
    p.FechaPedido,
    p.Estado,
    p.Canal
FROM dbo.Pedido AS p
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido < '2026-01-01'
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.PedidoHistorico2025 AS h
      WHERE h.PedidoID = p.PedidoID);



-- Conteo posterior: debe mantenerse en 7
SELECT COUNT(*) AS TotalPedidosHistoricos
FROM dbo.PedidoHistorico2025;

-- Verificar que no existan pedidos duplicados en el histórico.
SELECT
    PedidoID,
    COUNT(*) AS Cantidad
FROM dbo.PedidoHistorico2025
GROUP BY PedidoID
HAVING COUNT(*) > 1;

-- Comprobar que todos los pedidos que cumplen el criterio
-- estén registrados en el histórico.
SELECT COUNT(*) AS PedidosPendientesDeInsertar
FROM dbo.Pedido AS p
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido < '2026-01-01'
  AND NOT EXISTS (
    SELECT 1
      FROM dbo.PedidoHistorico2025 AS h
      WHERE h.PedidoID = p.PedidoID);



-- ========================================================
/* SEGUNDA TAREA: UPDATE CONDICIONADO
(Aplicación de la Oferta en Redes con Stock >= 10) 
-- ========================================================*/

-- 1. Comprobación: Ver productos de Redes y su estado actual
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


-- 2. Ejecución 1 del UPDATE: aplicamos 10% de descuento (90% de PrecioLista)
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
-- Verificar que solo los productos elegidos tienen oferta --*

SELECT 
    pr.ProductoID,pr.Nombre, cat.Nombre AS Categoria, pr.PrecioLista, pr.PrecioOferta, pr.Stock, pr.Activo
FROM dbo.Producto pr
JOIN dbo.Categoria cat ON pr.CategoriaID = cat.CategoriaID
ORDER BY cat.CategoriaID, pr.ProductoID;

-- 4. Comprobación de no alteración en otras categorías:
-- (solo el Kit CCTV mantiene su oferta previa)

SELECT ProductoID, CategoriaID, Nombre, PrecioOferta
FROM dbo.Producto
WHERE CategoriaID <> 1 AND PrecioOferta IS NOT NULL;

-- 5. Prueba de repetición: Demostrar que el cálculo NO es acumulativo
--    Al ejecutarse nuevamente sobre PrecioLista, los valores anterior 
-- y nuevo deben coincidir.

UPDATE pr
SET pr.PrecioOferta = ROUND(pr.PrecioLista * 0.90, 2)
OUTPUT 
    inserted.ProductoID,
    inserted.Nombre,
    deleted.PrecioOferta AS PrecioOferta_AntesDeRepetir,
    inserted.PrecioOferta AS PrecioOferta_DespuesDeRepetir
FROM dbo.Producto pr
JOIN dbo.Categoria cat ON pr.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes'
  AND pr.Activo = 1
  AND pr.Stock >= 10;
GO


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

-- 2. Ejecución del DELETE con OUTPUT de auditoría
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
      WHERE d.PedidoID = dbo.Pedido.PedidoID);
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

/* ===================================================================
   D. JUSTIFICACIÓN: OPERACIONES DE MANTENIMIENTO DML
   =================================================================== */
   /***
    Control de duplicados e idempotencia en INSERT ... SELECT:
    Para migrar los pedidos a PedidoHistorico2025 usamos NOT EXISTS en vez de un INSERT directo o vaciar la tabla con TRUNCATE. 
    Esto hace que la operación sea idempotente: si se vuelve a correr el script, el sistema detecta que el registro ya está 
    en la tabla destino y no intenta insertarlo otra vez, evitando que la consulta falle por clave primaria duplicada y manteniendo 
    la cuenta exacta en 7 registros. 
    Además, no colocamos IDENTITY a la tabla histórica para no generar números nuevos y mantener el mismo ID original del pedido.

    Cálculo no acumulativo en el UPDATE:
    La oferta de Redes pedía aplicar el 90 % del precio de lista a productos activos con stock mayor o igual a 10. 
    Para que el descuento no se aplique varias veces si se corre el script de nuevo, el cálculo se hace siempre sobre 
    la columna fija PrecioLista: ROUND(PrecioLista * 0.90, 2), y nunca sobre PrecioOferta. 
    Así, el precio final siempre da el mismo resultado. La cláusula OUTPUT muestra que los productos 1, 2 y 3 reciben su oferta, 
    y que en una segunda ejecución los valores antes y después resultan exactamente iguales.

    Protección de registros en el DELETE:
    Para limpiar carritos abandonados sin borrar datos válidos, combinamos Estado = 'BORRADOR' con NOT EXISTS hacia DetallePedido. 
    Esto impide borrar pedidos que ya tengan productos asignados.

---- Casos de prueba de la depuración (DELETE):
     Pedidos eliminados: tomamos como ejemplo los pedidos del 34 al 38. Cumplen con ser BORRADOR y no tienen ninguna línea en 
     DetallePedido, por lo que NOT EXISTS evalúa como verdadero y el comando los borra de la base (5 filas en total).

     Pedidos conservados: 
     - Pedidos 39 y 40: Aunque son BORRADOR, se quedan en la base porque sí tienen productos cargados, haciendo que NOT EXISTS 
       devuelva falso y evitando que se pierdan.
     - Pedidos CONFIRMADO, PENDIENTE y ANULADO: No entran en el filtro de borrado, comprobando en el conteo final que los 33 pedidos 
       restantes siguen intactos.
***/
