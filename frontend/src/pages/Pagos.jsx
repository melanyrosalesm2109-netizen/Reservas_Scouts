import { useCallback, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Plus, Search, RotateCcw } from "lucide-react";
import { listarPagos } from "../services/pagoService";
import { listarReservas } from "../services/reservaService";
import { verificarPago } from "../services/reservaPagoService";
import { esTransferencia, fechaCorta, moneda } from "../services/pagoGestionService";
import { useAuth } from "../context/useAuth";
import ComprobanteViewer from "../components/ComprobanteViewer";
import RegistroCobro from "../components/RegistroCobro";
import DetallePago from "../components/DetallePago";
import ResumenPagos from "../components/ResumenPagos";
import "./Pagos.css";
import "./PagosGestion.css";

const filtrosVacios = { codigoReserva: "", metodo: "", estado: "", fechaDesde: "", fechaHasta: "" };

export default function Pagos() {
  const [searchParams] = useSearchParams();
  const reservaFiltro = searchParams.get("reservaId");
  const { usuario } = useAuth();
  const administrador = usuario?.rol === "Administrador";
  const [pagos, setPagos] = useState([]);
  const [reservas, setReservas] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [filtros, setFiltros] = useState(filtrosVacios);
  const [aplicados, setAplicados] = useState(filtrosVacios);
  const [tab, setTab] = useState("todos");
  const [comprobante, setComprobante] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [nuevo, setNuevo] = useState(false);
  const [revisando, setRevisando] = useState(null);
  const cargar = useCallback(async () => {
    try {
      const [lista, actividades] = await Promise.all([listarPagos(), listarReservas()]);
      setPagos(lista); setReservas(actividades); setError("");
    } catch (err) { setError(err.message); }
    finally { setCargando(false); }
  }, []);
  useEffect(() => {
    queueMicrotask(() => { void cargar(); });
    const actualizar = () => { if (document.visibilityState !== "hidden") void cargar(); };
    const timer = setInterval(actualizar, 5000);
    window.addEventListener("focus", actualizar);
    window.addEventListener("reservas-pagos-actualizados", actualizar);
    return () => { clearInterval(timer); window.removeEventListener("focus", actualizar); window.removeEventListener("reservas-pagos-actualizados", actualizar); };
  }, [cargar]);

  const porReserva = new Map(reservas.map(r => [r.id, r]));
  const activa = pago => !porReserva.has(pago.reservaId) || ["PENDIENTE", "APROBADA"].includes(porReserva.get(pago.reservaId).estado);
  const porRevisar = pago => pago.estado === "PENDIENTE" && esTransferencia(pago) && activa(pago);
  const porCobrar = pago => pago.estado === "PENDIENTE" && pago.metodo === "Efectivo" && activa(pago);
  const revisar = pagos.filter(porRevisar).length;
  const efectivo = pagos.filter(porCobrar).length;
  const visibles = pagos.filter(p => (!reservaFiltro || String(p.reservaId) === reservaFiltro) && (tab !== "revisar" || porRevisar(p)) && (tab !== "efectivo" || porCobrar(p))
    && (!aplicados.codigoReserva || p.reservaCodigo.toLowerCase().includes(aplicados.codigoReserva.trim().toLowerCase()))
    && (!aplicados.metodo || p.metodo === aplicados.metodo) && (!aplicados.estado || p.estado === aplicados.estado)
    && (!aplicados.fechaDesde || p.fechaPago >= aplicados.fechaDesde) && (!aplicados.fechaHasta || p.fechaPago <= aplicados.fechaHasta));

  async function resolver(pago, aprobar, motivo = null) {
    if (revisando !== null) return;
    if (aprobar && !window.confirm(pago.metodo === "Efectivo" ? "¿Confirmas que recibiste este dinero en efectivo?" : "¿Revisaste el comprobante y confirmas que el pago es correcto?")) return;
    setRevisando(pago.id); setError(""); setMensaje("");
    try {
      await verificarPago(pago.id, aprobar, motivo);
      setComprobante(null); setDetalle(null); await cargar();
      setMensaje(aprobar ? "Cobro confirmado y reserva aprobada." : "Pago rechazado y reserva cancelada. Se conserva el motivo en el historial.");
    } catch (err) { setError(err.message); throw err; }
    finally { setRevisando(null); }
  }
  function cobrar(pago) { void resolver(pago, true).catch(() => {}); }
  const comprobanteActual = comprobante && (pagos.find(p => p.id === comprobante.id) || comprobante);
  const puedeRevisar = comprobanteActual && porRevisar(comprobanteActual);
  const cambiarFiltro = event => setFiltros(f => ({ ...f, [event.target.name]: event.target.value }));

  return <div className="pagos-page">
    {comprobante && <ComprobanteViewer pago={comprobanteActual} onCerrar={() => setComprobante(null)}
      onAprobar={puedeRevisar ? () => resolver(comprobanteActual, true) : undefined}
      onRechazar={puedeRevisar ? motivo => resolver(comprobanteActual, false, motivo) : undefined} procesando={revisando !== null} />}
    {detalle && <DetallePago pago={detalle} administrador={administrador} onCerrar={() => setDetalle(null)} onComprobante={setComprobante} onCobrar={cobrar} onActualizado={() => void cargar()}
      onAnulado={() => { setDetalle(null); setMensaje("Registro anulado con motivo. Se conserva el historial y el saldo se actualizó."); void cargar(); }} />}
    {nuevo && <RegistroCobro onCerrar={() => setNuevo(false)} onRegistrado={pago => {
      setNuevo(false); setMensaje(pago.estado === "PAGADO" ? "Pago simulado aprobado y saldo actualizado." : pago.metodo === "Efectivo" ? "Efectivo agendado. Registra el cobro cuando recibas el dinero." : "Comprobante registrado y pendiente de revisión."); void cargar();
    }} />}
    <div className="pagos-header"><div><span className="pagos-label">REGISTRO DE COBROS</span><h1>Pagos</h1><p>Consulta saldos e historial. Los pendientes también se atienden desde <Link to="/notificaciones">Notificaciones</Link>.</p></div>
      <button className="pagos-add-button" type="button" onClick={() => setNuevo(true)}><Plus size={18} />Registrar cobro</button></div>
    {mensaje && <div className="mensaje-exito" role="status">{mensaje}</div>}{error && <div className="mensaje-error" role="alert">{error}</div>}
    {reservaFiltro && <p className="pago-aviso">Pagos y comprobantes de la reserva seleccionada. <Link to="/pagos">Ver todas las reservas</Link></p>}
    <ResumenPagos pagos={pagos} revisar={revisar} efectivo={efectivo} cargando={cargando}
      onPendientes={vista => { setTab(vista); setFiltros(filtrosVacios); setAplicados(filtrosVacios); }}
      onEstado={estado => { setTab("todos"); const f = { ...filtrosVacios, estado }; setFiltros(f); setAplicados(f); }}
      onMetodo={metodo => { setTab("todos"); const f = { ...filtrosVacios, metodo, estado: "PAGADO" }; setFiltros(f); setAplicados(f); }} />
    <div className="pagos-tabs" role="tablist" aria-label="Registro de pagos">
      {[['todos', 'Todos', pagos.length], ['revisar', 'Comprobantes por revisar', revisar], ['efectivo', 'Efectivo por cobrar', efectivo]].map(([id, label, count]) =>
        <button type="button" role="tab" aria-selected={tab === id} key={id} onClick={() => setTab(id)}>{label} <span>{count}</span></button>)}
    </div>
    <section className="pagos-panel">
      <form className="pagos-filtros" onSubmit={e => { e.preventDefault(); setAplicados({ ...filtros }); }}>
        <div className="pagos-search"><Search size={17} /><input name="codigoReserva" aria-label="Código de reserva" placeholder="Código de reserva…" value={filtros.codigoReserva} onChange={cambiarFiltro} /></div>
        <select name="metodo" aria-label="Método de pago" value={filtros.metodo} onChange={cambiarFiltro}><option value="">Todos los métodos</option>{['SINPE Móvil', 'Transferencia bancaria', 'Efectivo', 'Tarjeta'].map(m => <option key={m}>{m}</option>)}</select>
        <select name="estado" aria-label="Estado de pago" value={filtros.estado} onChange={cambiarFiltro}><option value="">Todos los estados</option>{['PENDIENTE', 'PAGADO', 'RECHAZADO', 'ANULADO', 'VENCIDO'].map(e => <option key={e}>{e}</option>)}</select>
        <label className="pago-filtro-fecha">Desde<input type="date" name="fechaDesde" value={filtros.fechaDesde} onChange={cambiarFiltro} /></label>
        <label className="pago-filtro-fecha">Hasta<input type="date" name="fechaHasta" value={filtros.fechaHasta} onChange={cambiarFiltro} /></label>
        <button type="submit" className="pagos-filter-button">Buscar</button><button type="button" className="pagos-clear-button" onClick={() => { setFiltros(filtrosVacios); setAplicados(filtrosVacios); }}><RotateCcw size={15} />Limpiar</button>
      </form>
      <div className="pagos-resultados">Mostrando {visibles.length} pago(s). Las fechas corresponden al registro del pago o al cobro previsto si es efectivo pendiente.</div>
      <p className="pago-scroll-ayuda">Desliza la tabla horizontalmente para ver todas las columnas.</p>
      <div className="pagos-table-wrapper"><table className="pagos-table"><thead><tr><th>Reserva / espacio</th><th>Monto</th><th>Método</th><th>Fecha y concepto</th><th>Estado</th><th>Acciones</th></tr></thead>
        <tbody>{cargando ? <tr><td colSpan={6} className="pagos-empty">Cargando pagos…</td></tr> : visibles.length === 0 ? <tr><td colSpan={6} className="pagos-empty">No hay pagos en esta vista.</td></tr> : visibles.map(pago => {
          const etiqueta = porCobrar(pago) ? "Efectivo pendiente" : porRevisar(pago) ? "Por revisar" : pago.estado;
          return <tr key={pago.id}>
            <td><strong className="pago-codigo">{pago.reservaCodigo}</strong><span className="pago-espacio-texto">{pago.espacio}</span></td><td><strong>{moneda(pago.monto)}</strong></td>
            <td>{pago.metodo}{pago.metodo === "Tarjeta" && <small className="pago-espacio-texto">Simulado</small>}</td>
            <td><span className="pago-fecha-concepto">{porCobrar(pago) ? "Cobro previsto" : pago.estado === "PAGADO" ? "Pagado el" : "Registrado el"}</span>{fechaCorta(pago.fechaPago)}</td>
            <td><span className={`pago-status ${pago.estado.toLowerCase()}`}>{etiqueta}</span></td>
            <td><div className="pago-actions-gestion"><button type="button" onClick={() => setDetalle(pago)}>Ver detalle</button>
              {porRevisar(pago) && <button type="button" className="pago-principal" onClick={() => setComprobante(pago)} disabled={pago.comprobante !== "Comprobante adjunto"}>Revisar comprobante</button>}
              {porCobrar(pago) && <button type="button" className="pago-principal" disabled={revisando !== null} onClick={() => cobrar(pago)}>Registrar cobro</button>}
              {!porRevisar(pago) && pago.comprobante === "Comprobante adjunto" && <button type="button" onClick={() => setComprobante(pago)}>Ver comprobante</button>}
            </div></td>
          </tr>;
        })}</tbody></table></div>
    </section>
  </div>;
}
