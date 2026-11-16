-- Catalogo y bitacora externos a la base que se restaura.
USE master;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.reservasScoutsRespaldos') IS NULL
CREATE TABLE dbo.reservasScoutsRespaldos (
    nombre NVARCHAR(120) PRIMARY KEY, creadoEn DATETIME2(0) NOT NULL, bytes BIGINT NOT NULL
);
IF OBJECT_ID(N'dbo.reservasScoutsOperaciones') IS NULL
CREATE TABLE dbo.reservasScoutsOperaciones (
    id UNIQUEIDENTIFIER PRIMARY KEY, idAuditoria BIGINT IDENTITY NOT NULL, evento NVARCHAR(20) NOT NULL,
    archivo NVARCHAR(120) NOT NULL, usuarioId INT NULL, usuario NVARCHAR(160) NULL,
    direccionIp NVARCHAR(80) NULL, agente NVARCHAR(500) NULL,
    estado NVARCHAR(20) NOT NULL DEFAULT N'INICIADO', error NVARCHAR(1000) NULL,
    iniciadoEn DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(), finalizadoEn DATETIME2(3) NULL
);
GO
IF DB_ID(N'reservasScouts') IS NOT NULL AND OBJECT_ID(N'reservasScouts.dbo.respaldoHistorial') IS NOT NULL
INSERT dbo.reservasScoutsRespaldos(nombre,creadoEn,bytes)
SELECT nombreArchivo,creadoEn,bytes FROM reservasScouts.dbo.respaldoHistorial h
WHERE NOT EXISTS(SELECT 1 FROM dbo.reservasScoutsRespaldos c WHERE c.nombre=h.nombreArchivo);
GO
CREATE OR ALTER PROCEDURE dbo.paReservasRespaldoListar
AS
BEGIN
 SET NOCOUNT ON;
 SELECT nombre,creadoEn,bytes FROM dbo.reservasScoutsRespaldos ORDER BY creadoEn DESC,nombre;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasRespaldoRegistrar
 @nombre NVARCHAR(120),@creadoEn DATETIME2(0),@bytes BIGINT
AS
BEGIN
 SET NOCOUNT ON;
 IF @nombre NOT LIKE N'reservasScouts[_]%.bak' OR @bytes<=0 THROW 50031,N'Respaldo invalido.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.reservasScoutsRespaldos WHERE nombre=@nombre)
 INSERT dbo.reservasScoutsRespaldos VALUES(@nombre,@creadoEn,@bytes);
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionIniciar
 @id UNIQUEIDENTIFIER,@evento NVARCHAR(20),@archivo NVARCHAR(120),@usuarioId INT,
 @usuario NVARCHAR(160),@ip NVARCHAR(80),@agente NVARCHAR(500)
AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.reservasScoutsOperaciones(id,evento,archivo,usuarioId,usuario,direccionIp,agente)
 VALUES(@id,@evento,@archivo,@usuarioId,@usuario,@ip,LEFT(@agente,500));
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionFinalizar
 @id UNIQUEIDENTIFIER,@estado NVARCHAR(20),@error NVARCHAR(1000)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 UPDATE dbo.reservasScoutsOperaciones SET estado=@estado,error=@error,finalizadoEn=SYSUTCDATETIME() WHERE id=@id;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionesAuditoria
AS
BEGIN
 SET NOCOUNT ON;
 SELECT TOP(500) idAuditoria,N'respaldos' AS origen,evento,CAST(NULL AS INT) AS registroId,
    usuario,CAST(ORIGINAL_LOGIN() AS NVARCHAR(120)) AS usuarioBd,
    (SELECT archivo,estado,error,direccionIp,agente,iniciadoEn,finalizadoEn FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS detalle,
    CAST(NULL AS NVARCHAR(MAX)) AS valoresAnteriores,
    (SELECT archivo,estado,error,direccionIp,agente,iniciadoEn,finalizadoEn FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES) AS valoresNuevos,
    iniciadoEn AS creadoEn
 FROM dbo.reservasScoutsOperaciones ORDER BY iniciadoEn DESC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paRespaldoCompleto @pRuta NVARCHAR(4000)
AS
BEGIN
 SET NOCOUNT ON;
 IF NULLIF(LTRIM(RTRIM(@pRuta)),N'') IS NULL THROW 50040,N'La ruta es obligatoria.',1;
 BACKUP DATABASE reservasScouts TO DISK=@pRuta WITH COPY_ONLY,CHECKSUM,COMPRESSION,INIT;
 RESTORE VERIFYONLY FROM DISK=@pRuta WITH CHECKSUM;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paReservasOperacionesResumen
AS
BEGIN
 SET NOCOUNT ON;
 SELECT N'respaldos' AS origen,evento,COUNT_BIG(*) AS totalEventos,MAX(iniciadoEn) AS ultimoEvento
 FROM dbo.reservasScoutsOperaciones GROUP BY evento;
END;
GO
CREATE OR ALTER PROCEDURE dbo.paRestaurarReservasScouts @pRuta NVARCHAR(4000)
AS
BEGIN
 SET NOCOUNT ON;
 IF NULLIF(LTRIM(RTRIM(@pRuta)),N'') IS NULL THROW 50041,N'La ruta es obligatoria.',1;
 RESTORE VERIFYONLY FROM DISK=@pRuta WITH CHECKSUM;
 BEGIN TRY
  ALTER DATABASE reservasScouts SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  RESTORE DATABASE reservasScouts FROM DISK=@pRuta WITH REPLACE,RECOVERY,CHECKSUM;
  ALTER DATABASE reservasScouts SET MULTI_USER;
 END TRY
 BEGIN CATCH
  IF DB_ID(N'reservasScouts') IS NOT NULL ALTER DATABASE reservasScouts SET MULTI_USER;
  THROW;
 END CATCH;
END;
GO
IF DATABASE_PRINCIPAL_ID(N'reservas_maintenance') IS NULL
 CREATE USER reservas_maintenance FOR LOGIN reservas_maintenance;
IF DATABASE_PRINCIPAL_ID(N'reservas_app') IS NULL
 CREATE USER reservas_app FOR LOGIN reservas_app;
GRANT EXECUTE ON dbo.paReservasRespaldoListar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasRespaldoRegistrar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasOperacionIniciar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasOperacionFinalizar TO reservas_maintenance;
GRANT EXECUTE ON dbo.paReservasOperacionesAuditoria TO reservas_app;
GRANT EXECUTE ON dbo.paReservasOperacionesResumen TO reservas_app;
GRANT EXECUTE ON dbo.paRespaldoCompleto TO reservas_maintenance;
GRANT EXECUTE ON dbo.paRestaurarReservasScouts TO reservas_maintenance;
GO
