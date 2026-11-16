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
