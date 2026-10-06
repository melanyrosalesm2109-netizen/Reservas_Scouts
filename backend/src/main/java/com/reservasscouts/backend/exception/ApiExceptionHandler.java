package com.reservasscouts.backend.exception;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(
            BaseDatosException.class
    )
    public ResponseEntity<Map<String, Object>>
    manejarBaseDatos(
            BaseDatosException ex
    ) {

        return ResponseEntity
                .badRequest()
                .body(
                        Map.of(
                                "ok", false,
                                "mensaje",
                                ex.getMessage()
                        )
                );
    }

    @ExceptionHandler(
            MethodArgumentNotValidException.class
    )
    public ResponseEntity<Map<String, Object>>
    manejarValidacion(
            MethodArgumentNotValidException ex
    ) {

        String mensaje =
                ex.getBindingResult()
                        .getFieldErrors()
                        .stream()
                        .findFirst()
                        .map(
                                error ->
                                        error.getDefaultMessage()
                        )
                        .orElse(
                                "Datos inválidos."
                        );

        return ResponseEntity
                .badRequest()
                .body(
                        Map.of(
                                "ok", false,
                                "mensaje", mensaje
                        )
                );
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> manejarEstadoHttp(
            ResponseStatusException ex
    ) {
        return ResponseEntity
                .status(ex.getStatusCode())
                .body(Map.of(
                        "ok", false,
                        "mensaje", ex.getReason() == null ? "Solicitud no autorizada." : ex.getReason()
                ));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> manejarSolicitudInvalida(
            IllegalArgumentException ex
    ) {
        return ResponseEntity
                .badRequest()
                .body(Map.of(
                        "ok", false,
                        "mensaje", ex.getMessage()
                ));
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> manejarServicioNoDisponible(
            IllegalStateException ex
    ) {
        return ResponseEntity
                .status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of(
                        "ok", false,
                        "mensaje", ex.getMessage()
                ));
    }
}