# Revisión y organización del proyecto

Revisión realizada el 16 de noviembre de 2026. Se mantuvieron las funcionalidades,
los cambios locales, los comprobantes DEMO y el historial de migraciones.
Esta limpieza no ejecuta scripts ni modifica datos de SQL Server.

## Archivos retirados

Se comprobó que no estaban importados o referenciados por la aplicación:

| Archivo anterior | Motivo |
| --- | --- |
| `frontend/src/App.css` | Estilos de la plantilla inicial sin importar. |
| `frontend/src/pages/Page.css` | Hoja genérica anterior sin importar. |
| `frontend/src/components/RechazoPagoDialog.jsx` | Flujo reemplazado por el visor actual; sin consumidores. |
| `frontend/src/components/RechazoPagoDialog.css` | Estilos exclusivos del componente retirado. |
| `frontend/src/assets/react.svg` | Recurso de la plantilla inicial sin uso. |
| `frontend/src/assets/vite.svg` | Recurso de la plantilla inicial sin uso. |
| `frontend/src/assets/hero.png` | Ilustración de la plantilla inicial sin uso. |
| `frontend/public/icons.svg` | Sprite de la plantilla inicial sin uso. |

## Rutas reorganizadas

- Ocho scripts de datos y comprobantes se agruparon en `db/demo/`.
- Dos scripts anteriores se conservaron en `db/legacy/`, con instrucciones
  para distinguirlos de las migraciones vigentes.
- `InformeFinal.md` pasó a `documentacion/informes/InformeFinal.md`.
- `runtime-validation-report.md` pasó a
  `documentacion/informes/validacion-2026-10-06.md`.
- Se actualizaron las rutas operativas, los directorios de salida y las
  referencias de la documentación actual.

## Archivos generados

Las capturas de `.docwork/`, los temporales de `tmp/`, los resultados de
Playwright y los registros de diagnóstico son reproducibles. Se limpian y se
excluyen de Git. Se conservan las dependencias instaladas y las compilaciones
vigentes para no interrumpir los procesos de desarrollo.

## Duplicados y documentación

La comparación SHA-256 no encontró archivos idénticos entre las fuentes,
scripts, recursos y comprobantes útiles revisados. Se mantuvieron los pares de
migraciones `012` y `013`: sus nombres son parecidos, pero sus contenidos y
responsabilidades son diferentes. El orden está en `db/migrations/README.md`.

El README principal estaba vacío y el del frontend todavía describía la
plantilla de Vite. Se sustituyeron por guías del sistema y se agregaron índices
por módulo. Los informes antiguos se conservan como históricos, sin presentarlos
como validaciones actuales.

El título de la pestaña y el idioma HTML identifican ahora a Reservas Scouts.
El favicon de Vite se reemplazó por el símbolo de campamento que ya utiliza la
aplicación.

## Verificación de esta limpieza

- Compilación de producción y ESLint correctos.
- 14 pruebas de interfaz aprobadas con API simulada.
- 17 pruebas del backend aprobadas; las 26 que requieren SQL Server o helpers
  se omitieron expresamente para no modificar la base durante la limpieza.
- Enlaces internos de las guías comprobados y sin referencias rotas.
- Scripts PowerShell y JavaScript movidos comprobados sintácticamente.
- Contenido de los dos informes históricos conservado completo.
