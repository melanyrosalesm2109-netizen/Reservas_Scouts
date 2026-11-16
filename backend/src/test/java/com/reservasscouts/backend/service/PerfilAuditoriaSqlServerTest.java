package com.reservasscouts.backend.service;

import com.reservasscouts.backend.controller.PerfilController;
import com.reservasscouts.backend.dto.PerfilRequest;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
@EnabledIfEnvironmentVariable(named="RESERVAS_SQL_TEST",matches="true")
class PerfilAuditoriaSqlServerTest {
 @Autowired PerfilController controller;
 @Autowired PerfilService service;
 @Autowired JdbcTemplate jdbc;
 @Test void laPantallaRecibeLosPerfilesDeCuentasRegistradas() {
  var perfiles=controller.filtrar(null,null,null,null,null,true);
  assertFalse(perfiles.isEmpty());
  var ids=jdbc.queryForList("EXEC dbo.paUsuariosRegistradosIds",Integer.class);
  assertTrue(perfiles.stream().allMatch(p->ids.contains(p.usuarioId())));
 }
 @Test void crearEditarYEliminarPerfilConservaAuditoria() {
  var request=new MockHttpServletRequest();
  request.getSession().setAttribute("usuarioId",6);
  request.getSession().setAttribute("usuarioEmail","revision-perfiles@example.com");
  RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
  try {
   String email="it"+UUID.randomUUID().toString().replace("-","").substring(0,12)+"@example.com";
   var perfil=service.insertar(new PerfilRequest(null,"Perfil temporal",null,"88881111",email,"Grupo Scout",null));
   service.actualizar(perfil.idPerfil(),new PerfilRequest(null,"Perfil editado",null,"88882222",email,"Grupo Scout",null));
   service.eliminar(perfil.idPerfil());
   var eventos=jdbc.queryForList("EXEC dbo.paAuditoriaDetalle");
   for(String accion:List.of("INSERT","UPDATE","DELETE"))
    assertTrue(eventos.stream().anyMatch(e->"perfilesUsuario".equals(e.get("origen")) && accion.equals(e.get("evento")) && perfil.idPerfil().equals(e.get("registroId")) && "revision-perfiles@example.com".equals(e.get("usuario"))));
  } finally { RequestContextHolder.resetRequestAttributes(); }
 }
}
