import { randomUUID } from "node:crypto";
import { expect, test } from "@playwright/test";
import { createAdminApi, loginThroughUi } from "./support/fixtures.js";

test("regular user sees catalogue but cannot administer spaces", async ({ page }) => {
  const api = await createAdminApi();
  let user;
  try {
    const roles = await (await api.get("http://localhost:8080/api/usuarios/roles")).json();
    const credentials = { email: `catalogue.${randomUUID().replaceAll("-", "").slice(0, 12)}@example.com`, password: `Test_${randomUUID()}_A1` };
    const response = await api.post("http://localhost:8080/api/usuarios", { data: { ...credentials, rolId: roles.find(r => r.nombre === "Usuario").id, estado: "ACTIVO" } });
    expect(response.ok(), await response.text()).toBe(true);
    user = await response.json();
    await loginThroughUi(page, credentials.email, credentials.password);
    await expect(page).toHaveURL(/\/reservas$/);
    await page.setViewportSize({ width: 1440, height: 960 });
    await page.getByRole("navigation", { name: "Navegación principal" }).getByRole("link", { name: "Espacios", exact: true }).click();
    await expect(page.locator(".espacio-card")).toHaveCount(8);
    await expect(page.getByRole("button", { name: "Nuevo espacio" })).toHaveCount(0);
    await expect(page.locator(".space-edit, .space-delete")).toHaveCount(0);
    await expect(page.getByText("Solo lectura", { exact: true })).toHaveCount(8);
    const denied = await page.request.post("http://localhost:8080/api/espacios", { data: {} });
    expect(denied.status()).toBe(403);
  } finally {
    if (user) expect((await api.delete(`http://localhost:8080/api/usuarios/${user.id}`)).ok()).toBe(true);
    await api.dispose();
  }
});
