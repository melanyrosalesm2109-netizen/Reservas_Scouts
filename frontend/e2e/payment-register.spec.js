import { test, expect } from "@playwright/test";

const base = { reservaId: 10, reservaCodigo: "RES-EFECTIVO", espacio: "Campo Demo", monto: 25000, metodo: "Efectivo", estado: "PENDIENTE", fechaPago: "2099-11-26", comprobante: null };
async function preparar(page, rol = "Administrador") {
  const estado = { pagos: [{ ...base, id: 1 }, { ...base, id: 2, reservaId: 11, reservaCodigo: "RES-SINPE", metodo: "SINPE Móvil", comprobante: "Comprobante adjunto", fechaPago: "2026-11-15" },
    { ...base, id: 3, reservaId: 12, reservaCodigo: "RES-TARJETA", metodo: "Tarjeta", estado: "PAGADO", fechaPago: "2026-11-15", notas: "Pago simulado" }] };
  await page.route("**/api/**", async route => {
    const path = new URL(route.request().url()).pathname;
    let datos = [];
    if (path.endsWith("/usuarios/sesion")) datos = { id: 1, rol, email: "personal@example.com" };
    else if (path.endsWith("/pagos")) datos = estado.pagos;
    else if (path.endsWith("/reservas")) datos = estado.pagos.map(p => ({ id: p.reservaId, estado: "APROBADA", fechaInicio: `${p.fechaPago}T08:00:00` }));
    else if (path.endsWith("/detalle")) {
      const id = Number(path.split("/").at(-2));
      datos = { pago: estado.pagos.find(p => p.id === id), costo: 25000, saldo: 0, reservaEstado: "APROBADA", fechaInicio: "2026-11-26T08:00:00", fechaFin: "2026-11-26T17:00:00", tieneComprobante: false };
    } else if (path.endsWith("/anular")) {
      estado.anulacion = route.request().postDataJSON();
      estado.pagos = estado.pagos.map(p => p.id === 3 ? { ...p, estado: "ANULADO" } : p);
      datos = { ok: true };
    } else if (path.endsWith("/cobros-disponibles")) datos = estado.disponibles || [];
    else if (path.endsWith("/registrar-cobro")) {
      estado.cobro = route.request().postDataBuffer().toString();
      if (estado.conflicto) return route.fulfill({ status: 409, json: { mensaje: "Esta reserva ya tiene un pago pendiente." } });
      datos = { id: 99, estado: "PENDIENTE", metodo: "Efectivo" };
    }
    return route.fulfill({ json: datos });
  });
  return estado;
}

test("separates receipt review from cash and removes direct edit/delete actions", async ({ page }) => {
  await preparar(page);
  await page.goto("/pagos");
  await expect(page.getByText("Total registrado como pagado", { exact: true })).toBeVisible();
  const cash = page.getByRole("row").filter({ hasText: "RES-EFECTIVO" });
  await expect(cash.getByText("Cobro previsto", { exact: true })).toBeVisible();
  await expect(cash.getByRole("button", { name: "Registrar cobro" })).toBeEnabled();
  await expect(cash.getByText("Efectivo pendiente")).toBeVisible();
  await page.getByRole("tab", { name: /Comprobantes por revisar/ }).click();
  await expect(page.getByRole("row").filter({ hasText: "RES-SINPE" })).toBeVisible();
  await expect(cash).toHaveCount(0);
  await expect(page.locator(".pago-edit,.pago-delete")).toHaveCount(0);
  await page.screenshot({ path: "test-results/pagos-gestion-desktop.png", fullPage: true });
  await page.setViewportSize({ width: 390, height: 844 });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: "test-results/pagos-gestion-mobile.png", fullPage: true });
});

test("paid records can only be annulled with a reason and retain their history", async ({ page }) => {
  const estado = await preparar(page);
  await page.goto("/pagos");
  await page.getByRole("row").filter({ hasText: "RES-TARJETA" }).getByRole("button", { name: "Ver detalle" }).click();
  const dialogo = page.getByRole("dialog", { name: "Detalle del pago" });
  await dialogo.getByRole("button", { name: "Anular registro de pago" }).click();
  await expect(dialogo.getByRole("button", { name: "Confirmar anulación" })).toBeDisabled();
  await dialogo.getByLabel("Motivo de la anulación").fill("Registro de prueba duplicado.");
  page.once("dialog", d => d.accept());
  await dialogo.getByRole("button", { name: "Confirmar anulación" }).click();
  await expect(dialogo).toHaveCount(0);
  await expect(page.getByRole("row").filter({ hasText: "RES-TARJETA" }).getByText("ANULADO", { exact: true })).toBeVisible();
  expect(estado.anulacion).toEqual({ motivo: "Registro de prueba duplicado." });
});

test("reception cannot annul a paid record", async ({ page }) => {
  await preparar(page, "Recepcionista");
  await page.goto("/pagos");
  await page.getByRole("row").filter({ hasText: "RES-TARJETA" }).getByRole("button", { name: "Ver detalle" }).click();
  await expect(page.getByRole("dialog", { name: "Detalle del pago" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Anular registro de pago" })).toHaveCount(0);
});

test("registering a charge uses the server-provided balance and keeps conflicts visible", async ({ page }) => {
  const estado = await preparar(page);
  estado.disponibles = [{ reservaId: 20, codigo: "RES-SALDO", solicitante: "Persona Demo", saldo: 5000, costo: 25000 }];
  estado.conflicto = true;
  await page.goto("/pagos");
  await page.getByRole("button", { name: "Registrar cobro", exact: true }).first().click();
  const dialogo = page.getByRole("dialog", { name: "Registrar cobro" });
  await dialogo.getByLabel("Reserva con saldo").selectOption("20");
  await expect(dialogo.getByLabel("Saldo por registrar")).toHaveAttribute("readonly", "");
  await expect(dialogo.getByLabel("Saldo por registrar")).toHaveValue(/5/);
  await dialogo.getByLabel("Método").selectOption("Efectivo");
  await dialogo.getByRole("button", { name: "Registrar cobro", exact: true }).click();
  await expect(dialogo.getByRole("alert")).toContainText("ya tiene un pago pendiente");
  expect(estado.cobro).toContain('"reservaId":20');
  expect(estado.cobro).not.toContain('"monto"');
});

test("no available balance means no new payment can be submitted", async ({ page }) => {
  await preparar(page);
  await page.goto("/pagos");
  await page.getByRole("button", { name: "Registrar cobro", exact: true }).first().click();
  const dialogo = page.getByRole("dialog", { name: "Registrar cobro" });
  await expect(dialogo.getByText("No hay saldos disponibles para un nuevo cobro")).toBeVisible();
  await expect(dialogo.getByRole("button", { name: "Registrar cobro", exact: true })).toHaveCount(0);
});

test("financial charts use paid amounts, change periods and filter the ledger", async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-11-15T12:00:00"));
  const estado = await preparar(page);
  estado.pagos.push(
    { ...base, id: 4, reservaId: 14, reservaCodigo: "GRAFICO-SINPE", metodo: "SINPE Móvil", estado: "PAGADO", monto: 50000, fechaPago: "2026-11-14" },
    { ...base, id: 5, reservaId: 15, reservaCodigo: "GRAFICO-TRANSFERENCIA", metodo: "Transferencia bancaria", estado: "PAGADO", monto: 30000, fechaPago: "2026-11-04" },
    { ...base, id: 6, reservaId: 16, reservaCodigo: "GRAFICO-EFECTIVO", estado: "PAGADO", monto: 20000, fechaPago: "2026-11-01" },
    { ...base, id: 7, reservaId: 17, reservaCodigo: "RECHAZADO-1", estado: "RECHAZADO", monto: 99000 },
    { ...base, id: 8, reservaId: 18, reservaCodigo: "RECHAZADO-2", estado: "RECHAZADO", monto: 99000 },
    { ...base, id: 9, reservaId: 19, reservaCodigo: "ANULADO-1", estado: "ANULADO", monto: 99000 }
  );
  await page.setViewportSize({ width: 1440, height: 1100 });
  await page.goto("/pagos");
  const resumen = page.getByRole("region", { name: "Resumen gráfico de pagos" });
  const crc = valor => Number(valor).toLocaleString("es-CR", { style: "currency", currency: "CRC" });
  await expect(resumen.locator(".rp-importe")).toHaveText(crc(125000));
  await expect(resumen.getByRole("img", { name: /Distribución de 9 pagos: 4 pagados, 2 pendientes, 2 rechazados, 1 anulados/ })).toBeVisible();
  await expect(resumen.locator(".rp-periodo-total strong")).toHaveText(crc(125000));
  await page.screenshot({ path: "test-results/pagos-graficas-desktop.png", fullPage: true });
  await resumen.getByLabel("Periodo de la gráfica de pagos").selectOption("14");
  await expect(resumen.locator(".rp-periodo-total strong")).toHaveText(crc(105000));
  await resumen.getByTitle("Consultar pagos de SINPE Móvil").click();
  await expect(page.getByRole("row").filter({ hasText: "GRAFICO-SINPE" })).toBeVisible();
  await expect(page.locator(".pagos-table tbody tr")).toHaveCount(1);
  await resumen.getByTitle("Ver rechazados").click();
  await expect(page.locator(".pagos-table tbody tr")).toHaveCount(2);
  await page.setViewportSize({ width: 390, height: 844 });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.screenshot({ path: "test-results/pagos-graficas-mobile.png", fullPage: true });
});
