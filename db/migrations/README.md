# Migraciones de SQL Server

Para una base existente, aplicar los cambios pendientes con una cuenta
administradora y un respaldo verificado. Para una instalación nueva, utilizar
`../reservasScouts.sql` según [db/README.md](../README.md).

## Orden de referencia

| Orden | Archivo | Responsabilidad |
| --- | --- | --- |
| 1 | `001_cumplimiento.sql` | Sesión, auditoría y estructura base de actualización. |
| 2 | `002_roles_y_permisos.sql` | Roles y permisos. |
| 3 | `006_limpiar_nombres_visibles.sql` | Normalizar nombres antes de agregar espacios. |
| 4 | `005_espacios_demostracion.sql` | Espacios opcionales de demostración. |
| 5 | `007_fechas_ocupadas.sql` | Calendario de ocupación. |
| 6 | `008_contacto_solicitante.sql` | Contacto del solicitante. |
| 7 | `009_disponibilidad_reservas.sql` | Consulta de disponibilidad. |
| 8 | `010_reserva_pago_bloqueo.sql` | Confirmación, pagos, comprobantes y bloqueos. |
| 9 | `011_notificaciones_compartidas.sql` | Revisión compartida y trazabilidad. |
| 10 | `012_reservas_propias.sql` | Reservas vinculadas a la cuenta. |
| 11 | `012_registro_cobros.sql` | Saldos, cobros y anulaciones. |
| 12 | `013_perfiles_registrados.sql` | Perfiles de cuentas registradas. |
| 13 | `013_efectivo_anticipado.sql` | Confirmación anticipada del efectivo recibido. |
| 14 | `014_eliminacion_auditada_comprobantes.sql` | Archivo de reservas y comprobantes. |
| 15 | `015_respaldos_auditados.sql` | Catálogo y auditoría externa de respaldos. |
| 16 | `016_perfiles_auditoria.sql` | Consulta y auditoría de perfiles. |
| 17 | `017_reservas_pendientes_pago.sql` | Cupos pendientes, plazos y vencimiento. |

Los prefijos `012` y `013` se repiten porque existen cambios distintos con esos
números. Sus contenidos no son duplicados: se necesitan ambos archivos de cada
prefijo. Se mantienen los nombres originales para no perder las referencias
de instalaciones existentes. El orden anterior es explícito; no hay un ejecutor
automático de migraciones.

Las definiciones del instalador y sus actualizaciones pueden coincidir: cumplen
funciones diferentes. No eliminar procedimientos de una migración porque también
aparezcan en el instalador. No volver a aplicar migraciones antiguas después de
las actuales sin revisar qué definiciones reemplazan.
