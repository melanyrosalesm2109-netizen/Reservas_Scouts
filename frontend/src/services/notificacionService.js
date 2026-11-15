import { apiFetch } from "./api";
const raiz = `${import.meta.env.VITE_API_URL || (import.meta.env.DEV ? "http://localhost:8080" : "")}/api`;
export async function listarNotificaciones() {
  const res = await apiFetch(`${raiz}/notificaciones`);
  const datos = await res.json().catch(() => null);
  if (!res.ok) throw new Error(datos?.mensaje || "No se pudieron cargar las notificaciones.");
  return datos;
}
export const esPendiente = n => n.pagoEstado === "PENDIENTE" && ["PENDIENTE", "APROBADA"].includes(n.reservaEstado)
  && ["SINPE Móvil", "Transferencia bancaria", "Efectivo"].includes(n.metodo);
export function avisarCambioPagos() {
  window.dispatchEvent(new Event("reservas-pagos-actualizados"));
  try { localStorage.setItem("reservas-pagos-actualizados", `${Date.now()}-${Math.random()}`); } catch { /* El sondeo sigue activo si el almacenamiento no esta disponible. */ }
}
