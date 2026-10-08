package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.model.Reserva;
import com.reservasscouts.backend.model.ReservaResumen;
import com.reservasscouts.backend.service.ReservaService;
import com.reservasscouts.backend.service.PerfilService;

import jakarta.validation.Valid;
import jakarta.servlet.http.HttpSession;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@RestController
@RequestMapping("/api/reservas")
public class ReservaController {

    private final ReservaService service;
    private final PerfilService perfilService;

    public ReservaController(
            ReservaService service,
            PerfilService perfilService
    ) {
        this.service = service;
        this.perfilService = perfilService;
    }

    // LISTAR / FILTRAR
    @GetMapping
    public List<ReservaResumen> filtrar(

            @RequestParam(required = false)
            String codigo,

            @RequestParam(required = false)
            String responsable,

            @RequestParam(required = false)
            String estado,

            @RequestParam(required = false)
            Integer espacioId,

            @RequestParam(required = false)
            Integer solicitantePerfilId,

            @RequestParam(required = false)
            LocalDate fechaDesde,

            @RequestParam(required = false)
            LocalDate fechaHasta,
            HttpSession session
    ) {

        String rol = (String) session.getAttribute("usuarioRol");
        Integer usuarioId = (Integer) session.getAttribute("usuarioId");
        Integer creadorId = "Usuario".equalsIgnoreCase(rol)
                || "Miembro".equalsIgnoreCase(rol)
                ? usuarioId
                : null;

        return service.filtrar(
                codigo,
                responsable,
                estado,
                espacioId,
                solicitantePerfilId,
                fechaDesde,
                fechaHasta,
                creadorId
        );
    }

    // BUSCAR POR ID
    @GetMapping("/{id}")
    public Reserva buscarPorId(
            @PathVariable Integer id
    ) {

        return service.buscarPorId(id);
    }

    // INSERTAR
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Reserva insertar(
            @Valid
            @RequestBody ReservaRequest request,
            HttpSession session
    ) {
        Integer usuarioId = (Integer) session.getAttribute("usuarioId");
        String rol = (String) session.getAttribute("usuarioRol");
        if ("Usuario".equalsIgnoreCase(rol) || "Miembro".equalsIgnoreCase(rol)) {
            var perfil = perfilService.buscarPorId(request.solicitantePerfilId());
            if (perfil == null || !Objects.equals(perfil.usuarioId(), usuarioId)) {
                throw new ResponseStatusException(
                        HttpStatus.FORBIDDEN,
                        "Solo puede reservar usando su propio perfil."
                );
            }
        }

        return service.insertar(
                request.conCreador(usuarioId)
        );
    }

    // ACTUALIZAR
    @PutMapping("/{id}")
    public Reserva actualizar(
            @PathVariable Integer id,

            @Valid
            @RequestBody ReservaRequest request
    ) {

        return service.actualizar(
                id,
                request
        );
    }

    // ELIMINAR
    @DeleteMapping("/{id}")
    public Map<String, Object> eliminar(
            @PathVariable Integer id
    ) {

        service.eliminar(id);

        return Map.of(
                "ok", true,
                "mensaje",
                "Reserva eliminada correctamente."
        );
    }
}