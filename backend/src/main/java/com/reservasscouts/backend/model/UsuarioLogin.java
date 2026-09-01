package com.reservasscouts.backend.model;

public record UsuarioLogin(
        Integer id,
        String email,
        String passwordHash,
        String estado,
        Integer rolId,
        String rol
) {
}