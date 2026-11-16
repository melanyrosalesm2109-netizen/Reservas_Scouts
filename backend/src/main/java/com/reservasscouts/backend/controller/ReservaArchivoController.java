package com.reservasscouts.backend.controller;

import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/reservas")
public class ReservaArchivoController {
    private final JdbcTemplate jdbc;
    public ReservaArchivoController(JdbcTemplate jdbc) { this.jdbc=jdbc; }

    @GetMapping("/{id}/archivo")
    public Map<String,Object> archivo(@PathVariable int id) {
        var filas=jdbc.queryForList("EXEC dbo.paReservaArchivo ?",id);
        if(filas.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"No hay un archivo conservado para esta reserva.");
        return filas.get(0);
    }
}
