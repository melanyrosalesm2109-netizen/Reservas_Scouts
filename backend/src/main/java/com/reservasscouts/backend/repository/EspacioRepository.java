package com.reservasscouts.backend.repository;

import com.reservasscouts.backend.dto.EspacioRequest;
import com.reservasscouts.backend.exception.BaseDatosException;
import com.reservasscouts.backend.model.Espacio;

import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class EspacioRepository {

    private final JdbcTemplate jdbcTemplate;

    public EspacioRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // =========================================================
    // FILTRAR / LISTAR
    // paEspacioFiltrar
    // =========================================================

    public List<Espacio> filtrar(
            String nombre,
            String ubicacion,
            String estado,
            Integer capacidadMinima,
            BigDecimal costoMaximo
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<List<Espacio>>) connection -> {

                    String sql =
                            "{call dbo.paEspacioFiltrar(?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        setStringOrNull(
                                statement,
                                1,
                                nombre
                        );

                        setStringOrNull(
                                statement,
                                2,
                                ubicacion
                        );

                        setStringOrNull(
                                statement,
                                3,
                                estado
                        );

                        if (capacidadMinima == null) {
                            statement.setNull(
                                    4,
                                    Types.INTEGER
                            );
                        } else {
                            statement.setInt(
                                    4,
                                    capacidadMinima
                            );
                        }

                        if (costoMaximo == null) {
                            statement.setNull(
                                    5,
                                    Types.DECIMAL
                            );
                        } else {
                            statement.setBigDecimal(
                                    5,
                                    costoMaximo
                            );
                        }

                        // Parámetros OUTPUT
                        statement.registerOutParameter(
                                6,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                7,
                                Types.NVARCHAR
                        );

                        List<Espacio> espacios =
                                new ArrayList<>();

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                while (rs.next()) {
                                    espacios.add(
                                            mapearEspacio(rs)
                                    );
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                6,
                                7
                        );

                        return espacios;
                    }
                }
        );
    }

    // =========================================================
    // BUSCAR POR ID
    // paEspacioBuscarPorId
    // =========================================================

    public Espacio buscarPorId(Integer id) {

        return jdbcTemplate.execute(
                (ConnectionCallback<Espacio>) connection -> {

                    String sql =
                            "{call dbo.paEspacioBuscarPorId(?,?,?)}";

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

                        Espacio espacio = null;

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                if (rs.next()) {
                                    espacio =
                                            mapearEspacio(rs);
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                2,
                                3
                        );

                        return espacio;
                    }
                }
        );
    }

    // =========================================================
    // INSERTAR
    // paEspacioInsertar
    // =========================================================

    public Espacio insertar(
            EspacioRequest request
    ) {

        Integer idGenerado =
                jdbcTemplate.execute(
                        (ConnectionCallback<Integer>)
                                connection -> {

                    String sql =
                            "{call dbo.paEspacioInsertar(" +
                            "?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setString(
                                1,
                                request.nombre()
                        );

                        setStringOrNull(
                                statement,
                                2,
                                request.descripcion()
                        );

                        statement.setString(
                                3,
                                request.ubicacion()
                        );

                        statement.setInt(
                                4,
                                request.capacidad()
                        );

                        statement.setBigDecimal(
                                5,
                                request.costo()
                        );

                        String estado =
                                request.estado() == null ||
                                request.estado().isBlank()
                                        ? "DISPONIBLE"
                                        : request.estado()
                                        .toUpperCase();

                        statement.setString(
                                6,
                                estado
                        );

                        setStringOrNull(
                                statement,
                                7,
                                request.imagen()
                        );

                        // OUTPUT
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

        return buscarPorId(idGenerado);
    }

    // =========================================================
    // ACTUALIZAR
    // paEspacioActualizar
    // =========================================================

    public Espacio actualizar(
            Integer id,
            EspacioRequest request
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paEspacioActualizar(" +
                            "?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                id
                        );

                        statement.setString(
                                2,
                                request.nombre()
                        );

                        setStringOrNull(
                                statement,
                                3,
                                request.descripcion()
                        );

                        statement.setString(
                                4,
                                request.ubicacion()
                        );

                        statement.setInt(
                                5,
                                request.capacidad()
                        );

                        statement.setBigDecimal(
                                6,
                                request.costo()
                        );

                        String estado =
                                request.estado() == null ||
                                request.estado().isBlank()
                                        ? "DISPONIBLE"
                                        : request.estado()
                                        .toUpperCase();

                        statement.setString(
                                7,
                                estado
                        );

                        setStringOrNull(
                                statement,
                                8,
                                request.imagen()
                        );

                        // OUTPUT
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

    // =========================================================
    // ELIMINAR
    // paEspacioEliminar
    // =========================================================

    public void eliminar(Integer id) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paEspacioEliminar(?,?,?)}";

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

    // =========================================================
    // VALIDAR RESULTADO DEL PROCEDURE
    // =========================================================

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
                            ? "La operación no pudo realizarse."
                            : mensaje
            );
        }
    }

    // =========================================================
    // STRING NULL
    // =========================================================

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

    // =========================================================
    // RESULTSET -> ESPACIO
    // =========================================================

    private Espacio mapearEspacio(
            ResultSet rs
    ) throws SQLException {

        Timestamp created =
                rs.getTimestamp(
                        "createdAt"
                );

        Timestamp updated =
                rs.getTimestamp(
                        "updatedAt"
                );

        return new Espacio(
                rs.getInt("id"),
                rs.getString("nombre"),
                rs.getString("descripcion"),
                rs.getString("ubicacion"),
                rs.getInt("capacidad"),
                rs.getBigDecimal("costo"),
                rs.getString("estado"),
                rs.getString("imagen"),

                created == null
                        ? null
                        : created.toLocalDateTime(),

                updated == null
                        ? null
                        : updated.toLocalDateTime()
        );
    }
}