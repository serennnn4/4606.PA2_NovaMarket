# Proceso de Aprendizaje 2 | NovaMarket

   PA2 - Esquema base: NovaMarket
   Curso: Programación Avanzada de Base de Datos (30627)
   Motor: SQL Server | Autenticación de Windows | instancia local

## Integrantes:

   * LUIGUI ALVA SANCHEZ - Actividad 1  48584750@mail.isil.pe
   * MARIA FERNANDA LEON CATALAN - Actividad 2 75443768@mail.isil.pe
   * NADIA MABEL VINCES ASCA - Actividad 3 70474181@mail.isil.pe
   * JEAN LUC MELLET DEL CASTILLO - Actividad 4 73994056@mail.isil.pe
   * RODRIGO GOMEZ CARRASCO - Creación Base de datos 72207949@mail.isil.pe
  
   ============================================================ */

## Descripción: 
Se diseñó el siguiente proyecto para la empresa "NovaMarket", negocio del rubro tecnológico que comercializa productos clasificados en Redes, Seguridad y Accesorios. La organización requiere optimizar la segmentación de sus clientes, preservar cortes históricos sin afectar la operatividad del sistema transaccional, gestionar ofertas comerciales controladas y depurar transacciones incompletas. A través de este proyecto se asegura la integridad referencial y consistencia de los datos frente a modificaciones masivas (DML), centralizando reportes comerciales fiables mediante vistas y validaciones reproducibles.

## Objetivo:
Implementar y validar soluciones avanzadas en SQL Server mediante subconsultas correlacionadas, operaciones DML controladas e idempotentes, vistas consolidadas y generación de datos de prueba, asegurando la consistencia y reglas de negocio del caso empresarial.
---

## Desarrollo:
Dividimos el desarrollo en los siguientes puntos:

+ CREACIÓN BBDD



+ ACTIVIDAD 01




+ ACTIVIDAD 02 
* PRIMERA TAREA - Validación de Paridad Origen vs Destino:
Se realiza un conteo cruzado entre la tabla transaccional dbo.Pedido y la tabla destino dbo.PedidoHistorico2025. El resultado demuestra consistencia total en la migración histórica: 
Exactamente, 7 pedidos confirmados anteriores al 01/01/2026 esperados contra 7 registros efectivamente cargados. La omisión de la propiedad IDENTITY en PedidoID garantiza la trazabilidad al conservar los identificadores generados originalmente en origen.
<img width="931" height="290" alt="image" src="https://github.com/user-attachments/assets/bae22c75-7819-407e-a317-03bcbb63a8ca" />


* SEGUNDA TAREA - Prueba de Idempotencia y Cero Duplicados 
Se reejecuta el bloque de inserción para evaluar el comportamiento ante ejecuciones múltiples. La cláusula NOT EXISTS detecta la existencia previa de los registros y filtra la totalidad de las filas, insertando 0 registros nuevos y evitando violaciones de la clave primaria (PK_PedidoHistorico2025). El conteo posterior certifica que la tabla se mantiene en 7 filas, sin duplicados ni registros pendientes.
<img width="932" height="1000" alt="image" src="https://github.com/user-attachments/assets/2624083d-8eb9-482e-8417-6c185925c06c" />


* TERCERA TAREA - Comprobación Previa de Alcance:
Se evalúan las tres condiciones solicitadas por el negocio antes de modificar los datos: pertenencia a la categoría 'Redes' (CategoriaID = 1), producto operativo (Activo = 1) y disponibilidad suficiente (Stock >= 10). La consulta demuestra que únicamente los productos con ID 1, 2 y 3 califican para el descuento comercial. El producto 4 queda excluido por rotación crítica (Stock = 9), el producto 5 por descatalogación (Activo = 0), y los productos restantes por pertenecer a categorías distintas.
<img width="742" height="752" alt="image" src="https://github.com/user-attachments/assets/fb040328-d67c-463d-9ca0-496812151506" />

* CUARTA TAREA - Ejecución y Comprobación de No Acumulabilidad (Tarea B):

Se aplicó el 10 % de descuento formulado como ROUND(pr.PrecioLista * 0.90, 2). La cláusula OUTPUT certifica que el cálculo se basa en la columna fija PrecioLista y no sobre PrecioOferta, haciendo que la operación sea determinista: en ejecuciones sucesivas, el precio anterior y el posterior resultan idénticos, evitando que el descuento se acumule y degrade el margen del producto.

<img width="878" height="500" alt="image" src="https://github.com/user-attachments/assets/ed3353a9-76b4-468a-b0aa-184c2b3290f0" />







+ ACTIVIDAD 03: Vistas SQL y reutilización de consultas, se crearon dos vistas para facilitar la consulta de información en NovaMarket.

A) Vista de ventas por categoría y mes: Se creó vw_VentasCategoriaMes para resumir las unidades vendidas y los montos totales por categoría y mes, considerando únicamente pedidos confirmados.
<img width="790" height="481" alt="c15d9b3c-14f5-4292-a9a6-4a9451aa36dd" src="https://github.com/user-attachments/assets/8e689887-045f-49f3-8a76-72c3b226d129" />

B) Vista de clientes sin CONFIRMAR: Se creó vw_ClientesSinCompra2026 para identificar a los clientes que no realizaron pedidos confirmados durante el año 2026. Se verificaron los resultados mediante una consulta alternativa.
<img width="673" height="491" alt="b9db2d4d-8dfb-4577-a698-a21971d5bbad" src="https://github.com/user-attachments/assets/bed07e28-f652-4a44-b16d-7dcf047108e1" />

C) Consumo y verificación: Se consultaron ambas vistas y se comprobaron los montos de ventas de febrero (Redes: 1737.60) y mayo (Accesorios: 150.30) con consultas a las tablas originales. Las vistas permiten reutilizar la lógica y facilitar el mantenimiento del código.
<img width="655" height="505" alt="01b3c8b9-eb79-4c6b-9b45-a7092d0fcb3d" src="https://github.com/user-attachments/assets/285c4d71-2fcd-42c0-a3b1-046201167294" />

+ ACTIVIDAD 04
