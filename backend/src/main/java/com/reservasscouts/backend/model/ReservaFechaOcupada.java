package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record ReservaFechaOcupada(

        Integer espacioId,

        LocalDateTime fechaInicio,

        LocalDateTime fechaFin
) {
}