USE reservasScouts;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Archivo independiente: ninguna FK a las filas que se eliminan.
IF OBJECT_ID(N'dbo.reservasEliminadas') IS NULL
CREATE TABLE dbo.reservasEliminadas (
    reservaId INT PRIMARY KEY,
    reservaJson NVARCHAR(MAX) NOT NULL CHECK (ISJSON(reservaJson)=1),
    pagosJson NVARCHAR(MAX) NOT NULL CHECK (ISJSON(pagosJson)=1),
    eliminadaPor NVARCHAR(160) NULL,
    eliminadaEn DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
IF OBJECT_ID(N'dbo.comprobantesArchivados') IS NULL
CREATE TABLE dbo.comprobantesArchivados (
    pagoId INT PRIMARY KEY,
    reservaId INT NOT NULL REFERENCES dbo.reservasEliminadas(reservaId),
    nombre NVARCHAR(200) NOT NULL,
    tipo NVARCHAR(60) NOT NULL,
    contenido VARBINARY(MAX) NOT NULL
);
GO
CREATE OR ALTER PROCEDURE dbo.paReservaEliminar
    @pId INT, @pResultado TINYINT OUTPUT, @pMensaje NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @pResultado=0;
    SET @pMensaje=N'';
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS(SELECT 1 FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@pId)
            THROW 51018,N'La reserva indicada no existe.',1;
        DECLARE @reserva NVARCHAR(MAX),@pagos NVARCHAR(MAX);
        SELECT @reserva=(SELECT r.*,e.nombre AS espacio,pr.nombre AS solicitante
            FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
            JOIN dbo.perfilesUsuario pr ON pr.idPerfil=r.solicitantePerfilId
            WHERE r.id=@pId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
        SELECT @pagos=(SELECT p.*,c.nombre AS archivoNombre,c.tipo AS archivoTipo,
            rev.aprobada AS comprobanteCorrecto,rev.revisadaEn,rev.motivo AS motivoRevision,
            u.email AS revisadoPor,a.motivo AS motivoAnulacion,a.anuladaEn,au.email AS anuladoPor
            FROM dbo.pagos p WITH(UPDLOCK,HOLDLOCK)
            LEFT JOIN dbo.pagoComprobantes c ON c.pagoId=p.id
            LEFT JOIN dbo.pagoRevisiones rev ON rev.pagoId=p.id
            LEFT JOIN dbo.usuarios u ON u.id=rev.usuarioId
            LEFT JOIN dbo.pagoAnulaciones a ON a.pagoId=p.id
            LEFT JOIN dbo.usuarios au ON au.id=a.usuarioId
            WHERE p.reservaId=@pId FOR JSON PATH,INCLUDE_NULL_VALUES);
        INSERT dbo.reservasEliminadas(reservaId,reservaJson,pagosJson,eliminadaPor)
            VALUES(@pId,@reserva,COALESCE(@pagos,N'[]'),CONVERT(NVARCHAR(160),SESSION_CONTEXT(N'app_usuario_nombre')));
        INSERT dbo.comprobantesArchivados(pagoId,reservaId,nombre,tipo,contenido)
            SELECT c.pagoId,@pId,c.nombre,c.tipo,c.contenido
            FROM dbo.pagoComprobantes c JOIN dbo.pagos p ON p.id=c.pagoId WHERE p.reservaId=@pId;
        DELETE a FROM dbo.pagoAnulaciones a JOIN dbo.pagos p ON p.id=a.pagoId WHERE p.reservaId=@pId;
        -- Los triggers de pagos y reservas registran DELETE con el contexto de la cuenta.
        DELETE FROM dbo.pagos WHERE reservaId=@pId;
        DELETE FROM dbo.reservas WHERE id=@pId;
        COMMIT;
        SET @pResultado=1;
        SET @pMensaje=N'Reserva eliminada. Auditoría, pagos y comprobantes conservados.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        SET @pMensaje=LEFT(ERROR_MESSAGE(),250);
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservaArchivo @reservaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT reservaJson,pagosJson,eliminadaPor,eliminadaEn FROM dbo.reservasEliminadas WHERE reservaId=@reservaId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paComprobanteLeer @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT nombre,tipo,contenido FROM dbo.pagoComprobantes WHERE pagoId=@pagoId
    UNION ALL
    SELECT nombre,tipo,contenido FROM dbo.comprobantesArchivados WHERE pagoId=@pagoId
        AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes WHERE pagoId=@pagoId);
END;
GO
CREATE OR ALTER PROCEDURE dbo.paComprobanteAdjuntar
    @pagoId INT,@nombre NVARCHAR(200),@tipo NVARCHAR(60),@contenido VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @reservaId INT,@estadoReserva NVARCHAR(20),@estado NVARCHAR(15),@metodo NVARCHAR(30);
        SELECT @reservaId=reservaId FROM dbo.pagos WHERE id=@pagoId;
        SELECT @estadoReserva=estado FROM dbo.reservas WITH(UPDLOCK,HOLDLOCK) WHERE id=@reservaId;
        SELECT @estado=estado,@metodo=metodo FROM dbo.pagos WITH(UPDLOCK,HOLDLOCK) WHERE id=@pagoId;
        IF @estado IS NULL OR @estado<>N'PENDIENTE' OR @estadoReserva NOT IN(N'PENDIENTE',N'APROBADA')
            THROW 51018,N'Solo se adjuntan comprobantes a pagos pendientes de reservas activas.',1;
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
GRANT EXECUTE ON dbo.paReservaEliminar TO reservas_app;
GRANT EXECUTE ON dbo.paReservaArchivo TO reservas_app;
GRANT EXECUTE ON dbo.paComprobanteLeer TO reservas_app;
GRANT EXECUTE ON dbo.paComprobanteAdjuntar TO reservas_app;
GO
CREATE OR ALTER PROCEDURE dbo.paPagoDetalle @pagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.estado AS reservaEstado,r.fechaInicio,r.fechaFin,e.costo,
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
GRANT EXECUTE ON dbo.paPagoDetalle TO reservas_app;
GO

-- Restaura el detalle de auditoria en instalaciones anteriores.
CREATE OR ALTER PROCEDURE [dbo].[paAuditoriaDetalle]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (500)
        eventos.idAuditoria,
        eventos.origen,
        eventos.evento,
        eventos.registroId,
        eventos.usuario,
        eventos.usuarioBd,
        eventos.detalle,
        eventos.valoresAnteriores,
        eventos.valoresNuevos,
        eventos.creadoEn

    FROM
    (
        /* Cambios generales */
        SELECT
            ar.idAuditoria,
            ar.tabla COLLATE DATABASE_DEFAULT AS origen,
            ar.accion COLLATE DATABASE_DEFAULT AS evento,
            ar.idRegistro AS registroId,

            COALESCE(
                NULLIF(ar.usuarioAppNombre, N''),
                NULLIF(ar.usuarioBd, N''),
                N'No identificado'
            ) AS usuario,

            ar.usuarioBd,
            ar.detalle,

            CASE
                WHEN ISJSON(ar.detalle) = 1
                THEN JSON_QUERY(ar.detalle, '$.antes')
                ELSE NULL
            END AS valoresAnteriores,

            CASE
                WHEN ISJSON(ar.detalle) = 1
                THEN JSON_QUERY(ar.detalle, '$.despues')
                ELSE NULL
            END AS valoresNuevos,

            ar.creadoEn

        FROM dbo.auditoriaReservas AS ar


        UNION ALL


        /* Cambios de pagos */
        SELECT
            ap.idAuditoriaPago,
            N'pagos',
            ap.accion COLLATE DATABASE_DEFAULT,
            ap.pagoId,

            COALESCE(
                NULLIF(ap.usuarioAppNombre, N''),
                NULLIF(ap.usuarioBd, N''),
                N'No identificado'
            ),

            ap.usuarioBd,

            CONCAT(
                N'Reserva asociada: ',
                COALESCE(
                    CONVERT(NVARCHAR(20), ap.reservaId),
                    N'No indicada'
                )
            ),

            ap.valoresAnteriores,
            ap.valoresNuevos,
            ap.creadoEn

        FROM dbo.auditoriaPagos AS ap


        UNION ALL


        /* Accesos, respaldo y restauración */
        SELECT
            aa.idAuditoriaAcceso,
            N'accesos',
            aa.evento COLLATE DATABASE_DEFAULT,
            aa.usuarioId,

            COALESCE(
                u.email,
                N'No identificado'
            ),

            CAST(NULL AS NVARCHAR(120)),

            CONCAT(
                N'IP: ',
                COALESCE(
                    CONVERT(NVARCHAR(45), aa.direccionIp),
                    N'No disponible'
                ),
                N' | Navegador: ',
                COALESCE(
                    aa.agenteUsuario,
                    N'No disponible'
                )
            ),

            CAST(NULL AS NVARCHAR(MAX)),
            CAST(NULL AS NVARCHAR(MAX)),
            aa.creadoEn

        FROM dbo.auditoriaAccesos AS aa

        LEFT JOIN dbo.usuarios AS u
            ON u.id = aa.usuarioId

    ) AS eventos

    ORDER BY
        eventos.creadoEn DESC,
        eventos.idAuditoria DESC;
END;
GO

GRANT EXECUTE ON dbo.paAuditoriaDetalle TO reservas_app;
GO
