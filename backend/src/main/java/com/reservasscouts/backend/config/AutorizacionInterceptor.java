package com.reservasscouts.backend.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;

@Component
public class AutorizacionInterceptor
        implements HandlerInterceptor {

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler
    ) throws IOException {

        String method =
                request.getMethod();

        String path =
                request.getRequestURI();


        // =====================================================
        // RUTAS PÚBLICAS
        // =====================================================

        boolean registroPublico =
                HttpMethod.POST.matches(method)
                        && path.equals(
                                "/api/usuarios/registro"
                        );


        if (
                HttpMethod.OPTIONS.matches(method)
                        || !path.startsWith("/api/")
                        || path.equals("/api/prueba-db")
                        || path.equals("/api/usuarios/login")
                        || path.equals("/api/usuarios/sesion")
                        || path.equals("/api/usuarios/logout")
                        || registroPublico
        ) {

            return true;
        }


        // =====================================================
        // VALIDAR SESIÓN
        // =====================================================

        HttpSession session =
                request.getSession(false);


        Object usuarioId =
                session == null
                        ? null
                        : session.getAttribute(
                                "usuarioId"
                        );


        if (!(usuarioId instanceof Integer)) {

            responder(
                    response,
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Debe iniciar sesión."
            );

            return false;
        }


        // =====================================================
        // VALIDAR ORIGEN
        // =====================================================

        String origin =
                request.getHeader(
                        "Origin"
                );


        if (
                origin != null
                        && !origin.equals(
                                "http://localhost:5173"
                        )
                        && !origin.equals(
                                "http://127.0.0.1:5173"
                        )
                        && !origin.equals(
                                "https://reservas-scouts-basedatos.vercel.app"
                        )
        ) {

            responder(
                    response,
                    HttpServletResponse.SC_FORBIDDEN,
                    "Origen no permitido."
            );

            return false;
        }


        // =====================================================
        // ROL
        // =====================================================

        String rol =
                (String) session.getAttribute(
                        "usuarioRol"
                );


        // =====================================================
        // ADMINISTRADOR
        // =====================================================

        if (
                "Administrador"
                        .equalsIgnoreCase(
                                rol
                        )
        ) {

            request.setAttribute(
                    "usuarioId",
                    usuarioId
            );

            return true;
        }


        // =====================================================
        // RECEPCIONISTA
        // =====================================================

        boolean recepcionista =
                "Recepcionista"
                        .equalsIgnoreCase(
                                rol
                        );


        boolean metodoCrud =
                HttpMethod.GET.matches(method)
                        || HttpMethod.POST.matches(method)
                        || HttpMethod.PUT.matches(method)
                        || HttpMethod.DELETE.matches(method);


        boolean recursoGestionRecepcionista =
                path.equals(
                        "/api/reservas"
                )
                        || path.startsWith(
                                "/api/reservas/"
                        )
                        || path.equals(
                                "/api/pagos"
                        )
                        || path.startsWith(
                                "/api/pagos/"
                        );


        boolean recursoConsultaRecepcionista =
                path.equals(
                        "/api/espacios"
                )
                        || path.startsWith(
                                "/api/espacios/"
                        )
                        || path.equals(
                                "/api/perfiles"
                        )
                        || path.startsWith(
                                "/api/perfiles/"
                        );


        boolean accesoRecepcionista =
                recepcionista
                        && (
                        (
                                metodoCrud
                                        && recursoGestionRecepcionista
                        )
                                || (
                                HttpMethod.GET.matches(method)
                                        && recursoConsultaRecepcionista
                        )
                );


        // =====================================================
        // USUARIO / MIEMBRO
        // =====================================================

        boolean usuarioRegular =
                "Usuario"
                        .equalsIgnoreCase(
                                rol
                        )
                        || "Miembro"
                        .equalsIgnoreCase(
                                rol
                        );


        boolean consultaReservasPropias =
                HttpMethod.GET.matches(method)
                        && path.equals(
                                "/api/reservas"
                        );


        boolean consultaDisponibilidad =
                HttpMethod.GET.matches(method)
                        && path.equals(
                                "/api/reservas/disponibilidad"
                        );


        boolean consultaFechasOcupadas =
                HttpMethod.GET.matches(method)
                        && path.equals(
                                "/api/reservas/ocupadas"
                        );


        boolean consultaEspacios =
                HttpMethod.GET.matches(method)
                        && (
                        path.equals(
                                "/api/espacios"
                        )
                                || path.startsWith(
                                "/api/espacios/"
                        )
                );


        boolean consultaPerfilPropio =
                HttpMethod.GET.matches(method)
                        && path.equals(
                                "/api/perfiles/opciones-reserva"
                        );


        boolean crearReserva =
                HttpMethod.POST.matches(method)
                        && path.equals(
                                "/api/reservas"
                        );


        boolean accesoRegular =
                usuarioRegular
                        && (
                        consultaReservasPropias
                                || consultaDisponibilidad
                                || consultaFechasOcupadas
                                || consultaEspacios
                                || consultaPerfilPropio
                                || crearReserva
                );


        // =====================================================
        // PERMITIR
        // =====================================================

        if (
                accesoRecepcionista
                        || accesoRegular
        ) {

            request.setAttribute(
                    "usuarioId",
                    usuarioId
            );

            return true;
        }


        // =====================================================
        // BLOQUEAR
        // =====================================================

        responder(
                response,
                HttpServletResponse.SC_FORBIDDEN,
                "No tiene permisos para realizar esta operación."
        );

        return false;
    }


    // =====================================================
    // RESPUESTA JSON
    // =====================================================

    private void responder(
            HttpServletResponse response,
            int status,
            String mensaje
    ) throws IOException {

        response.setStatus(
                status
        );


        response.setContentType(
                "application/json"
        );


        response.setCharacterEncoding(
                "UTF-8"
        );


        response
                .getWriter()
                .write(
                        "{\"ok\":false,\"mensaje\":\""
                                + mensaje
                                + "\"}"
                );
    }
}