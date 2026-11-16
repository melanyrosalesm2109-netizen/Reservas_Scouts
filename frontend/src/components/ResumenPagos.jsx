import { useState } from "react";
import { ArrowUpRight, CheckCheck, Clock3, ReceiptText, Wallet, CreditCard, Landmark, Smartphone } from "lucide-react";
import { moneda, fechaHoy } from "../services/pagoGestionService";
import "./ResumenPagos.css";

const estados = [
  { id: "PAGADO", nombre: "Pagados", color: "#2f8b79" },
  { id: "PENDIENTE", nombre: "Pendientes", color: "#d8ad60" },
  { id: "RECHAZADO", nombre: "Rechazados", color: "#c37c73" },
  { id: "ANULADO", nombre: "Anulados", color: "#8b80a5" },
  { id: "VENCIDO", nombre: "Vencidos", color: "#8c999c" }
];
const metodos = [
  { id: "SINPE Móvil", icono: Smartphone, color: "#2f8b79" },
  { id: "Transferencia bancaria", icono: Landmark, color: "#527a94" },
  { id: "Efectivo", icono: Wallet, color: "#c49a50" },
  { id: "Tarjeta", icono: CreditCard, color: "#8b80a5" }
];
const abreviado = valor => new Intl.NumberFormat("es-CR", { notation: "compact", maximumFractionDigits: 1 }).format(valor);
const porcentaje = (valor, total) => total ? Math.round(valor * 100 / total) : 0;

export default function ResumenPagos({ pagos, revisar, efectivo, cargando, onPendientes, onEstado, onMetodo }) {
  const [dias, setDias] = useState(30);
  const pagados = pagos.filter(p => p.estado === "PAGADO");
  const total = pagados.reduce((suma, p) => suma + Number(p.monto), 0);
  const distribucion = estados.map(e => ({ ...e, cantidad: pagos.filter(p => p.estado === e.id).length }));
  const porMetodo = metodos.map(m => ({ ...m, monto: pagados.filter(p => p.metodo === m.id).reduce((s, p) => s + Number(p.monto), 0) })).sort((a, b) => b.monto - a.monto);
  const hoy = new Date(`${fechaHoy()}T12:00:00Z`);
  const serie = Array.from({ length: dias }, (_, i) => {
    const d = new Date(hoy); d.setUTCDate(d.getUTCDate() - dias + 1 + i);
    const fecha = d.toISOString().slice(0, 10);
    return { fecha, monto: pagados.filter(p => p.fechaPago?.slice(0, 10) === fecha).reduce((s, p) => s + Number(p.monto), 0) };
  });
  const maximo = Math.max(...serie.map(d => d.monto), 1);
  const totalPeriodo = serie.reduce((s, d) => s + d.monto, 0);
  const etiquetaFecha = fecha => new Date(`${fecha}T12:00:00Z`).toLocaleDateString("es-CR", { day: "numeric", month: "short", timeZone: "UTC" });

  if (cargando) return <section className="resumen-pagos resumen-pagos-cargando" aria-busy="true"><p role="status">Preparando el resumen de pagos…</p></section>;
  return <section className="resumen-pagos" aria-label="Resumen gráfico de pagos">
    <div className="rp-titulo"><div><span className="rp-eyebrow">PANORAMA FINANCIERO</span><h2>Los pagos, de un vistazo</h2></div><span className="rp-actualizacion"><i />Actualización automática</span></div>
    <div className="rp-superior">
      <article className="rp-total">
        <div className="rp-total-encabezado"><span>Total registrado como pagado</span><span className="rp-icono-total"><Wallet size={20} /></span></div>
        <strong className="rp-importe">{moneda(total)}</strong>
        <p className="rp-total-contexto">Acumulado de todos los registros pagados</p>
        <div className="rp-tasa"><span><CheckCheck size={16} />{pagados.length} de {pagos.length} pagos completados</span><b>{porcentaje(pagados.length, pagos.length)}%</b></div>
        <div className="rp-progreso" aria-hidden="true"><span style={{ width: `${porcentaje(pagados.length, pagos.length)}%` }} /></div>
        <div className="rp-tareas">
          <button type="button" onClick={() => onPendientes("revisar")}><ReceiptText size={18} /><span><strong>{revisar}</strong><small>Comprobantes por revisar</small></span><ArrowUpRight size={17} /></button>
          <button type="button" onClick={() => onPendientes("efectivo")}><Clock3 size={18} /><span><strong>{efectivo}</strong><small>Efectivo por cobrar</small></span><ArrowUpRight size={17} /></button>
        </div>
      </article>
      <article className="rp-tarjeta rp-estados"><div className="rp-card-titulo"><div><span className="rp-eyebrow">ESTADO DEL REGISTRO</span><h3>Distribución de pagos</h3></div><span className="rp-unidad">Por cantidad</span></div>
        <div className="rp-distribucion"><div className="rp-donut">
          <svg viewBox="0 0 160 160" role="img" aria-label={`Distribución de ${pagos.length} pagos: ${distribucion.map(e => `${e.cantidad} ${e.nombre.toLowerCase()}`).join(", ")}`}>
            <circle cx="80" cy="80" r="57" fill="none" stroke="#eef0ee" strokeWidth="16" />
            {distribucion.map((e, indice) => {
              const longitud = pagos.length ? e.cantidad / pagos.length * 358.142 : 0;
              const offset = pagos.length ? distribucion.slice(0, indice).reduce((s, anterior) => s + anterior.cantidad, 0) / pagos.length * 358.142 : 0;
              return e.cantidad > 0 && <circle key={e.id} cx="80" cy="80" r="57" fill="none" stroke={e.color} strokeWidth="16"
                strokeDasharray={`${longitud} ${358.142 - longitud}`} strokeDashoffset={-offset} transform="rotate(-90 80 80)"><title>{e.nombre}: {e.cantidad} ({porcentaje(e.cantidad, pagos.length)}%)</title></circle>;
            })}
          </svg><div className="rp-donut-centro"><strong>{pagos.length}</strong><span>Total de pagos</span></div>
        </div><div className="rp-leyenda">{distribucion.map(e => <button key={e.id} type="button" disabled={e.cantidad === 0} onClick={() => onEstado(e.id)} title={`Ver ${e.nombre.toLowerCase()}`}>
          <i style={{ background: e.color }} /><span>{e.nombre}</span><strong>{e.cantidad}</strong><small>{porcentaje(e.cantidad, pagos.length)}%</small>
        </button>)}</div></div>
        <p className="rp-nota">Selecciona un estado para consultar sus registros.</p>
      </article>
    </div>
    <div className="rp-inferior">
      <article className="rp-tarjeta rp-evolucion"><div className="rp-card-titulo"><div><span className="rp-eyebrow">EVOLUCIÓN DEL REGISTRO</span><h3>Montos pagados por día</h3></div>
        <select aria-label="Periodo de la gráfica de pagos" value={dias} onChange={e => setDias(Number(e.target.value))}><option value={14}>Últimos 14 días</option><option value={30}>Últimos 30 días</option><option value={90}>Últimos 90 días</option></select></div>
        <div className="rp-periodo-total"><strong>{moneda(totalPeriodo)}</strong><span>registrados en este periodo</span></div>
        <div className="rp-grafica-barras"><div className="rp-eje-y" aria-hidden="true"><span>₡{abreviado(maximo > 1 ? maximo : 0)}</span><span>₡{abreviado(maximo > 1 ? maximo / 2 : 0)}</span><span>₡0</span></div>
          <svg viewBox="0 0 600 145" preserveAspectRatio="none" role="img" aria-label={`Montos diarios de los últimos ${dias} días. Total: ${moneda(totalPeriodo)}.`}>
            {[8, 70, 132].map(y => <line key={y} x1="0" y1={y} x2="600" y2={y} stroke="#e7eceb" strokeDasharray="4 4" />)}
            {serie.map((d, i) => <rect key={d.fecha} x={i * 600 / dias + 1} y={132 - d.monto / maximo * 124} width={Math.max(600 / dias - 3, 2)} height={d.monto ? d.monto / maximo * 124 : 0} rx={2} fill="#397d78" tabIndex={d.monto ? 0 : undefined}>
              <title>{etiquetaFecha(d.fecha)}: {moneda(d.monto)}</title></rect>)}
          </svg>
        </div>
        <div className="rp-eje-x" aria-hidden="true"><span>{etiquetaFecha(serie[0].fecha)}</span><span>{etiquetaFecha(serie[Math.floor(dias / 2)].fecha)}</span><span>{etiquetaFecha(serie.at(-1).fecha)}</span></div>
        <p className="rp-nota">{totalPeriodo ? "Cada barra representa el monto registrado como pagado ese día." : "No hay pagos registrados como pagados en este periodo."} Los cobros previstos no se incluyen.</p>
      </article>
      <article className="rp-tarjeta rp-metodos"><div className="rp-card-titulo"><div><span className="rp-eyebrow">COMPOSICIÓN DEL ACUMULADO</span><h3>Pagado por método</h3></div><span className="rp-unidad">Por monto</span></div>
        <div className="rp-ranking">{porMetodo.map(({ id, monto, icono: Icono, color }) => <button type="button" key={id} disabled={!monto} onClick={() => onMetodo(id)} title={`Consultar pagos de ${id}`}>
          <span className="rp-metodo-icono" style={{ color }}><Icono size={19} /></span><span className="rp-metodo-info"><span className="rp-metodo-cabecera"><span>{id}</span><strong>{moneda(monto)}</strong></span>
            <span className="rp-metodo-barra"><span style={{ width: `${porcentaje(monto, total)}%`, background: color }} /></span></span><small>{porcentaje(monto, total)}%</small>
        </button>)}</div>
        <p className="rp-nota">Solo pagos en estado pagado.{pagados.some(p => p.metodo === "Tarjeta") && " La tarjeta corresponde a pagos simulados."} Selecciona un método para ver el detalle.</p>
      </article>
    </div>
  </section>;
}
