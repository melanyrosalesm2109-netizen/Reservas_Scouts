USE [master];
GO

IF LEN(N'$(MaintenancePassword)') < 20
    THROW 50030, N'Defina MaintenancePassword como una contraseña aleatoria de al menos 20 caracteres.', 1;
GO

DECLARE @password NVARCHAR(128) = N'$(MaintenancePassword)';
DECLARE @sql NVARCHAR(MAX);

IF SUSER_ID(N'reservas_maintenance') IS NULL
    SET @sql = N'CREATE LOGIN [reservas_maintenance] WITH PASSWORD = '
        + QUOTENAME(@password, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
ELSE
    SET @sql = N'ALTER LOGIN [reservas_maintenance] WITH PASSWORD = '
        + QUOTENAME(@password, '''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';

EXEC sys.sp_executesql @sql;

IF IS_SRVROLEMEMBER(N'dbcreator', N'reservas_maintenance') <> 1
    ALTER SERVER ROLE [dbcreator] ADD MEMBER [reservas_maintenance];
GO

USE [reservasScouts];
GO

IF DATABASE_PRINCIPAL_ID(N'reservas_maintenance') IS NULL
    CREATE USER [reservas_maintenance] FOR LOGIN [reservas_maintenance];
IF IS_ROLEMEMBER(N'db_backupoperator', N'reservas_maintenance') <> 1
    ALTER ROLE [db_backupoperator] ADD MEMBER [reservas_maintenance];
GO
