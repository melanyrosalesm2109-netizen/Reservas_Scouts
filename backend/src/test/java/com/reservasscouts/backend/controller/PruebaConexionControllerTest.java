package com.reservasscouts.backend.controller;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PruebaConexionControllerTest {

    @Test
    void obtieneElEstadoMedianteElProcedimientoAlmacenado() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        PruebaConexionController controller =
                new PruebaConexionController(jdbcTemplate);

        when(jdbcTemplate.queryForMap("EXEC dbo.paSistemaEstado"))
                .thenReturn(Map.of(
                        "baseDatos", "reservasScouts",
                        "cantidadEspacios", 4
                ));

        Map<String, Object> resultado = controller.pruebaConexion();

        assertThat(resultado)
                .containsEntry("mensaje", "Conexion con SQL Server correcta")
                .containsEntry("baseDatos", "reservasScouts")
                .containsEntry("cantidadEspacios", 4);
        verify(jdbcTemplate).queryForMap("EXEC dbo.paSistemaEstado");
    }
}
