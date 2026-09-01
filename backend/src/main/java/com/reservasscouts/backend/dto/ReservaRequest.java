package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public record ReservaRequest(

        @NotBlank(message = "El código es obligatorio")
        @Size(
                max = 20,
                message = "El código no puede superar 20 caracteres"
        )
        String codigo,

        @NotNull(message = "El espacio es obligatorio")
        @Min(
                value = 1,
                message = "El espacio seleccionado no es válido"
        )
        Integer espacioId,

        @NotNull(message = "El perfil solicitante es obligatorio")
        @Min(
                value = 1,
                message = "El perfil seleccionado no es válido"
        )
        Integer solicitantePerfilId,

        Integer creadoPorUsuarioId,

        @Size(
                max = 160,
                message = "El grupo no puede superar 160 caracteres"
        )
        String grupo,

        @NotBlank(message = "El responsable es obligatorio")
        @Size(
                max = 160,
                message = "El responsable no puede superar 160 caracteres"
        )
        String responsable,

        @NotBlank(message = "El teléfono es obligatorio")
        @Size(
                max = 30,
                message = "El teléfono no puede superar 30 caracteres"
        )
        String telefono,

        @NotBlank(message = "El correo es obligatorio")
        @Email(message = "El correo no es válido")
        @Size(
                max = 160,
                message = "El correo no puede superar 160 caracteres"
        )
        String email,

        @NotNull(message = "La cantidad de participantes es obligatoria")
        @Min(
                value = 1,
                message = "Debe existir al menos un participante"
        )
        Integer participantes,

        @NotBlank(message = "El tipo de actividad es obligatorio")
        @Size(
                max = 120,
                message = "El tipo de actividad no puede superar 120 caracteres"
        )
        String tipoActividad,

        @NotNull(message = "La fecha de inicio es obligatoria")
        LocalDateTime fechaInicio,

        @NotNull(message = "La fecha final es obligatoria")
        LocalDateTime fechaFin,

        @NotBlank(message = "El estado es obligatorio")
        @Pattern(
                regexp = "PENDIENTE|APROBADA|CANCELADA|FINALIZADA",
                message = "El estado de la reserva no es válido"
        )
        String estado,

        String observaciones
) {
}