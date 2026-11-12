package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.LoginRequest;
import com.reservasscouts.backend.dto.LoginResponse;
import com.reservasscouts.backend.dto.PerfilRequest;
import com.reservasscouts.backend.dto.RegistroUsuarioRequest;
import com.reservasscouts.backend.dto.UsuarioRequest;

import com.reservasscouts.backend.model.Rol;
import com.reservasscouts.backend.model.Usuario;
import com.reservasscouts.backend.model.UsuarioLogin;

import com.reservasscouts.backend.repository.PerfilRepository;
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

    private final PerfilRepository perfilRepository;

    private final AuditoriaContextoService auditoriaContexto;


    @Value("${spring.datasource.url}")
    private String jdbcUrl;


    private final BCryptPasswordEncoder passwordEncoder =
            new BCryptPasswordEncoder();


    public UsuarioService(
            UsuarioRepository repository,
            PerfilRepository perfilRepository,
            AuditoriaContextoService auditoriaContexto
    ) {

        this.repository = repository;

        this.perfilRepository =
                perfilRepository;

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

        return repository.buscarPorId(
                id
        );
    }


    // =====================================================
    // REGISTRO PÚBLICO
    // =====================================================

    @Transactional
    public Usuario registrar(
            RegistroUsuarioRequest request
    ) {

        String email =
                request.email()
                        .trim()
                        .toLowerCase();


        if (
                !request.password()
                        .equals(
                                request.confirmarPassword()
                        )
        ) {

            throw new IllegalArgumentException(
                    "Las contraseñas no coinciden."
            );
        }


        Rol rolUsuario =
                repository
                        .listarRoles()
                        .stream()
                        .filter(
                                rol ->
                                        "Usuario"
                                                .equalsIgnoreCase(
                                                        rol.nombre()
                                                )
                        )
                        .findFirst()
                        .orElseThrow(
                                () ->
                                        new IllegalStateException(
                                                "No existe el rol Usuario en el sistema."
                                        )
                        );


        String hash =
                passwordEncoder.encode(
                        request.password()
                );


        Usuario usuario =
                repository.insertar(
                        rolUsuario.id(),
                        email,
                        hash,
                        "ACTIVO"
                );


        PerfilRequest perfilRequest =
                new PerfilRequest(

                        usuario.id(),

                        request.nombre()
                                .trim(),

                        limpiarTexto(
                                request.identificacion()
                        ),

                        limpiarTexto(
                                request.telefono()
                        ),

                        email,

                        "Persona",

                        limpiarTexto(
                                request.direccion()
                        )
                );


        perfilRepository.insertar(
                perfilRequest
        );


        return usuario;
    }


    // =====================================================
    // INSERTAR USUARIO DESDE ADMINISTRACIÓN
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
                () ->
                        repository.insertar(

                                request.rolId(),

                                request.email()
                                        .trim(),

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
                () ->
                        repository.actualizar(

                                id,

                                request.rolId(),

                                request.email()
                                        .trim(),

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
                () ->
                        repository.eliminar(
                                id
                        )
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
                request.email()
                        .trim();


        if (
                "reservas_app"
                        .equalsIgnoreCase(
                                identificador
                        )
                        ||
                        "reservas_consulta"
                                .equalsIgnoreCase(
                                        identificador
                                )
        ) {

            return loginBaseDatos(
                    identificador,
                    request.password()
            );
        }


        UsuarioLogin usuario =
                repository.buscarParaLogin(
                        identificador
                );


        if (
                usuario == null
        ) {

            throw new IllegalArgumentException(
                    "Usuario o contraseña incorrectos."
            );
        }


        if (
                !"ACTIVO"
                        .equalsIgnoreCase(
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


        if (
                !passwordCorrecto
        ) {

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

        try (
                Connection connection =
                        DriverManager.getConnection(

                                jdbcUrl,

                                usuarioBd,

                                password
                        )
        ) {

            String emailAplicacion;


            if (
                    "reservas_app"
                            .equalsIgnoreCase(
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


            if (
                    usuario == null
            ) {

                throw new IllegalArgumentException(
                        "No existe una cuenta de aplicación asociada."
                );
            }


            if (
                    !"ACTIVO"
                            .equalsIgnoreCase(
                                    usuario.estado()
                            )
            ) {

                throw new IllegalArgumentException(
                        "La cuenta asociada se encuentra inactiva."
                );
            }


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


    // =====================================================
    // LIMPIAR CAMPOS OPCIONALES
    // =====================================================

    private String limpiarTexto(
            String valor
    ) {

        if (
                valor == null ||
                valor.isBlank()
        ) {

            return null;
        }


        return valor.trim();
    }
}