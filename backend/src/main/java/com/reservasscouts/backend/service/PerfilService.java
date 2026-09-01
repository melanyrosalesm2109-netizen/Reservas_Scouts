package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.PerfilRequest;
import com.reservasscouts.backend.model.Perfil;
import com.reservasscouts.backend.repository.PerfilRepository;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PerfilService {

    private final PerfilRepository repository;

    public PerfilService(
            PerfilRepository repository
    ) {
        this.repository = repository;
    }

    public List<Perfil> filtrar(
            String nombre,
            String identificacion,
            String correoContacto,
            String tipoPerfil,
            Integer usuarioId
    ) {

        return repository.filtrar(
                nombre,
                identificacion,
                correoContacto,
                tipoPerfil,
                usuarioId
        );
    }

    public Perfil buscarPorId(
            Integer idPerfil
    ) {

        return repository.buscarPorId(
                idPerfil
        );
    }

    public Perfil insertar(
            PerfilRequest request
    ) {

        return repository.insertar(
                request
        );
    }

    public Perfil actualizar(
            Integer idPerfil,
            PerfilRequest request
    ) {

        return repository.actualizar(
                idPerfil,
                request
        );
    }

    public void eliminar(
            Integer idPerfil
    ) {

        repository.eliminar(
                idPerfil
        );
    }
}