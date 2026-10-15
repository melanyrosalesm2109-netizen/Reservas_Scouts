USE reservasScouts;
GO

/* =========================================================
   TABLA DE AUDITORÍA DE PAGOS

   Registra los cambios realizados sobre la tabla pagos.
   Guarda la operación, los valores anteriores y nuevos,
   el usuario y la fecha en que ocurrió el cambio.
========================================================= */

IF OBJECT_ID(N'dbo.auditoriaPagos', N'U') IS NULL
BEGIN

    CREATE TABLE dbo.auditoriaPagos
    (
        idAuditoriaPago BIGINT IDENTITY(1,1) NOT NULL,

        pagoId INT NOT NULL,

        reservaId INT NULL,

        accion NVARCHAR(10) NOT NULL,

        valoresAnteriores NVARCHAR(MAX) NULL,

        valoresNuevos NVARCHAR(MAX) NULL,

        usuarioAppId INT NULL,

        usuarioAppNombre NVARCHAR(160) NULL,

        usuarioBd NVARCHAR(120) NOT NULL,

        creadoEn DATETIME2(0) NOT NULL
            CONSTRAINT dfAuditoriaPagosCreadoEn
            DEFAULT SYSDATETIME(),

        CONSTRAINT pkAuditoriaPagos
            PRIMARY KEY (idAuditoriaPago),

        CONSTRAINT ckAuditoriaPagosAccion
            CHECK
            (
                accion IN
                (
                    N'INSERT',
                    N'UPDATE',
                    N'DELETE'
                )
            )
    );

END;
GO


/* =========================================================
   TRIGGER: trgPagosAuditoria

   Registra automáticamente INSERT, UPDATE y DELETE
   realizados sobre la tabla pagos.
========================================================= */

CREATE OR ALTER TRIGGER dbo.trgPagosAuditoria
ON dbo.pagos
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

        /* Valores antes del cambio */
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
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )
            ELSE NULL
        END,

        /* Valores después del cambio */
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
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
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

        LEFT(
            ORIGINAL_LOGIN(),
            120
        ),

        SYSDATETIME()

    FROM inserted AS i

    FULL OUTER JOIN deleted AS d
        ON d.id = i.id;
END;
GO