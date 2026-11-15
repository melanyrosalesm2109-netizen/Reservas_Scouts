package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.PerfilRequest;
import com.reservasscouts.backend.service.PerfilService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpSession;
import static org.mockito.Mockito.*;

class PerfilPropioTest {
    @Test
    void usaElUsuarioDeLaSesionYUnPerfilPersonal() {
        PerfilService service = mock(PerfilService.class);
        when(service.filtrar(null, null, null, null, 7)).thenReturn(List.of());
        PerfilController controller = new PerfilController(service, mock(JdbcTemplate.class));
        MockHttpSession session = new MockHttpSession();
        session.setAttribute("usuarioId", 7);
        controller.completarPerfilPropio(new PerfilRequest(999, "Persona", "123", "88881111",
                "persona@example.com", "Grupo Scout", "Direccion"), session);
        verify(service).insertar(new PerfilRequest(7, "Persona", null, "88881111",
                "persona@example.com", "Persona", null));
    }
}
