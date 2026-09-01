package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.model.Reserva;
import com.reservasscouts.backend.model.ReservaResumen;
import com.reservasscouts.backend.repository.ReservaRepository;

import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class ReservaService {

    private final ReservaRepository repository;

    public ReservaService(
            ReservaRepository repository
    ) {
        this.repository = repository;
    }

    public List<ReservaResumen> filtrar(
            String codigo,
            String responsable,
            String estado,
            Integer espacioId,
            Integer solicitantePerfilId,
            LocalDate fechaDesde,
            LocalDate fechaHasta
    ) {

        return repository.filtrar(
                codigo,
                responsable,
                estado,
                espacioId,
                solicitantePerfilId,
                fechaDesde,
                fechaHasta
        );
    }

    public Reserva buscarPorId(
            Integer id
    ) {

        return repository.buscarPorId(id);
    }

    public Reserva insertar(
            ReservaRequest request
    ) {

        validarFechas(request);

        return repository.insertar(
                request
        );
    }

    public Reserva actualizar(
            Integer id,
            ReservaRequest request
    ) {

        validarFechas(request);

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

    private void validarFechas(
            ReservaRequest request
    ) {

        if (!request.fechaFin()
                .isAfter(
                        request.fechaInicio()
                )) {

            throw new IllegalArgumentException(
                    "La fecha final debe ser mayor que la fecha inicial."
            );
        }
    }
}