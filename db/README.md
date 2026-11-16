# Base de datos

El archivo `reservasScouts.sql` es el instalador inicial de la base de datos,
tablas, vistas, funciones, procedimientos, roles y triggers. Para actualizar
una base ya existente, usar únicamente las migraciones documentadas; no volver
a ejecutar el instalador completo.

## Requisitos y ejecución

- Microsoft SQL Server 2025 (compatibilidad 170).
- Habilitar TCP/IP en la instancia de SQL Server y configurar el puerto `1433`;
  reiniciar el servicio de SQL Server después del cambio.
- Habilitar el modo de autenticación de SQL Server y Windows (modo mixto).
- Crear previamente en la instancia un login de autenticación SQL llamado
  `reservas_app` y definir su contraseña en la variable de entorno de usuario
  `RESERVASSCOUTS_DB_PASSWORD`. El backend lee esa variable desde
  `backend/src/main/resources/application.properties`; no guardar contraseñas
  en el repositorio.
- Ejecutar `reservasScouts.sql` una sola vez como instalación inicial desde
  SQL Server Management Studio con **Query > SQLCMD Mode** habilitado, o con
  `sqlcmd`. Requiere permisos para crear bases de datos y usuarios. Los valores
  `DataFilePath` y `LogFilePath` incluidos corresponden a la instalación local
  de SQL Server 2025; ajustarlos si la instancia usa otra carpeta. No volver a
  ejecutar el instalador sobre una base existente.

El script crea la base `reservasScouts`, que coincide con el nombre configurado
en la URL JDBC del backend. El usuario `reservas_app` recibe únicamente permiso
para ejecutar procedimientos almacenados; las lecturas y escrituras se realizan
por medio de esos procedimientos.

`reservas_app` recibe ejecución de procedimientos, no acceso directo a tablas.
El usuario de base `reservas_consulta` (sin login) tiene SELECT solo sobre las
vistas informativas `vReservasResumen` y `vPerfilesConfidencial`. Si se necesita
una cuenta conectable de consulta, debe crearse por separado y mapearse a este
usuario/rol, con una contraseña definida fuera del repositorio.

## Actualización de una base existente

El índice completo y el orden de todos los scripts vigentes están en [migrations/README.md](migrations/README.md). Las primeras migraciones descritas abajo son la base histórica; no sustituyen la aplicación de las posteriores.

Antes de aplicar cambios, crear y verificar un respaldo. Ejecutar en orden
`migrations/001_cumplimiento.sql` y `migrations/002_roles_y_permisos.sql` sobre
`reservasScouts`; ambas son repetibles. La primera agrega o verifica el rol
`Usuario`, la vista `vAuditoriaResumen`, las tablas
`auditoriaAccesos` y `respaldoHistorial`, y los procedimientos de auditoría,
catálogo de respaldos y opciones de perfil. También instala cinco triggers que
registran cambios de espacios, perfiles, usuarios, reservas y pagos, y elimina
las membresías heredadas de lectura y escritura amplia del login `reservasApp`.
Los triggers no guardan credenciales. Las migraciones actuales conservan los campos de contacto de perfiles y reservas necesarios para la auditoría; los accesos y respaldos se registran por separado.

`Administrador` tiene acceso completo. `Recepcionista` puede gestionar
reservas y pagos y consultar espacios y perfiles. `Miembro` y `Usuario` pueden
crear reservas y consultar únicamente las que ellos crearon, además de consultar
espacios y su propio perfil como opción de reserva. Solo `Administrador` puede
administrar usuarios, modificar espacios/perfiles y ver auditoría/respaldos.
El backend guarda la autenticación en una sesión del
servidor con cookie `HttpOnly`, `SameSite=Strict` y 30 minutos de inactividad.
Para publicar con HTTPS, establecer `SESSION_COOKIE_SECURE=true`.

## Respaldos y restauración

La carpeta predeterminada es
`C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup`.
La cuenta del servicio SQL Server debe poder escribir en ella. El backend no
necesita leer directamente el sistema de archivos: el catálogo
`master.dbo.reservasScoutsRespaldos` conserva metadatos y SQL Server verifica el archivo y su
encabezado durante la restauración. Puede configurarse otra carpeta con
`RESERVASSCOUTS_BACKUP_DIRECTORY`, coordinando los permisos del servicio SQL Server.

La aplicación crea copias completas con checksum y ejecuta `RESTORE VERIFYONLY`
antes de ofrecerlas para restauración. Solo acepta archivos generados por esta
aplicación (`reservasScouts_*.bak`) cuyo encabezado identifica la base
`reservasScouts`. La restauración solo está disponible para administradores y
se ejecuta al seleccionar una copia y pulsar Restaurar base de datos. El resultado se muestra en una ventana de éxito o error y queda auditado en master.

Las operaciones de mantenimiento usan un login SQL separado:

1. Cree una contraseña aleatoria de al menos 20 caracteres y guárdela en la
   variable de entorno de usuario `RESERVASSCOUTS_MAINTENANCE_PASSWORD`; nunca
   la agregue al repositorio ni la registre en consola.
2. Ejecute `crearLoginMantenimiento.sql` en SSMS con SQLCMD Mode y defina la
   variable SQLCMD `MaintenancePassword` con el mismo valor. Ejecute la
   migración `migrations/001_cumplimiento.sql` después.
3. El login se agrega al rol de servidor `dbcreator` (requisito de SQL Server
   para restaurar) y al rol `db_backupoperator` únicamente en `reservasScouts`.
   **`dbcreator` puede crear, restaurar y eliminar otras bases de datos de la
   instancia**; por eso esta configuración está pensada solo para desarrollo
   local, no para una instancia compartida o producción. Mantenga TCP/firewall
   restringidos al equipo local y rote la contraseña si cambia de entorno.

`paSistemaEstado` proporciona el estado utilizado por el endpoint de prueba de
conexión sin conceder lectura directa de tablas al usuario de la aplicación.

Consulte el [diccionario de datos](./diccionarioDatos.md), el
[diagrama relacional](./diagrama-relacional.md) y el
[documento de arquitectura de datos](../.github/modernize/assessment/engines/facts/data-architecture.md)
para el esquema y sus relaciones.

## Calendario de disponibilidad

En bases existentes, ejecutar `migrations/007_fechas_ocupadas.sql`. Instala el
procedimiento `paReservaFechasOcupadas` y su permiso de ejecución para
`reservas_app`. Devuelve únicamente el espacio y los horarios de reservas
pendientes vigentes o aprobadas; las canceladas, finalizadas y vencidas no bloquean el calendario.
El instalador inicial también incluye este procedimiento.

## Reservas con pago y plazo de dos minutos

En una base existente, aplicar `009_disponibilidad_reservas.sql` y
`010_reserva_pago_bloqueo.sql` desde `migrations/` en ese orden. El instalador
inicial incorpora el flujo completo. Los bloqueos usan el reloj UTC de SQL
Server y duran 120 segundos; los vencidos no bloquean nuevas solicitudes.
Al confirmar se guardan reserva, pago y comprobante en una sola transaccion.
Los comprobantes admiten PDF, PNG y JPG hasta 5 MB y se descargan solo desde
las rutas de pagos de administracion o recepcion. Se guardan dentro de SQL Server.

SINPE y transferencia generan reserva y pago pendientes. Verificar el pago
aprueba la reserva; rechazarlo la cancela y libera el horario. Efectivo guarda el cupo con la reserva pendiente de pago; se aprueba al confirmar el cobro completo. La tarjeta solo simula un pago:
numero `4242 4242 4242 4242`, codigo `123` y vencimiento vigente. No hay cobros
reales ni almacenamiento de numero de tarjeta o codigo.

## Datos de demostracion actualizados

Ejecutar `sqlcmd -S localhost -E -C -I -b -f 65001 -i db/demo/demo_actualizado.sql`
y luego `powershell -File db/demo/demo_comprobantes.ps1` desde la raiz del proyecto.
Los ejemplos `DEMO-FLUJO-001` a `DEMO-FLUJO-006` cubren efectivo al llegar,
SINPE y transferencia pendientes, tarjeta simulada aprobada, SINPE verificado
y transferencia rechazada. Los adjuntos PNG dicen expresamente que no son
pagos reales. Repetir los scripts no duplica reservas, pagos o comprobantes.
La reserva personal previa al flujo de pagos se conserva sin asignarle un
metodo de pago supuesto.

### Comprobantes IA y vista previa

`output/comprobantes-demo/` contiene dos imagenes generadas con IA.
`output/pdf/` contiene dos comprobantes PDF ficticios generados por
`node db/demo/generar_pdfs_demo.cjs`. Para adjuntarlos a sus registros DEMO
correspondientes, ejecutar `powershell -File db/demo/adjuntar_comprobantes_ia.ps1`.
Solo se sustituyen adjuntos de cuatro pagos DEMO y se conservan sus estados.
Desde Pagos, Ver comprobante abre un visor con descarga para PDF e imagenes.

## Notificaciones compartidas

Aplicar `migrations/011_notificaciones_compartidas.sql` en bases existentes.
La bandeja de administracion y recepcion se calcula a partir de los estados
de reserva y pago: al resolver un pago deja de estar pendiente para todas las
cuentas. La pantalla consulta cada cinco segundos y al recuperar el foco.
La tabla `pagoRevisiones` conserva cuenta revisora, fecha UTC y motivo.
El rechazo exige motivo y cancela la reserva; el efectivo se registra
como recibido cuando el personal confirma la recepcion del dinero. El procedimiento bloquea la reserva
y el pago durante la revision y rechaza intentos duplicados.

## Registro de cobros y anulaciones

Aplicar `migrations/012_registro_cobros.sql` para activar saldos, detalles e
historial de anulaciones. Registrar cobro solo ofrece reservas activas con
saldo y sin un pago pendiente. El servidor vuelve a calcular y bloquear el
saldo dentro de la transaccion para impedir registros duplicados. El efectivo
se agenda para la llegada y se marca pagado al recibirlo, incluso anticipadamente.

Los pagos resueltos no se editan ni borran desde la aplicacion. Un administrador
puede anular un pago PAGADO con motivo: queda ANULADO y se conservan datos,
comprobante y revision original. Esta operacion anula el registro contable,
no ejecuta un reembolso bancario. La reserva activa queda pendiente si debe
registrarse otro pago. Recepcion puede revisar y cobrar, pero no anular pagos.

### Efectivo recibido antes de la llegada

Aplicar `migrations/013_efectivo_anticipado.sql`. Administradores y recepcionistas
pueden confirmar efectivo recibido en cualquier fecha, incluso antes de la reserva.
Se conserva la confirmacion explicita de recepcion, la fecha real del cobro en
Costa Rica, la cuenta revisora y la proteccion contra cobros duplicados.
Elegir efectivo al reservar no registra dinero recibido: el pago sigue pendiente.

## Eliminacion auditada y comprobantes por pago

Aplicar `migrations/014_eliminacion_auditada_comprobantes.sql` sobre una base
que ya tenga las migraciones de cobros. El instalador completo tambien incluye
la correccion. La migracion restaura `paAuditoriaDetalle` si faltaba.

Eliminar una reserva, incluso con pagos, archiva primero todos sus datos,
pagos, revisiones, anulaciones y archivos en una misma transaccion. Los triggers
conservan los eventos DELETE y la cuenta que realizo la operacion. Si falla
cualquier paso se revierte todo. El archivo se consulta desde el detalle del
evento DELETE de reservas en Auditoria. No ejecuta reembolsos ni altera el
resultado de una revision previa. El archivo no tiene fecha de caducidad.

Desde Reservas, el boton de pagos abre solo los registros de esa reserva.
En Pagos > Ver detalle se puede adjuntar un PDF, PNG o JPG de hasta 5 MB a un
pago pendiente de SINPE Movil o transferencia que aun no tenga archivo.
Se comprueba el contenido en el servidor. No se sustituyen comprobantes ni
se agregan a pagos resueltos. Cada pago muestra si el comprobante fue correcto,
incorrecto, esta pendiente de revision o falta, junto con revisor y motivo.
Las rutas de archivos siguen limitadas a administracion y recepcion.

### Seis ejemplos con archivos distintos y revisiones reales del flujo

Ejecutar desde la raiz, con los datos base DEMO instalados:

```powershell
sqlcmd -S localhost -E -C -I -b -f 65001 -i db/demo/demo_revision_comprobantes.sql
powershell -NoProfile -File db/demo/demo_comprobantes.ps1 -SoloRevision
sqlcmd -S localhost -E -C -I -b -f 65001 -i db/demo/demo_validar_comprobantes.sql
```

`DEMO-COMP-S-P/A/R` y `DEMO-COMP-T-P/A/R` cubren SINPE y transferencia,
cada uno pendiente, aprobado o rechazado. Las referencias y los archivos son
distintos; los rechazados muestran un monto que no coincide. Todos indican
que son ficticios. La validacion usa `paPagoVerificar`, conservando autor,
fecha y motivo. Repetir los comandos no duplica ni recrea ejemplos eliminados.
No se modifican reservas reales.
## Restauracion directa, auditoria externa y perfiles

Aplicar `migrations/015_respaldos_auditados.sql` y
`migrations/016_perfiles_auditoria.sql` con una cuenta administradora de SQL Server.
La aplicacion requiere `RESERVASSCOUTS_MAINTENANCE_PASSWORD` y utiliza
`RESERVASSCOUTS_BACKUP_DIRECTORY` si la carpeta difiere de la predeterminada.
La cuenta de mantenimiento existente conserva sus permisos de backup/dbcreator.

Respaldos permite seleccionar una version y pulsar Restaurar base de datos sin
escribir una frase. La operacion reemplaza los datos actuales por los de la copia.
El servidor exige una copia del catalogo, valida nombre/ruta, encabezado y checksum,
y desconecta las conexiones de la aplicacion antes de recuperar. Consume toda la
respuesta de SQL Server antes de informar el resultado. Las operaciones siguen
limitadas a Administrador; los controles se deshabilitan mientras trabaja.

El catalogo y los eventos BACKUP/RESTORE estan en `master`, en
`reservasScoutsRespaldos` y `reservasScoutsOperaciones`, para sobrevivir a la
restauracion. Conservan archivo, cuenta, IP, fecha, estado y error, sin FK a las
cuentas de la copia recuperada. Auditoria combina estos eventos con los locales.
El registro comienza antes de modificar datos y se finaliza al conocer el resultado.
Las copias antiguas recuperan el esquema de su fecha; aplicar las migraciones que
necesite la version actual de la aplicacion despues de recuperar una copia antigua.
El catalogo y la auditoria externa siguen disponibles independientemente del esquema.

Perfiles obtiene los registros de cuentas Usuario/Miembro mediante los procedimientos
base de usuarios y perfiles; no depende del procedimiento adicional que faltaba en
la instalacion anterior. El trigger registra nombre, identificacion, contacto,
direccion y tipo antes/despues, con la cuenta que realizo cada cambio.

### Prueba de recuperacion sin reemplazar datos actuales

`db/tests/preparar_restore_aislado.sql` prepara un procedimiento temporal exclusivo
para `reservasScouts_restore_test_codex`. Se niega a sobrescribir una base existente.
La prueba `RespaldoSqlServerTest` solo se activa con `RESERVAS_RESTORE_TEST=true`,
genera una copia real y recupera sus datos en esa base temporal. Nunca invoca el
procedimiento que restaura reservasScouts. Limpiar la base temporal y el procedimiento
de prueba al finalizar; las copias verificadas y sus eventos quedan conservados.
## Reserva pendiente de pago y vencimiento (017)

Aplicar `migrations/017_reservas_pendientes_pago.sql`. Efectivo crea una reserva
PENDIENTE y un pago PENDIENTE: conserva el cupo igual que APROBADA. Solo al
registrar el dinero recibido se aprueba la reserva, cuando el total PAGADO
cubre su costo. Se conserva cuenta revisora, fecha y auditoria. Las ediciones
manuales no pueden aprobar una reserva sin pago completo.

La politica se guarda en `reservaPoliticaPago` (fila 1):
- `efectivoGraciaMinutos=120`: llegada mas dos horas, sin superar el fin de la reserva.
- `transferenciaPlazoHoras=24`: plazo para pagos electronicos SIN archivo,
  sin superar la llegada. Los comprobantes enviados suspenden este vencimiento
  hasta la revision del personal. No se libera un espacio por demora de revision.

`pagoVenceEn` expresa hora de Costa Rica. El cliente ve el plazo concreto en
Mis reservas y, para efectivo, al seleccionar el metodo durante la solicitud.
Al vencer SIN pagos recibidos NI comprobante pendiente de revision, reserva
pasa a VENCIDA y sus pagos pendientes a VENCIDO. No se borra el historial ni
se marca un comprobante como incorrecto por vencimiento. Reservas con dinero
parcial recibido requieren atencion del personal y no se vencen automaticamente.

El backend ejecuta `paReservasVencerPendientes` cada minuto. Las consultas de
reservas, disponibilidad, calendario, notificaciones y bloqueos tambien lo
invocan, por lo que un nuevo intento de reserva libera primero los plazos
vencidos. Los bloqueos de reserva/pago serializan vencimiento y confirmacion.
La accion automatica se audita como `Sistema: vencimiento de reservas`.
El proceso es idempotente. La tarjeta sigue siendo una simulacion sin cobro real.

La migracion normaliza reservas activas existentes segun su saldo y metodo.
No reabre canceladas, finalizadas o vencidas, ni elimina archivos o revisiones.
El sistema requiere el backend activo para la ejecucion programada; la
comprobacion al consultar disponibilidad protege tambien tras una interrupcion.

Pruebas: preparar `db/tests/preparar_vencimiento.sql` y activar
`RESERVAS_VENCIMIENTO_TEST=true` junto con las variables de las pruebas SQL.
El helper solo cambia el plazo de codigos `IT-VENCE-%`; las pruebas revierten
todos sus datos. Eliminar el procedimiento de prueba al terminar.