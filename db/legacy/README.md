# Scripts históricos

Estos scripts se conservan para trazabilidad, separados de la instalación y
de las migraciones actuales:

- `auditoriaPagos.sql`: definición independiente anterior de auditoría de pagos.
- `auditar_actualizar_datos.sql`: correcciones históricas de datos DEMO y reglas
  de pago anteriores a la política de reservas pendientes.

No ejecutarlos sobre una instalación actual como si fueran migraciones: pueden
reemplazar reglas vigentes o cambiar datos. Para instalar o actualizar, utilizar
el [instalador y las migraciones documentadas](../README.md).
