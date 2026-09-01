package com.reservasscouts.backend.model;

import java.time.LocalDateTime;

public record ReservaResumen(
        Integer id,
        String codigo,
        String espacio,
        String solicitante,
        String responsable,
        Integer participantes,
        String tipoActividad,
        LocalDateTime fechaInicio,
        LocalDateTime fechaFin,
        String estado
) {
}