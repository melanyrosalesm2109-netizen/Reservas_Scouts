package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.service.CobroService;
import com.reservasscouts.backend.model.Pago;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import jakarta.validation.Validator;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.*;

@RestController
@RequestMapping("/api/pagos")
public class CobroController {
    private final CobroService service;
    private final Validator validator;
    public CobroController(CobroService service,Validator validator) { this.service=service;this.validator=validator; }
    @GetMapping("/cobros-disponibles")
    public List<CobroService.Disponible> disponibles() { return service.disponibles(); }
    @GetMapping("/{id}/detalle")
    public Map<String,Object> detalle(@PathVariable int id) { return service.detalle(id); }
    @PostMapping(value="/registrar-cobro",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Pago registrar(@RequestPart("datos") CobroService.Solicitud datos,
            @RequestPart(value="comprobante",required=false) MultipartFile archivo) throws Exception {
        var errores=validator.validate(datos);
        if(!errores.isEmpty()) throw new IllegalArgumentException(errores.iterator().next().getMessage());
        return service.registrar(datos,archivo);
    }
    public record Anulacion(@NotBlank @Size(max=500) String motivo) {}
    @PostMapping("/{id}/anular")
    public Map<String,Boolean> anular(@PathVariable int id,@Valid @RequestBody Anulacion datos,HttpSession session) {
        if(!"Administrador".equals(session.getAttribute("usuarioRol")))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Solo un administrador puede anular un pago.");
        service.anular(id,(Integer)session.getAttribute("usuarioId"),datos.motivo());return Map.of("ok",true);
    }
}
