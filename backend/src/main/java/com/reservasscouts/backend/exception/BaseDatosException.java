package com.reservasscouts.backend.exception;

public class BaseDatosException extends RuntimeException {

    public BaseDatosException(String mensaje) {
        super(mensaje);
    }
}