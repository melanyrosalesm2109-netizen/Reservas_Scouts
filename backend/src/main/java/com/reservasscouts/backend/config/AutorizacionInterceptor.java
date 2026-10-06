package com.reservasscouts.backend.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;

@Component
public class AutorizacionInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler
    ) throws IOException {
        if (HttpMethod.OPTIONS.matches(request.getMethod())
                || !request.getRequestURI().startsWith("/api/")
                || request.getRequestURI().equals("/api/prueba-db")
                || request.getRequestURI().equals("/api/usuarios/login")
                || request.getRequestURI().equals("/api/usuarios/sesion")
                || request.getRequestURI().equals("/api/usuarios/logout")) {
            return true;
        }

        HttpSession session = request.getSession(false);
        Object usuarioId = session == null ? null : session.getAttribute("usuarioId");
        if (!(usuarioId instanceof Integer)) {
            responder(response, HttpServletResponse.SC_UNAUTHORIZED, "Debe iniciar sesión.");
            return false;
        }

        String origin = request.getHeader("Origin");
        if (origin != null
                && !origin.equals("http://localhost:5173")
                && !origin.equals("http://127.0.0.1:5173")) {
            responder(response, HttpServletResponse.SC_FORBIDDEN, "Origen no permitido.");
            return false;
        }

        String rol = (String) session.getAttribute("usuarioRol");
        if ("Administrador".equalsIgnoreCase(rol)) {
            return true;
        }

        boolean lecturaPermitida = HttpMethod.GET.matches(request.getMethod())
                && (request.getRequestURI().equals("/api/reservas")
                || request.getRequestURI().startsWith("/api/espacios")
                || request.getRequestURI().equals("/api/perfiles/opciones-reserva"));
        boolean crearReservaPermitida = HttpMethod.POST.matches(request.getMethod())
                && request.getRequestURI().equals("/api/reservas");

        if (lecturaPermitida || crearReservaPermitida) {
            request.setAttribute("usuarioId", usuarioId);
            return true;
        }

        responder(response, HttpServletResponse.SC_FORBIDDEN, "No tiene permisos para realizar esta operación.");
        return false;
    }

    private void responder(
            HttpServletResponse response,
            int status,
            String mensaje
    ) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(
                "{\"ok\":false,\"mensaje\":\"" + mensaje + "\"}"
        );
    }
}
