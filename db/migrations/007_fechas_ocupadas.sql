-- Calendario de disponibilidad: solo expone el espacio y los intervalos activos.
USE [reservasScouts];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.paReservaFechasOcupadas
AS
BEGIN
    SET NOCOUNT ON;
    SELECT espacioId, fechaInicio, fechaFin
    FROM dbo.reservas
    WHERE estado IN (N'PENDIENTE', N'APROBADA')
    ORDER BY espacioId, fechaInicio;
END;
GO
GRANT EXECUTE ON OBJECT::dbo.paReservaFechasOcupadas TO reservas_app;
GO
