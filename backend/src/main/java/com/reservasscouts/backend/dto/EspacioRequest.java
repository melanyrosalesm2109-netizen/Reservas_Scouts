package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record EspacioRequest(

        @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 120)
        String nombre,

        String descripcion,

        @NotBlank(message = "La ubicación es obligatoria")
        @Size(max = 160)
        String ubicacion,

        @NotNull(message = "La capacidad es obligatoria")
        @Min(
                value = 1,
                message = "La capacidad debe ser mayor que cero"
        )
        Integer capacidad,

        @NotNull(message = "El costo es obligatorio")
        @DecimalMin(
                value = "0.00",
                message = "El costo no puede ser negativo"
        )
        BigDecimal costo,

        String estado,

        @Size(max = 255)
        String imagen
) {
}