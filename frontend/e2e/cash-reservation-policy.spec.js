import { expect, test } from "@playwright/test";
import path from "node:path";

test("el usuario ve el cupo guardado, el plazo del efectivo y las reservas vencidas", async ({ page }) => {
  await page.clock.install({ time: new Date("2026-11-16T18:00:00Z") });
  const reservas = [
    { id: 31, espacioId: 4, codigo: "EFECTIVO-PENDIENTE", espacio: "Campo Demo", solicitante: "Persona Demo", responsable: "Persona Demo", participantes: 1, estado: "PENDIENTE", metodoPagoPendiente: "Efectivo", pagoVenceEn: "2026-12-01T10:00:00", fechaInicio: "2026-12-01T08:00:00", fechaFin: "2026-12-01T12:00:00" },
    { id: 32, espacioId: 4, codigo: "EFECTIVO-VENCIDO", espacio: "Campo Demo", solicitante: "Persona Demo", responsable: "Persona Demo", participantes: 1, estado: "VENCIDA", fechaInicio: "2026-11-10T08:00:00", fechaFin: "2026-11-10T12:00:00" }
  ];
  await page.route("**/api/**", route => {
    const pathname = new URL(route.request().url()).pathname;
    const json = pathname.endsWith("/sesion") ? { id: 5, rol: "Usuario", email: "demo@example.com" }
      : pathname === "/api/reservas" ? reservas
      : pathname === "/api/espacios" ? [{ id: 4, nombre: "Campo Demo", estado: "DISPONIBLE", capacidad: 40, costo: 25000 }]
      : pathname === "/api/perfiles/opciones-reserva" || pathname === "/api/perfiles/mi-perfil" ? [{ idPerfil: 3, usuarioId: 5, nombre: "Persona Demo", correoContacto: "demo@example.com", tipoPerfil: "Persona" }] : [];
    return route.fulfill({ json });
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/reservas");
  await expect(page.getByText("Pendiente de efectivo", { exact: true })).toBeVisible();
  await expect(page.getByText(/Cupo guardado · Pagar antes/)).toHaveCount(1);
  await expect(page.getByText("Plazo vencido · cupo liberado", { exact: true })).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/reserva-efectivo-pendiente-vencida.png"), fullPage: true });
  await page.goto("/mi-perfil");
  await expect(page.getByRole("tabpanel")).toContainText("Pendiente de efectivo · cupo guardado");
  await expect(page.getByRole("tabpanel")).toContainText("Pagar antes de");
  await expect(page.getByRole("tabpanel")).not.toContainText("EFECTIVO-VENCIDO");
});
