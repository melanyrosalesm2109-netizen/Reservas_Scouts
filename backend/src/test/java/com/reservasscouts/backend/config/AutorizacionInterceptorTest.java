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
    void usuarioPuedeConsultarYCrearReservasPeroNoAdministrarlas() throws Exception {
        MockHttpServletRequest consulta = request("GET", "/api/reservas");
        MockHttpServletRequest detalle = request("GET", "/api/reservas/10");
        MockHttpServletRequest creacion = request("POST", "/api/reservas");
        MockHttpServletRequest edicion = request("PUT", "/api/reservas/10");
        MockHttpServletResponse responseConsulta = new MockHttpServletResponse();
        MockHttpServletResponse responseDetalle = new MockHttpServletResponse();
        MockHttpServletResponse responseCreacion = new MockHttpServletResponse();
        MockHttpServletResponse responseEdicion = new MockHttpServletResponse();
        agregarSesion(consulta, "Usuario");
        agregarSesion(detalle, "Usuario");
        agregarSesion(creacion, "Usuario");
        agregarSesion(edicion, "Usuario");

        assertThat(interceptor.preHandle(consulta, responseConsulta, new Object())).isTrue();
        assertThat(interceptor.preHandle(detalle, responseDetalle, new Object())).isFalse();
        assertThat(responseDetalle.getStatus()).isEqualTo(HttpServletResponse.SC_FORBIDDEN);
        assertThat(interceptor.preHandle(creacion, responseCreacion, new Object())).isTrue();
        assertThat(interceptor.preHandle(edicion, responseEdicion, new Object())).isFalse();
        assertThat(responseEdicion.getStatus()).isEqualTo(HttpServletResponse.SC_FORBIDDEN);
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
}
