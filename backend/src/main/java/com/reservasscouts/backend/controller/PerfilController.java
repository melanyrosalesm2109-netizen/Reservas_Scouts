package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.PerfilRequest;
import com.reservasscouts.backend.model.Perfil;
import org.springframework.jdbc.core.JdbcTemplate;
import com.reservasscouts.backend.service.PerfilService;

import jakarta.validation.Valid;
import jakarta.servlet.http.HttpSession;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.sql.Types;

@RestController
@RequestMapping("/api/perfiles")
public class PerfilController {

    private final PerfilService service;
    private final JdbcTemplate jdbcTemplate;

    public PerfilController(PerfilService service, JdbcTemplate jdbcTemplate) {
        this.service = service;
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/opciones-reserva")
    public List<PerfilOpcionReserva> listarOpcionesReserva(HttpSession session) {
        String rol = (String) session.getAttribute("usuarioRol");
        Integer usuarioId = "Usuario".equalsIgnoreCase(rol)
                || "Miembro".equalsIgnoreCase(rol)
                ? (Integer) session.getAttribute("usuarioId")
                : null;

        return jdbcTemplate.query(
                "{call dbo.paPerfilOpcionesReserva(?)}",
                statement -> {
                    if (usuarioId == null) {
                        statement.setNull(1, Types.INTEGER);
                    } else {
                        statement.setInt(1, usuarioId);
                    }
                },
                (rs, rowNum) -> new PerfilOpcionReserva(
                        rs.getInt("idPerfil"),
                        rs.getString("nombre"),
                        rs.getString("tipoPerfil")
                )
        );
    }

    @GetMapping
    public List<Perfil> filtrar(
            @RequestParam(required = false) String nombre,
            @RequestParam(required = false) String identificacion,
            @RequestParam(required = false) String correoContacto,
            @RequestParam(required = false) String tipoPerfil,
            @RequestParam(required = false) Integer usuarioId
    ) {

        return service.filtrar(
                nombre,
                identificacion,
                correoContacto,
                tipoPerfil,
                usuarioId
        );
    }

    @GetMapping("/{idPerfil}")
    public Perfil buscarPorId(
            @PathVariable Integer idPerfil
    ) {
        return service.buscarPorId(idPerfil);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Perfil insertar(
            @Valid @RequestBody PerfilRequest request
    ) {
        return service.insertar(request);
    }

    @PutMapping("/{idPerfil}")
    public Perfil actualizar(
            @PathVariable Integer idPerfil,
            @Valid @RequestBody PerfilRequest request
    ) {
        return service.actualizar(
                idPerfil,
                request
        );
    }

    @DeleteMapping("/{idPerfil}")
    public Map<String, Object> eliminar(
            @PathVariable Integer idPerfil
    ) {

        service.eliminar(idPerfil);

        return Map.of(
                "ok", true,
                "mensaje", "Perfil eliminado correctamente."
        );
    }
}