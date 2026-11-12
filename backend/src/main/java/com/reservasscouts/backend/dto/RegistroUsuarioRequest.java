package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegistroUsuarioRequest(

        @NotBlank(message = "El nombre es obligatorio")
        @Size(
                max = 160,
                message = "El nombre no puede superar los 160 caracteres"
        )
        String nombre,

        @Size(
                max = 30,
                message = "La identificación no puede superar los 30 caracteres"
        )
        String identificacion,

        @Size(
                max = 30,
                message = "El teléfono no puede superar los 30 caracteres"
        )
        String telefono,

        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        @Size(
                max = 160,
                message = "El correo no puede superar los 160 caracteres"
        )
        String email,

        @Size(
                max = 255,
                message = "La dirección no puede superar los 255 caracteres"
        )
        String direccion,

        @NotBlank(message = "La contraseña es obligatoria")
        @Size(
                min = 6,
                max = 100,
                message = "La contraseña debe tener entre 6 y 100 caracteres"
        )
        String password,

        @NotBlank(message = "Debe confirmar la contraseña")
        @Size(
                min = 6,
                max = 100,
                message = "La confirmación de contraseña debe tener entre 6 y 100 caracteres"
        )
        String confirmarPassword
) {
}