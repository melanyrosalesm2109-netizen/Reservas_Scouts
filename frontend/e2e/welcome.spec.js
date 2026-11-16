import path from "node:path";
import { expect, test } from "@playwright/test";

test("welcome page adapts, navigates and preserves login and registration", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: /Las mejores/ })).toBeVisible();
  const next = page.getByRole("button", { name: "Siguiente imagen", exact: true });
  await next.click();
  await expect(page.locator(".public-photo-caption h2")).toHaveText("Encuentros con propósito");
  await page.getByRole("button", { name: "Imagen anterior", exact: true }).click();
  await expect(page.locator(".public-photo-caption h2")).toHaveText("Aventuras que nos conectan");
  for (const [width, label] of [[1440, "desktop"], [820, "tablet"], [390, "movil"], [320, "compacto"]]) {
    await page.setViewportSize({ width, height: 1000 });
    await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await page.locator(".public-community").scrollIntoViewIfNeeded();
    await expect.poll(() => page.locator(".public-login img").evaluateAll(imgs => imgs.every(img => img.complete && img.naturalWidth > 0))).toBe(true);
    await page.evaluate(() => scrollTo(0,0));
    if (label === "desktop") await page.screenshot({ path: path.resolve("..", ".docwork/previews/bienvenida-portada.png") });
    await page.screenshot({ path: path.resolve("..", `.docwork/previews/bienvenida-${label}.png`), fullPage: true });
  }
  await expect(page.getByText("Organizar un encuentro", { exact: false })).toHaveCount(0);
  await page.setViewportSize({ width: 1440, height: 960 });
  await page.getByRole("link", { name: "Ya tengo una cuenta" }).click();
  await expect(page.getByRole("dialog", { name: "Acceso a Reservas Scouts" })).toBeVisible();
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/acceso-ventana-desktop.png") });
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).toBeHidden();
  await expect(page.getByRole("link", { name: "Ya tengo una cuenta" })).toBeFocused();
  await page.setViewportSize({ width: 390, height: 844 });
  await page.locator(".public-mobile-menu summary").click();
  await expect(page.getByRole("navigation", { name: "Menú de bienvenida" })).toBeVisible();
  await page.getByRole("navigation", { name: "Menú de bienvenida" }).getByRole("link", { name: "Espacios", exact: true }).click();
  await expect(page.locator(".public-mobile-menu")).not.toHaveAttribute("open", "");
  await expect(page).toHaveURL(/#lugares$/);
  await page.getByRole("link", { name: "Iniciar sesión", exact: true }).click();
  await expect(page.getByPlaceholder("Ingrese su usuario o correo")).toBeInViewport();
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/acceso-ventana-movil.png") });
  await page.getByRole("button", { name: "Crear cuenta", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Crear cuenta", exact: true })).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/registro-movil.png"), fullPage: true });
  await page.getByRole("button", { name: "Volver al inicio de sesión" }).click();
  await expect(page.getByPlaceholder("Ingrese su contraseña")).toBeVisible();
  await page.getByRole("button", { name: "Cerrar inicio de sesión" }).click();
  await expect(page.getByRole("dialog")).toBeHidden();
});
