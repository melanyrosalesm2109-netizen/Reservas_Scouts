package com.reservasscouts.backend.service;

import com.reservasscouts.backend.model.RespaldoArchivo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
public class RespaldoService {

    private static final String MAINTENANCE_USER =
            "reservas_maintenance";

    private static final String JDBC_PREFIX =
            "jdbc:sqlserver://localhost:1433;"
                    + "encrypt=true;"
                    + "trustServerCertificate=true;"
                    + "databaseName=";

    private static final Pattern BACKUP_NAME =
            Pattern.compile(
                    "^reservasScouts_\\d{8}_\\d{6}_[0-9a-fA-F-]{36}\\.bak$"
            );

    private static final DateTimeFormatter FILE_TIMESTAMP =
            DateTimeFormatter.ofPattern(
                    "yyyyMMdd_HHmmss"
            );

    private static final String RESTORE_CONFIRMATION =
            "RESTAURAR reservasScouts";


    private final Path backupDirectory;

    private final AuditoriaAccesoService auditoriaAcceso;

    private final JdbcTemplate jdbcTemplate;


    public RespaldoService(
            @Value("${app.backup.directory}")
            String backupDirectory,

            AuditoriaAccesoService auditoriaAcceso,

            JdbcTemplate jdbcTemplate
    ) {

        this.backupDirectory =
                Path.of(
                        backupDirectory
                )
                .toAbsolutePath()
                .normalize();

        this.auditoriaAcceso =
                auditoriaAcceso;

        this.jdbcTemplate =
                jdbcTemplate;
    }


    // =====================================================
    // LISTAR RESPALDOS
    // =====================================================

    public List<RespaldoArchivo> listar() {

        return jdbcTemplate.query(

                "EXEC dbo.paRespaldoListar",

                (rs, rowNum) ->
                        new RespaldoArchivo(
                                rs.getString(
                                        "nombre"
                                ),
                                rs.getTimestamp(
                                        "creadoEn"
                                )
                                .toLocalDateTime(),
                                rs.getLong(
                                        "bytes"
                                )
                        )
        );
    }


    // =====================================================
    // CREAR RESPALDO
    // =====================================================

    public RespaldoArchivo crear(
            Integer usuarioId,
            String direccionIp,
            String agenteUsuario
    ) {

        String nombre =
                "reservasScouts_"
                        + LocalDateTime
                        .now()
                        .format(
                                FILE_TIMESTAMP
                        )
                        + "_"
                        + UUID.randomUUID()
                        + ".bak";


        Path destino =
                backupDirectory
                        .resolve(
                                nombre
                        )
                        .normalize();


        validarRutaDestino(
                destino,
                nombre
        );


        String rutaSql =
                escaparLiteral(
                        destino.toString()
                );


        BackupMetadata metadata;


        try (
                Connection connection =
                        conectar(
                                "reservasScouts"
                        );

                Statement statement =
                        connection
                                .createStatement()
        ) {

            /*
             * La aplicación llama al procedimiento
             * almacenado de SQL Server.
             *
             * El procedimiento es el encargado
             * de ejecutar BACKUP DATABASE.
             */
            statement.execute(

                    "EXEC dbo.paRespaldoCompleto "
                            + "@pRuta = N'"
                            + rutaSql
                            + "'"
            );


            /*
             * Después de crear el respaldo,
             * se leen sus metadatos para verificar
             * que pertenece a reservasScouts.
             */
            metadata =
                    leerEncabezado(
                            statement,
                            rutaSql
                    );


            validarEncabezado(
                    metadata
            );


        } catch (SQLException ex) {

            throw new IllegalStateException(
                    "SQL Server no pudo crear o verificar el respaldo.",
                    ex
            );
        }


        registrar(
                usuarioId,
                nombre,
                metadata
        );


        auditoriaAcceso.registrar(
                usuarioId,
                "BACKUP",
                direccionIp,
                agenteUsuario
        );


        return new RespaldoArchivo(
                nombre,
                metadata.fechaFinalizacion(),
                metadata.bytes()
        );
    }


    // =====================================================
    // RESTAURAR RESPALDO
    // =====================================================

    public void restaurar(
            String nombreArchivo,
            String confirmacion,
            Integer usuarioId,
            String direccionIp,
            String agenteUsuario
    ) {

        /*
         * Se exige una confirmación exacta
         * antes de permitir la restauración.
         */
        if (
                !RESTORE_CONFIRMATION.equals(
                        confirmacion
                )
        ) {

            throw new IllegalArgumentException(
                    "La confirmación debe ser exactamente: "
                            + RESTORE_CONFIRMATION
            );
        }


        Path respaldo =
                backupDirectory
                        .resolve(
                                nombreArchivo
                        )
                        .normalize();


        validarRutaDestino(
                respaldo,
                nombreArchivo
        );


        /*
         * Solo se puede restaurar un respaldo
         * creado y registrado por la aplicación.
         */
        if (
                listar()
                        .stream()
                        .noneMatch(
                                item ->
                                        item.nombre()
                                                .equals(
                                                        nombreArchivo
                                                )
                        )
        ) {

            throw new IllegalArgumentException(
                    "El respaldo no está registrado como una copia creada por la aplicación."
            );
        }


        String rutaSql =
                escaparLiteral(
                        respaldo.toString()
                );


        BackupMetadata metadata;


        try (
                Connection connection =
                        conectar(
                                "master"
                        );

                Statement statement =
                        connection
                                .createStatement()
        ) {

            /*
             * Antes de restaurar se revisan
             * los metadatos del archivo.
             */
            metadata =
                    leerEncabezado(
                            statement,
                            rutaSql
                    );


            validarEncabezado(
                    metadata
            );


            /*
             * La aplicación ya no ejecuta
             * RESTORE DATABASE directamente.
             *
             * Ahora llama al procedimiento
             * almacenado creado en master.
             */
            statement.execute(

                    "EXEC dbo.paRestaurarReservasScouts "
                            + "@pRuta = N'"
                            + rutaSql
                            + "'"
            );


        } catch (SQLException ex) {

            throw new IllegalStateException(
                    "SQL Server no pudo restaurar el respaldo seleccionado.",
                    ex
            );
        }


        /*
         * Después de restaurar se registra
         * nuevamente el respaldo en el historial.
         */
        registrar(
                usuarioId,
                nombreArchivo,
                metadata
        );


        auditoriaAcceso.registrar(
                usuarioId,
                "RESTORE",
                direccionIp,
                agenteUsuario
        );
    }


    // =====================================================
    // LEER METADATOS DEL RESPALDO
    // =====================================================

    private BackupMetadata leerEncabezado(
            Statement statement,
            String rutaSql
    ) throws SQLException {

        try (
                ResultSet encabezado =
                        statement.executeQuery(

                                "RESTORE HEADERONLY "
                                        + "FROM DISK = N'"
                                        + rutaSql
                                        + "'"
                        )
        ) {

            if (
                    !encabezado.next()
            ) {

                throw new IllegalArgumentException(
                        "El archivo no contiene metadatos de respaldo."
                );
            }


            Timestamp finalizacion =
                    encabezado.getTimestamp(
                            "BackupFinishDate"
                    );


            if (
                    finalizacion == null
            ) {

                throw new IllegalArgumentException(
                        "El respaldo no tiene fecha de finalización válida."
                );
            }


            return new BackupMetadata(

                    encabezado.getString(
                            "DatabaseName"
                    ),

                    encabezado.getInt(
                            "BackupType"
                    ),

                    finalizacion
                            .toLocalDateTime(),

                    encabezado.getLong(
                            "BackupSize"
                    )
            );
        }
    }


    // =====================================================
    // VALIDAR RESPALDO
    // =====================================================

    private void validarEncabezado(
            BackupMetadata metadata
    ) {

        if (
                !"reservasScouts"
                        .equalsIgnoreCase(
                                metadata.baseDatos()
                        )
                        ||
                        metadata.tipo() != 1
                        ||
                        metadata.bytes() < 0
        ) {

            throw new IllegalArgumentException(
                    "El archivo no contiene un respaldo completo válido de reservasScouts."
            );
        }
    }


    // =====================================================
    // REGISTRAR RESPALDO
    // =====================================================

    private void registrar(
            Integer usuarioId,
            String nombre,
            BackupMetadata metadata
    ) {

        jdbcTemplate.update(

                "EXEC dbo.paRespaldoRegistrar ?, ?, ?, ?",

                nombre,

                usuarioId,

                Timestamp.valueOf(
                        metadata.fechaFinalizacion()
                ),

                metadata.bytes()
        );
    }


    // =====================================================
    // CONEXIÓN DE MANTENIMIENTO
    // =====================================================

    private Connection conectar(
            String baseDatos
    ) throws SQLException {

        String password =
                System.getenv(
                        "RESERVASSCOUTS_MAINTENANCE_PASSWORD"
                );


        if (
                password == null
                        ||
                        password.isBlank()
        ) {

            throw new IllegalStateException(
                    "Falta configurar RESERVASSCOUTS_MAINTENANCE_PASSWORD para las operaciones de respaldo."
            );
        }


        return DriverManager.getConnection(

                JDBC_PREFIX
                        + baseDatos,

                MAINTENANCE_USER,

                password
        );
    }


    // =====================================================
    // VALIDAR NOMBRE Y RUTA
    // =====================================================

    private void validarRutaDestino(
            Path ruta,
            String nombreArchivo
    ) {

        if (
                !BACKUP_NAME
                        .matcher(
                                nombreArchivo
                        )
                        .matches()
                        ||
                        !ruta
                                .getParent()
                                .equals(
                                        backupDirectory
                                )
        ) {

            throw new IllegalArgumentException(
                    "Nombre de archivo de respaldo no permitido."
            );
        }
    }


    // =====================================================
    // ESCAPAR RUTA PARA SQL SERVER
    // =====================================================

    private String escaparLiteral(
            String valor
    ) {

        return valor.replace(
                "'",
                "''"
        );
    }


    // =====================================================
    // METADATOS DEL RESPALDO
    // =====================================================

    private record BackupMetadata(

            String baseDatos,

            int tipo,

            LocalDateTime fechaFinalizacion,

            long bytes

    ) {
    }
}