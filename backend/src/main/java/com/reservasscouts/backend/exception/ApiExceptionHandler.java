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

    @ExceptionHandler(org.springframework.web.multipart.MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String,Object>> manejarComprobanteGrande(Exception ex) {
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                .body(Map.of("ok",false,"mensaje","El comprobante no puede superar 5 MB."));
    }

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

    @ExceptionHandler(org.springframework.dao.DataAccessException.class)
    public ResponseEntity<Map<String,Object>> manejarSql(org.springframework.dao.DataAccessException ex) {
        Throwable causa=ex.getMostSpecificCause();
        if(causa instanceof java.sql.SQLException sql && sql.getErrorCode()>=51010 && sql.getErrorCode()<=51019) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("ok",false,"mensaje",sql.getMessage()));
        }
        org.slf4j.LoggerFactory.getLogger(getClass()).error("Error al completar la operacion de datos",ex);
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("ok",false,"mensaje","No se pudo completar la operacion. Intenta nuevamente."));
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
