import { apiFetch } from "./api";

const API_URL = "http://localhost:8080/api/respaldo";

async function procesarRespuesta(response) {
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.mensaje || "La operación de respaldo falló.");
  }
  return data;
}

export async function listarRespaldos() {
  return procesarRespuesta(await apiFetch(API_URL));
}

export async function crearRespaldo() {
  return procesarRespuesta(await apiFetch(API_URL, { method: "POST" }));
}

export async function restaurarRespaldo(nombreArchivo, confirmacion) {
  return procesarRespuesta(await apiFetch(`${API_URL}/restaurar`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ nombreArchivo, confirmacion })
  }));
}
