package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PerfilRequest(

        Integer usuarioId,

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

        @NotBlank(message = "El correo de contacto es obligatorio")
        @Email(message = "El correo de contacto no es válido")
        @Size(
                max = 160,
                message = "El correo no puede superar los 160 caracteres"
        )
        String correoContacto,

        @NotBlank(message = "El tipo de perfil es obligatorio")
        String tipoPerfil,

        @Size(
                max = 255,
                message = "La dirección no puede superar los 255 caracteres"
        )
        String direccion
) {
}