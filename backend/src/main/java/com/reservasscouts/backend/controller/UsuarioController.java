package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.LoginRequest;
import com.reservasscouts.backend.dto.LoginResponse;
import com.reservasscouts.backend.dto.UsuarioRequest;

import com.reservasscouts.backend.model.Rol;
import com.reservasscouts.backend.model.Usuario;

import com.reservasscouts.backend.service.UsuarioService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/usuarios")
@CrossOrigin(origins = "http://localhost:5173")
public class UsuarioController {

    private final UsuarioService service;

    public UsuarioController(
            UsuarioService service
    ) {
        this.service = service;
    }

    // =====================================================
    // LOGIN
    // =====================================================

    @PostMapping("/login")
    public LoginResponse login(
            @Valid
            @RequestBody LoginRequest request
    ) {

        return service.login(request);
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