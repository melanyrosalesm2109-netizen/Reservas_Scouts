-- Revision integral de coherencia del flujo vigente.
-- Conserva importes cobrados y archivos; corrige datos historicos de demostracion.
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
DECLARE @hoy DATE=CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATE);
DECLARE @cambios TABLE(tipo NVARCHAR(60),codigo NVARCHAR(20));
BEGIN TRY
BEGIN TRANSACTION;

-- En ejemplos personales de usuarios regulares, el solicitante debe pertenecer al creador.
UPDATE r SET solicitantePerfilId=propio.idPerfil,responsable=propio.nombre,
    telefono=ISNULL(NULLIF(propio.telefono,N''),N'00000000'),email=propio.correoContacto,
    grupo=NULL,updatedAt=SYSDATETIME()
OUTPUT N'Perfil propio corregido',inserted.codigo INTO @cambios
FROM dbo.reservas r
JOIN dbo.usuarios u ON u.id=r.creadoPorUsuarioId
JOIN dbo.roles rol ON rol.id=u.rolId
JOIN dbo.perfilesUsuario actual ON actual.idPerfil=r.solicitantePerfilId
CROSS APPLY(SELECT TOP(1) * FROM dbo.perfilesUsuario p WHERE p.usuarioId=u.id AND p.tipoPerfil=N'Persona' ORDER BY p.idPerfil) propio
WHERE r.codigo LIKE N'DEMO-%' AND rol.nombre IN(N'Usuario',N'Miembro')
    AND (actual.usuarioId IS NULL OR actual.usuarioId<>u.id);

-- Los ejemplos de efectivo futuro no necesitan referencias ficticias de comprobante.
UPDATE p SET comprobante=NULL,updatedAt=SYSDATETIME()
OUTPUT N'Referencia de efectivo retirada',r.codigo INTO @cambios
FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId
WHERE r.codigo LIKE N'DEMO-%' AND p.metodo=N'Efectivo' AND p.estado=N'PENDIENTE'
    AND p.comprobante IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes c WHERE c.pagoId=p.id);

-- El efectivo se cobra al llegar; en los registros historicos DEMO se normaliza la fecha.
UPDATE p SET fechaPago=CAST(r.fechaInicio AS DATE),updatedAt=SYSDATETIME()
OUTPUT N'Fecha de efectivo ajustada',r.codigo INTO @cambios
FROM dbo.pagos p JOIN dbo.reservas r ON r.id=p.reservaId
WHERE r.codigo LIKE N'DEMO-%' AND p.metodo=N'Efectivo'
    AND p.fechaPago<>CAST(r.fechaInicio AS DATE);

DELETE FROM dbo.reservaBloqueos WHERE vence<=SYSUTCDATETIME();
COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK;
    THROW;
END CATCH;

SELECT tipo,codigo FROM @cambios ORDER BY codigo,tipo;
-- Todos los indicadores deben ser cero. Los perfiles de grupos sin cuenta son validos.
SELECT N'Reservas activas sin pago' AS revision,COUNT(*) AS pendientes
FROM dbo.reservas r WHERE r.estado IN(N'PENDIENTE',N'APROBADA') AND NOT EXISTS(SELECT 1 FROM dbo.pagos p WHERE p.reservaId=r.id)
UNION ALL
SELECT N'Transferencias o SINPE sin archivo',COUNT(*)
FROM dbo.pagos p WHERE p.metodo IN(N'SINPE Móvil',N'Transferencia bancaria')
    AND p.estado IN(N'PENDIENTE',N'PAGADO') AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes c WHERE c.pagoId=p.id)
UNION ALL
SELECT N'Totales pagados superiores al costo',COUNT(*)
FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
WHERE (SELECT ISNULL(SUM(monto),0) FROM dbo.pagos p WHERE p.reservaId=r.id AND p.estado=N'PAGADO')>e.costo
UNION ALL
SELECT N'Reservas activas con solo pagos rechazados',COUNT(*)
FROM dbo.reservas r WHERE r.estado IN(N'PENDIENTE',N'APROBADA')
AND EXISTS(SELECT 1 FROM dbo.pagos p WHERE p.reservaId=r.id AND p.estado=N'RECHAZADO')
AND NOT EXISTS(SELECT 1 FROM dbo.pagos p WHERE p.reservaId=r.id AND p.estado IN(N'PENDIENTE',N'PAGADO'))
UNION ALL
SELECT N'Creador regular usando un perfil ajeno',COUNT(*)
FROM dbo.reservas r JOIN dbo.usuarios u ON u.id=r.creadoPorUsuarioId JOIN dbo.roles rol ON rol.id=u.rolId
JOIN dbo.perfilesUsuario p ON p.idPerfil=r.solicitantePerfilId
WHERE rol.nombre IN(N'Usuario',N'Miembro') AND (p.usuarioId IS NULL OR p.usuarioId<>u.id)
UNION ALL
SELECT N'Cruces de horarios activos',COUNT(*) FROM dbo.reservas a JOIN dbo.reservas b ON a.id<b.id AND a.espacioId=b.espacioId
AND a.fechaInicio<b.fechaFin AND a.fechaFin>b.fechaInicio WHERE a.estado IN(N'PENDIENTE',N'APROBADA') AND b.estado IN(N'PENDIENTE',N'APROBADA')
UNION ALL
SELECT N'Cuentas sin perfil',COUNT(*) FROM dbo.usuarios u WHERE NOT EXISTS(SELECT 1 FROM dbo.perfilesUsuario p WHERE p.usuarioId=u.id)
UNION ALL
SELECT N'Referencias a archivos inexistentes',COUNT(*) FROM dbo.pagos p WHERE p.comprobante=N'Comprobante adjunto'
AND NOT EXISTS(SELECT 1 FROM dbo.pagoComprobantes c WHERE c.pagoId=p.id)
UNION ALL
SELECT N'Reservas activas en espacios no disponibles',COUNT(*) FROM dbo.reservas r JOIN dbo.espacios e ON e.id=r.espacioId
WHERE r.estado IN(N'PENDIENTE',N'APROBADA') AND e.estado<>N'DISPONIBLE'
UNION ALL
SELECT N'Reservas pendientes con tarjeta pagada',COUNT(*) FROM dbo.reservas r JOIN dbo.pagos p ON p.reservaId=r.id
WHERE r.estado=N'PENDIENTE' AND p.metodo=N'Tarjeta' AND p.estado=N'PAGADO';
GO
