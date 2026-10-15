package com.reservasscouts.backend.config;

import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockHttpSession;

import static org.assertj.core.api.Assertions.assertThat;

class AutorizacionInterceptorTest {

    private final AutorizacionInterceptor interceptor = new AutorizacionInterceptor();

    @Test
    void rechazaSolicitudesSinSesion() throws Exception {
        MockHttpServletRequest request = request("GET", "/api/reservas");
        MockHttpServletResponse response = new MockHttpServletResponse();

        boolean permitida = interceptor.preHandle(request, response, new Object());

        assertThat(permitida).isFalse();
        assertThat(response.getStatus()).isEqualTo(HttpServletResponse.SC_UNAUTHORIZED);
    }

    @Test
    void usuarioYMiembroSoloPuedenConsultarListaYCrearReservas() throws Exception {
        for (String rol : new String[]{"Usuario", "Miembro"}) {
            MockHttpServletRequest consulta = request("GET", "/api/reservas");
            MockHttpServletRequest detalle = request("GET", "/api/reservas/10");
            MockHttpServletRequest creacion = request("POST", "/api/reservas");
            MockHttpServletRequest edicion = request("PUT", "/api/reservas/10");
            MockHttpServletRequest pagos = request("GET", "/api/pagos");
            MockHttpServletRequest perfiles = request("GET", "/api/perfiles");
            MockHttpServletRequest opcionesPerfil = request("GET", "/api/perfiles/opciones-reserva");
            MockHttpServletResponse responseConsulta = new MockHttpServletResponse();
            MockHttpServletResponse responseDetalle = new MockHttpServletResponse();
            MockHttpServletResponse responseCreacion = new MockHttpServletResponse();
            MockHttpServletResponse responseEdicion = new MockHttpServletResponse();
            MockHttpServletResponse responsePagos = new MockHttpServletResponse();
            MockHttpServletResponse responsePerfiles = new MockHttpServletResponse();
            MockHttpServletResponse responseOpcionesPerfil = new MockHttpServletResponse();
            agregarSesion(consulta, rol);
            agregarSesion(detalle, rol);
            agregarSesion(creacion, rol);
            agregarSesion(edicion, rol);
            agregarSesion(pagos, rol);
            agregarSesion(perfiles, rol);
            agregarSesion(opcionesPerfil, rol);

            assertThat(interceptor.preHandle(consulta, responseConsulta, new Object())).isTrue();
            assertThat(interceptor.preHandle(detalle, responseDetalle, new Object())).isFalse();
            assertThat(responseDetalle.getStatus()).isEqualTo(HttpServletResponse.SC_FORBIDDEN);
            assertThat(interceptor.preHandle(creacion, responseCreacion, new Object())).isTrue();
            assertThat(interceptor.preHandle(edicion, responseEdicion, new Object())).isFalse();
            assertThat(responseEdicion.getStatus()).isEqualTo(HttpServletResponse.SC_FORBIDDEN);
            assertThat(interceptor.preHandle(pagos, responsePagos, new Object())).isFalse();
            assertThat(interceptor.preHandle(perfiles, responsePerfiles, new Object())).isFalse();
            assertThat(interceptor.preHandle(opcionesPerfil, responseOpcionesPerfil, new Object())).isTrue();
            assertThat(permite("GET", "/api/espacios", rol)).isTrue();
            assertThat(permite("GET", "/api/espacios/3", rol)).isTrue();
            assertThat(permite("POST", "/api/espacios", rol)).isFalse();
        }
    }

    @Test
    void recepcionistaGestionaReservasYPagosPeroSoloConsultaEspaciosYPerfiles() throws Exception {
        assertThat(permite("GET", "/api/reservas", "Recepcionista")).isTrue();
        assertThat(permite("GET", "/api/reservas/10", "Recepcionista")).isTrue();
        assertThat(permite("POST", "/api/reservas", "Recepcionista")).isTrue();
        assertThat(permite("PUT", "/api/reservas/10", "Recepcionista")).isTrue();
        assertThat(permite("DELETE", "/api/reservas/10", "Recepcionista")).isTrue();
        assertThat(permite("GET", "/api/pagos", "Recepcionista")).isTrue();
        assertThat(permite("POST", "/api/pagos", "Recepcionista")).isTrue();
        assertThat(permite("PUT", "/api/pagos/4", "Recepcionista")).isTrue();
        assertThat(permite("DELETE", "/api/pagos/4", "Recepcionista")).isTrue();
        assertThat(permite("GET", "/api/espacios", "Recepcionista")).isTrue();
        assertThat(permite("GET", "/api/perfiles", "Recepcionista")).isTrue();
        assertThat(permite("POST", "/api/espacios", "Recepcionista")).isFalse();
        assertThat(permite("POST", "/api/perfiles", "Recepcionista")).isFalse();
        assertThat(permite("GET", "/api/usuarios", "Recepcionista")).isFalse();
        assertThat(permite("PATCH", "/api/pagos/4", "Recepcionista")).isFalse();
    }

    @Test
    void administradorPuedeAdministrarRecursos() throws Exception {
        MockHttpServletRequest request = request("DELETE", "/api/pagos/4");
        MockHttpServletResponse response = new MockHttpServletResponse();
        agregarSesion(request, "Administrador");

        assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
    }

    private MockHttpServletRequest request(String method, String uri) {
        MockHttpServletRequest request = new MockHttpServletRequest(method, uri);
        request.setRequestURI(uri);
        return request;
    }

    private void agregarSesion(MockHttpServletRequest request, String rol) {
        MockHttpSession session = new MockHttpSession();
        session.setAttribute("usuarioId", 12);
        session.setAttribute("usuarioRol", rol);
        request.setSession(session);
    }

    private boolean permite(String method, String uri, String rol) throws Exception {
        MockHttpServletRequest request = request(method, uri);
        MockHttpServletResponse response = new MockHttpServletResponse();
        agregarSesion(request, rol);
        return interceptor.preHandle(request, response, new Object());
    }
}
