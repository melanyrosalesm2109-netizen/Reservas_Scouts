package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.PagoRequest;
import com.reservasscouts.backend.model.Pago;
import java.math.BigDecimal;
import java.time.*;
import java.sql.Timestamp;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;

@Service
public class CobroService {
    private final JdbcTemplate jdbc;
    private final PagoService pagos;
    private final AuditoriaContextoService auditoria;
    public CobroService(JdbcTemplate jdbc,PagoService pagos,AuditoriaContextoService auditoria) {
        this.jdbc=jdbc;this.pagos=pagos;this.auditoria=auditoria;
    }
    public record Disponible(int reservaId,String codigo,String espacio,String solicitante,LocalDateTime fechaInicio,LocalDateTime fechaFin,BigDecimal costo,BigDecimal saldo) {}
    public List<Disponible> disponibles() {
        return jdbc.query("EXEC dbo.paCobrosDisponibles",(rs,n)->new Disponible(rs.getInt("reservaId"),rs.getString("codigo"),
                rs.getString("espacio"),rs.getString("solicitante"),rs.getTimestamp("fechaInicio").toLocalDateTime(),
                rs.getTimestamp("fechaFin").toLocalDateTime(),rs.getBigDecimal("costo"),rs.getBigDecimal("saldo")));
    }
    public record Solicitud(@NotNull @Min(1) Integer reservaId,String metodo,ReservaPagoService.Tarjeta tarjeta) {}
    @Transactional(rollbackFor=Exception.class)
    public Pago registrar(Solicitud solicitud,MultipartFile comprobante) throws Exception {
        String metodo=solicitud.metodo();
        if(!Set.of("Efectivo","Tarjeta","SINPE Móvil","Transferencia bancaria").contains(metodo==null?"":metodo))
            throw new IllegalArgumentException("Selecciona un metodo de pago.");
        boolean transferencia=metodo.equals("SINPE Móvil")||metodo.equals("Transferencia bancaria");
        byte[] archivo=null;String tipo=null;
        if(transferencia) {
            if(comprobante==null||comprobante.isEmpty()||comprobante.getSize()>5242880)
                throw new IllegalArgumentException("Adjunta un comprobante PDF, PNG o JPG de hasta 5 MB.");
            archivo=comprobante.getBytes();tipo=ReservaPagoService.tipoArchivo(archivo);
        }
        if(metodo.equals("Tarjeta")) ReservaPagoService.validarTarjeta(solicitud.tarjeta());
        var contexto=jdbc.queryForMap("EXEC dbo.paCobroContexto ?",solicitud.reservaId());
        BigDecimal saldo=(BigDecimal)contexto.get("saldo");
        LocalDate llegada=((Timestamp)contexto.get("fechaInicio")).toLocalDateTime().toLocalDate();
        LocalDate hoy=LocalDate.now(ZoneId.of("America/Costa_Rica"));
        boolean tarjeta=metodo.equals("Tarjeta");
        boolean efectivo=metodo.equals("Efectivo");
        // El efectivo se agenda pendiente y se confirma con el boton de cobro al recibirlo.
        var pago=pagos.insertar(new PagoRequest(solicitud.reservaId(),saldo,metodo,efectivo?llegada:hoy,
                tarjeta?"PAGADO":"PENDIENTE",transferencia?"Comprobante adjunto":null,
                tarjeta?"Pago simulado aprobado. Sin cobro real.":efectivo?"Pago en efectivo al llegar.":"Comprobante pendiente de revision."));
        if(archivo!=null) {
            byte[] contenido=archivo;
            String mediaTipo=tipo;
            auditoria.ejecutar(()-> { jdbc.update("EXEC dbo.paComprobanteGuardar ?,?,?,?",pago.id(),
                "comprobante."+(mediaTipo.equals("application/pdf")?"pdf":mediaTipo.equals("image/png")?"png":"jpg"),mediaTipo,contenido); });
        }
        boolean aprobar=tarjeta;
        auditoria.ejecutar(()-> { jdbc.update("EXEC dbo.paCobroEstadoReserva ?,?",solicitud.reservaId(),aprobar); });
        return pago;
    }
    public Map<String,Object> detalle(int id) {
        Pago pago=pagos.buscarPorId(id);
        if(pago==null) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"El pago no existe.");
        var lista=jdbc.query("EXEC dbo.paPagoDetalle ?",(rs,n)-> {
            Map<String,Object> datos=new LinkedHashMap<>();datos.put("pago",pago);
            datos.put("reservaEstado",rs.getString("reservaEstado"));datos.put("costo",rs.getBigDecimal("costo"));datos.put("saldo",rs.getBigDecimal("saldo"));
            datos.put("fechaInicio",rs.getTimestamp("fechaInicio").toLocalDateTime());datos.put("fechaFin",rs.getTimestamp("fechaFin").toLocalDateTime());
            datos.put("tieneComprobante",rs.getBoolean("tieneComprobante"));
            datos.put("comprobanteCorrecto",rs.getObject("comprobanteCorrecto"));
            var vence=rs.getTimestamp("pagoVenceEn");
            datos.put("pagoVenceEn",vence==null?null:vence.toLocalDateTime());
            for(String campo:List.of("revisadoPor","motivoRevision","anuladoPor","motivoAnulacion")) datos.put(campo,rs.getString(campo));
            for(String campo:List.of("revisadaEn","anuladaEn")) { var fecha=rs.getTimestamp(campo);datos.put(campo,fecha==null?null:fecha.toLocalDateTime().toInstant(ZoneOffset.UTC)); }
            return datos;
        },id);
        if(lista.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"El pago no existe.");
        return lista.get(0);
    }
    @Transactional
    public void anular(int id,int usuario,String motivo) {
        auditoria.ejecutar(()-> { jdbc.update("EXEC dbo.paPagoAnular ?,?,?",id,usuario,motivo); });
    }
}
