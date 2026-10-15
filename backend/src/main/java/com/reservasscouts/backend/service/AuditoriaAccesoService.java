package com.reservasscouts.backend.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AuditoriaAccesoService {

    private final JdbcTemplate jdbcTemplate;

    public AuditoriaAccesoService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void registrar(
            Integer usuarioId,
            String evento,
            String direccionIp,
            String agenteUsuario
    ) {
        jdbcTemplate.update(
                "EXEC dbo.paAuditoriaAccesoRegistrar ?, ?, ?, ?",
                usuarioId,
                evento,
                direccionIp,
                agenteUsuario
        );
    }
}
