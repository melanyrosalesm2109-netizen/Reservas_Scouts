USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.paUsuariosRegistradosIds
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.id
    FROM dbo.usuarios u
    INNER JOIN dbo.roles r ON r.id = u.rolId
    WHERE r.nombre IN (N'Usuario', N'Miembro');
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paUsuariosRegistradosIds TO reservas_app;
GO
