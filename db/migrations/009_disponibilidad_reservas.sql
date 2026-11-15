-- Instala la consulta de horarios usada antes de guardar reservas.
USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [dbo].[paReservaDisponibilidad]
    @pEspacioId INT,
    @pFechaInicio DATETIME2(0),
    @pFechaFin DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    IF @pEspacioId IS NULL
       OR @pEspacioId <= 0
    BEGIN
        THROW 50001, N'El espacio indicado no es válido.', 1;
    END;

    IF @pFechaInicio IS NULL
       OR @pFechaFin IS NULL
       OR @pFechaFin <= @pFechaInicio
    BEGIN
        THROW 50002, N'El rango de fechas no es válido.', 1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.espacios
        WHERE id = @pEspacioId
    )
    BEGIN
        THROW 50003, N'El espacio indicado no existe.', 1;
    END;

    DECLARE @estadoEspacio NVARCHAR(20);

    SELECT
        @estadoEspacio = estado
    FROM dbo.espacios
    WHERE id = @pEspacioId;

    SELECT
        CAST(
            CASE
                WHEN @estadoEspacio <> N'DISPONIBLE'
                    THEN 0

                WHEN EXISTS (
                    SELECT 1
                    FROM dbo.reservas
                    WHERE espacioId = @pEspacioId
                      AND estado IN (
                          N'PENDIENTE',
                          N'APROBADA'
                      )
                      AND @pFechaInicio < fechaFin
                      AND @pFechaFin > fechaInicio
                )
                    THEN 0

                ELSE 1
            END
            AS BIT
        ) AS disponible;
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paReservaDisponibilidad TO reservas_app;
GO
