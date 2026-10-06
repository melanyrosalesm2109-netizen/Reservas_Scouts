package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record AuditoriaResumen(
        String origen,
        String evento,
        Long totalEventos,
        LocalDateTime ultimoEvento
) {
}
