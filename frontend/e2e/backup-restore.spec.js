import { expect, test } from "@playwright/test";
import path from "node:path";

test("restaura la version seleccionada sin pedir texto y bloquea envios duplicados", async ({ page }) => {
  const copias = ["reservasScouts_20261116_010000_11111111-1111-1111-1111-111111111111.bak", "reservasScouts_20261015_010000_22222222-2222-2222-2222-222222222222.bak"];
  let requestBody;
  let release;
  const wait = new Promise(resolve => { release = resolve; });
  await page.route("**/api/**", async route => {
    const url = new URL(route.request().url());
    if (url.pathname.endsWith("/sesion")) return route.fulfill({ json: { id: 6, rol: "Administrador", email: "admin@example.com" } });
    if (url.pathname.endsWith("/respaldo/restaurar")) {
      requestBody = route.request().postDataJSON();
      await wait;
      return route.fulfill({ json: { ok: true, mensaje: "El respaldo se restauró correctamente." } });
    }
    return route.fulfill({ json: url.pathname === "/api/respaldo" ? copias.map(nombre => ({ nombre, creadoEn: "2026-11-16T01:00:00", bytes: 1000000 })) : [] });
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/respaldos");
  await expect(page.locator(".backup-card input")).toHaveCount(0);
  await page.getByRole("combobox").selectOption(copias[1]);
  await page.getByRole("button", { name: "Restaurar base de datos", exact: true }).click();
  await expect.poll(() => requestBody).toEqual({ nombreArchivo: copias[1] });
  await expect(page.getByRole("combobox")).toBeDisabled();
  await expect(page.getByRole("button", { name: "Procesando…" })).toBeDisabled();
  release();
  await expect(page.getByRole("status")).toHaveText("El respaldo se restauró correctamente.");
  await expect(page.getByRole("dialog", { name: "Base de datos restaurada" })).toBeVisible();
  await expect(page.locator(".resultado-icono svg")).toBeVisible();
  await expect(page.getByRole("combobox")).toHaveValue(copias[1]);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/respaldos-sin-confirmacion.png"), fullPage: true });
  await page.getByRole("button", { name: "Entendido", exact: true }).click();
  await expect(page.getByRole("dialog")).toHaveCount(0);
});

test("una restauracion fallida muestra la ventana roja y permite cerrarla con Escape", async ({ page }) => {
  await page.route("**/api/**", route => {
    const pathname = new URL(route.request().url()).pathname;
    if (pathname.endsWith("/sesion")) return route.fulfill({ json: { id: 6, rol: "Administrador" } });
    if (pathname.endsWith("/restaurar")) return route.fulfill({ status: 503, json: { mensaje: "No se pudo verificar el archivo seleccionado." } });
    return route.fulfill({ json: pathname === "/api/respaldo" ? [{ nombre: "copia-demo.bak", creadoEn: "2026-11-16T01:00:00", bytes: 1000 }] : [] });
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/respaldos");
  await page.getByRole("button", { name: "Restaurar base de datos", exact: true }).click();
  const dialog = page.getByRole("dialog", { name: "No se pudo completar la restauración" });
  await expect(dialog).toBeVisible();
  await expect(dialog).toHaveClass(/resultado-error/);
  await expect(dialog.getByRole("alert")).toHaveText("No se pudo verificar el archivo seleccionado.");
  await dialog.screenshot({ path: path.resolve("..", ".docwork/previews/resultado-restauracion-error.png") });
  await page.keyboard.press("Escape");
  await expect(dialog).toHaveCount(0);
  await expect(page.getByRole("button", { name: "Restaurar base de datos", exact: true })).toBeEnabled();
});

test("el boton de restaurar permanece deshabilitado sin versiones disponibles", async ({ page }) => {
  await page.route("**/api/**", route => route.fulfill({ json: route.request().url().endsWith("/sesion") ? { id: 6, rol: "Administrador" } : [] }));
  await page.goto("/respaldos");
  await expect(page.getByText("No hay copias creadas desde esta aplicación.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Restaurar base de datos", exact: true })).toBeDisabled();
});

test("perfiles muestra los usuarios registrados recibidos de la base", async ({ page }) => {
  let query;
  await page.route("**/api/**", route => {
    const url = new URL(route.request().url());
    if (url.pathname.endsWith("/sesion")) return route.fulfill({ json: { id: 6, rol: "Administrador", email: "admin@example.com" } });
    if (url.pathname === "/api/perfiles") {
      query = url.searchParams.get("soloRegistrados");
      return route.fulfill({ json: [{ idPerfil: 3, usuarioId: 5, nombre: "Persona registrada Demo", correoContacto: "demo@example.com", telefono: "88881111", tipoPerfil: "Persona" }] });
    }
    return route.fulfill({ json: [] });
  });
  await page.goto("/perfiles");
  await expect(page.locator(".perfiles-table")).toContainText("Persona registrada Demo");
  expect(query).toBe("true");
});
