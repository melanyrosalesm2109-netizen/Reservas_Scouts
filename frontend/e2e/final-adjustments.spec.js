import { expect, test } from "@playwright/test";
import { API_ROOT, createAdminApi, createReservationFixture, cleanupReservationFixture, getAdminCredentials, loginThroughUi, localDateTime } from "./support/fixtures.js";

async function jsonOk(response) { expect(response.ok(), await response.text()).toBe(true); return response.json(); }

test("own pending reservations, staff lists, cancellation navigation and payment rejection", async ({ page }) => {
  test.setTimeout(100000);
  const api = await createAdminApi();
  const first = {}, second = {}, reservations = [];
  try {
    await createReservationFixture(api, first);
    await createReservationFixture(api, second);
    await jsonOk(await api.put(`${API_ROOT}/espacios/${first.space.id}`, { data: { nombre: first.space.nombre, ubicacion: first.space.ubicacion, capacidad: 40, costo: 100, estado: "DISPONIBLE" } }));
    for (const [fixture, estado, days] of [[first, "PENDIENTE", 60], [first, "APROBADA", 61], [second, "PENDIENTE", 60]]) {
      reservations.push(await jsonOk(await api.post(API_ROOT + "/reservas", { data: { codigo: fixture.codigo + days, espacioId: fixture.space.id, solicitantePerfilId: fixture.profile.idPerfil, responsable: fixture.profile.nombre, telefono: "55501010", email: fixture.email, participantes: 10, tipoActividad: "Prueba de visibilidad", fechaInicio: localDateTime(days * 24), fechaFin: localDateTime(days * 24 + 3), estado } })));
    }
    await jsonOk(await api.post(API_ROOT + "/pagos", { data: { reservaId: reservations[0].id, monto: 100, metodo: "SINPE Móvil", fechaPago: new Date().toISOString().slice(0,10), estado: "PENDIENTE" } }));
    await loginThroughUi(page, first.email, first.password);
    await expect(page).toHaveURL(/\/reservas$/);
    const propias = await jsonOk(await page.request.get(API_ROOT + "/reservas"));
    expect(propias.map(r => r.id)).toEqual(expect.arrayContaining([reservations[0].id, reservations[1].id]));
    expect(propias.some(r => r.id === reservations[2].id)).toBe(false);
    await page.goto("/mi-perfil");
    await expect(page.getByRole("heading", { name: "Mi perfil", exact: true })).toBeVisible();
    await expect(page.locator(".mi-perfil-reservas")).toContainText(reservations[0].codigo);
    await expect(page.locator(".mi-perfil-reservas")).not.toContainText(reservations[2].codigo);
    await page.goto(`/reservas?espacioId=${first.space.id}`);
    await expect(page.locator(".reservas-table-wrapper")).toContainText(reservations[0].codigo);
    await expect(page.locator(".reservas-table-wrapper")).toContainText("PENDIENTE");
    await page.goto(`/reservas?espacioId=${first.space.id}&nueva=1`);
    const form = page.locator(".reservation-form");
    await expect(form).toBeVisible();
    await expect(form.getByText("indica un campo obligatorio.", { exact: false })).toBeVisible();
    expect(await form.locator(".required-mark").first().evaluate(el => getComputedStyle(el).color)).toBe("rgb(189, 41, 41)");
    await form.getByRole("button", { name: "Cancelar", exact: true }).click();
    await expect(page).toHaveURL(/\/espacios$/);
    const credentials = getAdminCredentials();
    await loginThroughUi(page, credentials.email, credentials.password);
    await expect(page).toHaveURL(/\/dashboard$/);
    await page.goto("/usuarios");
    await expect(page.locator(".usuarios-table")).not.toContainText(first.email);
    const perfiles = await jsonOk(await api.get(API_ROOT + "/perfiles?soloRegistrados=true"));
    expect(perfiles.some(p => p.idPerfil === first.profile.idPerfil)).toBe(true);
    expect(perfiles.every(p => p.usuarioId != null)).toBe(true);
    await page.goto("/pagos");
    const row = page.getByRole("row").filter({ hasText: reservations[0].codigo });
    const reject = row.getByRole("button", { name: "Rechazar", exact: true });
    await expect(reject).toBeVisible();
    expect(await reject.evaluate(el => getComputedStyle(el).paddingLeft)).toBe("11px");
    await reject.click();
    const dialog = page.getByRole("dialog", { name: "Rechazar pago", exact: true });
    await expect(dialog).toBeVisible();
    await page.screenshot({ path: "../.docwork/previews/rechazo-pago.png" });
    await dialog.getByLabel("Motivo del rechazo").fill("Comprobante no corresponde a la reserva de prueba.");
    await dialog.getByRole("button", { name: "Confirmar rechazo", exact: true }).click();
    await expect(dialog).toBeHidden();
    await expect(row).toContainText("RECHAZADO");
    const cancelled = await jsonOk(await api.get(`${API_ROOT}/reservas/${reservations[0].id}`));
    expect(cancelled.estado).toBe("CANCELADA");
  } finally {
    for (const reserva of reservations.reverse()) {
      const pagos = await jsonOk(await api.get(`${API_ROOT}/pagos?reservaId=${reserva.id}`));
      for (const pago of pagos) expect((await api.delete(`${API_ROOT}/pagos/${pago.id}`)).ok()).toBe(true);
      expect((await api.delete(`${API_ROOT}/reservas/${reserva.id}`)).ok()).toBe(true);
    }
    await cleanupReservationFixture(api, first);
    await cleanupReservationFixture(api, second);
    await api.dispose();
  }
});

test("audit detail identifies the space even when only its status changed", async ({ page }) => {
  await page.route("**/api/**", async route => {
    const url = new URL(route.request().url());
    let data = [];
    if (url.pathname.endsWith("/usuarios/sesion")) data = { id: 1, email: "admin@example.com", rol: "Administrador" };
    else if (url.pathname.endsWith("/auditoria/detalle")) data = [{ id: 1, origen: "reservas", evento: "UPDATE", registroId: 10, usuario: "admin@example.com", usuarioBd: "reservas_app", creadoEn: "2026-11-15T12:00:00", valoresAnteriores: '{"espacioId":11,"estado":"PENDIENTE"}', valoresNuevos: '{"espacioId":11,"estado":"CANCELADA"}' }];
    else if (url.pathname.endsWith("/espacios")) data = [{ id: 11, nombre: "Campo Escuela Nacional Iztarú" }];
    else if (url.pathname.endsWith("/reservas")) data = [{ id: 10, codigo: "RES-PRUEBA", espacio: "Campo Escuela Nacional Iztarú" }];
    await route.fulfill({ json: data });
  });
  await page.goto("/auditoria");
  await page.getByRole("button", { name: "Ver detalle", exact: true }).click();
  await expect(page.locator(".audit-resource-name")).toContainText("Campo Escuela Nacional Iztarú");
  await page.screenshot({ path: "../.docwork/previews/auditoria-espacio.png" });
});
