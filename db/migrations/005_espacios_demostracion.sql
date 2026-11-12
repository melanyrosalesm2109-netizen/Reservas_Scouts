-- Agrega solo registros ausentes. No modifica el esquema ni datos existentes.
USE [reservasScouts];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
INSERT INTO dbo.espacios (nombre, descripcion, ubicacion, capacidad, costo, estado, imagen, createdAt, updatedAt)
SELECT d.*, SYSDATETIME(), SYSDATETIME()
FROM (VALUES
(N'Campo Escuela Nacional Iztarú', N'Campo escuela. Datos de demostración del proyecto: capacidad, costo y disponibilidad no oficiales. Imagen ilustrativa generada con IA; no representa la instalación real.', N'Cartago', 120, 35000, N'DISPONIBLE', N'/images/espacios/campo-demo.png'),
(N'Campo Escuela Nacional Yörí', N'Campo escuela. Datos de demostración del proyecto: capacidad, costo y disponibilidad no oficiales. Imagen ilustrativa generada con IA; no representa la instalación real.', N'Sarapiquí, Heredia', 100, 30000, N'DISPONIBLE', N'/images/espacios/campo-demo.png'),
(N'Sede Nacional', N'Sede institucional. Datos de demostración del proyecto: capacidad, costo y disponibilidad no oficiales. Imagen ilustrativa generada con IA; no representa la instalación real.', N'San Vicente, Moravia', 60, 25000, N'DISPONIBLE', N'/images/espacios/sede-demo.png'),
(N'Centro de Atención Alajuela', N'Centro de atención. Datos de demostración del proyecto: capacidad, costo y disponibilidad no oficiales. Imagen ilustrativa generada con IA; no representa la instalación real.', N'Alajuela', 40, 15000, N'DISPONIBLE', N'/images/espacios/centro-demo.png'),
(N'Centro de Atención Cartago', N'Centro de atención. Datos de demostración del proyecto: capacidad, costo y disponibilidad no oficiales. Imagen ilustrativa generada con IA; no representa la instalación real.', N'Cartago', 40, 15000, N'DISPONIBLE', N'/images/espacios/centro-demo.png'),
(N'Centro de Atención San José Casa Guía', N'Centro de atención. Datos de demostración del proyecto: capacidad, costo y disponibilidad no oficiales. Imagen ilustrativa generada con IA; no representa la instalación real.', N'San José', 50, 20000, N'DISPONIBLE', N'/images/espacios/centro-demo.png')
) AS d(nombre, descripcion, ubicacion, capacidad, costo, estado, imagen)
WHERE NOT EXISTS (SELECT 1 FROM dbo.espacios e WITH (UPDLOCK, HOLDLOCK) WHERE e.nombre = d.nombre);
COMMIT;
