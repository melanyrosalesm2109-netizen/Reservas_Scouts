package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.LoginRequest;
import com.reservasscouts.backend.dto.LoginResponse;
import com.reservasscouts.backend.dto.UsuarioRequest;

import com.reservasscouts.backend.model.Rol;
import com.reservasscouts.backend.model.Usuario;
import com.reservasscouts.backend.model.UsuarioLogin;

import com.reservasscouts.backend.repository.UsuarioRepository;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UsuarioService {

    private final UsuarioRepository repository;

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

        String email =
                request.email().trim();

        /*
         * Buscar usuario mediante
         * dbo.paUsuarioLogin
         */
        UsuarioLogin usuario =
                repository.buscarParaLogin(
                        email
                );

        /*
         * Si el correo no existe,
         * no dejamos entrar.
         */
        if (usuario == null) {

            throw new IllegalArgumentException(
                    "Correo o contraseña incorrectos."
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
         * BCrypt compara la contraseña
         * escrita con el hash guardado
         * en SQL Server.
         */
        boolean passwordCorrecto =
                passwordEncoder.matches(
                        request.password(),
                        usuario.passwordHash()
                );

        if (!passwordCorrecto) {

            throw new IllegalArgumentException(
                    "Correo o contraseña incorrectos."
            );
        }

        /*
         * Si todo está correcto,
         * devolvemos los datos necesarios
         * para la sesión del frontend.
         */
        return new LoginResponse(
                usuario.id(),
                usuario.email(),
                usuario.rolId(),
                usuario.rol()
        );
    }
}