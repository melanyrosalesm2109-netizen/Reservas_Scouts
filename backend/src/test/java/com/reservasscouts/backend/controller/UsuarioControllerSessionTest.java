package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.LoginRequest;
import com.reservasscouts.backend.dto.LoginResponse;
import com.reservasscouts.backend.service.AuditoriaAccesoService;
import com.reservasscouts.backend.service.UsuarioService;
import jakarta.servlet.http.HttpSession;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UsuarioControllerSessionTest {

    private final UsuarioService usuarioService = mock(UsuarioService.class);
    private final AuditoriaAccesoService auditoriaAcceso = mock(AuditoriaAccesoService.class);
    private final UsuarioController controller =
            new UsuarioController(usuarioService, auditoriaAcceso);

    @Test
    void loginGuardaIdentidadYRolEnLaSesionDelServidor() {
        LoginRequest request = new LoginRequest("admin@example.com", "password");
        LoginResponse usuario = new LoginResponse(7, "admin@example.com", 1, "Administrador");
        MockHttpServletRequest httpRequest = new MockHttpServletRequest();
        when(usuarioService.login(request)).thenReturn(usuario);

        LoginResponse respuesta = controller.login(request, httpRequest);
        HttpSession session = httpRequest.getSession(false);

        assertThat(respuesta).isEqualTo(usuario);
        assertThat(session.getAttribute("usuarioId")).isEqualTo(7);
        assertThat(session.getAttribute("usuarioEmail")).isEqualTo("admin@example.com");
        assertThat(session.getAttribute("usuarioRol")).isEqualTo("Administrador");
        verify(auditoriaAcceso).registrar(7, "LOGIN", "127.0.0.1", null);
    }

    @Test
    void rechazaCredencialesInvalidasYRegistraIntentoFallido() {
        LoginRequest request = new LoginRequest("alguien@example.com", "incorrecta");
        MockHttpServletRequest httpRequest = new MockHttpServletRequest();
        when(usuarioService.login(request))
                .thenThrow(new IllegalArgumentException("Correo o contraseña incorrectos."));

        assertThatThrownBy(() -> controller.login(request, httpRequest))
                .isInstanceOf(ResponseStatusException.class)
                .extracting("statusCode")
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(httpRequest.getSession(false)).isNull();
        verify(auditoriaAcceso).registrar(null, "LOGIN_FALLIDO", "127.0.0.1", null);
    }

    @Test
    void cerrarSesionInvalidaLaSesionYRegistraElEvento() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.getSession(true).setAttribute("usuarioId", 9);

        controller.cerrarSesion(request);

        assertThat(request.getSession(false)).isNull();
        verify(auditoriaAcceso).registrar(9, "LOGOUT", "127.0.0.1", null);
    }
}
