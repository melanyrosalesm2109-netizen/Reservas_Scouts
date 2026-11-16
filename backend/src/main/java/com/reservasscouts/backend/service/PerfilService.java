package com.reservasscouts.backend.service;

import com.reservasscouts.backend.dto.PerfilRequest;
import com.reservasscouts.backend.model.Perfil;
import com.reservasscouts.backend.repository.PerfilRepository;
import com.reservasscouts.backend.repository.UsuarioRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PerfilService {

    private final PerfilRepository repository;
    private final AuditoriaContextoService auditoriaContexto;
    private final UsuarioRepository usuarios;


    public PerfilService(
            PerfilRepository repository,
            AuditoriaContextoService auditoriaContexto,
            UsuarioRepository usuarios
    ) {

        this.repository = repository;
        this.auditoriaContexto = auditoriaContexto;
        this.usuarios = usuarios;
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
    public java.util.Set<Integer> usuariosRegistrados() {
        return usuarios.filtrar(null,null,null).stream()
                .filter(u -> "Usuario".equals(u.rol()) || "Miembro".equals(u.rol()))
                .map(u -> u.id()).collect(java.util.stream.Collectors.toSet());
    }


    @Transactional
    public Perfil insertar(
            PerfilRequest request
    ) {
        PerfilRequest datos = request;
        if (request.usuarioId() == null && "Persona".equals(request.tipoPerfil())) {
            var coincidencias = usuarios.filtrar(request.correoContacto().trim(), null, null).stream()
                    .filter(u -> u.email().equalsIgnoreCase(request.correoContacto().trim()))
                    .toList();
            if (coincidencias.size() == 1) {
                datos = new PerfilRequest(coincidencias.get(0).id(), request.nombre(),
                        request.identificacion(), request.telefono(), request.correoContacto(),
                        request.tipoPerfil(), request.direccion());
            }
        }
        PerfilRequest perfilVinculado = datos;
        return auditoriaContexto.ejecutar(
                () -> repository.insertar(
                        perfilVinculado
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
