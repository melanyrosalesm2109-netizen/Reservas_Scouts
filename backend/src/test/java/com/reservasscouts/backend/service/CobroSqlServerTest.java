package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.ReservaRequest;
import java.time.*;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.mock.web.MockMultipartFile;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
@EnabledIfEnvironmentVariable(named="RESERVAS_SQL_TEST",matches="true")
class CobroSqlServerTest {
    @Autowired CobroService cobros;
    @Autowired ReservaService reservas;
    @Autowired PagoService pagos;
    @Autowired ReservaPagoService checkout;
    int crear(int dias) {
        int usuario=Integer.parseInt(System.getenv("RESERVAS_SQL_USUARIO"));
        int perfil=Integer.parseInt(System.getenv("RESERVAS_SQL_PERFIL"));
        int espacio=Integer.parseInt(System.getenv("RESERVAS_SQL_ESPACIO"));
        var inicio=LocalDate.now(ZoneId.of("America/Costa_Rica")).plusDays(dias).atTime(8,0);
        return reservas.insertar(new ReservaRequest("IT-COBRO-"+UUID.randomUUID().toString().substring(0,8),espacio,perfil,usuario,null,"Prueba temporal","00000000","prueba@example.com",1,"Prueba de saldo",inicio,inicio.plusHours(2),"PENDIENTE",null)).id();
    }
    @Test void anularConservaElRegistroYReabreElSaldo() throws Exception {
        int reserva=crear(410);
        assertTrue(cobros.disponibles().stream().anyMatch(r->r.reservaId()==reserva));
        var tarjeta=new ReservaPagoService.Tarjeta("4242424242424242","Persona Demo","2099-12","123");
        var pago=cobros.registrar(new CobroService.Solicitud(reserva,"Tarjeta",tarjeta),null);
        assertEquals("PAGADO",pago.estado());
        assertEquals(0,((java.math.BigDecimal)cobros.detalle(pago.id()).get("saldo")).signum());
        cobros.anular(pago.id(),1,"Correccion de prueba");
        assertEquals("ANULADO",pagos.buscarPorId(pago.id()).estado());
        var detalle=cobros.detalle(pago.id());
        assertEquals("Correccion de prueba",detalle.get("motivoAnulacion"));
        assertNotNull(detalle.get("anuladoPor"));
        assertNotNull(detalle.get("anuladaEn"));
        assertTrue(((java.math.BigDecimal)detalle.get("saldo")).signum()>0);
        assertTrue(cobros.disponibles().stream().anyMatch(r->r.reservaId()==reserva));
        assertEquals("PENDIENTE",reservas.buscarPorId(reserva).estado());
    }
    @Test void otroPagoPendienteImpideDuplicarElCobro() throws Exception {
        int reserva=crear(411);
        var pago=cobros.registrar(new CobroService.Solicitud(reserva,"Efectivo",null),null);
        assertEquals("PENDIENTE",pago.estado());
        assertFalse(cobros.disponibles().stream().anyMatch(r->r.reservaId()==reserva));
        assertThrows(org.springframework.dao.DataAccessException.class,()->cobros.registrar(new CobroService.Solicitud(reserva,"Efectivo",null),null));
    }
    @Test void unComprobanteSeConservaDespuesDeAnular() throws Exception {
        int reserva=crear(412);
        var archivo=new MockMultipartFile("comprobante","prueba.pdf","application/pdf","%PDF-1.4 demo".getBytes());
        var pago=cobros.registrar(new CobroService.Solicitud(reserva,"Transferencia bancaria",null),archivo);
        assertEquals("PENDIENTE",pago.estado());
        assertEquals(Boolean.TRUE,cobros.detalle(pago.id()).get("tieneComprobante"));
        checkout.verificar(pago.id(),true,1,null);
        cobros.anular(pago.id(),1,"Anulacion de prueba con historial");
        assertEquals("ANULADO",pagos.buscarPorId(pago.id()).estado());
        assertArrayEquals(archivo.getBytes(),checkout.comprobante(pago.id()).contenido());
        assertNotNull(cobros.detalle(pago.id()).get("revisadoPor"));
        assertNotNull(cobros.detalle(pago.id()).get("anuladoPor"));
    }
    @Test void recepcionNoPuedeAnularUnPagoAprobado() throws Exception {
        int reserva=crear(413);
        var tarjeta=new ReservaPagoService.Tarjeta("4242424242424242","Demo","2099-12","123");
        var pago=cobros.registrar(new CobroService.Solicitud(reserva,"Tarjeta",tarjeta),null);
        assertThrows(org.springframework.dao.DataAccessException.class,()->cobros.anular(pago.id(),7,"Recepcion no puede anular"));
    }
    @Test void administracionYRecepcionPuedenRegistrarEfectivoAntesDeLaLlegada() throws Exception {
        for(int revisor:new int[]{1,7}) {
            int reserva=crear(420+revisor);
            var pago=cobros.registrar(new CobroService.Solicitud(reserva,"Efectivo",null),null);
            assertEquals("PENDIENTE",pago.estado());
            checkout.verificar(pago.id(),true,revisor,null);
            var cobrado=pagos.buscarPorId(pago.id());
            assertEquals("PAGADO",cobrado.estado());
            assertEquals(LocalDate.now(ZoneId.of("America/Costa_Rica")),cobrado.fechaPago());
            assertNotNull(cobros.detalle(pago.id()).get("revisadoPor"));
            assertNotNull(cobros.detalle(pago.id()).get("revisadaEn"));
            assertEquals("APROBADA",reservas.buscarPorId(reserva).estado());
        }
    }
}
