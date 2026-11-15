package com.reservasscouts.backend.service;

import com.reservasscouts.backend.controller.NotificacionController;
import com.reservasscouts.backend.dto.ReservaRequest;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@EnabledIfEnvironmentVariable(named="RESERVAS_SQL_TEST",matches="true")
class NotificacionesRevisionConcurrenteTest {
    @Autowired ReservaPagoService checkout;
    @Autowired PagoService pagos;
    @Autowired ReservaService reservas;
    @Autowired NotificacionController notificaciones;

    @Test void dosRevisoresNoPuedenProcesarElMismoPago() throws Exception {
        int usuario=Integer.parseInt(System.getenv("RESERVAS_SQL_USUARIO"));
        int perfil=Integer.parseInt(System.getenv("RESERVAS_SQL_PERFIL"));
        int espacio=Integer.parseInt(System.getenv("RESERVAS_SQL_ESPACIO"));
        var inicio=LocalDate.now(ZoneId.of("America/Costa_Rica")).plusDays(320).atTime(8,0);
        var bloqueo=checkout.bloquear(usuario,espacio,inicio,inicio.plusHours(2));
        UUID token=UUID.fromString((String)bloqueo.get("token"));
        Integer reservaId=null,pagoId=null;
        try {
            var solicitud=new ReservaRequest("IT-NOTIF-"+UUID.randomUUID().toString().substring(0,8),espacio,perfil,null,null,
                    "Prueba temporal","00000000","prueba@example.com",1,"Revision concurrente",inicio,inicio.plusHours(2),"PENDIENTE",null);
            var archivo=new MockMultipartFile("comprobante","demo.pdf","application/pdf","%PDF-1.4 demo".getBytes());
            var reserva=checkout.confirmar(new ReservaPagoService.DatosPago(solicitud,token,"Transferencia bancaria",null),archivo,usuario,"Usuario");
            reservaId=reserva.id();
            pagoId=pagos.filtrar(reservaId,null,null,null,null,null).get(0).id();
            int pago=pagoId;
            var inicioSimultaneo=new CountDownLatch(1);
            try(var pool=Executors.newFixedThreadPool(2)) {
                var resultados=new ArrayList<Future<Boolean>>();
                for(int revisor:List.of(1,7)) resultados.add(pool.submit(()-> {
                    inicioSimultaneo.await();
                    try { checkout.verificar(pago,true,revisor,null); return true; }
                    catch(org.springframework.dao.DataAccessException ex) {
                        assertInstanceOf(java.sql.SQLException.class,ex.getMostSpecificCause());
                        assertEquals(51017,((java.sql.SQLException)ex.getMostSpecificCause()).getErrorCode());
                        return false;
                    }
                }));
                inicioSimultaneo.countDown();
                int aprobados=0;
                for(var resultado:resultados) if(resultado.get(20,TimeUnit.SECONDS)) aprobados++;
                assertEquals(1,aprobados);
            }
            assertEquals("PAGADO",pagos.buscarPorId(pago).estado());
            assertEquals("APROBADA",reservas.buscarPorId(reservaId).estado());
            var avisos=notificaciones.listar().stream().filter(n->Objects.equals(n.pagoId(),pago)).toList();
            assertEquals(1,avisos.size());
            assertNotNull(avisos.get(0).revisadoPor());
            assertNotNull(avisos.get(0).revisadaEn());
        } finally {
            if(pagoId!=null) pagos.eliminar(pagoId);
            if(reservaId!=null) reservas.eliminar(reservaId);
            checkout.liberar(token,usuario);
        }
    }
}
