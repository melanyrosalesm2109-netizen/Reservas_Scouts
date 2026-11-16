package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.PagoRequest;
import com.reservasscouts.backend.model.Pago;
import com.reservasscouts.backend.repository.PagoRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class PagoService {

    private final PagoRepository repository;

    private final AuditoriaContextoService
            auditoriaContexto;


    public PagoService(
            PagoRepository repository,
            AuditoriaContextoService auditoriaContexto
    ) {

        this.repository = repository;

        this.auditoriaContexto =
                auditoriaContexto;
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


    @Transactional
    public Pago insertar(
            PagoRequest request
    ) {

        return auditoriaContexto.ejecutar(
                () ->
                        repository.insertar(
                                request
                        )
        );
    }


    @Transactional
    public Pago actualizar(
            Integer id,
            PagoRequest request
    ) {

        repository.bloquearEdicion(id);
        var actual = repository.buscarPorId(id);
        if (actual != null && !"PENDIENTE".equals(actual.estado()))
            throw new IllegalArgumentException("Un pago aprobado no se puede editar. Usa la anulacion con motivo para conservar el historial.");
        if (actual != null && ("Comprobante adjunto".equals(actual.comprobante())
                || "Pago en efectivo al llegar.".equals(actual.notas())
                || "Pago simulado aprobado. Sin cobro real.".equals(actual.notas()))
                && !actual.estado().equals(request.estado())) {
            throw new IllegalArgumentException("Usa la opcion Verificar pago o Rechazar para actualizar tambien la reserva.");
        }
        return auditoriaContexto.ejecutar(
                () ->
                        repository.actualizar(
                                id,
                                request
                        )
        );
    }


    @Transactional
    public void eliminar(
            Integer id
    ) {

        repository.bloquearEdicion(id);
        var actual = repository.buscarPorId(id);
        if (actual != null && !"PENDIENTE".equals(actual.estado()))
            throw new IllegalArgumentException("Los pagos aprobados o anulados no se eliminan. Conserva el historial y usa la anulacion con motivo.");
        auditoriaContexto.ejecutar(
                () ->
                        repository.eliminar(id)
        );
    }
}