package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record Rol(
        Integer id,
        String nombre,
        String descripcion,
        LocalDateTime createdAt
) {
}