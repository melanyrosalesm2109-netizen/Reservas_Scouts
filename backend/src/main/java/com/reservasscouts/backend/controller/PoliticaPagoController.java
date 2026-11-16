package com.reservasscouts.backend.controller;

import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
public class PoliticaPagoController {
    private final JdbcTemplate jdbc;
    public PoliticaPagoController(JdbcTemplate jdbc) { this.jdbc=jdbc; }
    @GetMapping("/api/reservas/politica-pago")
    public Map<String,Object> politica() { return jdbc.queryForMap("EXEC dbo.paReservaPoliticaPago"); }
}
