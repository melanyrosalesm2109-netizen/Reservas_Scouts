package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.dto.RestaurarRespaldoRequest;
import com.reservasscouts.backend.model.RespaldoArchivo;
import com.reservasscouts.backend.service.RespaldoService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/respaldo")
public class RespaldoController {

    private final RespaldoService respaldoService;

    public RespaldoController(RespaldoService respaldoService) {
        this.respaldoService = respaldoService;
    }

    @GetMapping
    public List<RespaldoArchivo> listar() {
        return respaldoService.listar();
    }

    @PostMapping
    public RespaldoArchivo crear(HttpSession session, HttpServletRequest request) {
        return respaldoService.crear(
                (Integer) session.getAttribute("usuarioId"),
                request.getRemoteAddr(),
                request.getHeader("User-Agent")
        );
    }

    @PostMapping("/restaurar")
    public Map<String, Object> restaurar(
            @Valid @RequestBody RestaurarRespaldoRequest requestBody,
            HttpSession session,
            HttpServletRequest request
    ) {
        respaldoService.restaurar(
                requestBody.nombreArchivo(),
                requestBody.confirmacion(),
                (Integer) session.getAttribute("usuarioId"),
                request.getRemoteAddr(),
                request.getHeader("User-Agent")
        );
        return Map.of("ok", true, "mensaje", "El respaldo se restauró correctamente.");
    }
}
