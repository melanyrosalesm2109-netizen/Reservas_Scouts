import { expect, test } from "@playwright/test";
import { getAdminCredentials, loginThroughUi } from "./support/fixtures.js";

test("admin can review persisted login audit and backup catalog", async ({ page }) => {
  const { email, password } = getAdminCredentials();

  await page.goto("/auditoria");
  await expect(page).toHaveURL(/\/login$/);
  await loginThroughUi(page, email, password);
  await expect(page).toHaveURL(/\/dashboard$/);

  await page.goto("/auditoria");
  const loginAuditRow = page
    .getByRole("row")
    .filter({ has: page.getByText("LOGIN", { exact: true }) });
  await expect(loginAuditRow).toBeVisible();
  await page.reload();
  await expect(
    page.getByRole("row").filter({ has: page.getByText("LOGIN", { exact: true }) })
  ).toBeVisible();

  await page.goto("/respaldos");
  await expect(page.getByRole("heading", { name: "Respaldos" })).toBeVisible();
  await expect(page.getByText("Cargando respaldos...")).toBeHidden();
  await expect(page.getByRole("alert")).toHaveCount(0);
  const backupCatalog = page
    .getByLabel("Selecciona un respaldo")
    .or(page.getByText("No hay copias creadas desde esta aplicación.", { exact: true }));
  await expect(backupCatalog).toBeVisible();

  await page.reload();
  await expect(page.getByRole("heading", { name: "Respaldos" })).toBeVisible();
  await expect(page.getByRole("alert")).toHaveCount(0);
  await expect(backupCatalog).toBeVisible();
});
