package com.reservasscouts.backend.service;

import jakarta.servlet.http.HttpSession;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.function.Supplier;

@Service
public class AuditoriaContextoService {

    private final JdbcTemplate jdbcTemplate;

    public AuditoriaContextoService(
            JdbcTemplate jdbcTemplate
    ) {
        this.jdbcTemplate = jdbcTemplate;
    }


    public <T> T ejecutar(
            Supplier<T> operacion
    ) {

        aplicarContexto();

        try {
            return operacion.get();
        } finally {
            limpiarContexto();
        }
    }


    public void ejecutar(
            Runnable operacion
    ) {

        aplicarContexto();

        try {
            operacion.run();
        } finally {
            limpiarContexto();
        }
    }


    private void aplicarContexto() {

        Integer usuarioId = null;
        String usuarioNombre = null;


        var atributos =
                RequestContextHolder
                        .getRequestAttributes();


        if (
                atributos instanceof
                        ServletRequestAttributes servlet
        ) {

            HttpSession session =
                    servlet
                            .getRequest()
                            .getSession(false);


            if (session != null) {

                Object id =
                        session.getAttribute(
                                "usuarioId"
                        );

                Object nombre =
                        session.getAttribute(
                                "usuarioEmail"
                        );


                if (id instanceof Integer) {
                    usuarioId = (Integer) id;
                }


                if (nombre instanceof String) {
                    usuarioNombre =
                            (String) nombre;
                }
            }
        }


        if (usuarioId != null) {

            jdbcTemplate.update(
                    """
                    EXEC sys.sp_set_session_context
                        @key = N'app_usuario_id',
                        @value = ?
                    """,
                    usuarioId
            );

        } else {

            jdbcTemplate.execute(
                    """
                    EXEC sys.sp_set_session_context
                        @key = N'app_usuario_id',
                        @value = NULL
                    """
            );
        }


        if (usuarioNombre != null) {

            jdbcTemplate.update(
                    """
                    EXEC sys.sp_set_session_context
                        @key = N'app_usuario_nombre',
                        @value = ?
                    """,
                    usuarioNombre
            );

        } else {

            jdbcTemplate.execute(
                    """
                    EXEC sys.sp_set_session_context
                        @key = N'app_usuario_nombre',
                        @value = NULL
                    """
            );
        }
    }


    private void limpiarContexto() {

        jdbcTemplate.execute(
                """
                EXEC sys.sp_set_session_context
                    @key = N'app_usuario_id',
                    @value = NULL;

                EXEC sys.sp_set_session_context
                    @key = N'app_usuario_nombre',
                    @value = NULL;
                """
        );
    }
}