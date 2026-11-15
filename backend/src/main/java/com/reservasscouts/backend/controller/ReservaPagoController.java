package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.service.ReservaPagoService;
import com.reservasscouts.backend.model.Reserva;
import com.reservasscouts.backend.model.ReservaFechaOcupada;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import jakarta.validation.Validator;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;
import java.util.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class ReservaPagoController {
    private final ReservaPagoService service;
    private final Validator validator;
    public ReservaPagoController(ReservaPagoService service, Validator validator) { this.service=service; this.validator=validator; }
    public record Bloqueo(@NotNull Integer espacioId,@NotNull LocalDateTime fechaInicio,@NotNull LocalDateTime fechaFin) {}
    @PostMapping("/api/reservas/bloqueos")
    public Map<String,Object> bloquear(@Valid @RequestBody Bloqueo datos,HttpSession session) {
        return service.bloquear((Integer)session.getAttribute("usuarioId"),datos.espacioId(),datos.fechaInicio(),datos.fechaFin());
    }
    @GetMapping("/api/reservas/bloqueos")
    public List<ReservaFechaOcupada> bloqueadas(HttpSession session) { return service.bloqueadas((Integer)session.getAttribute("usuarioId")); }
    @DeleteMapping("/api/reservas/bloqueos/{token}")
    public void liberar(@PathVariable UUID token,HttpSession session) { service.liberar(token,(Integer)session.getAttribute("usuarioId")); }
    @PostMapping(value="/api/reservas/confirmar",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Reserva confirmar(@RequestPart("datos") ReservaPagoService.DatosPago datos,
            @RequestPart(value="comprobante",required=false) MultipartFile comprobante,HttpSession session) throws Exception {
        if(datos.reserva()==null) throw new IllegalArgumentException("Faltan los datos de la reserva.");
        var errores=validator.validate(datos.reserva());
        if(!errores.isEmpty()) throw new IllegalArgumentException(errores.iterator().next().getMessage());
        return service.confirmar(datos,comprobante,(Integer)session.getAttribute("usuarioId"),(String)session.getAttribute("usuarioRol"));
    }
    public record Revision(@NotNull Boolean aprobar, @jakarta.validation.constraints.Size(max=500) String motivo) {}
    @PostMapping("/api/pagos/{id}/verificar")
    public Map<String,Boolean> verificar(@PathVariable int id,@Valid @RequestBody Revision revision,HttpSession session) {
        service.verificar(id,revision.aprobar(),(Integer)session.getAttribute("usuarioId"),revision.motivo()); return Map.of("ok",true);
    }
    @GetMapping("/api/pagos/{id}/comprobante")
    public ResponseEntity<byte[]> comprobante(@PathVariable int id) {
        var archivo=service.comprobante(id);
        return ResponseEntity.ok().contentType(MediaType.parseMediaType(archivo.tipo()))
                .header(HttpHeaders.CONTENT_DISPOSITION,"attachment; filename=\""+archivo.nombre()+"\"")
                .header("X-Content-Type-Options","nosniff").body(archivo.contenido());
    }
}
