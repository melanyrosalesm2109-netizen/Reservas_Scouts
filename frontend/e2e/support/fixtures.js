import process from "node:process";
import { randomUUID } from "node:crypto";
import { request } from "@playwright/test";

const API_ROOT = "http://localhost:8080/api";

export function getAdminCredentials() {
  const email = process.env.E2E_ADMIN_EMAIL || "admin@reservasscouts.com";
  const password = process.env.E2E_ADMIN_PASSWORD;

  if (!password) {
    throw new Error("Set E2E_ADMIN_PASSWORD before running the E2E suite.");
  }

  return { email, password };
}

async function requireOk(response, operation) {
  if (!response.ok()) {
    const body = await response.text();
    throw new Error(`${operation} failed with HTTP ${response.status()}: ${body}`);
  }
}

export async function createAdminApi() {
  const api = await request.newContext();
  const response = await api.post(`${API_ROOT}/usuarios/login`, {
    data: getAdminCredentials()
  });

  if (!response.ok()) {
    const body = await response.text();
    await api.dispose();
    throw new Error(`Admin API login failed with HTTP ${response.status()}: ${body}`);
  }

  return api;
}

export async function createReservationFixture(api, fixture) {
  const suffix = randomUUID().replaceAll("-", "").slice(0, 12);
  fixture.email = `e2e.${suffix}@example.com`;
  fixture.password = `Test_${randomUUID()}_A1`;
  fixture.codigo = `E2E${suffix}`;

  const rolesResponse = await api.get(`${API_ROOT}/usuarios/roles`);
  await requireOk(rolesResponse, "List user roles");
  const roles = await rolesResponse.json();
  const userRole = roles.find((role) => role.nombre === "Usuario");

  if (!userRole) {
    throw new Error("The Usuario role is missing from the database.");
  }

  const userResponse = await api.post(`${API_ROOT}/usuarios`, {
    data: {
      rolId: userRole.id,
      email: fixture.email,
      password: fixture.password,
      estado: "ACTIVO"
    }
  });
  await requireOk(userResponse, "Create temporary user");
  fixture.user = await userResponse.json();

  const profileResponse = await api.post(`${API_ROOT}/perfiles`, {
    data: {
      usuarioId: fixture.user.id,
      nombre: `E2E Persona ${suffix}`,
      identificacion: suffix,
      telefono: "55501010",
      correoContacto: fixture.email,
      tipoPerfil: "Persona",
      direccion: "Perfil temporal de pruebas"
    }
  });
  await requireOk(profileResponse, "Create temporary profile");
  fixture.profile = await profileResponse.json();

  const spaceResponse = await api.post(`${API_ROOT}/espacios`, {
    data: {
      nombre: `E2E Espacio ${suffix}`,
      descripcion: "Espacio temporal de pruebas automatizadas",
      ubicacion: "Ubicacion de pruebas",
      capacidad: 40,
      costo: 0,
      estado: "DISPONIBLE",
      imagen: null
    }
  });
  await requireOk(spaceResponse, "Create temporary space");
  fixture.space = await spaceResponse.json();
}

export async function cleanupReservationFixture(api, fixture) {
  const resources = [
    fixture.reservation && [`${API_ROOT}/reservas/${fixture.reservation.id}`, "reservation"],
    fixture.profile && [`${API_ROOT}/perfiles/${fixture.profile.idPerfil}`, "profile"],
    fixture.space && [`${API_ROOT}/espacios/${fixture.space.id}`, "space"],
    fixture.user && [`${API_ROOT}/usuarios/${fixture.user.id}`, "user"]
  ].filter(Boolean);
  const failures = [];

  for (const [url, resource] of resources) {
    const response = await api.delete(url);
    if (!response.ok()) {
      failures.push(`${resource}: HTTP ${response.status()} ${await response.text()}`);
    }
  }

  if (failures.length > 0) {
    throw new AggregateError(
      failures.map((failure) => new Error(failure)),
      "Could not clean up all temporary reservation test data."
    );
  }
}

export async function loginThroughUi(page, email, password) {
  await page.goto("/login");
  await page.getByPlaceholder("Ingrese su correo").fill(email);
  await page.getByPlaceholder("Ingrese su contraseña").fill(password);
  await page.getByRole("button", { name: "Iniciar sesión" }).click();
}

export function localDateTime(hoursFromNow) {
  const date = new Date(Date.now() + hoursFromNow * 60 * 60 * 1000);
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60 * 1000);
  return local.toISOString().slice(0, 16);
}

export { API_ROOT };
