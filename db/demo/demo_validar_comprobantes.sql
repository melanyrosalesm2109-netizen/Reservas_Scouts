-- Ejecutar despues de demo_revision_comprobantes.sql y demo_comprobantes.ps1.
USE reservasScouts;
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
DECLARE @admin INT=(SELECT id FROM dbo.usuarios WHERE email=N'admin@reservasscouts.test');
IF @admin IS NULL THROW 51100,N'No existe la cuenta administradora DEMO.',1;
EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=@admin;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=N'Datos ficticios de comprobantes';
DECLARE @pago INT,@aprobar BIT,@motivo NVARCHAR(500);
DECLARE revisiones CURSOR LOCAL FAST_FORWARD FOR
SELECT p.id,CAST(CASE WHEN RIGHT(r.codigo,1)=N'A' THEN 1 ELSE 0 END AS BIT)
FROM dbo.reservas r JOIN dbo.pagos p ON p.reservaId=r.id
WHERE r.codigo IN(N'DEMO-COMP-S-A',N'DEMO-COMP-S-R',N'DEMO-COMP-T-A',N'DEMO-COMP-T-R')
    AND p.estado=N'PENDIENTE' AND EXISTS(SELECT 1 FROM dbo.pagoComprobantes c WHERE c.pagoId=p.id);
OPEN revisiones;
FETCH NEXT FROM revisiones INTO @pago,@aprobar;
WHILE @@FETCH_STATUS=0
BEGIN
    SET @motivo=CASE WHEN @aprobar=1 THEN N'DEMO: referencia y monto coinciden con el registro.'
        ELSE N'DEMO: el monto del comprobante no coincide con el monto de la reserva.' END;
    EXEC dbo.paPagoVerificar @pago,@aprobar,@admin,@motivo;
    FETCH NEXT FROM revisiones INTO @pago,@aprobar;
END;
CLOSE revisiones;
DEALLOCATE revisiones;
EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=NULL;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=NULL;
GO
