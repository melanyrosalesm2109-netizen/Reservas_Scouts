package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.PagoRequest;
import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.model.Reserva;
import com.reservasscouts.backend.model.ReservaFechaOcupada;
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

@Service
public class ReservaPagoService {
    private final JdbcTemplate jdbc;
    private final ReservaService reservas;
    private final PerfilService perfiles;
    private final EspacioService espacios;
    private final PagoService pagos;
    private final AuditoriaContextoService auditoria;
    public ReservaPagoService(JdbcTemplate jdbc, ReservaService reservas, PerfilService perfiles,
            EspacioService espacios, PagoService pagos, AuditoriaContextoService auditoria) {
        this.jdbc=jdbc; this.reservas=reservas; this.perfiles=perfiles;
        this.espacios=espacios; this.pagos=pagos; this.auditoria=auditoria;
    }

    public Map<String,Object> bloquear(int usuario, int espacio, LocalDateTime inicio, LocalDateTime fin) {
        var resultado=jdbc.queryForMap("EXEC dbo.paBloqueoCrear ?,?,?,?",usuario,espacio,Timestamp.valueOf(inicio),Timestamp.valueOf(fin));
        return Map.of("token",resultado.get("token"),"vence",((Timestamp)resultado.get("vence")).toLocalDateTime().toInstant(ZoneOffset.UTC).toString(),
                "ahora",((Timestamp)resultado.get("ahora")).toLocalDateTime().toInstant(ZoneOffset.UTC).toString());
    }
    public void liberar(UUID token, int usuario) { jdbc.update("EXEC dbo.paBloqueoLiberar ?,?",token.toString(),usuario); }
    public List<ReservaFechaOcupada> bloqueadas(int usuario) {
        return jdbc.query("EXEC dbo.paBloqueoListar ?",(rs,n)->new ReservaFechaOcupada(rs.getInt("espacioId"),
                rs.getTimestamp("fechaInicio").toLocalDateTime(),rs.getTimestamp("fechaFin").toLocalDateTime()),usuario);
    }

    public record Tarjeta(String numero, String titular, String vencimiento, String cvv) {
        @Override public String toString() { return "Tarjeta[datos de simulacion ocultos]"; }
    }
    public record DatosPago(ReservaRequest reserva, UUID bloqueo, String metodo, Tarjeta tarjeta) {}

    @Transactional(rollbackFor=Exception.class)
    public Reserva confirmar(DatosPago datos, MultipartFile comprobante, int usuario, String rol) throws Exception {
        if (datos.bloqueo()==null || datos.reserva()==null) throw new IllegalArgumentException("Selecciona nuevamente las fechas para iniciar tu reserva.");
        var r=datos.reserva();
        var perfil=perfiles.buscarPorId(r.solicitantePerfilId());
        if (perfil==null || (("Usuario".equalsIgnoreCase(rol)||"Miembro".equalsIgnoreCase(rol)) && !Objects.equals(perfil.usuarioId(),usuario)))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Solo puede reservar con su propio perfil.");
        String metodo=datos.metodo();
        if (!Set.of("SINPE Móvil","Transferencia bancaria","Efectivo","Tarjeta").contains(metodo==null?"":metodo))
            throw new IllegalArgumentException("Selecciona un método de pago.");
        boolean transferencia=metodo.equals("SINPE Móvil")||metodo.equals("Transferencia bancaria");
        byte[] archivo=null;
        String tipo=null;
        if (transferencia) {
            if (comprobante==null || comprobante.isEmpty() || comprobante.getSize()>5*1024*1024)
                throw new IllegalArgumentException("Adjunta un comprobante PDF, PNG o JPG de hasta 5 MB.");
            archivo=comprobante.getBytes(); tipo=tipoArchivo(archivo);
        }
        boolean tarjeta=metodo.equals("Tarjeta");
        if (tarjeta) validarTarjeta(datos.tarjeta());
        jdbc.update("EXEC dbo.paBloqueoValidar ?,?,?,?,?",datos.bloqueo().toString(),usuario,r.espacioId(),
                Timestamp.valueOf(r.fechaInicio()),Timestamp.valueOf(r.fechaFin()));
        var espacio=espacios.buscarPorId(r.espacioId());
        String estado=tarjeta?"APROBADA":"PENDIENTE";
        var segura=new ReservaRequest(r.codigo(),r.espacioId(),r.solicitantePerfilId(),usuario,r.grupo(),r.responsable(),
                r.telefono(),r.email(),r.participantes(),r.tipoActividad(),r.fechaInicio(),r.fechaFin(),estado,r.observaciones());
        var reserva=reservas.insertar(segura);
        LocalDate hoy=LocalDate.now(ZoneId.of("America/Costa_Rica"));
        String notas=tarjeta?"Pago simulado aprobado. Sin cobro real.":transferencia?"Comprobante pendiente de revisión.":"Pago en efectivo al llegar.";
        var pago=pagos.insertar(new PagoRequest(reserva.id(),espacio.costo(),metodo,
                metodo.equals("Efectivo")?r.fechaInicio().toLocalDate():hoy,tarjeta?"PAGADO":"PENDIENTE",
                transferencia?"Comprobante adjunto":null,notas));
        if (archivo!=null) {
            byte[] contenido=archivo;
            String mediaTipo=tipo;
            auditoria.ejecutar(()-> { jdbc.update("EXEC dbo.paComprobanteGuardar ?,?,?,?",pago.id(),"comprobante."+(mediaTipo.equals("application/pdf")?"pdf":mediaTipo.equals("image/png")?"png":"jpg"),mediaTipo,contenido); });
        }
        liberar(datos.bloqueo(),usuario);
        return reserva;
    }

    static String tipoArchivo(byte[] b) {
        if(b.length>=5 && b[0]=='%' && b[1]=='P' && b[2]=='D' && b[3]=='F' && b[4]=='-') return "application/pdf";
        if(b.length>=8 && (b[0]&255)==137 && b[1]==80 && b[2]==78 && b[3]==71 && b[4]==13 && b[5]==10 && b[6]==26 && b[7]==10) return "image/png";
        if(b.length>=3 && (b[0]&255)==255 && (b[1]&255)==216 && (b[2]&255)==255) return "image/jpeg";
        throw new IllegalArgumentException("El comprobante debe ser un archivo PDF, PNG o JPG válido.");
    }
    static void validarTarjeta(Tarjeta tarjeta) {
        if(tarjeta==null || tarjeta.numero()==null || tarjeta.titular()==null || tarjeta.titular().isBlank()
                || tarjeta.titular().length()>100 || !"4242424242424242".equals(tarjeta.numero().replace(" ","")) || !"123".equals(tarjeta.cvv()))
            throw new IllegalArgumentException("Pago simulado rechazado. Usa la tarjeta de prueba 4242 4242 4242 4242 y código 123.");
        try {
            if(YearMonth.parse(tarjeta.vencimiento()).isBefore(YearMonth.now(ZoneId.of("America/Costa_Rica")))) throw new IllegalArgumentException();
        } catch(Exception ex) { throw new IllegalArgumentException("Indica un vencimiento vigente para la tarjeta de prueba."); }
    }
    @Transactional
    public void verificar(int pago, boolean aprobar, int usuario, String motivo) {
        auditoria.ejecutar(()-> { jdbc.update("EXEC dbo.paPagoVerificar ?,?,?,?",pago,aprobar,usuario,motivo); });
    }
    public record Archivo(String nombre,String tipo,byte[] contenido) {}
    @Transactional(rollbackFor=Exception.class)
    public void adjuntarComprobante(int pago, MultipartFile archivo) throws Exception {
        if (archivo == null || archivo.isEmpty() || archivo.getSize() > 5 * 1024 * 1024)
            throw new IllegalArgumentException("Adjunta un comprobante PDF, PNG o JPG de hasta 5 MB.");
        byte[] contenido = archivo.getBytes();
        String tipo = tipoArchivo(contenido);
        String extension = tipo.equals("application/pdf") ? "pdf" : tipo.equals("image/png") ? "png" : "jpg";
        auditoria.ejecutar(() -> { jdbc.update("EXEC dbo.paComprobanteAdjuntar ?,?,?,?", pago,
                "comprobante-pago-" + pago + "." + extension, tipo, contenido); });
    }
    public Archivo comprobante(int pago) {
        var lista=jdbc.query("EXEC dbo.paComprobanteLeer ?",(rs,n)->new Archivo(rs.getString("nombre"),rs.getString("tipo"),rs.getBytes("contenido")),pago);
        if(lista.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Este pago no tiene comprobante adjunto.");
        return lista.get(0);
    }
}
