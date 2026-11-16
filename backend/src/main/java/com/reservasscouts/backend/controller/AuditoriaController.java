package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.model.AuditoriaDetalle;
import com.reservasscouts.backend.model.AuditoriaResumen;
import java.sql.Timestamp;
import java.util.*;
import org.springframework.jdbc.core.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auditoria")
public class AuditoriaController {
 private final JdbcTemplate jdbc;
 public AuditoriaController(JdbcTemplate jdbc) { this.jdbc=jdbc; }
 @GetMapping("/resumen")
 public List<AuditoriaResumen> obtenerResumen() {
  RowMapper<AuditoriaResumen> mapper=(rs,n)-> {
   Timestamp fecha=rs.getTimestamp("ultimoEvento");
   return new AuditoriaResumen(rs.getString("origen"),rs.getString("evento"),rs.getLong("totalEventos"),fecha==null?null:fecha.toLocalDateTime());
  };
  var resumen=new ArrayList<>(auditoriaLocal("EXEC dbo.paAuditoriaResumen",mapper));
  resumen.addAll(jdbc.query("EXEC master.dbo.paReservasOperacionesResumen",mapper));
  return resumen;
 }
 @GetMapping("/detalle")
 public List<AuditoriaDetalle> obtenerDetalle() {
  RowMapper<AuditoriaDetalle> mapper=(rs,n)-> {
   Timestamp fecha=rs.getTimestamp("creadoEn");
   return new AuditoriaDetalle(rs.getLong("idAuditoria"),rs.getString("origen"),rs.getString("evento"),
    rs.getObject("registroId",Integer.class),rs.getString("usuario"),rs.getString("usuarioBd"),rs.getString("detalle"),
    rs.getString("valoresAnteriores"),rs.getString("valoresNuevos"),fecha==null?null:fecha.toLocalDateTime());
  };
  var eventos=new ArrayList<>(auditoriaLocal("EXEC dbo.paAuditoriaDetalle",mapper));
  eventos.addAll(jdbc.query("EXEC master.dbo.paReservasOperacionesAuditoria",mapper));
  eventos.sort(Comparator.comparing(AuditoriaDetalle::creadoEn,Comparator.nullsLast(Comparator.reverseOrder())));
  return eventos.stream().limit(500).toList();
 }
 private <T> List<T> auditoriaLocal(String sql,RowMapper<T> mapper) {
  try { return jdbc.query(sql,mapper); }
  catch(org.springframework.dao.DataAccessException ex) {
   if(ex.getMostSpecificCause() instanceof java.sql.SQLException causa && causa.getErrorCode()==2812) {
    org.slf4j.LoggerFactory.getLogger(getClass()).warn("La copia recuperada no incluye el procedimiento local de auditoria; se conserva la bitacora externa.");
    return List.of();
   }
   throw ex;
  }
 }
}
