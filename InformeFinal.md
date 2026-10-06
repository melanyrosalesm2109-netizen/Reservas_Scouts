# Reservas Scouts: informe técnico del sistema de reservas

**Autor(es):** [Completar]
**Institución:** [Completar]
**Curso:** [Completar]
**Docente:** [Completar]
**Fecha:** 6 de octubre de 2026

> Borrador técnico con estructura de informe APA 7.ª edición. Complete los datos institucionales de la portada antes de entregar. La aplicación aún no está publicada en un hosting y una restauración controlada en una copia desechable permanece pendiente.

## Resumen

Este informe documenta el sistema Reservas Scouts y las correcciones aplicadas para reforzar su integridad de datos, control de acceso, trazabilidad y operación de respaldos. La aplicación utiliza SQL Server y una capa backend que accede a procedimientos almacenados; la autenticación se mantiene en una sesión del servidor y la interfaz ofrece permisos diferenciados para usuarios y administradores. La validación incluye pruebas automatizadas del backend, lint y compilación de la interfaz, ejecución de la migración SQL sobre la base activa y tres flujos E2E con Playwright. No se declara conformidad completa con requisitos de despliegue en nube: aún no se seleccionaron plataforma, suscripción ni ambiente destino. La restauración válida sobre una copia desechable también requiere una prueba controlada posterior.

**Palabras clave:** reservas, SQL Server, control de acceso, auditoría, respaldo, persistencia.

## Descripción del proyecto

Reservas Scouts es una aplicación web para administrar perfiles de solicitantes, espacios, reservas y pagos. La solución tiene una interfaz React, un backend Spring Boot con endpoints HTTP y una base Microsoft SQL Server llamada `reservasScouts`. Incluye autenticación por sesión, roles de administrador y usuario, consultas resumidas, mantenimiento de reservas, auditoría de cambios y accesos, y administración local de copias de seguridad.

## Justificación

La centralización de reservas en una base relacional reduce la dependencia de registros manuales dispersos y permite aplicar reglas de integridad, consultar disponibilidad y mantener trazabilidad de operaciones. La separación entre roles limita el acceso a información personal y funciones administrativas; los procedimientos almacenados y las copias verificadas mejoran el control operativo. Por tratarse de información de contacto que puede involucrar menores, se requiere restringir el acceso y proteger los datos y respaldos antes de cualquier uso fuera del entorno local.

## Objetivos

### Objetivo general

Desarrollar y documentar un sistema web de reservas Scouts que permita gestionar espacios, solicitantes, reservas y pagos con persistencia relacional y controles de acceso por rol.

### Objetivos específicos

1. Modelar e implementar en SQL Server las entidades del sistema, sus relaciones, restricciones, vistas, funciones, procedimientos almacenados y triggers.
2. Proporcionar una interfaz web conectada al backend para autenticar usuarios y consultar o gestionar las operaciones conforme a su rol.
3. Mantener trazabilidad de accesos y cambios, y ofrecer respaldos verificables con una restauración restringida a administradores.

## Introducción

Reservas Scouts administra perfiles, espacios, reservas y pagos. La revisión del proyecto identificó necesidades de autorización efectiva en el servidor, trazabilidad de operaciones, separación de permisos SQL, operaciones de respaldo y documentación técnica; este informe resume los cambios y evidencia disponible sin afirmar como cumplidos los aspectos que requieren decisiones externas o validación adicional.

## Método de revisión

Se revisaron el instalador y la migración SQL, los repositorios y servicios Java, la configuración del backend y las rutas/interacciones principales del frontend. Se aplicó `db/migrations/001_cumplimiento.sql` a la base local `reservasScouts`, se consultaron metadatos reales del esquema y se ejecutaron Maven tests, ESLint y el build de Vite. El esquema detallado y sus relaciones están en el [diccionario de datos](./db/diccionarioDatos.md) y el [diagrama relacional](./db/diagrama-relacional.md).

## Diseño y persistencia

La aplicación guarda sus datos en SQL Server y actualmente tiene 12 tablas, vistas de lectura y procedimientos almacenados. La capa Java emplea JDBC y `JdbcTemplate`; no usa un ORM ni un sistema de migraciones como Flyway o Liquibase. El script `db/reservasScouts.sql` sirve para la instalación inicial y `db/migrations/001_cumplimiento.sql` actualiza la instalación existente. El backend no configura cifrado de base de datos en reposo. La conexión local confía en el certificado presentado por SQL Server, por lo que esa configuración debe reemplazarse por validación de certificados en un ambiente productivo.

La documentación de arquitectura describe configuración, propiedad de tablas, repositorios, caché y clasificación de datos en [data-architecture.md](./.github/modernize/assessment/engines/facts/data-architecture.md). La base distingue usuarios, roles y permisos; perfiles; espacios; reservas y pagos; actividad y auditoría; y metadatos de respaldos.

El inventario técnico del [diccionario de datos](./db/diccionarioDatos.md) documenta los objetos SQL: tres vistas (`vReservasResumen`, `vPerfilesConfidencial`, `vAuditoriaResumen`), siete funciones de validación, enmascaramiento y consulta, 33 procedimientos de autenticación, operaciones de las entidades, auditoría y respaldos, y cinco triggers de auditoría. El [script de instalación](./db/reservasScouts.sql) contiene la definición del esquema; la migración mantiene las instalaciones existentes actualizadas.

## Seguridad, autorización y privacidad

La autenticación usa una sesión server-side con cookie `HttpOnly`, `SameSite=Strict` y vencimiento por inactividad. El backend valida el rol por solicitud; el frontend oculta controles administrativos, pero la seguridad no depende de esa presentación visual. Los usuarios regulares pueden consultar resúmenes y crear reservas; la lectura detallada, modificaciones administrativas, gestión de usuarios, pagos, auditoría y respaldos están reservados al rol administrador. El identificador del usuario que crea una reserva se toma de la sesión autenticada.

La migración instala triggers de auditoría para cambios en espacios, perfiles, usuarios, reservas y pagos, y registra por separado accesos, intentos fallidos, cierre de sesión y operaciones de respaldo. La aplicación SQL `reservas_app` ejecuta procedimientos almacenados en vez de recibir acceso directo a las tablas. `reservas_consulta` es un usuario de base sin login que solo tiene lectura sobre vistas informativas. El login de mantenimiento para restauración requiere `dbcreator`, un rol de instancia con capacidad para crear, restaurar y eliminar bases de datos; se limita a la instalación local y no debe trasladarse a una instancia compartida o productiva.

Los perfiles y las reservas contienen datos personales de contacto, y la información puede involucrar menores. La vista confidencial enmascara teléfono y correo del perfil, pero no todos los campos personales. Las contraseñas se guardan como hash BCrypt. No se detectaron campos de número o código de seguridad de tarjeta, por lo que el esquema no almacena datos PCI evidentes; sí conserva información financiera y referencias de comprobantes. Los archivos `.bak` contienen el conjunto completo de datos y no se configuró cifrado de respaldo en reposo. Antes de operar fuera del entorno local se requiere definir cifrado, retención, protección del almacenamiento de respaldos y controles de acceso de producción.

## Auditoría y continuidad

`auditoriaReservas` conserva cambios hechos en entidades relevantes y `auditoriaAccesos` registra eventos de autenticación y mantenimiento. La vista `vAuditoriaResumen` agrupa eventos para consulta administrativa. `respaldoHistorial` registra nombre, fecha, usuario y tamaño del respaldo; el catálogo no sustituye al archivo `.bak`.

La aplicación genera respaldos completos con checksum, ejecuta `RESTORE VERIFYONLY` y valida nombre, encabezado y tipo antes de restaurar únicamente `reservasScouts` (Microsoft, s. f.-a, s. f.-b). La restauración exige una confirmación literal y queda restringida a administradores. SQL Server debe tener permisos de escritura en la carpeta local de respaldos. La restauración real sobre la base activa no se ejecutó durante esta validación para evitar reemplazar datos existentes sin autorización explícita; el flujo requiere una prueba controlada posterior en una copia desechable. El requisito de `dbcreator` y su alcance corresponden a un rol de servidor de SQL Server (Microsoft, s. f.-c), de modo que debe mantenerse fuera de instancias compartidas.

## Verificación y resultados

| Validación | Resultado | Evidencia / alcance |
|---|---|---|
| Pruebas backend | Aprobado | `mvn test -q`: 8 pruebas, 0 fallos, 0 errores, 0 omitidas. |
| Lint frontend | Aprobado | `npm run lint`, exit code 0. |
| Build frontend | Aprobado | `npm run build`, exit code 0; Vite generó los artefactos de producción. |
| Arranque y rechazo anónimo | Aprobado | Backend iniciado en `localhost:8080`; `GET /api/usuarios/sesion` sin sesión devolvió HTTP 401. |
| Migración SQL | Aprobado | `001_cumplimiento.sql` se aplicó y volvió a ejecutar sobre `reservasScouts`; la consulta posterior confirmó la pertenencia de mantenimiento a `db_backupoperator` y que el login legado `reservasApp` ya no tiene membresías de roles de base de datos. |
| Instalación SQL desde cero | Aprobado previamente | El instalador completo se ejecutó sobre una base temporal de validación y esa base de prueba fue eliminada después. |
| Smoke test manual de navegador | Aprobado | Login de administrador, página de auditoría, página de respaldos, creación/verificación de una copia y aparición de sus metadatos y evento `BACKUP` en la interfaz. El botón de restauración no se habilita con una confirmación incorrecta. |
| Acceso directo al archivo `.bak` desde la sesión Windows | Restringido por ACL | La cuenta de Windows usada para la validación recibió `Access denied` al listar la carpeta protegida; la operación de respaldo y `RESTORE VERIFYONLY` se realizaron por SQL Server y fueron exitosos. No se intentó cambiar ACLs. |
| Playwright / E2E automatizado | Aprobado | `npm run test:e2e`: 3 flujos aprobados, 0 fallos; autenticación, persistencia de auditoría/catálogo de respaldos y creación/lectura de una reserva con controles de rol. |
| Restauración válida de base | Pendiente | Requiere prueba controlada contra una base temporal o una copia desechable; no reemplazar la base activa sin autorización explícita. |
| Hosting | Pendiente | La app se ejecutó localmente (`localhost`); no se publicó en un hosting o servicio accesible externamente. |

El Docker daemon no respondió en esta máquina, por lo que no se usaron contenedores. La suite Playwright sí se ejecutó contra la aplicación local y el SQL Server instalado, sin sustituir la infraestructura por una base en memoria.

## Requisitos pendientes y evaluación

La guía distribuye la evaluación en 15 puntos de documento escrito y 25 de implementación práctica. La matriz indica evidencia observada, no una calificación asignada:

| Criterio de la guía | Puntos posibles | Estado de la evidencia |
|---|---:|---|
| Descripción del proyecto | 1 | Documentada en este informe. |
| Justificación | 1 | Documentada en este informe. |
| Objetivos | 3 | Objetivos general y específicos documentados. |
| Documentación de procedimientos, vistas, triggers y funciones | 3 | Inventario y propósito documentados en el diccionario de datos; objetos contrastados con SQL Server. |
| Script completo de la base de datos | 4 | Instalador inicial `db/reservasScouts.sql` y migración para instalaciones existentes. |
| Diagrama relacional | 1 | Documentado en `db/diagrama-relacional.md`. |
| Diccionario de datos | 2 | Documentado en `db/diccionarioDatos.md`. |
| Diseño de interfaces de usuario | 3 | Interfaz React y páginas de gestión implementadas; no se asigna calificación de diseño. |
| Funcionamiento del sistema | 4 | Backend, frontend y base local operativos; 3 flujos E2E aprobados. |
| Manejo de errores | 2 | Manejo centralizado en el backend y mensajes en la interfaz; validado parcialmente por pruebas. |
| Implementado en hosting | 2 | Pendiente: solo se verificó ejecución local; no hay hosting publicado. |
| Manejo de usuarios del sistema de bases de datos | 1 | Usuarios de aplicación/consulta/mantenimiento y permisos separados; configuración local documentada. |
| Uso de procedimientos almacenados | 3 | Backend usa procedimientos; 33 procedimientos existen en el esquema activo. |
| Uso de vistas (al menos 3) | 2 | Cumple el mínimo: 3 vistas verificadas en el esquema activo. |
| Triggers (al menos 3) | 3 | Cumple el mínimo: 5 triggers de auditoría verificados en el esquema activo. |
| Respaldo de la base de datos | 2 | Creación y verificación del respaldo probadas; restauración en copia desechable pendiente. |
| Manejo de auditoría en la base de datos | 3 | Tablas, vista, triggers y eventos de acceso implementados; flujo E2E aprobado. |

| Área | Estado | Trabajo pendiente |
|---|---|---|
| Integridad y acceso a datos | Implementado y validado parcialmente | Mantener los scripts de instalación/migración sincronizados y revisar permisos de SQL Server tras cambios de esquema. |
| Sesiones y autorización | Implementado y validado | Los flujos E2E cubren login válido/inválido, persistencia de sesión y rechazo de acceso fuera del rol. |
| Auditoría | Implementada; esquema migrado | Acordar retención, revisión periódica y protección contra alteración de los registros. |
| Respaldo | Flujo implementado; esquema migrado | Probar creación y restauración en una base temporal, medir recuperación y documentar retención/cifrado. |
| Informe y modelo de datos | Documentados | Completar portada APA con autoría, institución, curso y docente; validar requisitos formales de la rúbrica original. |
| Hosting / despliegue en nube | Pendiente | Elegir proveedor o servicio de hosting y configurar el ambiente; no se provisionaron recursos ni se publicó la aplicación. |
| Seguridad de producción | Parcial | Sustituir credenciales locales, validar certificados, evaluar cifrado en reposo, proteger respaldos y limitar el privilegio de restauración. |

La guía asigna 40 puntos: 15 al documento escrito y 25 a la implementación práctica. Hay evidencia de los artefactos escritos de descripción, justificación y objetivos; del instalador SQL, modelo relacional y diccionario; y de la implementación de interfaz, procedimientos, al menos tres vistas, al menos tres triggers, respaldo y auditoría. Las validaciones ejecutadas apoyan la funcionalidad principal y los controles de error/autorización. Sin embargo, no se declara una puntuación ni cumplimiento total: el hosting solicitado por la guía no se completó, la restauración válida no se probó en una copia desechable y quedan datos institucionales por completar en la portada.

Por tanto, el proyecto muestra mejoras verificables en persistencia, autorización, auditoría, respaldos locales y flujos E2E, pero todavía no satisface todos los elementos de la guía mientras permanezcan pendientes el hosting y la prueba controlada de restauración.

## Conclusiones

La aplicación cuenta ahora con controles server-side de sesión y rol, procedimientos SQL para acceso de la aplicación, registros de auditoría y un flujo de respaldo/restauración con verificaciones previas. Los tests backend, lint, build y tres flujos de navegador pasan, y la migración se aplicó a la base local. Para cerrar la evaluación según la guía faltan publicar el proyecto en un hosting, realizar una restauración controlada en una copia desechable y completar los datos institucionales de la portada.

## Referencias

Microsoft. (s. f.-a). *BACKUP (Transact-SQL).* Microsoft Learn. https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql?view=sql-server-ver17

Microsoft. (s. f.-b). *RESTORE (Transact-SQL).* Microsoft Learn. https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql?view=sql-server-ver17

Microsoft. (s. f.-c). *Server-level roles.* Microsoft Learn. https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/server-level-roles?view=sql-server-ver17

Microsoft. (s. f.-d). *Permissions (Database Engine).* Microsoft Learn. https://learn.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine?view=sql-server-ver17
