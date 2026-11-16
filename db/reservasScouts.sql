/* =========================================================
   SISTEMA DE RESERVAS SCOUTS
   Script principal de creación de base de datos

   Contenido:
   1. Creación y configuración básica de la base.
   2. Usuarios del motor de SQL Server y permisos.
   3. Funciones.
   4. Tablas, vistas e índices.
   5. Restricciones, valores por defecto y relaciones.
   6. Procedimientos almacenados.
   7. Triggers de auditoría.
   8. Datos iniciales para pruebas.
   9. Restauración de la base de datos.

   Nota:
   Las rutas físicas se definen mediante variables SQLCMD.
   Ejecutar este archivo con SQLCMD Mode habilitado en SSMS.
   ========================================================= */


/* =========================================================
   1. CREACIÓN DE LA BASE DE DATOS
   ========================================================= */

USE [master];
GO

:setvar DataFilePath "C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\reservasScouts.mdf"
:setvar LogFilePath "C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\reservasScouts_log.ldf"

CREATE DATABASE [reservasScouts]
ON PRIMARY
(
    NAME = N'reservasScouts',
    FILENAME = N'$(DataFilePath)',
    SIZE = 64MB,
    MAXSIZE = 2048MB,
    FILEGROWTH = 64MB
)
LOG ON
(
    NAME = N'reservasScouts_log',
    FILENAME = N'$(LogFilePath)',
    SIZE = 32MB,
    MAXSIZE = 1024MB,
    FILEGROWTH = 32MB
);
GO

/* Se utiliza recuperación SIMPLE porque el proyecto trabaja
   con respaldos completos gestionados desde la aplicación. */
ALTER DATABASE [reservasScouts]
SET RECOVERY SIMPLE;
GO

/* CHECKSUM permite detectar daños en páginas de datos. */
ALTER DATABASE [reservasScouts]
SET PAGE_VERIFY CHECKSUM;
GO

/* La aplicación requiere conexiones concurrentes. */
ALTER DATABASE [reservasScouts]
SET MULTI_USER;
GO

USE [reservasScouts];
GO

/* Configuración requerida para funciones, vistas y procedimientos. */
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO


/* =========================================================
   2. USUARIOS DEL MOTOR DE BASE DE DATOS
   =========================================================
   Se crean logins reales de SQL Server con funciones distintas:

   reservas_app:
       Usuario principal utilizado por la aplicación.

   reservas_consulta:
       Usuario con privilegios restringidos de consulta.

   reservas_maintenance:
       Usuario utilizado para las operaciones de respaldo
       y restauración de la base de datos.
   ========================================================= */

USE [master];
GO

IF SUSER_ID(N'reservas_app') IS NULL
BEGIN
    CREATE LOGIN [reservas_app]
    WITH PASSWORD = N'ReservaApp2026!',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

IF SUSER_ID(N'reservas_consulta') IS NULL
BEGIN
    CREATE LOGIN [reservas_consulta]
    WITH PASSWORD = N'ReservaConsulta2026!',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO
IF SUSER_ID(N'reservas_maintenance') IS NULL
BEGIN
    CREATE LOGIN [reservas_maintenance]
    WITH PASSWORD = N'ReservaMaintenance2026!',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

IF IS_SRVROLEMEMBER(N'dbcreator', N'reservas_maintenance') <> 1
BEGIN
    ALTER SERVER ROLE [dbcreator]
    ADD MEMBER [reservas_maintenance];
END;
GO

USE [reservasScouts];
GO

IF DATABASE_PRINCIPAL_ID(N'reservas_app') IS NULL
BEGIN
    CREATE USER [reservas_app]
    FOR LOGIN [reservas_app]
    WITH DEFAULT_SCHEMA = [dbo];
END;
GO

GRANT CONNECT TO [reservas_app];
GRANT EXECUTE ON SCHEMA::[dbo] TO [reservas_app];
GO

IF DATABASE_PRINCIPAL_ID(N'reservas_consulta') IS NULL
BEGIN
    CREATE USER [reservas_consulta]
    FOR LOGIN [reservas_consulta]
    WITH DEFAULT_SCHEMA = [dbo];
END;
GO

GRANT CONNECT TO [reservas_consulta];
GO
/* FUNCIÓN: fnCorreoValido */
/* =========================================================
   3. FUNCIONES
   ========================================================= */

CREATE FUNCTION [dbo].[fnCorreoValido]
(
    @correo NVARCHAR(160)
)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @arroba INT;
    DECLARE @local NVARCHAR(160);
    DECLARE @dominio NVARCHAR(160);
    DECLARE @ultimoPunto INT;

    IF @correo IS NULL OR LEN(@correo) = 0 OR LEN(@correo) > 160
        RETURN 0;

    SET @arroba = CHARINDEX(N'@', @correo);

    IF @arroba <= 1
        RETURN 0;

    IF CHARINDEX(N'@', @correo, @arroba + 1) > 0
        RETURN 0;

    IF PATINDEX(N'%[^A-Za-z0-9._%+@-]%', @correo COLLATE Latin1_General_100_BIN2) > 0
        RETURN 0;

    SET @local = LEFT(@correo, @arroba - 1);
    SET @dominio = SUBSTRING(@correo, @arroba + 1, LEN(@correo));

    IF LEN(@local) = 0 OR LEN(@dominio) = 0
        RETURN 0;

    IF LEFT(@local, 1) = N'.' OR RIGHT(@local, 1) = N'.' OR CHARINDEX(N'..', @local) > 0
        RETURN 0;

    IF LEFT(@dominio, 1) = N'.' OR RIGHT(@dominio, 1) = N'.' OR CHARINDEX(N'..', @dominio) > 0
        RETURN 0;

    IF CHARINDEX(N'.', @dominio) = 0
        RETURN 0;

    SET @ultimoPunto = LEN(@dominio) - CHARINDEX(N'.', REVERSE(@dominio)) + 1;

    IF LEN(@dominio) - @ultimoPunto < 2
        RETURN 0;

    RETURN 1;
END;

GO
/* FUNCIÓN: fnMascararCorreo */
CREATE FUNCTION [dbo].[fnMascararCorreo]
(
    @correo NVARCHAR(160)
)
RETURNS NVARCHAR(160)
WITH SCHEMABINDING
AS
BEGIN
    IF dbo.fnCorreoValido(@correo) = 0
        RETURN NULL;

    RETURN CONCAT(
        LEFT(@correo, 2),
        N'***',
        SUBSTRING(@correo, CHARINDEX(N'@', @correo), LEN(@correo))
    );
END;

GO
/* FUNCIÓN: fnMascararTelefono */
CREATE FUNCTION [dbo].[fnMascararTelefono]
(
    @telefono NVARCHAR(30)
)
RETURNS NVARCHAR(30)
WITH SCHEMABINDING
AS
BEGIN
    IF @telefono IS NULL OR LEN(@telefono) <= 4
        RETURN N'****';

    RETURN CONCAT(
        REPLICATE(N'*', LEN(@telefono) - 4),
        RIGHT(@telefono, 4)
    );
END;

GO
/* TABLA: perfilesUsuario */
/* =========================================================
   4. TABLAS, VISTAS E ÍNDICES
   ========================================================= */

CREATE TABLE [dbo].[perfilesUsuario](
	[idPerfil] [int] IDENTITY(1,1) NOT NULL,
	[usuarioId] [int] NULL,
	[nombre] [nvarchar](160) NOT NULL,
	[identificacion] [nvarchar](30) NULL,
	[telefono] [nvarchar](30) NULL,
	[correoContacto] [nvarchar](160) NOT NULL,
	[tipoPerfil] [nvarchar](20) NOT NULL,
	[direccion] [nvarchar](255) NULL,
	[createdAt] [datetime2](0) NOT NULL,
	[updatedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkPerfilesUsuario] PRIMARY KEY CLUSTERED 
(
	[idPerfil] ASC
)
) ON [PRIMARY]
GO
/* VISTA: vPerfilesConfidencial */
CREATE VIEW [dbo].[vPerfilesConfidencial]
AS
SELECT
    p.idPerfil,
    p.usuarioId,
    p.nombre,
    p.identificacion,
    dbo.fnMascararTelefono(p.telefono) AS telefono,
    dbo.fnMascararCorreo(p.correoContacto) AS correoContacto,
    p.tipoPerfil,
    p.direccion,
    p.createdAt,
    p.updatedAt
FROM dbo.perfilesUsuario AS p;

GO
/* TABLA: usuarios */
CREATE TABLE [dbo].[usuarios](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[rolId] [int] NOT NULL,
	[email] [nvarchar](160) NOT NULL,
	[passwordHash] [nvarchar](255) NOT NULL,
	[estado] [nvarchar](10) NOT NULL,
	[createdAt] [datetime2](0) NOT NULL,
	[updatedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkUsuarios] PRIMARY KEY CLUSTERED 
(
	[id] ASC
),
 CONSTRAINT [uqUsuariosEmail] UNIQUE NONCLUSTERED 
(
	[email] ASC
)
) ON [PRIMARY]
GO
/* TABLA: espacios */
CREATE TABLE [dbo].[espacios](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](120) NOT NULL,
	[descripcion] [nvarchar](max) NULL,
	[ubicacion] [nvarchar](160) NOT NULL,
	[capacidad] [int] NOT NULL,
	[costo] [decimal](12, 2) NOT NULL,
	[estado] [nvarchar](20) NOT NULL,
	[imagen] [nvarchar](255) NULL,
	[createdAt] [datetime2](0) NOT NULL,
	[updatedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkEspacios] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/* TABLA: reservas */
CREATE TABLE [dbo].[reservas](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[codigo] [nvarchar](20) NOT NULL,
	[espacioId] [int] NOT NULL,
	[solicitantePerfilId] [int] NOT NULL,
	[creadoPorUsuarioId] [int] NULL,
	[grupo] [nvarchar](160) NULL,
	[responsable] [nvarchar](160) NOT NULL,
	[telefono] [nvarchar](30) NOT NULL,
	[email] [nvarchar](160) NOT NULL,
	[participantes] [int] NOT NULL,
	[tipoActividad] [nvarchar](120) NOT NULL,
	[fechaInicio] [datetime2](0) NOT NULL,
	[fechaFin] [datetime2](0) NOT NULL,
	[estado] [nvarchar](20) NOT NULL,
	[observaciones] [nvarchar](max) NULL,
	[createdAt] [datetime2](0) NOT NULL,
	[updatedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkReservas] PRIMARY KEY CLUSTERED 
(
	[id] ASC
),
 CONSTRAINT [uqReservasCodigo] UNIQUE NONCLUSTERED 
(
	[codigo] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/* VISTA: vReservasResumen */
CREATE VIEW [dbo].[vReservasResumen]
AS
SELECT
    r.id,
    r.codigo,
    r.fechaInicio,
    r.fechaFin,
    r.estado,
    r.participantes,
    r.tipoActividad,
    p.idPerfil AS solicitantePerfilId,
    p.nombre AS solicitante,
    e.id AS espacioId,
    e.nombre AS espacio,
    r.creadoPorUsuarioId,
    COALESCE(pc.nombre, u.email) AS creadoPor
FROM dbo.reservas AS r
INNER JOIN dbo.perfilesUsuario AS p
    ON p.idPerfil = r.solicitantePerfilId
INNER JOIN dbo.espacios AS e
    ON e.id = r.espacioId
LEFT JOIN dbo.usuarios AS u
    ON u.id = r.creadoPorUsuarioId
LEFT JOIN dbo.perfilesUsuario AS pc
    ON pc.usuarioId = u.id;

GO
/* TABLA: actividad */
CREATE TABLE [dbo].[actividad](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[usuarioId] [int] NULL,
	[modulo] [nvarchar](80) NOT NULL,
	[accion] [nvarchar](120) NOT NULL,
	[descripcion] [nvarchar](255) NULL,
	[createdAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkActividad] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [PRIMARY]
GO
/* TABLA: auditoriaReservas */
CREATE TABLE [dbo].[auditoriaReservas](
	[idAuditoria] [bigint] IDENTITY(1,1) NOT NULL,
	[tabla] [nvarchar](40) NOT NULL,
	[idRegistro] [int] NOT NULL,
	[accion] [nvarchar](10) NOT NULL,
	[detalle] [nvarchar](max) NULL,
	[usuarioAppId] [int] NULL,
	[usuarioAppNombre] [nvarchar](160) NULL,
	[usuarioBd] [nvarchar](120) NOT NULL,
	[creadoEn] [datetime2](0) NOT NULL,
 CONSTRAINT [pkAuditoriaReservas] PRIMARY KEY CLUSTERED 
(
	[idAuditoria] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/* TABLA: auditoriaPagos */
CREATE TABLE [dbo].[auditoriaPagos](
    [idAuditoriaPago] [bigint] IDENTITY(1,1) NOT NULL,
    [pagoId] [int] NOT NULL,
    [reservaId] [int] NULL,
    [accion] [nvarchar](10) NOT NULL,
    [valoresAnteriores] [nvarchar](max) NULL,
    [valoresNuevos] [nvarchar](max) NULL,
    [usuarioAppId] [int] NULL,
    [usuarioAppNombre] [nvarchar](160) NULL,
    [usuarioBd] [nvarchar](120) NOT NULL,
    [creadoEn] [datetime2](0) NOT NULL
        CONSTRAINT [dfAuditoriaPagosCreadoEn]
        DEFAULT (sysdatetime()),

    CONSTRAINT [pkAuditoriaPagos]
        PRIMARY KEY CLUSTERED ([idAuditoriaPago] ASC),

    CONSTRAINT [ckAuditoriaPagosAccion]
        CHECK ([accion] IN (N'INSERT', N'UPDATE', N'DELETE'))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO
/* TABLA: auditoriaAccesos */
CREATE TABLE [dbo].[auditoriaAccesos](
    [idAuditoriaAcceso] [bigint] IDENTITY(1,1) NOT NULL,
    [usuarioId] [int] NULL,
    [evento] [nvarchar](20) NOT NULL,
    [direccionIp] [varchar](45) NULL,
    [agenteUsuario] [nvarchar](300) NULL,
    [creadoEn] [datetime2](0) NOT NULL,
    CONSTRAINT [pkAuditoriaAccesos] PRIMARY KEY CLUSTERED ([idAuditoriaAcceso] ASC),
    CONSTRAINT [ckAuditoriaAccesosEvento] CHECK ([evento] IN (N'LOGIN', N'LOGIN_FALLIDO', N'LOGOUT', N'BACKUP', N'RESTORE'))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ixAuditoriaAccesosUsuarioFecha]
    ON [dbo].[auditoriaAccesos] ([usuarioId], [creadoEn] DESC)
GO
    CREATE TABLE [dbo].[respaldoHistorial](
        [idRespaldo] [bigint] IDENTITY(1,1) NOT NULL,
        [nombreArchivo] [nvarchar](120) NOT NULL,
        [creadoPorUsuarioId] [int] NULL,
        [creadoEn] [datetime2](0) NOT NULL,
        [bytes] [bigint] NOT NULL,
        CONSTRAINT [pkRespaldoHistorial] PRIMARY KEY CLUSTERED ([idRespaldo] ASC),
        CONSTRAINT [uqRespaldoHistorialNombre] UNIQUE ([nombreArchivo]),
        CONSTRAINT [ckRespaldoHistorialBytes] CHECK ([bytes] >= 0),
        CONSTRAINT [fkRespaldoHistorialUsuario] FOREIGN KEY ([creadoPorUsuarioId])
            REFERENCES [dbo].[usuarios] ([id]) ON DELETE SET NULL
    ) ON [PRIMARY]
    GO
    CREATE NONCLUSTERED INDEX [ixRespaldoHistorialFecha]
        ON [dbo].[respaldoHistorial] ([creadoEn] DESC)
    GO
    /* Vista: resumen de auditoría */
CREATE VIEW [dbo].[vAuditoriaResumen]
AS

    SELECT
        tabla COLLATE DATABASE_DEFAULT AS origen,
        accion COLLATE DATABASE_DEFAULT AS evento,
        COUNT_BIG(*) AS totalEventos,
        MAX(creadoEn) AS ultimoEvento
    FROM dbo.auditoriaReservas
    GROUP BY tabla, accion

    UNION ALL

    SELECT
        N'pagos' AS origen,
        accion COLLATE DATABASE_DEFAULT AS evento,
        COUNT_BIG(*) AS totalEventos,
        MAX(creadoEn) AS ultimoEvento
    FROM dbo.auditoriaPagos
    GROUP BY accion

    UNION ALL

    SELECT
        N'accesos' AS origen,
        evento COLLATE DATABASE_DEFAULT AS evento,
        COUNT_BIG(*) AS totalEventos,
        MAX(creadoEn) AS ultimoEvento
    FROM dbo.auditoriaAccesos
    GROUP BY evento;
GO
    /* =========================================================
       PERMISOS DEL USUARIO RESTRINGIDO
       ========================================================= */
    GRANT SELECT ON OBJECT::dbo.vReservasResumen TO [reservas_consulta];
    GRANT SELECT ON OBJECT::dbo.vPerfilesConfidencial TO [reservas_consulta];
    GO
    IF SUSER_ID(N'reservas_maintenance') IS NOT NULL
    BEGIN
        IF DATABASE_PRINCIPAL_ID(N'reservas_maintenance') IS NULL
            CREATE USER [reservas_maintenance] FOR LOGIN [reservas_maintenance];
        IF IS_ROLEMEMBER(N'db_backupoperator', N'reservas_maintenance') <> 1
            ALTER ROLE [db_backupoperator] ADD MEMBER [reservas_maintenance];
    END;
    GO
/* TABLA: pagos */
CREATE TABLE [dbo].[pagos](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[reservaId] [int] NOT NULL,
	[monto] [decimal](12, 2) NOT NULL,
	[metodo] [nvarchar](30) NOT NULL,
	[fechaPago] [date] NOT NULL,
	[estado] [nvarchar](15) NOT NULL,
	[comprobante] [nvarchar](255) NULL,
	[notas] [nvarchar](max) NULL,
	[createdAt] [datetime2](0) NOT NULL,
	[updatedAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkPagos] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/* TABLA: permisos */
CREATE TABLE [dbo].[permisos](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[clave] [nvarchar](80) NOT NULL,
	[descripcion] [nvarchar](180) NOT NULL,
	[createdAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkPermisos] PRIMARY KEY CLUSTERED 
(
	[id] ASC
),
 CONSTRAINT [uqPermisosClave] UNIQUE NONCLUSTERED 
(
	[clave] ASC
)
) ON [PRIMARY]
GO
/* TABLA: rolPermisos */
CREATE TABLE [dbo].[rolPermisos](
	[rolId] [int] NOT NULL,
	[permisoId] [int] NOT NULL,
 CONSTRAINT [pkRolPermisos] PRIMARY KEY CLUSTERED 
(
	[rolId] ASC,
	[permisoId] ASC
)
) ON [PRIMARY]
GO
/* TABLA: roles */
CREATE TABLE [dbo].[roles](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](50) NOT NULL,
	[descripcion] [nvarchar](180) NULL,
	[createdAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkRoles] PRIMARY KEY CLUSTERED 
(
	[id] ASC
),
 CONSTRAINT [uqRolesNombre] UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)
) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Administrador')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (
        N'Administrador',
        N'Acceso completo y administración del sistema.',
        SYSDATETIME()
    );

IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Usuario')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (
        N'Usuario',
        N'Puede crear reservas y consultar las propias.',
        SYSDATETIME()
    );

IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Recepcionista')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (
        N'Recepcionista',
        N'Gestiona reservas y pagos; consulta espacios y perfiles.',
        SYSDATETIME()
    );

IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Miembro')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (
        N'Miembro',
        N'Puede crear reservas y consultar las propias.',
        SYSDATETIME()
    );
GO
/* ÍNDICE: ixActividadUsuario */
CREATE NONCLUSTERED INDEX [ixActividadUsuario] ON [dbo].[actividad]
(
	[usuarioId] ASC
)
GO
/* ÍNDICE: ixAuditoriaUsuario */
CREATE NONCLUSTERED INDEX [ixAuditoriaUsuario] ON [dbo].[auditoriaReservas]
(
	[usuarioAppId] ASC
)
GO
/* ÍNDICE: ixPagosReserva */
CREATE NONCLUSTERED INDEX [ixPagosReserva] ON [dbo].[pagos]
(
	[reservaId] ASC
)
GO
/* ÍNDICE: uxPerfilesUsuarioIdentificacion */
CREATE UNIQUE NONCLUSTERED INDEX [uxPerfilesUsuarioIdentificacion] ON [dbo].[perfilesUsuario]
(
	[identificacion] ASC
)
WHERE ([identificacion] IS NOT NULL)
GO
/* ÍNDICE: uxPerfilesUsuarioUsuario */
CREATE UNIQUE NONCLUSTERED INDEX [uxPerfilesUsuarioUsuario] ON [dbo].[perfilesUsuario]
(
	[usuarioId] ASC
)
WHERE ([usuarioId] IS NOT NULL)
GO
/* ÍNDICE: ixReservasCreadoPor */
CREATE NONCLUSTERED INDEX [ixReservasCreadoPor] ON [dbo].[reservas]
(
	[creadoPorUsuarioId] ASC
)
GO
/* ÍNDICE: ixReservasEspacio */
CREATE NONCLUSTERED INDEX [ixReservasEspacio] ON [dbo].[reservas]
(
	[espacioId] ASC
)
GO
/* ÍNDICE: ixReservasFechas */
CREATE NONCLUSTERED INDEX [ixReservasFechas] ON [dbo].[reservas]
(
	[fechaInicio] ASC,
	[fechaFin] ASC
)
GO
/* ÍNDICE: ixReservasSolicitante */
CREATE NONCLUSTERED INDEX [ixReservasSolicitante] ON [dbo].[reservas]
(
	[solicitantePerfilId] ASC
)
GO
/* ÍNDICE: ixUsuariosRol */
CREATE NONCLUSTERED INDEX [ixUsuariosRol] ON [dbo].[usuarios]
(
	[rolId] ASC
)
GO
/* =========================================================
   5. RESTRICCIONES, VALORES POR DEFECTO Y RELACIONES
   ========================================================= */

ALTER TABLE [dbo].[actividad] ADD  CONSTRAINT [dfActividadCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[auditoriaReservas] ADD  CONSTRAINT [dfAuditoriaCreadoEn]  DEFAULT (sysdatetime()) FOR [creadoEn]
GO
ALTER TABLE [dbo].[espacios] ADD  CONSTRAINT [dfEspaciosCosto]  DEFAULT ((0.00)) FOR [costo]
GO
ALTER TABLE [dbo].[espacios] ADD  CONSTRAINT [dfEspaciosEstado]  DEFAULT (N'DISPONIBLE') FOR [estado]
GO
ALTER TABLE [dbo].[espacios] ADD  CONSTRAINT [dfEspaciosCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[espacios] ADD  CONSTRAINT [dfEspaciosUpdatedAt]  DEFAULT (sysdatetime()) FOR [updatedAt]
GO
ALTER TABLE [dbo].[pagos] ADD  CONSTRAINT [dfPagosEstado]  DEFAULT (N'PENDIENTE') FOR [estado]
GO
ALTER TABLE [dbo].[pagos] ADD  CONSTRAINT [dfPagosCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[pagos] ADD  CONSTRAINT [dfPagosUpdatedAt]  DEFAULT (sysdatetime()) FOR [updatedAt]
GO
ALTER TABLE [dbo].[perfilesUsuario] ADD  CONSTRAINT [dfPerfilesTipo]  DEFAULT (N'Persona') FOR [tipoPerfil]
GO
ALTER TABLE [dbo].[perfilesUsuario] ADD  CONSTRAINT [dfPerfilesCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[perfilesUsuario] ADD  CONSTRAINT [dfPerfilesUpdatedAt]  DEFAULT (sysdatetime()) FOR [updatedAt]
GO
ALTER TABLE [dbo].[permisos] ADD  CONSTRAINT [dfPermisosCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[reservas] ADD  CONSTRAINT [dfReservasEstado]  DEFAULT (N'PENDIENTE') FOR [estado]
GO
ALTER TABLE [dbo].[reservas] ADD  CONSTRAINT [dfReservasCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[reservas] ADD  CONSTRAINT [dfReservasUpdatedAt]  DEFAULT (sysdatetime()) FOR [updatedAt]
GO
ALTER TABLE [dbo].[roles] ADD  CONSTRAINT [dfRolesCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[usuarios] ADD  CONSTRAINT [dfUsuariosEstado]  DEFAULT (N'ACTIVO') FOR [estado]
GO
ALTER TABLE [dbo].[usuarios] ADD  CONSTRAINT [dfUsuariosCreatedAt]  DEFAULT (sysdatetime()) FOR [createdAt]
GO
ALTER TABLE [dbo].[usuarios] ADD  CONSTRAINT [dfUsuariosUpdatedAt]  DEFAULT (sysdatetime()) FOR [updatedAt]
GO
ALTER TABLE [dbo].[actividad]  WITH CHECK ADD  CONSTRAINT [fkActividadUsuarios] FOREIGN KEY([usuarioId])
REFERENCES [dbo].[usuarios] ([id])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[actividad] CHECK CONSTRAINT [fkActividadUsuarios]
GO
ALTER TABLE [dbo].[auditoriaReservas]  WITH CHECK ADD  CONSTRAINT [fkAuditoriaUsuario] FOREIGN KEY([usuarioAppId])
REFERENCES [dbo].[usuarios] ([id])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[auditoriaReservas] CHECK CONSTRAINT [fkAuditoriaUsuario]
GO
ALTER TABLE [dbo].[pagos]  WITH CHECK ADD  CONSTRAINT [fkPagosReservas] FOREIGN KEY([reservaId])
REFERENCES [dbo].[reservas] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[pagos] CHECK CONSTRAINT [fkPagosReservas]
GO
ALTER TABLE [dbo].[perfilesUsuario]  WITH CHECK ADD  CONSTRAINT [fkPerfilesUsuarioUsuarios] FOREIGN KEY([usuarioId])
REFERENCES [dbo].[usuarios] ([id])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[perfilesUsuario] CHECK CONSTRAINT [fkPerfilesUsuarioUsuarios]
GO
ALTER TABLE [dbo].[reservas]  WITH CHECK ADD  CONSTRAINT [fkReservasCreadoPor] FOREIGN KEY([creadoPorUsuarioId])
REFERENCES [dbo].[usuarios] ([id])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[reservas] CHECK CONSTRAINT [fkReservasCreadoPor]
GO
ALTER TABLE [dbo].[reservas]  WITH CHECK ADD  CONSTRAINT [fkReservasEspacios] FOREIGN KEY([espacioId])
REFERENCES [dbo].[espacios] ([id])
GO
ALTER TABLE [dbo].[reservas] CHECK CONSTRAINT [fkReservasEspacios]
GO
ALTER TABLE [dbo].[reservas]  WITH CHECK ADD  CONSTRAINT [fkReservasSolicitante] FOREIGN KEY([solicitantePerfilId])
REFERENCES [dbo].[perfilesUsuario] ([idPerfil])
GO
ALTER TABLE [dbo].[reservas] CHECK CONSTRAINT [fkReservasSolicitante]
GO
ALTER TABLE [dbo].[rolPermisos]  WITH CHECK ADD  CONSTRAINT [fkRolPermisosPermisos] FOREIGN KEY([permisoId])
REFERENCES [dbo].[permisos] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[rolPermisos] CHECK CONSTRAINT [fkRolPermisosPermisos]
GO
ALTER TABLE [dbo].[rolPermisos]  WITH CHECK ADD  CONSTRAINT [fkRolPermisosRoles] FOREIGN KEY([rolId])
REFERENCES [dbo].[roles] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[rolPermisos] CHECK CONSTRAINT [fkRolPermisosRoles]
GO
ALTER TABLE [dbo].[usuarios]  WITH CHECK ADD  CONSTRAINT [fkUsuariosRoles] FOREIGN KEY([rolId])
REFERENCES [dbo].[roles] ([id])
GO
ALTER TABLE [dbo].[usuarios] CHECK CONSTRAINT [fkUsuariosRoles]
GO
ALTER TABLE [dbo].[auditoriaReservas]  WITH CHECK ADD  CONSTRAINT [ckAuditoriaAccion] CHECK  (([accion]=N'DELETE' OR [accion]=N'UPDATE' OR [accion]=N'INSERT'))
GO
ALTER TABLE [dbo].[auditoriaReservas] CHECK CONSTRAINT [ckAuditoriaAccion]
GO
ALTER TABLE [dbo].[auditoriaReservas]  WITH CHECK ADD  CONSTRAINT [ckAuditoriaTabla] CHECK  (([tabla]=N'usuarios' OR [tabla]=N'reservas' OR [tabla]=N'pagos' OR [tabla]=N'espacios' OR [tabla]=N'perfilesUsuario'))
GO
ALTER TABLE [dbo].[auditoriaReservas] CHECK CONSTRAINT [ckAuditoriaTabla]
GO
ALTER TABLE [dbo].[espacios]  WITH CHECK ADD  CONSTRAINT [ckEspaciosCapacidad] CHECK  (([capacidad]>(0)))
GO
ALTER TABLE [dbo].[espacios] CHECK CONSTRAINT [ckEspaciosCapacidad]
GO
ALTER TABLE [dbo].[espacios]  WITH CHECK ADD  CONSTRAINT [ckEspaciosCosto] CHECK  (([costo]>=(0)))
GO
ALTER TABLE [dbo].[espacios] CHECK CONSTRAINT [ckEspaciosCosto]
GO
ALTER TABLE [dbo].[espacios]  WITH CHECK ADD  CONSTRAINT [ckEspaciosEstado] CHECK  (([estado]=N'INACTIVO' OR [estado]=N'MANTENIMIENTO' OR [estado]=N'DISPONIBLE'))
GO
ALTER TABLE [dbo].[espacios] CHECK CONSTRAINT [ckEspaciosEstado]
GO
ALTER TABLE [dbo].[pagos]  WITH CHECK ADD  CONSTRAINT [ckPagosEstado] CHECK  (([estado]=N'RECHAZADO' OR [estado]=N'PENDIENTE' OR [estado]=N'PAGADO'))
GO
ALTER TABLE [dbo].[pagos] CHECK CONSTRAINT [ckPagosEstado]
GO
ALTER TABLE [dbo].[pagos]  WITH CHECK ADD  CONSTRAINT [ckPagosMetodo] CHECK  (([metodo]=N'Tarjeta' OR [metodo]=N'Efectivo' OR [metodo]=N'Transferencia bancaria' OR [metodo]=N'SINPE Móvil'))
GO
ALTER TABLE [dbo].[pagos] CHECK CONSTRAINT [ckPagosMetodo]
GO
ALTER TABLE [dbo].[pagos]  WITH CHECK ADD  CONSTRAINT [ckPagosMonto] CHECK  (([monto]>=(0)))
GO
ALTER TABLE [dbo].[pagos] CHECK CONSTRAINT [ckPagosMonto]
GO
ALTER TABLE [dbo].[perfilesUsuario]  WITH CHECK ADD  CONSTRAINT [ckPerfilesCorreo] CHECK  (([dbo].[fnCorreoValido]([correoContacto])=(1)))
GO
ALTER TABLE [dbo].[perfilesUsuario] CHECK CONSTRAINT [ckPerfilesCorreo]
GO
ALTER TABLE [dbo].[perfilesUsuario]  WITH CHECK ADD  CONSTRAINT [ckPerfilesTipo] CHECK  (([tipoPerfil]=N'Grupo Scout' OR [tipoPerfil]=N'Institucion' OR [tipoPerfil]=N'Persona'))
GO
ALTER TABLE [dbo].[perfilesUsuario] CHECK CONSTRAINT [ckPerfilesTipo]
GO
ALTER TABLE [dbo].[reservas]  WITH CHECK ADD  CONSTRAINT [ckReservasEmail] CHECK  (([dbo].[fnCorreoValido]([email])=(1)))
GO
ALTER TABLE [dbo].[reservas] CHECK CONSTRAINT [ckReservasEmail]
GO
ALTER TABLE [dbo].[reservas]  WITH CHECK ADD  CONSTRAINT [ckReservasEstado] CHECK  (([estado]=N'FINALIZADA' OR [estado]=N'CANCELADA' OR [estado]=N'APROBADA' OR [estado]=N'PENDIENTE'))
GO
ALTER TABLE [dbo].[reservas] CHECK CONSTRAINT [ckReservasEstado]
GO
ALTER TABLE [dbo].[reservas]  WITH CHECK ADD  CONSTRAINT [ckReservasFechas] CHECK  (([fechaFin]>[fechaInicio]))
GO
ALTER TABLE [dbo].[reservas] CHECK CONSTRAINT [ckReservasFechas]
GO
ALTER TABLE [dbo].[reservas]  WITH CHECK ADD  CONSTRAINT [ckReservasParticipantes] CHECK  (([participantes]>(0)))
GO
ALTER TABLE [dbo].[reservas] CHECK CONSTRAINT [ckReservasParticipantes]
GO
ALTER TABLE [dbo].[usuarios]  WITH CHECK ADD  CONSTRAINT [ckUsuariosEmail] CHECK  (([dbo].[fnCorreoValido]([email])=(1)))
GO
ALTER TABLE [dbo].[usuarios] CHECK CONSTRAINT [ckUsuariosEmail]
GO
ALTER TABLE [dbo].[usuarios]  WITH CHECK ADD  CONSTRAINT [ckUsuariosEstado] CHECK  (([estado]=N'INACTIVO' OR [estado]=N'ACTIVO'))
GO
ALTER TABLE [dbo].[usuarios] CHECK CONSTRAINT [ckUsuariosEstado]
GO
/* PROCEDIMIENTO: paEspacioActualizar */
-- ACTUALIZAR
/* =========================================================
   6. PROCEDIMIENTOS ALMACENADOS
   ========================================================= */

CREATE PROCEDURE [dbo].[paEspacioActualizar]
    @pId INT,
    @pNombre NVARCHAR(120),
    @pDescripcion NVARCHAR(MAX) = NULL,
    @pUbicacion NVARCHAR(160),
    @pCapacidad INT,
    @pCosto DECIMAL(12,2),
    @pEstado NVARCHAR(20),
    @pImagen NVARCHAR(255) = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    SET @pNombre = NULLIF(LTRIM(RTRIM(@pNombre)), N'');
    SET @pUbicacion = NULLIF(LTRIM(RTRIM(@pUbicacion)), N'');
    SET @pEstado = UPPER(NULLIF(LTRIM(RTRIM(@pEstado)), N''));

    IF @pId IS NULL OR @pId <= 0
    BEGIN
        SET @pMensaje = N'El ID del espacio es obligatorio y debe ser mayor que cero.';
        RETURN 0;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE id = @pId)
    BEGIN
        SET @pMensaje = N'El espacio indicado no existe.';
        RETURN 0;
    END;

    IF @pNombre IS NULL
    BEGIN
        SET @pMensaje = N'El nombre del espacio es obligatorio.';
        RETURN 0;
    END;

    IF @pUbicacion IS NULL
    BEGIN
        SET @pMensaje = N'La ubicación del espacio es obligatoria.';
        RETURN 0;
    END;

    IF @pCapacidad IS NULL OR @pCapacidad <= 0
    BEGIN
        SET @pMensaje = N'La capacidad debe ser mayor que cero.';
        RETURN 0;
    END;

    IF @pCosto IS NULL OR @pCosto < 0
    BEGIN
        SET @pMensaje = N'El costo no puede ser negativo.';
        RETURN 0;
    END;

    IF @pEstado IS NULL OR @pEstado NOT IN (N'DISPONIBLE', N'MANTENIMIENTO', N'INACTIVO')
    BEGIN
        SET @pMensaje = N'El estado debe ser DISPONIBLE, MANTENIMIENTO o INACTIVO.';
        RETURN 0;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.espacios
        WHERE UPPER(LTRIM(RTRIM(nombre))) = UPPER(@pNombre)
          AND UPPER(LTRIM(RTRIM(ubicacion))) = UPPER(@pUbicacion)
          AND id <> @pId
    )
    BEGIN
        SET @pMensaje = N'Ya existe otro espacio con el mismo nombre y ubicación.';
        RETURN 0;
    END;

    BEGIN TRY
        UPDATE dbo.espacios
        SET nombre = @pNombre,
            descripcion = @pDescripcion,
            ubicacion = @pUbicacion,
            capacidad = @pCapacidad,
            costo = @pCosto,
            estado = @pEstado,
            imagen = @pImagen,
            updatedAt = SYSDATETIME()
        WHERE id = @pId;

        SET @pResultado = 1;
        SET @pMensaje = N'Espacio actualizado correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        SET @pResultado = 0;
        SET @pMensaje = CONCAT(N'Error al actualizar el espacio: ', ERROR_MESSAGE());
        RETURN 0;
    END CATCH;
END;

GO
/* PROCEDIMIENTO: paEspacioBuscarPorId */
--BUSCAR POR ID 
CREATE PROCEDURE [dbo].[paEspacioBuscarPorId]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    IF @pId IS NULL OR @pId <= 0
    BEGIN
        SET @pMensaje = N'El ID del espacio es obligatorio y debe ser mayor que cero.';
        RETURN 0;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE id = @pId)
    BEGIN
        SET @pMensaje = N'El espacio indicado no existe.';
        RETURN 0;
    END;

    SELECT
        id,
        nombre,
        descripcion,
        ubicacion,
        capacidad,
        costo,
        estado,
        imagen,
        createdAt,
        updatedAt
    FROM dbo.espacios
    WHERE id = @pId;

    SET @pResultado = 1;
    SET @pMensaje = N'Consulta realizada correctamente.';
    RETURN 1;
END;

GO
/* PROCEDIMIENTO: paEspacioEliminar */
--ELIMINAR 
CREATE PROCEDURE [dbo].[paEspacioEliminar]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    IF @pId IS NULL OR @pId <= 0
    BEGIN
        SET @pMensaje = N'El ID del espacio es obligatorio y debe ser mayor que cero.';
        RETURN 0;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE id = @pId)
    BEGIN
        SET @pMensaje = N'El espacio indicado no existe.';
        RETURN 0;
    END;

    IF EXISTS (SELECT 1 FROM dbo.reservas WHERE espacioId = @pId)
    BEGIN
        SET @pMensaje = N'No se puede eliminar el espacio porque tiene reservas asociadas.';
        RETURN 0;
    END;

    BEGIN TRY
        DELETE FROM dbo.espacios
        WHERE id = @pId;

        SET @pResultado = 1;
        SET @pMensaje = N'Espacio eliminado correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        SET @pResultado = 0;
        SET @pMensaje = CONCAT(N'Error al eliminar el espacio: ', ERROR_MESSAGE());
        RETURN 0;
    END CATCH;
END;

GO
/* PROCEDIMIENTO: paEspacioFiltrar */
-- FILTRAR / LISTAR 
CREATE PROCEDURE [dbo].[paEspacioFiltrar]
    @pNombre NVARCHAR(120) = NULL,
    @pUbicacion NVARCHAR(160) = NULL,
    @pEstado NVARCHAR(20) = NULL,
    @pCapacidadMinima INT = NULL,
    @pCostoMaximo DECIMAL(12,2) = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    SET @pNombre = NULLIF(LTRIM(RTRIM(@pNombre)), N'');
    SET @pUbicacion = NULLIF(LTRIM(RTRIM(@pUbicacion)), N'');
    SET @pEstado = UPPER(NULLIF(LTRIM(RTRIM(@pEstado)), N''));

    IF @pEstado IS NOT NULL
       AND @pEstado NOT IN (N'DISPONIBLE', N'MANTENIMIENTO', N'INACTIVO')
    BEGIN
        SET @pMensaje = N'El estado debe ser DISPONIBLE, MANTENIMIENTO o INACTIVO.';
        RETURN 0;
    END;

    IF @pCapacidadMinima IS NOT NULL AND @pCapacidadMinima <= 0
    BEGIN
        SET @pMensaje = N'La capacidad mínima debe ser mayor que cero.';
        RETURN 0;
    END;

    IF @pCostoMaximo IS NOT NULL AND @pCostoMaximo < 0
    BEGIN
        SET @pMensaje = N'El costo máximo no puede ser negativo.';
        RETURN 0;
    END;

    SELECT
        id,
        nombre,
        descripcion,
        ubicacion,
        capacidad,
        costo,
        estado,
        imagen,
        createdAt,
        updatedAt
    FROM dbo.espacios
    WHERE (@pNombre IS NULL OR nombre LIKE N'%' + @pNombre + N'%')
      AND (@pUbicacion IS NULL OR ubicacion LIKE N'%' + @pUbicacion + N'%')
      AND (@pEstado IS NULL OR estado = @pEstado)
      AND (@pCapacidadMinima IS NULL OR capacidad >= @pCapacidadMinima)
      AND (@pCostoMaximo IS NULL OR costo <= @pCostoMaximo)
    ORDER BY nombre;

    SET @pResultado = 1;
    SET @pMensaje = N'Filtro realizado correctamente.';
    RETURN 1;
END;

GO
/* PROCEDIMIENTO: paEspacioInsertar */
--INSERTAR 
CREATE PROCEDURE [dbo].[paEspacioInsertar]
    @pNombre NVARCHAR(120),
    @pDescripcion NVARCHAR(MAX) = NULL,
    @pUbicacion NVARCHAR(160),
    @pCapacidad INT,
    @pCosto DECIMAL(12,2),
    @pEstado NVARCHAR(20) = N'DISPONIBLE',
    @pImagen NVARCHAR(255) = NULL,
    @pIdGenerado INT OUTPUT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pIdGenerado = NULL;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    SET @pNombre = NULLIF(LTRIM(RTRIM(@pNombre)), N'');
    SET @pUbicacion = NULLIF(LTRIM(RTRIM(@pUbicacion)), N'');
    SET @pEstado = UPPER(NULLIF(LTRIM(RTRIM(@pEstado)), N''));

    IF @pNombre IS NULL
    BEGIN
        SET @pMensaje = N'El nombre del espacio es obligatorio.';
        RETURN 0;
    END;

    IF @pUbicacion IS NULL
    BEGIN
        SET @pMensaje = N'La ubicación del espacio es obligatoria.';
        RETURN 0;
    END;

    IF @pCapacidad IS NULL OR @pCapacidad <= 0
    BEGIN
        SET @pMensaje = N'La capacidad debe ser mayor que cero.';
        RETURN 0;
    END;

    IF @pCosto IS NULL OR @pCosto < 0
    BEGIN
        SET @pMensaje = N'El costo no puede ser negativo.';
        RETURN 0;
    END;

    IF @pEstado IS NULL OR @pEstado NOT IN (N'DISPONIBLE', N'MANTENIMIENTO', N'INACTIVO')
    BEGIN
        SET @pMensaje = N'El estado debe ser DISPONIBLE, MANTENIMIENTO o INACTIVO.';
        RETURN 0;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.espacios
        WHERE UPPER(LTRIM(RTRIM(nombre))) = UPPER(@pNombre)
          AND UPPER(LTRIM(RTRIM(ubicacion))) = UPPER(@pUbicacion)
    )
    BEGIN
        SET @pMensaje = N'Ya existe un espacio con el mismo nombre y ubicación.';
        RETURN 0;
    END;

    BEGIN TRY
        INSERT INTO dbo.espacios
        (
            nombre,
            descripcion,
            ubicacion,
            capacidad,
            costo,
            estado,
            imagen,
            createdAt,
            updatedAt
        )
        VALUES
        (
            @pNombre,
            @pDescripcion,
            @pUbicacion,
            @pCapacidad,
            @pCosto,
            @pEstado,
            @pImagen,
            SYSDATETIME(),
            SYSDATETIME()
        );

        SET @pIdGenerado = CONVERT(INT, SCOPE_IDENTITY());
        SET @pResultado = 1;
        SET @pMensaje = N'Espacio insertado correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        SET @pResultado = 0;
        SET @pMensaje = CONCAT(N'Error al insertar el espacio: ', ERROR_MESSAGE());
        RETURN 0;
    END CATCH;
END;

GO

/* =========================================================
   PROCEDIMIENTO: paPagoActualizar
========================================================= */

CREATE PROCEDURE [dbo].[paPagoActualizar]
    @pId INT,
    @pReservaId INT,
    @pMonto DECIMAL(12,2),
    @pMetodo NVARCHAR(30),
    @pFechaPago DATE,
    @pEstado NVARCHAR(15),
    @pComprobante NVARCHAR(255) = NULL,
    @pNotas NVARCHAR(MAX) = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        SET @pMetodo =
            NULLIF(LTRIM(RTRIM(@pMetodo)), N'');

        SET @pEstado =
            NULLIF(LTRIM(RTRIM(@pEstado)), N'');

        SET @pComprobante =
            NULLIF(LTRIM(RTRIM(@pComprobante)), N'');

        SET @pNotas =
            NULLIF(LTRIM(RTRIM(@pNotas)), N'');

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.pagos
            WHERE id = @pId
        )
        BEGIN
            SET @pMensaje =
                N'El pago indicado no existe.';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.reservas
            WHERE id = @pReservaId
        )
        BEGIN
            SET @pMensaje =
                N'La reserva indicada no existe.';
            RETURN;
        END;

        IF @pMonto IS NULL OR @pMonto <= 0
        BEGIN
            SET @pMensaje =
                N'El monto debe ser mayor que cero.';
            RETURN;
        END;

        IF @pMetodo NOT IN
        (
            N'SINPE Móvil',
            N'Transferencia bancaria',
            N'Efectivo',
            N'Tarjeta'
        )
        BEGIN
            SET @pMensaje =
                N'El método de pago no es válido.';
            RETURN;
        END;

        IF @pFechaPago IS NULL
        BEGIN
            SET @pMensaje =
                N'La fecha del pago es obligatoria.';
            RETURN;
        END;

        IF @pEstado NOT IN
        (
            N'PAGADO',
            N'PENDIENTE',
            N'RECHAZADO'
        )
        BEGIN
            SET @pMensaje =
                N'El estado del pago no es válido.';
            RETURN;
        END;

        IF @pEstado IN (N'PAGADO', N'PENDIENTE')
           AND EXISTS
           (
               SELECT 1
               FROM dbo.reservas
               WHERE id = @pReservaId
                 AND estado = N'CANCELADA'
           )
        BEGIN
            SET @pMensaje =
                N'No se pueden registrar pagos activos para una reserva cancelada.';
            RETURN;
        END;

        IF @pEstado = N'PAGADO'
        BEGIN
            DECLARE @costoEspacio DECIMAL(12,2);
            DECLARE @totalPagado DECIMAL(12,2);

            SELECT
                @costoEspacio = e.costo
            FROM dbo.reservas AS r
            INNER JOIN dbo.espacios AS e
                ON e.id = r.espacioId
            WHERE r.id = @pReservaId;

            SELECT
                @totalPagado =
                    ISNULL(SUM(p.monto), 0)
            FROM dbo.pagos AS p
            WHERE p.reservaId = @pReservaId
              AND p.estado = N'PAGADO'
              AND p.id <> @pId;

            IF @totalPagado + @pMonto > @costoEspacio
            BEGIN
                SET @pMensaje =
                    N'El total pagado no puede superar el costo del espacio reservado.';
                RETURN;
            END;
        END;

        UPDATE dbo.pagos
        SET
            reservaId = @pReservaId,
            monto = @pMonto,
            metodo = @pMetodo,
            fechaPago = @pFechaPago,
            estado = @pEstado,
            comprobante = @pComprobante,
            notas = @pNotas,
            updatedAt = SYSDATETIME()
        WHERE id = @pId;

        SET @pResultado = 1;
        SET @pMensaje =
            N'Pago actualizado correctamente.';

    END TRY
    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje = ERROR_MESSAGE();

    END CATCH;
END;
GO
/* PROCEDIMIENTO: paPagoBuscarPorId */
CREATE PROCEDURE [dbo].[paPagoBuscarPorId]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        IF @pId IS NULL OR @pId <= 0
        BEGIN
            SET @pMensaje = N'El ID del pago no es válido.';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.pagos
            WHERE id = @pId
        )
        BEGIN
            SET @pMensaje = N'El pago indicado no existe.';
            RETURN;
        END;

        SELECT
            p.id,
            p.reservaId,
            r.codigo AS reservaCodigo,
            e.nombre AS espacio,

            p.monto,
            p.metodo,
            p.fechaPago,
            p.estado,
            p.comprobante,
            p.notas,

            e.costo AS costoEspacio,

            totales.totalPagado,

            e.costo - totales.totalPagado
                AS saldoPendiente,

            p.createdAt,
            p.updatedAt

        FROM dbo.pagos AS p

        INNER JOIN dbo.reservas AS r
            ON r.id = p.reservaId

        INNER JOIN dbo.espacios AS e
            ON e.id = r.espacioId

        OUTER APPLY
        (
            SELECT
                ISNULL(SUM(p2.monto), 0)
                    AS totalPagado
            FROM dbo.pagos AS p2
            WHERE p2.reservaId = p.reservaId
              AND p2.estado = N'PAGADO'
        ) AS totales

        WHERE p.id = @pId;

        SET @pResultado = 1;
        SET @pMensaje =
            N'Consulta realizada correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje = ERROR_MESSAGE();

    END CATCH;
END;
GO

/* =========================================================
   PROCEDIMIENTO: paPagoEliminar
========================================================= */

CREATE PROCEDURE [dbo].[paPagoEliminar]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        IF @pId IS NULL OR @pId <= 0
        BEGIN
            SET @pMensaje =
                N'El ID del pago no es válido.';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.pagos
            WHERE id = @pId
        )
        BEGIN
            SET @pMensaje =
                N'El pago indicado no existe.';
            RETURN;
        END;

        DELETE FROM dbo.pagos
        WHERE id = @pId;

        SET @pResultado = 1;
        SET @pMensaje =
            N'Pago eliminado correctamente.';

    END TRY
    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje = ERROR_MESSAGE();

    END CATCH;
END;
GO
/* PROCEDIMIENTO: paPagoFiltrar */
CREATE PROCEDURE [dbo].[paPagoFiltrar]
    @pReservaId INT = NULL,
    @pCodigoReserva NVARCHAR(20) = NULL,
    @pMetodo NVARCHAR(30) = NULL,
    @pEstado NVARCHAR(15) = NULL,
    @pFechaDesde DATE = NULL,
    @pFechaHasta DATE = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        SET @pCodigoReserva =
            NULLIF(LTRIM(RTRIM(@pCodigoReserva)), N'');

        SET @pMetodo =
            NULLIF(LTRIM(RTRIM(@pMetodo)), N'');

        SET @pEstado =
            NULLIF(LTRIM(RTRIM(@pEstado)), N'');

        /* Validar método */
        IF @pMetodo IS NOT NULL
           AND @pMetodo NOT IN
           (
               N'SINPE Móvil',
               N'Transferencia bancaria',
               N'Efectivo',
               N'Tarjeta'
           )
        BEGIN
            SET @pMensaje =
                N'El método de pago no es válido.';
            RETURN;
        END;

        /* Validar estado */
        IF @pEstado IS NOT NULL
           AND @pEstado NOT IN
           (
               N'PAGADO',
               N'PENDIENTE',
               N'RECHAZADO'
           )
        BEGIN
            SET @pMensaje =
                N'El estado del pago no es válido.';
            RETURN;
        END;

        /* Validar rango de fechas */
        IF @pFechaDesde IS NOT NULL
           AND @pFechaHasta IS NOT NULL
           AND @pFechaHasta < @pFechaDesde
        BEGIN
            SET @pMensaje =
                N'La fecha final no puede ser menor que la fecha inicial.';
            RETURN;
        END;

        SELECT
            p.id,
            p.reservaId,
            r.codigo AS reservaCodigo,
            e.nombre AS espacio,

            p.monto,
            p.metodo,
            p.fechaPago,
            p.estado,
            p.comprobante,
            p.notas,

            /* NUEVO: costo completo del espacio */
            e.costo AS costoEspacio,

            /* NUEVO: total que ya ha sido PAGADO */
            totales.totalPagado,

            /* NUEVO: dinero que todavía falta */
            e.costo - totales.totalPagado AS saldoPendiente,

            p.createdAt,
            p.updatedAt

        FROM dbo.pagos AS p

        INNER JOIN dbo.reservas AS r
            ON r.id = p.reservaId

        INNER JOIN dbo.espacios AS e
            ON e.id = r.espacioId

        /* Calcula todos los pagos PAGADO de la reserva */
        OUTER APPLY
        (
            SELECT
                ISNULL(SUM(p2.monto), 0) AS totalPagado
            FROM dbo.pagos AS p2
            WHERE p2.reservaId = p.reservaId
              AND p2.estado = N'PAGADO'
        ) AS totales

        WHERE
            (
                @pReservaId IS NULL
                OR p.reservaId = @pReservaId
            )
            AND
            (
                @pCodigoReserva IS NULL
                OR r.codigo LIKE
                    N'%' + @pCodigoReserva + N'%'
            )
            AND
            (
                @pMetodo IS NULL
                OR p.metodo = @pMetodo
            )
            AND
            (
                @pEstado IS NULL
                OR p.estado = @pEstado
            )
            AND
            (
                @pFechaDesde IS NULL
                OR p.fechaPago >= @pFechaDesde
            )
            AND
            (
                @pFechaHasta IS NULL
                OR p.fechaPago <= @pFechaHasta
            )

        ORDER BY
            p.fechaPago DESC,
            p.id DESC;

        SET @pResultado = 1;
        SET @pMensaje =
            N'Consulta realizada correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje = ERROR_MESSAGE();

    END CATCH;
END;
GO

/* =========================================================
   PROCEDIMIENTO: paPagoInsertar
   Descripción:
   Inserta un nuevo pago asociado a una reserva.
========================================================= */

CREATE PROCEDURE [dbo].[paPagoInsertar]
    @pReservaId INT,
    @pMonto DECIMAL(12,2),
    @pMetodo NVARCHAR(30),
    @pFechaPago DATE,
    @pEstado NVARCHAR(15) = N'PENDIENTE',
    @pComprobante NVARCHAR(255) = NULL,
    @pNotas NVARCHAR(MAX) = NULL,
    @pIdGenerado INT OUTPUT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @pIdGenerado = NULL;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        SET @pMetodo =
            NULLIF(LTRIM(RTRIM(@pMetodo)), N'');

        SET @pEstado =
            NULLIF(LTRIM(RTRIM(@pEstado)), N'');

        SET @pComprobante =
            NULLIF(LTRIM(RTRIM(@pComprobante)), N'');

        SET @pNotas =
            NULLIF(LTRIM(RTRIM(@pNotas)), N'');

        /* Validar reserva */
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.reservas
            WHERE id = @pReservaId
        )
        BEGIN
            SET @pMensaje =
                N'La reserva indicada no existe.';
            RETURN;
        END;

        /* Validar monto */
        IF @pMonto IS NULL OR @pMonto <= 0
        BEGIN
            SET @pMensaje =
                N'El monto debe ser mayor que cero.';
            RETURN;
        END;

        /* Validar método */
        IF @pMetodo NOT IN
        (
            N'SINPE Móvil',
            N'Transferencia bancaria',
            N'Efectivo',
            N'Tarjeta'
        )
        BEGIN
            SET @pMensaje =
                N'El método de pago no es válido.';
            RETURN;
        END;

        /* Validar fecha */
        IF @pFechaPago IS NULL
        BEGIN
            SET @pMensaje =
                N'La fecha del pago es obligatoria.';
            RETURN;
        END;

        /* Validar estado */
        IF @pEstado NOT IN
        (
            N'PAGADO',
            N'PENDIENTE',
            N'RECHAZADO'
        )
        BEGIN
            SET @pMensaje =
                N'El estado del pago no es válido.';
            RETURN;
        END;

        /* No permitir pagos activos para reservas canceladas */
        IF @pEstado IN (N'PAGADO', N'PENDIENTE')
           AND EXISTS
           (
               SELECT 1
               FROM dbo.reservas
               WHERE id = @pReservaId
                 AND estado = N'CANCELADA'
           )
        BEGIN
            SET @pMensaje =
                N'No se pueden registrar pagos activos para una reserva cancelada.';
            RETURN;
        END;

        /* Validar que pagos PAGADO no superen el costo */
        IF @pEstado = N'PAGADO'
        BEGIN
            DECLARE @costoEspacio DECIMAL(12,2);
            DECLARE @totalPagado DECIMAL(12,2);

            SELECT
                @costoEspacio = e.costo
            FROM dbo.reservas AS r
            INNER JOIN dbo.espacios AS e
                ON e.id = r.espacioId
            WHERE r.id = @pReservaId;

            SELECT
                @totalPagado =
                    ISNULL(SUM(p.monto), 0)
            FROM dbo.pagos AS p
            WHERE p.reservaId = @pReservaId
              AND p.estado = N'PAGADO';

            IF @totalPagado + @pMonto > @costoEspacio
            BEGIN
                SET @pMensaje =
                    N'El total pagado no puede superar el costo del espacio reservado.';
                RETURN;
            END;
        END;

        INSERT INTO dbo.pagos
        (
            reservaId,
            monto,
            metodo,
            fechaPago,
            estado,
            comprobante,
            notas
        )
        VALUES
        (
            @pReservaId,
            @pMonto,
            @pMetodo,
            @pFechaPago,
            @pEstado,
            @pComprobante,
            @pNotas
        );

        SET @pIdGenerado =
            CONVERT(INT, SCOPE_IDENTITY());

        SET @pResultado = 1;
        SET @pMensaje =
            N'Pago registrado correctamente.';

    END TRY
    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje = ERROR_MESSAGE();

    END CATCH;
END;
GO
/* PROCEDIMIENTO: paPerfilActualizar */
--ACTUALIZAR PERFIL
CREATE PROCEDURE [dbo].[paPerfilActualizar]
    @pIdPerfil INT,
    @pUsuarioId INT = NULL,
    @pNombre NVARCHAR(MAX),
    @pIdentificacion NVARCHAR(MAX) = NULL,
    @pTelefono NVARCHAR(MAX) = NULL,
    @pCorreoContacto NVARCHAR(MAX),
    @pTipoPerfil NVARCHAR(MAX),
    @pDireccion NVARCHAR(MAX) = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    SET @pNombre = NULLIF(LTRIM(RTRIM(@pNombre)), N'');
    SET @pIdentificacion = NULLIF(LTRIM(RTRIM(@pIdentificacion)), N'');
    SET @pTelefono = NULLIF(LTRIM(RTRIM(@pTelefono)), N'');
    SET @pCorreoContacto = NULLIF(LTRIM(RTRIM(@pCorreoContacto)), N'');
    SET @pTipoPerfil = NULLIF(LTRIM(RTRIM(@pTipoPerfil)), N'');
    SET @pDireccion = NULLIF(LTRIM(RTRIM(@pDireccion)), N'');

    IF @pIdPerfil IS NULL OR @pIdPerfil <= 0
    BEGIN
        SET @pMensaje = N'El ID del perfil debe ser mayor que cero.';
        RETURN 0;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.perfilesUsuario
        WHERE idPerfil = @pIdPerfil
    )
    BEGIN
        SET @pMensaje = N'El perfil indicado no existe.';
        RETURN 0;
    END;

    IF @pNombre IS NULL
    BEGIN
        SET @pMensaje = N'El nombre es obligatorio.';
        RETURN 0;
    END;

    IF LEN(@pNombre) > 160
    BEGIN
        SET @pMensaje = N'El nombre no puede superar los 160 caracteres.';
        RETURN 0;
    END;

    IF @pIdentificacion IS NOT NULL AND LEN(@pIdentificacion) > 30
    BEGIN
        SET @pMensaje = N'La identificación no puede superar los 30 caracteres.';
        RETURN 0;
    END;

    IF @pTelefono IS NOT NULL AND LEN(@pTelefono) > 30
    BEGIN
        SET @pMensaje = N'El teléfono no puede superar los 30 caracteres.';
        RETURN 0;
    END;

    IF @pCorreoContacto IS NULL
    BEGIN
        SET @pMensaje = N'El correo de contacto es obligatorio.';
        RETURN 0;
    END;

    IF LEN(@pCorreoContacto) > 160
       OR dbo.fnCorreoValido(CONVERT(NVARCHAR(160), @pCorreoContacto)) = 0
    BEGIN
        SET @pMensaje = N'El correo de contacto no es válido.';
        RETURN 0;
    END;

    IF @pTipoPerfil IS NULL
       OR UPPER(@pTipoPerfil) NOT IN
       (
           N'PERSONA',
           N'INSTITUCION',
           N'GRUPO SCOUT'
       )
    BEGIN
        SET @pMensaje =
            N'El tipo de perfil debe ser Persona, Institucion o Grupo Scout.';
        RETURN 0;
    END;

    IF UPPER(@pTipoPerfil) = N'PERSONA'
        SET @pTipoPerfil = N'Persona';

    IF UPPER(@pTipoPerfil) = N'INSTITUCION'
        SET @pTipoPerfil = N'Institucion';

    IF UPPER(@pTipoPerfil) = N'GRUPO SCOUT'
        SET @pTipoPerfil = N'Grupo Scout';

    IF @pDireccion IS NOT NULL AND LEN(@pDireccion) > 255
    BEGIN
        SET @pMensaje = N'La dirección no puede superar los 255 caracteres.';
        RETURN 0;
    END;

    IF @pUsuarioId IS NOT NULL AND @pUsuarioId <= 0
    BEGIN
        SET @pMensaje = N'El ID del usuario debe ser mayor que cero.';
        RETURN 0;
    END;

    IF @pUsuarioId IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM dbo.usuarios
           WHERE id = @pUsuarioId
       )
    BEGIN
        SET @pMensaje = N'El usuario indicado no existe.';
        RETURN 0;
    END;

    IF @pUsuarioId IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM dbo.perfilesUsuario
           WHERE usuarioId = @pUsuarioId
             AND idPerfil <> @pIdPerfil
       )
    BEGIN
        SET @pMensaje = N'El usuario indicado ya tiene otro perfil asociado.';
        RETURN 0;
    END;

    IF @pIdentificacion IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM dbo.perfilesUsuario
           WHERE identificacion = @pIdentificacion
             AND idPerfil <> @pIdPerfil
       )
    BEGIN
        SET @pMensaje = N'Ya existe otro perfil con esa identificación.';
        RETURN 0;
    END;

    BEGIN TRY

        UPDATE dbo.perfilesUsuario
        SET
            usuarioId = @pUsuarioId,
            nombre = @pNombre,
            identificacion = @pIdentificacion,
            telefono = @pTelefono,
            correoContacto = @pCorreoContacto,
            tipoPerfil = @pTipoPerfil,
            direccion = @pDireccion,
            updatedAt = SYSDATETIME()
        WHERE idPerfil = @pIdPerfil;

        SET @pResultado = 1;
        SET @pMensaje = N'Perfil actualizado correctamente.';

        RETURN 1;

    END TRY
    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje =
            CONCAT(N'Error al actualizar el perfil: ', ERROR_MESSAGE());

        RETURN 0;

    END CATCH;
END;

GO
/* PROCEDIMIENTO: paPerfilBuscarPorId */
-- BUSCAR PERFIL POR ID
 
CREATE PROCEDURE [dbo].[paPerfilBuscarPorId]
    @pIdPerfil INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    IF @pIdPerfil IS NULL OR @pIdPerfil <= 0
    BEGIN
        SET @pMensaje = N'El ID del perfil debe ser mayor que cero.';
        RETURN 0;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.perfilesUsuario
        WHERE idPerfil = @pIdPerfil
    )
    BEGIN
        SET @pMensaje = N'El perfil indicado no existe.';
        RETURN 0;
    END;

    SELECT
        idPerfil,
        usuarioId,
        nombre,
        identificacion,
        telefono,
        correoContacto,
        tipoPerfil,
        direccion,
        createdAt,
        updatedAt
    FROM dbo.perfilesUsuario
    WHERE idPerfil = @pIdPerfil;

    SET @pResultado = 1;
    SET @pMensaje = N'Consulta realizada correctamente.';

    RETURN 1;
END;

GO
/* PROCEDIMIENTO: paPerfilEliminar */
--ELIMINAR PERFIL
CREATE PROCEDURE [dbo].[paPerfilEliminar]
    @pIdPerfil INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    IF @pIdPerfil IS NULL OR @pIdPerfil <= 0
    BEGIN
        SET @pMensaje = N'El ID del perfil debe ser mayor que cero.';
        RETURN 0;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.perfilesUsuario
        WHERE idPerfil = @pIdPerfil
    )
    BEGIN
        SET @pMensaje = N'El perfil indicado no existe.';
        RETURN 0;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.reservas
        WHERE solicitantePerfilId = @pIdPerfil
    )
    BEGIN
        SET @pMensaje =
            N'No se puede eliminar el perfil porque tiene reservas asociadas.';
        RETURN 0;
    END;

    BEGIN TRY

        DELETE FROM dbo.perfilesUsuario
        WHERE idPerfil = @pIdPerfil;

        SET @pResultado = 1;
        SET @pMensaje = N'Perfil eliminado correctamente.';

        RETURN 1;

    END TRY
    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje =
            CONCAT(N'Error al eliminar el perfil: ', ERROR_MESSAGE());

        RETURN 0;

    END CATCH;
END;

GO
/* PROCEDIMIENTO: paPerfilFiltrar */
--FILTRAR PERFILES

CREATE PROCEDURE [dbo].[paPerfilFiltrar]
    @pNombre NVARCHAR(160) = NULL,
    @pIdentificacion NVARCHAR(30) = NULL,
    @pCorreoContacto NVARCHAR(160) = NULL,
    @pTipoPerfil NVARCHAR(20) = NULL,
    @pUsuarioId INT = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    SET @pNombre = NULLIF(LTRIM(RTRIM(@pNombre)), N'');
    SET @pIdentificacion = NULLIF(LTRIM(RTRIM(@pIdentificacion)), N'');
    SET @pCorreoContacto = NULLIF(LTRIM(RTRIM(@pCorreoContacto)), N'');
    SET @pTipoPerfil = NULLIF(LTRIM(RTRIM(@pTipoPerfil)), N'');

    IF @pUsuarioId IS NOT NULL AND @pUsuarioId <= 0
    BEGIN
        SET @pMensaje = N'El ID del usuario debe ser mayor que cero.';
        RETURN 0;
    END;

    IF @pTipoPerfil IS NOT NULL
       AND UPPER(@pTipoPerfil) NOT IN
       (
           N'PERSONA',
           N'INSTITUCION',
           N'GRUPO SCOUT'
       )
    BEGIN
        SET @pMensaje =
            N'El tipo de perfil indicado no es válido.';
        RETURN 0;
    END;

    SELECT
        idPerfil,
        usuarioId,
        nombre,
        identificacion,
        telefono,
        correoContacto,
        tipoPerfil,
        direccion,
        createdAt,
        updatedAt
    FROM dbo.perfilesUsuario
    WHERE
        (@pNombre IS NULL OR nombre LIKE N'%' + @pNombre + N'%')
        AND
        (@pIdentificacion IS NULL
            OR identificacion LIKE N'%' + @pIdentificacion + N'%')
        AND
        (@pCorreoContacto IS NULL
            OR correoContacto LIKE N'%' + @pCorreoContacto + N'%')
        AND
        (@pTipoPerfil IS NULL OR tipoPerfil = @pTipoPerfil)
        AND
        (@pUsuarioId IS NULL OR usuarioId = @pUsuarioId)
    ORDER BY nombre;

    SET @pResultado = 1;
    SET @pMensaje = N'Filtro realizado correctamente.';

    RETURN 1;
END;

GO
/* PROCEDIMIENTO: paPerfilInsertar */
  -- INSERTAR PERFIL
 
CREATE PROCEDURE [dbo].[paPerfilInsertar]
    @pUsuarioId INT = NULL,
    @pNombre NVARCHAR(MAX),
    @pIdentificacion NVARCHAR(MAX) = NULL,
    @pTelefono NVARCHAR(MAX) = NULL,
    @pCorreoContacto NVARCHAR(MAX),
    @pTipoPerfil NVARCHAR(MAX),
    @pDireccion NVARCHAR(MAX) = NULL,
    @pIdGenerado INT OUTPUT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pIdGenerado = NULL;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    SET @pNombre = NULLIF(LTRIM(RTRIM(@pNombre)), N'');
    SET @pIdentificacion = NULLIF(LTRIM(RTRIM(@pIdentificacion)), N'');
    SET @pTelefono = NULLIF(LTRIM(RTRIM(@pTelefono)), N'');
    SET @pCorreoContacto = NULLIF(LTRIM(RTRIM(@pCorreoContacto)), N'');
    SET @pTipoPerfil = NULLIF(LTRIM(RTRIM(@pTipoPerfil)), N'');
    SET @pDireccion = NULLIF(LTRIM(RTRIM(@pDireccion)), N'');

    IF @pNombre IS NULL
    BEGIN
        SET @pMensaje = N'El nombre es obligatorio.';
        RETURN 0;
    END;

    IF LEN(@pNombre) > 160
    BEGIN
        SET @pMensaje = N'El nombre no puede superar los 160 caracteres.';
        RETURN 0;
    END;

    IF @pIdentificacion IS NOT NULL AND LEN(@pIdentificacion) > 30
    BEGIN
        SET @pMensaje = N'La identificación no puede superar los 30 caracteres.';
        RETURN 0;
    END;

    IF @pTelefono IS NOT NULL AND LEN(@pTelefono) > 30
    BEGIN
        SET @pMensaje = N'El teléfono no puede superar los 30 caracteres.';
        RETURN 0;
    END;

    IF @pCorreoContacto IS NULL
    BEGIN
        SET @pMensaje = N'El correo de contacto es obligatorio.';
        RETURN 0;
    END;

    IF LEN(@pCorreoContacto) > 160
       OR dbo.fnCorreoValido(CONVERT(NVARCHAR(160), @pCorreoContacto)) = 0
    BEGIN
        SET @pMensaje = N'El correo de contacto no es válido.';
        RETURN 0;
    END;

    IF @pTipoPerfil IS NULL
       OR UPPER(@pTipoPerfil) NOT IN
       (
           N'PERSONA',
           N'INSTITUCION',
           N'GRUPO SCOUT'
       )
    BEGIN
        SET @pMensaje =
            N'El tipo de perfil debe ser Persona, Institucion o Grupo Scout.';
        RETURN 0;
    END;

    IF UPPER(@pTipoPerfil) = N'PERSONA'
        SET @pTipoPerfil = N'Persona';

    IF UPPER(@pTipoPerfil) = N'INSTITUCION'
        SET @pTipoPerfil = N'Institucion';

    IF UPPER(@pTipoPerfil) = N'GRUPO SCOUT'
        SET @pTipoPerfil = N'Grupo Scout';

    IF @pDireccion IS NOT NULL AND LEN(@pDireccion) > 255
    BEGIN
        SET @pMensaje = N'La dirección no puede superar los 255 caracteres.';
        RETURN 0;
    END;

    IF @pUsuarioId IS NOT NULL AND @pUsuarioId <= 0
    BEGIN
        SET @pMensaje = N'El ID del usuario debe ser mayor que cero.';
        RETURN 0;
    END;

    IF @pUsuarioId IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM dbo.usuarios
           WHERE id = @pUsuarioId
       )
    BEGIN
        SET @pMensaje = N'El usuario indicado no existe.';
        RETURN 0;
    END;

    IF @pUsuarioId IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM dbo.perfilesUsuario
           WHERE usuarioId = @pUsuarioId
       )
    BEGIN
        SET @pMensaje = N'El usuario indicado ya tiene un perfil asociado.';
        RETURN 0;
    END;

    IF @pIdentificacion IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM dbo.perfilesUsuario
           WHERE identificacion = @pIdentificacion
       )
    BEGIN
        SET @pMensaje = N'Ya existe un perfil con esa identificación.';
        RETURN 0;
    END;

    BEGIN TRY

        INSERT INTO dbo.perfilesUsuario
        (
            usuarioId,
            nombre,
            identificacion,
            telefono,
            correoContacto,
            tipoPerfil,
            direccion,
            createdAt,
            updatedAt
        )
        VALUES
        (
            @pUsuarioId,
            @pNombre,
            @pIdentificacion,
            @pTelefono,
            @pCorreoContacto,
            @pTipoPerfil,
            @pDireccion,
            SYSDATETIME(),
            SYSDATETIME()
        );

        SET @pIdGenerado = CONVERT(INT, SCOPE_IDENTITY());
        SET @pResultado = 1;
        SET @pMensaje = N'Perfil insertado correctamente.';

        RETURN 1;

    END TRY
    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje =
            CONCAT(N'Error al insertar el perfil: ', ERROR_MESSAGE());

        RETURN 0;

    END CATCH;
END;

GO
/* PROCEDIMIENTO: paReservaActualizar */
CREATE PROCEDURE [dbo].[paReservaActualizar]
    @pId INT,
    @pCodigo NVARCHAR(20),
    @pEspacioId INT,
    @pSolicitantePerfilId INT,
    @pCreadoPorUsuarioId INT = NULL,
    @pGrupo NVARCHAR(160) = NULL,
    @pResponsable NVARCHAR(160),
    @pTelefono NVARCHAR(30),
    @pEmail NVARCHAR(160),
    @pParticipantes INT,
    @pTipoActividad NVARCHAR(120),
    @pFechaInicio DATETIME2(0),
    @pFechaFin DATETIME2(0),
    @pEstado NVARCHAR(20),
    @pObservaciones NVARCHAR(MAX) = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY
        IF @pId IS NULL OR @pId <= 0
        BEGIN
            SET @pMensaje = N'El ID de la reserva debe ser mayor que cero.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pCodigo)), N'') IS NULL OR LEN(@pCodigo) > 20
        BEGIN
            SET @pMensaje = N'El código es obligatorio y no puede superar 20 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pResponsable)), N'') IS NULL OR LEN(@pResponsable) > 160
        BEGIN
            SET @pMensaje = N'El responsable es obligatorio y no puede superar 160 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pTelefono)), N'') IS NULL OR LEN(@pTelefono) > 30
        BEGIN
            SET @pMensaje = N'El teléfono es obligatorio y no puede superar 30 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pEmail)), N'') IS NULL OR LEN(@pEmail) > 160 OR dbo.fnCorreoValido(LTRIM(RTRIM(@pEmail))) <> 1
        BEGIN
            SET @pMensaje = N'El correo es obligatorio y debe ser válido.';
            RETURN 0;
        END;

        IF @pParticipantes IS NULL OR @pParticipantes <= 0
        BEGIN
            SET @pMensaje = N'La cantidad de participantes debe ser mayor que cero.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pTipoActividad)), N'') IS NULL OR LEN(@pTipoActividad) > 120
        BEGIN
            SET @pMensaje = N'El tipo de actividad es obligatorio y no puede superar 120 caracteres.';
            RETURN 0;
        END;

        IF @pGrupo IS NOT NULL AND LEN(@pGrupo) > 160
        BEGIN
            SET @pMensaje = N'El grupo no puede superar 160 caracteres.';
            RETURN 0;
        END;

        IF @pFechaInicio IS NULL OR @pFechaFin IS NULL OR @pFechaFin <= @pFechaInicio
        BEGIN
            SET @pMensaje = N'La fecha final debe ser mayor que la fecha inicial.';
            RETURN 0;
        END;

        IF @pEstado NOT IN (N'PENDIENTE', N'APROBADA', N'CANCELADA', N'FINALIZADA')
        BEGIN
            SET @pMensaje = N'El estado de la reserva no es válido.';
            RETURN 0;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.perfilesUsuario WHERE idPerfil = @pSolicitantePerfilId)
        BEGIN
            SET @pMensaje = N'El perfil solicitante no existe.';
            RETURN 0;
        END;

        IF @pCreadoPorUsuarioId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.usuarios WHERE id = @pCreadoPorUsuarioId)
        BEGIN
            SET @pMensaje = N'El usuario creador no existe.';
            RETURN 0;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.reservas WITH (UPDLOCK, HOLDLOCK) WHERE id = @pId)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'La reserva indicada no existe.';
            RETURN 0;
        END;

        IF EXISTS
        (
            SELECT 1 FROM dbo.reservas
            WHERE codigo = LTRIM(RTRIM(@pCodigo))
              AND id <> @pId
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'Ya existe otra reserva con ese código.';
            RETURN 0;
        END;

        DECLARE @capacidad INT;
        DECLARE @estadoEspacio NVARCHAR(20);

        SELECT
            @capacidad = capacidad,
            @estadoEspacio = estado
        FROM dbo.espacios WITH (UPDLOCK, HOLDLOCK)
        WHERE id = @pEspacioId;

        IF @capacidad IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio indicado no existe.';
            RETURN 0;
        END;

        IF @pEstado IN (N'PENDIENTE', N'APROBADA') AND @estadoEspacio <> N'DISPONIBLE'
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio indicado no está disponible.';
            RETURN 0;
        END;

        IF @pParticipantes > @capacidad
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'La cantidad de participantes supera la capacidad del espacio.';
            RETURN 0;
        END;

        IF @pEstado IN (N'PENDIENTE', N'APROBADA')
           AND EXISTS
           (
               SELECT 1
               FROM dbo.reservas WITH (UPDLOCK, HOLDLOCK)
               WHERE espacioId = @pEspacioId
                 AND id <> @pId
                 AND estado IN (N'PENDIENTE', N'APROBADA')
                 AND @pFechaInicio < fechaFin
                 AND @pFechaFin > fechaInicio
           )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio ya tiene otra reserva activa en ese rango de fechas.';
            RETURN 0;
        END;

        UPDATE dbo.reservas
        SET codigo = LTRIM(RTRIM(@pCodigo)),
            espacioId = @pEspacioId,
            solicitantePerfilId = @pSolicitantePerfilId,
            creadoPorUsuarioId = @pCreadoPorUsuarioId,
            grupo = @pGrupo,
            responsable = LTRIM(RTRIM(@pResponsable)),
            telefono = LTRIM(RTRIM(@pTelefono)),
            email = LTRIM(RTRIM(@pEmail)),
            participantes = @pParticipantes,
            tipoActividad = LTRIM(RTRIM(@pTipoActividad)),
            fechaInicio = @pFechaInicio,
            fechaFin = @pFechaFin,
            estado = @pEstado,
            observaciones = @pObservaciones,
            updatedAt = SYSDATETIME()
        WHERE id = @pId;

        COMMIT TRANSACTION;
        SET @pResultado = 1;
        SET @pMensaje = N'Reserva actualizada correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @pResultado = 0;
        SET @pMensaje = LEFT(ERROR_MESSAGE(), 250);
        RETURN 0;
    END CATCH;
END;

GO
/* PROCEDIMIENTO: paReservaBuscarPorId */
CREATE PROCEDURE [dbo].[paReservaBuscarPorId]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    IF @pId IS NULL OR @pId <= 0 OR NOT EXISTS (SELECT 1 FROM dbo.reservas WHERE id = @pId)
    BEGIN
        SET @pMensaje = N'La reserva indicada no existe.';
        RETURN 0;
    END;

    SELECT
        r.id,
        r.codigo,
        r.espacioId,
        e.nombre AS espacio,
        r.solicitantePerfilId,
        p.nombre AS solicitante,
        r.creadoPorUsuarioId,
        u.email AS creadoPor,
        r.grupo,
        r.responsable,
        r.telefono,
        r.email,
        r.participantes,
        r.tipoActividad,
        r.fechaInicio,
        r.fechaFin,
        r.estado,
        r.observaciones,
        r.createdAt,
        r.updatedAt
    FROM dbo.reservas r
    INNER JOIN dbo.espacios e ON e.id = r.espacioId
    INNER JOIN dbo.perfilesUsuario p ON p.idPerfil = r.solicitantePerfilId
    LEFT JOIN dbo.usuarios u ON u.id = r.creadoPorUsuarioId
    WHERE r.id = @pId;

    SET @pResultado = 1;
    SET @pMensaje = N'Consulta realizada correctamente.';
    RETURN 1;
END;

GO
/* PROCEDIMIENTO: paReservaEliminar */
CREATE PROCEDURE [dbo].[paReservaEliminar]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY
        IF @pId IS NULL OR @pId <= 0
        BEGIN
            SET @pMensaje = N'El ID de la reserva debe ser mayor que cero.';
            RETURN 0;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.reservas WITH (UPDLOCK, HOLDLOCK) WHERE id = @pId)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'La reserva indicada no existe.';
            RETURN 0;
        END;

        IF EXISTS (SELECT 1 FROM dbo.pagos WITH (UPDLOCK, HOLDLOCK) WHERE reservaId = @pId)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'No se puede eliminar una reserva que tiene pagos registrados.';
            RETURN 0;
        END;

        DELETE FROM dbo.reservas WHERE id = @pId;
        COMMIT TRANSACTION;

        SET @pResultado = 1;
        SET @pMensaje = N'Reserva eliminada correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @pResultado = 0;
        SET @pMensaje = LEFT(ERROR_MESSAGE(), 250);
        RETURN 0;
    END CATCH;
END;

GO
/* PROCEDIMIENTO: paReservaFiltrar */
CREATE PROCEDURE [dbo].[paReservaFiltrar]
    @pCodigo NVARCHAR(20) = NULL,
    @pResponsable NVARCHAR(160) = NULL,
    @pEstado NVARCHAR(20) = NULL,
    @pEspacioId INT = NULL,
    @pSolicitantePerfilId INT = NULL,
    @pFechaDesde DATE = NULL,
    @pFechaHasta DATE = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT,
    @pCreadorUsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @pEstado IS NOT NULL
       AND @pEstado NOT IN (N'PENDIENTE', N'APROBADA', N'CANCELADA', N'FINALIZADA')
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'El estado indicado no es válido.';
        RETURN 0;
    END;

    IF @pEspacioId IS NOT NULL
       AND (@pEspacioId <= 0 OR NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE id = @pEspacioId))
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'El espacio indicado no existe.';
        RETURN 0;
    END;

    IF @pSolicitantePerfilId IS NOT NULL
       AND (@pSolicitantePerfilId <= 0 OR NOT EXISTS (SELECT 1 FROM dbo.perfilesUsuario WHERE idPerfil = @pSolicitantePerfilId))
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'El perfil solicitante indicado no existe.';
        RETURN 0;
    END;

    IF @pFechaDesde IS NOT NULL AND @pFechaHasta IS NOT NULL AND @pFechaDesde > @pFechaHasta
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'La fecha inicial no puede ser posterior a la fecha final.';
        RETURN 0;
    END;

    SELECT
        r.id,
        r.codigo,
        e.nombre AS espacio,
        p.nombre AS solicitante,
        r.responsable,
        r.participantes,
        r.tipoActividad,
        r.fechaInicio,
        r.fechaFin,
        r.estado
    FROM dbo.reservas r
    INNER JOIN dbo.espacios e ON e.id = r.espacioId
    INNER JOIN dbo.perfilesUsuario p ON p.idPerfil = r.solicitantePerfilId
    WHERE (@pCodigo IS NULL OR r.codigo LIKE N'%' + @pCodigo + N'%')
      AND (@pResponsable IS NULL OR r.responsable LIKE N'%' + @pResponsable + N'%')
      AND (@pEstado IS NULL OR r.estado = @pEstado)
      AND (@pEspacioId IS NULL OR r.espacioId = @pEspacioId)
      AND (@pSolicitantePerfilId IS NULL OR r.solicitantePerfilId = @pSolicitantePerfilId)
      AND (@pCreadorUsuarioId IS NULL OR r.creadoPorUsuarioId = @pCreadorUsuarioId OR p.usuarioId = @pCreadorUsuarioId)
      AND (@pFechaDesde IS NULL OR CONVERT(DATE, r.fechaInicio) >= @pFechaDesde)
      AND (@pFechaHasta IS NULL OR CONVERT(DATE, r.fechaFin) <= @pFechaHasta)
    ORDER BY r.fechaInicio DESC;

    SET @pResultado = 1;
    SET @pMensaje = N'Filtro realizado correctamente.';
    RETURN 1;
END;

GO



/* =========================================================
   PROCEDIMIENTO: paReservaDisponibilidad
   Consulta si un espacio está disponible en un rango
   de fecha y hora.
   ========================================================= */

CREATE PROCEDURE [dbo].[paReservaDisponibilidad]
    @pEspacioId INT,
    @pFechaInicio DATETIME2(0),
    @pFechaFin DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    IF @pEspacioId IS NULL
       OR @pEspacioId <= 0
    BEGIN
        THROW 50001, N'El espacio indicado no es válido.', 1;
    END;

    IF @pFechaInicio IS NULL
       OR @pFechaFin IS NULL
       OR @pFechaFin <= @pFechaInicio
    BEGIN
        THROW 50002, N'El rango de fechas no es válido.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.espacios
        WHERE id = @pEspacioId
    )
    BEGIN
        THROW 50003, N'El espacio indicado no existe.', 1;
    END;

    DECLARE @estadoEspacio NVARCHAR(20);

    SELECT
        @estadoEspacio = estado
    FROM dbo.espacios
    WHERE id = @pEspacioId;

    SELECT
        CAST(
            CASE
                WHEN @estadoEspacio <> N'DISPONIBLE'
                    THEN 0

                WHEN EXISTS (
                    SELECT 1
                    FROM dbo.reservas
                    WHERE espacioId = @pEspacioId
                      AND estado IN (
                          N'PENDIENTE',
                          N'APROBADA'
                      )
                      AND @pFechaInicio < fechaFin
                      AND @pFechaFin > fechaInicio
                )
                    THEN 0

                ELSE 1
            END
            AS BIT
        ) AS disponible;
END;
GO
/* PROCEDIMIENTO: paReservaInsertar */
/* ============================================================
   PROCEDIMIENTOS ALMACENADOS - TABLA: reservas
   CRUD + búsqueda + filtrado
   ============================================================ */

CREATE PROCEDURE [dbo].[paReservaInsertar]
    @pCodigo NVARCHAR(20),
    @pEspacioId INT,
    @pSolicitantePerfilId INT,
    @pCreadoPorUsuarioId INT = NULL,
    @pGrupo NVARCHAR(160) = NULL,
    @pResponsable NVARCHAR(160),
    @pTelefono NVARCHAR(30),
    @pEmail NVARCHAR(160),
    @pParticipantes INT,
    @pTipoActividad NVARCHAR(120),
    @pFechaInicio DATETIME2(0),
    @pFechaFin DATETIME2(0),
    @pEstado NVARCHAR(20) = N'PENDIENTE',
    @pObservaciones NVARCHAR(MAX) = NULL,
    @pIdGenerado INT OUTPUT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @pIdGenerado = NULL;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY
        IF NULLIF(LTRIM(RTRIM(@pCodigo)), N'') IS NULL OR LEN(@pCodigo) > 20
        BEGIN
            SET @pMensaje = N'El código es obligatorio y no puede superar 20 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pResponsable)), N'') IS NULL OR LEN(@pResponsable) > 160
        BEGIN
            SET @pMensaje = N'El responsable es obligatorio y no puede superar 160 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pTelefono)), N'') IS NULL OR LEN(@pTelefono) > 30
        BEGIN
            SET @pMensaje = N'El teléfono es obligatorio y no puede superar 30 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pEmail)), N'') IS NULL OR LEN(@pEmail) > 160 OR dbo.fnCorreoValido(LTRIM(RTRIM(@pEmail))) <> 1
        BEGIN
            SET @pMensaje = N'El correo es obligatorio y debe ser válido.';
            RETURN 0;
        END;

        IF @pParticipantes IS NULL OR @pParticipantes <= 0
        BEGIN
            SET @pMensaje = N'La cantidad de participantes debe ser mayor que cero.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pTipoActividad)), N'') IS NULL OR LEN(@pTipoActividad) > 120
        BEGIN
            SET @pMensaje = N'El tipo de actividad es obligatorio y no puede superar 120 caracteres.';
            RETURN 0;
        END;

        IF @pGrupo IS NOT NULL AND LEN(@pGrupo) > 160
        BEGIN
            SET @pMensaje = N'El grupo no puede superar 160 caracteres.';
            RETURN 0;
        END;

        IF @pFechaInicio IS NULL OR @pFechaFin IS NULL OR @pFechaFin <= @pFechaInicio
        BEGIN
            SET @pMensaje = N'La fecha final debe ser mayor que la fecha inicial.';
            RETURN 0;
        END;

        IF @pEstado NOT IN (N'PENDIENTE', N'APROBADA', N'CANCELADA', N'FINALIZADA')
        BEGIN
            SET @pMensaje = N'El estado de la reserva no es válido.';
            RETURN 0;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.perfilesUsuario WHERE idPerfil = @pSolicitantePerfilId)
        BEGIN
            SET @pMensaje = N'El perfil solicitante no existe.';
            RETURN 0;
        END;

        IF @pCreadoPorUsuarioId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.usuarios WHERE id = @pCreadoPorUsuarioId)
        BEGIN
            SET @pMensaje = N'El usuario creador no existe.';
            RETURN 0;
        END;

        IF EXISTS (SELECT 1 FROM dbo.reservas WHERE codigo = LTRIM(RTRIM(@pCodigo)))
        BEGIN
            SET @pMensaje = N'Ya existe una reserva con ese código.';
            RETURN 0;
        END;

        BEGIN TRANSACTION;

        DECLARE @capacidad INT;
        DECLARE @estadoEspacio NVARCHAR(20);

        SELECT
            @capacidad = capacidad,
            @estadoEspacio = estado
        FROM dbo.espacios WITH (UPDLOCK, HOLDLOCK)
        WHERE id = @pEspacioId;

        IF @capacidad IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio indicado no existe.';
            RETURN 0;
        END;

        IF @pEstado IN (N'PENDIENTE', N'APROBADA') AND @estadoEspacio <> N'DISPONIBLE'
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio indicado no está disponible.';
            RETURN 0;
        END;

        IF @pParticipantes > @capacidad
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'La cantidad de participantes supera la capacidad del espacio.';
            RETURN 0;
        END;

        IF @pEstado IN (N'PENDIENTE', N'APROBADA')
           AND EXISTS
           (
               SELECT 1
               FROM dbo.reservas WITH (UPDLOCK, HOLDLOCK)
               WHERE espacioId = @pEspacioId
                 AND estado IN (N'PENDIENTE', N'APROBADA')
                 AND @pFechaInicio < fechaFin
                 AND @pFechaFin > fechaInicio
           )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio ya tiene una reserva activa en ese rango de fechas.';
            RETURN 0;
        END;

        INSERT INTO dbo.reservas
        (
            codigo, espacioId, solicitantePerfilId, creadoPorUsuarioId,
            grupo, responsable, telefono, email, participantes, tipoActividad,
            fechaInicio, fechaFin, estado, observaciones
        )
        VALUES
        (
            LTRIM(RTRIM(@pCodigo)), @pEspacioId, @pSolicitantePerfilId, @pCreadoPorUsuarioId,
            @pGrupo, LTRIM(RTRIM(@pResponsable)), LTRIM(RTRIM(@pTelefono)), LTRIM(RTRIM(@pEmail)),
            @pParticipantes, LTRIM(RTRIM(@pTipoActividad)), @pFechaInicio, @pFechaFin,
            @pEstado, @pObservaciones
        );

        SET @pIdGenerado = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;

        SET @pResultado = 1;
        SET @pMensaje = N'Reserva insertada correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @pIdGenerado = NULL;
        SET @pResultado = 0;
        SET @pMensaje = LEFT(ERROR_MESSAGE(), 250);
        RETURN 0;
    END CATCH;
END;

GO

/* =========================================================
   PROCEDIMIENTO: paRolFiltrar
   Lista los roles disponibles
========================================================= */

CREATE PROCEDURE [dbo].[paRolFiltrar]
    @pNombre NVARCHAR(100) = NULL,
    @pDescripcion NVARCHAR(250) = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        SET @pNombre =
            NULLIF(
                LTRIM(RTRIM(@pNombre)),
                N''
            );

        SET @pDescripcion =
            NULLIF(
                LTRIM(RTRIM(@pDescripcion)),
                N''
            );

        SELECT
            r.id,
            r.nombre,
            r.descripcion,
            r.createdAt
        FROM dbo.roles AS r

        WHERE
            (
                @pNombre IS NULL
                OR r.nombre LIKE
                    N'%' + @pNombre + N'%'
            )

            AND
            (
                @pDescripcion IS NULL
                OR r.descripcion LIKE
                    N'%' + @pDescripcion + N'%'
            )

        ORDER BY
            r.nombre ASC;

        SET @pResultado = 1;

        SET @pMensaje =
            N'Consulta realizada correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;

        SET @pMensaje =
            LEFT(
                ERROR_MESSAGE(),
                250
            );

    END CATCH;
END;
GO
/* PROCEDIMIENTO: paUsuarioActualizar */
/* =========================================================
   ACTUALIZAR USUARIO
   La contraseña puede venir NULL.
   Si viene NULL conserva la contraseña anterior.
========================================================= */

CREATE PROCEDURE [dbo].[paUsuarioActualizar]
    @pId INT,
    @pRolId INT,
    @pEmail NVARCHAR(160),
    @pPasswordHash NVARCHAR(255) = NULL,
    @pEstado NVARCHAR(10),
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        IF @pId IS NULL
           OR @pId <= 0
           OR NOT EXISTS
           (
               SELECT 1
               FROM dbo.usuarios
               WHERE id = @pId
           )
        BEGIN
            SET @pMensaje =
                N'El usuario indicado no existe.';
            RETURN;
        END;

        IF @pRolId IS NULL
           OR @pRolId <= 0
           OR NOT EXISTS
           (
               SELECT 1
               FROM dbo.roles
               WHERE id = @pRolId
           )
        BEGIN
            SET @pMensaje =
                N'El rol indicado no existe.';
            RETURN;
        END;

        SET @pEmail =
            LTRIM(RTRIM(@pEmail));

        IF NULLIF(@pEmail, N'') IS NULL
           OR LEN(@pEmail) > 160
        BEGIN
            SET @pMensaje =
                N'El correo es obligatorio y no puede superar 160 caracteres.';
            RETURN;
        END;

        IF dbo.fnCorreoValido(@pEmail) <> 1
        BEGIN
            SET @pMensaje =
                N'El correo ingresado no es válido.';
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.usuarios
            WHERE email = @pEmail
              AND id <> @pId
        )
        BEGIN
            SET @pMensaje =
                N'Ya existe otro usuario con ese correo.';
            RETURN;
        END;

        IF @pPasswordHash IS NOT NULL
           AND
           (
               NULLIF(
                   LTRIM(RTRIM(@pPasswordHash)),
                   N''
               ) IS NULL
               OR LEN(@pPasswordHash) > 255
           )
        BEGIN
            SET @pMensaje =
                N'El hash de contraseña no es válido.';
            RETURN;
        END;

        IF @pEstado NOT IN
        (
            N'ACTIVO',
            N'INACTIVO'
        )
        BEGIN
            SET @pMensaje =
                N'El estado debe ser ACTIVO o INACTIVO.';
            RETURN;
        END;

        /* Evitar dejar el sistema sin administrador */

        DECLARE @esAdminActivo BIT = 0;
        DECLARE @nuevoRolEsAdmin BIT = 0;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.usuarios AS u
            INNER JOIN dbo.roles AS r
                ON r.id = u.rolId
            WHERE u.id = @pId
              AND u.estado = N'ACTIVO'
              AND r.nombre = N'Administrador'
        )
        BEGIN
            SET @esAdminActivo = 1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.roles
            WHERE id = @pRolId
              AND nombre = N'Administrador'
        )
        BEGIN
            SET @nuevoRolEsAdmin = 1;
        END;

        IF @esAdminActivo = 1
           AND
           (
               @nuevoRolEsAdmin = 0
               OR @pEstado <> N'ACTIVO'
           )
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.usuarios AS u
               INNER JOIN dbo.roles AS r
                   ON r.id = u.rolId
               WHERE u.id <> @pId
                 AND u.estado = N'ACTIVO'
                 AND r.nombre = N'Administrador'
           )
        BEGIN
            SET @pMensaje =
                N'No se puede dejar el sistema sin un administrador activo.';
            RETURN;
        END;

        UPDATE dbo.usuarios
        SET
            rolId = @pRolId,
            email = @pEmail,

            passwordHash =
                CASE
                    WHEN @pPasswordHash IS NULL
                        THEN passwordHash
                    ELSE @pPasswordHash
                END,

            estado = @pEstado,
            updatedAt = SYSDATETIME()
        WHERE id = @pId;

        SET @pResultado = 1;

        SET @pMensaje =
            N'Usuario actualizado correctamente.';

    END TRY
    BEGIN CATCH

        SET @pResultado = 0;

        SET @pMensaje =
            LEFT(
                ERROR_MESSAGE(),
                250
            );

    END CATCH;
END;
GO

/* =========================================================
   PROCEDIMIENTO: paUsuarioBuscarPorId
========================================================= */

CREATE PROCEDURE [dbo].[paUsuarioBuscarPorId]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        IF @pId IS NULL
           OR @pId <= 0
           OR NOT EXISTS
           (
               SELECT 1
               FROM dbo.usuarios
               WHERE id = @pId
           )
        BEGIN
            SET @pMensaje =
                N'El usuario indicado no existe.';
            RETURN;
        END;


        SELECT
            u.id,
            u.rolId,
            r.nombre AS rol,
            u.email,
            u.estado,
            u.createdAt,
            u.updatedAt

        FROM dbo.usuarios AS u

        INNER JOIN dbo.roles AS r
            ON r.id = u.rolId

        WHERE u.id = @pId;


        SET @pResultado = 1;

        SET @pMensaje =
            N'Usuario encontrado correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;

        SET @pMensaje =
            LEFT(
                ERROR_MESSAGE(),
                250
            );

    END CATCH;
END;
GO

/* =========================================================
   PROCEDIMIENTO: paUsuarioEliminar
========================================================= */

CREATE PROCEDURE [dbo].[paUsuarioEliminar]
    @pId INT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        /* -------------------------------
           VALIDAR USUARIO
        -------------------------------- */

        IF @pId IS NULL
           OR @pId <= 0
           OR NOT EXISTS
           (
               SELECT 1
               FROM dbo.usuarios
               WHERE id = @pId
           )
        BEGIN
            SET @pMensaje =
                N'El usuario indicado no existe.';
            RETURN;
        END;


        /* -------------------------------
           NO ELIMINAR ÚLTIMO ADMIN ACTIVO
        -------------------------------- */

        IF EXISTS
        (
            SELECT 1

            FROM dbo.usuarios AS u

            INNER JOIN dbo.roles AS r
                ON r.id = u.rolId

            WHERE u.id = @pId
              AND u.estado = N'ACTIVO'
              AND r.nombre = N'Administrador'
        )
        AND NOT EXISTS
        (
            SELECT 1

            FROM dbo.usuarios AS u

            INNER JOIN dbo.roles AS r
                ON r.id = u.rolId

            WHERE u.id <> @pId
              AND u.estado = N'ACTIVO'
              AND r.nombre = N'Administrador'
        )
        BEGIN

            SET @pMensaje =
                N'No se puede eliminar el último administrador activo.';

            RETURN;
        END;


        /* -------------------------------
           VALIDAR RELACIONES
        -------------------------------- */

        IF EXISTS
        (
            SELECT 1
            FROM dbo.perfilesUsuario
            WHERE usuarioId = @pId
        )
        BEGIN
            SET @pMensaje =
                N'No se puede eliminar el usuario porque tiene un perfil asociado.';
            RETURN;
        END;


        IF EXISTS
        (
            SELECT 1
            FROM dbo.reservas
            WHERE creadoPorUsuarioId = @pId
        )
        BEGIN
            SET @pMensaje =
                N'No se puede eliminar el usuario porque tiene reservas asociadas.';
            RETURN;
        END;


        /* -------------------------------
           ELIMINAR
        -------------------------------- */

        DELETE FROM dbo.usuarios
        WHERE id = @pId;


        SET @pResultado = 1;

        SET @pMensaje =
            N'Usuario eliminado correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;

        SET @pMensaje =
            LEFT(
                ERROR_MESSAGE(),
                250
            );

    END CATCH;
END;
GO

/* =========================================================
   PROCEDIMIENTO: paUsuarioFiltrar
   Lista y filtra los usuarios del sistema
========================================================= */

CREATE PROCEDURE [dbo].[paUsuarioFiltrar]
    @pEmail NVARCHAR(160) = NULL,
    @pRolId INT = NULL,
    @pEstado NVARCHAR(10) = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        SET @pEmail =
            NULLIF(
                LTRIM(RTRIM(@pEmail)),
                N''
            );

        SET @pEstado =
            NULLIF(
                LTRIM(RTRIM(@pEstado)),
                N''
            );

        IF @pEstado IS NOT NULL
           AND @pEstado NOT IN
           (
               N'ACTIVO',
               N'INACTIVO'
           )
        BEGIN
            SET @pMensaje =
                N'El estado debe ser ACTIVO o INACTIVO.';
            RETURN;
        END;

        IF @pRolId IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM dbo.roles
               WHERE id = @pRolId
           )
        BEGIN
            SET @pMensaje =
                N'El rol indicado no existe.';
            RETURN;
        END;

        SELECT
            u.id,
            u.rolId,
            r.nombre AS rol,
            u.email,
            u.estado,
            u.createdAt,
            u.updatedAt
        FROM dbo.usuarios AS u

        INNER JOIN dbo.roles AS r
            ON r.id = u.rolId

        WHERE
            (
                @pEmail IS NULL
                OR u.email LIKE
                    N'%' + @pEmail + N'%'
            )

            AND
            (
                @pRolId IS NULL
                OR u.rolId = @pRolId
            )

            AND
            (
                @pEstado IS NULL
                OR u.estado = @pEstado
            )

        ORDER BY
            u.id DESC;

        SET @pResultado = 1;

        SET @pMensaje =
            N'Consulta realizada correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;

        SET @pMensaje =
            LEFT(
                ERROR_MESSAGE(),
                250
            );

    END CATCH;
END;
GO

/* =========================================================
   PROCEDIMIENTO: paUsuarioInsertar
   Crea un nuevo usuario
========================================================= */

CREATE PROCEDURE [dbo].[paUsuarioInsertar]
    @pRolId INT,
    @pEmail NVARCHAR(160),
    @pPasswordHash NVARCHAR(255),
    @pEstado NVARCHAR(10) = N'ACTIVO',
    @pIdGenerado INT OUTPUT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pIdGenerado = NULL;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        /* -------------------------------
           VALIDAR ROL
        -------------------------------- */

        IF @pRolId IS NULL
           OR @pRolId <= 0
           OR NOT EXISTS
           (
               SELECT 1
               FROM dbo.roles
               WHERE id = @pRolId
           )
        BEGIN
            SET @pMensaje =
                N'El rol indicado no existe.';
            RETURN;
        END;


        /* -------------------------------
           VALIDAR CORREO
        -------------------------------- */

        SET @pEmail =
            LTRIM(RTRIM(@pEmail));

        IF NULLIF(@pEmail, N'') IS NULL
           OR LEN(@pEmail) > 160
        BEGIN
            SET @pMensaje =
                N'El correo es obligatorio.';
            RETURN;
        END;

        IF @pEmail NOT LIKE N'%_@_%._%'
        BEGIN
            SET @pMensaje =
                N'El correo ingresado no es válido.';
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.usuarios
            WHERE email = @pEmail
        )
        BEGIN
            SET @pMensaje =
                N'Ya existe un usuario con ese correo.';
            RETURN;
        END;


        /* -------------------------------
           VALIDAR CONTRASEÑA HASH
        -------------------------------- */

        IF @pPasswordHash IS NULL
           OR NULLIF(
               LTRIM(RTRIM(@pPasswordHash)),
               N''
           ) IS NULL
        BEGIN
            SET @pMensaje =
                N'La contraseña es obligatoria.';
            RETURN;
        END;


        /* -------------------------------
           VALIDAR ESTADO
        -------------------------------- */

        IF @pEstado NOT IN
        (
            N'ACTIVO',
            N'INACTIVO'
        )
        BEGIN
            SET @pMensaje =
                N'El estado debe ser ACTIVO o INACTIVO.';
            RETURN;
        END;


        /* -------------------------------
           INSERTAR
        -------------------------------- */

        INSERT INTO dbo.usuarios
        (
            rolId,
            email,
            passwordHash,
            estado
        )
        VALUES
        (
            @pRolId,
            @pEmail,
            @pPasswordHash,
            @pEstado
        );


        SET @pIdGenerado =
            CONVERT(
                INT,
                SCOPE_IDENTITY()
            );

        SET @pResultado = 1;

        SET @pMensaje =
            N'Usuario creado correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;

        SET @pMensaje =
            LEFT(
                ERROR_MESSAGE(),
                250
            );

    END CATCH;
END;
GO
/* PROCEDIMIENTO: paUsuarioLogin */
CREATE PROCEDURE [dbo].[paUsuarioLogin]
    @pEmail NVARCHAR(160)
AS
BEGIN
    SET NOCOUNT ON;

    SET @pEmail = LTRIM(RTRIM(@pEmail));

    SELECT
        u.id,
        u.email,
        u.passwordHash,
        u.estado,
        u.rolId,
        r.nombre AS rol
    FROM dbo.usuarios AS u
    INNER JOIN dbo.roles AS r
        ON r.id = u.rolId
    WHERE u.email = @pEmail;
END;
GO
/* Procedimiento: estado de salud de la base de datos */
CREATE PROCEDURE [dbo].[paSistemaEstado]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        DB_NAME() AS baseDatos,
        COUNT(*) AS cantidadEspacios
    FROM dbo.espacios;
END;
GO
/* Procedimiento: registrar eventos de autenticación */
CREATE PROCEDURE [dbo].[paAuditoriaAccesoRegistrar]
    @pUsuarioId INT = NULL,
    @pEvento NVARCHAR(20),
    @pDireccionIp VARCHAR(45) = NULL,
    @pAgenteUsuario NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.auditoriaAccesos
        (usuarioId, evento, direccionIp, agenteUsuario, creadoEn)
    VALUES
        (@pUsuarioId, @pEvento, @pDireccionIp, @pAgenteUsuario, SYSDATETIME());
END;
GO
/* Procedimiento: resumen de auditoría */
CREATE PROCEDURE [dbo].[paAuditoriaResumen]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT origen, evento, totalEventos, ultimoEvento
    FROM dbo.vAuditoriaResumen
    ORDER BY ultimoEvento DESC, origen, evento;
END;
GO

/* Procedimiento: historial detallado de auditoría */
CREATE PROCEDURE [dbo].[paAuditoriaDetalle]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (500)
        eventos.idAuditoria,
        eventos.origen,
        eventos.evento,
        eventos.registroId,
        eventos.usuario,
        eventos.usuarioBd,
        eventos.detalle,
        eventos.valoresAnteriores,
        eventos.valoresNuevos,
        eventos.creadoEn

    FROM
    (
        /* Cambios generales */
        SELECT
            ar.idAuditoria,
            ar.tabla COLLATE DATABASE_DEFAULT AS origen,
            ar.accion COLLATE DATABASE_DEFAULT AS evento,
            ar.idRegistro AS registroId,

            COALESCE(
                NULLIF(ar.usuarioAppNombre, N''),
                NULLIF(ar.usuarioBd, N''),
                N'No identificado'
            ) AS usuario,

            ar.usuarioBd,
            ar.detalle,

            CASE
                WHEN ISJSON(ar.detalle) = 1
                THEN JSON_QUERY(ar.detalle, '$.antes')
                ELSE NULL
            END AS valoresAnteriores,

            CASE
                WHEN ISJSON(ar.detalle) = 1
                THEN JSON_QUERY(ar.detalle, '$.despues')
                ELSE NULL
            END AS valoresNuevos,

            ar.creadoEn

        FROM dbo.auditoriaReservas AS ar


        UNION ALL


        /* Cambios de pagos */
        SELECT
            ap.idAuditoriaPago,
            N'pagos',
            ap.accion COLLATE DATABASE_DEFAULT,
            ap.pagoId,

            COALESCE(
                NULLIF(ap.usuarioAppNombre, N''),
                NULLIF(ap.usuarioBd, N''),
                N'No identificado'
            ),

            ap.usuarioBd,

            CONCAT(
                N'Reserva asociada: ',
                COALESCE(
                    CONVERT(NVARCHAR(20), ap.reservaId),
                    N'No indicada'
                )
            ),

            ap.valoresAnteriores,
            ap.valoresNuevos,
            ap.creadoEn

        FROM dbo.auditoriaPagos AS ap


        UNION ALL


        /* Accesos, respaldo y restauración */
        SELECT
            aa.idAuditoriaAcceso,
            N'accesos',
            aa.evento COLLATE DATABASE_DEFAULT,
            aa.usuarioId,

            COALESCE(
                u.email,
                N'No identificado'
            ),

            CAST(NULL AS NVARCHAR(120)),

            CONCAT(
                N'IP: ',
                COALESCE(
                    CONVERT(NVARCHAR(45), aa.direccionIp),
                    N'No disponible'
                ),
                N' | Navegador: ',
                COALESCE(
                    aa.agenteUsuario,
                    N'No disponible'
                )
            ),

            CAST(NULL AS NVARCHAR(MAX)),
            CAST(NULL AS NVARCHAR(MAX)),
            aa.creadoEn

        FROM dbo.auditoriaAccesos AS aa

        LEFT JOIN dbo.usuarios AS u
            ON u.id = aa.usuarioId

    ) AS eventos

    ORDER BY
        eventos.creadoEn DESC,
        eventos.idAuditoria DESC;
END;
GO
/* Procedimientos: catálogo de respaldos creados por la aplicación */
CREATE PROCEDURE [dbo].[paRespaldoListar]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nombreArchivo AS nombre, creadoEn, bytes
    FROM dbo.respaldoHistorial
    ORDER BY creadoEn DESC, idRespaldo DESC;
END;
GO
CREATE PROCEDURE [dbo].[paRespaldoRegistrar]
    @pNombreArchivo NVARCHAR(120),
    @pUsuarioId INT = NULL,
    @pCreadoEn DATETIME2(0),
    @pBytes BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF @pNombreArchivo NOT LIKE N'reservasScouts[_]%.bak'
       OR @pBytes < 0
       OR @pCreadoEn IS NULL
        THROW 50031, N'Metadatos de respaldo no válidos.', 1;

    IF EXISTS (SELECT 1 FROM dbo.respaldoHistorial WHERE nombreArchivo = @pNombreArchivo)
        UPDATE dbo.respaldoHistorial
        SET creadoPorUsuarioId = @pUsuarioId, creadoEn = @pCreadoEn, bytes = @pBytes
        WHERE nombreArchivo = @pNombreArchivo;
    ELSE
        INSERT dbo.respaldoHistorial (nombreArchivo, creadoPorUsuarioId, creadoEn, bytes)
        VALUES (@pNombreArchivo, @pUsuarioId, @pCreadoEn, @pBytes);
END;
GO
/* Procedimiento: crear respaldo completo de reservasScouts */
CREATE PROCEDURE [dbo].[paRespaldoCompleto]
    @pRuta NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    IF @pRuta IS NULL OR LTRIM(RTRIM(@pRuta)) = N''
    BEGIN
        THROW 50040, N'La ruta del respaldo es obligatoria.', 1;
    END;

    BACKUP DATABASE [reservasScouts]
    TO DISK = @pRuta
    WITH
        COPY_ONLY,
        CHECKSUM,
        COMPRESSION,
        INIT;

    RESTORE VERIFYONLY
    FROM DISK = @pRuta
    WITH CHECKSUM;
END;
GO

GRANT EXECUTE
ON OBJECT::dbo.paRespaldoCompleto
TO [reservas_maintenance];
GO

/* Procedimiento: opciones mínimas de perfil para crear reservas */
CREATE PROCEDURE [dbo].[paReservaFechasOcupadas]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT espacioId, fechaInicio, fechaFin
    FROM dbo.reservas
    WHERE estado IN (N'PENDIENTE', N'APROBADA')
    ORDER BY espacioId, fechaInicio;
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paReservaFechasOcupadas TO reservas_app;
GO

CREATE PROCEDURE dbo.paPerfilOpcionesReserva
    @pUsuarioId INT = NULL,
    @pUsuarioContactoId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idPerfil, nombre, tipoPerfil, usuarioId,
        CASE WHEN usuarioId = @pUsuarioContactoId THEN telefono END AS telefono,
        CASE WHEN usuarioId = @pUsuarioContactoId THEN correoContacto END AS correoContacto
    FROM dbo.perfilesUsuario
    WHERE @pUsuarioId IS NULL OR usuarioId = @pUsuarioId
    ORDER BY nombre;
END;
GO
/* Trigger: auditoría de cambios en espacios */
/* =========================================================
   7. TRIGGERS DE AUDITORÍA
   ========================================================= */

CREATE TRIGGER [dbo].[trgEspaciosAuditoria]
ON [dbo].[espacios]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuarioBd NVARCHAR(120) = LEFT(ORIGINAL_LOGIN(), 120);

    INSERT INTO dbo.auditoriaReservas
    (
        tabla, idRegistro, accion, detalle,
        usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn
    )
    SELECT
        N'espacios',
        COALESCE(i.id, d.id),
        CASE
            WHEN d.id IS NULL THEN N'INSERT'
            WHEN i.id IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        (
            SELECT
                JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.nombre, d.ubicacion, d.capacidad, d.costo, d.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.nombre, i.ubicacion, i.capacidad, i.costo, i.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS despues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),
        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),
        @usuarioBd,
        SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.id = i.id;
END;
GO
/* Trigger: auditoría de cambios en perfiles */
CREATE TRIGGER [dbo].[trgPerfilesUsuarioAuditoria]
ON [dbo].[perfilesUsuario]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuarioBd NVARCHAR(120) = LEFT(ORIGINAL_LOGIN(), 120);

    INSERT INTO dbo.auditoriaReservas
    (
        tabla, idRegistro, accion, detalle,
        usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn
    )
    SELECT
        N'perfilesUsuario',
        COALESCE(i.idPerfil, d.idPerfil),
        CASE
            WHEN d.idPerfil IS NULL THEN N'INSERT'
            WHEN i.idPerfil IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        (
            SELECT
                JSON_QUERY(CASE WHEN d.idPerfil IS NOT NULL THEN
                    (SELECT d.usuarioId, d.tipoPerfil
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS antes,
                JSON_QUERY(CASE WHEN i.idPerfil IS NOT NULL THEN
                    (SELECT i.usuarioId, i.tipoPerfil
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS despues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),
        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),
        @usuarioBd,
        SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.idPerfil = i.idPerfil;
END;
GO
/* Trigger: auditoría de cambios en usuarios (sin credenciales ni correo) */
CREATE TRIGGER [dbo].[trgUsuariosAuditoria]
ON [dbo].[usuarios]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuarioBd NVARCHAR(120) = LEFT(ORIGINAL_LOGIN(), 120);

    INSERT INTO dbo.auditoriaReservas
    (
        tabla, idRegistro, accion, detalle,
        usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn
    )
    SELECT
        N'usuarios',
        COALESCE(i.id, d.id),
        CASE
            WHEN d.id IS NULL THEN N'INSERT'
            WHEN i.id IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        (
            SELECT
                JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.rolId, d.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.rolId, i.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS despues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),
        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),
        @usuarioBd,
        SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.id = i.id;
END;
GO
/* Trigger: auditoría de cambios en reservas (sin datos de contacto) */
CREATE TRIGGER [dbo].[trgReservasAuditoria]
ON [dbo].[reservas]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuarioBd NVARCHAR(120) = LEFT(ORIGINAL_LOGIN(), 120);

    INSERT INTO dbo.auditoriaReservas
    (
        tabla, idRegistro, accion, detalle,
        usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn
    )
    SELECT
        N'reservas',
        COALESCE(i.id, d.id),
        CASE
            WHEN d.id IS NULL THEN N'INSERT'
            WHEN i.id IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        (
            SELECT
                JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.codigo, d.espacioId, d.solicitantePerfilId,
                            d.fechaInicio, d.fechaFin, d.estado, d.participantes
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.codigo, i.espacioId, i.solicitantePerfilId,
                            i.fechaInicio, i.fechaFin, i.estado, i.participantes
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS despues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),
        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),
        @usuarioBd,
        SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.id = i.id;
END;
GO
/* Trigger: auditoría de cambios en pagos */
CREATE TRIGGER [dbo].[trgPagosAuditoria]
ON [dbo].[pagos]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.auditoriaPagos
    (
        pagoId,
        reservaId,
        accion,
        valoresAnteriores,
        valoresNuevos,
        usuarioAppId,
        usuarioAppNombre,
        usuarioBd,
        creadoEn
    )
    SELECT
        COALESCE(i.id, d.id),

        COALESCE(i.reservaId, d.reservaId),

        CASE
            WHEN d.id IS NULL THEN N'INSERT'
            WHEN i.id IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,

        CASE
            WHEN d.id IS NOT NULL THEN
            (
                SELECT
                    d.reservaId,
                    d.monto,
                    d.metodo,
                    d.fechaPago,
                    d.estado,
                    d.comprobante
                FOR JSON PATH,
                    WITHOUT_ARRAY_WRAPPER,
                    INCLUDE_NULL_VALUES
            )
            ELSE NULL
        END,

        CASE
            WHEN i.id IS NOT NULL THEN
            (
                SELECT
                    i.reservaId,
                    i.monto,
                    i.metodo,
                    i.fechaPago,
                    i.estado,
                    i.comprobante
                FOR JSON PATH,
                    WITHOUT_ARRAY_WRAPPER,
                    INCLUDE_NULL_VALUES
            )
            ELSE NULL
        END,

        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),

        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),

        LEFT(ORIGINAL_LOGIN(), 120),

        SYSDATETIME()

    FROM inserted AS i

    FULL OUTER JOIN deleted AS d
        ON d.id = i.id;
END;
GO
/* =========================================================
   8. DATOS INICIALES PARA PRUEBAS DEL SISTEMA
   ========================================================= */

/* ---------------------------------------------------------
   USUARIOS DE APLICACIÓN
   Estas cuentas también sirven como cuentas asociadas
   a reservas_app y reservas_consulta.
   --------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1
    FROM dbo.usuarios
    WHERE email = N'admin@reservasscouts.test'
)
BEGIN
    INSERT INTO dbo.usuarios
    (
        rolId,
        email,
        passwordHash,
        estado
    )
    VALUES
    (
        (
            SELECT TOP 1 id
            FROM dbo.roles
            WHERE nombre = N'Administrador'
        ),
        N'admin@reservasscouts.test',
        N'$2y$10$Y.R2Fn6/mGY8/y89r4wBjuYHtr1S9nm9R/vnFXmY8wfhAlb1BKg6q',
        N'ACTIVO'
    );
END;
GO


IF NOT EXISTS (
    SELECT 1
    FROM dbo.usuarios
    WHERE email = N'usuario@reservasscouts.test'
)
BEGIN
    INSERT INTO dbo.usuarios
    (
        rolId,
        email,
        passwordHash,
        estado
    )
    VALUES
    (
        (
            SELECT TOP 1 id
            FROM dbo.roles
            WHERE nombre = N'Usuario'
        ),
        N'usuario@reservasscouts.test',
        N'$2y$10$d1Br75ptBgWp1AYtRz/CMuoPaj0LLyRBOhD1YaTB6v4j88S/TfaK.',
        N'ACTIVO'
    );
END;
GO


/* ---------------------------------------------------------
   PERFILES DE PRUEBA
   --------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1
    FROM dbo.perfilesUsuario
    WHERE identificacion = N'DEMO-ADMIN-001'
)
BEGIN
    INSERT INTO dbo.perfilesUsuario
    (
        usuarioId,
        nombre,
        identificacion,
        telefono,
        correoContacto,
        tipoPerfil,
        direccion
    )
    VALUES
    (
        (
            SELECT id
            FROM dbo.usuarios
            WHERE email = N'admin@reservasscouts.test'
        ),
        N'Administrador Demo',
        N'DEMO-ADMIN-001',
        N'8888-0001',
        N'admin@reservasscouts.test',
        N'Persona',
        N'Liberia, Guanacaste'
    );
END;
GO


IF NOT EXISTS (
    SELECT 1
    FROM dbo.perfilesUsuario
    WHERE identificacion = N'DEMO-USUARIO-001'
)
BEGIN
    INSERT INTO dbo.perfilesUsuario
    (
        usuarioId,
        nombre,
        identificacion,
        telefono,
        correoContacto,
        tipoPerfil,
        direccion
    )
    VALUES
    (
        (
            SELECT id
            FROM dbo.usuarios
            WHERE email = N'usuario@reservasscouts.test'
        ),
        N'Usuario Demo',
        N'DEMO-USUARIO-001',
        N'8888-0002',
        N'usuario@reservasscouts.test',
        N'Persona',
        N'Liberia, Guanacaste'
    );
END;
GO


/* ---------------------------------------------------------
   ESPACIOS DE PRUEBA
   --------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1
    FROM dbo.espacios
    WHERE nombre = N'Campo Demo'
)
BEGIN
    INSERT INTO dbo.espacios
    (
        nombre,
        descripcion,
        ubicacion,
        capacidad,
        costo,
        estado
    )
    VALUES
    (
        N'Campo Demo',
        N'Espacio de prueba para reservas.',
        N'Liberia',
        100,
        100000,
        N'DISPONIBLE'
    );
END;
GO


IF NOT EXISTS (
    SELECT 1
    FROM dbo.espacios
    WHERE nombre = N'Salón Demo'
)
BEGIN
    INSERT INTO dbo.espacios
    (
        nombre,
        descripcion,
        ubicacion,
        capacidad,
        costo,
        estado
    )
    VALUES
    (
        N'Salón Demo',
        N'Salón utilizado para pruebas del sistema.',
        N'Liberia',
        50,
        75000,
        N'DISPONIBLE'
    );
END;
GO


/* ---------------------------------------------------------
   RESERVAS DE PRUEBA
   --------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1
    FROM dbo.reservas
    WHERE codigo = N'DEMO-RES-001'
)
BEGIN
    INSERT INTO dbo.reservas
    (
        codigo,
        espacioId,
        solicitantePerfilId,
        creadoPorUsuarioId,
        grupo,
        responsable,
        telefono,
        email,
        participantes,
        tipoActividad,
        fechaInicio,
        fechaFin,
        estado,
        observaciones
    )
    VALUES
    (
        N'DEMO-RES-001',

        (
            SELECT TOP 1 id
            FROM dbo.espacios
            WHERE nombre = N'Campo Demo'
        ),

        (
            SELECT TOP 1 idPerfil
            FROM dbo.perfilesUsuario
            WHERE identificacion = N'DEMO-USUARIO-001'
        ),

        (
            SELECT TOP 1 id
            FROM dbo.usuarios
            WHERE email = N'admin@reservasscouts.test'
        ),

        N'Grupo Demo',
        N'Usuario Demo',
        N'8888-0002',
        N'usuario@reservasscouts.test',
        25,
        N'Actividad Scout',
        DATEADD(DAY, 7, SYSDATETIME()),
        DATEADD(HOUR, 4, DATEADD(DAY, 7, SYSDATETIME())),
        N'APROBADA',
        N'Reserva de prueba.'
    );
END;
GO


IF NOT EXISTS (
    SELECT 1
    FROM dbo.reservas
    WHERE codigo = N'DEMO-RES-002'
)
BEGIN
    INSERT INTO dbo.reservas
    (
        codigo,
        espacioId,
        solicitantePerfilId,
        creadoPorUsuarioId,
        grupo,
        responsable,
        telefono,
        email,
        participantes,
        tipoActividad,
        fechaInicio,
        fechaFin,
        estado,
        observaciones
    )
    VALUES
    (
        N'DEMO-RES-002',

        (
            SELECT TOP 1 id
            FROM dbo.espacios
            WHERE nombre = N'Salón Demo'
        ),

        (
            SELECT TOP 1 idPerfil
            FROM dbo.perfilesUsuario
            WHERE identificacion = N'DEMO-USUARIO-001'
        ),

        (
            SELECT TOP 1 id
            FROM dbo.usuarios
            WHERE email = N'admin@reservasscouts.test'
        ),

        N'Grupo Demo',
        N'Usuario Demo',
        N'8888-0002',
        N'usuario@reservasscouts.test',
        20,
        N'Reunión Scout',
        DATEADD(DAY, 14, SYSDATETIME()),
        DATEADD(HOUR, 3, DATEADD(DAY, 14, SYSDATETIME())),
        N'PENDIENTE',
        N'Reserva de prueba.'
    );
END;
GO


/* ---------------------------------------------------------
   PAGOS DE PRUEBA
   --------------------------------------------------------- */

IF NOT EXISTS (
    SELECT 1
    FROM dbo.pagos AS p
    INNER JOIN dbo.reservas AS r
        ON r.id = p.reservaId
    WHERE r.codigo = N'DEMO-RES-001'
)
BEGIN
    INSERT INTO dbo.pagos
    (
        reservaId,
        monto,
        metodo,
        fechaPago,
        estado,
        comprobante,
        notas
    )
    VALUES
    (
        (
            SELECT TOP 1 id
            FROM dbo.reservas
            WHERE codigo = N'DEMO-RES-001'
        ),
        50000,
        N'SINPE Móvil',
        CONVERT(DATE, SYSDATETIME()),
        N'PAGADO',
        N'DEMO-PAGO-001',
        N'Pago de prueba.'
    );
END;
GO


/* =========================================================
   9. RESTAURACIÓN DE LA BASE DE DATOS
   ========================================================= */

USE [master]
GO

/* Procedimiento: restaurar la base reservasScouts */
CREATE OR ALTER PROCEDURE [dbo].[paRestaurarReservasScouts]
    @pRuta NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    IF @pRuta IS NULL OR LTRIM(RTRIM(@pRuta)) = N''
    BEGIN
        THROW 50041, N'La ruta del respaldo es obligatoria.', 1;
    END;

    RESTORE VERIFYONLY
    FROM DISK = @pRuta
    WITH CHECKSUM;

    BEGIN TRY
        ALTER DATABASE [reservasScouts]
        SET SINGLE_USER
        WITH ROLLBACK IMMEDIATE;

        RESTORE DATABASE [reservasScouts]
        FROM DISK = @pRuta
        WITH
            REPLACE,
            RECOVERY,
            CHECKSUM;

        ALTER DATABASE [reservasScouts]
        SET MULTI_USER;
    END TRY
    BEGIN CATCH
        IF DB_ID(N'reservasScouts') IS NOT NULL
        BEGIN
            ALTER DATABASE [reservasScouts]
            SET MULTI_USER;
        END;

        THROW;
    END CATCH;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'reservas_maintenance') IS NULL
BEGIN
    CREATE USER [reservas_maintenance]
    FOR LOGIN [reservas_maintenance];
END;
GO

GRANT EXECUTE
ON OBJECT::dbo.paRestaurarReservasScouts
TO [reservas_maintenance];
GO

ALTER DATABASE [reservasScouts] SET READ_WRITE
GO


GO
-- Flujo de pago y bloqueos temporales (migracion 010).
USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('dbo.reservaBloqueos') IS NULL
BEGIN
    CREATE TABLE dbo.reservaBloqueos (
        token UNIQUEIDENTIFIER PRIMARY KEY,
        usuarioId INT NOT NULL REFERENCES dbo.usuarios(id),
        espacioId INT NOT NULL REFERENCES dbo.espacios(id),
        fechaInicio DATETIME2(0) NOT NULL,
        fechaFin DATETIME2(0) NOT NULL,
        vence DATETIME2(3) NOT NULL,
        CONSTRAINT ckBloqueoFechas CHECK(fechaFin > fechaInicio)
    );
    CREATE INDEX ixBloqueoEspacio ON dbo.reservaBloqueos(espacioId, vence);
END;
IF OBJECT_ID('dbo.pagoComprobantes') IS NULL
BEGIN
    CREATE TABLE dbo.pagoComprobantes (
        pagoId INT PRIMARY KEY REFERENCES dbo.pagos(id) ON DELETE CASCADE,
        nombre NVARCHAR(200) NOT NULL,
        tipo NVARCHAR(60) NOT NULL,
        contenido VARBINARY(MAX) NOT NULL
    );
END;
GO
CREATE OR ALTER PROCEDURE dbo.paBloqueoComprobar
    @espacioId INT, @inicio DATETIME2(0), @fin DATETIME2(0), @usuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @resultado INT, @recurso NVARCHAR(255) = CONCAT(N'reserva-espacio-', @espacioId);
    EXEC @resultado=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
    IF @resultado < 0 THROW 51010, N'El espacio está siendo consultado. Intenta nuevamente.', 1;
    IF EXISTS (SELECT 1 FROM dbo.reservaBloqueos WHERE espacioId=@espacioId AND vence>SYSUTCDATETIME()
        AND usuarioId<>ISNULL(@usuarioId,-1) AND @inicio<fechaFin AND @fin>fechaInicio)
        THROW 51011, N'Espacio no disponible: otro usuario está completando su reserva.', 1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paBloqueoCrear
    @usuarioId INT, @espacioId INT, @inicio DATETIME2(0), @fin DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @inicio IS NULL OR @fin IS NULL OR @fin<=@inicio
            THROW 51012, N'Indica un rango de fechas válido.', 1;
        IF CAST(@inicio AS DATE)<CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE)
            THROW 51013, N'Solo se permiten reservas desde hoy.', 1;
        EXEC dbo.paBloqueoComprobar @espacioId,@inicio,@fin,@usuarioId;
        IF NOT EXISTS(SELECT 1 FROM dbo.espacios WHERE id=@espacioId AND estado=N'DISPONIBLE')
            THROW 51014, N'Espacio no disponible.', 1;
        IF EXISTS(SELECT 1 FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE espacioId=@espacioId
            AND estado IN(N'PENDIENTE',N'APROBADA') AND @inicio<fechaFin AND @fin>fechaInicio)
            THROW 51015, N'Espacio no disponible.', 1;
        DECLARE @token UNIQUEIDENTIFIER, @vence DATETIME2(3);
        SELECT @token=token,@vence=vence FROM dbo.reservaBloqueos
            WHERE usuarioId=@usuarioId AND espacioId=@espacioId AND fechaInicio=@inicio AND fechaFin=@fin AND vence>SYSUTCDATETIME();
        IF @token IS NULL
        BEGIN
            DELETE FROM dbo.reservaBloqueos WHERE usuarioId=@usuarioId OR vence<=SYSUTCDATETIME();
            SET @token=NEWID();
            SET @vence=DATEADD(SECOND,120,SYSUTCDATETIME());
            INSERT dbo.reservaBloqueos VALUES(@token,@usuarioId,@espacioId,@inicio,@fin,@vence);
        END;
        SELECT CONVERT(VARCHAR(36),@token) AS token, @vence AS vence, SYSUTCDATETIME() AS ahora;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paBloqueoValidar
    @token UNIQUEIDENTIFIER, @usuarioId INT, @espacioId INT, @inicio DATETIME2(0), @fin DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paBloqueoComprobar @espacioId,@inicio,@fin,@usuarioId;
    IF NOT EXISTS(SELECT 1 FROM dbo.reservaBloqueos WITH(UPDLOCK,HOLDLOCK) WHERE token=@token AND usuarioId=@usuarioId
        AND espacioId=@espacioId AND fechaInicio=@inicio AND fechaFin=@fin AND vence>SYSUTCDATETIME())
        THROW 51016, N'El plazo de dos minutos terminó. Selecciona nuevamente las fechas disponibles.', 1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paBloqueoLiberar @token UNIQUEIDENTIFIER, @usuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.reservaBloqueos WHERE token=@token AND usuarioId=@usuarioId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paBloqueoListar @usuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT espacioId,fechaInicio,fechaFin FROM dbo.reservaBloqueos
        WHERE usuarioId<>@usuarioId AND vence>SYSUTCDATETIME();
END;
GO
CREATE OR ALTER PROCEDURE dbo.paComprobanteGuardar
    @pagoId INT, @nombre NVARCHAR(200), @tipo NVARCHAR(60), @contenido VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.pagoComprobantes VALUES(@pagoId,@nombre,@tipo,@contenido);
END;
GO
CREATE OR ALTER PROCEDURE dbo.paComprobanteLeer @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nombre,tipo,contenido FROM dbo.pagoComprobantes WHERE pagoId=@pagoId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoVerificar @pagoId INT, @aprobar BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @reservaId INT;
    SELECT @reservaId=reservaId FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE id=@pagoId
        AND estado=N'PENDIENTE' AND metodo IN(N'SINPE Móvil',N'Transferencia bancaria',N'Efectivo');
    IF @reservaId IS NULL THROW 51017, N'El pago ya fue revisado o no admite verificación.', 1;
    IF EXISTS(SELECT 1 FROM dbo.reservas WHERE id=@reservaId AND estado=N'CANCELADA')
        THROW 51018, N'La reserva está cancelada.', 1;
    IF @aprobar=1
    BEGIN
        IF (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reservaId AND estado=N'PAGADO')
            + (SELECT monto FROM dbo.pagos WHERE id=@pagoId) >
            (SELECT e.costo FROM dbo.espacios e JOIN dbo.reservas r ON r.espacioId=e.id WHERE r.id=@reservaId)
            THROW 51019, N'El pago supera el costo de la reserva.', 1;
    END;
    UPDATE dbo.pagos SET estado=CASE WHEN @aprobar=1 THEN N'PAGADO' ELSE N'RECHAZADO' END,updatedAt=SYSDATETIME() WHERE id=@pagoId;
    UPDATE dbo.reservas SET estado=CASE WHEN @aprobar=1 THEN N'APROBADA' ELSE N'CANCELADA' END,updatedAt=SYSDATETIME() WHERE id=@reservaId;
END;
GO
GRANT EXECUTE ON dbo.paBloqueoComprobar TO reservas_app;
GRANT EXECUTE ON dbo.paBloqueoCrear TO reservas_app;
GRANT EXECUTE ON dbo.paBloqueoValidar TO reservas_app;
GRANT EXECUTE ON dbo.paBloqueoLiberar TO reservas_app;
GRANT EXECUTE ON dbo.paBloqueoListar TO reservas_app;
GRANT EXECUTE ON dbo.paComprobanteGuardar TO reservas_app;
GRANT EXECUTE ON dbo.paComprobanteLeer TO reservas_app;
GRANT EXECUTE ON dbo.paPagoVerificar TO reservas_app;
GO

CREATE OR ALTER PROCEDURE [dbo].[paReservaInsertar]
    @pCodigo NVARCHAR(20),
    @pEspacioId INT,
    @pSolicitantePerfilId INT,
    @pCreadoPorUsuarioId INT = NULL,
    @pGrupo NVARCHAR(160) = NULL,
    @pResponsable NVARCHAR(160),
    @pTelefono NVARCHAR(30),
    @pEmail NVARCHAR(160),
    @pParticipantes INT,
    @pTipoActividad NVARCHAR(120),
    @pFechaInicio DATETIME2(0),
    @pFechaFin DATETIME2(0),
    @pEstado NVARCHAR(20) = N'PENDIENTE',
    @pObservaciones NVARCHAR(MAX) = NULL,
    @pIdGenerado INT OUTPUT,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @pIdGenerado = NULL;
    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY
        IF NULLIF(LTRIM(RTRIM(@pCodigo)), N'') IS NULL OR LEN(@pCodigo) > 20
        BEGIN
            SET @pMensaje = N'El código es obligatorio y no puede superar 20 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pResponsable)), N'') IS NULL OR LEN(@pResponsable) > 160
        BEGIN
            SET @pMensaje = N'El responsable es obligatorio y no puede superar 160 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pTelefono)), N'') IS NULL OR LEN(@pTelefono) > 30
        BEGIN
            SET @pMensaje = N'El teléfono es obligatorio y no puede superar 30 caracteres.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pEmail)), N'') IS NULL OR LEN(@pEmail) > 160 OR dbo.fnCorreoValido(LTRIM(RTRIM(@pEmail))) <> 1
        BEGIN
            SET @pMensaje = N'El correo es obligatorio y debe ser válido.';
            RETURN 0;
        END;

        IF @pParticipantes IS NULL OR @pParticipantes <= 0
        BEGIN
            SET @pMensaje = N'La cantidad de participantes debe ser mayor que cero.';
            RETURN 0;
        END;

        IF NULLIF(LTRIM(RTRIM(@pTipoActividad)), N'') IS NULL OR LEN(@pTipoActividad) > 120
        BEGIN
            SET @pMensaje = N'El tipo de actividad es obligatorio y no puede superar 120 caracteres.';
            RETURN 0;
        END;

        IF @pGrupo IS NOT NULL AND LEN(@pGrupo) > 160
        BEGIN
            SET @pMensaje = N'El grupo no puede superar 160 caracteres.';
            RETURN 0;
        END;

        IF @pFechaInicio IS NULL OR @pFechaFin IS NULL OR @pFechaFin <= @pFechaInicio
        BEGIN
            SET @pMensaje = N'La fecha final debe ser mayor que la fecha inicial.';
            RETURN 0;
        END;

        IF @pEstado NOT IN (N'PENDIENTE', N'APROBADA', N'CANCELADA', N'FINALIZADA')
        BEGIN
            SET @pMensaje = N'El estado de la reserva no es válido.';
            RETURN 0;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.perfilesUsuario WHERE idPerfil = @pSolicitantePerfilId)
        BEGIN
            SET @pMensaje = N'El perfil solicitante no existe.';
            RETURN 0;
        END;

        IF @pCreadoPorUsuarioId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.usuarios WHERE id = @pCreadoPorUsuarioId)
        BEGIN
            SET @pMensaje = N'El usuario creador no existe.';
            RETURN 0;
        END;

        IF EXISTS (SELECT 1 FROM dbo.reservas WHERE codigo = LTRIM(RTRIM(@pCodigo)))
        BEGIN
            SET @pMensaje = N'Ya existe una reserva con ese código.';
            RETURN 0;
        END;

        BEGIN TRANSACTION;
        EXEC dbo.paBloqueoComprobar @pEspacioId,@pFechaInicio,@pFechaFin,@pCreadoPorUsuarioId;

        DECLARE @capacidad INT;
        DECLARE @estadoEspacio NVARCHAR(20);

        SELECT
            @capacidad = capacidad,
            @estadoEspacio = estado
        FROM dbo.espacios WITH (UPDLOCK, HOLDLOCK)
        WHERE id = @pEspacioId;

        IF @capacidad IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio indicado no existe.';
            RETURN 0;
        END;

        IF @pEstado IN (N'PENDIENTE', N'APROBADA') AND @estadoEspacio <> N'DISPONIBLE'
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio indicado no está disponible.';
            RETURN 0;
        END;

        IF @pParticipantes > @capacidad
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'La cantidad de participantes supera la capacidad del espacio.';
            RETURN 0;
        END;

        IF @pEstado IN (N'PENDIENTE', N'APROBADA')
           AND EXISTS
           (
               SELECT 1
               FROM dbo.reservas WITH (UPDLOCK, HOLDLOCK)
               WHERE espacioId = @pEspacioId
                 AND estado IN (N'PENDIENTE', N'APROBADA')
                 AND @pFechaInicio < fechaFin
                 AND @pFechaFin > fechaInicio
           )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @pMensaje = N'El espacio ya tiene una reserva activa en ese rango de fechas.';
            RETURN 0;
        END;

        INSERT INTO dbo.reservas
        (
            codigo, espacioId, solicitantePerfilId, creadoPorUsuarioId,
            grupo, responsable, telefono, email, participantes, tipoActividad,
            fechaInicio, fechaFin, estado, observaciones
        )
        VALUES
        (
            LTRIM(RTRIM(@pCodigo)), @pEspacioId, @pSolicitantePerfilId, @pCreadoPorUsuarioId,
            @pGrupo, LTRIM(RTRIM(@pResponsable)), LTRIM(RTRIM(@pTelefono)), LTRIM(RTRIM(@pEmail)),
            @pParticipantes, LTRIM(RTRIM(@pTipoActividad)), @pFechaInicio, @pFechaFin,
            @pEstado, @pObservaciones
        );

        SET @pIdGenerado = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;

        SET @pResultado = 1;
        SET @pMensaje = N'Reserva insertada correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @pIdGenerado = NULL;
        SET @pResultado = 0;
        SET @pMensaje = LEFT(ERROR_MESSAGE(), 250);
        RETURN 0;
    END CATCH;
END;

GO

GO
-- Bandeja de notificaciones compartidas (migracion 011).
USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID('dbo.pagoRevisiones') IS NULL
BEGIN
    CREATE TABLE dbo.pagoRevisiones(
        pagoId INT PRIMARY KEY REFERENCES dbo.pagos(id) ON DELETE CASCADE,
        usuarioId INT NOT NULL REFERENCES dbo.usuarios(id),
        aprobada BIT NOT NULL,
        revisadaEn DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        motivo NVARCHAR(500) NULL
    );
END;
GO
CREATE OR ALTER PROCEDURE dbo.paNotificacionesListar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.id AS reservaId,r.espacioId,r.codigo,pr.nombre AS solicitante,e.nombre AS espacio,
        r.responsable,r.participantes,r.fechaInicio,r.fechaFin,r.estado AS reservaEstado,
        r.createdAt AS reservaCreadaEn,p.id AS pagoId,p.monto,p.metodo,p.estado AS pagoEstado,
        p.fechaPago,CAST(CASE WHEN c.pagoId IS NULL THEN 0 ELSE 1 END AS BIT) AS tieneComprobante,
        rev.revisadaEn,rev.motivo,revisor.email AS revisadoPor
    FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
    JOIN dbo.perfilesUsuario pr ON pr.idPerfil=r.solicitantePerfilId
    LEFT JOIN dbo.pagos p ON p.reservaId=r.id
    LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
    LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id
    LEFT JOIN dbo.usuarios revisor ON revisor.id=rev.usuarioId
    ORDER BY r.createdAt DESC,r.id DESC,p.id DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoVerificar
    @pagoId INT,@aprobar BIT,@usuarioId INT,@motivo NVARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.usuarios u JOIN dbo.roles r ON r.id=u.rolId
            WHERE u.id=@usuarioId AND u.estado=N'ACTIVO' AND r.nombre IN(N'Administrador',N'Recepcionista'))
            THROW 51019,N'No tiene permiso para revisar pagos.',1;
        DECLARE @reserva INT,@estadoReserva NVARCHAR(20),@inicio DATETIME2(0),@costo DECIMAL(12,2);
        SELECT @reserva=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=r.estado,@inicio=r.fechaInicio,@costo=e.costo
            FROM dbo.reservas r WITH(UPDLOCK,HOLDLOCK) JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reserva;
        DECLARE @metodo NVARCHAR(30),@monto DECIMAL(12,2);
        SELECT @metodo=metodo,@monto=monto FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK)
            WHERE id=@pagoId AND estado=N'PENDIENTE';
        IF @metodo IS NULL OR @metodo NOT IN(N'SINPE Móvil',N'Transferencia bancaria',N'Efectivo')
            THROW 51017,N'Este pago ya fue revisado por otra persona o no admite revisión. La bandeja se actualizará.',1;
        IF @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'La reserva está cerrada o cancelada y no admite revisión.',1;
        IF @aprobar=1 AND @metodo=N'Efectivo' AND CAST(@inicio AS DATE)>
            CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE)
            THROW 51018,N'El efectivo se confirma cuando se recibe, desde el día de llegada.',1;
        IF @aprobar=1 AND @metodo<>N'Efectivo' AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId)
            THROW 51018,N'Falta el comprobante para verificar este pago.',1;
        SET @motivo=NULLIF(LTRIM(RTRIM(@motivo)),N'');
        IF @aprobar=0 AND @motivo IS NULL THROW 51018,N'Indica el motivo del rechazo.',1;
        IF @aprobar=1 AND (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PAGADO')+@monto>@costo
            THROW 51019,N'El pago supera el costo de la reserva.',1;
        UPDATE dbo.pagos SET estado=CASE WHEN @aprobar=1 THEN N'PAGADO' ELSE N'RECHAZADO' END,
            fechaPago=CASE WHEN @aprobar=1 AND @metodo=N'Efectivo' THEN CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE) ELSE fechaPago END,
            updatedAt=SYSDATETIME() WHERE id=@pagoId;
        UPDATE dbo.reservas SET estado=CASE WHEN @aprobar=1 THEN N'APROBADA' ELSE N'CANCELADA' END,
            updatedAt=SYSDATETIME() WHERE id=@reserva;
        INSERT dbo.pagoRevisiones(pagoId,usuarioId,aprobada,motivo) VALUES(@pagoId,@usuarioId,@aprobar,@motivo);
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
GRANT EXECUTE ON dbo.paNotificacionesListar TO reservas_app;
GRANT EXECUTE ON dbo.paPagoVerificar TO reservas_app;
GO

GO
-- Registro de cobros, saldos y anulaciones (migracion 012).
USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=N'ckPagosEstado')
    ALTER TABLE dbo.pagos DROP CONSTRAINT ckPagosEstado;
ALTER TABLE dbo.pagos ADD CONSTRAINT ckPagosEstado CHECK(estado IN(N'PENDIENTE',N'PAGADO',N'RECHAZADO',N'ANULADO'));
IF OBJECT_ID(N'dbo.pagoAnulaciones') IS NULL
CREATE TABLE dbo.pagoAnulaciones(
    pagoId INT PRIMARY KEY REFERENCES dbo.pagos(id),
    usuarioId INT NOT NULL REFERENCES dbo.usuarios(id),
    motivo NVARCHAR(500) NOT NULL,
    anuladaEn DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
CREATE OR ALTER PROCEDURE dbo.paCobrosDisponibles
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.id AS reservaId,r.codigo,e.nombre AS espacio,pr.nombre AS solicitante,
        r.fechaInicio,r.fechaFin,e.costo,
        e.costo-ISNULL((SELECT SUM(monto) FROM dbo.pagos p WHERE p.reservaId=r.id AND p.estado=N'PAGADO'),0) AS saldo
    FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
    JOIN dbo.perfilesUsuario pr ON pr.idPerfil=r.solicitantePerfilId
    WHERE r.estado IN(N'PENDIENTE',N'APROBADA')
    AND e.costo>ISNULL((SELECT SUM(monto) FROM dbo.pagos p WHERE p.reservaId=r.id AND p.estado=N'PAGADO'),0)
    AND NOT EXISTS(SELECT 1 FROM dbo.pagos p WHERE p.reservaId=r.id AND p.estado=N'PENDIENTE')
    ORDER BY r.fechaInicio,r.id;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paCobroContexto @reservaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @costo DECIMAL(12,2),@estado NVARCHAR(20),@inicio DATETIME2(0),@saldo DECIMAL(12,2);
    SELECT @costo=e.costo,@estado=r.estado,@inicio=r.fechaInicio FROM dbo.reservas r WITH(UPDLOCK,HOLDLOCK)
        JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reservaId;
    IF @costo IS NULL OR @estado NOT IN(N'PENDIENTE',N'APROBADA')
        THROW 51018,N'La reserva no admite nuevos cobros.',1;
    IF EXISTS(SELECT 1 FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE reservaId=@reservaId AND estado=N'PENDIENTE')
        THROW 51017,N'Esta reserva ya tiene un pago pendiente. Revisa o registra ese pago existente.',1;
    SELECT @saldo=@costo-ISNULL(SUM(monto),0) FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE reservaId=@reservaId AND estado=N'PAGADO';
    IF @saldo<=0 THROW 51019,N'La reserva ya tiene el costo cubierto.',1;
    SELECT @saldo AS saldo,@inicio AS fechaInicio;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paCobroEstadoReserva @reservaId INT,@aprobada BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.reservas SET estado=CASE WHEN @aprobada=1 THEN N'APROBADA' ELSE N'PENDIENTE' END,
        updatedAt=SYSDATETIME() WHERE id=@reservaId AND estado IN(N'PENDIENTE',N'APROBADA');
END;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoDetalle @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.estado AS reservaEstado,r.fechaInicio,r.fechaFin,e.costo,
        e.costo-ISNULL((SELECT SUM(monto) FROM dbo.pagos WHERE reservaId=r.id AND estado=N'PAGADO'),0) AS saldo,
        CAST(CASE WHEN c.pagoId IS NULL THEN 0 ELSE 1 END AS BIT) AS tieneComprobante,
        rv.email AS revisadoPor,rev.revisadaEn,rev.motivo AS motivoRevision,
        au.email AS anuladoPor,a.anuladaEn,a.motivo AS motivoAnulacion
    FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId JOIN dbo.espacios e ON e.id=r.espacioId
    LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
    LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id LEFT JOIN dbo.usuarios rv ON rv.id=rev.usuarioId
    LEFT JOIN dbo.pagoAnulaciones a ON a.pagoId=p.id LEFT JOIN dbo.usuarios au ON au.id=a.usuarioId
    WHERE p.id=@pagoId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoAnular @pagoId INT,@usuarioId INT,@motivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.usuarios u JOIN dbo.roles r ON r.id=u.rolId WHERE u.id=@usuarioId AND u.estado=N'ACTIVO' AND r.nombre=N'Administrador')
            THROW 51019,N'Solo un administrador puede anular un pago.',1;
        SET @motivo=NULLIF(LTRIM(RTRIM(@motivo)),N'');
        IF @motivo IS NULL THROW 51018,N'Indica el motivo de la anulacion.',1;
        DECLARE @reserva INT,@estado NVARCHAR(15);
        SELECT @reserva=reservaId FROM dbo.pagos WHERE id=@pagoId;
        DECLARE @estadoReserva NVARCHAR(20);
        SELECT @estadoReserva=estado FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@reserva;
        SELECT @estado=estado FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE id=@pagoId;
        IF @estado IS NULL OR @estado<>N'PAGADO' THROW 51017,N'Este pago no esta pagado o ya fue anulado.',1;
        INSERT dbo.pagoAnulaciones(pagoId,usuarioId,motivo) VALUES(@pagoId,@usuarioId,@motivo);
        UPDATE dbo.pagos SET estado=N'ANULADO',updatedAt=SYSDATETIME() WHERE id=@pagoId;
        IF @estadoReserva=N'APROBADA' AND NOT EXISTS(SELECT 1 FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PENDIENTE')
            AND EXISTS(SELECT 1 FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reserva
                AND e.costo>ISNULL((SELECT SUM(monto) FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PAGADO'),0))
            UPDATE dbo.reservas SET estado=N'PENDIENTE',updatedAt=SYSDATETIME() WHERE id=@reserva;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
GRANT EXECUTE ON dbo.paCobrosDisponibles TO reservas_app;
GRANT EXECUTE ON dbo.paCobroContexto TO reservas_app;
GRANT EXECUTE ON dbo.paCobroEstadoReserva TO reservas_app;
GRANT EXECUTE ON dbo.paPagoDetalle TO reservas_app;
GRANT EXECUTE ON dbo.paPagoAnular TO reservas_app;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoBloquearEdicion @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @reserva INT,@estado NVARCHAR(15);
    SELECT @reserva=reservaId FROM dbo.pagos WHERE id=@pagoId;
    DECLARE @ignorado INT;
    SELECT @ignorado=id FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@reserva;
    SELECT @estado=estado FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE id=@pagoId;
    IF @estado IN(N'PAGADO',N'ANULADO',N'RECHAZADO')
        THROW 51018,N'Un pago resuelto no se edita ni elimina. Conserva el historial y utiliza la anulacion con motivo si corresponde.',1;
END;
GO
GRANT EXECUTE ON dbo.paPagoBloquearEdicion TO reservas_app;
GO

CREATE OR ALTER PROCEDURE [dbo].[paPagoFiltrar]
    @pReservaId INT = NULL,
    @pCodigoReserva NVARCHAR(20) = NULL,
    @pMetodo NVARCHAR(30) = NULL,
    @pEstado NVARCHAR(15) = NULL,
    @pFechaDesde DATE = NULL,
    @pFechaHasta DATE = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        SET @pCodigoReserva =
            NULLIF(LTRIM(RTRIM(@pCodigoReserva)), N'');

        SET @pMetodo =
            NULLIF(LTRIM(RTRIM(@pMetodo)), N'');

        SET @pEstado =
            NULLIF(LTRIM(RTRIM(@pEstado)), N'');

        /* Validar método */
        IF @pMetodo IS NOT NULL
           AND @pMetodo NOT IN
           (
               N'SINPE Móvil',
               N'Transferencia bancaria',
               N'Efectivo',
               N'Tarjeta'
           )
        BEGIN
            SET @pMensaje =
                N'El método de pago no es válido.';
            RETURN;
        END;

        /* Validar estado */
        IF @pEstado IS NOT NULL
           AND @pEstado NOT IN
           (
               N'PAGADO',
               N'PENDIENTE',
               N'RECHAZADO', N'ANULADO'
           )
        BEGIN
            SET @pMensaje =
                N'El estado del pago no es válido.';
            RETURN;
        END;

        /* Validar rango de fechas */
        IF @pFechaDesde IS NOT NULL
           AND @pFechaHasta IS NOT NULL
           AND @pFechaHasta < @pFechaDesde
        BEGIN
            SET @pMensaje =
                N'La fecha final no puede ser menor que la fecha inicial.';
            RETURN;
        END;

        SELECT
            p.id,
            p.reservaId,
            r.codigo AS reservaCodigo,
            e.nombre AS espacio,

            p.monto,
            p.metodo,
            p.fechaPago,
            p.estado,
            p.comprobante,
            p.notas,

            /* NUEVO: costo completo del espacio */
            e.costo AS costoEspacio,

            /* NUEVO: total que ya ha sido PAGADO */
            totales.totalPagado,

            /* NUEVO: dinero que todavía falta */
            e.costo - totales.totalPagado AS saldoPendiente,

            p.createdAt,
            p.updatedAt

        FROM dbo.pagos AS p

        INNER JOIN dbo.reservas AS r
            ON r.id = p.reservaId

        INNER JOIN dbo.espacios AS e
            ON e.id = r.espacioId

        /* Calcula todos los pagos PAGADO de la reserva */
        OUTER APPLY
        (
            SELECT
                ISNULL(SUM(p2.monto), 0) AS totalPagado
            FROM dbo.pagos AS p2
            WHERE p2.reservaId = p.reservaId
              AND p2.estado = N'PAGADO'
        ) AS totales

        WHERE
            (
                @pReservaId IS NULL
                OR p.reservaId = @pReservaId
            )
            AND
            (
                @pCodigoReserva IS NULL
                OR r.codigo LIKE
                    N'%' + @pCodigoReserva + N'%'
            )
            AND
            (
                @pMetodo IS NULL
                OR p.metodo = @pMetodo
            )
            AND
            (
                @pEstado IS NULL
                OR p.estado = @pEstado
            )
            AND
            (
                @pFechaDesde IS NULL
                OR p.fechaPago >= @pFechaDesde
            )
            AND
            (
                @pFechaHasta IS NULL
                OR p.fechaPago <= @pFechaHasta
            )

        ORDER BY
            p.fechaPago DESC,
            p.id DESC;

        SET @pResultado = 1;
        SET @pMensaje =
            N'Consulta realizada correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje = ERROR_MESSAGE();

    END CATCH;
END;
GO

GO
-- Efectivo anticipado (migracion 013).
-- Permite registrar efectivo recibido por personal autorizado antes de la llegada.
USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoVerificar
    @pagoId INT,@aprobar BIT,@usuarioId INT,@motivo NVARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.usuarios u JOIN dbo.roles r ON r.id=u.rolId
            WHERE u.id=@usuarioId AND u.estado=N'ACTIVO' AND r.nombre IN(N'Administrador',N'Recepcionista'))
            THROW 51019,N'No tiene permiso para revisar pagos.',1;
        DECLARE @reserva INT,@estadoReserva NVARCHAR(20),@inicio DATETIME2(0),@costo DECIMAL(12,2);
        SELECT @reserva=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=r.estado,@inicio=r.fechaInicio,@costo=e.costo
            FROM dbo.reservas r WITH(UPDLOCK,HOLDLOCK) JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reserva;
        DECLARE @metodo NVARCHAR(30),@monto DECIMAL(12,2);
        SELECT @metodo=metodo,@monto=monto FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK)
            WHERE id=@pagoId AND estado=N'PENDIENTE';
        IF @metodo IS NULL OR @metodo NOT IN(N'SINPE Móvil',N'Transferencia bancaria',N'Efectivo')
            THROW 51017,N'Este pago ya fue revisado por otra persona o no admite revisión. La bandeja se actualizará.',1;
        IF @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'La reserva está cerrada o cancelada y no admite revisión.',1;
        IF @aprobar=1 AND @metodo<>N'Efectivo' AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId)
            THROW 51018,N'Falta el comprobante para verificar este pago.',1;
        SET @motivo=NULLIF(LTRIM(RTRIM(@motivo)),N'');
        IF @aprobar=0 AND @motivo IS NULL THROW 51018,N'Indica el motivo del rechazo.',1;
        IF @aprobar=1 AND (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PAGADO')+@monto>@costo
            THROW 51019,N'El pago supera el costo de la reserva.',1;
        UPDATE dbo.pagos SET estado=CASE WHEN @aprobar=1 THEN N'PAGADO' ELSE N'RECHAZADO' END,
            fechaPago=CASE WHEN @aprobar=1 AND @metodo=N'Efectivo' THEN CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE) ELSE fechaPago END,
            updatedAt=SYSDATETIME() WHERE id=@pagoId;
        UPDATE dbo.reservas SET estado=CASE WHEN @aprobar=1 THEN N'APROBADA' ELSE N'CANCELADA' END,
            updatedAt=SYSDATETIME() WHERE id=@reserva;
        INSERT dbo.pagoRevisiones(pagoId,usuarioId,aprobada,motivo) VALUES(@pagoId,@usuarioId,@aprobar,@motivo);
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
GRANT EXECUTE ON dbo.paPagoVerificar TO reservas_app;
GO

USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.paUsuariosRegistradosIds
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.id
    FROM dbo.usuarios u
    INNER JOIN dbo.roles r ON r.id = u.rolId
    WHERE r.nombre IN (N'Usuario', N'Miembro');
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paUsuariosRegistradosIds TO reservas_app;
GO

-- Eliminacion auditada y comprobantes (migracion 014).
USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Archivo independiente: ninguna FK a las filas que se eliminan.
IF OBJECT_ID(N'dbo.reservasEliminadas') IS NULL
CREATE TABLE dbo.reservasEliminadas (
    reservaId INT PRIMARY KEY,
    reservaJson NVARCHAR(MAX) NOT NULL CHECK (ISJSON(reservaJson)=1),
    pagosJson NVARCHAR(MAX) NOT NULL CHECK (ISJSON(pagosJson)=1),
    eliminadaPor NVARCHAR(160) NULL,
    eliminadaEn DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
IF OBJECT_ID(N'dbo.comprobantesArchivados') IS NULL
CREATE TABLE dbo.comprobantesArchivados (
    pagoId INT PRIMARY KEY,
    reservaId INT NOT NULL REFERENCES dbo.reservasEliminadas(reservaId),
    nombre NVARCHAR(200) NOT NULL,
    tipo NVARCHAR(60) NOT NULL,
    contenido VARBINARY(MAX) NOT NULL
);
GO
CREATE OR ALTER PROCEDURE dbo.paReservaEliminar
    @pId INT, @pResultado TINYINT OUTPUT, @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @pResultado=0;
    SET @pMensaje=N'';
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@pId)
            THROW 51018,N'La reserva indicada no existe.',1;
        DECLARE @reserva NVARCHAR(MAX),@pagos NVARCHAR(MAX);
        SELECT @reserva=(SELECT r.*,e.nombre AS espacio,pr.nombre AS solicitante
            FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
            JOIN dbo.perfilesUsuario pr ON pr.idPerfil=r.solicitantePerfilId
            WHERE r.id=@pId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
        SELECT @pagos=(SELECT p.*,c.nombre AS archivoNombre,c.tipo AS archivoTipo,
            rev.aprobada AS comprobanteCorrecto,rev.revisadaEn,rev.motivo AS motivoRevision,
            u.email AS revisadoPor,a.motivo AS motivoAnulacion,a.anuladaEn,au.email AS anuladoPor
            FROM dbo.pagos p WITH(UPDLOCK,HOLDLOCK)
            LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
            LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id
            LEFT JOIN dbo.usuarios u ON u.id=rev.usuarioId
            LEFT JOIN dbo.pagoAnulaciones a ON a.pagoId=p.id
            LEFT JOIN dbo.usuarios au ON au.id=a.usuarioId
            WHERE p.reservaId=@pId FOR JSON PATH,INCLUDE_NULL_VALUES);
        INSERT dbo.reservasEliminadas(reservaId,reservaJson,pagosJson,eliminadaPor)
            VALUES(@pId,@reserva,COALESCE(@pagos,N'[]'),CONVERT(NVARCHAR(160),SESSION_CONTEXT(N'app_usuario_nombre')));
        INSERT dbo.comprobantesArchivados(pagoId,reservaId,nombre,tipo,contenido)
            SELECT c.pagoId,@pId,c.nombre,c.tipo,c.contenido
            FROM dbo.pagoComprobantes c JOIN dbo.pagos p ON p.id=c.pagoId WHERE p.reservaId=@pId;
        DELETE a FROM dbo.pagoAnulaciones a JOIN dbo.pagos p ON p.id=a.pagoId WHERE p.reservaId=@pId;
        -- Los triggers de pagos y reservas registran DELETE con el contexto de la cuenta.
        DELETE FROM dbo.pagos WHERE reservaId=@pId;
        DELETE FROM dbo.reservas WHERE id=@pId;
        COMMIT;
        SET @pResultado=1;
        SET @pMensaje=N'Reserva eliminada. Auditoría, pagos y comprobantes conservados.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        SET @pMensaje=LEFT(ERROR_MESSAGE(),250);
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservaArchivo @reservaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT reservaJson,pagosJson,eliminadaPor,eliminadaEn FROM dbo.reservasEliminadas WHERE reservaId=@reservaId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paComprobanteLeer @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nombre,tipo,contenido FROM dbo.pagoComprobantes WHERE pagoId=@pagoId
    UNION ALL
    SELECT nombre,tipo,contenido FROM dbo.comprobantesArchivados WHERE pagoId=@pagoId
        AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId);
END;
GO
CREATE OR ALTER PROCEDURE dbo.paComprobanteAdjuntar
    @pagoId INT,@nombre NVARCHAR(200),@tipo NVARCHAR(60),@contenido VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @reservaId INT,@estadoReserva NVARCHAR(20),@estado NVARCHAR(15),@metodo NVARCHAR(30);
        SELECT @reservaId=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=estado FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@reservaId;
        SELECT @estado=estado,@metodo=metodo FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE id=@pagoId;
        IF @estado IS NULL OR @estado<>N'PENDIENTE' OR @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'Solo se adjuntan comprobantes a pagos pendientes de reservas activas.',1;
        IF @metodo NOT IN(N'SINPE Móvil',N'Transferencia bancaria')
            THROW 51018,N'El comprobante corresponde a SINPE Móvil o transferencia bancaria.',1;
        IF EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId)
            THROW 51018,N'Este pago ya tiene un comprobante. Se conserva el archivo original.',1;
        EXEC dbo.paComprobanteGuardar @pagoId,@nombre,@tipo,@contenido;
        UPDATE dbo.pagos SET comprobante=N'Comprobante adjunto',updatedAt=SYSDATETIME() WHERE id=@pagoId;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
GRANT EXECUTE ON dbo.paReservaEliminar TO reservas_app;
GRANT EXECUTE ON dbo.paReservaArchivo TO reservas_app;
GRANT EXECUTE ON dbo.paComprobanteLeer TO reservas_app;
GRANT EXECUTE ON dbo.paComprobanteAdjuntar TO reservas_app;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoDetalle @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.estado AS reservaEstado,r.fechaInicio,r.fechaFin,e.costo,
        e.costo-ISNULL((SELECT SUM(monto) FROM dbo.pagos WHERE reservaId=r.id AND estado=N'PAGADO'),0) AS saldo,
        CAST(CASE WHEN c.pagoId IS NULL THEN 0 ELSE 1 END AS BIT) AS tieneComprobante,
        rev.aprobada AS comprobanteCorrecto,rv.email AS revisadoPor,rev.revisadaEn,rev.motivo AS motivoRevision,
        au.email AS anuladoPor,a.anuladaEn,a.motivo AS motivoAnulacion
    FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId JOIN dbo.espacios e ON e.id=r.espacioId
    LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
    LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id LEFT JOIN dbo.usuarios rv ON rv.id=rev.usuarioId
    LEFT JOIN dbo.pagoAnulaciones a ON a.pagoId=p.id LEFT JOIN dbo.usuarios au ON au.id=a.usuarioId
    WHERE p.id=@pagoId;
END;
GO
GRANT EXECUTE ON dbo.paPagoDetalle TO reservas_app;
GO

-- Respaldos externos y perfiles (migraciones 015 y 016).
-- Catalogo y bitacora externos a la base que se restaura.
USE master;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.reservasScoutsRespaldos') IS NULL
CREATE TABLE dbo.reservasScoutsRespaldos (
    nombre NVARCHAR(120) PRIMARY KEY, creadoEn DATETIME2(0) NOT NULL, bytes BIGINT NOT NULL
);
IF OBJECT_ID(N'dbo.reservasScoutsOperaciones') IS NULL
CREATE TABLE dbo.reservasScoutsOperaciones (
    id UNIQUEIDENTIFIER PRIMARY KEY, idAuditoria BIGINT IDENTITY NOT NULL, evento NVARCHAR(20) NOT NULL,
    archivo NVARCHAR(120) NOT NULL, usuarioId INT NULL, usuario NVARCHAR(160) NULL,
    direccionIp NVARCHAR(80) NULL, agente NVARCHAR(500) NULL,
    estado NVARCHAR(20) NOT NULL DEFAULT N'INICIADO', error NVARCHAR(1000) NULL,
    iniciadoEn DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(), finalizadoEn DATETIME2(3) NULL
);
GO
IF DB_ID(N'reservasScouts') IS NOT NULL AND OBJECT_ID(N'reservasScouts.dbo.respaldoHistorial') IS NOT NULL
INSERT dbo.reservasScoutsRespaldos(nombre,creadoEn,bytes)
SELECT nombreArchivo,creadoEn,bytes FROM reservasScouts.dbo.respaldoHistorial h
WHERE NOT EXISTS(SELECT 1 FROM dbo.reservasScoutsRespaldos c WHERE c.nombre=h.nombreArchivo);
GO
CREATE OR ALTER PROCEDURE dbo.paReservasRespaldoListar
AS
BEGIN
 SET NOCOUNT ON;
 SELECT nombre,creadoEn,bytes FROM dbo.reservasScoutsRespaldos ORDER BY creadoEn DESC,nombre;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasRespaldoRegistrar
 @nombre NVARCHAR(120),@creadoEn DATETIME2(0),@bytes BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF @nombre NOT LIKE N'reservasScouts[_]%.bak' OR @bytes<=0 THROW 50031,N'Respaldo invalido.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.reservasScoutsRespaldos WHERE nombre=@nombre)
 INSERT dbo.reservasScoutsRespaldos VALUES(@nombre,@creadoEn,@bytes);
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionIniciar
 @id UNIQUEIDENTIFIER,@evento NVARCHAR(20),@archivo NVARCHAR(120),@usuarioId INT,
 @usuario NVARCHAR(160),@ip NVARCHAR(80),@agente NVARCHAR(500)
AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.reservasScoutsOperaciones(id,evento,archivo,usuarioId,usuario,direccionIp,agente)
 VALUES(@id,@evento,@archivo,@usuarioId,@usuario,@ip,LEFT(@agente,500));
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionFinalizar
 @id UNIQUEIDENTIFIER,@estado NVARCHAR(20),@error NVARCHAR(1000)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 UPDATE dbo.reservasScoutsOperaciones SET estado=@estado,error=@error,finalizadoEn=SYSUTCDATETIME() WHERE id=@id;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionesAuditoria
AS
BEGIN
 SET NOCOUNT ON;
 SELECT TOP(500) idAuditoria,N'respaldos' AS origen,evento,CAST(NULL AS INT) AS registroId,
    usuario,CAST(ORIGINAL_LOGIN() AS NVARCHAR(120)) AS usuarioBd,
    (SELECT archivo,estado,error,direccionIp,agente,iniciadoEn,finalizadoEn FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS detalle,
    CAST(NULL AS NVARCHAR(MAX)) AS valoresAnteriores,
    (SELECT archivo,estado,error,direccionIp,agente,iniciadoEn,finalizadoEn FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS valoresNuevos,
    iniciadoEn AS creadoEn
 FROM dbo.reservasScoutsOperaciones ORDER BY iniciadoEn DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paRespaldoCompleto @pRuta NVARCHAR(4000)
AS
BEGIN
 SET NOCOUNT ON;
 IF NULLIF(LTRIM(RTRIM(@pRuta)),N'') IS NULL THROW 50040,N'La ruta es obligatoria.',1;
 BACKUP DATABASE reservasScouts TO DISK=@pRuta WITH COPY_ONLY,CHECKSUM,COMPRESSION,INIT;
 RESTORE VERIFYONLY FROM DISK=@pRuta WITH CHECKSUM;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionesResumen
AS
BEGIN
 SET NOCOUNT ON;
 SELECT N'respaldos' AS origen,evento,COUNT_BIG(*) AS totalEventos,MAX(iniciadoEn) AS ultimoEvento
 FROM dbo.reservasScoutsOperaciones GROUP BY evento;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paRestaurarReservasScouts @pRuta NVARCHAR(4000)
AS
BEGIN
 SET NOCOUNT ON;
 IF NULLIF(LTRIM(RTRIM(@pRuta)),N'') IS NULL THROW 50041,N'La ruta es obligatoria.',1;
 RESTORE VERIFYONLY FROM DISK=@pRuta WITH CHECKSUM;
 BEGIN TRY
  ALTER DATABASE reservasScouts SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  RESTORE DATABASE reservasScouts FROM DISK=@pRuta WITH REPLACE,RECOVERY,CHECKSUM;
  ALTER DATABASE reservasScouts SET MULTI_USER;
 END TRY
 BEGIN CATCH
  IF DB_ID(N'reservasScouts') IS NOT NULL ALTER DATABASE reservasScouts SET MULTI_USER;
  THROW;
 END CATCH;
END;
GO
IF DATABASE_PRINCIPAL_ID(N'reservas_maintenance') IS NULL
 CREATE USER reservas_maintenance FOR LOGIN reservas_maintenance;
IF DATABASE_PRINCIPAL_ID(N'reservas_app') IS NULL
 CREATE USER reservas_app FOR LOGIN reservas_app;
GRANT EXECUTE ON dbo.paReservasRespaldoListar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasRespaldoRegistrar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasOperacionIniciar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasOperacionFinalizar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasOperacionesAuditoria TO reservas_app;
GRANT EXECUTE ON dbo.paReservasOperacionesResumen TO reservas_app;
GRANT EXECUTE ON dbo.paRespaldoCompleto TO reservas_maintenance;
GRANT EXECUTE ON dbo.paRestaurarReservasScouts TO reservas_maintenance;
GO

USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.paUsuariosRegistradosIds
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.id
    FROM dbo.usuarios u
    INNER JOIN dbo.roles r ON r.id = u.rolId
    WHERE r.nombre IN (N'Usuario', N'Miembro');
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paUsuariosRegistradosIds TO reservas_app;
GO

CREATE OR ALTER TRIGGER [dbo].[trgPerfilesUsuarioAuditoria]
ON [dbo].[perfilesUsuario]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuarioBd NVARCHAR(120) = LEFT(ORIGINAL_LOGIN(), 120);

    INSERT INTO dbo.auditoriaReservas
    (
        tabla, idRegistro, accion, detalle,
        usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn
    )
    SELECT
        N'perfilesUsuario',
        COALESCE(i.idPerfil, d.idPerfil),
        CASE
            WHEN d.idPerfil IS NULL THEN N'INSERT'
            WHEN i.idPerfil IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        (
            SELECT
                JSON_QUERY(CASE WHEN d.idPerfil IS NOT NULL THEN
                    (SELECT d.usuarioId, d.tipoPerfil, d.nombre, d.identificacion, d.telefono, d.correoContacto, d.direccion
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS antes,
                JSON_QUERY(CASE WHEN i.idPerfil IS NOT NULL THEN
                    (SELECT i.usuarioId, i.tipoPerfil, i.nombre, i.identificacion, i.telefono, i.correoContacto, i.direccion
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS despues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),
        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),
        @usuarioBd,
        SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.idPerfil = i.idPerfil;
END;
GO

-- Reservas pendientes de pago (migracion 017).
USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF COL_LENGTH(N'dbo.reservas',N'pagoVenceEn') IS NULL
 ALTER TABLE dbo.reservas ADD pagoVenceEn DATETIME2(0) NULL;
IF OBJECT_ID(N'dbo.reservaPoliticaPago') IS NULL
BEGIN
 CREATE TABLE dbo.reservaPoliticaPago(id INT PRIMARY KEY CHECK(id=1),efectivoGraciaMinutos INT NOT NULL CHECK(efectivoGraciaMinutos BETWEEN 0 AND 1440),transferenciaPlazoHoras INT NOT NULL CHECK(transferenciaPlazoHoras BETWEEN 1 AND 168));
 INSERT dbo.reservaPoliticaPago VALUES(1,120,24);
END;
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=N'ckReservasEstado') ALTER TABLE dbo.reservas DROP CONSTRAINT ckReservasEstado;
ALTER TABLE dbo.reservas ADD CONSTRAINT ckReservasEstado CHECK(estado IN(N'PENDIENTE',N'APROBADA',N'CANCELADA',N'FINALIZADA',N'VENCIDA'));
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=N'ckPagosEstado') ALTER TABLE dbo.pagos DROP CONSTRAINT ckPagosEstado;
ALTER TABLE dbo.pagos ADD CONSTRAINT ckPagosEstado CHECK(estado IN(N'PENDIENTE',N'PAGADO',N'RECHAZADO',N'ANULADO',N'VENCIDO'));
GO
CREATE OR ALTER PROCEDURE dbo.paReservaPlazoActualizar @reservaId INT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @vence DATETIME2(0),@costo DECIMAL(12,2),@pagado DECIMAL(12,2);
 SELECT @costo=e.costo FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reservaId;
 SELECT @pagado=ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reservaId AND estado=N'PAGADO';
 SELECT @vence=MIN(CASE WHEN limite>r.fechaFin THEN r.fechaFin ELSE limite END)
 FROM dbo.reservas r CROSS JOIN dbo.reservaPoliticaPago cfg
 JOIN dbo.pagos p ON p.reservaId=r.id
 CROSS APPLY(SELECT CASE WHEN p.metodo=N'Efectivo' THEN DATEADD(MINUTE,cfg.efectivoGraciaMinutos,r.fechaInicio)
   ELSE CASE WHEN DATEADD(HOUR,cfg.transferenciaPlazoHoras,p.createdAt)>r.fechaInicio THEN r.fechaInicio ELSE DATEADD(HOUR,cfg.transferenciaPlazoHoras,p.createdAt) END END AS limite) l
 WHERE r.id=@reservaId AND p.estado=N'PENDIENTE'
 AND (p.metodo=N'Efectivo' OR (p.metodo IN(N'SINPE Móvil',N'Transferencia bancaria') AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes c WHERE c.pagoId=p.id)));
 UPDATE dbo.reservas SET pagoVenceEn=CASE WHEN @pagado>=@costo THEN NULL ELSE @vence END,
  estado=CASE WHEN @pagado>=@costo THEN N'APROBADA' ELSE N'PENDIENTE' END,updatedAt=SYSDATETIME()
 WHERE id=@reservaId AND estado IN(N'PENDIENTE',N'APROBADA')
 AND (estado<>CASE WHEN @pagado>=@costo THEN N'APROBADA' ELSE N'PENDIENTE' END
      OR ISNULL(pagoVenceEn,'19000101')<>ISNULL(CASE WHEN @pagado>=@costo THEN NULL ELSE @vence END,'19000101'));
END;
GO
CREATE OR ALTER TRIGGER dbo.trgPagosPlazoReserva ON dbo.pagos AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @id INT;
 DECLARE filas CURSOR LOCAL FAST_FORWARD FOR SELECT reservaId FROM inserted UNION SELECT reservaId FROM deleted;
 OPEN filas; FETCH NEXT FROM filas INTO @id;
 WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM filas INTO @id; END;
 CLOSE filas; DEALLOCATE filas;
END;
GO
CREATE OR ALTER TRIGGER dbo.trgComprobantesPlazoReserva ON dbo.pagoComprobantes AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @id INT;
 DECLARE filas CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT p.reservaId FROM inserted i JOIN dbo.pagos p ON p.id=i.pagoId;
 OPEN filas; FETCH NEXT FROM filas INTO @id;
 WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM filas INTO @id; END;
 CLOSE filas; DEALLOCATE filas;
END;
GO
CREATE OR ALTER TRIGGER dbo.trgReservasPagoIntegro ON dbo.reservas AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.espacios e ON e.id=i.espacioId WHERE i.estado=N'APROBADA'
  AND e.costo>ISNULL((SELECT SUM(monto) FROM dbo.pagos WHERE reservaId=i.id AND estado=N'PAGADO'),0))
  THROW 51019,N'La reserva solo se aprueba al recibir y confirmar el pago completo.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasVencerPendientes
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @ahora DATETIME2(0)=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATETIME2(0));
 DECLARE @usuario SQL_VARIANT=SESSION_CONTEXT(N'app_usuario_id'),@nombre SQL_VARIANT=SESSION_CONTEXT(N'app_usuario_nombre');
 EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=N'Sistema: vencimiento de reservas';
 BEGIN TRY
  DECLARE @id INT;
  DECLARE filas CURSOR LOCAL FAST_FORWARD FOR SELECT id FROM dbo.reservas WHERE estado=N'PENDIENTE' AND pagoVenceEn<=@ahora ORDER BY id;
  OPEN filas; FETCH NEXT FROM filas INTO @id;
  WHILE @@FETCH_STATUS=0
  BEGIN
   BEGIN TRANSACTION;
   IF EXISTS(SELECT 1 FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@id AND estado=N'PENDIENTE' AND pagoVenceEn<=@ahora)
     AND NOT EXISTS(SELECT 1 FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE reservaId=@id AND estado=N'PAGADO')
     AND NOT EXISTS(SELECT 1 FROM dbo.pagos p JOIN dbo.pagoComprobantes c ON c.pagoId=p.id WHERE p.reservaId=@id AND p.estado=N'PENDIENTE')
   BEGIN
    UPDATE dbo.reservas SET estado=N'VENCIDA',updatedAt=SYSDATETIME() WHERE id=@id;
    UPDATE dbo.pagos SET estado=N'VENCIDO',notas=CONCAT(ISNULL(notas,N''),N' Plazo de pago vencido; cupo liberado.'),updatedAt=SYSDATETIME() WHERE reservaId=@id AND estado=N'PENDIENTE';
   END;
   COMMIT;
   FETCH NEXT FROM filas INTO @id;
  END;
  CLOSE filas; DEALLOCATE filas;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=@usuario;
  EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=@nombre;
  THROW;
 END CATCH;
 EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=@usuario;
 EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=@nombre;
END;
GO
CREATE OR ALTER TRIGGER dbo.trgReservasFechaPlazo ON dbo.reservas AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF NOT (UPDATE(fechaInicio) OR UPDATE(fechaFin)) RETURN;
 DECLARE @id INT;
 DECLARE filas CURSOR LOCAL FAST_FORWARD FOR
 SELECT i.id FROM inserted i JOIN deleted d ON d.id=i.id
 WHERE i.estado IN(N'PENDIENTE',N'APROBADA') AND (i.fechaInicio<>d.fechaInicio OR i.fechaFin<>d.fechaFin)
 AND EXISTS(SELECT 1 FROM dbo.pagos WHERE reservaId=i.id);
 OPEN filas; FETCH NEXT FROM filas INTO @id;
 WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM filas INTO @id; END;
 CLOSE filas; DEALLOCATE filas;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paCobroEstadoReserva @reservaId INT,@aprobada BIT
AS
BEGIN
 SET NOCOUNT ON;
 -- El estado se deriva del saldo recibido, nunca del metodo elegido por el cliente.
 EXEC dbo.paReservaPlazoActualizar @reservaId;
END;
GO
GRANT EXECUTE ON dbo.paReservaPlazoActualizar TO reservas_app;
GRANT EXECUTE ON dbo.paReservasVencerPendientes TO reservas_app;
GRANT EXECUTE ON dbo.paCobroEstadoReserva TO reservas_app;
GO

-- Permite registrar efectivo recibido por personal autorizado antes de la llegada.
USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoVerificar
    @pagoId INT,@aprobar BIT,@usuarioId INT,@motivo NVARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.usuarios u JOIN dbo.roles r ON r.id=u.rolId
            WHERE u.id=@usuarioId AND u.estado=N'ACTIVO' AND r.nombre IN(N'Administrador',N'Recepcionista'))
            THROW 51019,N'No tiene permiso para revisar pagos.',1;
        DECLARE @reserva INT,@estadoReserva NVARCHAR(20),@inicio DATETIME2(0),@costo DECIMAL(12,2),@vence DATETIME2(0);
        SELECT @reserva=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=r.estado,@inicio=r.fechaInicio,@costo=e.costo,@vence=r.pagoVenceEn
            FROM dbo.reservas r WITH(UPDLOCK,HOLDLOCK) JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reserva;
        DECLARE @metodo NVARCHAR(30),@monto DECIMAL(12,2);
        SELECT @metodo=metodo,@monto=monto FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK)
            WHERE id=@pagoId AND estado=N'PENDIENTE';
        IF @metodo IS NULL OR @metodo NOT IN(N'SINPE Móvil',N'Transferencia bancaria',N'Efectivo')
            THROW 51017,N'Este pago ya fue revisado por otra persona o no admite revisión. La bandeja se actualizará.',1;
        IF @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'La reserva está cerrada o cancelada y no admite revisión.',1;
        IF @vence IS NOT NULL AND @vence<=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATETIME2(0))
            THROW 51018,N'El plazo de pago vencio. El cupo debe consultarse nuevamente.',1;
        IF @aprobar=1 AND @metodo<>N'Efectivo' AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId)
            THROW 51018,N'Falta el comprobante para verificar este pago.',1;
        SET @motivo=NULLIF(LTRIM(RTRIM(@motivo)),N'');
        IF @aprobar=0 AND @motivo IS NULL THROW 51018,N'Indica el motivo del rechazo.',1;
        IF @aprobar=1 AND (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PAGADO')+@monto>@costo
            THROW 51019,N'El pago supera el costo de la reserva.',1;
        UPDATE dbo.pagos SET estado=CASE WHEN @aprobar=1 THEN N'PAGADO' ELSE N'RECHAZADO' END,
            fechaPago=CASE WHEN @aprobar=1 AND @metodo=N'Efectivo' THEN CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE) ELSE fechaPago END,
            updatedAt=SYSDATETIME() WHERE id=@pagoId;
        UPDATE dbo.reservas SET estado=CASE WHEN @aprobar=0 THEN N'CANCELADA' WHEN (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PAGADO')>=@costo THEN N'APROBADA' ELSE N'PENDIENTE' END,
            updatedAt=SYSDATETIME() WHERE id=@reserva;
        INSERT dbo.pagoRevisiones(pagoId,usuarioId,aprobada,motivo) VALUES(@pagoId,@usuarioId,@aprobar,@motivo);
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
GRANT EXECUTE ON dbo.paPagoVerificar TO reservas_app;
GO

USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [dbo].[paReservaFiltrar]
    @pCodigo NVARCHAR(20) = NULL,
    @pResponsable NVARCHAR(160) = NULL,
    @pEstado NVARCHAR(20) = NULL,
    @pEspacioId INT = NULL,
    @pSolicitantePerfilId INT = NULL,
    @pFechaDesde DATE = NULL,
    @pFechaHasta DATE = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT,
    @pCreadorUsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @pEstado IS NOT NULL
       AND @pEstado NOT IN (N'PENDIENTE', N'APROBADA', N'CANCELADA', N'FINALIZADA', N'VENCIDA')
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'El estado indicado no es válido.';
        RETURN 0;
    END;

    IF @pEspacioId IS NOT NULL
       AND (@pEspacioId <= 0 OR NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE id = @pEspacioId))
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'El espacio indicado no existe.';
        RETURN 0;
    END;

    IF @pSolicitantePerfilId IS NOT NULL
       AND (@pSolicitantePerfilId <= 0 OR NOT EXISTS (SELECT 1 FROM dbo.perfilesUsuario WHERE idPerfil = @pSolicitantePerfilId))
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'El perfil solicitante indicado no existe.';
        RETURN 0;
    END;

    IF @pFechaDesde IS NOT NULL AND @pFechaHasta IS NOT NULL AND @pFechaDesde > @pFechaHasta
    BEGIN
        SET @pResultado = 0;
        SET @pMensaje = N'La fecha inicial no puede ser posterior a la fecha final.';
        RETURN 0;
    END;

    EXEC dbo.paReservasVencerPendientes;
    SELECT
        r.id,
        r.codigo,
        e.nombre AS espacio,
        p.nombre AS solicitante,
        r.responsable,
        r.participantes,
        r.tipoActividad,
        r.fechaInicio,
        r.fechaFin,
        r.estado, r.espacioId, r.pagoVenceEn,
        (SELECT TOP(1) metodo FROM dbo.pagos WHERE reservaId=r.id AND estado=N'PENDIENTE' ORDER BY id DESC) AS metodoPagoPendiente
    FROM dbo.reservas r
    INNER JOIN dbo.espacios e ON e.id = r.espacioId
    INNER JOIN dbo.perfilesUsuario p ON p.idPerfil = r.solicitantePerfilId
    WHERE (@pCodigo IS NULL OR r.codigo LIKE N'%' + @pCodigo + N'%')
      AND (@pResponsable IS NULL OR r.responsable LIKE N'%' + @pResponsable + N'%')
      AND (@pEstado IS NULL OR r.estado = @pEstado)
      AND (@pEspacioId IS NULL OR r.espacioId = @pEspacioId)
      AND (@pSolicitantePerfilId IS NULL OR r.solicitantePerfilId = @pSolicitantePerfilId)
      AND (@pCreadorUsuarioId IS NULL OR r.creadoPorUsuarioId = @pCreadorUsuarioId OR p.usuarioId = @pCreadorUsuarioId)
      AND (@pFechaDesde IS NULL OR CONVERT(DATE, r.fechaInicio) >= @pFechaDesde)
      AND (@pFechaHasta IS NULL OR CONVERT(DATE, r.fechaFin) <= @pFechaHasta)
    ORDER BY r.fechaInicio DESC;

    SET @pResultado = 1;
    SET @pMensaje = N'Filtro realizado correctamente.';
    RETURN 1;
END;

GO

CREATE OR ALTER PROCEDURE [dbo].[paReservaFechasOcupadas]
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;
    SELECT espacioId, fechaInicio, fechaFin
    FROM dbo.reservas
    WHERE estado IN (N'PENDIENTE', N'APROBADA')
    ORDER BY espacioId, fechaInicio;
END;
GO

CREATE OR ALTER PROCEDURE [dbo].[paPagoFiltrar]
    @pReservaId INT = NULL,
    @pCodigoReserva NVARCHAR(20) = NULL,
    @pMetodo NVARCHAR(30) = NULL,
    @pEstado NVARCHAR(15) = NULL,
    @pFechaDesde DATE = NULL,
    @pFechaHasta DATE = NULL,
    @pResultado TINYINT OUTPUT,
    @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @pResultado = 0;
    SET @pMensaje = N'';

    BEGIN TRY

        SET @pCodigoReserva =
            NULLIF(LTRIM(RTRIM(@pCodigoReserva)), N'');

        SET @pMetodo =
            NULLIF(LTRIM(RTRIM(@pMetodo)), N'');

        SET @pEstado =
            NULLIF(LTRIM(RTRIM(@pEstado)), N'');

        /* Validar método */
        IF @pMetodo IS NOT NULL
           AND @pMetodo NOT IN
           (
               N'SINPE Móvil',
               N'Transferencia bancaria',
               N'Efectivo',
               N'Tarjeta'
           )
        BEGIN
            SET @pMensaje =
                N'El método de pago no es válido.';
            RETURN;
        END;

        /* Validar estado */
        IF @pEstado IS NOT NULL
           AND @pEstado NOT IN
           (
               N'PAGADO',
               N'PENDIENTE',
               N'RECHAZADO', N'ANULADO', N'VENCIDO'
           )
        BEGIN
            SET @pMensaje =
                N'El estado del pago no es válido.';
            RETURN;
        END;

        /* Validar rango de fechas */
        IF @pFechaDesde IS NOT NULL
           AND @pFechaHasta IS NOT NULL
           AND @pFechaHasta < @pFechaDesde
        BEGIN
            SET @pMensaje =
                N'La fecha final no puede ser menor que la fecha inicial.';
            RETURN;
        END;

        SELECT
            p.id,
            p.reservaId,
            r.codigo AS reservaCodigo,
            e.nombre AS espacio,

            p.monto,
            p.metodo,
            p.fechaPago,
            p.estado,
            p.comprobante,
            p.notas,

            /* NUEVO: costo completo del espacio */
            e.costo AS costoEspacio,

            /* NUEVO: total que ya ha sido PAGADO */
            totales.totalPagado,

            /* NUEVO: dinero que todavía falta */
            e.costo - totales.totalPagado AS saldoPendiente,

            p.createdAt,
            p.updatedAt

        FROM dbo.pagos AS p

        INNER JOIN dbo.reservas AS r
            ON r.id = p.reservaId

        INNER JOIN dbo.espacios AS e
            ON e.id = r.espacioId

        /* Calcula todos los pagos PAGADO de la reserva */
        OUTER APPLY
        (
            SELECT
                ISNULL(SUM(p2.monto), 0) AS totalPagado
            FROM dbo.pagos AS p2
            WHERE p2.reservaId = p.reservaId
              AND p2.estado = N'PAGADO'
        ) AS totales

        WHERE
            (
                @pReservaId IS NULL
                OR p.reservaId = @pReservaId
            )
            AND
            (
                @pCodigoReserva IS NULL
                OR r.codigo LIKE
                    N'%' + @pCodigoReserva + N'%'
            )
            AND
            (
                @pMetodo IS NULL
                OR p.metodo = @pMetodo
            )
            AND
            (
                @pEstado IS NULL
                OR p.estado = @pEstado
            )
            AND
            (
                @pFechaDesde IS NULL
                OR p.fechaPago >= @pFechaDesde
            )
            AND
            (
                @pFechaHasta IS NULL
                OR p.fechaPago <= @pFechaHasta
            )

        ORDER BY
            p.fechaPago DESC,
            p.id DESC;

        SET @pResultado = 1;
        SET @pMensaje =
            N'Consulta realizada correctamente.';

    END TRY

    BEGIN CATCH

        SET @pResultado = 0;
        SET @pMensaje = ERROR_MESSAGE();

    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paBloqueoComprobar
    @espacioId INT, @inicio DATETIME2(0), @fin DATETIME2(0), @usuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;
    DECLARE @resultado INT, @recurso NVARCHAR(255) = CONCAT(N'reserva-espacio-', @espacioId);
    EXEC @resultado=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
    IF @resultado < 0 THROW 51010, N'El espacio está siendo consultado. Intenta nuevamente.', 1;
    IF EXISTS (SELECT 1 FROM dbo.reservaBloqueos WHERE espacioId=@espacioId AND vence>SYSUTCDATETIME()
        AND usuarioId<>ISNULL(@usuarioId,-1) AND @inicio<fechaFin AND @fin>fechaInicio)
        THROW 51011, N'Espacio no disponible: otro usuario está completando su reserva.', 1;
END;
GO

-- Instala la consulta de horarios usada antes de guardar reservas.
USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [dbo].[paReservaDisponibilidad]
    @pEspacioId INT,
    @pFechaInicio DATETIME2(0),
    @pFechaFin DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;

    IF @pEspacioId IS NULL
       OR @pEspacioId <= 0
    BEGIN
        THROW 50001, N'El espacio indicado no es válido.', 1;
    END;

    IF @pFechaInicio IS NULL
       OR @pFechaFin IS NULL
       OR @pFechaFin <= @pFechaInicio
    BEGIN
        THROW 50002, N'El rango de fechas no es válido.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.espacios
        WHERE id = @pEspacioId
    )
    BEGIN
        THROW 50003, N'El espacio indicado no existe.', 1;
    END;

    DECLARE @estadoEspacio NVARCHAR(20);

    SELECT
        @estadoEspacio = estado
    FROM dbo.espacios
    WHERE id = @pEspacioId;

    SELECT
        CAST(
            CASE
                WHEN @estadoEspacio <> N'DISPONIBLE'
                    THEN 0

                WHEN EXISTS (
                    SELECT 1
                    FROM dbo.reservas
                    WHERE espacioId = @pEspacioId
                      AND estado IN (
                          N'PENDIENTE',
                          N'APROBADA'
                      )
                      AND @pFechaInicio < fechaFin
                      AND @pFechaFin > fechaInicio
                )
                    THEN 0

                ELSE 1
            END
            AS BIT
        ) AS disponible;
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paReservaDisponibilidad TO reservas_app;
GO

CREATE OR ALTER PROCEDURE dbo.paPagoDetalle @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.estado AS reservaEstado,r.fechaInicio,r.fechaFin,r.pagoVenceEn,e.costo,
        e.costo-ISNULL((SELECT SUM(monto) FROM dbo.pagos WHERE reservaId=r.id AND estado=N'PAGADO'),0) AS saldo,
        CAST(CASE WHEN c.pagoId IS NULL THEN 0 ELSE 1 END AS BIT) AS tieneComprobante,
        rev.aprobada AS comprobanteCorrecto,rv.email AS revisadoPor,rev.revisadaEn,rev.motivo AS motivoRevision,
        au.email AS anuladoPor,a.anuladaEn,a.motivo AS motivoAnulacion
    FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId JOIN dbo.espacios e ON e.id=r.espacioId
    LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
    LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id LEFT JOIN dbo.usuarios rv ON rv.id=rev.usuarioId
    LEFT JOIN dbo.pagoAnulaciones a ON a.pagoId=p.id LEFT JOIN dbo.usuarios au ON au.id=a.usuarioId
    WHERE p.id=@pagoId;
END;
GO


CREATE OR ALTER TRIGGER dbo.trgReservasAuditoria ON dbo.reservas AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.auditoriaReservas(tabla,idRegistro,accion,detalle,usuarioAppId,usuarioAppNombre,usuarioBd,creadoEn)
 SELECT N'reservas',COALESCE(i.id,d.id),CASE WHEN d.id IS NULL THEN N'INSERT' WHEN i.id IS NULL THEN N'DELETE' ELSE N'UPDATE' END,
  (SELECT JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN (SELECT d.* FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) END) AS antes,
          JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN (SELECT i.* FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) END) AS despues
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  TRY_CONVERT(INT,SESSION_CONTEXT(N'app_usuario_id')),TRY_CONVERT(NVARCHAR(160),SESSION_CONTEXT(N'app_usuario_nombre')),LEFT(ORIGINAL_LOGIN(),120),SYSDATETIME()
 FROM inserted i FULL JOIN deleted d ON d.id=i.id;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservaPoliticaPago AS
BEGIN SET NOCOUNT ON; SELECT efectivoGraciaMinutos,transferenciaPlazoHoras FROM dbo.reservaPoliticaPago WHERE id=1; END;
GO
GRANT EXECUTE ON dbo.paReservaPoliticaPago TO reservas_app;
GO
CREATE OR ALTER TRIGGER [dbo].[trgPagosAuditoria]
ON [dbo].[pagos]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.auditoriaPagos
    (
        pagoId,
        reservaId,
        accion,
        valoresAnteriores,
        valoresNuevos,
        usuarioAppId,
        usuarioAppNombre,
        usuarioBd,
        creadoEn
    )
    SELECT
        COALESCE(i.id, d.id),

        COALESCE(i.reservaId, d.reservaId),

        CASE
            WHEN d.id IS NULL THEN N'INSERT'
            WHEN i.id IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,

        CASE
            WHEN d.id IS NOT NULL THEN
            (
                SELECT
                    d.reservaId,
                    d.monto,
                    d.metodo,
                    d.fechaPago,
                    d.estado,
                    d.comprobante
                FOR JSON PATH,
                    WITHOUT_ARRAY_WRAPPER,
                    INCLUDE_NULL_VALUES
            )
            ELSE NULL
        END,

        CASE
            WHEN i.id IS NOT NULL THEN
            (
                SELECT
                    i.reservaId,
                    i.monto,
                    i.metodo,
                    i.fechaPago,
                    i.estado,
                    i.comprobante
                FOR JSON PATH,
                    WITHOUT_ARRAY_WRAPPER,
                    INCLUDE_NULL_VALUES
            )
            ELSE NULL
        END,

        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),

        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),

        LEFT(ORIGINAL_LOGIN(), 120),

        SYSDATETIME()

    FROM inserted AS i

    FULL OUTER JOIN deleted AS d
        ON d.id = i.id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paNotificacionesListar
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;
    SELECT r.id AS reservaId,r.espacioId,r.codigo,pr.nombre AS solicitante,e.nombre AS espacio,
        r.responsable,r.participantes,r.fechaInicio,r.fechaFin,r.pagoVenceEn,r.estado AS reservaEstado,
        r.createdAt AS reservaCreadaEn,p.id AS pagoId,p.monto,p.metodo,p.estado AS pagoEstado,
        p.fechaPago,CAST(CASE WHEN c.pagoId IS NULL THEN 0 ELSE 1 END AS BIT) AS tieneComprobante,
        rev.revisadaEn,rev.motivo,revisor.email AS revisadoPor
    FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
    JOIN dbo.perfilesUsuario pr ON pr.idPerfil=r.solicitantePerfilId
    LEFT JOIN dbo.pagos p ON p.reservaId=r.id
    LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
    LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id
    LEFT JOIN dbo.usuarios revisor ON revisor.id=rev.usuarioId
    ORDER BY r.createdAt DESC,r.id DESC,p.id DESC;
END;
GO

DECLARE @id INT;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=N'Sistema: politica de pago pendiente';
DECLARE actuales CURSOR LOCAL FAST_FORWARD FOR
 SELECT DISTINCT r.id FROM dbo.reservas r JOIN dbo.pagos p ON p.reservaId=r.id
 WHERE r.estado IN(N'PENDIENTE',N'APROBADA');
OPEN actuales; FETCH NEXT FROM actuales INTO @id;
WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM actuales INTO @id; END;
CLOSE actuales; DEALLOCATE actuales;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=NULL;
EXEC dbo.paReservasVencerPendientes;
GO

CREATE OR ALTER PROCEDURE dbo.paComprobanteAdjuntar
    @pagoId INT,@nombre NVARCHAR(200),@tipo NVARCHAR(60),@contenido VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @reservaId INT,@estadoReserva NVARCHAR(20),@estado NVARCHAR(15),@metodo NVARCHAR(30),@vence DATETIME2(0);
        SELECT @reservaId=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=estado,@vence=pagoVenceEn FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@reservaId;
        SELECT @estado=estado,@metodo=metodo FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE id=@pagoId;
        IF @estado IS NULL OR @estado<>N'PENDIENTE' OR @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'Solo se adjuntan comprobantes a pagos pendientes de reservas activas.',1;
        IF @vence IS NOT NULL AND @vence<=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATETIME2(0))
            THROW 51018,N'El plazo para adjuntar el comprobante vencio. Consulta nuevamente la disponibilidad.',1;
        IF @metodo NOT IN(N'SINPE Móvil',N'Transferencia bancaria')
            THROW 51018,N'El comprobante corresponde a SINPE Móvil o transferencia bancaria.',1;
        IF EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId)
            THROW 51018,N'Este pago ya tiene un comprobante. Se conserva el archivo original.',1;
        EXEC dbo.paComprobanteGuardar @pagoId,@nombre,@tipo,@contenido;
        UPDATE dbo.pagos SET comprobante=N'Comprobante adjunto',updatedAt=SYSDATETIME() WHERE id=@pagoId;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
