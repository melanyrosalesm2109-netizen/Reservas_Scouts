package com.reservasscouts.backend.service;

import com.reservasscouts.backend.model.RespaldoArchivo;
import com.zaxxer.hikari.HikariDataSource;
import javax.sql.DataSource;
import java.nio.file.Path;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.*;

@Service
public class RespaldoService {
    private static final Pattern NAME=Pattern.compile("^reservasScouts_\\d{8}_\\d{6}_[0-9a-fA-F-]{36}\\.bak$");
    private final Path directory;
    private final DataSource datasource;
    public RespaldoService(@Value("${app.backup.directory}") String directory,DataSource datasource) {
        this.directory=Path.of(directory).toAbsolutePath().normalize(); this.datasource=datasource;
    }
    Connection conectar() throws SQLException {
        String password=System.getenv("RESERVASSCOUTS_MAINTENANCE_PASSWORD");
        if(password==null || password.isBlank()) throw new IllegalStateException("Falta configurar la cuenta de mantenimiento de respaldos.");
        return DriverManager.getConnection("jdbc:sqlserver://localhost:1433;encrypt=true;trustServerCertificate=true;databaseName=master", "reservas_maintenance",password);
    }
    public List<RespaldoArchivo> listar() {
        try(Connection c=conectar(); Statement s=c.createStatement(); ResultSet rs=s.executeQuery("EXEC dbo.paReservasRespaldoListar")) {
            var result=new ArrayList<RespaldoArchivo>();
            while(rs.next()) result.add(new RespaldoArchivo(rs.getString("nombre"),rs.getTimestamp("creadoEn").toLocalDateTime(),rs.getLong("bytes")));
            return result;
        } catch(SQLException ex) { throw new IllegalStateException("No se pudo consultar el catalogo de respaldos de SQL Server.",ex); }
    }
    public RespaldoArchivo crear(Integer usuarioId,String ip,String agente) {
        String nombre="reservasScouts_"+LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"))+"_"+UUID.randomUUID()+".bak";
        return ejecutar(nombre,false,usuarioId,ip,agente);
    }
    public void restaurar(String nombre,Integer usuarioId,String ip,String agente) {
        ejecutar(nombre,true,usuarioId,ip,agente);
    }
    private RespaldoArchivo ejecutar(String nombre,boolean restaurar,Integer usuarioId,String ip,String agente) {
        Path path=validarRuta(nombre);
        UUID operacion=UUID.randomUUID();
        try(Connection c=conectar()) {
            iniciar(c,operacion,restaurar?"RESTORE":"BACKUP",nombre,usuarioId,ip,agente);
            try {
                if(restaurar && listar().stream().noneMatch(r->r.nombre().equals(nombre)))
                    throw new IllegalArgumentException("El respaldo seleccionado no pertenece al catalogo de la aplicacion.");
                Metadata meta;
                try(Statement s=c.createStatement()) {
                    s.setQueryTimeout(600);
                    String ruta=path.toString().replace("'","''");
                    if(restaurar) {
                        meta=encabezado(s,ruta);
                        vaciarConexiones();
                        try { restaurarCopia(s,ruta); }
                        finally { vaciarConexiones(); }
                    } else {
                        ejecutarSQL(s,"EXEC dbo.paRespaldoCompleto @pRuta=N'"+ruta+"'");
                        meta=encabezado(s,ruta);
                    }
                }
                try(PreparedStatement p=c.prepareStatement("EXEC dbo.paReservasRespaldoRegistrar ?,?,?")) {
                    p.setString(1,nombre);p.setTimestamp(2,Timestamp.valueOf(meta.fecha));p.setLong(3,meta.bytes);p.execute();
                }
                finalizar(c,operacion,"COMPLETADO",null);
                return new RespaldoArchivo(nombre,meta.fecha,meta.bytes);
            } catch(Exception ex) {
                try { finalizar(c,operacion,"ERROR",ex.getMessage()); } catch(SQLException logError) { ex.addSuppressed(logError); }
                if(ex instanceof IllegalArgumentException validation) throw validation;
                throw new IllegalStateException(restaurar?"SQL Server no pudo restaurar la copia seleccionada. La incidencia quedo registrada en auditoria.":"SQL Server no pudo crear o verificar el respaldo. La incidencia quedo registrada en auditoria.",ex);
            }
        } catch(SQLException ex) { throw new IllegalStateException("No se pudo conectar con el servicio de mantenimiento de SQL Server.",ex); }
    }
    Path validarRuta(String nombre) {
        if(nombre==null || !NAME.matcher(nombre).matches()) throw new IllegalArgumentException("Nombre de respaldo no permitido.");
        Path path=directory.resolve(nombre).normalize();
        if(!directory.equals(path.getParent())) throw new IllegalArgumentException("Ruta de respaldo no permitida.");
        return path;
    }
    void restaurarCopia(Statement statement,String ruta) throws SQLException {
        ejecutarSQL(statement,"EXEC dbo.paRestaurarReservasScouts @pRuta=N'"+ruta+"'");
    }
    static void ejecutarSQL(Statement statement,String sql) throws SQLException {
        boolean resultado=statement.execute(sql);
        while(true) {
            if(resultado) { try(ResultSet rs=statement.getResultSet()) { while(rs.next()) { /* Consumir el resultado completo. */ } } }
            else if(statement.getUpdateCount()==-1) break;
            resultado=statement.getMoreResults(Statement.CLOSE_CURRENT_RESULT);
        }
    }
    private Metadata encabezado(Statement s,String ruta) throws SQLException {
        try(ResultSet rs=s.executeQuery("RESTORE HEADERONLY FROM DISK=N'"+ruta+"'")) {
            if(!rs.next() || !"reservasScouts".equalsIgnoreCase(rs.getString("DatabaseName")) || rs.getInt("BackupType")!=1
                || rs.getLong("BackupSize")<=0 || rs.getTimestamp("BackupFinishDate")==null)
                throw new IllegalArgumentException("El archivo debe contener una unica copia completa valida de reservasScouts.");
            var metadata=new Metadata(rs.getTimestamp("BackupFinishDate").toLocalDateTime(),rs.getLong("BackupSize"));
            if(rs.next()) throw new IllegalArgumentException("Selecciona una copia con un unico respaldo completo.");
            return metadata;
        }
    }
    private void iniciar(Connection c,UUID id,String evento,String archivo,Integer usuarioId,String ip,String agente) throws SQLException {
        String usuario="Cuenta #"+usuarioId;
        if(RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes attrs) {
            var session=attrs.getRequest().getSession(false);
            if(session!=null && session.getAttribute("usuarioEmail") instanceof String email) usuario=email;
        }
        try(PreparedStatement p=c.prepareStatement("EXEC dbo.paReservasOperacionIniciar ?,?,?,?,?,?,?")) {
            p.setString(1,id.toString());p.setString(2,evento);p.setString(3,archivo);p.setObject(4,usuarioId,Types.INTEGER);
            p.setString(5,usuario);p.setString(6,ip);p.setString(7,agente==null?null:agente.substring(0,Math.min(500,agente.length())));p.execute();
        }
    }
    private void finalizar(Connection c,UUID id,String estado,String error) throws SQLException {
        try(PreparedStatement p=c.prepareStatement("EXEC dbo.paReservasOperacionFinalizar ?,?,?")) {
            p.setString(1,id.toString());p.setString(2,estado);p.setString(3,error==null?null:error.substring(0,Math.min(1000,error.length())));p.execute();
        }
    }
    private void vaciarConexiones() {
        if(datasource instanceof HikariDataSource hikari && hikari.getHikariPoolMXBean()!=null) hikari.getHikariPoolMXBean().softEvictConnections();
    }
    private record Metadata(LocalDateTime fecha,long bytes) {}
}
