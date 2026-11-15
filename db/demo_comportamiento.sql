-- Datos ficticios para explorar el sistema. Solo agrega registros ausentes.
-- Ejecutar en la base local con: sqlcmd -S localhost -E -C -b -f 65001 -i db/demo_comportamiento.sql
USE reservasScouts;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ANSI_PADDING ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @id INT, @ok TINYINT, @mensaje NVARCHAR(250);
  DECLARE @nombre NVARCHAR(120), @estadoEspacio NVARCHAR(20), @capacidad INT, @costo DECIMAL(12,2);
  DECLARE espaciosDemo CURSOR LOCAL FAST_FORWARD FOR
    SELECT * FROM (VALUES
      (N'Zona de campamento Demo', N'DISPONIBLE', 80, 35000),
      (N'Rancho Demo en mantenimiento', N'MANTENIMIENTO', 25, 18000),
      (N'Aula Demo inactiva', N'INACTIVO', 20, 10000)
    ) d(nombre, estado, capacidad, costo);
  OPEN espaciosDemo;
  FETCH NEXT FROM espaciosDemo INTO @nombre, @estadoEspacio, @capacidad, @costo;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE nombre = @nombre)
    BEGIN
      EXEC dbo.paEspacioInsertar @pNombre=@nombre,
        @pDescripcion=N'Datos de demostración. Espacio ficticio para probar filtros, capacidad y reservas.',
        @pUbicacion=N'Sede de demostración, Costa Rica', @pCapacidad=@capacidad, @pCosto=@costo,
        @pEstado=@estadoEspacio, @pImagen=N'/images/espacios/campo-demo.png',
        @pIdGenerado=@id OUTPUT, @pResultado=@ok OUTPUT, @pMensaje=@mensaje OUTPUT;
      IF @ok <> 1 THROW 51000, @mensaje, 1;
    END;
    FETCH NEXT FROM espaciosDemo INTO @nombre, @estadoEspacio, @capacidad, @costo;
  END;
  CLOSE espaciosDemo;
  DEALLOCATE espaciosDemo;

  DECLARE @perfilNombre NVARCHAR(160), @correo NVARCHAR(160);
  DECLARE perfilesDemo CURSOR LOCAL FAST_FORWARD FOR
    SELECT * FROM (VALUES
      (N'Grupo Demo Exploradores', N'exploradores.demo@example.com'),
      (N'Grupo Demo Caminantes', N'caminantes.demo@example.com')
    ) d(nombre, correo);
  OPEN perfilesDemo;
  FETCH NEXT FROM perfilesDemo INTO @perfilNombre, @correo;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.perfilesUsuario WHERE correoContacto = @correo)
    BEGIN
      EXEC dbo.paPerfilInsertar @pNombre=@perfilNombre, @pTelefono=N'00000000',
        @pCorreoContacto=@correo, @pTipoPerfil=N'Grupo Scout',
        @pDireccion=N'Perfil ficticio de demostración',
        @pIdGenerado=@id OUTPUT, @pResultado=@ok OUTPUT, @pMensaje=@mensaje OUTPUT;
      IF @ok <> 1 THROW 51001, @mensaje, 1;
    END;
    FETCH NEXT FROM perfilesDemo INTO @perfilNombre, @correo;
  END;
  CLOSE perfilesDemo;
  DEALLOCATE perfilesDemo;

  DECLARE @campo INT = (SELECT TOP (1) id FROM dbo.espacios WHERE nombre=N'Campo Scout Demo');
  DECLARE @salon INT = (SELECT TOP (1) id FROM dbo.espacios WHERE nombre=N'Salón Scout Demo');
  DECLARE @zona INT = (SELECT TOP (1) id FROM dbo.espacios WHERE nombre=N'Zona de campamento Demo');
  DECLARE @exploradores INT = (SELECT TOP (1) idPerfil FROM dbo.perfilesUsuario WHERE correoContacto=N'exploradores.demo@example.com');
  DECLARE @caminantes INT = (SELECT TOP (1) idPerfil FROM dbo.perfilesUsuario WHERE correoContacto=N'caminantes.demo@example.com');
  IF @campo IS NULL OR @salon IS NULL THROW 51002, N'Faltan los espacios Campo Scout Demo y Salón Scout Demo. No se agregaron datos.', 1;
  DECLARE @codigo NVARCHAR(20), @espacio INT, @perfil INT, @participantes INT,
    @actividad NVARCHAR(120), @inicio DATETIME2(0), @fin DATETIME2(0), @estado NVARCHAR(20);
  DECLARE reservasDemo CURSOR LOCAL FAST_FORWARD FOR
    SELECT * FROM (VALUES
      (N'DEMO-CAL-001', @campo, @exploradores, 35, N'Campamento de fin de semana', '2026-11-20T08:00:00', '2026-11-22T17:00:00', N'APROBADA'),
      (N'DEMO-CAL-002', @campo, @caminantes, 25, N'Taller de orientación', '2026-11-25T08:00:00', '2026-11-25T12:00:00', N'PENDIENTE'),
      (N'DEMO-CAL-003', @campo, @exploradores, 20, N'Actividad cancelada: fecha liberada', '2026-11-27T09:00:00', '2026-11-27T16:00:00', N'CANCELADA'),
      (N'DEMO-CAL-004', @salon, @caminantes, 18, N'Reunión de planificación', '2026-11-18T09:00:00', '2026-11-18T12:00:00', N'APROBADA'),
      (N'DEMO-CAL-005', @salon, @exploradores, 22, N'Taller de primeros auxilios', '2026-11-18T14:00:00', '2026-11-18T18:00:00', N'PENDIENTE'),
      (N'DEMO-CAL-006', @salon, @caminantes, 15, N'Reunión finalizada de ejemplo', '2026-11-10T09:00:00', '2026-11-10T12:00:00', N'FINALIZADA'),
      (N'DEMO-CAL-007', @zona, @exploradores, 55, N'Campamento de diciembre', '2026-12-04T08:00:00', '2026-12-06T17:00:00', N'APROBADA'),
      (N'DEMO-CAL-008', @zona, @caminantes, 40, N'Jornada de integración', '2026-11-28T08:00:00', '2026-11-28T17:00:00', N'PENDIENTE')
    ) d(codigo, espacio, perfil, participantes, actividad, inicio, fin, estado);
  OPEN reservasDemo;
  FETCH NEXT FROM reservasDemo INTO @codigo, @espacio, @perfil, @participantes, @actividad, @inicio, @fin, @estado;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.reservas WHERE codigo=@codigo)
    BEGIN
      EXEC dbo.paReservaInsertar @pCodigo=@codigo, @pEspacioId=@espacio,
        @pSolicitantePerfilId=@perfil, @pGrupo=N'Grupo ficticio de demostración',
        @pResponsable=N'Responsable Demo', @pTelefono=N'00000000', @pEmail=N'reservas.demo@example.com',
        @pParticipantes=@participantes, @pTipoActividad=@actividad, @pFechaInicio=@inicio, @pFechaFin=@fin,
        @pEstado=@estado, @pObservaciones=N'Datos ficticios para explorar el sistema. No corresponde a una reserva real.',
        @pIdGenerado=@id OUTPUT, @pResultado=@ok OUTPUT, @pMensaje=@mensaje OUTPUT;
      IF @ok <> 1 THROW 51003, @mensaje, 1;
    END;
    FETCH NEXT FROM reservasDemo INTO @codigo, @espacio, @perfil, @participantes, @actividad, @inicio, @fin, @estado;
  END;
  CLOSE reservasDemo;
  DEALLOCATE reservasDemo;

  DECLARE @reserva INT, @monto DECIMAL(12,2), @metodo NVARCHAR(30), @estadoPago NVARCHAR(15), @comprobante NVARCHAR(255);
  DECLARE pagosDemo CURSOR LOCAL FAST_FORWARD FOR
    SELECT r.id, d.monto, d.metodo, d.estado, d.comprobante FROM (VALUES
      (N'DEMO-CAL-001', 12500, N'SINPE Móvil', N'PAGADO', N'DEMO-PAGO-001'),
      (N'DEMO-CAL-002', 25000, N'Transferencia bancaria', N'PENDIENTE', N'DEMO-PAGO-002'),
      (N'DEMO-CAL-004', 15000, N'Efectivo', N'PAGADO', N'DEMO-PAGO-003'),
      (N'DEMO-CAL-008', 35000, N'Tarjeta', N'RECHAZADO', N'DEMO-PAGO-004')
    ) d(codigo, monto, metodo, estado, comprobante) JOIN dbo.reservas r ON r.codigo=d.codigo;
  OPEN pagosDemo;
  FETCH NEXT FROM pagosDemo INTO @reserva, @monto, @metodo, @estadoPago, @comprobante;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.pagos WHERE comprobante=@comprobante)
    BEGIN
      EXEC dbo.paPagoInsertar @pReservaId=@reserva, @pMonto=@monto, @pMetodo=@metodo,
        @pFechaPago='2026-11-14', @pEstado=@estadoPago, @pComprobante=@comprobante,
        @pNotas=N'Pago ficticio de demostración. No se realizó ningún cobro.',
        @pIdGenerado=@id OUTPUT, @pResultado=@ok OUTPUT, @pMensaje=@mensaje OUTPUT;
      IF @ok <> 1 THROW 51004, @mensaje, 1;
    END;
    FETCH NEXT FROM pagosDemo INTO @reserva, @monto, @metodo, @estadoPago, @comprobante;
  END;
  CLOSE pagosDemo;
  DEALLOCATE pagosDemo;
  COMMIT;
  SELECT codigo, espacioId, fechaInicio, fechaFin, estado FROM dbo.reservas WHERE codigo LIKE N'DEMO-CAL-%' ORDER BY codigo;
  SELECT comprobante, monto, metodo, estado FROM dbo.pagos WHERE comprobante LIKE N'DEMO-PAGO-%' ORDER BY comprobante;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  THROW;
END CATCH;
GO
