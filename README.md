# Proceso de Aprendizaje 2 | NovaMarket

   PA2 - Esquema base: NovaMarket
   Curso: Programación Avanzada de Base de Datos (30627)
   Motor: SQL Server | Autenticación de Windows | instancia local

## Integrantes:

   * LUIGI ALVA SANCHEZ - Actividad 1  48584750@mail.isil.pe
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
 

+ ACTIVIDAD 02
PRIMERA TAREA:

Se migran los pedidos en estado CONFIRMADO anteriores al 01/01/2026 hacia la tabla PedidoHistorico2025. 
La comprobación cruzada valida la paridad exacta entre origen y destino (7 registros esperados vs 7 registros cargados). La subconsulta con NOT EXISTS garantiza la idempotencia del proceso: ante ejecuciones repetidas, el sistema inserta 0 filas sin generar conflictos con la clave primaria. Asimismo, se omitió la propiedad IDENTITY en PedidoID para conservar el identificador de venta original y mantener la trazabilidad histórica. 

<img width="822" height="265" alt="image" src="https://github.com/user-attachments/assets/98dbe22d-1154-404f-b91a-ad1ad74b4806" />
