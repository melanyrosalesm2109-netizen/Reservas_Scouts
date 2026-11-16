import { expect, test } from "@playwright/test";
import path from "node:path";
import { Buffer } from "node:buffer";

async function mockPayments(page, metodo, estado = "PENDIENTE", correcto = null) {
  let attached = estado !== "PENDIENTE";
  const pago = { id: 71, reservaId: 31, reservaCodigo: "DEMO-COMP-TEST", espacio: "Campo de prueba", monto: 25000, metodo, fechaPago: "2026-11-16", estado };
  const uploads = [];
  await page.route("**/api/**", async route => {
    const pathname = new URL(route.request().url()).pathname;
    if (pathname.endsWith("/comprobante") && route.request().method() === "POST") {
      uploads.push(route.request().postDataBuffer().toString()); attached = true;
      return route.fulfill({ json: { ok: true } });
    }
    if (pathname.endsWith("/comprobante")) return route.fulfill({ contentType: "image/png", body: Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZxkAAAAASUVORK5CYII=", "base64") });
    let json = [];
    if (pathname.endsWith("/sesion")) json = { id: 1, rol: "Administrador", email: "admin@example.com" };
    if (pathname === "/api/pagos") json = [{ ...pago, comprobante: attached ? "Comprobante adjunto" : null }];
    if (pathname.endsWith("/detalle") && pathname.startsWith("/api/pagos")) json = {
      pago: { ...pago, comprobante: attached ? "Comprobante adjunto" : null }, tieneComprobante: attached,
      reservaEstado: estado === "RECHAZADO" ? "CANCELADA" : "APROBADA", fechaInicio: "2027-01-01", fechaFin: "2027-01-02", costo: 25000, saldo: 25000,
      comprobanteCorrecto: correcto, revisadoPor: correcto === null ? null : "revisor@example.com", revisadaEn: "2026-11-16T12:00:00Z", motivoRevision: correcto === false ? "Monto incorrecto" : null
    };
    return route.fulfill({ json });
  });
  return uploads;
}

for (const metodo of ["SINPE Móvil", "Transferencia bancaria"]) {
  test(`adjunta un comprobante propio y lo muestra en ${metodo}`, async ({ page }) => {
    const uploads = await mockPayments(page, metodo);
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/pagos");
    await page.getByRole("button", { name: "Ver detalle", exact: true }).click();
    const dialog = page.getByRole("dialog", { name: "Detalle del pago" });
    await expect(dialog.getByText("Sin comprobante adjunto", { exact: true })).toBeVisible();
    const filename = metodo.startsWith("SINPE") ? "sinpe-reserva-31.pdf" : "transferencia-reserva-31.pdf";
    await dialog.locator("input[type=file]").setInputFiles({ name: filename, mimeType: "application/pdf", buffer: Buffer.from(`%PDF-1.4 ${metodo} reserva31 pago71`) });
    await dialog.getByRole("button", { name: "Adjuntar comprobante", exact: true }).click();
    await expect(dialog.getByText("Pendiente de revisión", { exact: true })).toBeVisible();
    expect(uploads).toHaveLength(1);
    expect(uploads[0]).toContain(filename);
    await dialog.screenshot({ path: path.resolve("..", `.docwork/previews/pago-adjunto-${metodo.startsWith("SINPE") ? "sinpe" : "transferencia"}.png`) });
    await dialog.getByRole("button", { name: "Revisar comprobante", exact: true }).click();
    await expect(page.getByRole("dialog", { name: "Comprobante de pago" }).locator("img")).toBeVisible();
  });
  for (const [estado, correcto, label] of [["PAGADO", true, "Correcto · aprobado"], ["RECHAZADO", false, "Incorrecto · rechazado"]]) {
    test(`conserva la validación ${estado} en ${metodo}`, async ({ page }) => {
      await mockPayments(page, metodo, estado, correcto);
      await page.goto("/pagos");
      await page.getByRole("button", { name: "Ver detalle", exact: true }).click();
      const dialog = page.getByRole("dialog", { name: "Detalle del pago" });
      await expect(dialog.getByText(label, { exact: true })).toBeVisible();
      await expect(dialog.locator("input[type=file]")).toHaveCount(0);
      await expect(dialog.getByRole("button", { name: "Ver comprobante", exact: true })).toBeVisible();
      if (!correcto) await expect(dialog.getByText(/Monto incorrecto/)).toBeVisible();
    });
  }
}

test("auditoría conserva reserva eliminada, revisión y comprobante", async ({ page }) => {
  await page.route("**/api/**", route => {
    const pathname = new URL(route.request().url()).pathname;
    let json = [];
    if (pathname.endsWith("/sesion")) json = { id: 1, rol: "Administrador", email: "admin@example.com" };
    if (pathname === "/api/auditoria/detalle") json = [{ idAuditoria: 1, origen: "reservas", evento: "DELETE", registroId: 31, usuario: "admin@example.com", creadoEn: "2026-11-16T12:00:00Z", detalle: JSON.stringify({ antes: { codigo: "DEMO-ARCHIVO", estado: "CANCELADA" } }) }];
    if (pathname.endsWith("/archivo")) json = { reservaJson: JSON.stringify({ codigo: "DEMO-ARCHIVO", espacio: "Campo de prueba", solicitante: "Persona Demo" }), pagosJson: JSON.stringify([{ id: 71, metodo: "SINPE Móvil", monto: 25000, estado: "RECHAZADO", comprobanteCorrecto: false, revisadoPor: "revisor@example.com", motivoRevision: "Monto incorrecto", archivoNombre: "sinpe-demo.png" }]) };
    return route.fulfill({ json });
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/auditoria");
  await page.getByRole("button", { name: /detalle/i }).first().click();
  await page.getByRole("button", { name: "Consultar reserva y pagos archivados" }).click();
  await expect(page.locator(".reserva-archivo").getByText(/Incorrecto · rechazado/)).toBeVisible();
  await expect(page.getByRole("button", { name: "Ver comprobante del pago #71" })).toBeVisible();
  expect(await page.locator(".audit-modal").evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
  await page.locator(".audit-modal").screenshot({ path: path.resolve("..", ".docwork/previews/reserva-archivo-auditoria.png") });
});

test("el enlace de reserva filtra sus pagos y permite volver a todos", async ({ page }) => {
  await mockPayments(page, "SINPE Móvil");
  await page.route("**/api/pagos", route => route.fulfill({ json: [31, 99].map(id => ({ id, reservaId: id, reservaCodigo: `RES-${id}`, espacio: "Campo", monto: 25000, metodo: "SINPE Móvil", estado: "PENDIENTE", fechaPago: "2026-11-16" })) }));
  await page.goto("/pagos?reservaId=31");
  await expect(page.locator(".pagos-table tbody tr")).toHaveCount(1);
  await expect(page.locator(".pagos-table")).toContainText("RES-31");
  await expect(page.locator(".pagos-table")).not.toContainText("RES-99");
  await page.getByRole("link", { name: "Ver todas las reservas" }).click();
  await expect(page.locator(".pagos-table tbody tr")).toHaveCount(2);
});

test("eliminar reserva advierte que conserva pagos y quita la fila", async ({ page }) => {
  let deleted = false;
  await page.route("**/api/**", route => {
    const pathname = new URL(route.request().url()).pathname;
    let json = [];
    if (pathname.endsWith("/sesion")) json = { id: 1, rol: "Administrador", email: "admin@example.com" };
    if (pathname === "/api/reservas/31" && route.request().method() === "DELETE") { deleted = true; json = { ok: true }; }
    if (pathname === "/api/reservas" && !deleted) json = [{ id: 31, codigo: "DEMO-ELIMINAR", espacio: "Campo", responsable: "Persona Demo", solicitante: "Persona Demo", participantes: 1, fechaInicio: "2027-04-01T09:00:00", fechaFin: "2027-04-01T11:00:00", estado: "PENDIENTE" }];
    return route.fulfill({ json });
  });
  page.once("dialog", async dialog => {
    expect(dialog.message()).toContain("se conservarán la auditoría, los pagos y los comprobantes");
    await dialog.accept();
  });
  await page.goto("/reservas");
  await page.getByTitle("Eliminar reserva", { exact: true }).click();
  await expect(page.getByText("Reserva eliminada. La auditoría, los pagos y los comprobantes se conservaron.", { exact: true })).toBeVisible();
  await expect(page.locator(".reservas-table-wrapper")).not.toContainText("DEMO-ELIMINAR");
  expect(deleted).toBe(true);
});
