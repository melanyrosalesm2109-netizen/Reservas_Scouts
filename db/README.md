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

Antes de aplicar cambios, crear y verificar un respaldo. Ejecutar en orden
`migrations/001_cumplimiento.sql` y `migrations/002_roles_y_permisos.sql` sobre
`reservasScouts`; ambas son repetibles. La primera agrega o verifica el rol
`Usuario`, la vista `vAuditoriaResumen`, las tablas
`auditoriaAccesos` y `respaldoHistorial`, y los procedimientos de auditoría,
catálogo de respaldos y opciones de perfil. También instala cinco triggers que
registran cambios de espacios, perfiles, usuarios, reservas y pagos, y elimina
las membresías heredadas de lectura y escritura amplia del login `reservasApp`.
Los triggers no guardan credenciales ni datos de contacto; los intentos de
acceso, cierres de sesión y operaciones de respaldo se registran separadamente.

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
`respaldoHistorial` conserva metadatos y SQL Server verifica el archivo y su
encabezado durante la restauración. Puede configurarse otra carpeta con
`RESERVASSCOUTS_BACKUP_DIRECTORY`, coordinando los permisos del servicio SQL Server.

La aplicación crea copias completas con checksum y ejecuta `RESTORE VERIFYONLY`
antes de ofrecerlas para restauración. Solo acepta archivos generados por esta
aplicación (`reservasScouts_*.bak`) cuyo encabezado identifica la base
`reservasScouts`. La restauración solo está disponible para administradores y
exige escribir exactamente `RESTAURAR reservasScouts`.

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
