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
