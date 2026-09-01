package com.reservasscouts.backend.repository;

import com.reservasscouts.backend.dto.PerfilRequest;
import com.reservasscouts.backend.exception.BaseDatosException;
import com.reservasscouts.backend.model.Perfil;

import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

@Repository
public class PerfilRepository {

    private final JdbcTemplate jdbcTemplate;

    public PerfilRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // =====================================================
    // FILTRAR / LISTAR PERFILES
    // =====================================================
    public List<Perfil> filtrar(
            String nombre,
            String identificacion,
            String correoContacto,
            String tipoPerfil,
            Integer usuarioId
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<List<Perfil>>) connection -> {

                    String sql =
                            "{call dbo.paPerfilFiltrar(?,?,?,?,?,?,?)}";

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
                                identificacion
                        );

                        setStringOrNull(
                                statement,
                                3,
                                correoContacto
                        );

                        setStringOrNull(
                                statement,
                                4,
                                tipoPerfil
                        );

                        setIntegerOrNull(
                                statement,
                                5,
                                usuarioId
                        );

                        // OUTPUT
                        statement.registerOutParameter(
                                6,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                7,
                                Types.NVARCHAR
                        );

                        List<Perfil> perfiles =
                                new ArrayList<>();

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                while (rs.next()) {
                                    perfiles.add(
                                            mapearPerfil(rs)
                                    );
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                6,
                                7
                        );

                        return perfiles;
                    }
                }
        );
    }

    // =====================================================
    // BUSCAR POR ID
    // =====================================================
    public Perfil buscarPorId(Integer idPerfil) {

        return jdbcTemplate.execute(
                (ConnectionCallback<Perfil>) connection -> {

                    String sql =
                            "{call dbo.paPerfilBuscarPorId(?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                idPerfil
                        );

                        statement.registerOutParameter(
                                2,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                3,
                                Types.NVARCHAR
                        );

                        Perfil perfil = null;

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (ResultSet rs =
                                         statement.getResultSet()) {

                                if (rs.next()) {
                                    perfil =
                                            mapearPerfil(rs);
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                2,
                                3
                        );

                        return perfil;
                    }
                }
        );
    }

    // =====================================================
    // INSERTAR PERFIL
    // =====================================================
    public Perfil insertar(
            PerfilRequest request
    ) {

        Integer idGenerado =
                jdbcTemplate.execute(
                        (ConnectionCallback<Integer>)
                                connection -> {

                    String sql =
                            "{call dbo.paPerfilInsertar(" +
                            "?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        setIntegerOrNull(
                                statement,
                                1,
                                request.usuarioId()
                        );

                        statement.setString(
                                2,
                                request.nombre()
                        );

                        setStringOrNull(
                                statement,
                                3,
                                request.identificacion()
                        );

                        setStringOrNull(
                                statement,
                                4,
                                request.telefono()
                        );

                        statement.setString(
                                5,
                                request.correoContacto()
                        );

                        statement.setString(
                                6,
                                request.tipoPerfil()
                        );

                        setStringOrNull(
                                statement,
                                7,
                                request.direccion()
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

    // =====================================================
    // ACTUALIZAR PERFIL
    // =====================================================
    public Perfil actualizar(
            Integer idPerfil,
            PerfilRequest request
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paPerfilActualizar(" +
                            "?,?,?,?,?,?,?,?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                idPerfil
                        );

                        setIntegerOrNull(
                                statement,
                                2,
                                request.usuarioId()
                        );

                        statement.setString(
                                3,
                                request.nombre()
                        );

                        setStringOrNull(
                                statement,
                                4,
                                request.identificacion()
                        );

                        setStringOrNull(
                                statement,
                                5,
                                request.telefono()
                        );

                        statement.setString(
                                6,
                                request.correoContacto()
                        );

                        statement.setString(
                                7,
                                request.tipoPerfil()
                        );

                        setStringOrNull(
                                statement,
                                8,
                                request.direccion()
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

        return buscarPorId(idPerfil);
    }

    // =====================================================
    // ELIMINAR PERFIL
    // =====================================================
    public void eliminar(Integer idPerfil) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paPerfilEliminar(?,?,?)}";

                    try (CallableStatement statement =
                                 connection.prepareCall(sql)) {

                        statement.setInt(
                                1,
                                idPerfil
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
    // VALIDAR RESULTADO PROCEDIMIENTO
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
    // RESULTSET -> PERFIL
    // =====================================================
    private Perfil mapearPerfil(
            ResultSet rs
    ) throws SQLException {

        Integer usuarioId =
                rs.getInt(
                        "usuario_id"
                );

        if (rs.wasNull()) {
            usuarioId = null;
        }

        Timestamp created =
                rs.getTimestamp(
                        "created_at"
                );

        Timestamp updated =
                rs.getTimestamp(
                        "updated_at"
                );

        return new Perfil(
                rs.getInt(
                        "id_perfil"
                ),

                usuarioId,

                rs.getString(
                        "nombre"
                ),

                rs.getString(
                        "identificacion"
                ),

                rs.getString(
                        "telefono"
                ),

                rs.getString(
                        "correo_contacto"
                ),

                rs.getString(
                        "tipo_perfil"
                ),

                rs.getString(
                        "direccion"
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