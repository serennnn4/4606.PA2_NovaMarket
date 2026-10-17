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



---

## ACTIVIDAD 02: Mantenimiento controlado de datos (DML)

### PRIMERA TAREA: INSERT ... SELECT | (Corte histórico a PedidoHistorico2025)
#### **Validación de Paridad Origen vs Destino:**
Se realiza un conteo cruzado entre la tabla transaccional dbo.Pedido y la tabla histórica dbo.PedidoHistorico2025. El resultado confirma que los 7 pedidos calificados en origen (estado 'CONFIRMADO' y fecha anterior al 01/01/2026) migraron en su totalidad al destino. Además, la tabla histórica se creó omitiendo la propiedad IDENTITY en PedidoID para conservar el identificador de venta original y garantizar su trazabilidad

<img width="931" height="290" alt="image" src="https://github.com/user-attachments/assets/bae22c75-7819-407e-a317-03bcbb63a8ca" />


#### **Prueba de Idempotencia y Cero Duplicados:**
Se vuelve a ejecutar la carga para verificar que el script sea seguro ante ejecuciones repetidas. Gracias a la subconsulta con NOT EXISTS, el sistema reconoce que los registros ya existen y no vuelve a insertarlos, evitando errores por clave primaria duplicada. Las tres consultas de validación demuestran que: el total se mantiene exactamente en 7 pedidos, no existen identificadores duplicados y quedan 0 pedidos pendientes de migrar.

<img width="932" height="1000" alt="image" src="https://github.com/user-attachments/assets/2624083d-8eb9-482e-8417-6c185925c06c" />


### SEGUNDA TAREA: UPDATE CONDICIONADO | (Aplicación de Oferta en Redes con Stock >= 10)
#### **Comprobación Previa de Alcance (UPDATE):**
Antes de alterar los precios, se evalúan las tres reglas del negocio: categoría 'Redes' (CategoriaID = 1), producto operativo (Activo = 1) y disponibilidad suficiente (Stock >= 10). La consulta demuestra que únicamente los productos con ID 1, 2 y 3 cumplen todas las condiciones. Quedan excluidos el producto 4 por stock insuficiente (tiene 9 unidades), el producto 5 por encontrarse inactivo, y todos los artículos de Seguridad y Accesorios.

<img width="742" height="752" alt="image" src="https://github.com/user-attachments/assets/fb040328-d67c-463d-9ca0-496812151506" />



#### **Ejecución del UPDATE con cláusula OUTPUT:**
Se aplica el 10 % de descuento fijando PrecioOferta al 90 % del PrecioLista (ROUND(pr.PrecioLista * 0.90, 2)) únicamente para los productos de Redes calificados. La cláusula OUTPUT audita el cambio en tiempo real: demuestra que los productos 1, 2 y 3 no tenían oferta previa (PrecioOferta_Anterior = NULL) y reciben su nuevo precio descontado, respetando la regla de integridad de ser menor a su precio de lista.

<img width="878" height="500" alt="image" src="https://github.com/user-attachments/assets/ed3353a9-76b4-468a-b0aa-184c2b3290f0" />


#### Demostración de Cálculo No Acumulativo:
Se repite la ejecución del UPDATE para comprobar que el descuento no se aplique de forma acumulativa sobre precios previamente rebajados. La cláusula OUTPUT evidencia que las columnas PrecioOferta_AntesDeRepetir y PrecioOferta_DespuesDeRepetir devuelven cifras idénticas. Esto certifica que el cálculo se formuló de manera fija sobre PrecioLista y no sobre PrecioOferta, manteniendo los precios estables y consistentes ante múltiples ejecuciones del script.

<img width="930" height="476" alt="image" src="https://github.com/user-attachments/assets/5849fc2a-e149-47dd-8f40-13c2313aa7b3" />


### TERCERA TAREA: DELETE PROTEGIDO | (Depuración de BORRADOR sin detalle)
#### **Depuración Protegida (DELETE) y Validación de Integridad:**
Se eliminaron únicamente los pedidos en estado BORRADOR que no registraban líneas de detalle hijas, empleando una subconsulta con NOT EXISTS hacia DetallePedido. La cláusula OUTPUT certifica la depuración exacta de los 5 pedidos huérfanos (IDs 34 al 38). La comprobación posterior confirma que los borradores con compras reales asociadas (IDs 39 y 40) se mantuvieron intactos, y el conteo general demuestra que los 33 pedidos válidos (CONFIRMADO, PENDIENTE y ANULADO) no sufrieron modificaciones.

<img width="935" height="1049" alt="image" src="https://github.com/user-attachments/assets/b1f3cfca-5783-4d29-8e23-3045032de8d7" />

---

## ACTIVIDAD 03: Vistas SQL y reutilización de consultas, se crearon dos vistas para facilitar la consulta de información en NovaMarket.

A) Vista de ventas por categoría y mes: Se creó vw_VentasCategoriaMes para resumir las unidades vendidas y los montos totales por categoría y mes, considerando únicamente pedidos confirmados.
<img width="790" height="481" alt="c15d9b3c-14f5-4292-a9a6-4a9451aa36dd" src="https://github.com/user-attachments/assets/8e689887-045f-49f3-8a76-72c3b226d129" />

B) Vista de clientes sin CONFIRMAR: Se creó vw_ClientesSinCompra2026 para identificar a los clientes que no realizaron pedidos confirmados durante el año 2026. Se verificaron los resultados mediante una consulta alternativa.
<img width="673" height="491" alt="b9db2d4d-8dfb-4577-a698-a21971d5bbad" src="https://github.com/user-attachments/assets/bed07e28-f652-4a44-b16d-7dcf047108e1" />

C) Consumo y verificación: Se consultaron ambas vistas y se comprobaron los montos de ventas de febrero (Redes: 1737.60) y mayo (Accesorios: 150.30) con consultas a las tablas originales. Las vistas permiten reutilizar la lógica y facilitar el mantenimiento del código.
<img width="655" height="505" alt="01b3c8b9-eb79-4c6b-9b45-a7092d0fcb3d" src="https://github.com/user-attachments/assets/285c4d71-2fcd-42c0-a3b1-046201167294" />

---
## ACTIVIDAD 04
