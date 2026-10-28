import { apiFetch } from "./api";

const API_URL = "http://localhost:8080/api/auditoria";

async function procesarRespuesta(response, mensajeError) {
  const data = await response.json().catch(() => null);

  if (!response.ok) {
    throw new Error(
      data?.mensaje || mensajeError
    );
  }

  return data;
}

export async function obtenerResumenAuditoria() {
  const response = await apiFetch(
    `${API_URL}/resumen`
  );

  return procesarRespuesta(
    response,
    "No se pudo cargar el resumen de auditoría."
  );
}

export async function obtenerDetalleAuditoria() {
  const response = await apiFetch(
    `${API_URL}/detalle`
  );

  return procesarRespuesta(
    response,
    "No se pudo cargar el historial de auditoría."
  );
}