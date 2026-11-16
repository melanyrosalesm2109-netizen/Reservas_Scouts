import { expect, test } from "@playwright/test";
import path from "node:path";

const screens = [[320, 568], [360, 800], [390, 844], [640, 360], [768, 1024], [1024, 768], [1280, 800], [1920, 1080], [2560, 1440]];

test.beforeEach(async ({ page }) => {
  await page.route("**/api/**", route => {
    const url = new URL(route.request().url());
    let data = [];
    if (url.pathname.endsWith("/sesion")) data = { id: 1, rol: "Administrador", email: "administrador-con-correo-largo@example.com" };
    if (url.pathname === "/api/pagos") data = [{ id: 1, reservaId: 1, reservaCodigo: "RES-2026-000001", espacio: "Espacio con nombre extenso para actividades y campamentos", monto: 1250000, metodo: "Efectivo", fechaPago: "2026-12-10", estado: "PENDIENTE" }];
    if (url.pathname.endsWith("/cobros-disponibles")) data = [{ reservaId: 2, codigo: "RES-2026-000002", solicitante: "Solicitante con nombre extenso", saldo: 1250000 }];
    return route.fulfill({ json: data });
  });
});

test("administration fits narrow, landscape, tablet and large viewports", async ({ page }) => {
  test.setTimeout(120000);
  const errors = [];
  page.on("pageerror", error => errors.push(error.message));
  for (const route of ["dashboard", "reservas", "espacios", "perfiles", "pagos", "usuarios", "auditoria", "respaldos", "notificaciones"]) {
    await page.goto(`/${route}`);
    await expect(page.locator(".main-content h1").first()).toBeVisible();
    for (const [width, height] of screens) {
      await page.setViewportSize({ width, height });
      await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), { message: `${route} at ${width}x${height}` }).toBe(true);
      if (route === "pagos" && width <= 640) {
        const cell = page.locator(".pagos-table tbody td").first();
        await expect(cell).toHaveAttribute("data-column", "Reserva / espacio");
        expect(await cell.evaluate(el => getComputedStyle(el).display)).toBe("grid");
      }
      if ([390, 1280].includes(width)) await page.screenshot({ path: path.resolve("..", `.docwork/previews/revision-${route}-${width}.png`), fullPage: true });
    }
  }
  expect(errors).toEqual([]);
});

test("payment form stays usable on small and short screens", async ({ page }) => {
  await page.goto("/pagos");
  for (const [width, height] of screens.slice(0, 6)) {
    await page.setViewportSize({ width, height });
    await page.locator(".pagos-header").getByRole("button", { name: "Registrar cobro", exact: true }).click();
    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await expect(page.locator("#cobro-reserva")).toBeVisible();
    const box = await dialog.boundingBox();
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.y).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(width);
    expect(box.y + box.height).toBeLessThanOrEqual(height);
    expect(await dialog.evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
    await dialog.getByRole("button", { name: "Cancelar", exact: true }).click();
  }
});

test("public access and navigation remain reachable at each screen size", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ status: 401, json: {} }));
  await page.goto("/login");
  for (const [width, height] of screens) {
    await page.setViewportSize({ width, height });
    await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await page.getByRole("link", { name: "Iniciar sesión", exact: true }).click();
    const dialog = page.locator(".public-auth-dialog");
    await expect(dialog).toBeVisible();
    const box = await dialog.boundingBox();
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.y).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(width);
    expect(box.y + box.height).toBeLessThanOrEqual(height);
    await page.keyboard.press("Escape");
  }
});

test("community year is centered and colors stay consistent with OS appearance", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ status: 401, json: {} }));
  for (const colorScheme of ["light", "dark"]) {
    await page.emulateMedia({ colorScheme, reducedMotion: "reduce" });
    await page.goto("/login");
    expect(await page.evaluate(() => getComputedStyle(document.documentElement).colorScheme)).toBe("light");
    for (const width of [320, 390, 768, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      const community = page.locator(".public-community");
      const footer = page.locator(".public-footer");
      await expect(footer).toHaveText("© 2026");
      await expect(page.getByRole("link", { name: /Volver arriba/ })).toHaveCount(0);
      await community.scrollIntoViewIfNeeded();
      const box = await footer.boundingBox();
      expect(Math.abs(box.x + box.width / 2 - width / 2)).toBeLessThan(2);
      await page.screenshot({ path: path.resolve("..", `.docwork/previews/revision-comunidad-${colorScheme}-${width}.png`) });
      await page.getByRole("link", { name: "Iniciar sesión", exact: true }).click();
      await page.locator(".public-auth-dialog").screenshot({ path: path.resolve("..", `.docwork/previews/revision-acceso-${colorScheme}-${width}.png`) });
      await page.keyboard.press("Escape");
    }
  }
});

test("welcome navigation marks the section and mobile menu closes with Escape", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ status: 401, json: {} }));
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto("/login");
  const desktop = page.getByRole("navigation", { name: "Navegación de bienvenida" });
  await desktop.getByRole("link", { name: "Espacios" }).click();
  await expect(desktop.getByRole("link", { name: "Espacios" })).toHaveAttribute("aria-current", "location");
  await page.evaluate(() => scrollTo(0, 0));
  await page.locator(".public-header").screenshot({ path: path.resolve("..", ".docwork/previews/menu-moderno-desktop.png") });
  for (const width of [320, 390, 768]) {
    await page.setViewportSize({ width, height: 844 });
    await page.locator(".public-mobile-menu summary").click();
    const nav = page.getByRole("navigation", { name: "Menú de bienvenida" });
    await expect(nav).toBeVisible();
    const box = await nav.boundingBox();
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(width);
    await page.screenshot({ path: path.resolve("..", `.docwork/previews/menu-moderno-${width}.png`) });
    await page.keyboard.press("Escape");
    await expect(nav).toBeHidden();
  }
});
