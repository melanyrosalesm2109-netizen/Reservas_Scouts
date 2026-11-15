package com.reservasscouts.backend.controller;

import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notificaciones")
public class NotificacionController {
    private final JdbcTemplate jdbc;
    public NotificacionController(JdbcTemplate jdbc) { this.jdbc=jdbc; }
    public record Notificacion(int reservaId,int espacioId,String codigo,String solicitante,String espacio,String responsable,
            int participantes,LocalDateTime fechaInicio,LocalDateTime fechaFin,String reservaEstado,
            LocalDateTime reservaCreadaEn,Integer pagoId,BigDecimal monto,String metodo,String pagoEstado,
            LocalDate fechaPago,boolean tieneComprobante,Instant revisadaEn,String motivo,String revisadoPor) {}
    @GetMapping
    public List<Notificacion> listar() {
        return jdbc.query("EXEC dbo.paNotificacionesListar",(rs,n)->new Notificacion(
                rs.getInt("reservaId"),rs.getInt("espacioId"),rs.getString("codigo"),rs.getString("solicitante"),rs.getString("espacio"),
                rs.getString("responsable"),rs.getInt("participantes"),rs.getTimestamp("fechaInicio").toLocalDateTime(),
                rs.getTimestamp("fechaFin").toLocalDateTime(),rs.getString("reservaEstado"),
                rs.getTimestamp("reservaCreadaEn").toLocalDateTime(),rs.getObject("pagoId",Integer.class),
                rs.getBigDecimal("monto"),rs.getString("metodo"),rs.getString("pagoEstado"),
                rs.getDate("fechaPago")==null?null:rs.getDate("fechaPago").toLocalDate(),rs.getBoolean("tieneComprobante"),
                rs.getTimestamp("revisadaEn")==null?null:rs.getTimestamp("revisadaEn").toLocalDateTime().toInstant(ZoneOffset.UTC),
                rs.getString("motivo"),rs.getString("revisadoPor")));
    }
}
