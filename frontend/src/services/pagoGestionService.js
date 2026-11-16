import { apiFetch } from "./api";
import { avisarCambioPagos } from "./notificacionService";
const raiz = `${import.meta.env.VITE_API_URL || (import.meta.env.DEV ? "http://localhost:8080" : "")}/api/pagos`;
async function leer(res) {
  const datos = await res.json().catch(() => null);
  if (!res.ok) throw new Error(datos?.mensaje || "No se pudo completar la operación.");
  return datos;
}
export async function detallePago(id) { return leer(await apiFetch(`${raiz}/${id}/detalle`)); }
export async function cobrosDisponibles() { return leer(await apiFetch(`${raiz}/cobros-disponibles`)); }
export async function registrarCobro(datos, archivo) {
  const body = new FormData();
  body.append("datos", new Blob([JSON.stringify(datos)], { type: "application/json" }));
  if (archivo) body.append("comprobante", archivo);
  const pago = await leer(await apiFetch(`${raiz}/registrar-cobro`, { method: "POST", body }));
  avisarCambioPagos(); return pago;
}
export async function anularPago(id, motivo) {
  const datos = await leer(await apiFetch(`${raiz}/${id}/anular`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ motivo }) }));
  avisarCambioPagos(); return datos;
}
export const esTransferencia = pago => ["SINPE Móvil", "Transferencia bancaria"].includes(pago.metodo);
export const moneda = monto => Number(monto || 0).toLocaleString("es-CR", { style: "currency", currency: "CRC" });
export const fechaHoy = () => new Intl.DateTimeFormat("sv-SE", { timeZone: "America/Costa_Rica" }).format(new Date());
export const fechaCorta = valor => valor ? new Date(`${valor.slice(0, 10)}T12:00:00`).toLocaleDateString("es-CR") : "—";
export const fechaPlazoPago = valor => valor ? new Date(/[Zz]$|[+-]\d{2}:\d{2}$/.test(valor) ? valor : `${valor}-06:00`).toLocaleString("es-CR", { timeZone: "America/Costa_Rica", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "";
