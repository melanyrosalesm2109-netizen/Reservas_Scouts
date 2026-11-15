import { test, expect } from "@playwright/test";

const pendiente = {
  reservaId: 25, espacioId: 4, codigo: "DEMO-FLUJO-002", solicitante: "Persona Demo", espacio: "Campo Demo",
  responsable: "Persona Demo", participantes: 12, fechaInicio: "2026-12-01T08:00:00", fechaFin: "2026-12-01T17:00:00",
  reservaEstado: "PENDIENTE", reservaCreadaEn: "2026-11-15T08:00:00", pagoId: 23, monto: 25000,
  metodo: "SINPE Móvil", pagoEstado: "PENDIENTE", fechaPago: "2026-11-14", tieneComprobante: true
};

async function conectar(page, rol, estado) {
  await page.route("**/api/**", async route => {
    const path = new URL(route.request().url()).pathname;
    let datos = [];
    if (path.endsWith("/usuarios/sesion")) datos = { id: rol === "Administrador" ? 1 : 7, email: "personal@example.com", rol };
    else if (path === "/api/notificaciones") datos = estado.filas;
    else if (path.endsWith("/verificar")) {
      if (estado.resuelto) return route.fulfill({ status: 409, json: { mensaje: "Este pago ya fue revisado por otra persona." } });
      const revision = route.request().postDataJSON();
      estado.revision = revision;
      estado.resuelto = true;
      estado.filas = estado.filas.map(n => n.pagoId === 23 ? { ...n, pagoEstado: revision.aprobar ? "PAGADO" : "RECHAZADO", reservaEstado: revision.aprobar ? "APROBADA" : "CANCELADA", revisadoPor: "personal@example.com", revisadaEn: "2026-11-15T15:00:00Z", motivo: revision.motivo } : n);
      datos = { ok: true };
    }
    return route.fulfill({ json: datos });
  });
}

test("a reviewed payment disappears from both staff inboxes", async ({ browser }) => {
  const contextoAdmin = await browser.newContext({ baseURL: test.info().project.use.baseURL });
  const contextoRecepcion = await browser.newContext();
  try {
    const admin = await contextoAdmin.newPage();
    const recepcion = await contextoRecepcion.newPage();
    const estado = { filas: [{ ...pendiente }] };
    await conectar(admin, "Administrador", estado);
    await conectar(recepcion, "Recepcionista", estado);
    await admin.goto("/notificaciones");
    await recepcion.goto("/notificaciones");
    await expect(admin.getByRole("article")).toContainText("DEMO-FLUJO-002");
    await expect(recepcion.getByRole("article")).toContainText("DEMO-FLUJO-002");
    await expect(recepcion.getByRole("link", { name: "Notificaciones: 1 pagos pendientes", exact: true })).toBeVisible();
    admin.once("dialog", dialog => dialog.accept());
    await admin.getByRole("button", { name: "Aprobar pago", exact: true }).click();
    await expect(admin.getByRole("article")).toHaveCount(0);
    await recepcion.evaluate(() => window.dispatchEvent(new Event("focus")));
    await expect(recepcion.getByRole("article")).toHaveCount(0);
    await expect(recepcion.getByRole("link", { name: "Notificaciones: 0 pagos pendientes", exact: true })).toBeVisible();
    await recepcion.getByRole("tab", { name: /Historial/ }).click();
    await expect(recepcion.getByRole("article")).toContainText("personal@example.com");
    await expect(recepcion.getByRole("article")).toContainText("PAGADO");
  } finally { await contextoAdmin.close(); await contextoRecepcion.close(); }
});

test("future cash cannot be marked received and rejection requires a reason", async ({ page }) => {
  const estado = { filas: [{ ...pendiente }, { ...pendiente, reservaId: 30, codigo: "EFECTIVO-DEMO", pagoId: 24, metodo: "Efectivo", reservaEstado: "APROBADA", fechaInicio: "2099-12-01T08:00:00", fechaFin: "2099-12-01T17:00:00", tieneComprobante: false }] };
  await conectar(page, "Recepcionista", estado);
  await page.goto("/notificaciones");
  await page.getByRole("tab", { name: /Efectivo al llegar/ }).click();
  await expect(page.getByRole("button", { name: "Registrar efectivo recibido" })).toBeDisabled();
  await page.getByRole("tab", { name: /Pagos por revisar/ }).click();
  await page.getByRole("button", { name: "Rechazar", exact: true }).click();
  await expect(page.getByRole("button", { name: "Confirmar rechazo" })).toBeDisabled();
  await page.getByLabel("Motivo del rechazo").fill("El monto del comprobante no corresponde.");
  await page.getByRole("button", { name: "Confirmar rechazo" }).click();
  await expect(page.getByRole("article")).toHaveCount(0);
  expect(estado.revision).toEqual({ aprobar: false, motivo: "El monto del comprobante no corresponde." });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByRole("tab", { name: /Efectivo al llegar/ }).click();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: "test-results/notificaciones-mobile.png", fullPage: true });
});

test("regular users cannot access the staff inbox", async ({ page }) => {
  const estado = { filas: [] };
  await conectar(page, "Usuario", estado);
  const consultas = [];
  page.on("request", request => { if (request.url().endsWith("/api/notificaciones")) consultas.push(request.url()); });
  await page.goto("/notificaciones");
  await expect(page).not.toHaveURL(/\/notificaciones$/);
  await expect(page.getByRole("link", { name: /Notificaciones:/ })).toHaveCount(0);
  expect(consultas).toHaveLength(0);
});

test("a stale review refreshes the shared inbox instead of processing it twice", async ({ page }) => {
  const estado = { filas: [{ ...pendiente }] };
  await conectar(page, "Administrador", estado);
  await page.goto("/notificaciones");
  await expect(page.getByRole("button", { name: "Aprobar pago" })).toBeVisible();
  estado.resuelto = true;
  estado.filas = [{ ...pendiente, pagoEstado: "PAGADO", reservaEstado: "APROBADA" }];
  page.once("dialog", dialog => dialog.accept());
  await page.getByRole("button", { name: "Aprobar pago" }).click();
  await expect(page.getByRole("alert")).toContainText("ya fue revisado");
  await expect(page.getByRole("article")).toHaveCount(0);
});
