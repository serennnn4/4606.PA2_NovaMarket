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




+ ACTIVIDAD 02 (PENDIENTE POR COMPLETAR)
PRIMERA TAREA:

Se migran los pedidos en estado CONFIRMADO anteriores al 01/01/2026 hacia la tabla PedidoHistorico2025. 
La comprobación cruzada valida la paridad exacta entre origen y destino (7 registros esperados vs 7 registros cargados). La subconsulta con NOT EXISTS garantiza la idempotencia del proceso: ante ejecuciones repetidas, el sistema inserta 0 filas sin generar conflictos con la clave primaria.
Además, se omitió la propiedad IDENTITY en PedidoID para conservar el identificador de venta original y mantener la trazabilidad histórica. 
(pendiente)
<img width="822" height="265" alt="image" src="https://github.com/user-attachments/assets/98dbe22d-1154-404f-b91a-ad1ad74b4806" />


+ ACTIVIDAD 03: Vistas SQL y reutilización de consultas
Se crearon dos vistas para facilitar la consulta de información en NovaMarket

A) Vista de ventas por categoría y mes: Se creó vw_VentasCategoriaMes para resumir las unidades vendidas y los montos totales por categoría y mes, considerando únicamente pedidos confirmados.
<img width="790" height="481" alt="c15d9b3c-14f5-4292-a9a6-4a9451aa36dd" src="https://github.com/user-attachments/assets/8e689887-045f-49f3-8a76-72c3b226d129" />

B) Vista de clientes sin CONFIRMAR: Se creó vw_ClientesSinCompra2026 para identificar a los clientes que no realizaron pedidos confirmados durante el año 2026. Se verificaron los resultados mediante una consulta alternativa.
<img width="673" height="491" alt="b9db2d4d-8dfb-4577-a698-a21971d5bbad" src="https://github.com/user-attachments/assets/bed07e28-f652-4a44-b16d-7dcf047108e1" />

C) Consumo y verificación: Se consultaron ambas vistas y se comprobaron los montos de ventas de febrero (Redes: 1737.60) y mayo (Accesorios: 150.30) con consultas a las tablas originales. Las vistas permiten reutilizar la lógica y facilitar el mantenimiento del código.
<img width="655" height="505" alt="01b3c8b9-eb79-4c6b-9b45-a7092d0fcb3d" src="https://github.com/user-attachments/assets/285c4d71-2fcd-42c0-a3b1-046201167294" />

+ ACTIVIDAD 04
