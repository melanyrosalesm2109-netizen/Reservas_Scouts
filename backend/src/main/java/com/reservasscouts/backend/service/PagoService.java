package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.PagoRequest;
import com.reservasscouts.backend.model.Pago;
import com.reservasscouts.backend.repository.PagoRepository;

import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class PagoService {

    private final PagoRepository repository;

    public PagoService(
            PagoRepository repository
    ) {
        this.repository = repository;
    }

    public List<Pago> filtrar(
            Integer reservaId,
            String codigoReserva,
            String metodo,
            String estado,
            LocalDate fechaDesde,
            LocalDate fechaHasta
    ) {

        return repository.filtrar(
                reservaId,
                codigoReserva,
                metodo,
                estado,
                fechaDesde,
                fechaHasta
        );
    }

    public Pago buscarPorId(
            Integer id
    ) {

        return repository.buscarPorId(id);
    }

    public Pago insertar(
            PagoRequest request
    ) {

        return repository.insertar(
                request
        );
    }

    public Pago actualizar(
            Integer id,
            PagoRequest request
    ) {

        return repository.actualizar(
                id,
                request
        );
    }

    public void eliminar(
            Integer id
    ) {

        repository.eliminar(id);
    }
}