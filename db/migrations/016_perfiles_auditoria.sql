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

CREATE OR ALTER TRIGGER [dbo].[trgPerfilesUsuarioAuditoria]
ON [dbo].[perfilesUsuario]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuarioBd NVARCHAR(120) = LEFT(ORIGINAL_LOGIN(), 120);

    INSERT INTO dbo.auditoriaReservas
    (
        tabla, idRegistro, accion, detalle,
        usuarioAppId, usuarioAppNombre, usuarioBd, creadoEn
    )
    SELECT
        N'perfilesUsuario',
        COALESCE(i.idPerfil, d.idPerfil),
        CASE
            WHEN d.idPerfil IS NULL THEN N'INSERT'
            WHEN i.idPerfil IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        (
            SELECT
                JSON_QUERY(CASE WHEN d.idPerfil IS NOT NULL THEN
                    (SELECT d.usuarioId, d.tipoPerfil, d.nombre, d.identificacion, d.telefono, d.correoContacto, d.direccion
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS antes,
                JSON_QUERY(CASE WHEN i.idPerfil IS NOT NULL THEN
                    (SELECT i.usuarioId, i.tipoPerfil, i.nombre, i.identificacion, i.telefono, i.correoContacto, i.direccion
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
                END) AS despues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        TRY_CONVERT(
            INT,
            SESSION_CONTEXT(N'app_usuario_id')
        ),
        TRY_CONVERT(
            NVARCHAR(160),
            SESSION_CONTEXT(N'app_usuario_nombre')
        ),
        @usuarioBd,
        SYSDATETIME()
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d ON d.idPerfil = i.idPerfil;
END;
GO
