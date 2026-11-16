USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF COL_LENGTH(N'dbo.reservas',N'pagoVenceEn') IS NULL
 ALTER TABLE dbo.reservas ADD pagoVenceEn DATETIME2(0) NULL;
IF OBJECT_ID(N'dbo.reservaPoliticaPago') IS NULL
BEGIN
 CREATE TABLE dbo.reservaPoliticaPago(id INT PRIMARY KEY CHECK(id=1),efectivoGraciaMinutos INT NOT NULL CHECK(efectivoGraciaMinutos BETWEEN 0 AND 1440),transferenciaPlazoHoras INT NOT NULL CHECK(transferenciaPlazoHoras BETWEEN 1 AND 168));
 INSERT dbo.reservaPoliticaPago VALUES(1,120,24);
END;
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=N'ckReservasEstado') ALTER TABLE dbo.reservas DROP CONSTRAINT ckReservasEstado;
ALTER TABLE dbo.reservas ADD CONSTRAINT ckReservasEstado CHECK(estado IN(N'PENDIENTE',N'APROBADA',N'CANCELADA',N'FINALIZADA',N'VENCIDA'));
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE name=N'ckPagosEstado') ALTER TABLE dbo.pagos DROP CONSTRAINT ckPagosEstado;
ALTER TABLE dbo.pagos ADD CONSTRAINT ckPagosEstado CHECK(estado IN(N'PENDIENTE',N'PAGADO',N'RECHAZADO',N'ANULADO',N'VENCIDO'));
GO
CREATE OR ALTER PROCEDURE dbo.paReservaPlazoActualizar @reservaId INT
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @vence DATETIME2(0),@costo DECIMAL(12,2),@pagado DECIMAL(12,2);
 SELECT @costo=e.costo FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reservaId;
 SELECT @pagado=ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reservaId AND estado=N'PAGADO';
 SELECT @vence=MIN(CASE WHEN limite>r.fechaFin THEN r.fechaFin ELSE limite END)
 FROM dbo.reservas r CROSS JOIN dbo.reservaPoliticaPago cfg
 JOIN dbo.pagos p ON p.reservaId=r.id
 CROSS APPLY(SELECT CASE WHEN p.metodo=N'Efectivo' THEN DATEADD(MINUTE,cfg.efectivoGraciaMinutos,r.fechaInicio)
   ELSE CASE WHEN DATEADD(HOUR,cfg.transferenciaPlazoHoras,p.createdAt)>r.fechaInicio THEN r.fechaInicio ELSE DATEADD(HOUR,cfg.transferenciaPlazoHoras,p.createdAt) END END AS limite) l
 WHERE r.id=@reservaId AND p.estado=N'PENDIENTE'
 AND (p.metodo=N'Efectivo' OR (p.metodo IN(N'SINPE Móvil',N'Transferencia bancaria') AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes c WHERE c.pagoId=p.id)));
 UPDATE dbo.reservas SET pagoVenceEn=CASE WHEN @pagado>=@costo THEN NULL ELSE @vence END,
  estado=CASE WHEN @pagado>=@costo THEN N'APROBADA' ELSE N'PENDIENTE' END,updatedAt=SYSDATETIME()
 WHERE id=@reservaId AND estado IN(N'PENDIENTE',N'APROBADA')
 AND (estado<>CASE WHEN @pagado>=@costo THEN N'APROBADA' ELSE N'PENDIENTE' END
      OR ISNULL(pagoVenceEn,'19000101')<>ISNULL(CASE WHEN @pagado>=@costo THEN NULL ELSE @vence END,'19000101'));
END;
GO
CREATE OR ALTER TRIGGER dbo.trgPagosPlazoReserva ON dbo.pagos AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @id INT;
 DECLARE filas CURSOR LOCAL FAST_FORWARD FOR SELECT reservaId FROM inserted UNION SELECT reservaId FROM deleted;
 OPEN filas; FETCH NEXT FROM filas INTO @id;
 WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM filas INTO @id; END;
 CLOSE filas; DEALLOCATE filas;
END;
GO
CREATE OR ALTER TRIGGER dbo.trgComprobantesPlazoReserva ON dbo.pagoComprobantes AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @id INT;
 DECLARE filas CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT p.reservaId FROM inserted i JOIN dbo.pagos p ON p.id=i.pagoId;
 OPEN filas; FETCH NEXT FROM filas INTO @id;
 WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM filas INTO @id; END;
 CLOSE filas; DEALLOCATE filas;
END;
GO
CREATE OR ALTER TRIGGER dbo.trgReservasPagoIntegro ON dbo.reservas AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.espacios e ON e.id=i.espacioId WHERE i.estado=N'APROBADA'
  AND e.costo>ISNULL((SELECT SUM(monto) FROM dbo.pagos WHERE reservaId=i.id AND estado=N'PAGADO'),0))
  THROW 51019,N'La reserva solo se aprueba al recibir y confirmar el pago completo.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasVencerPendientes
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @ahora DATETIME2(0)=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATETIME2(0));
 DECLARE @usuario SQL_VARIANT=SESSION_CONTEXT(N'app_usuario_id'),@nombre SQL_VARIANT=SESSION_CONTEXT(N'app_usuario_nombre');
 EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=N'Sistema: vencimiento de reservas';
 BEGIN TRY
  DECLARE @id INT;
  DECLARE filas CURSOR LOCAL FAST_FORWARD FOR SELECT id FROM dbo.reservas WHERE estado=N'PENDIENTE' AND pagoVenceEn<=@ahora ORDER BY id;
  OPEN filas; FETCH NEXT FROM filas INTO @id;
  WHILE @@FETCH_STATUS=0
  BEGIN
   BEGIN TRANSACTION;
   IF EXISTS(SELECT 1 FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@id AND estado=N'PENDIENTE' AND pagoVenceEn<=@ahora)
     AND NOT EXISTS(SELECT 1 FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE reservaId=@id AND estado=N'PAGADO')
     AND NOT EXISTS(SELECT 1 FROM dbo.pagos p JOIN dbo.pagoComprobantes c ON c.pagoId=p.id WHERE p.reservaId=@id AND p.estado=N'PENDIENTE')
   BEGIN
    UPDATE dbo.reservas SET estado=N'VENCIDA',updatedAt=SYSDATETIME() WHERE id=@id;
    UPDATE dbo.pagos SET estado=N'VENCIDO',notas=CONCAT(ISNULL(notas,N''),N' Plazo de pago vencido; cupo liberado.'),updatedAt=SYSDATETIME() WHERE reservaId=@id AND estado=N'PENDIENTE';
   END;
   COMMIT;
   FETCH NEXT FROM filas INTO @id;
  END;
  CLOSE filas; DEALLOCATE filas;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK;
  EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=@usuario;
  EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=@nombre;
  THROW;
 END CATCH;
 EXEC sys.sp_set_session_context @key=N'app_usuario_id',@value=@usuario;
 EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=@nombre;
END;
GO
CREATE OR ALTER TRIGGER dbo.trgReservasFechaPlazo ON dbo.reservas AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF NOT (UPDATE(fechaInicio) OR UPDATE(fechaFin)) RETURN;
 DECLARE @id INT;
 DECLARE filas CURSOR LOCAL FAST_FORWARD FOR
 SELECT i.id FROM inserted i JOIN deleted d ON d.id=i.id
 WHERE i.estado IN(N'PENDIENTE',N'APROBADA') AND (i.fechaInicio<>d.fechaInicio OR i.fechaFin<>d.fechaFin)
 AND EXISTS(SELECT 1 FROM dbo.pagos WHERE reservaId=i.id);
 OPEN filas; FETCH NEXT FROM filas INTO @id;
 WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM filas INTO @id; END;
 CLOSE filas; DEALLOCATE filas;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paCobroEstadoReserva @reservaId INT,@aprobada BIT
AS
BEGIN
 SET NOCOUNT ON;
 -- El estado se deriva del saldo recibido, nunca del metodo elegido por el cliente.
 EXEC dbo.paReservaPlazoActualizar @reservaId;
END;
GO
GRANT EXECUTE ON dbo.paReservaPlazoActualizar TO reservas_app;
GRANT EXECUTE ON dbo.paReservasVencerPendientes TO reservas_app;
GRANT EXECUTE ON dbo.paCobroEstadoReserva TO reservas_app;
GO

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
        DECLARE @reserva INT,@estadoReserva NVARCHAR(20),@inicio DATETIME2(0),@costo DECIMAL(12,2),@vence DATETIME2(0);
        SELECT @reserva=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=r.estado,@inicio=r.fechaInicio,@costo=e.costo,@vence=r.pagoVenceEn
            FROM dbo.reservas r WITH(UPDLOCK,HOLDLOCK) JOIN dbo.espacios e ON e.id=r.espacioId WHERE r.id=@reserva;
        DECLARE @metodo NVARCHAR(30),@monto DECIMAL(12,2);
        SELECT @metodo=metodo,@monto=monto FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK)
            WHERE id=@pagoId AND estado=N'PENDIENTE';
        IF @metodo IS NULL OR @metodo NOT IN(N'SINPE Móvil',N'Transferencia bancaria',N'Efectivo')
            THROW 51017,N'Este pago ya fue revisado por otra persona o no admite revisión. La bandeja se actualizará.',1;
        IF @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'La reserva está cerrada o cancelada y no admite revisión.',1;
        IF @vence IS NOT NULL AND @vence<=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATETIME2(0))
            THROW 51018,N'El plazo de pago vencio. El cupo debe consultarse nuevamente.',1;
        IF @aprobar=1 AND @metodo<>N'Efectivo' AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId)
            THROW 51018,N'Falta el comprobante para verificar este pago.',1;
        SET @motivo=NULLIF(LTRIM(RTRIM(@motivo)),N'');
        IF @aprobar=0 AND @motivo IS NULL THROW 51018,N'Indica el motivo del rechazo.',1;
        IF @aprobar=1 AND (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PAGADO')+@monto>@costo
            THROW 51019,N'El pago supera el costo de la reserva.',1;
        UPDATE dbo.pagos SET estado=CASE WHEN @aprobar=1 THEN N'PAGADO' ELSE N'RECHAZADO' END,
            fechaPago=CASE WHEN @aprobar=1 AND @metodo=N'Efectivo' THEN CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE) ELSE fechaPago END,
            updatedAt=SYSDATETIME() WHERE id=@pagoId;
        UPDATE dbo.reservas SET estado=CASE WHEN @aprobar=0 THEN N'CANCELADA' WHEN (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos WHERE reservaId=@reserva AND estado=N'PAGADO')>=@costo THEN N'APROBADA' ELSE N'PENDIENTE' END,
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
       AND @pEstado NOT IN (N'PENDIENTE', N'APROBADA', N'CANCELADA', N'FINALIZADA', N'VENCIDA')
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

    EXEC dbo.paReservasVencerPendientes;
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
        r.estado, r.espacioId, r.pagoVenceEn,
        (SELECT TOP(1) metodo FROM dbo.pagos WHERE reservaId=r.id AND estado=N'PENDIENTE' ORDER BY id DESC) AS metodoPagoPendiente
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

CREATE OR ALTER PROCEDURE [dbo].[paReservaFechasOcupadas]
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;
    SELECT espacioId, fechaInicio, fechaFin
    FROM dbo.reservas
    WHERE estado IN (N'PENDIENTE', N'APROBADA')
    ORDER BY espacioId, fechaInicio;
END;
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
               N'RECHAZADO', N'ANULADO', N'VENCIDO'
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

CREATE OR ALTER PROCEDURE dbo.paBloqueoComprobar
    @espacioId INT, @inicio DATETIME2(0), @fin DATETIME2(0), @usuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;
    DECLARE @resultado INT, @recurso NVARCHAR(255) = CONCAT(N'reserva-espacio-', @espacioId);
    EXEC @resultado=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=5000;
    IF @resultado < 0 THROW 51010, N'El espacio está siendo consultado. Intenta nuevamente.', 1;
    IF EXISTS (SELECT 1 FROM dbo.reservaBloqueos WHERE espacioId=@espacioId AND vence>SYSUTCDATETIME()
        AND usuarioId<>ISNULL(@usuarioId,-1) AND @inicio<fechaFin AND @fin>fechaInicio)
        THROW 51011, N'Espacio no disponible: otro usuario está completando su reserva.', 1;
END;
GO

-- Instala la consulta de horarios usada antes de guardar reservas.
USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [dbo].[paReservaDisponibilidad]
    @pEspacioId INT,
    @pFechaInicio DATETIME2(0),
    @pFechaFin DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;

    IF @pEspacioId IS NULL
       OR @pEspacioId <= 0
    BEGIN
        THROW 50001, N'El espacio indicado no es válido.', 1;
    END;

    IF @pFechaInicio IS NULL
       OR @pFechaFin IS NULL
       OR @pFechaFin <= @pFechaInicio
    BEGIN
        THROW 50002, N'El rango de fechas no es válido.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.espacios
        WHERE id = @pEspacioId
    )
    BEGIN
        THROW 50003, N'El espacio indicado no existe.', 1;
    END;

    DECLARE @estadoEspacio NVARCHAR(20);

    SELECT
        @estadoEspacio = estado
    FROM dbo.espacios
    WHERE id = @pEspacioId;

    SELECT
        CAST(
            CASE
                WHEN @estadoEspacio <> N'DISPONIBLE'
                    THEN 0

                WHEN EXISTS (
                    SELECT 1
                    FROM dbo.reservas
                    WHERE espacioId = @pEspacioId
                      AND estado IN (
                          N'PENDIENTE',
                          N'APROBADA'
                      )
                      AND @pFechaInicio < fechaFin
                      AND @pFechaFin > fechaInicio
                )
                    THEN 0

                ELSE 1
            END
            AS BIT
        ) AS disponible;
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paReservaDisponibilidad TO reservas_app;
GO

CREATE OR ALTER PROCEDURE dbo.paPagoDetalle @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.estado AS reservaEstado,r.fechaInicio,r.fechaFin,r.pagoVenceEn,e.costo,
        e.costo-ISNULL((SELECT SUM(monto) FROM dbo.pagos WHERE reservaId=r.id AND estado=N'PAGADO'),0) AS saldo,
        CAST(CASE WHEN c.pagoId IS NULL THEN 0 ELSE 1 END AS BIT) AS tieneComprobante,
        rev.aprobada AS comprobanteCorrecto,rv.email AS revisadoPor,rev.revisadaEn,rev.motivo AS motivoRevision,
        au.email AS anuladoPor,a.anuladaEn,a.motivo AS motivoAnulacion
    FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId JOIN dbo.espacios e ON e.id=r.espacioId
    LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
    LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id LEFT JOIN dbo.usuarios rv ON rv.id=rev.usuarioId
    LEFT JOIN dbo.pagoAnulaciones a ON a.pagoId=p.id LEFT JOIN dbo.usuarios au ON au.id=a.usuarioId
    WHERE p.id=@pagoId;
END;
GO


CREATE OR ALTER TRIGGER dbo.trgReservasAuditoria ON dbo.reservas AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.auditoriaReservas(tabla,idRegistro,accion,detalle,usuarioAppId,usuarioAppNombre,usuarioBd,creadoEn)
 SELECT N'reservas',COALESCE(i.id,d.id),CASE WHEN d.id IS NULL THEN N'INSERT' WHEN i.id IS NULL THEN N'DELETE' ELSE N'UPDATE' END,
  (SELECT JSON_QUERY(CASE WHEN d.id IS NOT NULL THEN (SELECT d.* FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) END) AS antes,
          JSON_QUERY(CASE WHEN i.id IS NOT NULL THEN (SELECT i.* FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) END) AS despues
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  TRY_CONVERT(INT,SESSION_CONTEXT(N'app_usuario_id')),TRY_CONVERT(NVARCHAR(160),SESSION_CONTEXT(N'app_usuario_nombre')),LEFT(ORIGINAL_LOGIN(),120),SYSDATETIME()
 FROM inserted i FULL JOIN deleted d ON d.id=i.id;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservaPoliticaPago AS
BEGIN SET NOCOUNT ON; SELECT efectivoGraciaMinutos,transferenciaPlazoHoras FROM dbo.reservaPoliticaPago WHERE id=1; END;
GO
GRANT EXECUTE ON dbo.paReservaPoliticaPago TO reservas_app;
GO
CREATE OR ALTER TRIGGER [dbo].[trgPagosAuditoria]
ON [dbo].[pagos]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.auditoriaPagos
    (
        pagoId,
        reservaId,
        accion,
        valoresAnteriores,
        valoresNuevos,
        usuarioAppId,
        usuarioAppNombre,
        usuarioBd,
        creadoEn
    )
    SELECT
        COALESCE(i.id, d.id),

        COALESCE(i.reservaId, d.reservaId),

        CASE
            WHEN d.id IS NULL THEN N'INSERT'
            WHEN i.id IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,

        CASE
            WHEN d.id IS NOT NULL THEN
            (
                SELECT
                    d.reservaId,
                    d.monto,
                    d.metodo,
                    d.fechaPago,
                    d.estado,
                    d.comprobante
                FOR JSON PATH,
                    WITHOUT_ARRAY_WRAPPER,
                    INCLUDE_NULL_VALUES
            )
            ELSE NULL
        END,

        CASE
            WHEN i.id IS NOT NULL THEN
            (
                SELECT
                    i.reservaId,
                    i.monto,
                    i.metodo,
                    i.fechaPago,
                    i.estado,
                    i.comprobante
                FOR JSON PATH,
                    WITHOUT_ARRAY_WRAPPER,
                    INCLUDE_NULL_VALUES
            )
            ELSE NULL
        END,

        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),

        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),

        LEFT(ORIGINAL_LOGIN(), 120),

        SYSDATETIME()

    FROM inserted AS i

    FULL OUTER JOIN deleted AS d
        ON d.id = i.id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.paNotificacionesListar
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.paReservasVencerPendientes;
    SELECT r.id AS reservaId,r.espacioId,r.codigo,pr.nombre AS solicitante,e.nombre AS espacio,
        r.responsable,r.participantes,r.fechaInicio,r.fechaFin,r.pagoVenceEn,r.estado AS reservaEstado,
        r.createdAt AS reservaCreadaEn,p.id AS pagoId,p.monto,p.metodo,p.estado AS pagoEstado,
        p.fechaPago,CAST(CASE WHEN c.pagoId IS NULL THEN 0 ELSE 1 END AS BIT) AS tieneComprobante,
        rev.revisadaEn,rev.motivo,revisor.email AS revisadoPor
    FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
    JOIN dbo.perfilesUsuario pr ON pr.idPerfil=r.solicitantePerfilId
    LEFT JOIN dbo.pagos p ON p.reservaId=r.id
    LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
    LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id
    LEFT JOIN dbo.usuarios revisor ON revisor.id=rev.usuarioId
    ORDER BY r.createdAt DESC,r.id DESC,p.id DESC;
END;
GO

DECLARE @id INT;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=N'Sistema: politica de pago pendiente';
DECLARE actuales CURSOR LOCAL FAST_FORWARD FOR
 SELECT DISTINCT r.id FROM dbo.reservas r JOIN dbo.pagos p ON p.reservaId=r.id
 WHERE r.estado IN(N'PENDIENTE',N'APROBADA');
OPEN actuales; FETCH NEXT FROM actuales INTO @id;
WHILE @@FETCH_STATUS=0 BEGIN EXEC dbo.paReservaPlazoActualizar @id; FETCH NEXT FROM actuales INTO @id; END;
CLOSE actuales; DEALLOCATE actuales;
EXEC sys.sp_set_session_context @key=N'app_usuario_nombre',@value=NULL;
EXEC dbo.paReservasVencerPendientes;
GO

CREATE OR ALTER PROCEDURE dbo.paComprobanteAdjuntar
    @pagoId INT,@nombre NVARCHAR(200),@tipo NVARCHAR(60),@contenido VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @reservaId INT,@estadoReserva NVARCHAR(20),@estado NVARCHAR(15),@metodo NVARCHAR(30),@vence DATETIME2(0);
        SELECT @reservaId=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=estado,@vence=pagoVenceEn FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@reservaId;
        SELECT @estado=estado,@metodo=metodo FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE id=@pagoId;
        IF @estado IS NULL OR @estado<>N'PENDIENTE' OR @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'Solo se adjuntan comprobantes a pagos pendientes de reservas activas.',1;
        IF @vence IS NOT NULL AND @vence<=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATETIME2(0))
            THROW 51018,N'El plazo para adjuntar el comprobante vencio. Consulta nuevamente la disponibilidad.',1;
        IF @metodo NOT IN(N'SINPE Móvil',N'Transferencia bancaria')
            THROW 51018,N'El comprobante corresponde a SINPE Móvil o transferencia bancaria.',1;
        IF EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId)
            THROW 51018,N'Este pago ya tiene un comprobante. Se conserva el archivo original.',1;
        EXEC dbo.paComprobanteGuardar @pagoId,@nombre,@tipo,@contenido;
        UPDATE dbo.pagos SET comprobante=N'Comprobante adjunto',updatedAt=SYSDATETIME() WHERE id=@pagoId;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
