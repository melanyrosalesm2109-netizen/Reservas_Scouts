package com.reservasscouts.backend.service;

import java.sql.*;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@EnabledIfEnvironmentVariable(named="RESERVAS_RESTORE_TEST",matches="true")
class RespaldoSqlServerTest {
 @Autowired RespaldoService service;
 @Autowired DataSource datasource;
 @Autowired JdbcTemplate jdbc;
 @Value("${app.backup.directory}") String directory;
 @Test void creaVerificaYRecuperaEnBaseAisladaConAuditoriaPersistente() throws Exception {
  var copia=service.crear(6,"127.0.0.1","Prueba aislada de respaldo y restauracion");
  assertTrue(copia.bytes()>0);
  assertTrue(service.listar().stream().anyMatch(c -> c.nombre().equals(copia.nombre())));
  // La prueba sustituye exclusivamente el destino; nunca llama al RESTORE de la base real.
  var aislado=new RespaldoService(directory,datasource) {
   @Override void restaurarCopia(Statement statement,String ruta) throws SQLException {
    ejecutarSQL(statement,"EXEC dbo.paRestaurarReservasScoutsPrueba @pRuta=N'"+ruta+"'");
   }
  };
  aislado.restaurar(copia.nombre(),6,"127.0.0.1","Prueba de restauracion SOLO en base temporal");
  assertFalse(jdbc.queryForList("EXEC reservasScouts_restore_test_codex.dbo.paUsuariosRegistradosIds").isEmpty());
  assertTrue(service.listar().stream().anyMatch(c -> c.nombre().equals(copia.nombre())));
  var eventos=jdbc.queryForList("EXEC master.dbo.paReservasOperacionesAuditoria");
  assertTrue(eventos.stream().anyMatch(e -> "RESTORE".equals(e.get("evento")) && e.get("detalle").toString().contains(copia.nombre()) && e.get("detalle").toString().contains("COMPLETADO")));
  assertTrue(eventos.stream().anyMatch(e -> "BACKUP".equals(e.get("evento")) && e.get("detalle").toString().contains(copia.nombre()) && e.get("detalle").toString().contains("COMPLETADO")));
 }
 @Test void intentoDeCopiaNoRegistradaQuedaAuditadoSinRestaurar() {
  String nombre="reservasScouts_20000101_000000_00000000-0000-0000-0000-000000000000.bak";
  assertThrows(IllegalArgumentException.class,()->service.restaurar(nombre,6,"127.0.0.1","Prueba de archivo inexistente"));
  assertTrue(jdbc.queryForList("EXEC master.dbo.paReservasOperacionesAuditoria").stream().anyMatch(e -> e.get("detalle").toString().contains(nombre) && e.get("detalle").toString().contains("ERROR")));
 }
}
