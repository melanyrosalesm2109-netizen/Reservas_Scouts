import { expect, test } from "@playwright/test";
import { getAdminCredentials, loginThroughUi } from "./support/fixtures.js";

test("rejects invalid credentials and preserves a valid admin session", async ({ page }) => {
  const { email, password } = getAdminCredentials();

  await page.goto("/auditoria");
  await expect(page).toHaveURL(/\/login$/);

  await page.getByPlaceholder("Ingrese su correo").fill(email);
  await page.getByPlaceholder("Ingrese su contraseña").fill("invalid-e2e-password");
  await page.getByRole("button", { name: "Iniciar sesión" }).click();
  await expect(page.locator(".login-error")).toContainText(/incorrectos/i);
  await expect(page).toHaveURL(/\/login$/);

  await loginThroughUi(page, email, password);
  await expect(page).toHaveURL(/\/dashboard$/);
  await expect(page.getByText("Administrador", { exact: true })).toBeVisible();

  await page.reload();
  await expect(page).toHaveURL(/\/dashboard$/);
  await expect(page.getByText("Administrador", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Cerrar sesión" }).click();
  await expect(page).toHaveURL(/\/login$/);
  await page.goto("/auditoria");
  await expect(page).toHaveURL(/\/login$/);
});
