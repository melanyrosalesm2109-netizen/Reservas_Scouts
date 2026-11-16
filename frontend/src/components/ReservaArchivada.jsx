import { useState } from "react";
import { obtenerReservaArchivada } from "../services/reservaPagoService";
import { moneda } from "../services/pagoGestionService";
import ComprobanteViewer from "./ComprobanteViewer";
import "./ReservaArchivada.css";

export default function ReservaArchivada({ id }) {
  const [archivo, setArchivo] = useState(null);
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(false);
  const [comprobante, setComprobante] = useState(null);
  async function consultar() {
    setCargando(true); setError("");
    try { setArchivo(await obtenerReservaArchivada(id)); }
    catch (err) { setError(err.message); }
    finally { setCargando(false); }
  }
  return <section className="reserva-archivo" aria-label="Archivo de reserva eliminada">
    <h3>Reserva eliminada · historial conservado</h3>
    {!archivo && <button type="button" disabled={cargando} onClick={() => void consultar()}>{cargando ? "Consultando…" : "Consultar reserva y pagos archivados"}</button>}
    {error && <p role="alert">{error}</p>}
    {archivo && <>
      <p><strong>{archivo.reserva.codigo}</strong> · {archivo.reserva.espacio} · {archivo.reserva.solicitante}</p>
      <p>Los archivos y las revisiones corresponden al momento de la eliminación.</p>
      {archivo.pagos.length === 0 && <p>Esta reserva no tenía pagos registrados.</p>}
      {archivo.pagos.map(pago => <article key={pago.id}>
        <h4>Pago #{pago.id} · {pago.metodo}</h4>
        <p>{moneda(pago.monto)} · {pago.estado}</p>
        <p>Validación: {pago.comprobanteCorrecto === true ? "Correcto · aprobado" : pago.comprobanteCorrecto === false ? "Incorrecto · rechazado" : pago.archivoNombre ? "Pendiente de revisión" : "Sin comprobante"}</p>
        {pago.revisadoPor && <p>Revisado por {pago.revisadoPor}{pago.revisadaEn ? ` · ${new Date(`${pago.revisadaEn}Z`).toLocaleString("es-CR", { timeZone: "America/Costa_Rica" })}` : ""}{pago.motivoRevision ? ` · Motivo: ${pago.motivoRevision}` : ""}</p>}
        {pago.motivoAnulacion && <p>Anulación: {pago.motivoAnulacion}</p>}
        {pago.archivoNombre && <button type="button" onClick={() => setComprobante({ ...pago, reservaCodigo: archivo.reserva.codigo })}>Ver comprobante del pago #{pago.id}</button>}
      </article>)}
    </>}
    {comprobante && <ComprobanteViewer pago={comprobante} onCerrar={() => setComprobante(null)} />}
  </section>;
}
