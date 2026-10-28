package com.reservasscouts.backend.controller;

import com.reservasscouts.backend.model.AuditoriaDetalle;
import com.reservasscouts.backend.model.AuditoriaResumen;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;


@RestController
@RequestMapping("/api/auditoria")
public class AuditoriaController {

    private final JdbcTemplate jdbcTemplate;


    public AuditoriaController(
            JdbcTemplate jdbcTemplate
    ) {

        this.jdbcTemplate = jdbcTemplate;
    }


    // =====================================================
    // RESUMEN DE AUDITORÍA
    // =====================================================

    @GetMapping("/resumen")
    public List<AuditoriaResumen> obtenerResumen() {

        return jdbcTemplate.query(
                "EXEC dbo.paAuditoriaResumen",

                (rs, rowNum) -> {

                    Timestamp timestamp =
                            rs.getTimestamp(
                                    "ultimoEvento"
                            );


                    LocalDateTime ultimoEvento =
                            timestamp != null
                                    ? timestamp.toLocalDateTime()
                                    : null;


                    return new AuditoriaResumen(
                            rs.getString(
                                    "origen"
                            ),

                            rs.getString(
                                    "evento"
                            ),

                            rs.getLong(
                                    "totalEventos"
                            ),

                            ultimoEvento
                    );
                }
        );
    }


    // =====================================================
    // DETALLE DE AUDITORÍA
    // =====================================================

    @GetMapping("/detalle")
    public List<AuditoriaDetalle> obtenerDetalle() {

        return jdbcTemplate.query(
                "EXEC dbo.paAuditoriaDetalle",

                (rs, rowNum) -> {

                    Timestamp timestamp =
                            rs.getTimestamp(
                                    "creadoEn"
                            );


                    LocalDateTime creadoEn =
                            timestamp != null
                                    ? timestamp.toLocalDateTime()
                                    : null;


                    Integer registroId =
                            rs.getObject(
                                    "registroId",
                                    Integer.class
                            );


                    return new AuditoriaDetalle(

                            rs.getLong(
                                    "idAuditoria"
                            ),

                            rs.getString(
                                    "origen"
                            ),

                            rs.getString(
                                    "evento"
                            ),

                            registroId,

                            rs.getString(
                                    "usuario"
                            ),

                            rs.getString(
                                    "usuarioBd"
                            ),

                            rs.getString(
                                    "detalle"
                            ),

                            rs.getString(
                                    "valoresAnteriores"
                            ),

                            rs.getString(
                                    "valoresNuevos"
                            ),

                            creadoEn
                    );
                }
        );
    }
}