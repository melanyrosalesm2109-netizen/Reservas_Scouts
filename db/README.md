# Base de datos

El archivo `reservasScouts.sql` crea la base de datos, tablas, vistas, funciones
y procedimientos almacenados que utiliza el backend.

## Requisitos y ejecución

- Microsoft SQL Server 2025 (compatibilidad 170).
- Crear previamente en la instancia un login de autenticación SQL llamado
  `reservas_app` y configurar su contraseña en `backend/src/main/resources/application.properties`.
- Ejecutar el script una sola vez como instalación inicial, en SQL Server
  Management Studio conectado a la instancia con permisos para crear bases de
  datos y usuarios. No volver a ejecutarlo sobre una base existente: no es un
  script de migración ni de actualización de datos.

El script crea la base `reservasScouts`, que coincide con el nombre configurado
en la URL JDBC del backend. El usuario `reservas_app` recibe únicamente permiso
para ejecutar procedimientos almacenados; las lecturas y escrituras se realizan
por medio de esos procedimientos.

La base incluye procedimientos CRUD para los recursos del backend, vistas de
reservas y perfiles, y funciones para validación y enmascaramiento. Los triggers
de auditoría registran inserciones, actualizaciones y eliminaciones de espacios,
perfiles, usuarios, reservas y pagos en `dbo.auditoriaReservas`. El detalle evita
guardar hashes de contraseñas, correos, teléfonos e información de contacto.
`dbo.paSistemaEstado` proporciona el estado usado por el endpoint de prueba de
conexión, sin requerir permisos directos de lectura sobre las tablas.
