import { test, expect } from "@playwright/test";

const espacios = [
  { id: 1, nombre: "Campo de prueba", ubicacion: "Sede", capacidad: 50, costo: 25000, estado: "DISPONIBLE" },
  { id: 2, nombre: "Salón de prueba", ubicacion: "Sede", capacidad: 30, costo: 15000, estado: "DISPONIBLE" }
];

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-11-14T12:00:00"));
  await page.route("**/api/**", async route => {
    const url = new URL(route.request().url());
    let data = [];
    if (url.pathname.endsWith("/reservas/bloqueos") && route.request().method() === "POST") data = {
      token: "11111111-1111-1111-1111-111111111111", ahora: "2026-11-14T18:00:00Z", vence: "2026-11-14T18:02:00Z"
    };
    else if (url.pathname.endsWith("/usuarios/sesion")) data = { id: 1, nombre: "Administrador", rol: "Administrador", email: "admin@example.com" };
    else if (url.pathname.endsWith("/espacios")) data = espacios;
    else if (url.pathname.endsWith("/ocupadas")) data = [
      { espacioId: 1, fechaInicio: "2027-02-10T08:00:00", fechaFin: "2027-02-12T00:00:00" },
      { espacioId: 2, fechaInicio: "2027-02-15T08:00:00", fechaFin: "2027-02-15T17:00:00" }
    ];
    await route.fulfill({ json: data });
  });
});

test("opens reservations and books the selected space with its occupied dates", async ({ page }) => {
  await page.goto("/espacios");
  const card = page.locator(".espacio-card").filter({ hasText: "Campo de prueba" });
  await card.getByRole("link", { name: "Ver reservas" }).click();
  await expect(page).toHaveURL(/reservas\?espacioId=1$/);
  await expect(page.locator('.reservas-filtros-reales [name="espacioId"]')).toHaveValue("1");
  await page.goto("/espacios");
  await card.getByRole("link", { name: "Reservar", exact: true }).click();
  const form = page.locator(".reservation-form");
  await expect(form.locator('[name="espacioId"]')).toHaveValue("1");
  const calendar = page.getByRole("region", { name: "Disponibilidad de Campo de prueba" });
  await expect(calendar).toBeVisible();
  for (let i = 0; i < 18; i++) {
    if ((await calendar.locator(".calendario-mes strong").innerText()).toLowerCase().includes("febrero de 2027")) break;
    await calendar.getByRole("button", { name: "Mes siguiente" }).click();
  }
  await expect(calendar.getByRole("button", { name: "2027-02-10: con horarios ocupados" })).toBeVisible();
  await expect(calendar.getByRole("button", { name: "2027-02-11: con horarios ocupados" })).toBeVisible();
  await expect(calendar.getByRole("button", { name: "2027-02-12: disponible" })).toBeVisible();
  await expect(calendar.getByRole("button", { name: "2027-02-15: disponible" })).toBeVisible();
  await calendar.getByRole("button", { name: "2027-02-10: con horarios ocupados" }).click();
  await expect(calendar.locator(".calendario-horarios")).toContainText("08:00");
  await expect(form.locator('[name="responsable"]')).toBeDisabled();
  await expect(form.locator('[name="espacioId"]')).toBeDisabled();
  await expect(form.locator('[name="fechaInicio"]')).toBeDisabled();
  await expect(form.getByRole("button", { name: "Crear reserva", exact: true })).toBeDisabled();
  await expect(calendar.getByRole("button", { name: "2027-02-12: disponible" })).toBeEnabled();
  await calendar.getByRole("button", { name: "2027-02-12: disponible" }).click();
  await expect(form.locator('[name="fechaInicio"]')).toHaveValue("2027-02-12T08:00");
  await expect(form.locator('[name="fechaFin"]')).toHaveValue("2027-02-12T17:00");
  await expect(form.locator('[name="responsable"]')).toBeEnabled();
  await form.locator("#reserva-metodo").selectOption("Efectivo");
  await expect(form.getByRole("button", { name: "Crear reserva", exact: true })).toBeEnabled();
  await form.locator('[name="responsable"]').fill("Responsable de prueba");
  await calendar.getByRole("button", { name: "2027-02-11: con horarios ocupados" }).click();
  await expect(form.locator('[name="responsable"]')).toBeDisabled();
  await calendar.getByRole("button", { name: "2027-02-15: disponible" }).click();
  await expect(form.locator('[name="responsable"]')).toBeEnabled();
  await expect(form.locator('[name="responsable"]')).toHaveValue("Responsable de prueba");
  await page.setViewportSize({ width: 390, height: 844 });
  await expect(calendar).toBeVisible();
  expect(await calendar.evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
});

test("shows a retry when availability cannot be loaded", async ({ page }) => {
  await page.goto("/reservas");
  await page.getByRole("button", { name: "Nueva reserva", exact: true }).click();
  await page.route("**/api/reservas/ocupadas", route => route.fulfill({ status: 500, json: {} }));
  await page.locator('.reservation-form [name="espacioId"]').selectOption("1");
  const calendar = page.getByRole("region", { name: "Disponibilidad de Campo de prueba" });
  await expect(calendar.getByRole("alert")).toContainText("No se pudo cargar");
  await expect(calendar.locator(".calendario-dia").first()).toBeDisabled();
  await page.unroute("**/api/reservas/ocupadas");
  await calendar.getByRole("button", { name: "Reintentar" }).click();
  await expect(calendar.locator(".calendario-dia").first()).toBeEnabled();
});

test("blocks past dates and enables the form again for today", async ({ page }) => {
  await page.goto("/reservas?espacioId=1&nueva=1");
  const form = page.locator(".reservation-form");
  const calendar = page.getByRole("region", { name: "Disponibilidad de Campo de prueba" });
  await calendar.getByRole("button", { name: "2026-11-13: fecha pasada" }).click();
  await expect(form.locator('[name="responsable"]')).toBeDisabled();
  await expect(form.locator('[name="fechaInicio"]')).toBeDisabled();
  await expect(form.getByRole("button", { name: "Crear reserva", exact: true })).toBeDisabled();
  await expect(form.getByRole("status")).toContainText("desde la fecha actual");
  await calendar.getByRole("button", { name: "2026-11-14: disponible" }).click();
  await expect(form.locator('[name="responsable"]')).toBeEnabled();
  await form.locator("#reserva-metodo").selectOption("Efectivo");
  await expect(form.getByRole("button", { name: "Crear reserva", exact: true })).toBeEnabled();
  await form.locator('[name="fechaInicio"]').fill("2026-11-12T08:00");
  await expect(form.getByRole("button", { name: "Crear reserva", exact: true })).toBeDisabled();
});

test("prefills the signed-in user's profile and keeps activity fields editable", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ json: {
    id: 7, email: "persona@example.com", rol: "Usuario"
  } }));
  await page.route("**/api/perfiles/opciones-reserva", route => route.fulfill({ json: [{
    idPerfil: 12, usuarioId: 7, nombre: "Persona de prueba", tipoPerfil: "Persona",
    telefono: "88881111", correoContacto: "contacto@example.com"
  }] }));
  await page.goto("/reservas?espacioId=1&nueva=1");
  let form = page.locator(".reservation-form");
  await expect(form.locator('[name="responsable"]')).toHaveValue("Persona de prueba");
  await expect(form.locator('[name="telefono"]')).toHaveValue("88881111");
  await expect(form.locator('[name="email"]')).toHaveValue("contacto@example.com");
  await expect(form.locator('[name="participantes"]')).toHaveValue("");
  await expect(form.locator('[name="tipoActividad"]')).toHaveValue("");
  await form.locator('[name="responsable"]').fill("Nombre ajustado");
  await expect(form.locator('[name="responsable"]')).toHaveValue("Nombre ajustado");
  await form.getByRole("button", { name: "Cancelar", exact: true }).click();
  await expect(page).toHaveURL(/\/espacios$/);
  await page.goto("/reservas");
  await page.getByRole("button", { name: "Nueva reserva", exact: true }).click();
  form = page.locator(".reservation-form");
  await expect(form.locator('[name="responsable"]')).toHaveValue("Persona de prueba");
  await expect(form.locator('[name="telefono"]')).toHaveValue("88881111");
});

test("personal profiles do not ask for a group or another applicant", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ json: { id: 7, email: "persona@example.com", rol: "Miembro" } }));
  await page.route("**/api/perfiles/opciones-reserva", route => route.fulfill({ json: [{ idPerfil: 12, usuarioId: 7, nombre: "Persona de prueba", tipoPerfil: "Persona", telefono: "88881111", correoContacto: "persona@example.com" }] }));
  await page.goto("/reservas?espacioId=1&nueva=1");
  const form = page.locator(".reservation-form");
  await expect(form.locator(".reserva-solicitante-propio")).toContainText("Persona de prueba");
  await expect(form.locator('select[name="solicitantePerfilId"]')).toHaveCount(0);
  await expect(form.locator('[name="grupo"]')).toHaveCount(0);
  await expect(form.locator('[name="responsable"]')).toHaveValue("Persona de prueba");
});

test("reception selects an organization and requests its responsible person", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ json: { id: 8, email: "recepcion@example.com", rol: "Recepcionista" } }));
  await page.route("**/api/perfiles/opciones-reserva", route => route.fulfill({ json: [{ idPerfil: 20, usuarioId: 9, nombre: "Grupo Exploradores", tipoPerfil: "Grupo Scout", telefono: null, correoContacto: null }] }));
  await page.goto("/reservas?espacioId=1&nueva=1");
  const form = page.locator(".reservation-form");
  await form.locator('[name="solicitantePerfilId"]').selectOption("20");
  await expect(form.locator('[name="grupo"]')).toHaveValue("Grupo Exploradores");
  await expect(form.locator('[name="grupo"]')).toHaveAttribute("readonly", "");
  await expect(form.locator('[name="responsable"]')).toHaveValue("");
  await expect(form.locator('[name="email"]')).toHaveValue("");
});

test("a user without a profile completes their own data before booking", async ({ page }) => {
  await page.route("**/api/usuarios/sesion", route => route.fulfill({ json: { id: 7, email: "nuevo@example.com", rol: "Usuario" } }));
  await page.route("**/api/perfiles/opciones-reserva", route => route.fulfill({ json: [] }));
  let perfilCreado;
  let reservaCreada;
  await page.route("**/api/perfiles/propio", async route => {
    perfilCreado = route.request().postDataJSON();
    await route.fulfill({ json: { ...perfilCreado, idPerfil: 55, usuarioId: 7 } });
  });
  await page.route("**/api/reservas/disponibilidad?**", route => route.fulfill({ json: { disponible: true } }));
  await page.route("**/api/reservas/confirmar", async route => {
    const raw = route.request().postDataBuffer().toString();
    const start = raw.indexOf('{"reserva"');
    reservaCreada = JSON.parse(raw.slice(start, raw.indexOf('\r\n--', start))).reserva;
    await route.fulfill({ status: 201, json: { id: 100 } });
  });
  await page.goto("/reservas?espacioId=1&nueva=1");
  const form = page.locator(".reservation-form");
  await expect(form.locator('select[name="solicitantePerfilId"]')).toHaveCount(0);
  await expect(form.locator('[name="email"]')).toHaveValue("nuevo@example.com");
  await form.locator('[name="responsable"]').fill("Persona nueva");
  await form.locator('[name="telefono"]').fill("88881111");
  await form.locator('[name="participantes"]').fill("10");
  await form.locator('[name="tipoActividad"]').fill("Reunion");
  await form.locator('[name="fechaInicio"]').fill("2026-11-26T08:00");
  await form.locator('[name="fechaFin"]').fill("2026-11-26T17:00");
  await form.locator("#reserva-metodo").selectOption("Efectivo");
  await form.getByRole("button", { name: "Enviar solicitud", exact: true }).click();
  await expect(page.getByText("Reserva realizada correctamente. El pago en efectivo queda pendiente para el día de llegada.")).toBeVisible();
  expect(perfilCreado.nombre).toBe("Persona nueva");
  expect(perfilCreado.usuarioId).toBeUndefined();
  expect(reservaCreada.solicitantePerfilId).toBe(55);
});
