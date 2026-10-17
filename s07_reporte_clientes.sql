/* ===================================================================
   ACTIVIDAD 04 | SESIÓN 07 - B) Reporte de ventas por cliente
                             C) Pruebas y sustento
   Base: PA2_NovaMarket. Ejecutar después de s07_datos_prueba.sql.
   ================================================================= */

USE PA2_NovaMarket;
GO

/* B) Reporte para TODOS los clientes activos.
      - OUTER APPLY: devuelve una fila por cliente aunque no tenga pedidos
        (el equivalente a un LEFT JOIN).
      - Los filtros de Estado y fecha van DENTRO del APPLY, no en el WHERE
        externo, para no eliminar a los clientes sin ventas.
      - COUNT(DISTINCT p.PedidoID): un pedido con varias líneas se cuenta
        una sola vez.
      - ISNULL(..., 0): cuando el cliente no tiene filas, SUM devuelve NULL;
        el reporte debe mostrar 0.                                          */
SELECT
    c.ClienteID,
    c.Nombre,
    ISNULL(x.TotalPedidos2026, 0)    AS TotalPedidos2026,
    ISNULL(x.MontoVendido2026, 0.00) AS MontoVendido2026
FROM dbo.Cliente AS c
OUTER APPLY (
    SELECT
        COUNT(DISTINCT p.PedidoID)          AS TotalPedidos2026,
        SUM(d.Cantidad * d.PrecioUnitario)  AS MontoVendido2026
    FROM dbo.Pedido AS p
    JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
    WHERE p.ClienteID   = c.ClienteID
      AND p.Estado      = 'CONFIRMADO'
      AND p.FechaPedido BETWEEN '2026-01-01' AND '2026-12-31'
) AS x
WHERE c.Activo = 1
ORDER BY c.ClienteID;
GO

/* C) Matriz de pruebas: resultado esperado vs. resultado obtenido.
      Los valores esperados se calcularon a mano desde los datos base:
        E1 cliente 10: pedido 23 = 1 x 79.90 + 8 x 12.90 = 183.10
           (el pedido 26 está PENDIENTE y no cuenta)
        E2 cliente 14: no tiene pedidos -> 0 y 0.00
        E3 cliente 13: solo pedido 29 PENDIENTE y borradores -> 0 y 0.00
        E4 cliente 12: pedido 22 = 289.90 + 119.90 + 2 x 12.90 = 435.60
           (el pedido 31 está ANULADO y no cuenta)                          */
WITH Reporte AS (
    SELECT
        c.ClienteID,
        ISNULL(x.TotalPedidos2026, 0)    AS TotalPedidos2026,
        ISNULL(x.MontoVendido2026, 0.00) AS MontoVendido2026
    FROM dbo.Cliente AS c
    OUTER APPLY (
        SELECT
            COUNT(DISTINCT p.PedidoID)         AS TotalPedidos2026,
            SUM(d.Cantidad * d.PrecioUnitario) AS MontoVendido2026
        FROM dbo.Pedido AS p
        JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
        WHERE p.ClienteID   = c.ClienteID
          AND p.Estado      = 'CONFIRMADO'
          AND p.FechaPedido BETWEEN '2026-01-01' AND '2026-12-31'
    ) AS x
    WHERE c.Activo = 1
),
Esperado AS (
    SELECT * FROM (VALUES
        ('E1 Cliente con varias líneas en un pedido', 10, 1, CAST(183.10 AS DECIMAL(12,2))),
        ('E2 Cliente sin compras confirmadas',        14, 0, CAST(0.00   AS DECIMAL(12,2))),
        ('E3 Pedido PENDIENTE no se cuenta',          13, 0, CAST(0.00   AS DECIMAL(12,2))),
        ('E4 Pedido ANULADO no se cuenta',            12, 1, CAST(435.60 AS DECIMAL(12,2)))
    ) AS t (Prueba, ClienteID, PedidosEsperados, MontoEsperado)
)
SELECT
    e.Prueba,
    e.ClienteID,
    e.PedidosEsperados,
    r.TotalPedidos2026  AS PedidosObtenidos,
    e.MontoEsperado,
    r.MontoVendido2026  AS MontoObtenido,
    CASE WHEN r.TotalPedidos2026 = e.PedidosEsperados
          AND r.MontoVendido2026 = e.MontoEsperado
         THEN 'OK' ELSE 'FALLA' END AS Resultado
FROM Esperado AS e
LEFT JOIN Reporte AS r ON r.ClienteID = e.ClienteID
ORDER BY e.Prueba;
GO

/* Demostración 1: por qué COUNT(DISTINCT).
   Con COUNT(*) el pedido 23 del cliente 10 se contaría 2 veces (tiene 2 líneas). */
SELECT
    p.ClienteID,
    COUNT(*)                   AS ConteoPorLineas_Incorrecto,
    COUNT(DISTINCT p.PedidoID) AS ConteoPorPedido_Correcto
FROM dbo.Pedido AS p
JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
WHERE p.ClienteID   = 10
  AND p.Estado      = 'CONFIRMADO'
  AND p.FechaPedido BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY p.ClienteID;

/* Demostración 2: filtro mal ubicado.
   Si el Estado y la fecha se filtran en el WHERE de un LEFT JOIN, las filas
   de clientes sin pedidos (que llegan con NULL) se descartan y el LEFT JOIN
   termina funcionando como un INNER JOIN. El reporte correcto tiene 14
   clientes activos; la versión incorrecta pierde a los que no compraron. */
SELECT
    (SELECT COUNT(*) FROM dbo.Cliente WHERE Activo = 1) AS ClientesActivos_Correcto,
    (SELECT COUNT(DISTINCT c.ClienteID)
     FROM dbo.Cliente AS c
     LEFT JOIN dbo.Pedido AS p ON p.ClienteID = c.ClienteID
     WHERE c.Activo = 1
       AND p.Estado = 'CONFIRMADO'
       AND p.FechaPedido BETWEEN '2026-01-01' AND '2026-12-31') AS Clientes_FiltroEnWhere_Incorrecto;
GO

/* ===================================================================
   SUSTENTO
   Tratamiento de NULL: cuando un cliente no tiene pedidos CONFIRMADO de
   2026, el OUTER APPLY no encuentra filas. COUNT devuelve 0, pero SUM
   devuelve NULL, y NULL no es lo mismo que cero en un reporte de montos.
   Por eso se envuelve con ISNULL(..., 0): los clientes sin compras salen
   con 0 pedidos y 0.00 de monto, como pide la regla del reporte.

   Cómo evitar perder clientes sin ventas: la tabla de partida es Cliente
   y las condiciones sobre Pedido (estado y fecha) van dentro del APPLY o
   en el ON de un LEFT JOIN. Si se ponen en el WHERE externo, se comparan
   contra NULL, la condición da UNKNOWN y SQL Server descarta la fila del
   cliente. La demostración 2 lo muestra con números.

   Conclusión: las cuatro pruebas deben salir OK. El reporte cuenta pedidos
   y no líneas, ignora PENDIENTE, ANULADO y BORRADOR, respeta los límites
   del año 2026 e incluye a todos los clientes activos.
   ================================================================= */
