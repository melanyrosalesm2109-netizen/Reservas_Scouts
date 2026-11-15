package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.repository.ReservaRepository;
import java.time.LocalDate;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ReservaServiceFechaTest {
    private final ReservaRepository repository = mock(ReservaRepository.class);
    private final AuditoriaContextoService auditoria = mock(AuditoriaContextoService.class);
    private final ReservaService service = new ReservaService(repository, auditoria);

    private ReservaRequest solicitud(LocalDate fecha) {
        return new ReservaRequest("FECHA-TEST", 1, 1, 1, "Demo", "Responsable", "00000000",
                "demo@example.com", 5, "Reunion", fecha.atTime(8, 0), fecha.atTime(17, 0),
                "PENDIENTE", null);
    }

    @Test
    void rechazaFechasAnterioresSinEscribirDatos() {
        LocalDate ayer = LocalDate.now(ZoneId.of("America/Costa_Rica")).minusDays(1);
        assertThrows(IllegalArgumentException.class, () -> service.insertar(solicitud(ayer)));
        assertThrows(IllegalArgumentException.class, () -> service.actualizar(1, solicitud(ayer)));
        verifyNoInteractions(repository, auditoria);
    }

    @Test
    void permiteHoyYFechasFuturas() {
        LocalDate hoy = LocalDate.now(ZoneId.of("America/Costa_Rica"));
        assertDoesNotThrow(() -> service.insertar(solicitud(hoy)));
        assertDoesNotThrow(() -> service.insertar(solicitud(hoy.plusDays(1))));
    }
}
