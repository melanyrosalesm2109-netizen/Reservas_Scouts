USE [master] 
GO
/****** Objeto: Database [reservasScouts] Fecha de script: 24/09/2026 09:13:57 a. m. ******/
:setvar DataFilePath "C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\reservasScouts.mdf"
:setvar LogFilePath "C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\reservasScouts_log.ldf"
CREATE DATABASE [reservasScouts]
 CONTAINMENT = NONE
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
)
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [reservasScouts] SET COMPATIBILITY_LEVEL = 170
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [reservasScouts].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [reservasScouts] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [reservasScouts] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [reservasScouts] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [reservasScouts] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [reservasScouts] SET ARITHABORT OFF 
GO
ALTER DATABASE [reservasScouts] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [reservasScouts] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [reservasScouts] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [reservasScouts] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [reservasScouts] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [reservasScouts] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [reservasScouts] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [reservasScouts] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [reservasScouts] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [reservasScouts] SET  ENABLE_BROKER 
GO
ALTER DATABASE [reservasScouts] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [reservasScouts] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [reservasScouts] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [reservasScouts] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [reservasScouts] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [reservasScouts] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [reservasScouts] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [reservasScouts] SET RECOVERY SIMPLE
GO
ALTER DATABASE [reservasScouts] SET  MULTI_USER 
GO
ALTER DATABASE [reservasScouts] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [reservasScouts] SET DB_CHAINING OFF 
GO
ALTER DATABASE [reservasScouts] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [reservasScouts] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [reservasScouts] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [reservasScouts] SET OPTIMIZED_LOCKING = OFF 
GO
ALTER DATABASE [reservasScouts] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [reservasScouts] SET QUERY_STORE = ON
GO
ALTER DATABASE [reservasScouts] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [reservasScouts]
GO
/****** Objeto: User [reservas_app] Fecha de script: 24/09/2026 09:13:57 a. m. ******/
IF SUSER_ID(N'reservas_app') IS NULL
    THROW 50000, N'Cree primero el login SQL Server reservas_app para poder ejecutar este script.', 1;
GO
CREATE USER [reservas_app] FOR LOGIN [reservas_app] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT EXECUTE ON SCHEMA::[dbo] TO [reservas_app]
GO
/****** Objeto: UserDefinedFunction [dbo].[fnCorreoValido] Fecha de script: 24/09/2026 09:13:57 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Objeto: UserDefinedFunction [dbo].[fnMascararCorreo] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Objeto: UserDefinedFunction [dbo].[fnMascararTelefono] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Objeto: Table [dbo].[perfilesUsuario] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[vPerfilesConfidencial] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Objeto: Table [dbo].[usuarios] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uqUsuariosEmail] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[espacios] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[reservas] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uqReservasCodigo] UNIQUE NONCLUSTERED 
(
	[codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[vReservasResumen] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Objeto: Table [dbo].[actividad] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[auditoriaReservas] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[auditoriaAccesos] ******/
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
            N'auditoriaAccesos' AS origen,
            evento COLLATE DATABASE_DEFAULT,
            COUNT_BIG(*),
            MAX(creadoEn)
        FROM dbo.auditoriaAccesos
        GROUP BY evento;
    GO
    IF DATABASE_PRINCIPAL_ID(N'reservas_consulta') IS NULL
        CREATE USER [reservas_consulta] WITHOUT LOGIN;
    GO
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
/****** Objeto: Table [dbo].[pagos] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[permisos] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[permisos](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[clave] [nvarchar](80) NOT NULL,
	[descripcion] [nvarchar](180) NOT NULL,
	[createdAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkPermisos] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uqPermisosClave] UNIQUE NONCLUSTERED 
(
	[clave] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[rolPermisos] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rolPermisos](
	[rolId] [int] NOT NULL,
	[permisoId] [int] NOT NULL,
 CONSTRAINT [pkRolPermisos] PRIMARY KEY CLUSTERED 
(
	[rolId] ASC,
	[permisoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[roles] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[roles](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](50) NOT NULL,
	[descripcion] [nvarchar](180) NULL,
	[createdAt] [datetime2](0) NOT NULL,
 CONSTRAINT [pkRoles] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uqRolesNombre] UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Administrador')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (N'Administrador', N'Acceso completo y administración del sistema.', SYSDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Usuario')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (N'Usuario', N'Puede consultar y crear reservas.', SYSDATETIME());
GO
/****** Objeto: Index [ixActividadUsuario] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixActividadUsuario] ON [dbo].[actividad]
(
	[usuarioId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ixAuditoriaUsuario] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixAuditoriaUsuario] ON [dbo].[auditoriaReservas]
(
	[usuarioAppId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ixPagosReserva] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixPagosReserva] ON [dbo].[pagos]
(
	[reservaId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uxPerfilesUsuarioIdentificacion] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [uxPerfilesUsuarioIdentificacion] ON [dbo].[perfilesUsuario]
(
	[identificacion] ASC
)
WHERE ([identificacion] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [uxPerfilesUsuarioUsuario] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [uxPerfilesUsuarioUsuario] ON [dbo].[perfilesUsuario]
(
	[usuarioId] ASC
)
WHERE ([usuarioId] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ixReservasCreadoPor] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixReservasCreadoPor] ON [dbo].[reservas]
(
	[creadoPorUsuarioId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ixReservasEspacio] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixReservasEspacio] ON [dbo].[reservas]
(
	[espacioId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ixReservasFechas] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixReservasFechas] ON [dbo].[reservas]
(
	[fechaInicio] ASC,
	[fechaFin] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ixReservasSolicitante] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixReservasSolicitante] ON [dbo].[reservas]
(
	[solicitantePerfilId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ixUsuariosRol] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
CREATE NONCLUSTERED INDEX [ixUsuariosRol] ON [dbo].[usuarios]
(
	[rolId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
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
/****** Objeto: StoredProcedure [dbo].[paEspacioActualizar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ACTUALIZAR
CREATE   PROCEDURE [dbo].[paEspacioActualizar]
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
/****** Objeto: StoredProcedure [dbo].[paEspacioBuscarPorId] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--BUSCAR POR ID 
CREATE   PROCEDURE [dbo].[paEspacioBuscarPorId]
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
/****** Objeto: StoredProcedure [dbo].[paEspacioEliminar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ELIMINAR 
CREATE   PROCEDURE [dbo].[paEspacioEliminar]
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
/****** Objeto: StoredProcedure [dbo].[paEspacioFiltrar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- FILTRAR / LISTAR 
CREATE   PROCEDURE [dbo].[paEspacioFiltrar]
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
/****** Objeto: StoredProcedure [dbo].[paEspacioInsertar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--INSERTAR 
CREATE   PROCEDURE [dbo].[paEspacioInsertar]
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
/****** Objeto: StoredProcedure [dbo].[paPagoActualizar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   PROCEDIMIENTO: paPagoActualizar
========================================================= */

CREATE   PROCEDURE [dbo].[paPagoActualizar]
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
/****** Objeto: StoredProcedure [dbo].[paPagoBuscarPorId] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Objeto: StoredProcedure [dbo].[paPagoEliminar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   PROCEDIMIENTO: paPagoEliminar
========================================================= */

CREATE   PROCEDURE [dbo].[paPagoEliminar]
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
/****** Objeto: StoredProcedure [dbo].[paPagoFiltrar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Objeto: StoredProcedure [dbo].[paPagoInsertar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =========================================================
   PROCEDIMIENTO: paPagoInsertar
   Descripción:
   Inserta un nuevo pago asociado a una reserva.
========================================================= */

CREATE   PROCEDURE [dbo].[paPagoInsertar]
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
/****** Objeto: StoredProcedure [dbo].[paPerfilActualizar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--ACTUALIZAR PERFIL
CREATE   PROCEDURE [dbo].[paPerfilActualizar]
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
/****** Objeto: StoredProcedure [dbo].[paPerfilBuscarPorId] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- BUSCAR PERFIL POR ID
 
CREATE   PROCEDURE [dbo].[paPerfilBuscarPorId]
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
/****** Objeto: StoredProcedure [dbo].[paPerfilEliminar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--ELIMINAR PERFIL
CREATE   PROCEDURE [dbo].[paPerfilEliminar]
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
/****** Objeto: StoredProcedure [dbo].[paPerfilFiltrar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--FILTRAR PERFILES

CREATE   PROCEDURE [dbo].[paPerfilFiltrar]
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
/****** Objeto: StoredProcedure [dbo].[paPerfilInsertar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  -- INSERTAR PERFIL
 
CREATE   PROCEDURE [dbo].[paPerfilInsertar]
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
/****** Objeto: StoredProcedure [dbo].[paReservaActualizar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[paReservaActualizar]
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
/****** Objeto: StoredProcedure [dbo].[paReservaBuscarPorId] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[paReservaBuscarPorId]
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
/****** Objeto: StoredProcedure [dbo].[paReservaEliminar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[paReservaEliminar]
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
/****** Objeto: StoredProcedure [dbo].[paReservaFiltrar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[paReservaFiltrar]
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
      AND (@pCreadorUsuarioId IS NULL OR r.creadoPorUsuarioId = @pCreadorUsuarioId)
      AND (@pFechaDesde IS NULL OR CONVERT(DATE, r.fechaInicio) >= @pFechaDesde)
      AND (@pFechaHasta IS NULL OR CONVERT(DATE, r.fechaFin) <= @pFechaHasta)
    ORDER BY r.fechaInicio DESC;

    SET @pResultado = 1;
    SET @pMensaje = N'Filtro realizado correctamente.';
    RETURN 1;
END;

GO
/****** Objeto: StoredProcedure [dbo].[paReservaInsertar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ============================================================
   PROCEDIMIENTOS ALMACENADOS - TABLA: reservas
   CRUD + búsqueda + filtrado
   ============================================================ */

CREATE   PROCEDURE [dbo].[paReservaInsertar]
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
/****** Objeto: StoredProcedure [dbo].[paRolFiltrar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   PROCEDIMIENTO: paRolFiltrar
   Lista los roles disponibles
========================================================= */

CREATE   PROCEDURE [dbo].[paRolFiltrar]
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
/****** Objeto: StoredProcedure [dbo].[paUsuarioActualizar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   ACTUALIZAR USUARIO
   La contraseña puede venir NULL.
   Si viene NULL conserva la contraseña anterior.
========================================================= */

CREATE   PROCEDURE [dbo].[paUsuarioActualizar]
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
/****** Objeto: StoredProcedure [dbo].[paUsuarioBuscarPorId] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   PROCEDIMIENTO: paUsuarioBuscarPorId
========================================================= */

CREATE   PROCEDURE [dbo].[paUsuarioBuscarPorId]
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
/****** Objeto: StoredProcedure [dbo].[paUsuarioEliminar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   PROCEDIMIENTO: paUsuarioEliminar
========================================================= */

CREATE   PROCEDURE [dbo].[paUsuarioEliminar]
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
/****** Objeto: StoredProcedure [dbo].[paUsuarioFiltrar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =========================================================
   PROCEDIMIENTO: paUsuarioFiltrar
   Lista y filtra los usuarios del sistema
========================================================= */

CREATE   PROCEDURE [dbo].[paUsuarioFiltrar]
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
/****** Objeto: StoredProcedure [dbo].[paUsuarioInsertar] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =========================================================
   PROCEDIMIENTO: paUsuarioInsertar
   Crea un nuevo usuario
========================================================= */

CREATE   PROCEDURE [dbo].[paUsuarioInsertar]
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
/****** Objeto: StoredProcedure [dbo].[paUsuarioLogin] Fecha de script: 24/09/2026 09:13:58 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[paUsuarioLogin]
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
/****** Procedimiento: estado de salud de la base de datos ******/
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
/****** Procedimiento: registrar eventos de autenticación ******/
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
/****** Procedimiento: resumen de auditoría ******/
CREATE PROCEDURE [dbo].[paAuditoriaResumen]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT origen, evento, totalEventos, ultimoEvento
    FROM dbo.vAuditoriaResumen
    ORDER BY ultimoEvento DESC, origen, evento;
END;
GO
/****** Procedimientos: catálogo de respaldos creados por la aplicación ******/
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
/****** Procedimiento: opciones mínimas de perfil para crear reservas ******/
CREATE PROCEDURE [dbo].[paPerfilOpcionesReserva]
    @pUsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idPerfil, nombre, tipoPerfil
    FROM dbo.perfilesUsuario
    WHERE @pUsuarioId IS NULL OR usuarioId = @pUsuarioId
    ORDER BY nombre;
END;
GO
/****** Trigger: auditoría de cambios en espacios ******/
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
        NULL, NULL, @usuarioBd, SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.id = i.id;
END;
GO
/****** Trigger: auditoría de cambios en perfiles ******/
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
        NULL, NULL, @usuarioBd, SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.idPerfil = i.idPerfil;
END;
GO
/****** Trigger: auditoría de cambios en usuarios (sin credenciales ni correo) ******/
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
        NULL, NULL, @usuarioBd, SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.id = i.id;
END;
GO
/****** Trigger: auditoría de cambios en reservas (sin datos de contacto) ******/
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
        NULL, NULL, @usuarioBd, SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.id = i.id;
END;
GO
/****** Trigger: auditoría de cambios en pagos ******/
CREATE TRIGGER [dbo].[trgPagosAuditoria]
ON [dbo].[pagos]
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
        N'pagos',
        COALESCE(i.id, d.id),
        CASE
            WHEN d.id IS NULL THEN N'INSERT'
            WHEN i.id IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        (
            SELECT
                JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.reservaId, d.monto, d.metodo, d.fechaPago, d.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.reservaId, i.monto, i.metodo, i.fechaPago, i.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS despues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        NULL, NULL, @usuarioBd, SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.id = i.id;
END;
GO
USE [master]
GO
ALTER DATABASE [reservasScouts] SET  READ_WRITE 
