USE [reservasScouts];
GO
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
UPDATE dbo.espacios SET nombre = REPLACE(nombre, N' Demo', N''), updatedAt = SYSDATETIME() WHERE nombre IN (N'Campo Scout Demo', N'Salón Scout Demo');
UPDATE dbo.perfilesUsuario SET nombre = REPLACE(REPLACE(nombre, N' Demo', N''), N' de demostración', N''), updatedAt = SYSDATETIME() WHERE nombre IN (N'Invitado de demostración', N'Administrador de demostración', N'Recepcionista de demostración', N'Miembro de demostración', N'Usuario de demostración', N'Grupo Scout Demo Norte', N'Grupo Scout Demo Sur');
UPDATE r SET codigo = REPLACE(r.codigo, N'DEMO-', N''), updatedAt = SYSDATETIME() FROM dbo.reservas r WHERE r.codigo IN (N'DEMO-RES-001', N'DEMO-RES-002') AND NOT EXISTS (SELECT 1 FROM dbo.reservas existente WHERE existente.codigo = REPLACE(r.codigo, N'DEMO-', N''));
COMMIT;
