/* ===================================================================
   ACTIVIDAD 04 | SESIÓN 07 - A) Generación y control de datos de prueba
   Base: PA2_NovaMarket (la misma de 00_esquema_y_datos_base.sql)

   Objetivo: ampliar la base hasta al menos 200 pedidos y 400 detalles
   con claves foráneas válidas, mostrar los conteos por tabla, la
   distribución por estado y año, y dejar identificados los escenarios
   de prueba que usa el reporte de s07_reporte_clientes.sql.

   La carga es determinística (sin NEWID ni RAND): cada vez que se corre
   sobre la base recién creada genera exactamente los mismos datos, así
   los resultados esperados del reporte se pueden comprobar.
   ================================================================= */

USE PA2_NovaMarket;
GO

-- 1. Conteo ANTES de la ampliación
SELECT 'Pedido' AS Tabla, COUNT(*) AS Filas FROM dbo.Pedido
UNION ALL SELECT 'DetallePedido', COUNT(*) FROM dbo.DetallePedido;
GO

/* 2. Ampliación con INSERT ... SELECT
      - 170 pedidos nuevos, numerados N = 1..170.
      - Cliente: 1 + (N % 9), o sea solo clientes 1 a 9. Los clientes 10 a 16
        quedan intactos a propósito porque son los casos de prueba del reporte.
      - Fecha: repartida entre 01/01/2025 y 15/10/2026 (653 días posibles).
      - Estado: 60 % CONFIRMADO, 20 % PENDIENTE, 10 % ANULADO, 10 % BORRADOR.
      - Cada pedido nuevo recibe 2 líneas de detalle con productos distintos.
      - Precio histórico: en 2025 se vendió al 95 % del PrecioLista actual.
      - El IF evita duplicar la carga si el script se ejecuta dos veces.     */

DECLARE @UltimoPedido INT = (SELECT MAX(PedidoID) FROM dbo.Pedido);

IF (SELECT COUNT(*) FROM dbo.Pedido) < 200
BEGIN
    ;WITH Numeros AS (
        SELECT TOP (170) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
        FROM sys.all_objects
    )
    INSERT INTO dbo.Pedido (ClienteID, FechaPedido, Estado, Canal)
    SELECT
        1 + (N % 9),
        DATEADD(DAY, (N * 37) % 653, CAST('2025-01-01' AS DATE)),
        CASE
            WHEN N % 10 < 6 THEN 'CONFIRMADO'
            WHEN N % 10 < 8 THEN 'PENDIENTE'
            WHEN N % 10 = 8 THEN 'ANULADO'
            ELSE 'BORRADOR'
        END,
        CASE N % 4
            WHEN 0 THEN 'Web'
            WHEN 1 THEN 'Tienda'
            WHEN 2 THEN 'WhatsApp'
            ELSE 'Teléfono'
        END
    FROM Numeros
    ORDER BY N;

    -- Primera línea de cada pedido nuevo
    INSERT INTO dbo.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
    SELECT
        p.PedidoID,
        pr.ProductoID,
        1 + ((p.PedidoID - @UltimoPedido) % 4),
        CASE WHEN p.FechaPedido < '2026-01-01'
             THEN ROUND(pr.PrecioLista * 0.95, 2)
             ELSE pr.PrecioLista END
    FROM dbo.Pedido AS p
    JOIN dbo.Producto AS pr
      ON pr.ProductoID = 1 + ((p.PedidoID - @UltimoPedido) % 12)
    WHERE p.PedidoID > @UltimoPedido;

    -- Segunda línea, con otro producto (desplazado 5 posiciones)
    INSERT INTO dbo.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
    SELECT
        p.PedidoID,
        pr.ProductoID,
        1 + ((p.PedidoID - @UltimoPedido + 2) % 3),
        CASE WHEN p.FechaPedido < '2026-01-01'
             THEN ROUND(pr.PrecioLista * 0.95, 2)
             ELSE pr.PrecioLista END
    FROM dbo.Pedido AS p
    JOIN dbo.Producto AS pr
      ON pr.ProductoID = 1 + ((p.PedidoID - @UltimoPedido + 5) % 12)
    WHERE p.PedidoID > @UltimoPedido;
END
GO

-- 3. Conteo DESPUÉS por tabla y control del volumen mínimo
SELECT 'Cliente' AS Tabla, COUNT(*) AS Filas FROM dbo.Cliente
UNION ALL SELECT 'Categoria',     COUNT(*) FROM dbo.Categoria
UNION ALL SELECT 'Producto',      COUNT(*) FROM dbo.Producto
UNION ALL SELECT 'Pedido',        COUNT(*) FROM dbo.Pedido
UNION ALL SELECT 'DetallePedido', COUNT(*) FROM dbo.DetallePedido;

SELECT
    (SELECT COUNT(*) FROM dbo.Pedido)        AS TotalPedidos,
    (SELECT COUNT(*) FROM dbo.DetallePedido) AS TotalDetalles,
    CASE WHEN (SELECT COUNT(*) FROM dbo.Pedido) >= 200
          AND (SELECT COUNT(*) FROM dbo.DetallePedido) >= 400
         THEN 'CUMPLE' ELSE 'NO CUMPLE' END  AS VolumenMinimo;

-- 4. Distribución por estado y año
SELECT YEAR(FechaPedido) AS Anio, Estado, COUNT(*) AS Pedidos
FROM dbo.Pedido
GROUP BY YEAR(FechaPedido), Estado
ORDER BY Anio, Estado;

-- 5. Integridad referencial: las dos consultas deben devolver 0 filas
SELECT d.DetalleID AS DetalleHuerfano
FROM dbo.DetallePedido AS d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pedido   AS p  WHERE p.PedidoID    = d.PedidoID)
   OR NOT EXISTS (SELECT 1 FROM dbo.Producto AS pr WHERE pr.ProductoID = d.ProductoID);

SELECT p.PedidoID AS PedidoSinCliente
FROM dbo.Pedido AS p
WHERE NOT EXISTS (SELECT 1 FROM dbo.Cliente AS c WHERE c.ClienteID = p.ClienteID);
GO

/* 6. Escenarios de prueba identificados con sus IDs
      E1  Cliente con varias líneas en un pedido: cliente 10, pedido 23
          (CONFIRMADO 2026, 2 líneas). Debe contar 1 pedido, no 2.
      E2  Cliente sin compras confirmadas: cliente 14, sin ningún pedido.
      E3  Pedido PENDIENTE: cliente 13, pedido 29 (su único pedido con
          detalle). No debe sumar en 2026.
      E4  Pedido ANULADO: cliente 12, pedido 31. No debe sumar; el cliente
          solo tiene válido el pedido 22.
      Límites de fecha: pedido 8 (01/01/2026, entra) y pedido 7
      (31/12/2025, queda fuera del año 2026).
      Negativos: clientes 15 y 16 están inactivos y no salen en el reporte. */
SELECT
    p.PedidoID,
    p.ClienteID,
    c.Nombre,
    c.Activo,
    p.FechaPedido,
    p.Estado,
    COUNT(d.DetalleID) AS LineasDetalle,
    CASE p.PedidoID
        WHEN 23 THEN 'E1 varias líneas'
        WHEN 29 THEN 'E3 pendiente'
        WHEN 31 THEN 'E4 anulado'
        WHEN 8  THEN 'Límite 01/01/2026'
        WHEN 7  THEN 'Límite 31/12/2025'
    END AS Escenario
FROM dbo.Pedido AS p
JOIN dbo.Cliente AS c ON c.ClienteID = p.ClienteID
LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
WHERE p.PedidoID IN (7, 8, 23, 29, 31)
GROUP BY p.PedidoID, p.ClienteID, c.Nombre, c.Activo, p.FechaPedido, p.Estado
ORDER BY p.PedidoID;

-- E2: cliente activo sin ningún pedido
SELECT c.ClienteID, c.Nombre, 'E2 sin pedidos' AS Escenario
FROM dbo.Cliente AS c
WHERE c.ClienteID = 14
  AND NOT EXISTS (SELECT 1 FROM dbo.Pedido AS p WHERE p.ClienteID = c.ClienteID);
GO
