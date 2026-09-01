package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record Reserva(
        Integer id,
        String codigo,
        Integer espacioId,
        String espacio,
        Integer solicitantePerfilId,
        String solicitante,
        Integer creadoPorUsuarioId,
        String creadoPor,
        String grupo,
        String responsable,
        String telefono,
        String email,
        Integer participantes,
        String tipoActividad,
        LocalDateTime fechaInicio,
        LocalDateTime fechaFin,
        String estado,
        String observaciones,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}