package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record RestaurarRespaldoRequest(
        @NotBlank String nombreArchivo,
        @NotBlank String confirmacion
) {
}
