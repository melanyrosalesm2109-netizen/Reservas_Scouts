package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.repository.ReservaRepository;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

// Prueba optativa sobre SQL Server local. La transacción revierte la reserva y auditoría.
@SpringBootTest
@Transactional
@EnabledIfEnvironmentVariable(named = "RESERVAS_SQL_TEST", matches = "true")
class ReservaSqlServerTest {
    @Autowired ReservaController controller;
    @Autowired ReservaRepository repository;

    @Test
    void consultaDisponibilidadGuardaYRecuperaLaReserva() {
        int usuario = Integer.parseInt(System.getenv("RESERVAS_SQL_USUARIO"));
        int perfil = Integer.parseInt(System.getenv("RESERVAS_SQL_PERFIL"));
        int espacio = Integer.parseInt(System.getenv("RESERVAS_SQL_ESPACIO"));
        var inicio = LocalDate.now(ZoneId.of("America/Costa_Rica")).plusDays(90).atTime(8, 0);
        int intentos = 0;
        while (!repository.consultarDisponibilidad(espacio, inicio, inicio.plusHours(2)) && intentos++ < 30) {
            inicio = inicio.plusDays(1);
        }
        assertTrue(repository.consultarDisponibilidad(espacio, inicio, inicio.plusHours(2)));
        MockHttpSession session = new MockHttpSession();
        session.setAttribute("usuarioId", usuario);
        session.setAttribute("usuarioRol", "Administrador");
        var request = new ReservaRequest("IT-" + UUID.randomUUID().toString().substring(0, 12),
                espacio, perfil, null, null, "Prueba temporal", "00000000", "prueba@example.com",
                1, "Verificacion temporal", inicio, inicio.plusHours(2), "PENDIENTE", "Se revierte al finalizar la prueba");
        var reserva = controller.insertar(request, session);
        assertNotNull(reserva.id());
        assertEquals(usuario, reserva.creadoPorUsuarioId());
        assertEquals(request.codigo(), repository.buscarPorId(reserva.id()).codigo());
        assertFalse(repository.consultarDisponibilidad(espacio, inicio, inicio.plusHours(2)));
    }
}
