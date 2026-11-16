import { useEffect, useRef, useState } from "react";
import { anularPago, detallePago, esTransferencia, fechaCorta, moneda, fechaPlazoPago } from "../services/pagoGestionService";
import { adjuntarComprobante } from "../services/reservaPagoService";

export default function DetallePago({ pago, administrador, onCerrar, onComprobante, onCobrar, onAnulado, onActualizado }) {
  const ref = useRef(null);
  const [datos, setDatos] = useState(null);
  const [error, setError] = useState("");
  const [anulando, setAnulando] = useState(false);
  const [motivo, setMotivo] = useState("");
  const [guardando, setGuardando] = useState(false);
  const [archivo, setArchivo] = useState(null);
  useEffect(() => {
    ref.current.showModal(); let vigente = true;
    detallePago(pago.id).then(d => { if (vigente) setDatos(d); }).catch(err => { if (vigente) setError(err.message); });
    return () => { vigente = false; };
  }, [pago.id]);
  const actual = datos?.pago || pago;
  const activo = datos && ["PENDIENTE", "APROBADA"].includes(datos.reservaEstado);
  const pendiente = activo && actual.estado === "PENDIENTE";
  async function adjuntar(event) {
    event.preventDefault();
    if (guardando || !archivo) return;
    setGuardando(true); setError("");
    try {
      await adjuntarComprobante(actual.id, archivo);
      setDatos(await detallePago(actual.id)); setArchivo(null);
      onActualizado?.();
    } catch (err) { setError(err.message); }
    finally { setGuardando(false); }
  }
  async function anular(event) {
    event.preventDefault(); if (guardando || !motivo.trim()) return;
    if (!window.confirm("¿Anular este registro de pago? Se conservará el historial y puede quedar un saldo pendiente. Esta acción no realiza un reembolso bancario.")) return;
    setGuardando(true); setError("");
    try { await anularPago(actual.id, motivo.trim()); onAnulado(); }
    catch (err) { setError(err.message); }
    finally { setGuardando(false); }
  }
  return <dialog ref={ref} className="pago-gestion-dialog" aria-labelledby="detalle-pago-titulo" onCancel={e => { e.preventDefault(); if (!guardando) onCerrar(); }}>
    <header><div><h2 id="detalle-pago-titulo">Detalle del pago</h2><p>{actual.reservaCodigo} · {actual.espacio}</p></div><button type="button" disabled={guardando} onClick={onCerrar} aria-label="Cerrar detalle">×</button></header>
    <div className="pago-detalle-cuerpo">
      {error && <p className="mensaje-error" role="alert">{error}</p>}
      <dl><div><dt>Monto</dt><dd>{moneda(actual.monto)}</dd></div><div><dt>Método</dt><dd>{actual.metodo}</dd></div><div><dt>Estado del pago</dt><dd>{actual.estado}</dd></div>
        <div><dt>{actual.metodo === "Efectivo" && actual.estado === "PENDIENTE" ? "Cobro previsto" : "Fecha registrada"}</dt><dd>{fechaCorta(actual.fechaPago)}</dd></div>
        {datos && <><div><dt>Estado de la reserva</dt><dd>{datos.reservaEstado}</dd></div><div><dt>Llegada</dt><dd>{fechaCorta(datos.fechaInicio)}</dd></div><div><dt>Costo de la reserva</dt><dd>{moneda(datos.costo)}</dd></div><div><dt>Saldo sin pagar</dt><dd>{moneda(datos.saldo)}</dd></div></>}
      </dl>
      {actual.notas && <p className="pago-ayuda">{actual.notas}</p>}
      {pendiente && <p className="pago-aviso">El cupo está reservado. La reserva se aprobará al confirmar el pago completo.{datos?.pagoVenceEn && <> Plazo de pago: <strong>{fechaPlazoPago(datos.pagoVenceEn)}</strong>.</>}</p>}
      {datos?.reservaEstado === "VENCIDA" && <p className="pago-aviso">El plazo terminó sin pago confirmado. El cupo fue liberado; consulta la disponibilidad antes de crear otra reserva.</p>}
      {actual.metodo === "Tarjeta" && <p className="pago-ayuda">Pago con tarjeta de simulación. No representa un cobro real.</p>}
      {esTransferencia(actual) && datos && <p className="pago-aviso">Validación del comprobante: <strong>{datos.comprobanteCorrecto === true ? "Correcto · aprobado" : datos.comprobanteCorrecto === false ? "Incorrecto · rechazado" : datos.tieneComprobante ? "Pendiente de revisión" : "Sin comprobante adjunto"}</strong></p>}
      {datos?.revisadoPor && <p>Revisado por {datos.revisadoPor} · {new Date(datos.revisadaEn).toLocaleString("es-CR")}{datos.motivoRevision ? ` · ${datos.motivoRevision}` : ""}</p>}
      {datos?.anuladoPor && <div className="pago-aviso">Anulado por {datos.anuladoPor} · {new Date(datos.anuladaEn).toLocaleString("es-CR")}<p>Motivo: {datos.motivoAnulacion}</p></div>}
      {!datos && !error && <p role="status">Consultando saldo e historial…</p>}
      {datos?.tieneComprobante && <button type="button" onClick={() => onComprobante(actual)}>{pendiente && esTransferencia(actual) ? "Revisar comprobante" : "Ver comprobante"}</button>}
      {pendiente && esTransferencia(actual) && !datos.tieneComprobante && <form onSubmit={adjuntar}>
        <label htmlFor="adjuntar-comprobante">Comprobante de {actual.metodo} para {actual.reservaCodigo} *</label>
        <input id="adjuntar-comprobante" type="file" accept="application/pdf,image/png,image/jpeg" required disabled={guardando} onChange={event => {
          const file = event.target.files[0]; setArchivo(null);
          if (file && (file.size > 5242880 || !["application/pdf", "image/png", "image/jpeg"].includes(file.type))) {
            setError("Adjunta un PDF, PNG o JPG de hasta 5 MB."); event.target.value = ""; return;
          }
          setError(""); setArchivo(file || null);
        }} />
        <p className="pago-ayuda">El archivo se guarda únicamente en este pago. Debe revisarse antes de aprobarlo.</p>
        <button type="submit" disabled={guardando || !archivo}>{guardando ? "Guardando…" : "Adjuntar comprobante"}</button>
      </form>}
      {pendiente && actual.metodo === "Efectivo" && <><p>Confirma únicamente el dinero que hayas recibido.</p><button type="button" className="pago-principal" onClick={() => onCobrar(actual)}>Registrar cobro</button></>}
      {administrador && actual.estado === "PAGADO" && <><p className="pago-ayuda">El monto, método y estado de un pago aprobado no se editan ni se eliminan directamente.</p><button type="button" onClick={() => setAnulando(true)}>Anular registro de pago</button></>}
      {anulando && <form className="pago-anulacion" onSubmit={anular}><label htmlFor="anulacion-motivo">Motivo de la anulación *</label><textarea id="anulacion-motivo" required maxLength={500} value={motivo} onChange={e => setMotivo(e.target.value)} />
        <p>El comprobante y la revisión se conservan. La anulación del registro no ejecuta un reembolso.</p><button type="submit" disabled={guardando || !motivo.trim()}>Confirmar anulación</button></form>}
    </div><footer><button type="button" disabled={guardando} onClick={onCerrar}>Cerrar</button></footer>
  </dialog>;
}
