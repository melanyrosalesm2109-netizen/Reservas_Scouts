package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.model.AuditoriaResumen;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/auditoria")
public class AuditoriaController {

    private final JdbcTemplate jdbcTemplate;

    public AuditoriaController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/resumen")
    public List<AuditoriaResumen> obtenerResumen() {
        return jdbcTemplate.query(
                "EXEC dbo.paAuditoriaResumen",
                (rs, rowNum) -> new AuditoriaResumen(
                        rs.getString("origen"),
                        rs.getString("evento"),
                        rs.getLong("totalEventos"),
                        rs.getTimestamp("ultimoEvento").toLocalDateTime()
                )
        );
    }
}
