package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UsuarioRequest(

        @NotNull(
                message = "El rol es obligatorio"
        )
        Integer rolId,

        @NotBlank(
                message = "El correo es obligatorio"
        )
        @Email(
                message = "El correo no es válido"
        )
        @Size(
                max = 160,
                message = "El correo no puede superar 160 caracteres"
        )
        String email,

        /*
         * En creación es obligatoria.
         * En actualización puede venir vacía.
         */
        @Size(
                max = 100,
                message = "La contraseña no puede superar 100 caracteres"
        )
        String password,

        @NotBlank(
                message = "El estado es obligatorio"
        )
        @Pattern(
                regexp = "ACTIVO|INACTIVO",
                message = "El estado debe ser ACTIVO o INACTIVO"
        )
        String estado
) {
}