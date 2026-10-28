package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record AuditoriaDetalle(
        Long idAuditoria,
        String origen,
        String evento,
        Integer registroId,
        String usuario,
        String usuarioBd,
        String detalle,
        String valoresAnteriores,
        String valoresNuevos,
        LocalDateTime creadoEn
) {
}