package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record Usuario(
        Integer id,
        Integer rolId,
        String rol,
        String email,
        String estado,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}