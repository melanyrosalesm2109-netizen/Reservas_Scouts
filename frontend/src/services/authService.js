import { apiFetch } from "./api";

const API_URL = "http://localhost:8080/api/usuarios";

async function mensajeError(response) {
  const data = await response.json().catch(() => null);
  return data?.mensaje || data?.message || data?.detail;
}

export async function iniciarSesion(email, password) {
  const response = await apiFetch(`${API_URL}/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password })
  });

  if (!response.ok) {
    throw new Error(
      await mensajeError(response) || "Correo o contraseña incorrectos."
    );
  }

  return response.json();
}

export async function obtenerSesion() {
  const response = await apiFetch(`${API_URL}/sesion`);
  if (response.status === 401) {
    return null;
  }
  if (!response.ok) {
    throw new Error(
      await mensajeError(response) || "No se pudo verificar la sesión."
    );
  }
  return response.json();
}

export async function cerrarSesion() {
  const response = await apiFetch(`${API_URL}/logout`, {
    method: "POST"
  });
  if (!response.ok) {
    throw new Error(
      await mensajeError(response) || "No se pudo cerrar la sesión."
    );
  }
}
