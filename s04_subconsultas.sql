USE PA2_NovaMarket;

---- A. Segmentación con EXISTS y NOT EXISTS -----
/***    Para listar los clientes que tengan al menos un pedido CONFIRMADO de productos de Redes 
        durante 2026 y que NO tengan pedidos CONFIRMADO de productos de Seguridad durante 2026 
        (evitando duplicados mediante EXISTS y NOT EXISTS), se utiliza la siguiente consulta:   ***/

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

---- C. Justificación del uso de EXISTS/NOT EXISTS frente a IN/NOT IN -----

/***    Eficiencia y Evaluación de Cortocircuito: EXISTS evalúa la subconsulta devolviendo un valor booleano 
        (TRUE o FALSE) y se detiene (hace cortocircuito) en cuanto encuentra la primera coincidencia, optimizando 
        el rendimiento.

        Manejo seguro de valores nulos: A diferencia de NOT IN —el cual falla o no devuelve registros si la 
        subconsulta interna llega a arrojar al menos un valor NULL (debido a la lógica ternaria de SQL donde 
        NOT (X IN (NULL)) se evalúa como UNKNOWN)—, NOT EXISTS evalúa de forma robusta la no existencia de filas 
        sin verse afectado por la presencia de nulos.

----    Cliente incluido: usaremos como ejemplo al ClienteID 1 - Ana Ramírez Torres
        Cuenta con pedidos confirmados de Redes en 2026 (ej. el pedido con ID 8 del 01/01/2026 contiene productos 
        de Redes). Al verificar sus compras en Seguridad durante 2026, no registra ningún pedido confirmado en dicha 
        categoría, cumpliendo ambas condiciones de la consulta.
        
        Cliente excluido: usaremos como ejemplo al ClienteID 5 - Elena Torres Paredes
        Aunque cumple la primera condición al registrar compras de Redes confirmadas en 2026 (ej. pedido 15), es excluido 
        porque la base de datos demuestra que también compró y confirmó productos de la categoría Seguridad durante 2026, 
        violando la restricción del NOT EXISTS.
***/
