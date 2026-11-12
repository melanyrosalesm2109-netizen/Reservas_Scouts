package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.ReservaRequest;
import com.reservasscouts.backend.model.Reserva;
import com.reservasscouts.backend.model.ReservaFechaOcupada;
import com.reservasscouts.backend.model.ReservaResumen;
import com.reservasscouts.backend.repository.ReservaRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class ReservaService {

    private final ReservaRepository repository;
    private final AuditoriaContextoService auditoriaContexto;


    public ReservaService(
            ReservaRepository repository,
            AuditoriaContextoService auditoriaContexto
    ) {

        this.repository = repository;
        this.auditoriaContexto = auditoriaContexto;
    }


    // =====================================================
    // LISTAR / FILTRAR
    // =====================================================

    public List<ReservaResumen> filtrar(
            String codigo,
            String responsable,
            String estado,
            Integer espacioId,
            Integer solicitantePerfilId,
            LocalDate fechaDesde,
            LocalDate fechaHasta,
            Integer creadoPorUsuarioId
    ) {

        return repository.filtrar(
                codigo,
                responsable,
                estado,
                espacioId,
                solicitantePerfilId,
                fechaDesde,
                fechaHasta,
                creadoPorUsuarioId
        );
    }


    // =====================================================
    // BUSCAR POR ID
    // =====================================================

    public Reserva buscarPorId(
            Integer id
    ) {

        return repository.buscarPorId(
                id
        );
    }


    // =====================================================
    // CONSULTAR DISPONIBILIDAD
    // =====================================================

    public boolean consultarDisponibilidad(
            Integer espacioId,
            LocalDateTime fechaInicio,
            LocalDateTime fechaFin
    ) {

        if (
                espacioId == null
                        || espacioId <= 0
        ) {

            throw new IllegalArgumentException(
                    "El espacio indicado no es válido."
            );
        }


        if (
                fechaInicio == null
                        || fechaFin == null
                        || !fechaFin.isAfter(fechaInicio)
        ) {

            throw new IllegalArgumentException(
                    "La fecha final debe ser mayor que la fecha inicial."
            );
        }


        return repository.consultarDisponibilidad(
                espacioId,
                fechaInicio,
                fechaFin
        );
    }


    // =====================================================
    // FECHAS OCUPADAS
    // =====================================================

    public List<ReservaFechaOcupada> listarFechasOcupadas() {

        return repository.listarFechasOcupadas();
    }


    // =====================================================
    // INSERTAR
    // =====================================================

    @Transactional
    public Reserva insertar(
            ReservaRequest request
    ) {

        validarFechas(
                request
        );


        return auditoriaContexto.ejecutar(
                () -> repository.insertar(
                        request
                )
        );
    }


    // =====================================================
    // ACTUALIZAR
    // =====================================================

    @Transactional
    public Reserva actualizar(
            Integer id,
            ReservaRequest request
    ) {

        validarFechas(
                request
        );


        Reserva reservaActual =
                repository.buscarPorId(
                        id
                );


        if (reservaActual == null) {

            throw new IllegalArgumentException(
                    "La reserva indicada no existe."
            );
        }


        ReservaRequest requestConCreadorOriginal =
                new ReservaRequest(

                        request.codigo(),

                        request.espacioId(),

                        request.solicitantePerfilId(),

                        reservaActual.creadoPorUsuarioId(),

                        request.grupo(),

                        request.responsable(),

                        request.telefono(),

                        request.email(),

                        request.participantes(),

                        request.tipoActividad(),

                        request.fechaInicio(),

                        request.fechaFin(),

                        request.estado(),

                        request.observaciones()
                );


        return auditoriaContexto.ejecutar(
                () -> repository.actualizar(
                        id,
                        requestConCreadorOriginal
                )
        );
    }


    // =====================================================
    // ELIMINAR
    // =====================================================

    @Transactional
    public void eliminar(
            Integer id
    ) {

        auditoriaContexto.ejecutar(
                () -> repository.eliminar(
                        id
                )
        );
    }


    // =====================================================
    // VALIDAR FECHAS
    // =====================================================

    private void validarFechas(
            ReservaRequest request
    ) {

        if (
                request.fechaInicio() == null
                        || request.fechaFin() == null
        ) {

            throw new IllegalArgumentException(
                    "Debe indicar la fecha de inicio y la fecha final."
            );
        }


        if (
                !request.fechaFin()
                        .isAfter(
                                request.fechaInicio()
                        )
        ) {

            throw new IllegalArgumentException(
                    "La fecha final debe ser mayor que la fecha inicial."
            );
        }
    }
}