import path from "node:path";
import { expect, test } from "@playwright/test";
import { getAdminCredentials, loginThroughUi } from "./support/fixtures.js";

test.beforeEach(async ({ page }) => {
  const { email, password } = getAdminCredentials();
  await loginThroughUi(page, email, password);
  await expect(page).toHaveURL(/\/dashboard$/);
  await page.goto("/reservas");
  await expect(page.getByRole("heading", { name: "Reservas", exact: true, level: 1 })).toBeVisible();
  await expect(page.getByText("Cargando reservas...", { exact: true })).toBeHidden();
});

test("desktop shows horizontal sections and navigates without a dropdown", async ({ page }) => {
  const navigation = page.getByRole("navigation", { name: "Navegación principal" });
  for (const width of [1280, 1440]) {
    await page.setViewportSize({ width, height: 960 });
    await expect(navigation).toBeVisible();
    await expect(navigation.getByRole("link")).toHaveCount(8);
    await expect(page.locator(".topbar-dropdown")).toBeHidden();
    expect(await page.locator(".topbar").evaluate((el) => el.scrollWidth <= el.clientWidth)).toBe(true);
  }
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/menu-horizontal-desktop.png") });
  for (const [nombre, ruta] of [["Espacios", "/espacios"], ["Perfiles", "/perfiles"], ["Pagos", "/pagos"], ["Usuarios", "/usuarios"], ["Auditoría", "/auditoria"], ["Respaldos", "/respaldos"], ["Dashboard", "/dashboard"], ["Reservas", "/reservas"]]) {
    await navigation.getByRole("link", { name: nombre, exact: true }).click();
    await expect(page).toHaveURL(new RegExp(`${ruta}$`));
    await expect(navigation.getByRole("link", { name: nombre, exact: true })).toHaveAttribute("aria-current", "page");
  }
});

test("tablet collapses sections and supports keyboard, outside click and resizing", async ({ page }) => {
  await page.setViewportSize({ width: 1024, height: 768 });
  const trigger = page.locator(".topbar-dropdown > summary");
  const navigation = page.getByRole("navigation", { name: "Menú principal" });
  await expect(page.getByRole("navigation", { name: "Navegación principal" })).toBeHidden();
  await expect(navigation).toBeHidden();
  await trigger.click();
  await expect(navigation).toBeVisible();
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/menu-horizontal-tablet.png") });
  await page.keyboard.press("Escape");
  await expect(navigation).toBeHidden();
  await expect(trigger).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(navigation).toBeVisible();
  await page.getByRole("heading", { name: "Reservas", exact: true, level: 1 }).click();
  await expect(navigation).toBeHidden();
  await trigger.click();
  await navigation.getByRole("link", { name: "Espacios", exact: true }).click();
  await expect(page).toHaveURL(/\/espacios$/);
  await expect(navigation).toBeHidden();
  await trigger.click();
  await page.setViewportSize({ width: 1440, height: 960 });
  await expect(page.getByRole("navigation", { name: "Navegación principal" })).toBeVisible();
  await page.setViewportSize({ width: 1024, height: 768 });
  await expect(navigation).toBeHidden();
});
test("mobile dropdown fits the viewport and navigates", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const trigger = page.locator(".topbar-dropdown > summary");
  const navigation = page.getByRole("navigation", { name: "Menú principal" });
  await trigger.click();
  await expect(navigation).toBeVisible();
  const bounds = await navigation.boundingBox();
  expect(bounds.x).toBeGreaterThanOrEqual(0);
  expect(bounds.x + bounds.width).toBeLessThanOrEqual(390);
  await page.screenshot({ path: path.resolve("..", ".docwork/previews/menu-superior-movil.png") });
  await navigation.getByRole("link", { name: "Espacios", exact: true }).click();
  await expect(page).toHaveURL(/\/espacios$/);
  await expect(navigation).toBeHidden();
});
