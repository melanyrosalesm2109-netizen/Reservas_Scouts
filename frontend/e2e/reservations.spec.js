import { expect, request, test } from "@playwright/test";
import {
  API_ROOT,
  cleanupReservationFixture,
  createAdminApi,
  createReservationFixture,
  localDateTime,
  loginThroughUi
} from "./support/fixtures.js";

test.describe("regular user reservation flow", () => {
  let adminApi;
  let fixture;

  test.beforeEach(async () => {
    adminApi = await createAdminApi();
    fixture = {};
    await createReservationFixture(adminApi, fixture);
  });

  test.afterEach(async () => {
    try {
      if (adminApi && fixture) {
        await cleanupReservationFixture(adminApi, fixture);
      }
    } finally {
      await adminApi?.dispose();
    }
  });

  test("requires authentication, creates a reservation, and reads it back", async ({ page }) => {
    const anonymousApi = await request.newContext();
    try {
      const anonymousResponse = await anonymousApi.get(`${API_ROOT}/reservas`);
      expect(anonymousResponse.status()).toBe(401);
    } finally {
      await anonymousApi.dispose();
    }

    const userApi = await request.newContext();
    try {
      const loginResponse = await userApi.post(`${API_ROOT}/usuarios/login`, {
        data: { email: fixture.email, password: fixture.password }
      });
      expect(loginResponse.status()).toBe(200);

      const adminOnlyResponse = await userApi.get(`${API_ROOT}/usuarios`);
      expect(adminOnlyResponse.status()).toBe(403);
    } finally {
      await userApi.dispose();
    }

    await loginThroughUi(page, fixture.email, fixture.password);
    await expect(page).toHaveURL(/\/reservas$/);
    await page.getByRole("button", { name: "Nueva reserva" }).click();

    const reservationForm = page.locator("form.reservation-form");
    await expect(reservationForm).toBeVisible();
    await reservationForm.locator('[name="espacioId"]').selectOption(String(fixture.space.id));
    await reservationForm.locator('[name="responsable"]').fill("Responsable E2E");
    await reservationForm.locator('[name="telefono"]').fill("55501011");
    await reservationForm.locator('[name="email"]').fill(fixture.email);
    await reservationForm.locator('[name="participantes"]').fill("12");
    await reservationForm.locator('[name="tipoActividad"]').fill("Prueba automatizada");
    await reservationForm.locator('[name="fechaInicio"]').fill(localDateTime(48));
    await reservationForm.locator('[name="fechaFin"]').fill(localDateTime(50));
    await reservationForm.locator("#reserva-metodo").selectOption("Efectivo");
    const confirmacion = page.waitForResponse(response => response.url().endsWith("/api/reservas/confirmar") && response.request().method() === "POST");
    await page.getByRole("button", { name: "Enviar solicitud", exact: true }).click();
    const respuesta = await confirmacion;
    expect(respuesta.status()).toBe(201);
    fixture.reservation = await respuesta.json();
    fixture.codigo = fixture.reservation.codigo;

    await expect(page.getByText("Solicitud de reserva enviada correctamente.")).toBeVisible();
    const reservationRow = page.getByRole("row").filter({ hasText: fixture.codigo });
    await expect(reservationRow).toBeVisible();

    await page.reload();
    await expect(page.getByRole("row").filter({ hasText: fixture.codigo })).toBeVisible();

    const listResponse = await adminApi.get(
      `${API_ROOT}/reservas?codigo=${encodeURIComponent(fixture.codigo)}`
    );
    expect(listResponse.status()).toBe(200);
    const reservations = await listResponse.json();
    const savedSummary = reservations.find((reservation) => reservation.codigo === fixture.codigo);
    expect(savedSummary).toBeDefined();
    fixture.reservation = savedSummary;

    const detailResponse = await adminApi.get(
      `${API_ROOT}/reservas/${savedSummary.id}`
    );
    expect(detailResponse.status()).toBe(200);
    const savedReservation = await detailResponse.json();
    expect(savedReservation.codigo).toBe(fixture.codigo);
    expect(savedReservation.creadoPorUsuarioId).toBe(fixture.user.id);
  });
});
