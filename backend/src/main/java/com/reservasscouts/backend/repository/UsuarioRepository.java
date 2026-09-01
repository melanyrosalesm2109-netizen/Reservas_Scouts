package com.reservasscouts.backend.repository;

import com.reservasscouts.backend.exception.BaseDatosException;
import com.reservasscouts.backend.model.Rol;
import com.reservasscouts.backend.model.Usuario;
import com.reservasscouts.backend.model.UsuarioLogin;

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
public class UsuarioRepository {

    private final JdbcTemplate jdbcTemplate;

    public UsuarioRepository(
            JdbcTemplate jdbcTemplate
    ) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // =====================================================
    // LISTAR / FILTRAR USUARIOS
    // =====================================================

    public List<Usuario> filtrar(
            String email,
            Integer rolId,
            String estado
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<List<Usuario>>) connection -> {

                    String sql =
                            "{call dbo.paUsuarioFiltrar(?,?,?,?,?)}";

                    try (
                            CallableStatement statement =
                                    connection.prepareCall(sql)
                    ) {

                        setStringOrNull(
                                statement,
                                1,
                                email
                        );

                        setIntegerOrNull(
                                statement,
                                2,
                                rolId
                        );

                        setStringOrNull(
                                statement,
                                3,
                                estado
                        );

                        statement.registerOutParameter(
                                4,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                5,
                                Types.NVARCHAR
                        );

                        List<Usuario> usuarios =
                                new ArrayList<>();

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (
                                    ResultSet rs =
                                            statement.getResultSet()
                            ) {

                                while (rs.next()) {

                                    usuarios.add(
                                            mapearUsuario(rs)
                                    );
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                4,
                                5
                        );

                        return usuarios;
                    }
                }
        );
    }

    // =====================================================
    // BUSCAR USUARIO POR ID
    // =====================================================

    public Usuario buscarPorId(
            Integer id
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<Usuario>) connection -> {

                    String sql =
                            "{call dbo.paUsuarioBuscarPorId(?,?,?)}";

                    try (
                            CallableStatement statement =
                                    connection.prepareCall(sql)
                    ) {

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

                        Usuario usuario = null;

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (
                                    ResultSet rs =
                                            statement.getResultSet()
                            ) {

                                if (rs.next()) {

                                    usuario =
                                            mapearUsuario(rs);
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                2,
                                3
                        );

                        return usuario;
                    }
                }
        );
    }

    // =====================================================
    // INSERTAR USUARIO
    // =====================================================

    public Usuario insertar(
            Integer rolId,
            String email,
            String passwordHash,
            String estado
    ) {

        Integer idGenerado =
                jdbcTemplate.execute(
                        (ConnectionCallback<Integer>) connection -> {

                            String sql =
                                    "{call dbo.paUsuarioInsertar(?,?,?,?,?,?,?)}";

                            try (
                                    CallableStatement statement =
                                            connection.prepareCall(sql)
                            ) {

                                statement.setInt(
                                        1,
                                        rolId
                                );

                                statement.setString(
                                        2,
                                        email
                                );

                                statement.setString(
                                        3,
                                        passwordHash
                                );

                                statement.setString(
                                        4,
                                        estado
                                );

                                statement.registerOutParameter(
                                        5,
                                        Types.INTEGER
                                );

                                statement.registerOutParameter(
                                        6,
                                        Types.TINYINT
                                );

                                statement.registerOutParameter(
                                        7,
                                        Types.NVARCHAR
                                );

                                statement.execute();

                                validarResultado(
                                        statement,
                                        6,
                                        7
                                );

                                return statement.getInt(
                                        5
                                );
                            }
                        }
                );

        return buscarPorId(
                idGenerado
        );
    }

    // =====================================================
    // ACTUALIZAR USUARIO
    // =====================================================

    public Usuario actualizar(
            Integer id,
            Integer rolId,
            String email,
            String passwordHash,
            String estado
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paUsuarioActualizar(?,?,?,?,?,?,?)}";

                    try (
                            CallableStatement statement =
                                    connection.prepareCall(sql)
                    ) {

                        statement.setInt(
                                1,
                                id
                        );

                        statement.setInt(
                                2,
                                rolId
                        );

                        statement.setString(
                                3,
                                email
                        );

                        // Si no se escribe una contraseña nueva,
                        // mandamos NULL para conservar la anterior.
                        if (
                                passwordHash == null ||
                                passwordHash.isBlank()
                        ) {

                            statement.setNull(
                                    4,
                                    Types.NVARCHAR
                            );

                        } else {

                            statement.setString(
                                    4,
                                    passwordHash
                            );
                        }

                        statement.setString(
                                5,
                                estado
                        );

                        statement.registerOutParameter(
                                6,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                7,
                                Types.NVARCHAR
                        );

                        statement.execute();

                        validarResultado(
                                statement,
                                6,
                                7
                        );

                        return null;
                    }
                }
        );

        return buscarPorId(id);
    }

    // =====================================================
    // ELIMINAR USUARIO
    // =====================================================

    public void eliminar(
            Integer id
    ) {

        jdbcTemplate.execute(
                (ConnectionCallback<Void>) connection -> {

                    String sql =
                            "{call dbo.paUsuarioEliminar(?,?,?)}";

                    try (
                            CallableStatement statement =
                                    connection.prepareCall(sql)
                    ) {

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
    // LISTAR ROLES
    // =====================================================

    public List<Rol> listarRoles() {

        return jdbcTemplate.execute(
                (ConnectionCallback<List<Rol>>) connection -> {

                    String sql =
                            "{call dbo.paRolFiltrar(?,?,?,?)}";

                    try (
                            CallableStatement statement =
                                    connection.prepareCall(sql)
                    ) {

                        statement.setNull(
                                1,
                                Types.NVARCHAR
                        );

                        statement.setNull(
                                2,
                                Types.NVARCHAR
                        );

                        statement.registerOutParameter(
                                3,
                                Types.TINYINT
                        );

                        statement.registerOutParameter(
                                4,
                                Types.NVARCHAR
                        );

                        List<Rol> roles =
                                new ArrayList<>();

                        boolean tieneResultado =
                                statement.execute();

                        if (tieneResultado) {

                            try (
                                    ResultSet rs =
                                            statement.getResultSet()
                            ) {

                                while (rs.next()) {

                                    roles.add(
                                            mapearRol(rs)
                                    );
                                }
                            }
                        }

                        validarResultado(
                                statement,
                                3,
                                4
                        );

                        return roles;
                    }
                }
        );
    }

    // =====================================================
    // LOGIN
    // Busca usuario por correo para validar contraseña
    // =====================================================

    public UsuarioLogin buscarParaLogin(
            String email
    ) {

        return jdbcTemplate.execute(
                (ConnectionCallback<UsuarioLogin>) connection -> {

                    String sql =
                            "{call dbo.paUsuarioLogin(?)}";

                    try (
                            CallableStatement statement =
                                    connection.prepareCall(sql)
                    ) {

                        statement.setString(
                                1,
                                email
                        );

                        try (
                                ResultSet rs =
                                        statement.executeQuery()
                        ) {

                            if (rs.next()) {

                                return new UsuarioLogin(

                                        rs.getInt(
                                                "id"
                                        ),

                                        rs.getString(
                                                "email"
                                        ),

                                        rs.getString(
                                                "password_hash"
                                        ),

                                        rs.getString(
                                                "estado"
                                        ),

                                        rs.getInt(
                                                "rol_id"
                                        ),

                                        rs.getString(
                                                "rol"
                                        )
                                );
                            }

                            return null;
                        }
                    }
                }
        );
    }

    // =====================================================
    // VALIDAR RESPUESTA DE PROCEDIMIENTOS
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
    // STRING O NULL
    // =====================================================

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

    // =====================================================
    // INTEGER O NULL
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
    // MAPEAR USUARIO
    // =====================================================

    private Usuario mapearUsuario(
            ResultSet rs
    ) throws SQLException {

        Timestamp created =
                rs.getTimestamp(
                        "created_at"
                );

        Timestamp updated =
                rs.getTimestamp(
                        "updated_at"
                );

        return new Usuario(

                rs.getInt(
                        "id"
                ),

                rs.getInt(
                        "rol_id"
                ),

                rs.getString(
                        "rol"
                ),

                rs.getString(
                        "email"
                ),

                rs.getString(
                        "estado"
                ),

                created == null
                        ? null
                        : created.toLocalDateTime(),

                updated == null
                        ? null
                        : updated.toLocalDateTime()
        );
    }

    // =====================================================
    // MAPEAR ROL
    // =====================================================

    private Rol mapearRol(
            ResultSet rs
    ) throws SQLException {

        Timestamp created =
                rs.getTimestamp(
                        "created_at"
                );

        return new Rol(

                rs.getInt(
                        "id"
                ),

                rs.getString(
                        "nombre"
                ),

                rs.getString(
                        "descripcion"
                ),

                created == null
                        ? null
                        : created.toLocalDateTime()
        );
    }
}