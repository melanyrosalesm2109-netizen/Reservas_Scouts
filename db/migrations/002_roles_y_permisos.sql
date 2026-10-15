USE [reservasScouts];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Recepcionista')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Recepcionista', N'Gestiona reservas y pagos; consulta espacios y perfiles.', SYSDATETIME());

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Miembro')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Miembro', N'Puede crear reservas y consultar las propias.', SYSDATETIME());

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Usuario')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Usuario', N'Puede crear reservas y consultar las propias.', SYSDATETIME());

    UPDATE dbo.roles
    SET descripcion = N'Puede crear reservas y consultar las propias.'
    WHERE nombre = N'Usuario';

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.usuarios
        WHERE email = N'usuario@reservasscouts.test'
    )
        UPDATE dbo.usuarios
        SET email = N'usuario@reservasscouts.test',
            updatedAt = SYSDATETIME()
        WHERE email = N'invitado@reservasscouts.test';

    UPDATE u
    SET rolId = usuarioRol.id,
        updatedAt = SYSDATETIME()
    FROM dbo.usuarios AS u
    INNER JOIN dbo.roles AS invitadoRol ON invitadoRol.id = u.rolId
    CROSS JOIN
    (
        SELECT id FROM dbo.roles WHERE nombre = N'Usuario'
    ) AS usuarioRol
    WHERE invitadoRol.nombre = N'Invitado';

    DELETE FROM dbo.roles WHERE nombre = N'Invitado';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

CREATE OR ALTER PROCEDURE dbo.paReservaFiltrar
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

CREATE OR ALTER PROCEDURE dbo.paPerfilOpcionesReserva
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
