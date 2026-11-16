# Reservas Scouts

Sistema de reservas para Guías y Scouts de Costa Rica. Permite consultar
espacios y horarios, registrar reservas y pagos, revisar comprobantes y
administrar perfiles, auditoría y respaldos.

## Organización

| Ruta | Propósito |
| --- | --- |
| [frontend/](frontend/README.md) | Interfaz React, recursos públicos y pruebas de navegador. |
| [backend/](backend/README.md) | API Spring Boot, reglas de negocio y pruebas Java. |
| [db/](db/README.md) | Instalador, migraciones, demostraciones y pruebas SQL. |
| [documentacion/](documentacion/README.md) | Guías, decisiones e informes históricos. |
| [output/](output/README.md) | Comprobantes ficticios utilizados por las demostraciones. |

El backend organiza sus clases por responsabilidad; el frontend separa
pantallas, componentes, servicios, contexto y estilos. Los archivos generados
por herramientas se excluyen del control de versiones.

## Iniciar el sistema

Requisitos: Java 21, Node.js con npm, SQL Server y un navegador compatible.

1. Preparar SQL Server y la base según [db/README.md](db/README.md). Usar el
   instalador solo para una base nueva; para una existente, seguir el
   [orden de migraciones](db/migrations/README.md).
2. Configurar las variables de entorno indicadas en [backend/README.md](backend/README.md).
3. Iniciar la API en una terminal:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

4. Iniciar la interfaz en otra terminal, desde la raíz:

```powershell
cd frontend
npm ci
npm run dev
```

Abrir `http://localhost:5173`. La API local utiliza `http://localhost:8080`.
Para otro servidor, consultar [frontend/.env.example](frontend/.env.example).

## Reglas principales

- Los usuarios consultan su perfil y sus propias reservas. Administración y
  recepción disponen de las funciones que corresponden a su rol.
- El efectivo pendiente conserva el cupo; la reserva se aprueba al confirmar
  el pago completo. El plazo se muestra en la solicitud y en Mis reservas.
- SINPE y transferencia conservan el comprobante y la revisión. Un comprobante
  enviado mantiene el cupo mientras espera revisión del personal.
- Las reservas sin pago ni comprobante vencen según la política configurada,
  liberando el espacio y conservando auditoría.
- Eliminar una reserva conserva su archivo, pagos y revisiones. La auditoría
  de respaldos se guarda fuera de la base restaurada para conservarla.

## Comprobaciones

Desde `frontend/`:

```powershell
npm run lint
npm run build
```

Desde `backend/`:

```powershell
.\mvnw.cmd test
```

Las pruebas que requieren SQL Server, credenciales o helpers se activan
explícitamente. Consultar [pruebas de navegador](frontend/e2e/README.md) y
[pruebas SQL](db/tests/README.md) antes de ejecutarlas.

## Archivos de trabajo

`node_modules/`, `target/` y `dist/` son dependencias o resultados de compilación.
`tmp/`, `.docwork/`, los registros `.log` y los resultados de Playwright son
temporales. No deben subirse al repositorio. Los comprobantes de `output/`
son recursos DEMO referenciados por scripts y pruebas; se conservan.

Consultar el [registro de organización](documentacion/Organizacion-del-proyecto.md)
para conocer los archivos retirados y las rutas reorganizadas.
