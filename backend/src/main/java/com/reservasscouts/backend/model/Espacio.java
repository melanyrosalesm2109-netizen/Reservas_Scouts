package com.reservasscouts.backend.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record Espacio(
        Integer id,
        String nombre,
        String descripcion,
        String ubicacion,
        Integer capacidad,
        BigDecimal costo,
        String estado,
        String imagen,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}