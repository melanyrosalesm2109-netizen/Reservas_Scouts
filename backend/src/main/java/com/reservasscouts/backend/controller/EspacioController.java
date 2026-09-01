package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.EspacioRequest;
import com.reservasscouts.backend.model.Espacio;
import com.reservasscouts.backend.service.EspacioService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
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

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/espacios")
@CrossOrigin(origins = "http://localhost:5173")
public class EspacioController {

    private final EspacioService service;

    public EspacioController(EspacioService service) {
        this.service = service;
    }

    // LISTAR Y FILTRAR ESPACIOS
    @GetMapping
    public List<Espacio> filtrar(
            @RequestParam(required = false) String nombre,
            @RequestParam(required = false) String ubicacion,
            @RequestParam(required = false) String estado,
            @RequestParam(required = false) Integer capacidadMinima,
            @RequestParam(required = false) BigDecimal costoMaximo
    ) {

        return service.filtrar(
                nombre,
                ubicacion,
                estado,
                capacidadMinima,
                costoMaximo
        );
    }

    // BUSCAR ESPACIO POR ID
    @GetMapping("/{id}")
    public Espacio buscarPorId(
            @PathVariable Integer id
    ) {

        return service.buscarPorId(id);
    }

    // INSERTAR ESPACIO
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Espacio insertar(
            @Valid
            @RequestBody EspacioRequest request
    ) {

        return service.insertar(request);
    }

    // ACTUALIZAR ESPACIO
    @PutMapping("/{id}")
    public Espacio actualizar(
            @PathVariable Integer id,
            @Valid
            @RequestBody EspacioRequest request
    ) {

        return service.actualizar(
                id,
                request
        );
    }

    // ELIMINAR ESPACIO
    @DeleteMapping("/{id}")
    public Map<String, Object> eliminar(
            @PathVariable Integer id
    ) {

        service.eliminar(id);

        return Map.of(
                "ok", true,
                "mensaje", "Espacio eliminado correctamente."
        );
    }
}