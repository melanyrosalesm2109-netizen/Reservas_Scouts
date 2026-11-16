USE reservasScouts;
GO
CREATE OR ALTER PROCEDURE dbo.paReservaPlazoPrueba @reservaId INT
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.reservas WHERE id=@reservaId AND codigo LIKE N'IT-VENCE-%')
  THROW 51200,N'Solo se permiten reservas temporales de esta prueba.',1;
 UPDATE dbo.reservas SET pagoVenceEn=DATEADD(MINUTE,-1,CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time' AS DATETIME2(0))) WHERE id=@reservaId;
END;
GO
GRANT EXECUTE ON dbo.paReservaPlazoPrueba TO reservas_app;
GO
