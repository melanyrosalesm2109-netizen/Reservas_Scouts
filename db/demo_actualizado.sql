-- Actualiza SOLO datos ficticios identificados por codigos DEMO.
-- Las reservas personales y sus pagos se conservan.
USE reservasScouts;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRY
BEGIN TRANSACTION;
DECLARE @id INT,@ok TINYINT,@mensaje NVARCHAR(250);

-- Cuentas anteriores que no tenian perfil: vinculo explicito, nunca por secuencia.
DECLARE @usuario INT,@correo NVARCHAR(160),@nombre NVARCHAR(160);
DECLARE cuentas CURSOR LOCAL FAST_FORWARD FOR
SELECT u.id,u.email,d.nombre FROM (VALUES
    (N'admin@reservasscouts.com',N'Administrador principal Demo'),
    (N'invitado@example.com',N'Invitado Demo')
) d(email,nombre) JOIN dbo.usuarios u ON u.email=d.email
WHERE NOT EXISTS(SELECT 1 FROM dbo.perfilesUsuario p WHERE p.usuarioId=u.id);
OPEN cuentas;
FETCH NEXT FROM cuentas INTO @usuario,@correo,@nombre;
WHILE @@FETCH_STATUS=0
BEGIN
    EXEC dbo.paPerfilInsertar @pUsuarioId=@usuario,@pNombre=@nombre,@pTelefono=N'00000000',
        @pCorreoContacto=@correo,@pTipoPerfil=N'Persona',@pDireccion=N'Datos ficticios de demostracion',
        @pIdGenerado=@id OUTPUT,@pResultado=@ok OUTPUT,@pMensaje=@mensaje OUTPUT;
    IF @ok<>1 THROW 51100,@mensaje,1;
    FETCH NEXT FROM cuentas INTO @usuario,@correo,@nombre;
END;
CLOSE cuentas;
DEALLOCATE cuentas;

DECLARE @admin INT=(SELECT id FROM dbo.usuarios WHERE email=N'admin@reservasscouts.test');
UPDATE dbo.reservas SET creadoPorUsuarioId=@admin,updatedAt=SYSDATETIME()
WHERE codigo LIKE N'DEMO-CAL-%' AND creadoPorUsuarioId IS NULL;
UPDATE dbo.reservas SET estado=N'FINALIZADA',updatedAt=SYSDATETIME() WHERE codigo=N'DEMO-RES-001';
UPDATE dbo.reservas SET estado=N'CANCELADA',updatedAt=SYSDATETIME() WHERE codigo=N'DEMO-CAL-008';
-- Se conserva el efectivo registrado manualmente; el comprobante antiguo no verificado se rechaza.
UPDATE p SET estado=N'RECHAZADO',notas=N'[DEMO-ACT-HIST-TRANSFER] Comprobante ficticio anterior sin verificar; no es un pago real.',updatedAt=SYSDATETIME()
FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId
WHERE r.codigo=N'DEMO-RES-001' AND p.comprobante=N'DEMO-PAGO-001' AND p.estado=N'PENDIENTE';
-- El efectivo de una reserva futura se cobra al llegar.
UPDATE p SET estado=N'PENDIENTE',fechaPago=CAST(r.fechaInicio AS DATE),
    notas=N'[DEMO-ACT-EFECTIVO] Pago ficticio pendiente para la llegada.',updatedAt=SYSDATETIME()
FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId
WHERE r.codigo=N'DEMO-CAL-004' AND p.comprobante=N'DEMO-PAGO-003'
AND CHARINDEX(N'[DEMO-ACT-EFECTIVO]',ISNULL(p.notas,N''))=0;

DECLARE @campo INT=(SELECT id FROM dbo.espacios WHERE nombre=N'Campo Scout Demo');
DECLARE @salon INT=(SELECT id FROM dbo.espacios WHERE nombre=N'Salón Scout Demo');
DECLARE @zona INT=(SELECT id FROM dbo.espacios WHERE nombre=N'Zona de campamento Demo');
DECLARE @regular INT=(SELECT id FROM dbo.usuarios WHERE email=N'usuario@reservasscouts.test');
DECLARE @miembro INT=(SELECT id FROM dbo.usuarios WHERE email=N'miembro@reservasscouts.test');
DECLARE @perfilRegular INT=(SELECT TOP(1) idPerfil FROM dbo.perfilesUsuario WHERE usuarioId=@regular ORDER BY idPerfil);
DECLARE @perfilMiembro INT=(SELECT TOP(1) idPerfil FROM dbo.perfilesUsuario WHERE usuarioId=@miembro ORDER BY idPerfil);
IF @campo IS NULL OR @salon IS NULL OR @zona IS NULL OR @perfilRegular IS NULL OR @perfilMiembro IS NULL
    THROW 51101,N'Faltan datos base de demostracion.',1;
DECLARE @codigo NVARCHAR(20),@espacio INT,@perfil INT,@creador INT,@inicio DATETIME2(0),@fin DATETIME2(0),@estado NVARCHAR(20),@actividad NVARCHAR(120);
DECLARE nuevas CURSOR LOCAL FAST_FORWARD FOR
SELECT * FROM (VALUES
 (N'DEMO-FLUJO-001',@salon,@perfilRegular,@regular,'2026-11-23T09:00:00','2026-11-23T12:00:00',N'APROBADA',N'Efectivo pendiente al llegar'),
 (N'DEMO-FLUJO-002',@campo,@perfilMiembro,@miembro,'2026-12-01T08:00:00','2026-12-01T17:00:00',N'PENDIENTE',N'SINPE por verificar'),
 (N'DEMO-FLUJO-003',@salon,@perfilRegular,@regular,'2026-11-24T09:00:00','2026-11-24T15:00:00',N'PENDIENTE',N'Transferencia por verificar'),
 (N'DEMO-FLUJO-004',@zona,@perfilMiembro,@miembro,'2026-12-10T08:00:00','2026-12-10T17:00:00',N'APROBADA',N'Tarjeta simulada aprobada'),
 (N'DEMO-FLUJO-005',@zona,@perfilRegular,@regular,'2026-12-12T08:00:00','2026-12-12T17:00:00',N'APROBADA',N'SINPE verificado de ejemplo'),
 (N'DEMO-FLUJO-006',@salon,@perfilMiembro,@miembro,'2026-12-02T09:00:00','2026-12-02T15:00:00',N'CANCELADA',N'Transferencia rechazada: fecha liberada')
) d(codigo,espacio,perfil,creador,inicio,fin,estado,actividad);
OPEN nuevas;
FETCH NEXT FROM nuevas INTO @codigo,@espacio,@perfil,@creador,@inicio,@fin,@estado,@actividad;
WHILE @@FETCH_STATUS=0
BEGIN
    IF NOT EXISTS(SELECT 1 FROM dbo.reservas WHERE codigo=@codigo)
    BEGIN
        EXEC dbo.paReservaInsertar @pCodigo=@codigo,@pEspacioId=@espacio,@pSolicitantePerfilId=@perfil,
            @pCreadoPorUsuarioId=@creador,@pResponsable=N'Responsable Demo',@pTelefono=N'00000000',
            @pEmail=N'demo@example.com',@pParticipantes=12,@pTipoActividad=@actividad,
            @pFechaInicio=@inicio,@pFechaFin=@fin,@pEstado=@estado,
            @pObservaciones=N'[DEMO-ACT] Datos ficticios para probar pagos y calendario. No es una reserva real.',
            @pIdGenerado=@id OUTPUT,@pResultado=@ok OUTPUT,@pMensaje=@mensaje OUTPUT;
        IF @ok<>1 THROW 51102,@mensaje,1;
    END;
    FETCH NEXT FROM nuevas INTO @codigo,@espacio,@perfil,@creador,@inicio,@fin,@estado,@actividad;
END;
CLOSE nuevas;
DEALLOCATE nuevas;

-- Los ejemplos personales usan el contacto real de su perfil de demostracion.
UPDATE r SET responsable=p.nombre,telefono=ISNULL(NULLIF(p.telefono,N''),N'00000000'),
    email=p.correoContacto,grupo=NULL,updatedAt=SYSDATETIME()
FROM dbo.reservas r JOIN dbo.perfilesUsuario p ON p.idPerfil=r.solicitantePerfilId
WHERE r.codigo LIKE N'DEMO-FLUJO-%' AND p.tipoPerfil=N'Persona';

DECLARE @reserva INT,@metodo NVARCHAR(30),@estadoPago NVARCHAR(15),@clave NVARCHAR(100),@monto DECIMAL(12,2),@fecha DATE;
DECLARE pagosDemo CURSOR LOCAL FAST_FORWARD FOR
SELECT r.id,d.metodo,d.estado,d.clave,
    CASE WHEN r.codigo=N'DEMO-RES-001' THEN e.costo-ISNULL((SELECT SUM(p.monto) FROM dbo.pagos p WHERE p.reservaId=r.id AND p.estado=N'PAGADO'),0) ELSE e.costo END,
    CASE WHEN d.metodo=N'Efectivo' THEN CAST(r.fechaInicio AS DATE) ELSE CAST('2026-11-14' AS DATE) END
FROM (VALUES
 (N'DEMO-RES-001',N'Efectivo',N'PAGADO',N'DEMO-ACT-SALDO-HIST'),
 (N'DEMO-CAL-001',N'Tarjeta',N'PAGADO',N'DEMO-ACT-CAL-001'),
 (N'DEMO-CAL-002',N'Transferencia bancaria',N'PENDIENTE',N'DEMO-ACT-CAL-002'),
 (N'DEMO-CAL-003',N'SINPE Móvil',N'RECHAZADO',N'DEMO-ACT-CAL-003'),
 (N'DEMO-CAL-005',N'SINPE Móvil',N'PENDIENTE',N'DEMO-ACT-CAL-005'),
 (N'DEMO-CAL-006',N'Efectivo',N'PAGADO',N'DEMO-ACT-CAL-006'),
 (N'DEMO-CAL-007',N'Tarjeta',N'PAGADO',N'DEMO-ACT-CAL-007'),
 (N'DEMO-FLUJO-001',N'Efectivo',N'PENDIENTE',N'DEMO-ACT-FLUJO-001'),
 (N'DEMO-FLUJO-002',N'SINPE Móvil',N'PENDIENTE',N'DEMO-ACT-FLUJO-002'),
 (N'DEMO-FLUJO-003',N'Transferencia bancaria',N'PENDIENTE',N'DEMO-ACT-FLUJO-003'),
 (N'DEMO-FLUJO-004',N'Tarjeta',N'PAGADO',N'DEMO-ACT-FLUJO-004'),
 (N'DEMO-FLUJO-005',N'SINPE Móvil',N'PAGADO',N'DEMO-ACT-FLUJO-005'),
 (N'DEMO-FLUJO-006',N'Transferencia bancaria',N'RECHAZADO',N'DEMO-ACT-FLUJO-006')
) d(codigo,metodo,estado,clave) JOIN dbo.reservas r ON r.codigo=d.codigo JOIN dbo.espacios e ON e.id=r.espacioId;
OPEN pagosDemo;
FETCH NEXT FROM pagosDemo INTO @reserva,@metodo,@estadoPago,@clave,@monto,@fecha;
WHILE @@FETCH_STATUS=0
BEGIN
    IF @monto>0 AND NOT EXISTS(SELECT 1 FROM dbo.pagos WHERE reservaId=@reserva AND CHARINDEX(N'['+@clave+N']',notas)=1)
    BEGIN
        DECLARE @notas NVARCHAR(MAX)=N'['+@clave+N'] Datos ficticios de demostracion. No hubo cobro real.';
        EXEC dbo.paPagoInsertar @pReservaId=@reserva,@pMonto=@monto,@pMetodo=@metodo,@pFechaPago=@fecha,
            @pEstado=@estadoPago,@pNotas=@notas,
            @pIdGenerado=@id OUTPUT,@pResultado=@ok OUTPUT,@pMensaje=@mensaje OUTPUT;
        IF @ok<>1 THROW 51103,@mensaje,1;
    END;
    FETCH NEXT FROM pagosDemo INTO @reserva,@metodo,@estadoPago,@clave,@monto,@fecha;
END;
CLOSE pagosDemo;
DEALLOCATE pagosDemo;
COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;
GO
