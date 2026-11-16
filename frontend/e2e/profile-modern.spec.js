import { expect, test } from "@playwright/test";
import path from "node:path";

async function cuenta(page, reservas = [], perfil = true) {
  await page.clock.install({ time: new Date("2026-11-16T18:00:00Z") });
  await page.route("**/api/**", route => {
    const pathname = new URL(route.request().url()).pathname;
    const json = pathname.endsWith("/sesion") ? { id: 5, rol: "Usuario", email: "persona@example.com" }
      : pathname === "/api/perfiles/mi-perfil" ? perfil ? [{ idPerfil: 3, nombre: "María Rodríguez Fernández", telefono: "8888 1234", correoContacto: "maria.rodriguez@example.com", direccion: "San José, Costa Rica", tipoPerfil: "Persona" }] : []
      : pathname === "/api/reservas" ? reservas : [];
    return route.fulfill({ json });
  });
}

test("perfil moderno presenta datos propios, pendientes y proximas sin incluir reservas pasadas", async ({ page }) => {
  await cuenta(page, [
    { id: 1, codigo: "PENDIENTE-001", espacio: "Campo Escuela Nacional Iztarú", fechaInicio: "2026-12-01T08:00:00", estado: "PENDIENTE" },
    { id: 2, codigo: "PROXIMA-002", espacio: "Sede Nacional", fechaInicio: "2026-12-02T09:00:00", estado: "APROBADA" },
    { id: 3, codigo: "PASADA-003", espacio: "Sede Nacional", fechaInicio: "2025-10-01T09:00:00", estado: "APROBADA" },
    { id: 4, codigo: "FINALIZADA-004", espacio: "Sede Nacional", fechaInicio: "2025-09-01T09:00:00", estado: "FINALIZADA" }
  ]);
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/mi-perfil");
  await expect(page.getByRole("heading", { name: "María Rodríguez Fernández" })).toBeVisible();
  await expect(page.locator(".mp-stat").first().locator("strong")).toHaveText("4");
  await expect(page.locator(".mi-perfil-reservas")).toContainText("PENDIENTE-001");
  await expect(page.locator(".mp-next")).toContainText("PROXIMA-002");
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/mi-perfil-moderno-desktop.png"), fullPage: true });
  await page.getByRole("tab", { name: /Próximas/ }).click();
  await expect(page.getByRole("tabpanel")).toContainText("PROXIMA-002");
  await expect(page.getByRole("tabpanel")).not.toContainText("PASADA-003");
  await expect(page.getByRole("tabpanel")).not.toContainText("FINALIZADA-004");
  for (const width of [320, 390, 768, 1024]) {
    await page.setViewportSize({ width, height: 844 });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    if (width === 390) await page.screenshot({ path: path.resolve("..", ".docwork/previews/mi-perfil-moderno-movil.png"), fullPage: true });
  }
  await page.getByRole("link", { name: "Ver reserva PROXIMA-002", exact: true }).click();
  await expect(page).toHaveURL(/\/reservas\?codigo=PROXIMA-002$/);
});

test("perfil sin pendientes muestra un estado vacio cuidado", async ({ page }) => {
  await cuenta(page);
  await page.goto("/mi-perfil");
  await expect(page.getByRole("heading", { name: "Todo al día" })).toBeVisible();
  await expect(page.locator(".mp-stat strong")).toHaveText(["0", "0", "0", "0"]);
  await page.getByRole("tab", { name: /Próximas/ }).click();
  await expect(page.getByRole("heading", { name: "Tu próxima aventura te espera" })).toBeVisible();
});

test("una cuenta sin perfil no inventa datos de contacto", async ({ page }) => {
  await cuenta(page, [], false);
  await page.goto("/mi-perfil");
  await expect(page.locator(".mp-incomplete")).toBeVisible();
  await expect(page.locator(".mp-details")).toContainText("persona@example.com");
  await expect(page.locator(".mp-details")).toContainText("Sin registrar");
});
