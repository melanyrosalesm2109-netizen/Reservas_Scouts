import { apiFetch } from "./api";

const API_URL = "http://localhost:8080/api/auditoria/resumen";

export async function obtenerResumenAuditoria() {
  const response = await apiFetch(API_URL);
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(
      data?.mensaje || "No se pudo cargar el resumen de auditoría."
    );
  }
  return data;
}
