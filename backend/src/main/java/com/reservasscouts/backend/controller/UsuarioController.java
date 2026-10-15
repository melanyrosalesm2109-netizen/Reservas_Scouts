package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.LoginRequest;
import com.reservasscouts.backend.dto.LoginResponse;
import com.reservasscouts.backend.dto.UsuarioRequest;

import com.reservasscouts.backend.model.Rol;
import com.reservasscouts.backend.model.Usuario;

import com.reservasscouts.backend.service.UsuarioService;
import com.reservasscouts.backend.service.AuditoriaAccesoService;

import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService service;
    private final AuditoriaAccesoService auditoriaAcceso;

    public UsuarioController(
            UsuarioService service,
            AuditoriaAccesoService auditoriaAcceso
    ) {
        this.service = service;
        this.auditoriaAcceso = auditoriaAcceso;
    }

    // =====================================================
    // LOGIN
    // =====================================================

    @PostMapping("/login")
    public LoginResponse login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest
    ) {
        LoginResponse usuario;
        try {
            usuario = service.login(request);
        } catch (IllegalArgumentException ex) {
            auditoriaAcceso.registrar(
                    null,
                    "LOGIN_FALLIDO",
                    httpRequest.getRemoteAddr(),
                    httpRequest.getHeader("User-Agent")
            );
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Correo o contraseña incorrectos."
            );
        }

        auditoriaAcceso.registrar(
                usuario.id(),
                "LOGIN",
                httpRequest.getRemoteAddr(),
                httpRequest.getHeader("User-Agent")
        );
        HttpSession session = httpRequest.getSession(true);
        httpRequest.changeSessionId();
        session.setAttribute("usuarioId", usuario.id());
        session.setAttribute("usuarioEmail", usuario.email());
        session.setAttribute("usuarioRolId", usuario.rolId());
        session.setAttribute("usuarioRol", usuario.rol());
        return usuario;
    }

    @GetMapping("/sesion")
    public LoginResponse sesion(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("usuarioId") == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sesión no iniciada.");
        }

        return new LoginResponse(
                (Integer) session.getAttribute("usuarioId"),
                (String) session.getAttribute("usuarioEmail"),
                (Integer) session.getAttribute("usuarioRolId"),
                (String) session.getAttribute("usuarioRol")
        );
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cerrarSesion(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return;
        }

        Object usuarioId = session.getAttribute("usuarioId");
        if (usuarioId instanceof Integer id) {
            auditoriaAcceso.registrar(
                    id,
                    "LOGOUT",
                    request.getRemoteAddr(),
                    request.getHeader("User-Agent")
            );
        }
        session.invalidate();
    }

    // =====================================================
    // LISTAR / FILTRAR USUARIOS
    // =====================================================

    @GetMapping
    public List<Usuario> filtrar(

            @RequestParam(required = false)
            String email,

            @RequestParam(required = false)
            Integer rolId,

            @RequestParam(required = false)
            String estado

    ) {

        return service.filtrar(
                email,
                rolId,
                estado
        );
    }

    // =====================================================
    // LISTAR ROLES
    // =====================================================

    @GetMapping("/roles")
    public List<Rol> listarRoles() {

        return service.listarRoles();
    }

    // =====================================================
    // BUSCAR USUARIO POR ID
    // =====================================================

    @GetMapping("/{id}")
    public Usuario buscarPorId(
            @PathVariable Integer id
    ) {

        return service.buscarPorId(id);
    }

    // =====================================================
    // INSERTAR USUARIO
    // =====================================================

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Usuario insertar(

            @Valid
            @RequestBody UsuarioRequest request

    ) {

        return service.insertar(request);
    }

    // =====================================================
    // ACTUALIZAR USUARIO
    // =====================================================

    @PutMapping("/{id}")
    public Usuario actualizar(

            @PathVariable Integer id,

            @Valid
            @RequestBody UsuarioRequest request

    ) {

        return service.actualizar(
                id,
                request
        );
    }

    // =====================================================
    // ELIMINAR USUARIO
    // =====================================================

    @DeleteMapping("/{id}")
    public Map<String, Object> eliminar(
            @PathVariable Integer id
    ) {

        service.eliminar(id);

        return Map.of(
                "ok",
                true,

                "mensaje",
                "Usuario eliminado correctamente."
        );
    }
}