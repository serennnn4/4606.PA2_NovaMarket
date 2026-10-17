# PA2 | NovaMarket

Programación Avanzada de Base de Datos (30627) · ISIL
Examen PA2, sesiones 04 a 07 · Microsoft SQL Server

## Integrantes

| Integrante | Usuario GitHub | Actividad | Archivos | Contribución concreta |
|---|---|---|---|---|
| Rodrigo Gómez Carrasco · 72207949@mail.isil.pe | [@rdkhub](https://github.com/rdkhub) | Base de datos | `00 esquema y datos base.sql` | Esquema de las 5 tablas con PK, FK, UNIQUE, CHECK y DEFAULT; datos base (16 clientes, 12 productos, 40 pedidos, 86 detalles) con los casos de prueba que usan S04 a S07 |
| Luigui Alva Sánchez · 48584750@mail.isil.pe | @usuario | Actividad 1 · S04 | `s04_subconsultas.sql` | Segmentación con EXISTS / NOT EXISTS, subconsulta correlacionada por categoría y análisis de casos |
| María Fernanda León Catalán · 75443768@mail.isil.pe | @usuario | Actividad 2 · S05 | `s05_mantenimiento.sql` | Corte histórico con INSERT ... SELECT idempotente, UPDATE de oferta no acumulativo y DELETE protegido, con OUTPUT y comprobaciones antes/después |
| Nadia Mabel Vinces Asca · 70474181@mail.isil.pe | @whitecatador | Actividad 3 · S06 | `s06_vistas.sql` | Vistas `vw_VentasCategoriaMes` y `vw_ClientesSinCompra2026`, consulta alternativa y contraste de dos totales mensuales |
| Jean Luc Mellet del Castillo · 73994056@mail.isil.pe | @usuario | Actividad 4 · S07 | `s07_datos_prueba.sql`, `s07_reporte_clientes.sql` | Ampliación a más de 200 pedidos y 400 detalles, reporte de ventas por cliente y matriz de 4 pruebas |

## Contexto del caso

NovaMarket es una tienda de tecnología que vende productos de Redes, Seguridad y Accesorios. Gerencia necesita segmentar clientes sin duplicarlos, guardar un corte histórico de ventas, publicar ofertas sin tocar productos fuera de la campaña, depurar borradores abandonados y tener reportes de ventas que no se equivoquen con pedidos pendientes, anulados o clientes sin compras.

## Objetivo

Resolver el caso con T-SQL ejecutable sobre una sola base de datos (`PA2_NovaMarket`): subconsultas y EXISTS (S04), mantenimiento controlado con DML (S05), vistas reutilizables (S06) y datos de prueba con un reporte validado contra resultados esperados (S07).

## Requisitos

- Microsoft SQL Server 2016 SP1 o superior (los scripts usan `CREATE OR ALTER VIEW`).
- SQL Server Management Studio (SSMS).
- Conexión con Autenticación de Windows a la instancia local.

## Orden de ejecución

Abrir cada archivo en SSMS y ejecutarlo completo (F5) en este orden:

| Paso | Archivo | Qué hace |
|---|---|---|
| 1 | `00 esquema y datos base.sql` | Crea `PA2_NovaMarket`, las 5 tablas y carga los datos base |
| 2 | `s04_subconsultas.sql` | Consultas de S04 (no modifica datos) |
| 3 | `s05_mantenimiento.sql` | Crea `PedidoHistorico2025`, aplica la oferta y elimina borradores sin detalle |
| 4 | `s06_vistas.sql` | Crea las dos vistas y ejecuta los contrastes |
| 5 | `s07_datos_prueba.sql` | Amplía la base a 205 pedidos y 426 detalles |
| 6 | `s07_reporte_clientes.sql` | Reporte por cliente, matriz de pruebas y demostraciones |

Para volver al estado inicial basta con ejecutar otra vez el paso 1 (borra y recrea las tablas). Si la base ya existe, la línea `CREATE DATABASE` marca el error "ya existe", pero el resto del script continúa y recrea las tablas.

## Esquema

| Tabla | Campos | Restricciones principales |
|---|---|---|
| Cliente | ClienteID, Documento, Nombre, Ciudad, Activo | PK, Documento UNIQUE, Activo DEFAULT 1 |
| Categoria | CategoriaID, Nombre | PK, Nombre UNIQUE (Redes, Seguridad, Accesorios) |
| Producto | ProductoID, CategoriaID, Nombre, PrecioLista, PrecioOferta, Stock, Activo | FK a Categoria, PrecioLista > 0, PrecioOferta NULL o entre 0 y PrecioLista, Stock >= 0 |
| Pedido | PedidoID, ClienteID, FechaPedido, Estado, Canal | FK a Cliente, Estado en CONFIRMADO, PENDIENTE, ANULADO, BORRADOR |
| DetallePedido | DetalleID, PedidoID, ProductoID, Cantidad, PrecioUnitario | FK a Pedido y Producto, Cantidad > 0, PrecioUnitario > 0 |

`PrecioUnitario` guarda el precio histórico de la venta. En los pedidos de 2025 se vendió al 95 % del `PrecioLista` actual, así que el reporte usa siempre `Cantidad × PrecioUnitario` y nunca el precio del producto.

## Datos base y casos preparados

- 16 clientes (14 activos, 2 inactivos), 12 productos, 40 pedidos y 86 detalles.
- Pedidos de 2025 y 2026 en los cuatro estados: 25 CONFIRMADO, 5 PENDIENTE, 3 ANULADO, 7 BORRADOR.
- 7 pedidos CONFIRMADO anteriores al 01/01/2026 (pedidos 1 a 7). El pedido 7 es del 31/12/2025 y el 8 del 01/01/2026, para probar el límite del año.
- 5 borradores sin detalle (34 a 38) y 2 borradores con detalle (39 y 40).
- Productos de Redes en el límite de la oferta: el 2 tiene stock 10 (entra), el 4 tiene stock 9 (no entra) y el 5 está inactivo.

---

## Actividad 1 · S04: Subconsultas y EXISTS

**A. Segmentación.** Clientes con al menos un pedido CONFIRMADO de Redes en 2026 y ningún pedido CONFIRMADO de Seguridad en 2026. Se usa `EXISTS` para la primera condición y `NOT EXISTS` para la segunda, así cada cliente aparece una sola vez aunque tenga varios pedidos.

| ClienteID | Nombre | Ciudad |
|---|---|---|
| 1 | Ana Ramírez Torres | Lima |
| 2 | Carlos Flores Medina | Arequipa |
| 3 | Bertha Quispe Huamán | Cusco |
| 4 | Diego Salazar Vega | Lima |
| 12 | Luis Herrera Ponce | Trujillo |

Casos que explican el resultado:
- El cliente 4 compró Seguridad, pero en 2025; el filtro de año lo deja pasar.
- El cliente 3 tiene Seguridad en un pedido PENDIENTE y el 12 en uno ANULADO; como no están confirmados, ambos se incluyen.
- El cliente 5 queda excluido porque compró Redes y también Seguridad confirmados en 2026 (caso excluido documentado en el script).

**B. Subconsulta correlacionada.** Productos con `PrecioLista` estrictamente mayor al promedio de su propia categoría. La subconsulta recalcula `AVG(PrecioLista)` filtrando por la categoría del producto evaluado en la consulta externa.

| ProductoID | Producto | PrecioLista | Promedio de su categoría |
|---|---|---|---|
| 1 | Router WiFi 6 AX1800 | 289.90 | 271.54 (Redes) |
| 3 | Access Point empresarial | 459.00 | 271.54 (Redes) |
| 4 | Cable UTP Cat6 caja 305 m | 389.00 | 271.54 (Redes) |
| 7 | Firewall UTM | 1890.00 | 831.75 (Seguridad) |
| 8 | Kit 4 cámaras CCTV | 899.00 | 831.75 (Seguridad) |
| 12 | Tester de red RJ45 | 79.90 | 39.23 (Accesorios) |

El Cable UTP muestra por qué se compara contra la categoría: su precio está por debajo del promedio general de la tienda, pero por encima del promedio de Redes.

**C. Análisis.** `EXISTS` solo pregunta si hay al menos una fila que cumpla, por eso no duplica clientes. Con `NOT IN`, si la subconsulta devuelve un solo NULL, la comparación da UNKNOWN y la consulta no devuelve ninguna fila; `NOT EXISTS` no tiene ese problema. La precaución con `NOT IN` es filtrar `WHERE columna IS NOT NULL` dentro de la subconsulta o usar `NOT EXISTS`.

Evidencia: [ captura de los resultados de A y B ]

---

## Actividad 2 · S05: Mantenimiento controlado de datos (DML)

### A. INSERT ... SELECT (corte histórico a PedidoHistorico2025)

**Validación origen vs destino.** Se hace un conteo cruzado entre `dbo.Pedido` y `dbo.PedidoHistorico2025`. Los 7 pedidos que cumplen el criterio en origen (CONFIRMADO y fecha anterior al 01/01/2026) pasaron todos al destino. La tabla histórica no tiene IDENTITY en `PedidoID`, para conservar el número de pedido original.

<img width="931" height="290" alt="image" src="https://github.com/user-attachments/assets/bae22c75-7819-407e-a317-03bcbb63a8ca" />

**Prueba de repetición sin duplicados.** La carga se ejecuta una segunda vez. El `NOT EXISTS` detecta que los pedidos ya están en el histórico y no los vuelve a insertar, así que no salta error de clave duplicada. Las comprobaciones muestran que el total sigue en 7, que no hay IDs repetidos y que quedan 0 pedidos pendientes de migrar.

<img width="932" height="1000" alt="image" src="https://github.com/user-attachments/assets/2624083d-8eb9-482e-8417-6c185925c06c" />

### B. UPDATE condicionado (oferta en Redes con Stock >= 10)

**Comprobación previa.** Antes de cambiar precios se revisan las tres condiciones: categoría Redes, producto activo y stock de al menos 10 unidades. Solo cumplen los productos 1, 2 y 3. Quedan fuera el 4 (stock 9), el 5 (inactivo) y todo lo de Seguridad y Accesorios.

<img width="742" height="752" alt="image" src="https://github.com/user-attachments/assets/fb040328-d67c-463d-9ca0-496812151506" />

**UPDATE con OUTPUT.** `PrecioOferta = ROUND(PrecioLista * 0.90, 2)` solo para esos productos. El `OUTPUT` muestra el valor anterior (NULL) y el nuevo: 260.91, 107.91 y 413.10. `PrecioLista` no cambia, y el Kit CCTV conserva su oferta previa de 849.00.

<img width="878" height="500" alt="image" src="https://github.com/user-attachments/assets/ed3353a9-76b4-468a-b0aa-184c2b3290f0" />

**Cálculo no acumulativo.** Al repetir el UPDATE, el valor anterior y el nuevo son iguales, porque el descuento siempre se calcula sobre `PrecioLista` y no sobre `PrecioOferta`.

<img width="930" height="476" alt="image" src="https://github.com/user-attachments/assets/5849fc2a-e149-47dd-8f40-13c2313aa7b3" />

### C. DELETE protegido (borradores sin detalle)

Se eliminan solo los pedidos BORRADOR que no tienen ninguna línea en `DetallePedido`, usando `NOT EXISTS`. El `OUTPUT` muestra los 5 pedidos eliminados (34 a 38). Los borradores 39 y 40, que sí tienen detalle, siguen en la tabla, y el conteo por estado confirma que los 25 CONFIRMADO, 5 PENDIENTE y 3 ANULADO no se tocaron (35 pedidos en total después del DELETE).

<img width="935" height="1049" alt="image" src="https://github.com/user-attachments/assets/b1f3cfca-5783-4d29-8e23-3045032de8d7" />

---

## Actividad 3 · S06: Vistas SQL y reutilización de consultas

**A. `vw_VentasCategoriaMes`.** Resume unidades vendidas y monto (`Cantidad × PrecioUnitario`) por año, mes y categoría, solo con pedidos CONFIRMADO. Se consulta para 2026 ordenando por mes y monto.

<img width="790" height="481" alt="c15d9b3c-14f5-4292-a9a6-4a9451aa36dd" src="https://github.com/user-attachments/assets/8e689887-045f-49f3-8a76-72c3b226d129" />

**B. `vw_ClientesSinCompra2026`.** Clientes sin ningún pedido CONFIRMADO en 2026, aunque tengan pedidos en otro estado. Se usa `NOT EXISTS`, así que cada cliente sale una vez. Una consulta alternativa con `NOT IN` sobre las tablas originales devuelve los mismos 5 clientes: 11, 13, 14, 15 y 16.

<img width="673" height="491" alt="b9db2d4d-8dfb-4577-a698-a21971d5bbad" src="https://github.com/user-attachments/assets/bed07e28-f652-4a44-b16d-7dcf047108e1" />

**C. Contraste.** Dos totales de la vista se recalcularon directamente desde `Pedido`, `DetallePedido` y `Producto`, y coinciden:

| Mes 2026 | Categoría | Vista | Tablas originales |
|---|---|---|---|
| Febrero | Redes | 1737.60 | 1737.60 |
| Mayo | Accesorios | 150.30 | 150.30 |

Tener esta lógica en vistas evita repetir los JOIN y el filtro de estado en cada reporte. Si cambia una regla, por ejemplo qué estados cuentan como venta, se corrige en un solo lugar y todos los reportes salen con el mismo cálculo.

<img width="655" height="505" alt="01b3c8b9-eb79-4c6b-9b45-a7092d0fcb3d" src="https://github.com/user-attachments/assets/285c4d71-2fcd-42c0-a3b1-046201167294" />

---

## Actividad 4 · S07: Datos de prueba y validación de consultas

**A. Datos de prueba.** `s07_datos_prueba.sql` agrega 170 pedidos con 2 líneas cada uno mediante `INSERT ... SELECT`. La carga no usa valores aleatorios, así que siempre genera los mismos datos y los resultados esperados se pueden comprobar. Los pedidos nuevos solo van a los clientes 1 a 9, para que los clientes de prueba (10 a 16) no cambien. Un `IF` evita duplicar la carga si el script se ejecuta dos veces.

| Tabla | Filas después de S05 y S07 |
|---|---|
| Cliente | 16 |
| Categoria | 3 |
| Producto | 12 |
| Pedido | 205 |
| DetallePedido | 426 |

| Año | CONFIRMADO | PENDIENTE | ANULADO | BORRADOR |
|---|---|---|---|---|
| 2025 | 66 | 20 | 10 | 10 |
| 2026 | 61 | 19 | 10 | 9 |

Las comprobaciones de integridad (detalles sin pedido o sin producto, pedidos sin cliente) devuelven 0 filas.

Escenarios identificados:

| Escenario | IDs | Qué se prueba |
|---|---|---|
| E1 · varias líneas en un pedido | cliente 10, pedido 23 | Debe contar 1 pedido aunque tenga 2 líneas |
| E2 · sin compras confirmadas | cliente 14 | No tiene pedidos; debe salir con 0 y 0.00 |
| E3 · pedido PENDIENTE | cliente 13, pedido 29 | El pendiente no suma |
| E4 · pedido ANULADO | cliente 12, pedido 31 | El anulado no suma; solo cuenta el pedido 22 |
| Límite de fecha | pedidos 7 y 8 | 31/12/2025 queda fuera, 01/01/2026 entra |
| Negativo | clientes 15 y 16 | Inactivos; no deben aparecer en el reporte |

**B. Reporte por cliente.** `s07_reporte_clientes.sql` lista los 14 clientes activos con `ClienteID | Nombre | TotalPedidos2026 | MontoVendido2026`. Se parte de `Cliente` y se usa `OUTER APPLY` para que los clientes sin compras también salgan. Los filtros de estado y fecha van dentro del APPLY, `COUNT(DISTINCT PedidoID)` evita contar un pedido por cada línea, e `ISNULL` convierte en 0 el NULL que devuelve `SUM` cuando no hay filas.

**C. Matriz de pruebas.** El script compara los valores esperados (calculados a mano desde los datos base) con lo que devuelve el reporte:

| Prueba | Cliente | Esperado | Obtenido | Resultado |
|---|---|---|---|---|
| E1 · varias líneas en un pedido | 10 | 1 pedido · 183.10 | 1 pedido · 183.10 | OK |
| E2 · sin compras confirmadas | 14 | 0 · 0.00 | 0 · 0.00 | OK |
| E3 · pedido PENDIENTE | 13 | 0 · 0.00 | 0 · 0.00 | OK |
| E4 · pedido ANULADO | 12 | 1 pedido · 435.60 | 1 pedido · 435.60 | OK |

El script también incluye dos demostraciones. La primera muestra que con `COUNT(*)` el cliente 10 saldría con 2 pedidos en vez de 1. La segunda muestra que poner el filtro de estado y fecha en el `WHERE` de un `LEFT JOIN` deja el reporte en 11 clientes en lugar de 14, porque las filas con NULL se descartan.

Evidencia: [ captura del reporte y de la matriz de pruebas ]

---

## Comandos de prueba rápidos

```sql
USE PA2_NovaMarket;

-- Volumen y estados
SELECT COUNT(*) FROM dbo.Pedido;          -- 205 después de S05 y S07
SELECT COUNT(*) FROM dbo.DetallePedido;   -- 426
SELECT Estado, COUNT(*) FROM dbo.Pedido GROUP BY Estado;

-- S05: histórico y oferta
SELECT COUNT(*) FROM dbo.PedidoHistorico2025;                        -- 7
SELECT ProductoID, PrecioLista, PrecioOferta FROM dbo.Producto
WHERE PrecioOferta IS NOT NULL;                                      -- 1, 2, 3 y 8

-- S06: vistas
SELECT * FROM dbo.vw_ClientesSinCompra2026;                          -- 11, 13, 14, 15, 16
```

## Limitaciones encontradas

- Los scripts se ejecutan en orden. S07 agrega ventas de 2025 y 2026, así que si se vuelve a correr `s06_vistas.sql` después de S07, los totales de febrero y mayo ya no son 1737.60 y 150.30. Para repetir los contrastes de S06 con esos valores hay que recrear la base con el paso 1.
- El DELETE de S05 es definitivo: los borradores 34 a 38 solo vuelven ejecutando de nuevo el paso 1.
- La ampliación de S07 asigna los productos según el número de pedido, contando desde el último ID existente. Sobre la base recién creada siempre produce los mismos datos; si se insertan pedidos a mano antes de ejecutarla, los valores de los clientes 1 a 9 cambian (los escenarios E1 a E4 no se ven afectados).

## Conclusiones

- Las restricciones del esquema (UNIQUE, CHECK y FK) impiden datos inválidos desde el inicio, por ejemplo una oferta mayor al precio de lista o un detalle sin pedido.
- `EXISTS` y `NOT EXISTS` resolvieron la segmentación sin duplicar clientes y sin el riesgo de NULL que tiene `NOT IN`.
- En S05 cada operación se puede repetir sin efectos de más: el histórico no se duplica, la oferta no se acumula y el DELETE no toca pedidos con detalle.
- Las vistas concentran la regla de qué cuenta como venta; los contrastes contra las tablas originales confirman que los totales son correctos.
- El reporte de S07 pasó las cuatro pruebas: cuenta pedidos y no líneas, ignora PENDIENTE, ANULADO y BORRADOR, respeta el año 2026 y mantiene a los clientes sin compras con valores en cero.

## Video de exposición

Video de YouTube: [ pegar aquí el enlace ]

| Integrante | Parte | Inicio | Fin |
|---|---|---|---|
| Rodrigo Gómez Carrasco | Base de datos y esquema | 00:00 | 00:00 |
| Luigui Alva Sánchez | S04 · Subconsultas | 00:00 | 00:00 |
| María Fernanda León Catalán | S05 · Mantenimiento DML | 00:00 | 00:00 |
| Nadia Mabel Vinces Asca | S06 · Vistas | 00:00 | 00:00 |
| Jean Luc Mellet del Castillo | S07 · Datos de prueba y reporte | 00:00 | 00:00 |
