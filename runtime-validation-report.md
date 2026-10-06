# Runtime Validation Report

**Generated**: 2026-10-06T17:18:00-06:00
**Target**: `E:\Proyecto AdmBD\Reservas_Scouts`

## Summary

| Step | Status | Exit Code | Details |
|------|--------|-----------|---------|
| Startup | PASS | n/a | The backend was already running; `GET http://localhost:8080/api/usuarios/sesion` without a session returned the expected HTTP 401. Playwright started/reused the Vite server at `http://localhost:5173`; startup duration was not measured. |
| Backend tests | PASS | 0 | `mvn test -q`: 8 tests, 0 failures, 0 errors, 0 skipped. |
| Frontend lint | PASS | 0 | `npm run lint`. |
| Frontend build | PASS | 0 | `npm run build`; Vite generated production assets. |
| E2E tests | PASS | 0 | `npm run test:e2e`: 3 passed, 0 failed. |
| Standalone integration tier | UNVERIFIED | n/a | No separate backend integration-test suite was run. The browser E2E journeys exercised the running application with the local SQL Server database. |

**Overall**: NEEDS_SIGNOFF — the automated browser journeys and build checks pass; a valid restore against a disposable database and any cloud-hosting requirements remain unverified.

## Environment

- **Docker**: UNAVAILABLE — the Docker CLI/daemon was unavailable in this environment; no containerized infrastructure was started.
- **Node.js**: AVAILABLE — v24.14.0.
- **Playwright**: AVAILABLE — Playwright 1.63.0 ran headlessly with the installed Chrome channel; no browser download was needed.
- **Database**: SQL Server 2025 at `localhost:1433`, database `reservasScouts`. E2E tests used this existing local instance, not an in-memory substitute.
- **Browser tier**: PRIMARY (Playwright).
- **Infrastructure tier**: Existing local SQL Server; no isolated Docker database. This leaves containerized/clean-database fidelity unverified.

## E2E Journeys

| Spec | Journey | Result |
|------|---------|--------|
| `frontend/e2e/authentication.spec.js` | Reject invalid credentials; log in with valid administrator credentials; verify session persistence and logout/protected-route behavior. | PASS |
| `frontend/e2e/admin-audit-backup.spec.js` | Log in as administrator; verify persisted login audit and the available/empty backup catalog across reloads. | PASS |
| `frontend/e2e/reservations.spec.js` | Verify anonymous rejection and user role restrictions; create a reservation through the UI; read it back through the UI and API; clean up temporary records. | PASS |

The administrator password was provided to the test process through `E2E_ADMIN_PASSWORD`; it was not written to the repository or test artifacts.

## Issues Found and Corrected

- Repository result-set mappers used snake_case labels for fields that the SQL Server procedures return in camelCase (`createdAt`, `updatedAt`, `rolId`, `fechaInicio`, and related names). The mappings were aligned with the stored-procedure result columns.
- The audit E2E locator matched both `LOGIN` and `LOGIN_FALLIDO`; it now selects the exact `LOGIN` cell.
- The backup-catalog assertion treated an `<option>` as visible text; it now checks the visible selector or the explicit empty state.
- Reservation form selectors were scoped to the modal form to avoid matching duplicate filter controls.
- Migration `001_cumplimiento.sql` now defines `paRolFiltrar` with the schema's `createdAt` column and can be rerun safely.

## Remaining Gaps

- Do not run a valid restore against the active database. Verify restore only with explicit authorization against a disposable database/copy.
- No Docker-based database integration tier was run; E2E used the installed local SQL Server.
- Cloud deployment was not attempted because the target platform and environment have not been selected.
