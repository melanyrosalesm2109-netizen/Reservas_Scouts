package com.reservasscouts.backend.dto;

public record LoginResponse(
        Integer id,
        String email,
        Integer rolId,
        String rol
) {
}