# Playwright E2E

These browser tests exercise the local React app and Spring API against the SQL Server database configured for development.

## Prerequisites

- Start SQL Server and apply `db/migrations/001_cumplimiento.sql`.
- Start the backend on `http://localhost:8080` with the local database credentials loaded in its process environment.
- Set `E2E_ADMIN_PASSWORD` in the test process. `E2E_ADMIN_EMAIL` defaults to `admin@reservasscouts.com`.
- Install project dependencies with `npm install`. The test runner launches Vite when it is not already available at `http://localhost:5173`.
- The Playwright config uses the installed Google Chrome channel by default. Set `PLAYWRIGHT_CHANNEL` to another Playwright-supported installed browser when needed.

## Run

From `frontend/`:

```powershell
$env:E2E_ADMIN_PASSWORD = '<local admin password>'
npm run test:e2e
```

The reservation journey creates a uniquely named user, profile, space, and reservation through the application, then removes those records in teardown. Authentication and database audit entries are intentionally retained by the audit trail. Do not run this suite against production data.

## Coverage

- Invalid login, successful admin login, persisted server session, logout, and protected-route rejection.
- Anonymous and regular-user API authorization, regular-user reservation creation, database read-back, and session-derived creator identity.
- Admin-only audit and backup screens plus persistence of login audit and backup-catalog data.
