package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.ReservaRequest;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
@EnabledIfEnvironmentVariable(named="RESERVAS_VENCIMIENTO_TEST",matches="true")
class ReservaVencimientoSqlServerTest {
 @Autowired ReservaService reservas;
 @Autowired PagoService pagos;
 @Autowired CobroService cobros;
 @Autowired ReservaPagoService checkout;
 @Autowired JdbcTemplate jdbc;
 private int espacio() { return Integer.parseInt(System.getenv("RESERVAS_SQL_ESPACIO")); }
 private ReservaRequest solicitud(int dias,String estado) {
  var inicio=LocalDate.now(ZoneId.of("America/Costa_Rica")).plusDays(dias).atTime(8,0);
  return new ReservaRequest("IT-VENCE-"+UUID.randomUUID().toString().substring(0,7),espacio(),Integer.parseInt(System.getenv("RESERVAS_SQL_PERFIL")),
   Integer.parseInt(System.getenv("RESERVAS_SQL_USUARIO")),null,"Prueba plazo","00000000","prueba@example.com",1,"Prueba transaccional",inicio,inicio.plusHours(4),estado,null);
 }
 @Test void efectivoGuardaCupoSinAprobarYElCobroLoAprueba() throws Exception {
  var request=solicitud(1800,"PENDIENTE");
  var reserva=reservas.insertar(request);
  var pago=cobros.registrar(new CobroService.Solicitud(reserva.id(),"Efectivo",null),null);
  assertEquals("PENDIENTE",reservas.buscarPorId(reserva.id()).estado());
  assertEquals("PENDIENTE",pago.estado());
  assertFalse(reservas.consultarDisponibilidad(espacio(),request.fechaInicio(),request.fechaFin()));
  var resumen=reservas.filtrar(request.codigo(),null,null,null,null,null,null,null).getFirst();
  assertEquals(request.fechaInicio().plusHours(2),resumen.pagoVenceEn());
  assertEquals("Efectivo",resumen.metodoPagoPendiente());
  checkout.verificar(pago.id(),true,1,null);
  assertEquals("APROBADA",reservas.buscarPorId(reserva.id()).estado());
  assertEquals("PAGADO",pagos.buscarPorId(pago.id()).estado());
  assertEquals(LocalDate.now(ZoneId.of("America/Costa_Rica")),pagos.buscarPorId(pago.id()).fechaPago());
  assertNull(cobros.detalle(pago.id()).get("pagoVenceEn"));
  assertNotNull(cobros.detalle(pago.id()).get("revisadoPor"));
 }
 @Test void vencerLiberaCupoConservaPagoYRegistraElProcesoAutomatico() throws Exception {
  var request=solicitud(1801,"PENDIENTE");
  var reserva=reservas.insertar(request);
  var pago=cobros.registrar(new CobroService.Solicitud(reserva.id(),"Efectivo",null),null);
  jdbc.update("EXEC dbo.paReservaPlazoPrueba ?",reserva.id());
  assertTrue(reservas.consultarDisponibilidad(espacio(),request.fechaInicio(),request.fechaFin()));
  assertEquals("VENCIDA",reservas.buscarPorId(reserva.id()).estado());
  assertEquals("VENCIDO",pagos.buscarPorId(pago.id()).estado());
  assertEquals(1,reservas.filtrar(request.codigo(),null,"VENCIDA",null,null,null,null,null).size());
  assertEquals(1,pagos.filtrar(reserva.id(),null,null,"VENCIDO",null,null).size());
  var eventos=jdbc.queryForList("EXEC dbo.paAuditoriaDetalle");
  assertTrue(eventos.stream().anyMatch(e->"reservas".equals(e.get("origen")) && reserva.id().equals(e.get("registroId")) && "Sistema: vencimiento de reservas".equals(e.get("usuario")) && e.get("valoresNuevos").toString().contains("VENCIDA")));
  int antes=eventos.size();
  jdbc.execute("EXEC dbo.paReservasVencerPendientes");
  assertEquals(antes,jdbc.queryForList("EXEC dbo.paAuditoriaDetalle").size());
  assertThrows(Exception.class,()->checkout.verificar(pago.id(),true,1,null));
 }
 @Test void unComprobanteEnviadoNoVencePorDemoraDelRevisor() throws Exception {
  var request=solicitud(1802,"PENDIENTE");
  var reserva=reservas.insertar(request);
  var pago=cobros.registrar(new CobroService.Solicitud(reserva.id(),"Transferencia bancaria",null),new MockMultipartFile("comprobante","prueba.pdf","application/pdf","%PDF-1.4 demo".getBytes()));
  assertNull(cobros.detalle(pago.id()).get("pagoVenceEn"));
  jdbc.execute("EXEC dbo.paReservasVencerPendientes");
  assertEquals("PENDIENTE",reservas.buscarPorId(reserva.id()).estado());
  assertFalse(reservas.consultarDisponibilidad(espacio(),request.fechaInicio(),request.fechaFin()));
  checkout.verificar(pago.id(),true,1,null);
  assertEquals("APROBADA",reservas.buscarPorId(reserva.id()).estado());
 }
 @Test void editarReservaNoPermiteSaltarLaConfirmacionDelEfectivo() throws Exception {
  var request=solicitud(1803,"PENDIENTE");
  var reserva=reservas.insertar(request);
  cobros.registrar(new CobroService.Solicitud(reserva.id(),"Efectivo",null),null);
  var editar=new ReservaRequest(request.codigo(),request.espacioId(),request.solicitantePerfilId(),request.creadoPorUsuarioId(),null,request.responsable(),request.telefono(),request.email(),request.participantes(),request.tipoActividad(),request.fechaInicio(),request.fechaFin(),"APROBADA",null);
  assertThrows(Exception.class,()->reservas.actualizar(reserva.id(),editar));
 }
 @Test void adjuntarLaTransferenciaDentroDelPlazoDetieneElVencimiento() throws Exception {
  var request=solicitud(1804,"PENDIENTE");
  var reserva=reservas.insertar(request);
  var pago=pagos.insertar(new com.reservasscouts.backend.dto.PagoRequest(reserva.id(),new java.math.BigDecimal("1000"),"SINPE Móvil",LocalDate.now(),"PENDIENTE",null,null));
  assertNotNull(cobros.detalle(pago.id()).get("pagoVenceEn"));
  checkout.adjuntarComprobante(pago.id(),new MockMultipartFile("comprobante","prueba.pdf","application/pdf","%PDF-1.4 demo".getBytes()));
  assertNull(cobros.detalle(pago.id()).get("pagoVenceEn"));
  assertEquals("PENDIENTE",reservas.buscarPorId(reserva.id()).estado());
 }
}
