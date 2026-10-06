# Diccionario de datos - `reservasScouts`

Inventario basado en los metadatos de la base activa `reservasScouts` y contrastado con `db/reservasScouts.sql`. Los nombres de objetos y columnas conservan el formato camelCase definido por el esquema. `NULL` indica que la columna admite valor nulo; `NO` indica que es obligatoria. `IDENTITY` identifica columnas autoincrementales.

## Tablas y columnas

### `dbo.actividad`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `id` | `int` | NO | PK, IDENTITY | Identificador del evento de actividad. |
| `usuarioId` | `int` | Sí | FK -> `usuarios.id` | Usuario relacionado, si se conoce. |
| `modulo` | `nvarchar(80)` | NO | - | Módulo de la aplicación. |
| `accion` | `nvarchar(120)` | NO | - | Acción registrada. |
| `descripcion` | `nvarchar(255)` | Sí | - | Detalle textual de la actividad. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha y hora del registro. |

### `dbo.auditoriaAccesos`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `idAuditoriaAcceso` | `bigint` | NO | PK, IDENTITY | Identificador del evento de acceso. |
| `usuarioId` | `int` | Sí | Sin FK declarada | Usuario identificado; puede ser NULL en un intento de inicio fallido. |
| `evento` | `nvarchar(20)` | NO | CHECK `LOGIN`, `LOGIN_FALLIDO`, `LOGOUT`, `BACKUP`, `RESTORE` | Tipo de evento registrado. |
| `direccionIp` | `varchar(45)` | Sí | - | Dirección de origen IPv4 o IPv6. |
| `agenteUsuario` | `nvarchar(300)` | Sí | - | Agente de usuario enviado por el cliente. |
| `creadoEn` | `datetime2(0)` | NO | - | Fecha y hora suministrada por el procedimiento de auditoría. |

### `dbo.auditoriaReservas`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `idAuditoria` | `bigint` | NO | PK, IDENTITY | Identificador del registro de auditoría. |
| `tabla` | `nvarchar(40)` | NO | CHECK: tablas auditadas | Tabla afectada por el cambio. |
| `idRegistro` | `int` | NO | - | Identificador de la fila afectada. |
| `accion` | `nvarchar(10)` | NO | CHECK `INSERT`, `UPDATE`, `DELETE` | Operación detectada por el trigger. |
| `detalle` | `nvarchar(max)` | Sí | - | Detalle del cambio registrado. |
| `usuarioAppId` | `int` | Sí | FK -> `usuarios.id` | Usuario de la aplicación asociado al cambio, si está disponible. |
| `usuarioAppNombre` | `nvarchar(160)` | Sí | - | Nombre registrado para identificar al actor. |
| `usuarioBd` | `nvarchar(120)` | NO | - | Principal SQL que realizó la operación. |
| `creadoEn` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha y hora del evento. |

### `dbo.espacios`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `id` | `int` | NO | PK, IDENTITY | Identificador del espacio. |
| `nombre` | `nvarchar(120)` | NO | - | Nombre del espacio. |
| `descripcion` | `nvarchar(max)` | Sí | - | Descripción del espacio. |
| `ubicacion` | `nvarchar(160)` | NO | - | Ubicación física. |
| `capacidad` | `int` | NO | CHECK `> 0` | Capacidad máxima admitida por el registro. |
| `costo` | `decimal(12,2)` | NO | `0.00`, CHECK `>= 0` | Costo asociado al espacio. |
| `estado` | `nvarchar(20)` | NO | `DISPONIBLE`, CHECK `DISPONIBLE`, `MANTENIMIENTO`, `INACTIVO` | Estado operativo. |
| `imagen` | `nvarchar(255)` | Sí | - | Referencia o ruta de imagen. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de creación. |
| `updatedAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de última actualización. |

### `dbo.pagos`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `id` | `int` | NO | PK, IDENTITY | Identificador del pago. |
| `reservaId` | `int` | NO | FK -> `reservas.id` | Reserva a la que corresponde. |
| `monto` | `decimal(12,2)` | NO | CHECK `>= 0` | Importe registrado. |
| `metodo` | `nvarchar(30)` | NO | CHECK: `Tarjeta`, `Efectivo`, `Transferencia bancaria`, `SINPE Móvil` | Medio de pago reportado. |
| `fechaPago` | `date` | NO | - | Fecha del pago. |
| `estado` | `nvarchar(15)` | NO | `PENDIENTE`, CHECK `PENDIENTE`, `PAGADO`, `RECHAZADO` | Estado del pago. |
| `comprobante` | `nvarchar(255)` | Sí | - | Referencia del comprobante; no contiene un campo de tarjeta en el esquema. |
| `notas` | `nvarchar(max)` | Sí | - | Notas asociadas. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de creación. |
| `updatedAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de última actualización. |

### `dbo.perfilesUsuario`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `idPerfil` | `int` | NO | PK, IDENTITY | Identificador del perfil. |
| `usuarioId` | `int` | Sí | FK -> `usuarios.id`; único cuando no es NULL | Cuenta asociada, si existe. |
| `nombre` | `nvarchar(160)` | NO | - | Nombre de persona, grupo o institución. |
| `identificacion` | `nvarchar(30)` | Sí | Único filtrado cuando no es NULL | Identificación del perfil. |
| `telefono` | `nvarchar(30)` | Sí | - | Teléfono de contacto. |
| `correoContacto` | `nvarchar(160)` | NO | CHECK `fnCorreoValido` | Correo de contacto. |
| `tipoPerfil` | `nvarchar(20)` | NO | `Persona`, CHECK `Persona`, `Grupo Scout`, `Institucion` | Tipo de perfil. |
| `direccion` | `nvarchar(255)` | Sí | - | Dirección de contacto. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de creación. |
| `updatedAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de última actualización. |

### `dbo.permisos`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `id` | `int` | NO | PK, IDENTITY | Identificador del permiso. |
| `clave` | `nvarchar(80)` | NO | Único | Clave del permiso. |
| `descripcion` | `nvarchar(180)` | NO | - | Descripción del permiso. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de creación. |

### `dbo.reservas`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `id` | `int` | NO | PK, IDENTITY | Identificador de la reserva. |
| `codigo` | `nvarchar(20)` | NO | Único | Código de reserva. |
| `espacioId` | `int` | NO | FK -> `espacios.id` | Espacio solicitado. |
| `solicitantePerfilId` | `int` | NO | FK -> `perfilesUsuario.idPerfil` | Perfil solicitante. |
| `creadoPorUsuarioId` | `int` | Sí | FK -> `usuarios.id` | Cuenta que creó la reserva, si aplica. |
| `grupo` | `nvarchar(160)` | Sí | - | Grupo relacionado con la solicitud. |
| `responsable` | `nvarchar(160)` | NO | - | Persona responsable de contacto. |
| `telefono` | `nvarchar(30)` | NO | - | Teléfono de contacto. |
| `email` | `nvarchar(160)` | NO | CHECK `fnCorreoValido` | Correo de contacto. |
| `participantes` | `int` | NO | CHECK `> 0` | Cantidad de participantes. |
| `tipoActividad` | `nvarchar(120)` | NO | - | Tipo de actividad declarada. |
| `fechaInicio` | `datetime2(0)` | NO | - | Inicio solicitado. |
| `fechaFin` | `datetime2(0)` | NO | CHECK `> fechaInicio` | Final solicitado. |
| `estado` | `nvarchar(20)` | NO | `PENDIENTE`, CHECK `PENDIENTE`, `APROBADA`, `CANCELADA`, `FINALIZADA` | Estado de la reserva. |
| `observaciones` | `nvarchar(max)` | Sí | - | Observaciones. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de creación. |
| `updatedAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de última actualización. |

### `dbo.respaldoHistorial`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `idRespaldo` | `bigint` | NO | PK, IDENTITY | Identificador del registro del catálogo. |
| `nombreArchivo` | `nvarchar(120)` | NO | Único | Nombre del archivo de respaldo creado por la aplicación. |
| `creadoPorUsuarioId` | `int` | Sí | FK -> `usuarios.id` | Usuario que solicitó la copia. |
| `creadoEn` | `datetime2(0)` | NO | - | Fecha de finalización informada por SQL Server. |
| `bytes` | `bigint` | NO | CHECK `>= 0` | Tamaño informado para la copia. |

### `dbo.roles`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `id` | `int` | NO | PK, IDENTITY | Identificador del rol. |
| `nombre` | `nvarchar(50)` | NO | Único | Nombre del rol. |
| `descripcion` | `nvarchar(180)` | Sí | - | Descripción del rol. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de creación. |

### `dbo.rolPermisos`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `rolId` | `int` | NO | PK compuesta; FK -> `roles.id` | Rol de la asignación. |
| `permisoId` | `int` | NO | PK compuesta; FK -> `permisos.id` | Permiso de la asignación. |

### `dbo.usuarios`

| Columna | Tipo SQL | Nulo | Clave / valor predeterminado | Descripción |
|---|---|---:|---|---|
| `id` | `int` | NO | PK, IDENTITY | Identificador de la cuenta. |
| `rolId` | `int` | NO | FK -> `roles.id` | Rol asignado. |
| `email` | `nvarchar(160)` | NO | Único; CHECK `fnCorreoValido` | Correo de inicio de sesión. |
| `passwordHash` | `nvarchar(255)` | NO | - | Hash de contraseña; no almacenar texto claro. |
| `estado` | `nvarchar(10)` | NO | `ACTIVO`, CHECK `ACTIVO`, `INACTIVO` | Estado de la cuenta. |
| `createdAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de creación. |
| `updatedAt` | `datetime2(0)` | NO | `SYSDATETIME()` | Fecha de última actualización. |

## Relaciones y restricciones

| Tabla origen | Columna(s) | Tabla destino | Columna(s) destino | Cardinalidad / restricción |
|---|---|---|---|---|
| `usuarios` | `rolId` | `roles` | `id` | Cada usuario tiene un rol; un rol puede estar asignado a muchos usuarios. |
| `perfilesUsuario` | `usuarioId` | `usuarios` | `id` | Relación opcional; el índice único filtrado permite como máximo un perfil por usuario cuando se asigna. |
| `reservas` | `espacioId` | `espacios` | `id` | Cada reserva referencia un espacio. |
| `reservas` | `solicitantePerfilId` | `perfilesUsuario` | `idPerfil` | Cada reserva referencia un perfil solicitante. |
| `reservas` | `creadoPorUsuarioId` | `usuarios` | `id` | Creador opcional asociado a la reserva. |
| `pagos` | `reservaId` | `reservas` | `id` | Cada pago referencia una reserva. |
| `actividad` | `usuarioId` | `usuarios` | `id` | Usuario opcional asociado a la actividad. |
| `auditoriaReservas` | `usuarioAppId` | `usuarios` | `id` | Usuario opcional asociado al cambio auditado. |
| `respaldoHistorial` | `creadoPorUsuarioId` | `usuarios` | `id` | Usuario opcional que solicitó el respaldo. |
| `rolPermisos` | `rolId` | `roles` | `id` | Parte de la clave primaria compuesta. |
| `rolPermisos` | `permisoId` | `permisos` | `id` | Parte de la clave primaria compuesta. |

`auditoriaAccesos.usuarioId` no tiene una clave foránea declarada; el evento se conserva aunque la cuenta asociada deje de existir. También se aplican claves únicas a `usuarios.email`, `reservas.codigo`, `respaldoHistorial.nombreArchivo`, `roles.nombre` y `permisos.clave`; `perfilesUsuario.identificacion` y `perfilesUsuario.usuarioId` usan índices únicos filtrados para valores no nulos. Las restricciones CHECK adicionales y los tipos permitidos se enumeran en las tablas anteriores.

## Vistas, funciones y procedimientos relacionados

El esquema activo verificado contiene 3 vistas, 7 funciones, 33 procedimientos almacenados y 5 triggers de tabla.

| Tipo | Objeto | Propósito |
|---|---|---|
| Vista | `vReservasResumen` | Presenta datos resumidos de reservas para consultas autorizadas. |
| Vista | `vPerfilesConfidencial` | Limita y enmascara datos de contacto del perfil para consultas permitidas. |
| Vista | `vAuditoriaResumen` | Agrupa eventos de auditoría por origen y tipo de evento. |
| Función | `fnCorreoValido` | Valida el formato de una dirección de correo. |
| Funciones | `fnMascararCorreo`, `fnMascararTelefono` | Enmascaran datos de contacto para exposición limitada. |
| Funciones | `fnPagosPorReserva`, `fnResumenPagosReserva` | Consultan o resumen los pagos asociados a una reserva. |
| Funciones | `fnReservasPorEspacio`, `fnReservasPorEstado` | Consultan reservas por espacio o estado. |
| Procedimientos | `paUsuarioLogin`, `paUsuarioInsertar`, `paUsuarioBuscarPorId`, `paUsuarioFiltrar`, `paUsuarioActualizar`, `paUsuarioEliminar` | Autenticación y mantenimiento de usuarios mediante operaciones parametrizadas. |
| Procedimiento | `paRolFiltrar` | Lista y filtra los roles del sistema. |
| Procedimientos | `paPerfilInsertar`, `paPerfilBuscarPorId`, `paPerfilFiltrar`, `paPerfilActualizar`, `paPerfilEliminar`, `paPerfilOpcionesReserva` | Mantienen perfiles y exponen las opciones mínimas requeridas para una reserva. |
| Procedimientos | `paEspacioInsertar`, `paEspacioBuscarPorId`, `paEspacioFiltrar`, `paEspacioActualizar`, `paEspacioEliminar` | Mantienen y consultan los espacios disponibles. |
| Procedimientos | `paReservaInsertar`, `paReservaBuscarPorId`, `paReservaFiltrar`, `paReservaActualizar`, `paReservaEliminar` | Registran y gestionan reservas con validaciones de negocio. |
| Procedimientos | `paPagoInsertar`, `paPagoBuscarPorId`, `paPagoFiltrar`, `paPagoActualizar`, `paPagoEliminar` | Registran y gestionan pagos asociados a reservas. |
| Procedimientos | `paAuditoriaAccesoRegistrar`, `paAuditoriaResumen` | Registran eventos de acceso y exponen su resumen. |
| Procedimientos | `paRespaldoListar`, `paRespaldoRegistrar` | Consultan y registran los metadatos del catálogo de respaldos. |
| Procedimiento | `paSistemaEstado` | Proporciona el estado usado por la prueba de conexión del backend. |
| Trigger | `trgEspaciosAuditoria` | Registra inserciones, cambios y eliminaciones de espacios. |
| Trigger | `trgPerfilesUsuarioAuditoria` | Registra inserciones, cambios y eliminaciones de perfiles. |
| Trigger | `trgUsuariosAuditoria` | Registra inserciones, cambios y eliminaciones de usuarios. |
| Trigger | `trgReservasAuditoria` | Registra inserciones, cambios y eliminaciones de reservas. |
| Trigger | `trgPagosAuditoria` | Registra inserciones, cambios y eliminaciones de pagos. |

Los nombres y cantidades corresponden al esquema SQL Server 2025 verificado; si se actualiza el esquema, volver a consultar los scripts de instalación/migración y sincronizar este inventario.
