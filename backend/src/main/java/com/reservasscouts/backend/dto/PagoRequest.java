package com.reservasscouts.backend.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PagoRequest(

        @NotNull(message = "La reserva es obligatoria")
        Integer reservaId,

        @NotNull(message = "El monto es obligatorio")
        @DecimalMin(
                value = "0.01",
                message = "El monto debe ser mayor que cero"
        )
        BigDecimal monto,

        @NotBlank(message = "El método de pago es obligatorio")
        String metodo,

        @NotNull(message = "La fecha del pago es obligatoria")
        LocalDate fechaPago,

        @NotBlank(message = "El estado es obligatorio")
        @Pattern(
                regexp = "PAGADO|PENDIENTE|RECHAZADO",
                message = "El estado del pago no es válido"
        )
        String estado,

        @Size(
                max = 255,
                message = "El comprobante no puede superar 255 caracteres"
        )
        String comprobante,

        String notas
) {
}