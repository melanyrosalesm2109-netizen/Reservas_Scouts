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
