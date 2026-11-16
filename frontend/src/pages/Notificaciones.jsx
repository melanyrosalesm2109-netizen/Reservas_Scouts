import { useState } from "react";
import { useOutletContext, Link } from "react-router-dom";
import { Bell, CheckCircle2, Clock3, RefreshCw, ReceiptText } from "lucide-react";
import { verificarPago } from "../services/reservaPagoService";
import { esPendiente } from "../services/notificacionService";
import ComprobanteViewer from "../components/ComprobanteViewer";
import "./Notificaciones.css";
import { fechaPlazoPago } from "../services/pagoGestionService";

const moneda = monto => Number(monto || 0).toLocaleString("es-CR", { style: "currency", currency: "CRC" });
const fecha = valor => valor ? new Date(valor).toLocaleString("es-CR", { timeZone: "America/Costa_Rica", dateStyle: "medium", timeStyle: "short" }) : "Sin fecha";

export default function Notificaciones() {
  const { bandeja } = useOutletContext();
  const { notificaciones, cargando, error, actualizado, refrescar } = bandeja;
  const [tab, setTab] = useState("revisar");
  const [comprobante, setComprobante] = useState(null);
  const [procesando, setProcesando] = useState(null);
  const [rechazando, setRechazando] = useState(null);
  const [motivo, setMotivo] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [errorAccion, setErrorAccion] = useState("");
  const revisar = notificaciones.filter(n => esPendiente(n) && n.metodo !== "Efectivo");
  const efectivo = notificaciones.filter(n => esPendiente(n) && n.metodo === "Efectivo");
  const reservas = notificaciones.filter((n, i, lista) => lista.findIndex(otra => otra.reservaId === n.reservaId) === i);
  const historial = notificaciones.filter(n => n.pagoId && !esPendiente(n));
  const pestañas = [
    { id: "revisar", texto: "Pagos por revisar", cantidad: revisar.length },
    { id: "efectivo", texto: "Efectivo por cobrar", cantidad: efectivo.length },
    { id: "reservas", texto: "Reservas realizadas", cantidad: reservas.length },
    { id: "historial", texto: "Historial", cantidad: historial.length }
  ];
  const datos = { revisar, efectivo, reservas, historial }[tab];

  async function resolver(n, aprobar) {
    if (procesando !== null) return;
    if (aprobar && !window.confirm(n.metodo === "Efectivo" ? "¿Confirmas que recibiste este pago en efectivo?" : "¿Revisaste el comprobante y confirmas que el pago es correcto?")) return;
    setProcesando(n.pagoId); setErrorAccion(""); setMensaje("");
    try {
      await verificarPago(n.pagoId, aprobar, aprobar ? null : motivo.trim());
      setRechazando(null); setMotivo("");
      await refrescar();
      setMensaje(aprobar ? "Pago verificado. Ya no está pendiente para ningún administrador o recepcionista." : "Pago rechazado y reserva cancelada. Se retiró de la bandeja compartida.");
    } catch (err) { setErrorAccion(err.message); await refrescar(); }
    finally { setProcesando(null); }
  }

  return <div className="notificaciones-page">
    {comprobante && <ComprobanteViewer pago={comprobante} onCerrar={() => setComprobante(null)} />}
    <header className="notificaciones-header"><div><span>BANDEJA COMPARTIDA</span><h1><Bell size={29} /> Notificaciones</h1>
      <p>Reservas y pagos para administración y recepción. Lo que una persona resuelve deja de estar pendiente para todos.</p></div>
      <button type="button" onClick={() => void refrescar()}><RefreshCw size={16} /> Actualizar</button></header>
    <p className="notificaciones-sync">Se sincroniza cada 5 segundos y al volver a esta ventana.{actualizado && ` Última actualización: ${actualizado.toLocaleTimeString("es-CR", { timeZone: "America/Costa_Rica" })}.`}</p>
    {(error || errorAccion) && <div className="notificaciones-error" role="alert">{errorAccion || error}</div>}
    {mensaje && <div className="notificaciones-exito" role="status">{mensaje}</div>}
    <div className="notificaciones-tabs" role="tablist" aria-label="Bandejas de notificaciones">
      {pestañas.map(p => <button type="button" role="tab" aria-selected={tab === p.id} aria-controls="notificaciones-lista" key={p.id} onClick={() => { setTab(p.id); setRechazando(null); setMotivo(""); }}>
        {p.texto}<span>{p.cantidad}</span></button>)}
    </div>
    <section id="notificaciones-lista" role="tabpanel" aria-label={pestañas.find(p => p.id === tab).texto}>
      {tab === "efectivo" && <p className="notificaciones-ayuda">El cupo está guardado y la reserva sigue pendiente. Registra el efectivo al recibirlo para aprobarla, incluso antes de la llegada.</p>}
      {cargando ? <p role="status">Cargando notificaciones…</p> : datos.length === 0 ? <div className="notificaciones-vacio"><CheckCircle2 size={38} /><h2>No hay notificaciones en esta bandeja</h2><p>Los nuevos registros aparecerán automáticamente.</p></div> :
        datos.map(n => {
          const pendiente = esPendiente(n) && ["revisar", "efectivo"].includes(tab);
          return <article className="notificacion-card" key={tab === "reservas" ? n.reservaId : n.pagoId}>
            <div className="notificacion-cabecera"><div><strong>{n.codigo}</strong><h2>{n.espacio}</h2><p>{n.solicitante} · {n.participantes} participantes</p></div>
              <span className={`notificacion-estado ${pendiente ? "pendiente" : ""}`}>{pendiente ? n.metodo === "Efectivo" ? "Efectivo pendiente" : "Comprobante por revisar" : n.reservaEstado === "APROBADA" ? "Reservada" : n.reservaEstado}</span></div>
            <div className="notificacion-detalles"><p><Clock3 size={15} />{fecha(n.fechaInicio)} — {fecha(n.fechaFin)}</p>
              <p><ReceiptText size={15} />{n.metodo || "Sin método de pago"}{n.pagoId ? ` · ${moneda(n.monto)} · ${n.pagoEstado}` : ""}</p></div>
            {pendiente && n.pagoVenceEn && <p className="notificacion-revision">Pagar antes de {fechaPlazoPago(n.pagoVenceEn)}. Al vencer sin pago se libera el cupo.</p>}
            {n.reservaEstado === "VENCIDA" && <p className="notificacion-revision">Plazo de pago vencido. El cupo fue liberado y el historial se conserva.</p>}
            {n.revisadoPor && <p className="notificacion-revision">Revisado por {n.revisadoPor} · {fecha(n.revisadaEn)}{n.motivo ? ` · Motivo: ${n.motivo}` : ""}</p>}
            {n.metodo === "Tarjeta" && n.pagoEstado === "PAGADO" && <p className="notificacion-revision">Tarjeta simulada aprobada automáticamente.</p>}
            <div className="notificacion-acciones">
              {n.tieneComprobante && <button type="button" onClick={() => setComprobante({ id: n.pagoId, reservaCodigo: n.codigo, metodo: n.metodo, estado: n.pagoEstado })}>Ver comprobante</button>}
              <Link to={`/reservas?espacioId=${n.espacioId || ""}&codigo=${encodeURIComponent(n.codigo)}`}>Ver reserva</Link>
              {pendiente && <>
                <button type="button" className="notificacion-aprobar" disabled={procesando !== null || (n.metodo !== "Efectivo" && !n.tieneComprobante)}
                  onClick={() => void resolver(n, true)}>{n.metodo === "Efectivo" ? "Registrar efectivo recibido" : "Aprobar pago"}</button>
                <button type="button" disabled={procesando !== null} onClick={() => { setRechazando(n.pagoId); setMotivo(""); }}>Rechazar</button>
              </>}
            </div>
            {pendiente && n.metodo !== "Efectivo" && !n.tieneComprobante && <p role="status">Falta el comprobante. No se puede aprobar todavía.</p>}
            {pendiente && rechazando === n.pagoId && <form className="notificacion-rechazo" onSubmit={e => { e.preventDefault(); void resolver(n, false); }}>
              <p className="required-fields-note"><span className="required-mark">*</span> indica un campo obligatorio.</p><label htmlFor={`motivo-${n.pagoId}`}>Motivo del rechazo <span className="required-mark" aria-hidden="true">*</span></label><textarea id={`motivo-${n.pagoId}`} value={motivo} onChange={e => setMotivo(e.target.value)} required maxLength={500} />
              <p>El rechazo cancela la reserva y libera el horario.</p><button type="submit" disabled={procesando !== null || !motivo.trim()}>Confirmar rechazo</button>
              <button type="button" onClick={() => setRechazando(null)}>Cancelar</button>
            </form>}
          </article>;
        })}
    </section>
  </div>;
}
