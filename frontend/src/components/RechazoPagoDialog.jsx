import { useEffect, useRef, useState } from "react";
import { X } from "lucide-react";
import "./RechazoPagoDialog.css";
export default function RechazoPagoDialog({ pago, onCerrar, onConfirmar }) {
  const ref = useRef(null);
  const [motivo, setMotivo] = useState("");
  const [error, setError] = useState("");
  const [ocupado, setOcupado] = useState(false);
  useEffect(() => {
    ref.current.showModal();
    const previo = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { document.body.style.overflow = previo; };
  }, []);
  const enviar = async event => {
    event.preventDefault();
    if (!motivo.trim()) { setError("Indica el motivo del rechazo."); return; }
    setOcupado(true); setError("");
    try { await onConfirmar(motivo.trim()); }
    catch (err) { setError(err.message); setOcupado(false); }
  };
  return <dialog ref={ref} className="rechazo-pago-dialog" aria-labelledby="rechazo-titulo" onCancel={event => { event.preventDefault(); if (!ocupado) onCerrar(); }}>
    <header><div><span>REVISIÓN DEL PAGO</span><h2 id="rechazo-titulo">Rechazar pago</h2></div><button type="button" aria-label="Cerrar rechazo" disabled={ocupado} onClick={onCerrar}><X size={20} /></button></header>
    <p>Reserva <strong>{pago.reservaCodigo || `#${pago.reservaId}`}</strong>. Al confirmar, el pago se marcará como rechazado y la reserva se cancelará para liberar el horario.</p>
    <form onSubmit={enviar}><p className="required-fields-note"><span className="required-mark">*</span> indica un campo obligatorio.</p><label htmlFor="rechazo-motivo">Motivo del rechazo <span className="required-mark">*</span></label>
      <textarea id="rechazo-motivo" value={motivo} onChange={event => setMotivo(event.target.value)} required maxLength={500} rows={4} disabled={ocupado} placeholder="Explica por qué se rechaza el pago" />
      {error && <p role="alert">{error}</p>}
      <footer><button type="button" disabled={ocupado} onClick={onCerrar}>Volver</button><button className="rechazo-confirmar" type="submit" disabled={ocupado}>{ocupado ? "Rechazando…" : "Confirmar rechazo"}</button></footer>
    </form>
  </dialog>;
}
