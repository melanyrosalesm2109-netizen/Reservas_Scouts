package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.*;
import com.reservasscouts.backend.controller.ReservaArchivoController;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
@EnabledIfEnvironmentVariable(named="RESERVAS_SQL_TEST",matches="true")
class ReservaArchivoSqlServerTest {
    @Autowired ReservaService reservas;
    @Autowired PagoService pagos;
    @Autowired ReservaPagoService checkout;
    @Autowired ReservaArchivoController archivos;
    @Autowired JdbcTemplate jdbc;

    private int crear(int dias) {
        var inicio=LocalDate.now(ZoneId.of("America/Costa_Rica")).plusDays(dias).atTime(8,0);
        return reservas.insertar(new ReservaRequest("IT-ARC-"+UUID.randomUUID().toString().substring(0,8),
            Integer.parseInt(System.getenv("RESERVAS_SQL_ESPACIO")),Integer.parseInt(System.getenv("RESERVAS_SQL_PERFIL")),
            Integer.parseInt(System.getenv("RESERVAS_SQL_USUARIO")),null,"Prueba archivo","00000000","prueba@example.com",1,
            "Prueba transaccional",inicio,inicio.plusHours(2),"PENDIENTE",null)).id();
    }

    @Test void eliminaConPagosYConservaArchivoRevisionYAutorDeAuditoria() throws Exception {
        var request=new MockHttpServletRequest();
        request.getSession().setAttribute("usuarioId",1);
        request.getSession().setAttribute("usuarioEmail","revision-archivo@example.com");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        try {
            int indice=0;
            for(String metodo:List.of("SINPE Móvil","Transferencia bancaria")) {
                for(String estado:List.of("PENDIENTE","PAGADO","RECHAZADO","ANULADO")) {
                    int reserva=crear(1200+indice++);
                    var pago=pagos.insertar(new PagoRequest(reserva,new java.math.BigDecimal("1000"),metodo,LocalDate.now(),"PENDIENTE",null,null));
                    byte[] contenido=("%PDF-1.4 prueba unica "+pago.id()).getBytes(java.nio.charset.StandardCharsets.UTF_8);
                    checkout.adjuntarComprobante(pago.id(),new MockMultipartFile("comprobante","ejemplo.pdf","application/pdf",contenido));
                    if(!estado.equals("PENDIENTE")) checkout.verificar(pago.id(),!estado.equals("RECHAZADO"),1,estado.equals("RECHAZADO")?"Monto incorrecto de prueba":null);
                    if(estado.equals("ANULADO")) {
                        jdbc.update("EXEC dbo.paPagoAnular ?,?,?",pago.id(),1,"Anulacion de prueba");
                    }
                    reservas.eliminar(reserva);
                    assertTrue(reservas.filtrar(null,null,null,null,null,null,null,null).stream().noneMatch(r -> r.id()==reserva));
                    var archivo=archivos.archivo(reserva);
                    String historial=(String)archivo.get("pagosJson");
                    assertTrue(historial.contains(estado));
                    assertTrue(historial.contains(metodo));
                    if(estado.equals("RECHAZADO")) assertTrue(historial.contains("\"comprobanteCorrecto\":false"));
                    if(estado.equals("PAGADO") || estado.equals("ANULADO")) assertTrue(historial.contains("\"comprobanteCorrecto\":true"));
                    assertEquals("revision-archivo@example.com",archivo.get("eliminadaPor"));
                    assertArrayEquals(contenido,checkout.comprobante(pago.id()).contenido());
                    assertTrue(jdbc.queryForList("EXEC dbo.paAuditoriaDetalle").stream().anyMatch(e ->
                        "reservas".equals(e.get("origen")) && "DELETE".equals(e.get("evento")) && Integer.valueOf(reserva).equals(e.get("registroId"))));
                }
            }
        } finally { RequestContextHolder.resetRequestAttributes(); }
    }

    @Test void eliminaReservaSinPagosYGuardaLaCopia() {
        int reserva=crear(1250);
        reservas.eliminar(reserva);
        assertEquals("[]",archivos.archivo(reserva).get("pagosJson"));
    }

    @Test void noSustituyeElComprobanteOriginal() throws Exception {
        int reserva=crear(1251);
        var pago=pagos.insertar(new PagoRequest(reserva,new java.math.BigDecimal("1000"),"SINPE Móvil",LocalDate.now(),"PENDIENTE",null,null));
        var file=new MockMultipartFile("comprobante","original.pdf","application/pdf","%PDF-1.4 original".getBytes());
        checkout.adjuntarComprobante(pago.id(),file);
        assertThrows(Exception.class,()->checkout.adjuntarComprobante(pago.id(),file));
    }
}
