package com.reservasscouts.backend.service;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.*;

@Configuration
@EnableScheduling
@ConditionalOnProperty(name="app.reservas.vencimiento-activo",havingValue="true",matchIfMissing=true)
public class VencimientoReservaService {
    private final JdbcTemplate jdbc;
    public VencimientoReservaService(JdbcTemplate jdbc) { this.jdbc=jdbc; }
    @Scheduled(fixedDelayString="${app.reservas.vencimiento-intervalo-ms:60000}",initialDelay=60000)
    public void vencer() {
        try { jdbc.execute("EXEC dbo.paReservasVencerPendientes"); }
        catch(org.springframework.dao.DataAccessException ex) {
            org.slf4j.LoggerFactory.getLogger(getClass()).error("No se pudieron procesar los vencimientos de reservas; se reintentara.",ex);
        }
    }
}
