USE [reservasScouts];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ahora DATETIME2(0) = SYSDATETIME();
    DECLARE @hashDemo NVARCHAR(255) =
        N'$2a$10$N9qo8uLOickgx2ZMRZoMye.IjZAgcfl7p92ldGxad68LJZdL17lhWy';

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Invitado')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Invitado', N'Cuenta de demostración para usuarios invitados.', @ahora);

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Administrador')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Administrador', N'Acceso completo y administración del sistema.', @ahora);

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Recepcionista')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Recepcionista', N'Cuenta de demostración para recepción y gestión de reservas.', @ahora);

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Miembro')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Miembro', N'Cuenta de demostración para miembros de grupos Scout.', @ahora);

    IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = N'Usuario')
        INSERT INTO dbo.roles (nombre, descripcion, createdAt)
        VALUES (N'Usuario', N'Puede consultar y crear reservas.', @ahora);

    DECLARE @cuentas TABLE
    (
        email NVARCHAR(160) NOT NULL,
        nombreRol NVARCHAR(50) NOT NULL
    );

    INSERT INTO @cuentas (email, nombreRol)
    VALUES
        (N'invitado@reservasscouts.test', N'Invitado'),
        (N'admin@reservasscouts.test', N'Administrador'),
        (N'recepcion@reservasscouts.test', N'Recepcionista'),
        (N'miembro@reservasscouts.test', N'Miembro');

    INSERT INTO dbo.usuarios (rolId, email, passwordHash, estado, createdAt, updatedAt)
    SELECT r.id, c.email, @hashDemo, N'ACTIVO', @ahora, @ahora
    FROM @cuentas AS c
    INNER JOIN dbo.roles AS r ON r.nombre = c.nombreRol
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.usuarios AS u
        WHERE u.email = c.email
    );

    DECLARE @usuarios TABLE
    (
        email NVARCHAR(160) NOT NULL,
        usuarioId INT NOT NULL,
        nombre NVARCHAR(160) NOT NULL
    );

    INSERT INTO @usuarios (email, usuarioId, nombre)
    SELECT c.email, u.id,
        CASE c.nombreRol
            WHEN N'Invitado' THEN N'Invitado de demostración'
            WHEN N'Administrador' THEN N'Administrador de demostración'
            WHEN N'Recepcionista' THEN N'Recepcionista de demostración'
            ELSE N'Miembro de demostración'
        END
    FROM @cuentas AS c
    INNER JOIN dbo.usuarios AS u ON u.email = c.email;

    INSERT INTO dbo.perfilesUsuario
        (usuarioId, nombre, identificacion, telefono, correoContacto, tipoPerfil,
         direccion, createdAt, updatedAt)
    SELECT u.usuarioId, u.nombre, NULL, N'8888-0000', u.email, N'Persona',
           N'Dirección de demostración', @ahora, @ahora
    FROM @usuarios AS u
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.perfilesUsuario AS p
        WHERE p.usuarioId = u.usuarioId
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE nombre = N'Campo Scout Demo')
        INSERT INTO dbo.espacios
            (nombre, descripcion, ubicacion, capacidad, costo, estado, imagen, createdAt, updatedAt)
        VALUES
            (N'Campo Scout Demo', N'Espacio de demostración para actividades al aire libre.',
             N'Sede principal', 50, 25000.00, N'DISPONIBLE', NULL, @ahora, @ahora);

    IF NOT EXISTS (SELECT 1 FROM dbo.espacios WHERE nombre = N'Salón Scout Demo')
        INSERT INTO dbo.espacios
            (nombre, descripcion, ubicacion, capacidad, costo, estado, imagen, createdAt, updatedAt)
        VALUES
            (N'Salón Scout Demo', N'Salón de demostración para reuniones y talleres.',
             N'Sede principal', 30, 15000.00, N'DISPONIBLE', NULL, @ahora, @ahora);

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.perfilesUsuario
        WHERE correoContacto = N'grupo1@reservasscouts.test'
    )
        INSERT INTO dbo.perfilesUsuario
            (usuarioId, nombre, identificacion, telefono, correoContacto, tipoPerfil,
             direccion, createdAt, updatedAt)
        VALUES
            (NULL, N'Grupo Scout Demo Norte', N'DEMO-GSN-001', N'8888-1111',
             N'grupo1@reservasscouts.test', N'Grupo Scout', N'Región Norte', @ahora, @ahora);

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.perfilesUsuario
        WHERE correoContacto = N'grupo2@reservasscouts.test'
    )
        INSERT INTO dbo.perfilesUsuario
            (usuarioId, nombre, identificacion, telefono, correoContacto, tipoPerfil,
             direccion, createdAt, updatedAt)
        VALUES
            (NULL, N'Grupo Scout Demo Sur', N'DEMO-GSS-002', N'8888-2222',
             N'grupo2@reservasscouts.test', N'Grupo Scout', N'Región Sur', @ahora, @ahora);

    DECLARE @recepcionistaId INT;
    DECLARE @miembroId INT;
    DECLARE @perfilGrupo1Id INT;
    DECLARE @perfilGrupo2Id INT;
    DECLARE @campoId INT;
    DECLARE @salonId INT;
    DECLARE @fechaReserva1 DATETIME2(0) =
        DATEADD(HOUR, 9, DATEADD(DAY, 30, CONVERT(DATETIME2(0), CONVERT(DATE, @ahora))));
    DECLARE @fechaReserva2 DATETIME2(0) =
        DATEADD(HOUR, 14, DATEADD(DAY, 45, CONVERT(DATETIME2(0), CONVERT(DATE, @ahora))));

    SELECT @recepcionistaId = usuarioId
    FROM @usuarios
    WHERE email = N'recepcion@reservasscouts.test';

    SELECT @miembroId = usuarioId
    FROM @usuarios
    WHERE email = N'miembro@reservasscouts.test';

    SELECT @perfilGrupo1Id = idPerfil
    FROM dbo.perfilesUsuario
    WHERE correoContacto = N'grupo1@reservasscouts.test';

    SELECT @perfilGrupo2Id = idPerfil
    FROM dbo.perfilesUsuario
    WHERE correoContacto = N'grupo2@reservasscouts.test';

    SELECT @campoId = id
    FROM dbo.espacios
    WHERE nombre = N'Campo Scout Demo';

    SELECT @salonId = id
    FROM dbo.espacios
    WHERE nombre = N'Salón Scout Demo';

    IF NOT EXISTS (SELECT 1 FROM dbo.reservas WHERE codigo = N'DEMO-RES-001')
        INSERT INTO dbo.reservas
            (codigo, espacioId, solicitantePerfilId, creadoPorUsuarioId, grupo, responsable,
             telefono, email, participantes, tipoActividad, fechaInicio, fechaFin, estado,
             observaciones, createdAt, updatedAt)
        VALUES
            (N'DEMO-RES-001', @campoId, @perfilGrupo1Id, @recepcionistaId,
             N'Grupo Scout Demo Norte', N'Responsable Demo Norte', N'8888-1111',
             N'grupo1@reservasscouts.test', 25, N'Campamento de demostración',
             @fechaReserva1, DATEADD(HOUR, 8, @fechaReserva1), N'PENDIENTE',
             N'Reserva de demostración generada por db/datos.sql.', @ahora, @ahora);

    IF NOT EXISTS (SELECT 1 FROM dbo.reservas WHERE codigo = N'DEMO-RES-002')
        INSERT INTO dbo.reservas
            (codigo, espacioId, solicitantePerfilId, creadoPorUsuarioId, grupo, responsable,
             telefono, email, participantes, tipoActividad, fechaInicio, fechaFin, estado,
             observaciones, createdAt, updatedAt)
        VALUES
            (N'DEMO-RES-002', @salonId, @perfilGrupo2Id, @miembroId,
             N'Grupo Scout Demo Sur', N'Responsable Demo Sur', N'8888-2222',
             N'grupo2@reservasscouts.test', 18, N'Taller de demostración',
             @fechaReserva2, DATEADD(HOUR, 3, @fechaReserva2), N'APROBADA',
             N'Reserva de demostración generada por db/datos.sql.', @ahora, @ahora);

    DECLARE @reserva1Id INT;
    DECLARE @reserva2Id INT;

    SELECT @reserva1Id = id
    FROM dbo.reservas
    WHERE codigo = N'DEMO-RES-001';

    SELECT @reserva2Id = id
    FROM dbo.reservas
    WHERE codigo = N'DEMO-RES-002';

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.pagos
        WHERE reservaId = @reserva1Id AND comprobante = N'DEMO-PAGO-001'
    )
        INSERT INTO dbo.pagos
            (reservaId, monto, metodo, fechaPago, estado, comprobante, notas, createdAt, updatedAt)
        VALUES
            (@reserva1Id, 25000.00, N'Transferencia bancaria', CONVERT(DATE, @ahora),
             N'PENDIENTE', N'DEMO-PAGO-001', N'Pago de demostración pendiente.',
             @ahora, @ahora);

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.pagos
        WHERE reservaId = @reserva2Id AND comprobante = N'DEMO-PAGO-002'
    )
        INSERT INTO dbo.pagos
            (reservaId, monto, metodo, fechaPago, estado, comprobante, notas, createdAt, updatedAt)
        VALUES
            (@reserva2Id, 15000.00, N'SINPE Móvil', CONVERT(DATE, @ahora),
             N'PAGADO', N'DEMO-PAGO-002', N'Pago de demostración recibido.',
             @ahora, @ahora);

    COMMIT TRANSACTION;

    SELECT N'Roles, usuarios, perfiles, espacios, reservas y pagos de demostración cargados.' AS mensaje;
    SELECT u.email, r.nombre AS rol, u.estado
    FROM dbo.usuarios AS u
    INNER JOIN dbo.roles AS r ON r.id = u.rolId
    WHERE u.email IN
    (
        N'invitado@reservasscouts.test',
        N'admin@reservasscouts.test',
        N'recepcion@reservasscouts.test',
        N'miembro@reservasscouts.test'
    )
    ORDER BY r.nombre;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
