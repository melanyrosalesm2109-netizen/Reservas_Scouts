package com.reservasscouts.backend.service;

import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@EnabledIfEnvironmentVariable(named="RESERVAS_SQL_TEST",matches="true")
class ReservaBloqueoConcurrenciaTest {
    @Autowired ReservaPagoService service;
    @Test void soloUnUsuarioPuedeApartarElMismoHorario() throws Exception {
        int usuario=Integer.parseInt(System.getenv("RESERVAS_SQL_USUARIO"));
        int otro=Integer.parseInt(System.getenv("RESERVAS_SQL_OTRO_USUARIO"));
        int espacio=Integer.parseInt(System.getenv("RESERVAS_SQL_ESPACIO"));
        var inicio=LocalDate.now(ZoneId.of("America/Costa_Rica")).plusDays(250).atTime(10,0);
        var inicioSimultaneo=new CountDownLatch(1);
        var tokens=new ConcurrentHashMap<Integer,UUID>();
        try(var pool=Executors.newFixedThreadPool(2)) {
            var tareas=new ArrayList<Future<Boolean>>();
            for(int id:List.of(usuario,otro)) tareas.add(pool.submit(()-> {
                inicioSimultaneo.await();
                try {
                    var bloqueo=service.bloquear(id,espacio,inicio,inicio.plusHours(2));
                    tokens.put(id,UUID.fromString((String)bloqueo.get("token")));
                    long restante=Duration.between(Instant.parse((String)bloqueo.get("ahora")),Instant.parse((String)bloqueo.get("vence"))).toMillis();
                    assertTrue(restante>118000 && restante<=120100);
                    return true;
                } catch(org.springframework.dao.DataAccessException ex) { return false; }
            }));
            inicioSimultaneo.countDown();
            int aceptados=0;
            for(var t:tareas) if(t.get(15,TimeUnit.SECONDS)) aceptados++;
            assertEquals(1,aceptados);
            int ganador=tokens.keySet().iterator().next();
            int perdedor=ganador==usuario?otro:usuario;
            assertTrue(service.bloqueadas(perdedor).stream().anyMatch(b->b.espacioId()==espacio && b.fechaInicio().equals(inicio)));
            service.liberar(tokens.remove(ganador),ganador);
            var nuevo=service.bloquear(perdedor,espacio,inicio,inicio.plusHours(2));
            tokens.put(perdedor,UUID.fromString((String)nuevo.get("token")));
        } finally { tokens.forEach((id,token)->service.liberar(token,id)); }
    }
}
