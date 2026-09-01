package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.PagoRequest;
import com.reservasscouts.backend.model.Pago;
import com.reservasscouts.backend.service.PagoService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/pagos")
@CrossOrigin(origins = "http://localhost:5173")
public class PagoController {

    private final PagoService service;

    public PagoController(
            PagoService service
    ) {
        this.service = service;
    }

    @GetMapping
    public List<Pago> filtrar(

            @RequestParam(required = false)
            Integer reservaId,

            @RequestParam(required = false)
            String codigoReserva,

            @RequestParam(required = false)
            String metodo,

            @RequestParam(required = false)
            String estado,

            @RequestParam(required = false)
            LocalDate fechaDesde,

            @RequestParam(required = false)
            LocalDate fechaHasta
    ) {

        return service.filtrar(
                reservaId,
                codigoReserva,
                metodo,
                estado,
                fechaDesde,
                fechaHasta
        );
    }

    @GetMapping("/{id}")
    public Pago buscarPorId(
            @PathVariable Integer id
    ) {

        return service.buscarPorId(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Pago insertar(
            @Valid
            @RequestBody PagoRequest request
    ) {

        return service.insertar(request);
    }

    @PutMapping("/{id}")
    public Pago actualizar(
            @PathVariable Integer id,

            @Valid
            @RequestBody PagoRequest request
    ) {

        return service.actualizar(
                id,
                request
        );
    }

    @DeleteMapping("/{id}")
    public Map<String, Object> eliminar(
            @PathVariable Integer id
    ) {

        service.eliminar(id);

        return Map.of(
                "ok", true,
                "mensaje",
                "Pago eliminado correctamente."
        );
    }
}