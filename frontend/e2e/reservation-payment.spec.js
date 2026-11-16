import { test, expect } from "@playwright/test";
import { Buffer } from "node:buffer";
import { readFileSync } from "node:fs";

test.beforeEach(async ({ page }) => {
  await page.route("**/api/**", async route => {
    const url = new URL(route.request().url());
    let data = [];
    if (url.pathname.endsWith("/usuarios/sesion")) data = { id: 9, email: "demo@example.com", rol: "Usuario" };
    else if (url.pathname.endsWith("/espacios")) data = [{ id: 4, nombre: "Campo Demo", estado: "DISPONIBLE", capacidad: 40, costo: 25000 }];
    else if (url.pathname.endsWith("/perfiles/opciones-reserva")) data = [{ idPerfil: 11, usuarioId: 9, nombre: "Persona Demo", tipoPerfil: "Persona", telefono: "00000000", correoContacto: "demo@example.com" }];
    else if (url.pathname.endsWith("/bloqueos") && route.request().method() === "POST") data = {
      token: "11111111-1111-1111-1111-111111111111", ahora: new Date().toISOString(), vence: new Date(Date.now() + 120000).toISOString()
    };
    await route.fulfill({ json: data });
  });
});

async function formulario(page) {
  await page.goto("/reservas?espacioId=4&nueva=1");
  const form = page.locator(".reservation-form");
  await form.locator('[name="participantes"]').fill("10");
  await form.locator('[name="tipoActividad"]').fill("Campamento");
  const fecha = new Date(); fecha.setDate(fecha.getDate() + 60);
  const dia = fecha.toISOString().slice(0, 10);
  await form.locator('[name="fechaInicio"]').fill(`${dia}T08:00`);
  await form.locator('[name="fechaFin"]').fill(`${dia}T17:00`);
  await expect(form.getByRole("timer")).toBeVisible();
  return form;
}

test("SINPE requires a receipt and submits it together with the reservation", async ({ page }) => {
  let solicitud;
  await page.route("**/api/reservas/confirmar", async route => {
    solicitud = route.request().postDataBuffer().toString();
    await route.fulfill({ status: 201, json: { id: 100, estado: "PENDIENTE" } });
  });
  const form = await formulario(page);
  await form.locator("#reserva-metodo").selectOption("SINPE Móvil");
  await expect(form.getByRole("button", { name: "Enviar solicitud", exact: true })).toBeDisabled();
  await form.locator("#reserva-comprobante").setInputFiles({ name: "prueba.pdf", mimeType: "application/pdf", buffer: Buffer.from("%PDF-1.4 demo") });
  await expect(form.getByRole("button", { name: "Enviar solicitud", exact: true })).toBeEnabled();
  await form.getByRole("button", { name: "Enviar solicitud", exact: true }).click();
  await expect(page.getByText("Reserva realizada correctamente. Puedes consultar su estado en Mis reservas.")).toBeVisible();
  expect(solicitud).toContain('"metodo":"SINPE Móvil"');
  expect(solicitud).toContain("%PDF-1.4 demo");
});

test("expiry disables confirmation and allows requesting another hold", async ({ page }) => {
  await page.clock.install();
  const form = await formulario(page);
  await form.locator("#reserva-metodo").selectOption("Efectivo");
  await expect(form.getByRole("button", { name: "Enviar solicitud", exact: true })).toBeEnabled();
  await page.clock.fastForward(121000);
  await expect(form.getByRole("button", { name: "Enviar solicitud", exact: true })).toBeDisabled();
  await expect(form.getByText("El plazo terminó. El horario quedó libre para otros usuarios.")).toBeVisible();
  await form.getByRole("button", { name: "Volver a consultar y apartar" }).click();
  await page.clock.runFor(1000);
  await expect(form.getByRole("timer")).toBeVisible();
});

test("an occupied hold cannot be submitted and card fields belong to a simulation", async ({ page }) => {
  const form = await formulario(page);
  await form.locator("#reserva-metodo").selectOption("Tarjeta");
  await expect(form.getByText(/Simulación sin cobro real/)).toBeVisible();
  await expect(form.getByRole("button", { name: "Enviar solicitud", exact: true })).toBeDisabled();
  await form.locator('[name="numero"]').fill("4242424242424242");
  await form.locator('[name="titular"]').fill("Persona Demo");
  await form.locator('[name="vencimiento"]').fill("2099-12");
  await form.locator('[name="cvv"]').fill("123");
  await expect(form.getByRole("button", { name: "Enviar solicitud", exact: true })).toBeEnabled();
  await page.route("**/api/reservas/bloqueos", route => route.request().method() === "POST"
    ? route.fulfill({ status: 409, json: { mensaje: "Espacio no disponible: otro usuario está completando su reserva." } })
    : route.fulfill({ json: [] }));
  const fecha = new Date(); fecha.setDate(fecha.getDate() + 61);
  const dia = fecha.toISOString().slice(0, 10);
  await form.locator('[name="fechaInicio"]').fill(`${dia}T08:00`);
  await form.locator('[name="fechaFin"]').fill(`${dia}T17:00`);
  await expect(form.getByText(/otro usuario está completando/)).toBeVisible();
  await expect(form.getByRole("button", { name: "Enviar solicitud", exact: true })).toBeDisabled();
});

test("reception downloads the receipt and verifies the pending payment", async ({ page }) => {
  let verificado = false;
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ json: { id: 8, email: "recepcion@example.com", rol: "Recepcionista" } }));
  await page.route("**/api/pagos**", async route => {
    const path = new URL(route.request().url()).pathname;
    if (path.endsWith("/comprobante")) return route.fulfill({ contentType: "application/pdf", headers: { "Content-Disposition": 'attachment; filename="comprobante.pdf"' }, body: "%PDF-1.4 demo" });
    if (path.endsWith("/verificar")) {
      expect(route.request().postDataJSON()).toEqual({ aprobar: true });
      verificado = true;
      return route.fulfill({ json: { ok: true } });
    }
    return route.fulfill({ json: [{ id: 100, reservaId: 50, reservaCodigo: "PRUEBA-PAGO", espacio: "Campo Demo", monto: 25000, metodo: "Transferencia bancaria", fechaPago: "2026-11-14", estado: verificado ? "PAGADO" : "PENDIENTE", comprobante: "Comprobante adjunto" }] });
  });
  await page.goto("/pagos");
  const row = page.getByRole("row").filter({ hasText: "PRUEBA-PAGO" });
  await row.getByRole("button", { name: "Revisar comprobante" }).click();
  const visor = page.getByRole("dialog", { name: "Comprobante de pago" });
  await expect(visor.locator("iframe")).toBeVisible();
  const descarga = page.waitForEvent("download");
  await visor.getByRole("link", { name: "Descargar comprobante" }).click();
  expect((await descarga).suggestedFilename()).toBe("comprobante.pdf");
  page.once("dialog", dialog => dialog.accept());
  await visor.getByRole("button", { name: "Aprobar pago" }).click();
  await expect(row.getByText("PAGADO", { exact: true })).toBeVisible();
});


test("previews the actual demo image and closes with Escape", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ json: { id: 1, email: "admin@example.com", rol: "Administrador" } }));
  await page.route("**/api/pagos**", async route => {
    if (new URL(route.request().url()).pathname.endsWith("/comprobante")) return route.fulfill({
      contentType: "image/png", headers: { "Content-Disposition": 'attachment; filename="sinpe-ia-demo.png"' },
      body: readFileSync(new URL("../../output/comprobantes-demo/sinpe-ia-demo.png", import.meta.url))
    });
    return route.fulfill({ json: [{ id: 100, reservaCodigo: "DEMO-FLUJO-002", espacio: "Campo Demo", monto: 25000, metodo: "SINPE M\u00f3vil", fechaPago: "2026-11-14", estado: "PENDIENTE", comprobante: "Comprobante adjunto" }] });
  });
  await page.goto("/pagos");
  await page.getByRole("button", { name: "Revisar comprobante" }).click();
  const visor = page.getByRole("dialog", { name: "Comprobante de pago" });
  const imagen = visor.getByRole("img");
  await expect(imagen).toBeVisible();
  await expect.poll(() => imagen.evaluate(img => img.naturalWidth)).toBeGreaterThan(0);
  await page.keyboard.press("Escape");
  await expect(visor).toHaveCount(0);
});
