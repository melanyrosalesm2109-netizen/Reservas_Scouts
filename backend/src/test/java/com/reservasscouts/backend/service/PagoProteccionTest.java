package com.reservasscouts.backend.service;

import com.reservasscouts.backend.model.Pago;
import com.reservasscouts.backend.repository.PagoRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PagoProteccionTest {
    @Test void losPagosResueltosNoSeEditanNiEliminan() {
        var repo=mock(PagoRepository.class);
        var service=new PagoService(repo,mock(AuditoriaContextoService.class));
        for(String estado:new String[]{"PAGADO","ANULADO","RECHAZADO"}) {
            when(repo.buscarPorId(1)).thenReturn(new Pago(1,1,"TEST","Campo",new BigDecimal("25000"),"Tarjeta",LocalDate.now(),estado,null,null,null,null));
            assertThrows(IllegalArgumentException.class,()->service.actualizar(1,null));
            assertThrows(IllegalArgumentException.class,()->service.eliminar(1));
        }
        verify(repo,never()).actualizar(any(),any());
        verify(repo,never()).eliminar(any());
    }
}
