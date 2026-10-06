package com.reservasscouts.backend.repository;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.exception.BaseDatosException;
import com.reservasscouts.backend.model.Reserva;
import com.reservasscouts.backend.model.ReservaResumen;

import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ReservaRepository {

    private final JdbcTemplate jdbcTemplate;

    public ReservaRepository(
            JdbcTemplate jdbcTemplate
    ) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // =====================================================
    // LISTAR / FILTRAR
    // paReservaFiltrar
    // =====================================================

    public List<ReservaResumen> filtrar(
            String codigo,
            String responsable,
            String estado,
            Integer espacioId,
            Integer solicitantePerfilId,
            LocalDate fechaDesde,
            LocalDate fechaHasta
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<List<ReservaResumen>>) connection -> {

                    String sql =
                            "{call dbo.paReservaFiltrar(" +
                            "?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        setStringOrNull(
                                statement,
                                1,
                                codigo
                        );

                        setStringOrNull(
                                statement,
                                2,
                                responsable
                        );

                        setStringOrNull(
                                statement,
                                3,
                                estado
                        );

                        setIntegerOrNull(
                                statement,
                                4,
                                espacioId
                        );

                        setIntegerOrNull(
                                statement,
                                5,
                                solicitantePerfilId
                        );

                        setDateOrNull(
                                statement,
                                6,
                                fechaDesde
                        );

                        setDateOrNull(
                                statement,
                                7,
                                fechaHasta
                        );

                        // OUTPUT
                        statement.registerOutParameter(
                                8,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                9,
                                Types.NVARCHAR
                        );

                        List<ReservaResumen> reservas =
                                new ArrayList<>();

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                while (rs.next()) {

                                    reservas.add(
                                            mapearResumen(rs)
                                    );
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                8,
                                9
                        );

                        return reservas;
                    }
                }
        );
    }

    // =====================================================
    // BUSCAR POR ID
    // paReservaBuscarPorId
    // =====================================================

    public Reserva buscarPorId(
            Integer id
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<Reserva>) connection -> {

                    String sql =
                            "{call dbo.paReservaBuscarPorId(?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                id
                        );

                        statement.registerOutParameter(
                                2,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                3,
                                Types.NVARCHAR
                        );

                        Reserva reserva = null;

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                if (rs.next()) {
                                    reserva =
                                            mapearReserva(rs);
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                2,
                                3
                        );

                        return reserva;
                    }
                }
        );
    }

    // =====================================================
    // INSERTAR
    // paReservaInsertar
    // =====================================================

    public Reserva insertar(
            ReservaRequest request
    ) {

        Integer idGenerado =
                jdbcTemplate.execute(
                        (ConnectionCallback<Integer>) connection -> {

                    String sql =
                            "{call dbo.paReservaInsertar(" +
                            "?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setString(
                                1,
                                request.codigo()
                        );

                        statement.setInt(
                                2,
                                request.espacioId()
                        );

                        statement.setInt(
                                3,
                                request.solicitantePerfilId()
                        );

                        setIntegerOrNull(
                                statement,
                                4,
                                request.creadoPorUsuarioId()
                        );

                        setStringOrNull(
                                statement,
                                5,
                                request.grupo()
                        );

                        statement.setString(
                                6,
                                request.responsable()
                        );

                        statement.setString(
                                7,
                                request.telefono()
                        );

                        statement.setString(
                                8,
                                request.email()
                        );

                        statement.setInt(
                                9,
                                request.participantes()
                        );

                        statement.setString(
                                10,
                                request.tipoActividad()
                        );

                        statement.setTimestamp(
                                11,
                                Timestamp.valueOf(
                                        request.fechaInicio()
                                )
                        );

                        statement.setTimestamp(
                                12,
                                Timestamp.valueOf(
                                        request.fechaFin()
                                )
                        );

                        statement.setString(
                                13,
                                request.estado()
                        );

                        setStringOrNull(
                                statement,
                                14,
                                request.observaciones()
                        );

                        // OUTPUT ID
                        statement.registerOutParameter(
                                15,
                                Types.INTEGER
                        );

                        // OUTPUT resultado
                        statement.registerOutParameter(
                                16,
                                Types.TINYINT
                        );

                        // OUTPUT mensaje
                        statement.registerOutParameter(
                                17,
                                Types.NVARCHAR
                        );

                        statement.execute();

                        validarResultado(
                                statement,
                                16,
                                17
                        );

                        return statement.getInt(15);
                    }
                });

        return buscarPorId(
                idGenerado
        );
    }

    // =====================================================
    // ACTUALIZAR
    // paReservaActualizar
    // =====================================================

    public Reserva actualizar(
            Integer id,
            ReservaRequest request
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paReservaActualizar(" +
                            "?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                id
                        );

                        statement.setString(
                                2,
                                request.codigo()
                        );

                        statement.setInt(
                                3,
                                request.espacioId()
                        );

                        statement.setInt(
                                4,
                                request.solicitantePerfilId()
                        );

                        setIntegerOrNull(
                                statement,
                                5,
                                request.creadoPorUsuarioId()
                        );

                        setStringOrNull(
                                statement,
                                6,
                                request.grupo()
                        );

                        statement.setString(
                                7,
                                request.responsable()
                        );

                        statement.setString(
                                8,
                                request.telefono()
                        );

                        statement.setString(
                                9,
                                request.email()
                        );

                        statement.setInt(
                                10,
                                request.participantes()
                        );

                        statement.setString(
                                11,
                                request.tipoActividad()
                        );

                        statement.setTimestamp(
                                12,
                                Timestamp.valueOf(
                                        request.fechaInicio()
                                )
                        );

                        statement.setTimestamp(
                                13,
                                Timestamp.valueOf(
                                        request.fechaFin()
                                )
                        );

                        statement.setString(
                                14,
                                request.estado()
                        );

                        setStringOrNull(
                                statement,
                                15,
                                request.observaciones()
                        );

                        statement.registerOutParameter(
                                16,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                17,
                                Types.NVARCHAR
                        );

                        statement.execute();

                        validarResultado(
                                statement,
                                16,
                                17
                        );

                        return null;
                    }
                }
        );

        return buscarPorId(id);
    }

    // =====================================================
    // ELIMINAR
    // paReservaEliminar
    // =====================================================

    public void eliminar(
            Integer id
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paReservaEliminar(?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                id
                        );

                        statement.registerOutParameter(
                                2,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                3,
                                Types.NVARCHAR
                        );

                        statement.execute();

                        validarResultado(
                                statement,
                                2,
                                3
                        );

                        return null;
                    }
                }
        );
    }

    // =====================================================
    // VALIDAR OUTPUT
    // =====================================================

    private void validarResultado(
            CallableStatement statement,
            int indiceResultado,
            int indiceMensaje
    ) throws SQLException {

        int resultado =
                statement.getInt(
                        indiceResultado
                );

        String mensaje =
                statement.getString(
                        indiceMensaje
                );

        if (resultado != 1) {

            throw new BaseDatosException(
                    mensaje == null ||
                    mensaje.isBlank()
                            ? "No se pudo realizar la operación."
                            : mensaje
            );
        }
    }

    // =====================================================
    // STRING NULL
    // =====================================================

    private void setStringOrNull(
            CallableStatement statement,
            int indice,
            String valor
    ) throws SQLException {

        if (valor == null ||
            valor.isBlank()) {

            statement.setNull(
                    indice,
                    Types.NVARCHAR
            );

        } else {

            statement.setString(
                    indice,
                    valor
            );
        }
    }

    // =====================================================
    // INTEGER NULL
    // =====================================================

    private void setIntegerOrNull(
            CallableStatement statement,
            int indice,
            Integer valor
    ) throws SQLException {

        if (valor == null) {

            statement.setNull(
                    indice,
                    Types.INTEGER
            );

        } else {

            statement.setInt(
                    indice,
                    valor
            );
        }
    }

    // =====================================================
    // DATE NULL
    // =====================================================

    private void setDateOrNull(
            CallableStatement statement,
            int indice,
            LocalDate valor
    ) throws SQLException {

        if (valor == null) {

            statement.setNull(
                    indice,
                    Types.DATE
            );

        } else {

            statement.setDate(
                    indice,
                    Date.valueOf(valor)
            );
        }
    }

    // =====================================================
    // MAPEAR LISTADO
    // =====================================================

    private ReservaResumen mapearResumen(
            ResultSet rs
    ) throws SQLException {

        Timestamp inicio =
                rs.getTimestamp(
                        "fechaInicio"
                );

        Timestamp fin =
                rs.getTimestamp(
                        "fechaFin"
                );

        return new ReservaResumen(
                rs.getInt("id"),
                rs.getString("codigo"),
                rs.getString("espacio"),
                rs.getString("solicitante"),
                rs.getString("responsable"),
                rs.getInt("participantes"),
                rs.getString("tipoActividad"),

                inicio == null
                        ? null
                        : inicio.toLocalDateTime(),

                fin == null
                        ? null
                        : fin.toLocalDateTime(),

                rs.getString("estado")
        );
    }

    // =====================================================
    // MAPEAR RESERVA COMPLETA
    // =====================================================

    private Reserva mapearReserva(
            ResultSet rs
    ) throws SQLException {

        Integer creadoPorUsuarioId =
                rs.getInt(
                        "creadoPorUsuarioId"
                );

        if (rs.wasNull()) {
            creadoPorUsuarioId = null;
        }

        Timestamp inicio =
                rs.getTimestamp(
                        "fechaInicio"
                );

        Timestamp fin =
                rs.getTimestamp(
                        "fechaFin"
                );

        Timestamp created =
                rs.getTimestamp(
                        "createdAt"
                );

        Timestamp updated =
                rs.getTimestamp(
                        "updatedAt"
                );

        return new Reserva(
                rs.getInt("id"),
                rs.getString("codigo"),

                rs.getInt(
                        "espacioId"
                ),

                rs.getString(
                        "espacio"
                ),

                rs.getInt(
                        "solicitantePerfilId"
                ),

                rs.getString(
                        "solicitante"
                ),

                creadoPorUsuarioId,

                rs.getString(
                        "creadoPor"
                ),

                rs.getString(
                        "grupo"
                ),

                rs.getString(
                        "responsable"
                ),

                rs.getString(
                        "telefono"
                ),

                rs.getString(
                        "email"
                ),

                rs.getInt(
                        "participantes"
                ),

                rs.getString(
                        "tipoActividad"
                ),

                inicio == null
                        ? null
                        : inicio.toLocalDateTime(),

                fin == null
                        ? null
                        : fin.toLocalDateTime(),

                rs.getString(
                        "estado"
                ),

                rs.getString(
                        "observaciones"
                ),

                created == null
                        ? null
                        : created.toLocalDateTime(),

                updated == null
                        ? null
                        : updated.toLocalDateTime()
        );
    }
}