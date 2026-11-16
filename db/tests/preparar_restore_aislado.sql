USE master;
GO
IF DB_ID(N'reservasScouts_restore_test_codex') IS NOT NULL
 THROW 51200,N'La base temporal ya existe. No se sobrescribe.',1;
GO
CREATE OR ALTER PROCEDURE dbo.paRestaurarReservasScoutsPrueba @pRuta NVARCHAR(4000)
AS
BEGIN
 SET NOCOUNT ON;
 IF DB_ID(N'reservasScouts_restore_test_codex') IS NOT NULL
  THROW 51200,N'La prueba solo puede crear una base temporal nueva.',1;
 DECLARE @data sysname,@log sysname,@dataPath NVARCHAR(4000),@logPath NVARCHAR(4000),@sql NVARCHAR(MAX);
 SELECT @data=name FROM reservasScouts.sys.database_files WHERE type=0;
 SELECT @log=name FROM reservasScouts.sys.database_files WHERE type=1;
 SET @dataPath=CONVERT(NVARCHAR(4000),SERVERPROPERTY('InstanceDefaultDataPath'))+N'reservasScouts_restore_test_codex.mdf';
 SET @logPath=CONVERT(NVARCHAR(4000),SERVERPROPERTY('InstanceDefaultLogPath'))+N'reservasScouts_restore_test_codex_log.ldf';
 IF @data IS NULL OR @log IS NULL OR @dataPath IS NULL OR @logPath IS NULL
  THROW 51201,N'No se pudieron resolver los archivos de la base temporal.',1;
 RESTORE VERIFYONLY FROM DISK=@pRuta WITH CHECKSUM;
 SET @sql=N'RESTORE DATABASE [reservasScouts_restore_test_codex] FROM DISK=N'''+REPLACE(@pRuta,'''','''''')
   +N''' WITH RECOVERY,CHECKSUM,MOVE '+QUOTENAME(@data,'''')+N' TO N'''+REPLACE(@dataPath,'''','''''')
   +N''',MOVE '+QUOTENAME(@log,'''')+N' TO N'''+REPLACE(@logPath,'''','''''')+N''';';
 IF @sql IS NULL THROW 51201,N'La instruccion de prueba no puede estar vacia.',1;
 EXEC sys.sp_executesql @sql;
END;
GO
GRANT EXECUTE ON dbo.paRestaurarReservasScoutsPrueba TO reservas_maintenance;
GO
