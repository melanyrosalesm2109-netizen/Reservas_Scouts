-- Contacto para completar reservas. La consulta conserva el filtro por usuario.
USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.paPerfilOpcionesReserva
    @pUsuarioId INT = NULL,
    @pUsuarioContactoId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idPerfil, nombre, tipoPerfil, usuarioId,
        CASE WHEN usuarioId = @pUsuarioContactoId THEN telefono END AS telefono,
        CASE WHEN usuarioId = @pUsuarioContactoId THEN correoContacto END AS correoContacto
    FROM dbo.perfilesUsuario
    WHERE @pUsuarioId IS NULL OR usuarioId = @pUsuarioId
    ORDER BY nombre;
END;
GO
