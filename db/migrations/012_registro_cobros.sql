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
