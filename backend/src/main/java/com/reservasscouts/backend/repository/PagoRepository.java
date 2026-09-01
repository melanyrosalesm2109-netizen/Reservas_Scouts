package com.reservasscouts.backend.repository;

import com.reservasscouts.backend.dto.PagoRequest;
import com.reservasscouts.backend.exception.BaseDatosException;
import com.reservasscouts.backend.model.Pago;

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
public class PagoRepository {

    private final JdbcTemplate jdbcTemplate;

    public PagoRepository(
            JdbcTemplate jdbcTemplate
    ) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // =====================================================
    // LISTAR / FILTRAR
    // paPagoFiltrar
    // =====================================================

    public List<Pago> filtrar(
            Integer reservaId,
            String codigoReserva,
            String metodo,
            String estado,
            LocalDate fechaDesde,
            LocalDate fechaHasta
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<List<Pago>>) connection -> {

                    String sql =
                            "{call dbo.paPagoFiltrar(?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        setIntegerOrNull(
                                statement,
                                1,
                                reservaId
                        );

                        setStringOrNull(
                                statement,
                                2,
                                codigoReserva
                        );

                        setStringOrNull(
                                statement,
                                3,
                                metodo
                        );

                        setStringOrNull(
                                statement,
                                4,
                                estado
                        );

                        setDateOrNull(
                                statement,
                                5,
                                fechaDesde
                        );

                        setDateOrNull(
                                statement,
                                6,
                                fechaHasta
                        );

                        statement.registerOutParameter(
                                7,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                8,
                                Types.NVARCHAR
                        );

                        List<Pago> pagos =
                                new ArrayList<>();

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                while (rs.next()) {
                                    pagos.add(
                                            mapearPago(rs)
                                    );
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                7,
                                8
                        );

                        return pagos;
                    }
                }
        );
    }

    // =====================================================
    // BUSCAR POR ID
    // =====================================================

    public Pago buscarPorId(
            Integer id
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<Pago>) connection -> {

                    String sql =
                            "{call dbo.paPagoBuscarPorId(?,?,?)}";

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

                        Pago pago = null;

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                if (rs.next()) {
                                    pago =
                                            mapearPago(rs);
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                2,
                                3
                        );

                        return pago;
                    }
                }
        );
    }

    // =====================================================
    // INSERTAR
    // =====================================================

    public Pago insertar(
            PagoRequest request
    ) {

        Integer idGenerado =
                jdbcTemplate.execute(
                        (ConnectionCallback<Integer>) connection -> {

                    String sql =
                            "{call dbo.paPagoInsertar(" +
                            "?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                request.reservaId()
                        );

                        statement.setBigDecimal(
                                2,
                                request.monto()
                        );

                        statement.setString(
                                3,
                                request.metodo()
                        );

                        statement.setDate(
                                4,
                                Date.valueOf(
                                        request.fechaPago()
                                )
                        );

                        statement.setString(
                                5,
                                request.estado()
                        );

                        setStringOrNull(
                                statement,
                                6,
                                request.comprobante()
                        );

                        setStringOrNull(
                                statement,
                                7,
                                request.notas()
                        );

                        statement.registerOutParameter(
                                8,
                                Types.INTEGER
                        );

                        statement.registerOutParameter(
                                9,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                10,
                                Types.NVARCHAR
                        );

                        statement.execute();

                        validarResultado(
                                statement,
                                9,
                                10
                        );

                        return statement.getInt(8);
                    }
                });

        return buscarPorId(
                idGenerado
        );
    }

    // =====================================================
    // ACTUALIZAR
    // =====================================================

    public Pago actualizar(
            Integer id,
            PagoRequest request
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paPagoActualizar(" +
                            "?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                id
                        );

                        statement.setInt(
                                2,
                                request.reservaId()
                        );

                        statement.setBigDecimal(
                                3,
                                request.monto()
                        );

                        statement.setString(
                                4,
                                request.metodo()
                        );

                        statement.setDate(
                                5,
                                Date.valueOf(
                                        request.fechaPago()
                                )
                        );

                        statement.setString(
                                6,
                                request.estado()
                        );

                        setStringOrNull(
                                statement,
                                7,
                                request.comprobante()
                        );

                        setStringOrNull(
                                statement,
                                8,
                                request.notas()
                        );

                        statement.registerOutParameter(
                                9,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                10,
                                Types.NVARCHAR
                        );

                        statement.execute();

                        validarResultado(
                                statement,
                                9,
                                10
                        );

                        return null;
                    }
                }
        );

        return buscarPorId(id);
    }

    // =====================================================
    // ELIMINAR
    // =====================================================

    public void eliminar(
            Integer id
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paPagoEliminar(?,?,?)}";

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
    // VALIDAR PROCEDIMIENTO
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

    private void setStringOrNull(
            CallableStatement statement,
            int indice,
            String valor
    ) throws SQLException {

        if (
            valor == null ||
            valor.isBlank()
        ) {

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
    // RESULTSET -> PAGO
    // =====================================================

    private Pago mapearPago(
            ResultSet rs
    ) throws SQLException {

        Date fechaPago =
                rs.getDate(
                        "fecha_pago"
                );

        Timestamp created =
                rs.getTimestamp(
                        "created_at"
                );

        Timestamp updated =
                rs.getTimestamp(
                        "updated_at"
                );

        return new Pago(
                rs.getInt("id"),

                rs.getInt(
                        "reserva_id"
                ),

                rs.getString(
                        "reserva_codigo"
                ),

                rs.getString(
                        "espacio"
                ),

                rs.getBigDecimal(
                        "monto"
                ),

                rs.getString(
                        "metodo"
                ),

                fechaPago == null
                        ? null
                        : fechaPago.toLocalDate(),

                rs.getString(
                        "estado"
                ),

                rs.getString(
                        "comprobante"
                ),

                rs.getString(
                        "notas"
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