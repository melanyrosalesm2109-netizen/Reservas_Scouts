package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.PerfilRequest;
import com.reservasscouts.backend.model.Perfil;
import com.reservasscouts.backend.repository.PerfilRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PerfilService {

    private final PerfilRepository repository;
    private final AuditoriaContextoService auditoriaContexto;


    public PerfilService(
            PerfilRepository repository,
            AuditoriaContextoService auditoriaContexto
    ) {

        this.repository = repository;
        this.auditoriaContexto = auditoriaContexto;
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


    @Transactional
    public Perfil insertar(
            PerfilRequest request
    ) {

        return auditoriaContexto.ejecutar(
                () -> repository.insertar(
                        request
                )
        );
    }


    @Transactional
    public Perfil actualizar(
            Integer idPerfil,
            PerfilRequest request
    ) {

        return auditoriaContexto.ejecutar(
                () -> repository.actualizar(
                        idPerfil,
                        request
                )
        );
    }


    @Transactional
    public void eliminar(
            Integer idPerfil
    ) {

        auditoriaContexto.ejecutar(
                () -> repository.eliminar(
                        idPerfil
                )
        );
    }
}