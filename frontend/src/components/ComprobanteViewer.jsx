import { useEffect, useRef, useState } from "react";
import { obtenerComprobante } from "../services/reservaPagoService";
import "./ComprobanteViewer.css";

export default function ComprobanteViewer({ pago, onCerrar, onAprobar, onRechazar, procesando = false }) {
  const dialogo = useRef(null);
  const [archivo, setArchivo] = useState(null);
  const [error, setError] = useState("");
  const [rechazando, setRechazando] = useState(false);
  const [motivo, setMotivo] = useState("");
  const [errorRevision, setErrorRevision] = useState("");
  async function revisar(aprobar) {
    if (procesando) return;
    setErrorRevision("");
    try { if (aprobar) await onAprobar(); else await onRechazar(motivo.trim()); }
    catch (err) { setErrorRevision(err.message); }
  }
  useEffect(() => {
    dialogo.current.showModal();
    let vigente = true;
    let url;
    obtenerComprobante(pago.id).then(datos => {
      url = datos.url;
      if (vigente) setArchivo(datos);
      else URL.revokeObjectURL(url);
    }).catch(err => { if (vigente) setError(err.message); });
    return () => { vigente = false; if (url) URL.revokeObjectURL(url); };
  }, [pago.id]);
  return <dialog ref={dialogo} className="comprobante-dialog" aria-labelledby="comprobante-titulo"
    onCancel={event => { event.preventDefault(); onCerrar(); }}>
    <header>
      <div><h2 id="comprobante-titulo">Comprobante de pago</h2><p>{pago.reservaCodigo} · {pago.metodo}{pago.monto != null ? ` · ${Number(pago.monto).toLocaleString("es-CR", { style: "currency", currency: "CRC" })}` : ""}</p></div>
      <button type="button" onClick={onCerrar} aria-label="Cerrar comprobante">×</button>
    </header>
    <div className="comprobante-contenido">
      {error ? <p role="alert">{error}</p> : !archivo ? <p role="status">Cargando comprobante…</p> :
        archivo.tipo === "application/pdf" ? <iframe src={archivo.url} title={`Comprobante PDF de ${pago.reservaCodigo}`} /> :
        archivo.tipo.startsWith("image/") ? <img src={archivo.url} alt={`Comprobante de ${pago.reservaCodigo}`} /> : <p>Descarga el archivo para revisarlo.</p>}
    </div>
    {(onAprobar || onRechazar) && <section className="comprobante-revision" aria-label="Revisión del comprobante">
      <p>Compara el monto, la referencia y los datos de la reserva antes de aprobar.</p>
      {errorRevision && <p role="alert">{errorRevision}</p>}
      {onAprobar && <button type="button" className="pago-principal" disabled={!archivo || procesando} onClick={() => void revisar(true)}>Aprobar pago</button>}
      {onRechazar && <button type="button" disabled={!archivo || procesando} onClick={() => setRechazando(true)}>Rechazar pago</button>}
      {rechazando && <form onSubmit={e => { e.preventDefault(); void revisar(false); }}><label htmlFor="visor-motivo">Motivo del rechazo *</label>
        <textarea id="visor-motivo" required maxLength={500} value={motivo} onChange={e => setMotivo(e.target.value)} />
        <p>Se cancelará la reserva y se conservará el motivo.</p><button type="submit" disabled={procesando || !motivo.trim()}>Confirmar rechazo</button></form>}
    </section>}
    <footer><span>Estado del pago: {pago.estado}</span>{archivo && <a href={archivo.url} download={archivo.nombre}>Descargar comprobante</a>}
      <button type="button" onClick={onCerrar}>Cerrar</button></footer>
  </dialog>;
}
