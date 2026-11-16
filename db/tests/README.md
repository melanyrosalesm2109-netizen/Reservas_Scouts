# Helpers de pruebas SQL

Estos procedimientos auxiliares se instalan únicamente para las pruebas de
integración correspondientes. No son parte del instalador ni del arranque normal.

| Preparación | Prueba | Activación adicional |
| --- | --- | --- |
| `preparar_vencimiento.sql` | `ReservaVencimientoSqlServerTest` | `RESERVAS_VENCIMIENTO_TEST=true` |
| `preparar_restore_aislado.sql` | `RespaldoSqlServerTest` | `RESERVAS_RESTORE_TEST=true` |

Las pruebas SQL generales usan `RESERVAS_SQL_TEST=true`,
`RESERVAS_SQL_USUARIO`, `RESERVAS_SQL_PERFIL`, `RESERVAS_SQL_ESPACIO` y,
para concurrencia, `RESERVAS_SQL_OTRO_USUARIO`.

El helper de vencimiento solo acepta códigos `IT-VENCE-%`; sus pruebas son
transaccionales y revierten los registros. El helper de restauración únicamente
crea `reservasScouts_restore_test_codex` y se niega a sobrescribir una base
temporal existente. Esa prueba genera una copia real y conserva su auditoría.

Al terminar, retirar los procedimientos auxiliares y la base temporal después
de verificar su nombre y archivos. Seguir el procedimiento de
[db/README.md](../README.md). No ejecutar restauraciones de prueba sobre la base real.
