# Pruebas de navegador · Playwright

La carpeta incluye pruebas con API simulada y pruebas de integración que usan
el backend y SQL Server. No requieren la misma preparación.

## Interfaz con API simulada

Estos ejemplos comprueban pantallas, cálculos, navegación y adaptación a
celular sin modificar la base de datos:

```powershell
cd frontend
npx playwright test e2e/dashboard-charts.spec.js e2e/profile-modern.spec.js e2e/backup-restore.spec.js e2e/cash-reservation-policy.spec.js
```

Playwright inicia Vite en `http://localhost:5173` o reutiliza el servidor activo.
El navegador se configura en `playwright.config.js`: Chrome o Edge instalado,
con posibilidad de definir `PLAYWRIGHT_CHANNEL`.

## Integración con la API y SQL Server

1. Preparar SQL Server y las migraciones actuales según [db/README.md](../../db/README.md).
2. Iniciar el backend en `http://localhost:8080` con sus variables de entorno.
3. Definir `E2E_ADMIN_PASSWORD` en el proceso de pruebas. Opcionalmente definir
   `E2E_ADMIN_EMAIL`; el valor predeterminado es `admin@reservasscouts.com`.
4. Ejecutar desde `frontend/`:

```powershell
$env:E2E_ADMIN_PASSWORD = '<contraseña local de pruebas>'
npm run test:e2e
```

La suite completa contiene recorridos que crean cuentas, perfiles, espacios y
reservas y luego limpian sus fixtures. La auditoría se conserva. Ejecutar estos
recorridos únicamente sobre una base local de pruebas.

Las pruebas de restauración SQL tienen preparación y activación adicionales;
consultar [db/tests/README.md](../../db/tests/README.md).

## Resultados

- `frontend/test-results/`: trazas y diagnósticos de ejecución.
- `frontend/playwright-report/`: informe HTML cuando se solicita.
- `.docwork/previews/`: capturas reproducibles para revisar el diseño.

Estas carpetas están excluidas de Git y se pueden regenerar. Los comprobantes
ficticios utilizados por algunas pruebas viven en [output/](../../output/README.md)
y se conservan como recursos del proyecto.