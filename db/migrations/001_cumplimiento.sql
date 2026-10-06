USE [reservasScouts];
GO

IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Administrador')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (N'Administrador', N'Acceso completo y administración del sistema.', SYSDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Usuario')
    INSERT INTO dbo.roles (nombre, descripcion, createdAt)
    VALUES (N'Usuario', N'Puede consultar y crear reservas.', SYSDATETIME());
GO

IF OBJECT_ID(N'dbo.auditoriaAccesos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoriaAccesos
    (
        idAuditoriaAcceso BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT pkAuditoriaAccesos PRIMARY KEY CLUSTERED,
        usuarioId INT NULL,
        evento NVARCHAR(20) NOT NULL,
        direccionIp VARCHAR(45) NULL,
        agenteUsuario NVARCHAR(300) NULL,
        creadoEn DATETIME2(0) NOT NULL,
        CONSTRAINT ckAuditoriaAccesosEvento
            CHECK (evento IN (N'LOGIN', N'LOGIN_FALLIDO', N'LOGOUT'))
    );
    CREATE NONCLUSTERED INDEX ixAuditoriaAccesosUsuarioFecha
        ON dbo.auditoriaAccesos (usuarioId, creadoEn DESC);
END;
IF OBJECT_ID(N'dbo.respaldoHistorial', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.respaldoHistorial
    (
        idRespaldo BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT pkRespaldoHistorial PRIMARY KEY CLUSTERED,
        nombreArchivo NVARCHAR(120) NOT NULL
            CONSTRAINT uqRespaldoHistorialNombre UNIQUE,
        creadoPorUsuarioId INT NULL,
        creadoEn DATETIME2(0) NOT NULL,
        bytes BIGINT NOT NULL,
        CONSTRAINT ckRespaldoHistorialBytes CHECK (bytes >= 0),
        CONSTRAINT fkRespaldoHistorialUsuario
            FOREIGN KEY (creadoPorUsuarioId) REFERENCES dbo.usuarios(id) ON DELETE SET NULL
    );
    CREATE NONCLUSTERED INDEX ixRespaldoHistorialFecha
        ON dbo.respaldoHistorial (creadoEn DESC);
END;
IF OBJECT_ID(N'dbo.ckAuditoriaAccesosEvento', N'C') IS NOT NULL
    ALTER TABLE dbo.auditoriaAccesos DROP CONSTRAINT ckAuditoriaAccesosEvento;
ALTER TABLE dbo.auditoriaAccesos
    ADD CONSTRAINT ckAuditoriaAccesosEvento
    CHECK (evento IN (N'LOGIN', N'LOGIN_FALLIDO', N'LOGOUT', N'BACKUP', N'RESTORE'));
GO

CREATE OR ALTER VIEW dbo.vAuditoriaResumen
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
        N'auditoriaAccesos',
        evento COLLATE DATABASE_DEFAULT,
        COUNT_BIG(*),
        MAX(creadoEn)
    FROM dbo.auditoriaAccesos
    GROUP BY evento;
GO

IF DATABASE_PRINCIPAL_ID(N'reservas_consulta') IS NULL
    CREATE USER reservas_consulta WITHOUT LOGIN;
GRANT SELECT ON OBJECT::dbo.vReservasResumen TO reservas_consulta;
GRANT SELECT ON OBJECT::dbo.vPerfilesConfidencial TO reservas_consulta;
IF SUSER_ID(N'reservas_maintenance') IS NOT NULL
BEGIN
    IF DATABASE_PRINCIPAL_ID(N'reservas_maintenance') IS NULL
        CREATE USER reservas_maintenance FOR LOGIN reservas_maintenance;
    IF IS_ROLEMEMBER(N'db_backupoperator', N'reservas_maintenance') <> 1
        ALTER ROLE db_backupoperator ADD MEMBER reservas_maintenance;
END;
IF DATABASE_PRINCIPAL_ID(N'reservasApp') IS NOT NULL
BEGIN
    IF IS_ROLEMEMBER(N'db_datareader', N'reservasApp') = 1
        ALTER ROLE db_datareader DROP MEMBER reservasApp;
    IF IS_ROLEMEMBER(N'db_datawriter', N'reservasApp') = 1
        ALTER ROLE db_datawriter DROP MEMBER reservasApp;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paRolFiltrar
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
        SET @pNombre = NULLIF(LTRIM(RTRIM(@pNombre)), N'');
        SET @pDescripcion = NULLIF(LTRIM(RTRIM(@pDescripcion)), N'');

        SELECT id, nombre, descripcion, createdAt
        FROM dbo.roles
        WHERE (@pNombre IS NULL OR nombre LIKE N'%' + @pNombre + N'%')
          AND (@pDescripcion IS NULL OR descripcion LIKE N'%' + @pDescripcion + N'%')
        ORDER BY nombre ASC;

        SET @pResultado = 1;
        SET @pMensaje = N'Consulta realizada correctamente.';
    END TRY
    BEGIN CATCH
        SET @pResultado = 0;
        SET @pMensaje = LEFT(ERROR_MESSAGE(), 250);
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paAuditoriaAccesoRegistrar
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

CREATE OR ALTER PROCEDURE dbo.paAuditoriaResumen
AS
BEGIN
    SET NOCOUNT ON;
    SELECT origen, evento, totalEventos, ultimoEvento
    FROM dbo.vAuditoriaResumen
    ORDER BY ultimoEvento DESC, origen, evento;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paPerfilOpcionesReserva
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idPerfil, nombre, tipoPerfil
    FROM dbo.perfilesUsuario
    ORDER BY nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paRespaldoListar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nombreArchivo AS nombre, creadoEn, bytes
    FROM dbo.respaldoHistorial
    ORDER BY creadoEn DESC, idRespaldo DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paRespaldoRegistrar
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

CREATE OR ALTER TRIGGER dbo.trgEspaciosAuditoria
ON dbo.espacios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.auditoriaReservas
        (tabla, idRegistro, accion, detalle, usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn)
    SELECT
        N'espacios',
        COALESCE(i.id, d.id),
        CASE WHEN d.id IS NULL THEN N'INSERT' WHEN i.id IS NULL THEN N'DELETE' ELSE N'UPDATE' END,
        (SELECT JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.nombre, d.ubicacion, d.capacidad, d.costo, d.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.nombre, i.ubicacion, i.capacidad, i.costo, i.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS despues
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        NULL, NULL, LEFT(ORIGINAL_LOGIN(), 120), SYSDATETIME()
    FROM inserted i FULL OUTER JOIN deleted d ON d.id = i.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.trgPerfilesUsuarioAuditoria
ON dbo.perfilesUsuario
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.auditoriaReservas
        (tabla, idRegistro, accion, detalle, usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn)
    SELECT
        N'perfilesUsuario',
        COALESCE(i.idPerfil, d.idPerfil),
        CASE WHEN d.idPerfil IS NULL THEN N'INSERT' WHEN i.idPerfil IS NULL THEN N'DELETE' ELSE N'UPDATE' END,
        (SELECT JSON_QUERY(CASE WHEN d.idPerfil IS NOT NULL THEN
                    (SELECT d.usuarioId, d.tipoPerfil
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS antes,
                JSON_QUERY(CASE WHEN i.idPerfil IS NOT NULL THEN
                    (SELECT i.usuarioId, i.tipoPerfil
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS despues
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        NULL, NULL, LEFT(ORIGINAL_LOGIN(), 120), SYSDATETIME()
    FROM inserted i FULL OUTER JOIN deleted d ON d.idPerfil = i.idPerfil;
END;
GO

CREATE OR ALTER TRIGGER dbo.trgUsuariosAuditoria
ON dbo.usuarios
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.auditoriaReservas
        (tabla, idRegistro, accion, detalle, usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn)
    SELECT
        N'usuarios',
        COALESCE(i.id, d.id),
        CASE WHEN d.id IS NULL THEN N'INSERT' WHEN i.id IS NULL THEN N'DELETE' ELSE N'UPDATE' END,
        (SELECT JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.rolId, d.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.rolId, i.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS despues
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        NULL, NULL, LEFT(ORIGINAL_LOGIN(), 120), SYSDATETIME()
    FROM inserted i FULL OUTER JOIN deleted d ON d.id = i.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.trgReservasAuditoria
ON dbo.reservas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.auditoriaReservas
        (tabla, idRegistro, accion, detalle, usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn)
    SELECT
        N'reservas',
        COALESCE(i.id, d.id),
        CASE WHEN d.id IS NULL THEN N'INSERT' WHEN i.id IS NULL THEN N'DELETE' ELSE N'UPDATE' END,
        (SELECT JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.codigo, d.espacioId, d.solicitantePerfilId,
                            d.fechaInicio, d.fechaFin, d.estado, d.participantes
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.codigo, i.espacioId, i.solicitantePerfilId,
                            i.fechaInicio, i.fechaFin, i.estado, i.participantes
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS despues
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        NULL, NULL, LEFT(ORIGINAL_LOGIN(), 120), SYSDATETIME()
    FROM inserted i FULL OUTER JOIN deleted d ON d.id = i.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.trgPagosAuditoria
ON dbo.pagos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.auditoriaReservas
        (tabla, idRegistro, accion, detalle, usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn)
    SELECT
        N'pagos',
        COALESCE(i.id, d.id),
        CASE WHEN d.id IS NULL THEN N'INSERT' WHEN i.id IS NULL THEN N'DELETE' ELSE N'UPDATE' END,
        (SELECT JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN
                    (SELECT d.reservaId, d.monto, d.metodo, d.fechaPago, d.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS antes,
                JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN
                    (SELECT i.reservaId, i.monto, i.metodo, i.fechaPago, i.estado
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) END) AS despues
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        NULL, NULL, LEFT(ORIGINAL_LOGIN(), 120), SYSDATETIME()
    FROM inserted i FULL OUTER JOIN deleted d ON d.id = i.id;
END;
GO
