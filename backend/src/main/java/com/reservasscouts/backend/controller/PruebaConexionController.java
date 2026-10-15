package com.reservasscouts.backend.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class PruebaConexionController {

    private final JdbcTemplate jdbcTemplate;

    public PruebaConexionController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/prueba-db")
    public Map<String, Object> pruebaConexion() {

        Map<String, Object> estado =
                jdbcTemplate.queryForMap("EXEC dbo.paSistemaEstado");

        return Map.of(
                "mensaje", "Conexion con SQL Server correcta",
                "baseDatos", estado.get("baseDatos"),
                "cantidadEspacios", estado.get("cantidadEspacios")
        );
    }
}