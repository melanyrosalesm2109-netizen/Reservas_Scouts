package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(

        @NotBlank(
                message = "El usuario o correo es obligatorio"
        )
        String email,

        @NotBlank(
                message = "La contraseña es obligatoria"
        )
        String password
) {
}