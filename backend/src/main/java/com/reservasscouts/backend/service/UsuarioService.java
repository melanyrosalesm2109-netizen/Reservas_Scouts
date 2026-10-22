package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.LoginRequest;
import com.reservasscouts.backend.dto.LoginResponse;
import com.reservasscouts.backend.dto.UsuarioRequest;

import com.reservasscouts.backend.model.Rol;
import com.reservasscouts.backend.model.Usuario;
import com.reservasscouts.backend.model.UsuarioLogin;

import com.reservasscouts.backend.repository.UsuarioRepository;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;

@Service
public class UsuarioService {

    private final UsuarioRepository repository;

    @Value("${spring.datasource.url}")
    private String jdbcUrl;

    private final BCryptPasswordEncoder passwordEncoder =
            new BCryptPasswordEncoder();


    public UsuarioService(
            UsuarioRepository repository
    ) {
        this.repository = repository;
    }


    // =====================================================
    // LISTAR / FILTRAR USUARIOS
    // =====================================================

    public List<Usuario> filtrar(
            String email,
            Integer rolId,
            String estado
    ) {

        return repository.filtrar(
                email,
                rolId,
                estado
        );
    }


    // =====================================================
    // BUSCAR USUARIO POR ID
    // =====================================================

    public Usuario buscarPorId(
            Integer id
    ) {

        return repository.buscarPorId(id);
    }


    // =====================================================
    // INSERTAR USUARIO
    // =====================================================

    public Usuario insertar(
            UsuarioRequest request
    ) {

        if (
                request.password() == null ||
                request.password().isBlank()
        ) {

            throw new IllegalArgumentException(
                    "La contraseña es obligatoria."
            );
        }


        if (
                request.password().length() < 6
        ) {

            throw new IllegalArgumentException(
                    "La contraseña debe tener al menos 6 caracteres."
            );
        }


        String hash =
                passwordEncoder.encode(
                        request.password()
                );


        return repository.insertar(
                request.rolId(),
                request.email().trim(),
                hash,
                request.estado()
        );
    }


    // =====================================================
    // ACTUALIZAR USUARIO
    // =====================================================

    public Usuario actualizar(
            Integer id,
            UsuarioRequest request
    ) {

        String hash = null;


        /*
         * Si la contraseña viene vacía,
         * se conserva la contraseña anterior.
         */
        if (
                request.password() != null &&
                !request.password().isBlank()
        ) {

            if (
                    request.password().length() < 6
            ) {

                throw new IllegalArgumentException(
                        "La contraseña debe tener al menos 6 caracteres."
                );
            }


            hash =
                    passwordEncoder.encode(
                            request.password()
                    );
        }


        return repository.actualizar(
                id,
                request.rolId(),
                request.email().trim(),
                hash,
                request.estado()
        );
    }


    // =====================================================
    // ELIMINAR USUARIO
    // =====================================================

    public void eliminar(
            Integer id
    ) {

        repository.eliminar(id);
    }


    // =====================================================
    // LISTAR ROLES
    // =====================================================

    public List<Rol> listarRoles() {

        return repository.listarRoles();
    }


    // =====================================================
    // LOGIN
    // =====================================================

    public LoginResponse login(
            LoginRequest request
    ) {

        String identificador =
                request.email().trim();


        /*
         * Si se utiliza uno de los usuarios reales
         * creados en el motor SQL Server,
         * validamos sus credenciales directamente
         * contra SQL Server.
         */
        if (
                "reservas_app".equalsIgnoreCase(identificador) ||
                "reservas_consulta".equalsIgnoreCase(identificador)
        ) {

            return loginBaseDatos(
                    identificador,
                    request.password()
            );
        }


        /*
         * Se conserva el login anterior para no romper
         * las cuentas existentes de dbo.usuarios.
         */
        UsuarioLogin usuario =
                repository.buscarParaLogin(
                        identificador
                );


        /*
         * Si el usuario o correo no existe,
         * no permitimos el acceso.
         */
        if (usuario == null) {

            throw new IllegalArgumentException(
                    "Usuario o contraseña incorrectos."
            );
        }


        /*
         * Solo usuarios activos
         * pueden iniciar sesión.
         */
        if (
                !"ACTIVO".equalsIgnoreCase(
                        usuario.estado()
                )
        ) {

            throw new IllegalArgumentException(
                    "El usuario se encuentra inactivo."
            );
        }


        /*
         * Para las cuentas tradicionales
         * se mantiene la validación con BCrypt.
         */
        boolean passwordCorrecto =
                passwordEncoder.matches(
                        request.password(),
                        usuario.passwordHash()
                );


        if (!passwordCorrecto) {

            throw new IllegalArgumentException(
                    "Usuario o contraseña incorrectos."
            );
        }


        return new LoginResponse(
                usuario.id(),
                usuario.email(),
                usuario.rolId(),
                usuario.rol()
        );
    }


    // =====================================================
    // LOGIN CON USUARIO DEL MOTOR SQL SERVER
    // =====================================================

    private LoginResponse loginBaseDatos(
            String usuarioBd,
            String password
    ) {

        /*
         * Intentamos abrir una conexión real
         * a SQL Server utilizando las credenciales
         * ingresadas en el login.
         */
        try (
                Connection connection =
                        DriverManager.getConnection(
                                jdbcUrl,
                                usuarioBd,
                                password
                        )
        ) {


            /*
             * Si llegamos hasta aquí,
             * SQL Server aceptó las credenciales.
             *
             * Asociamos el usuario de BD con una
             * cuenta existente de la aplicación
             * para reutilizar los roles y permisos.
             *
             * reservas_app
             *      -> Administrador
             *
             * reservas_consulta
             *      -> Usuario restringido
             */
            String emailAplicacion;


            if (
                    "reservas_app".equalsIgnoreCase(
                            usuarioBd
                    )
            ) {

                emailAplicacion =
                        "admin@reservasscouts.test";

            } else {

                emailAplicacion =
                        "usuario@reservasscouts.test";
            }


            /*
             * Buscamos la cuenta asociada
             * para obtener su id y rol.
             */
            UsuarioLogin usuario =
                    repository.buscarParaLogin(
                            emailAplicacion
                    );


            if (usuario == null) {

                throw new IllegalArgumentException(
                        "No existe una cuenta de aplicación asociada."
                );
            }


            if (
                    !"ACTIVO".equalsIgnoreCase(
                            usuario.estado()
                    )
            ) {

                throw new IllegalArgumentException(
                        "La cuenta asociada se encuentra inactiva."
                );
            }


            /*
             * Importante:
             *
             * En lugar de devolver el correo asociado,
             * devolvemos el usuario real de SQL Server.
             *
             * Así en la interfaz aparecerá:
             *
             * reservas_app
             * o
             * reservas_consulta
             */
            return new LoginResponse(
                    usuario.id(),
                    usuarioBd,
                    usuario.rolId(),
                    usuario.rol()
            );


        } catch (SQLException ex) {

            throw new IllegalArgumentException(
                    "Usuario o contraseña de base de datos incorrectos."
            );
        }
    }
}