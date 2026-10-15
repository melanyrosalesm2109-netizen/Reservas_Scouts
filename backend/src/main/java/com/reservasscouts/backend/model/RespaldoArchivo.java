package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record RespaldoArchivo(
        String nombre,
        LocalDateTime creadoEn,
        long bytes
) {
}
