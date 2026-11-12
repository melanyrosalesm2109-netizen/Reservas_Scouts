import path from "node:path";
import { expect, test } from "@playwright/test";
import { getAdminCredentials, loginThroughUi } from "./support/fixtures.js";

test("space catalogue loads demo records, filters, edits and adapts to devices", async ({ page }) => {
  const { email, password } = getAdminCredentials();
  await loginThroughUi(page, email, password);
  await expect(page).toHaveURL(/\/dashboard$/);
  await page.goto("/espacios");
  await expect(page.getByText("Cargando espacios...", { exact: true })).toBeHidden();
  const cards = page.locator(".espacio-card");
  await expect(cards).toHaveCount(8);
  for (const name of ["Campo Escuela Nacional Iztarú", "Campo Escuela Nacional Yörí", "Sede Nacional", "Centro de Atención Alajuela", "Centro de Atención Cartago", "Centro de Atención San José Casa Guía"]) {
    const card = cards.filter({ has: page.getByRole("heading", { name, exact: true }) });
    await expect(card).toHaveCount(1);
    await expect(card.getByText("Capacidad y tarifa de demostración", { exact: true })).toHaveCount(0);
  }
  const firstImage = cards.first().locator("img");
  const originalImage = await firstImage.getAttribute("src");
  await cards.first().getByRole("button", { name: /^Siguiente imagen/ }).click();
  await expect(firstImage).not.toHaveAttribute("src", originalImage);
  await cards.first().getByRole("button", { name: /^Imagen anterior/ }).click();
  await expect(firstImage).toHaveAttribute("src", originalImage);
  await expect(page.getByText("Imagen ilustrativa · IA", { exact: true })).toHaveCount(0);
  for (const [width, columns, label] of [[1440, 4, "desktop"], [820, 2, "tablet"], [390, 1, "movil"]]) {
    await page.setViewportSize({ width, height: 1000 });
    expect(await page.locator(".espacios-catalogo").evaluate(el => getComputedStyle(el).gridTemplateColumns.split(" ").length)).toBe(columns);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await cards.last().scrollIntoViewIfNeeded();
    await expect.poll(() => cards.locator("img").evaluateAll(imgs => imgs.every(img => img.complete && img.naturalWidth > 0))).toBe(true);
    await page.evaluate(() => scrollTo(0, 0));
    await page.screenshot({ path: path.resolve("..", `.docwork/previews/espacios-${label}.png`), fullPage: true });
  }
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.getByPlaceholder("Nombre del espacio...").fill("Iztarú");
  await page.getByRole("button", { name: "Buscar", exact: true }).click();
  await expect(cards).toHaveCount(1);
  await expect(cards.getByRole("heading")).toHaveText("Campo Escuela Nacional Iztarú");
  await page.getByRole("button", { name: "Editar Campo Escuela Nacional Iztarú", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Editar espacio", exact: true })).toBeVisible();
  await expect(page.locator('.espacio-modal input[name="nombre"]')).toHaveValue("Campo Escuela Nacional Iztarú");
  await page.getByRole("button", { name: "Cancelar", exact: true }).click();
  await page.getByPlaceholder("Nombre del espacio...").fill("sin-coincidencias-zz");
  await page.getByRole("button", { name: "Buscar", exact: true }).click();
  await expect(page.getByText("No se encontraron espacios", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Limpiar", exact: true }).click();
  await expect(cards).toHaveCount(8);
  await cards.first().locator("img").evaluate(img => { img.src = "/imagen-inexistente.png"; });
  await expect.poll(() => cards.first().locator("img").evaluate(img => img.complete && img.naturalWidth > 0 && img.getAttribute("src") === "/images/espacios/campo-demo.png")).toBe(true);
});
