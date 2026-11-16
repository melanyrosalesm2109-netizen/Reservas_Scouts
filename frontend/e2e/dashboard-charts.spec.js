import { expect, test } from "@playwright/test";
import path from "node:path";

test("las graficas calculan los datos reales y cambian de periodo sin contar pagos rechazados", async ({ page }) => {
  await page.clock.install({ time: new Date("2026-11-16T18:00:00Z") });
  const reservas = [
    { id: 1, espacioId: 1, espacio: "Campo Escuela Iztarú", codigo: "PROXIMA", solicitante: "Grupo Scout", fechaInicio: "2026-11-20T08:00:00", estado: "APROBADA" },
    { id: 2, espacioId: 2, espacio: "Sede Nacional", codigo: "PASADA", fechaInicio: "2026-10-10T08:00:00", estado: "PENDIENTE" },
    { id: 3, espacioId: 1, espacio: "Campo Escuela Iztarú", codigo: "CANCELADA", fechaInicio: "2026-11-21T08:00:00", estado: "CANCELADA" },
    { id: 4, espacioId: 1, espacio: "Campo Escuela Iztarú", codigo: "ANTIGUA", fechaInicio: "2024-05-10T08:00:00", estado: "FINALIZADA" },
    { id: 5, espacioId: 2, espacio: "Sede Nacional", codigo: "ENERO", fechaInicio: "2026-01-10T08:00:00", estado: "FINALIZADA" }
  ];
  const pagos = [
    { estado: "PAGADO", monto: 10000, fechaPago: "2026-11-15" },
    { estado: "PAGADO", monto: 20000, fechaPago: "2026-10-10" },
    { estado: "PAGADO", monto: 5000, fechaPago: "2026-01-10" },
    { estado: "RECHAZADO", monto: 999999, fechaPago: "2026-11-15" },
    { estado: "ANULADO", monto: 999999, fechaPago: "2026-11-15" },
    { estado: "PENDIENTE", monto: 999999, fechaPago: "2026-11-15" }
  ];
  await page.route("**/api/**", route => {
    const pathname = new URL(route.request().url()).pathname;
    const data = pathname.endsWith("/sesion") ? { id: 1, rol: "Administrador", email: "admin@example.com" }
      : pathname === "/api/reservas" ? reservas : pathname === "/api/pagos" ? pagos
      : pathname === "/api/espacios" ? [{ id: 1, nombre: "Campo Escuela Iztarú", estado: "DISPONIBLE" }, { id: 2, nombre: "Sede Nacional", estado: "DISPONIBLE" }]
      : pathname === "/api/perfiles" ? [{ idPerfil: 1 }, { idPerfil: 2 }] : [];
    return route.fulfill({ json: data });
  });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/dashboard");
  await expect(page.locator(".db-stat").first().locator("strong")).toHaveText("5");
  await expect(page.locator(".db-chart-total strong")).toHaveText("3");
  await expect(page.locator(".db-upcoming")).toContainText("PROXIMA");
  await expect(page.locator(".db-upcoming")).not.toContainText("PASADA");
  await expect(page.locator(".db-upcoming")).not.toContainText("CANCELADA");
  await expect(page.locator(".db-donut")).toHaveAttribute("aria-label", /Finalizadas: 2/);
  await page.getByRole("button", { name: "Ingresos", exact: true }).click();
  await expect(page.locator(".db-chart-total strong")).toHaveText((30000).toLocaleString("es-CR", { style: "currency", currency: "CRC", maximumFractionDigits: 0 }));
  await page.getByLabel("Periodo de la gráfica").selectOption("12");
  await expect(page.locator(".db-chart-total strong")).toHaveText((35000).toLocaleString("es-CR", { style: "currency", currency: "CRC", maximumFractionDigits: 0 }));
  await expect(page.locator(".db-chart rect[tabindex]")).toHaveCount(12);
  await page.getByRole("button", { name: "Reservas", exact: true }).click();
  await expect(page.locator(".db-chart-total strong")).toHaveText("4");
  await page.getByLabel("Periodo de la gráfica").selectOption("6");
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/dashboard-moderno-desktop.png"), fullPage: true });
  for (const width of [320, 390, 768, 1024]) {
    await page.setViewportSize({ width, height: 844 });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    if (width === 390) await page.screenshot({ path: path.resolve("..", ".docwork/previews/dashboard-moderno-movil.png"), fullPage: true });
  }
});
