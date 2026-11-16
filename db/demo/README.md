# Datos y comprobantes de demostración

Scripts opcionales para una base local de demostración. No forman parte de
las migraciones y no deben ejecutarse automáticamente al iniciar la aplicación.
Todos los comandos siguientes se ejecutan desde la raíz del proyecto.

| Archivo | Propósito |
| --- | --- |
| `datos.sql` | Datos base de demostración. |
| `demo_comportamiento.sql` | Casos de reservas y comportamiento del sistema. |
| `demo_actualizado.sql` | Escenarios históricos `DEMO-FLUJO-*`. |
| `demo_revision_comprobantes.sql` | Casos `DEMO-COMP-*` de SINPE y transferencia. |
| `demo_comprobantes.ps1` | Genera y guarda comprobantes PNG ficticios ausentes. |
| `demo_validar_comprobantes.sql` | Revisa los casos DEMO mediante el flujo de pagos. |
| `generar_pdfs_demo.cjs` | Genera los PDF ficticios de `output/pdf/`. |
| `adjuntar_comprobantes_ia.ps1` | Adjunta los recursos de `output/` a pagos DEMO. |

## Ejemplos del flujo actual

Con los datos base DEMO ya instalados y las migraciones aplicadas:

```powershell
sqlcmd -S localhost -E -C -I -b -f 65001 -i db/demo/demo_revision_comprobantes.sql
powershell -NoProfile -File db/demo/demo_comprobantes.ps1 -SoloRevision
sqlcmd -S localhost -E -C -I -b -f 65001 -i db/demo/demo_validar_comprobantes.sql
```

Los archivos generados no representan pagos reales. La generación de PDF
requiere las dependencias del frontend y un navegador instalado:

```powershell
node db/demo/generar_pdfs_demo.cjs
```

Los scripts anteriores con fechas de ejemplo fijas se conservan como escenarios
históricos. Revisar su contenido y las instrucciones de [db/README.md](../README.md)
antes de utilizarlos. Mover estos archivos no ejecuta ninguna operación sobre SQL Server.
