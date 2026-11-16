import { avisarCambioPagos } from "./notificacionService";
import { apiFetch } from "./api";
const raiz = `${import.meta.env.VITE_API_URL || (import.meta.env.DEV ? "http://localhost:8080" : "")}/api`;
async function respuesta(res) {
  const datos = await res.json().catch(() => null);
  if (!res.ok) throw new Error(datos?.mensaje || datos?.detail || "No se pudo completar la operación.");
  return datos;
}
export async function bloquearHorario(datos) {
  return respuesta(await apiFetch(`${raiz}/reservas/bloqueos`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(datos) }));
}
export async function consultarPoliticaPago() {
  return respuesta(await apiFetch(`${raiz}/reservas/politica-pago`));
}
export async function liberarHorario(token) {
  await apiFetch(`${raiz}/reservas/bloqueos/${token}`, { method: "DELETE", keepalive: true });
}
export async function listarBloqueos() {
  return respuesta(await apiFetch(`${raiz}/reservas/bloqueos`));
}
export async function confirmarReserva(reserva, pago) {
  const datos = new FormData();
  datos.append("datos", new Blob([JSON.stringify({ reserva, bloqueo: pago.token, metodo: pago.metodo, tarjeta: pago.metodo === "Tarjeta" ? pago.tarjeta : null })], { type: "application/json" }));
  if (pago.archivo) datos.append("comprobante", pago.archivo);
  return respuesta(await apiFetch(`${raiz}/reservas/confirmar`, { method: "POST", body: datos }));
}
export async function verificarPago(id, aprobar, motivo = null) {
  const datos = await respuesta(await apiFetch(`${raiz}/pagos/${id}/verificar`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ aprobar, ...(motivo ? { motivo } : {}) }) }));
  avisarCambioPagos();
  return datos;
}
export async function obtenerComprobante(id) {
  const res = await apiFetch(`${raiz}/pagos/${id}/comprobante`);
  if (!res.ok) return respuesta(res);
  const blob = await res.blob();
  const nombre = /filename="([^"]+)"/.exec(res.headers.get("Content-Disposition") || "");
  return { url: URL.createObjectURL(blob), tipo: blob.type, nombre: nombre?.[1] || "comprobante" };
}
export async function adjuntarComprobante(id, archivo) {
  const body = new FormData();
  body.append("comprobante", archivo);
  const datos = await respuesta(await apiFetch(`${raiz}/pagos/${id}/comprobante`, { method: "POST", body }));
  avisarCambioPagos();
  return datos;
}
export async function obtenerReservaArchivada(id) {
  const datos = await respuesta(await apiFetch(`${raiz}/reservas/${id}/archivo`));
  return { ...datos, reserva: JSON.parse(datos.reservaJson), pagos: JSON.parse(datos.pagosJson) };
}
export async function descargarComprobante(id) {
  const archivo = await obtenerComprobante(id);
  const enlace = document.createElement("a");
  enlace.href = archivo.url;
  enlace.download = archivo.nombre;
  enlace.click();
  setTimeout(() => URL.revokeObjectURL(archivo.url), 10000);
}
