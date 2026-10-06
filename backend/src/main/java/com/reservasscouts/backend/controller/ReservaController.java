package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.model.Reserva;
import com.reservasscouts.backend.model.ReservaResumen;
import com.reservasscouts.backend.service.ReservaService;

import jakarta.validation.Valid;
import jakarta.servlet.http.HttpSession;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reservas")
public class ReservaController {

    private final ReservaService service;

    public ReservaController(
            ReservaService service
    ) {
        this.service = service;
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
            LocalDate fechaHasta
    ) {

        return service.filtrar(
                codigo,
                responsable,
                estado,
                espacioId,
                solicitantePerfilId,
                fechaDesde,
                fechaHasta
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

        return service.insertar(
                request.conCreador((Integer) session.getAttribute("usuarioId"))
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