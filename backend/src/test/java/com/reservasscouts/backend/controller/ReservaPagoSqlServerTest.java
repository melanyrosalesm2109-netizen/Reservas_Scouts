package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.service.*;
import java.time.*;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
@EnabledIfEnvironmentVariable(named="RESERVAS_SQL_TEST",matches="true")
class ReservaPagoSqlServerTest {
    @Autowired ReservaPagoController controller;
    @Autowired ReservaPagoService checkout;
    @Autowired ReservaService reservas;
    @Autowired PagoService pagos;
    private int usuario() { return Integer.parseInt(System.getenv("RESERVAS_SQL_USUARIO")); }
    private int perfil() { return Integer.parseInt(System.getenv("RESERVAS_SQL_PERFIL")); }
    private int espacio() { return Integer.parseInt(System.getenv("RESERVAS_SQL_ESPACIO")); }
    private ReservaRequest solicitud(int dias) {
        var inicio=LocalDate.now(ZoneId.of("America/Costa_Rica")).plusDays(dias).atTime(8,0);
        return new ReservaRequest("IT-"+UUID.randomUUID().toString().substring(0,12),espacio(),perfil(),null,null,
                "Prueba temporal","00000000","prueba@example.com",1,"Verificacion",inicio,inicio.plusHours(2),"PENDIENTE",null);
    }
    private UUID apartar(ReservaRequest r) {
        return UUID.fromString((String)checkout.bloquear(usuario(),espacio(),r.fechaInicio(),r.fechaFin()).get("token"));
    }
    @Test void transferenciaRequiereRevisionYGuardaElArchivo() throws Exception {
        var r=solicitud(150); var token=apartar(r);
        var archivo=new MockMultipartFile("comprobante","demo.pdf","application/pdf","%PDF-1.4 demo".getBytes());
        var reserva=checkout.confirmar(new ReservaPagoService.DatosPago(r,token,"Transferencia bancaria",null),archivo,usuario(),"Usuario");
        assertEquals("PENDIENTE",reserva.estado());
        var pago=pagos.filtrar(reserva.id(),null,null,null,null,null).get(0);
        assertEquals("PENDIENTE",pago.estado());
        assertArrayEquals(archivo.getBytes(),checkout.comprobante(pago.id()).contenido());
        checkout.verificar(pago.id(),true,1,null);
        assertEquals("PAGADO",pagos.buscarPorId(pago.id()).estado());
        assertEquals("APROBADA",reservas.buscarPorId(reserva.id()).estado());
    }
    @Test void tarjetaApruebaYEfectivoQuedaPorCobrar() throws Exception {
        var r=solicitud(151);
        var tarjeta=new ReservaPagoService.Tarjeta("4242424242424242","Demo","2099-12","123");
        var reserva=checkout.confirmar(new ReservaPagoService.DatosPago(r,apartar(r),"Tarjeta",tarjeta),null,usuario(),"Usuario");
        assertEquals("APROBADA",reserva.estado());
        assertEquals("PAGADO",pagos.filtrar(reserva.id(),null,null,null,null,null).get(0).estado());
        r=solicitud(152);
        reserva=checkout.confirmar(new ReservaPagoService.DatosPago(r,apartar(r),"Efectivo",null),null,usuario(),"Usuario");
        var pago=pagos.filtrar(reserva.id(),null,null,null,null,null).get(0);
        assertEquals("APROBADA",reserva.estado());
        assertEquals("PENDIENTE",pago.estado());
        assertEquals(r.fechaInicio().toLocalDate(),pago.fechaPago());
    }
    @Test void pagoRechazadoLiberaLaReserva() throws Exception {
        var r=solicitud(153);
        var archivo=new MockMultipartFile("comprobante","demo.pdf","application/pdf","%PDF-1.4 demo".getBytes());
        var reserva=checkout.confirmar(new ReservaPagoService.DatosPago(r,apartar(r),"SINPE Móvil",null),archivo,usuario(),"Usuario");
        var pago=pagos.filtrar(reserva.id(),null,null,null,null,null).get(0);
        checkout.verificar(pago.id(),false,1,"Comprobante de prueba rechazado");
        assertEquals("CANCELADA",reservas.buscarPorId(reserva.id()).estado());
        assertEquals("RECHAZADO",pagos.buscarPorId(pago.id()).estado());
    }
    @Test void noPermiteConfirmarSinBloqueoVigente() {
        var r=solicitud(154);
        assertThrows(Exception.class,()->checkout.confirmar(new ReservaPagoService.DatosPago(r,UUID.randomUUID(),"Efectivo",null),null,usuario(),"Usuario"));
    }

    @Test void aceptaElFormularioMultipartDesdeHttp() throws Exception {
        var r=solicitud(155); var token=apartar(r);
        var json="""
                {"bloqueo":"%s","metodo":"Transferencia bancaria","reserva":{
                "codigo":"%s","espacioId":%d,"solicitantePerfilId":%d,
                "responsable":"Persona Demo","telefono":"00000000","email":"prueba@example.com",
                "participantes":1,"tipoActividad":"Prueba HTTP","fechaInicio":"%s","fechaFin":"%s","estado":"PENDIENTE"}}
                """.formatted(token,r.codigo(),espacio(),perfil(),r.fechaInicio(),r.fechaFin());
        var datos=new MockMultipartFile("datos","","application/json",json.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        var archivo=new MockMultipartFile("comprobante","demo.pdf","application/pdf","%PDF-1.4 demo".getBytes());
        var session=new org.springframework.mock.web.MockHttpSession();
        session.setAttribute("usuarioId",usuario()); session.setAttribute("usuarioRol","Usuario");
        var mvc=org.springframework.test.web.servlet.setup.MockMvcBuilders.standaloneSetup(controller).build();
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart("/api/reservas/confirmar")
                .file(datos).file(archivo).session(session))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isCreated())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$.estado").value("PENDIENTE"));
    }
}
