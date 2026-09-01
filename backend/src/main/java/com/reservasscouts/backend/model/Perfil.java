package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record Perfil(
        Integer idPerfil,
        Integer usuarioId,
        String nombre,
        String identificacion,
        String telefono,
        String correoContacto,
        String tipoPerfil,
        String direccion,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}