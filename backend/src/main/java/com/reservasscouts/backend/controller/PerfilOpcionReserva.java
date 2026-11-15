package com.reservasscouts.backend.controller;

public record PerfilOpcionReserva(
        Integer idPerfil,
        String nombre,
        String tipoPerfil,
        Integer usuarioId,
        String telefono,
        String correoContacto
) {
}
