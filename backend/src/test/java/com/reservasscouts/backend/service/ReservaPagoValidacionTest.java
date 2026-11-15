package com.reservasscouts.backend.service;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ReservaPagoValidacionTest {
    @Test void permiteSoloTarjetaDeSimulacionYNoExponeDatosEnTexto() {
        var tarjeta=new ReservaPagoService.Tarjeta("4242 4242 4242 4242","Persona Demo","2099-12","123");
        assertDoesNotThrow(()->ReservaPagoService.validarTarjeta(tarjeta));
        assertFalse(tarjeta.toString().contains("4242"));
        assertFalse(tarjeta.toString().contains("123"));
        assertThrows(IllegalArgumentException.class,()->ReservaPagoService.validarTarjeta(
                new ReservaPagoService.Tarjeta("4000000000000002","Demo","2099-12","123")));
        assertThrows(IllegalArgumentException.class,()->ReservaPagoService.validarTarjeta(
                new ReservaPagoService.Tarjeta("4242424242424242","Demo","2000-01","123")));
    }
    @Test void compruebaLaFirmaDelArchivo() {
        assertEquals("application/pdf",ReservaPagoService.tipoArchivo("%PDF-1.4".getBytes()));
        assertEquals("image/png",ReservaPagoService.tipoArchivo(new byte[]{(byte)137,80,78,71,13,10,26,10}));
        assertEquals("image/jpeg",ReservaPagoService.tipoArchivo(new byte[]{(byte)255,(byte)216,(byte)255}));
        assertThrows(IllegalArgumentException.class,()->ReservaPagoService.tipoArchivo("<script>".getBytes()));
    }
}
