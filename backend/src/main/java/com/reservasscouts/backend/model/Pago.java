package com.reservasscouts.backend.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record Pago(
        Integer id,
        Integer reservaId,
        String reservaCodigo,
        String espacio,
        BigDecimal monto,
        String metodo,
        LocalDate fechaPago,
        String estado,
        String comprobante,
        String notas,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}