package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.EspacioRequest;
import com.reservasscouts.backend.model.Espacio;
import com.reservasscouts.backend.repository.EspacioRepository;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

@Service
public class EspacioService {

    private final EspacioRepository repository;

    public EspacioService(
            EspacioRepository repository
    ) {
        this.repository = repository;
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

    public Espacio insertar(
            EspacioRequest request
    ) {

        return repository.insertar(request);
    }

    public Espacio actualizar(
            Integer id,
            EspacioRequest request
    ) {

        return repository.actualizar(
                id,
                request
        );
    }

    public void eliminar(Integer id) {

        repository.eliminar(id);
    }
}