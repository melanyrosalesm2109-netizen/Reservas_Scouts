import path from "node:path";
import { expect, test } from "@playwright/test";
import { createAdminApi, createReservationFixture, cleanupReservationFixture, getAdminCredentials } from "./support/fixtures.js";

async function fits(page) {
  await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
}
const widths = [320, 390, 768, 1024, 1280, 1440];

test("public footer is continuous and login adapts to every screen", async ({ page }) => {
  test.setTimeout(90000);
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/login");
  const colors = await page.evaluate(() => [".public-community", ".public-footer"].map(selector => getComputedStyle(document.querySelector(selector)).backgroundColor));
  expect(colors[0]).toBe(colors[1]);
  for (const width of widths) {
    await page.setViewportSize({ width, height: 900 });
    await fits(page);
    await page.getByRole("link", { name: "Iniciar sesión", exact: true }).click();
    const dialog = page.locator(".public-auth-dialog");
    await expect(dialog).toBeVisible();
    const box = await dialog.boundingBox();
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(width);
    await page.keyboard.press("Escape");
    await page.evaluate(() => scrollTo(0, document.body.scrollHeight));
    if ([390, 1440].includes(width)) await page.screenshot({ path: path.resolve("..", `.docwork/previews/pie-integrado-${width}.png`) });
  }
});

test("all administration pages fit desktop, tablet and mobile with labelled table cards", async ({ page }) => {
  test.setTimeout(180000);
  const login = await page.request.post("http://localhost:8080/api/usuarios/login", { data: getAdminCredentials() });
  expect(login.ok()).toBe(true);
  await page.emulateMedia({ reducedMotion: "reduce" });
  for (const route of ["dashboard", "reservas", "espacios", "perfiles", "pagos", "usuarios", "auditoria", "respaldos", "notificaciones"]) {
    await page.goto(`/${route}`);
    await expect(page.locator(".main-content h1").first()).toBeVisible();
    await expect(page.locator(".main-content").getByText(/^Cargando/).first()).toBeHidden();
    for (const width of widths) {
      await page.setViewportSize({ width, height: 900 });
      await fits(page);
      await page.evaluate(() => scrollTo(0,0));
      if (width === 390 && await page.locator(".responsive-data-table tbody td[data-column]").count()) {
        const cell = page.locator(".responsive-data-table tbody td[data-column]").first();
        expect(await cell.evaluate(el => getComputedStyle(el, "::before").content)).not.toBe('""');
        expect(await cell.evaluate(el => getComputedStyle(el).display)).toBe("grid");
      }
      if ([390, 1440].includes(width)) await page.screenshot({ path: path.resolve("..", `.docwork/previews/adaptable-${route}-${width}.png`) });
      if (width === 390 && await page.locator(".responsive-data-table tbody tr").count()) {
        await page.locator(".responsive-data-table tbody tr").first().scrollIntoViewIfNeeded();
        await page.screenshot({ path: path.resolve("..", `.docwork/previews/tarjetas-${route}-movil.png`) });
      }
    }
  }
});

test("create forms remain within mobile screen and controls stay reachable", async ({ page }) => {
  test.setTimeout(90000);
  expect((await page.request.post("http://localhost:8080/api/usuarios/login", { data: getAdminCredentials() })).ok()).toBe(true);
  await page.setViewportSize({ width: 390, height: 844 });
  for (const [route, button, modal] of [["espacios", "Nuevo espacio", ".espacio-modal"], ["usuarios", "Nuevo usuario", ".usuario-modal"], ["pagos", "Registrar cobro", ".pago-gestion-dialog"], ["reservas", "Nueva reserva", ".reservation-modal"]]) {
    await page.goto(`/${route}`);
    await page.locator(`.${route}-header`).getByRole("button", { name: button, exact: true }).click();
    const dialog = page.locator(modal);
    await expect(dialog).toBeVisible();
    const box = await dialog.boundingBox();
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(390);
    expect(await dialog.evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
    for (const input of await dialog.locator("input:not([type=hidden]),select,textarea").all()) {
      if (await input.isVisible()) expect(await input.evaluate(el => parseFloat(getComputedStyle(el).fontSize))).toBeGreaterThanOrEqual(16);
    }
    await dialog.getByRole("button", { name: "Cancelar", exact: true }).click();
    await expect(dialog).toBeHidden();
  }
});


test("registered user's pages adapt without exposing staff screens", async ({ page }) => {
  test.setTimeout(90000);
  const api = await createAdminApi();
  const fixture = {};
  try {
    await createReservationFixture(api, fixture);
    expect((await page.request.post("http://localhost:8080/api/usuarios/login", { data: { email: fixture.email, password: fixture.password } })).ok()).toBe(true);
    for (const route of ["mi-perfil", "reservas", "espacios"]) {
      await page.goto("/" + route);
      await expect(page.locator(".main-content h1").first()).toBeVisible();
      for (const width of widths) {
        await page.setViewportSize({ width, height: 900 });
        await fits(page);
      }
      if (route === "mi-perfil") {
        await page.setViewportSize({ width: 390, height: 844 });
        await page.screenshot({ path: path.resolve("..", ".docwork/previews/adaptable-mi-perfil-390.png") });
      }
    }
    await expect(page.locator(".topbar-links a[href='/usuarios']")).toHaveCount(0);
  } finally {
    await cleanupReservationFixture(api, fixture);
    await api.dispose();
  }
});
