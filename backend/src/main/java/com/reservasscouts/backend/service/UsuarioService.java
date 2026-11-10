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
import org.springframework.transaction.annotation.Transactional;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;


@Service
public class UsuarioService {

    private final UsuarioRepository repository;

    private final AuditoriaContextoService auditoriaContexto;


    @Value("${spring.datasource.url}")
    private String jdbcUrl;


    private final BCryptPasswordEncoder passwordEncoder =
            new BCryptPasswordEncoder();


    public UsuarioService(
            UsuarioRepository repository,
            AuditoriaContextoService auditoriaContexto
    ) {

        this.repository = repository;

        this.auditoriaContexto =
                auditoriaContexto;
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

    @Transactional
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


        return auditoriaContexto.ejecutar(
                () -> repository.insertar(
                        request.rolId(),
                        request.email().trim(),
                        hash,
                        request.estado()
                )
        );
    }


    // =====================================================
    // ACTUALIZAR USUARIO
    // =====================================================

    @Transactional
    public Usuario actualizar(
            Integer id,
            UsuarioRequest request
    ) {

        final String hash;


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

        } else {

            hash = null;
        }


        return auditoriaContexto.ejecutar(
                () -> repository.actualizar(
                        id,
                        request.rolId(),
                        request.email().trim(),
                        hash,
                        request.estado()
                )
        );
    }


    // =====================================================
    // ELIMINAR USUARIO
    // =====================================================

    @Transactional
    public void eliminar(
            Integer id
    ) {

        auditoriaContexto.ejecutar(
                () -> repository.eliminar(id)
        );
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


        if (usuario == null) {

            throw new IllegalArgumentException(
                    "Usuario o contraseña incorrectos."
            );
        }


        if (
                !"ACTIVO".equalsIgnoreCase(
                        usuario.estado()
                )
        ) {

            throw new IllegalArgumentException(
                    "El usuario se encuentra inactivo."
            );
        }


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
             * Si SQL Server acepta las credenciales,
             * asociamos el usuario del motor con
             * una cuenta existente de la aplicación.
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
             * Mostramos en la interfaz el usuario
             * real utilizado para iniciar sesión
             * en SQL Server.
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