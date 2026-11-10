package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.EspacioRequest;
import com.reservasscouts.backend.model.Espacio;
import com.reservasscouts.backend.repository.EspacioRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class EspacioService {

    private final EspacioRepository repository;
    private final AuditoriaContextoService auditoriaContexto;

    public EspacioService(
            EspacioRepository repository,
            AuditoriaContextoService auditoriaContexto
    ) {
        this.repository = repository;
        this.auditoriaContexto = auditoriaContexto;
    }


    public List<Espacio> filtrar(
            String nombre,
            String ubicacion,
            String estado,
            Integer capacidadMinima,
            BigDecimal costoMaximo
    ) {

        return repository.filtrar(
                nombre,
                ubicacion,
                estado,
                capacidadMinima,
                costoMaximo
        );
    }


    public Espacio buscarPorId(
            Integer id
    ) {

        return repository.buscarPorId(id);
    }


    @Transactional
    public Espacio insertar(
            EspacioRequest request
    ) {

        return auditoriaContexto.ejecutar(
                () -> repository.insertar(request)
        );
    }


    @Transactional
    public Espacio actualizar(
            Integer id,
            EspacioRequest request
    ) {

        return auditoriaContexto.ejecutar(
                () -> repository.actualizar(
                        id,
                        request
                )
        );
    }


    @Transactional
    public void eliminar(
            Integer id
    ) {

        auditoriaContexto.ejecutar(
                () -> repository.eliminar(id)
        );
    }
}