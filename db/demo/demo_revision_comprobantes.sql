-- Seis reservas ficticias: dos metodos x pendiente/aprobado/rechazado.
-- No modifica reservas reales ni recrea ejemplos que fueron eliminados.
USE reservasScouts;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
GO
BEGIN TRY
BEGIN TRANSACTION;
DECLARE @usuario INT=(SELECT id FROM dbo.usuarios WHERE email=N'usuario@reservasscouts.test'),
    @admin INT=(SELECT id FROM dbo.usuarios WHERE email=N'admin@reservasscouts.test'),
    @perfil INT,@espacio INT,@costo DECIMAL(12,2);
SELECT TOP(1) @perfil=idPerfil FROM dbo.perfilesUsuario WHERE usuarioId=@usuario ORDER BY idPerfil;
SELECT TOP(1) @espacio=id,@costo=costo FROM dbo.espacios WHERE nombre=N'Campo Scout Demo' ORDER BY id;
IF @usuario IS NULL OR @perfil IS NULL OR @admin IS NULL OR @espacio IS NULL OR @costo<=0
    THROW 51100,N'Primero instala los datos base DEMO. No se utilizan cuentas o espacios reales.',1;
EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=@admin;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=N'Datos ficticios de comprobantes';
DECLARE @n INT,@codigo NVARCHAR(20),@metodo NVARCHAR(30),@reserva INT,@id INT,@ok TINYINT,@mensaje NVARCHAR(250),
    @inicio DATETIME2(0),@fin DATETIME2(0),@hoy DATE=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE);
DECLARE ejemplos CURSOR LOCAL FAST_FORWARD FOR SELECT * FROM (VALUES
 (1,N'DEMO-COMP-S-P',N'SINPE Móvil'),(2,N'DEMO-COMP-S-A',N'SINPE Móvil'),(3,N'DEMO-COMP-S-R',N'SINPE Móvil'),
 (4,N'DEMO-COMP-T-P',N'Transferencia bancaria'),(5,N'DEMO-COMP-T-A',N'Transferencia bancaria'),(6,N'DEMO-COMP-T-R',N'Transferencia bancaria')
) d(n,codigo,metodo);
OPEN ejemplos;
FETCH NEXT FROM ejemplos INTO @n,@codigo,@metodo;
WHILE @@FETCH_STATUS=0
BEGIN
    SET @reserva=NULL;
    SELECT @reserva=id FROM dbo.reservas WHERE codigo=@codigo;
    IF @reserva IS NULL AND NOT EXISTS(SELECT 1 FROM dbo.reservasEliminadas WHERE JSON_VALUE(reservaJson,'$.codigo')=@codigo)
    BEGIN
        SET @inicio=DATEADD(HOUR,9,CAST(DATEADD(DAY,90+@n,@hoy) AS DATETIME2(0)));
        SET @fin=DATEADD(HOUR,2,@inicio);
        EXEC dbo.paReservaInsertar @pCodigo=@codigo,@pEspacioId=@espacio,@pSolicitantePerfilId=@perfil,
            @pCreadoPorUsuarioId=@usuario,@pResponsable=N'Persona de demostracion',@pTelefono=N'00000000',
            @pEmail=N'demo@example.com',@pParticipantes=1,@pTipoActividad=N'DEMO revision de comprobantes',
            @pFechaInicio=@inicio,@pFechaFin=@fin,@pEstado=N'PENDIENTE',
            @pObservaciones=N'Datos ficticios. No existe un pago ni una reserva real.',
            @pIdGenerado=@reserva OUTPUT,@pResultado=@ok OUTPUT,@pMensaje=@mensaje OUTPUT;
        IF @ok<>1 THROW 51101,@mensaje,1;
    END;
    IF @reserva IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.pagos WHERE reservaId=@reserva)
    BEGIN
        EXEC dbo.paPagoInsertar @pReservaId=@reserva,@pMonto=@costo,@pMetodo=@metodo,@pFechaPago=@hoy,
            @pEstado=N'PENDIENTE',@pNotas=N'[DEMO-COMP] Archivo ficticio para revision; no hubo cobro real.',
            @pIdGenerado=@id OUTPUT,@pResultado=@ok OUTPUT,@pMensaje=@mensaje OUTPUT;
        IF @ok<>1 THROW 51102,@mensaje,1;
    END;
    FETCH NEXT FROM ejemplos INTO @n,@codigo,@metodo;
END;
CLOSE ejemplos;
DEALLOCATE ejemplos;
COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;
EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=NULL;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=NULL;
GO
