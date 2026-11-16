import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { CalendarDays, Building2, UsersRound, Wallet, Plus, ArrowUpRight, RefreshCw, ArrowRight, Clock3 } from "lucide-react";
import { listarReservas } from "../services/reservaService";
import { listarEspacios } from "../services/espacioService";
import { listarPerfiles } from "../services/perfilService";
import { listarPagos } from "../services/pagoService";
import "./Dashboard.css";

const moneda = valor => Number(valor).toLocaleString("es-CR", { style: "currency", currency: "CRC", maximumFractionDigits: 0 });
const compacto = valor => new Intl.NumberFormat("es-CR", { notation: "compact", maximumFractionDigits: 1 }).format(valor);
const estados = [{ id: "APROBADA", nombre: "Reservadas", color: "#258477" }, { id: "PENDIENTE", nombre: "Pendientes de pago", color: "#d1a250" }, { id: "FINALIZADA", nombre: "Finalizadas", color: "#547a9c" }, { id: "CANCELADA", nombre: "Canceladas", color: "#bd7770" }, { id: "VENCIDA", nombre: "Vencidas", color: "#909b9f" }];
const hoyCR = () => new Intl.DateTimeFormat("sv-SE", { timeZone: "America/Costa_Rica" }).format(new Date());

export default function Dashboard() {
  const navigate = useNavigate();
  const [datos, setDatos] = useState(null);
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(true);
  const [actualizado, setActualizado] = useState(null);
  const [meses, setMeses] = useState(6);
  const [metrica, setMetrica] = useState("reservas");
  const cargar = useCallback(async () => {
    try {
      const listas = await Promise.all([listarReservas(), listarEspacios(), listarPerfiles(), listarPagos()]);
      if (listas.some(lista => !Array.isArray(lista))) throw new Error("No se recibieron todos los datos del dashboard.");
      setDatos({ reservas: listas[0], espacios: listas[1], perfiles: listas[2], pagos: listas[3] });
      setActualizado(new Date()); setError("");
    } catch (err) { setError(err.message || "No se pudo actualizar el dashboard."); }
    finally { setCargando(false); }
  }, []);
  useEffect(() => {
    queueMicrotask(() => void cargar());
    const refrescar = () => { if (document.visibilityState !== "hidden") void cargar(); };
    const timer = setInterval(refrescar, 30000);
    window.addEventListener("focus", refrescar);
    window.addEventListener("reservas-pagos-actualizados", refrescar);
    return () => { clearInterval(timer); window.removeEventListener("focus", refrescar); window.removeEventListener("reservas-pagos-actualizados", refrescar); };
  }, [cargar]);
  const { reservas = [], espacios = [], perfiles = [], pagos = [] } = datos || {};
  const hoy = hoyCR();
  const pagados = pagos.filter(p => p.estado === "PAGADO");
  const ingresos = pagados.reduce((sum, p) => sum + Number(p.monto || 0), 0);
  const pendientes = reservas.filter(r => r.estado === "PENDIENTE").length;
  const disponibles = espacios.filter(e => e.estado === "DISPONIBLE").length;
  const distribucion = estados.map(e => ({ ...e, cantidad: reservas.filter(r => r.estado === e.id).length }));
  const otros = reservas.length - distribucion.reduce((sum, e) => sum + e.cantidad, 0);
  if (otros) distribucion.push({ id: "OTROS", nombre: "Otros estados", color: "#909b9f", cantidad: otros });
  let acumulado = 0;
  const segmentos = distribucion.map(e => {
    const inicio = acumulado;
    acumulado += reservas.length ? e.cantidad / reservas.length * 100 : 0;
    return `${e.color} ${inicio}% ${acumulado}%`;
  });
  const [anio, mes] = hoy.split("-").map(Number);
  const serie = Array.from({ length: meses }, (_, i) => {
    const date = new Date(Date.UTC(anio, mes - meses + i, 1));
    const clave = date.toISOString().slice(0, 7);
    return { clave, etiqueta: date.toLocaleDateString("es-CR", { month: "short", timeZone: "UTC" }).replace(".", ""),
      nombre: date.toLocaleDateString("es-CR", { month: "long", year: "numeric", timeZone: "UTC" }),
      reservas: reservas.filter(r => r.fechaInicio?.slice(0, 7) === clave).length,
      ingresos: pagados.filter(p => p.fechaPago?.slice(0, 7) === clave).reduce((sum, p) => sum + Number(p.monto || 0), 0) };
  });
  const pico = Math.max(1, ...serie.map(s => s[metrica]));
  const maximo = metrica === "reservas" ? Math.ceil(pico / 3) * 3 : pico;
  const totalPeriodo = serie.reduce((sum, s) => sum + s[metrica], 0);
  const proximas = reservas.filter(r => ["PENDIENTE", "APROBADA"].includes(r.estado) && r.fechaInicio?.slice(0, 10) >= hoy)
    .sort((a, b) => a.fechaInicio.localeCompare(b.fechaInicio)).slice(0, 4);
  const ranking = espacios.map(e => ({ ...e, cantidad: reservas.filter(r => r.espacioId === e.id && !["CANCELADA", "VENCIDA"].includes(r.estado)).length }))
    .sort((a, b) => b.cantidad - a.cantidad).slice(0, 4);
  const maxRanking = Math.max(1, ...ranking.map(e => e.cantidad));
  const tarjetas = [
    { nombre: "Reservas", valor: reservas.length, nota: "En todo el historial", icono: CalendarDays, clase: "azul", ruta: "/reservas" },
    { nombre: "Ingresos recibidos", valor: moneda(ingresos), nota: "Solo pagos en estado pagado", icono: Wallet, clase: "verde", ruta: "/pagos" },
    { nombre: "Espacios disponibles", valor: disponibles, nota: `${espacios.length} espacios en el catálogo`, icono: Building2, clase: "dorado", ruta: "/espacios" },
    { nombre: "Perfiles", valor: perfiles.length, nota: "Personas y grupos registrados", icono: UsersRound, clase: "violeta", ruta: "/perfiles" }
  ];
  return <div className="dashboard-page">
    <header className="dashboard-top"><div><span className="dashboard-eyebrow">TU CENTRO DE OPERACIONES</span><h1>Dashboard</h1><p>Una mirada clara a tus reservas, espacios e ingresos.</p></div>
      <div className="db-header-actions"><button type="button" className="db-refresh" aria-label="Actualizar dashboard" onClick={() => void cargar()}><RefreshCw size={17} /></button><button type="button" className="dashboard-new" onClick={() => navigate("/reservas")}><Plus size={17} />Nueva reserva</button></div></header>
    <div className="db-sync"><span className={error ? "db-dot db-dot-error" : "db-dot"} />{error ? "Actualización pendiente" : actualizado ? `Actualizado a las ${actualizado.toLocaleTimeString("es-CR", { timeZone: "America/Costa_Rica", hour: "2-digit", minute: "2-digit" })}` : "Consultando datos…"}<span>Vista general · historial completo</span></div>
    {error && <p className="dashboard-error" role="alert">{error}{datos && " Se muestran los últimos datos recibidos."}</p>}
    {cargando && <p className="db-loading" role="status">Cargando dashboard…</p>}
    <section className="dashboard-stats" aria-label="Indicadores generales">{tarjetas.map(({ nombre, valor, nota, icono: Icono, clase, ruta }) => <button type="button" className={`db-stat ${clase}`} key={nombre} onClick={() => navigate(ruta)}><div className="db-stat-top"><span className="db-stat-icon"><Icono size={19} /></span><ArrowUpRight size={16} /></div><span className="db-stat-label">{nombre}</span><strong>{datos ? valor : "—"}</strong><small>{nota}</small></button>)}</section>
    <section className="db-analytics" aria-label="Gráficas de actividad">
      <article className="db-panel db-evolution"><header className="db-panel-header"><div><span className="dashboard-eyebrow">EL PULSO DE TU ACTIVIDAD</span><h2>Evolución mensual</h2></div><select aria-label="Periodo de la gráfica" value={meses} onChange={e => setMeses(Number(e.target.value))}><option value={6}>Últimos 6 meses</option><option value={12}>Últimos 12 meses</option></select></header>
        <div className="db-chart-toolbar"><div className="db-chart-total"><strong>{datos ? metrica === "ingresos" ? moneda(totalPeriodo) : totalPeriodo : "—"}</strong><span>{metrica === "ingresos" ? "recibidos en el periodo" : "reservas con inicio en el periodo"}</span></div><div className="db-segment" aria-label="Métrica de la gráfica">{["reservas", "ingresos"].map(m => <button type="button" key={m} aria-pressed={metrica === m} onClick={() => setMetrica(m)}>{m === "reservas" ? "Reservas" : "Ingresos"}</button>)}</div></div>
        <div className="db-chart"><svg viewBox="0 0 620 230" role="img" aria-label={`${metrica === "ingresos" ? "Ingresos recibidos" : "Reservas por fecha de inicio"} de los últimos ${meses} meses`}>
          <defs><linearGradient id="db-bar-fill" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#238b88" /><stop offset="100%" stopColor="#16445c" /></linearGradient></defs>
          {[0, 1, 2, 3].map(i => <g key={i}><line x1="45" x2="610" y1={22 + i * 54} y2={22 + i * 54} stroke="#e7edea" strokeDasharray="3 5" /><text x="35" y={26 + i * 54} textAnchor="end">{metrica === "ingresos" ? compacto(maximo * (3 - i) / 3) : Math.ceil(maximo * (3 - i) / 3)}</text></g>)}
          {serie.map((s, i) => {
            const ancho = 560 / meses;
            const altura = s[metrica] / maximo * 162;
            const etiqueta = `${s.nombre}: ${metrica === "ingresos" ? moneda(s.ingresos) : `${s.reservas} reservas`}`;
            return <g key={s.clave}><rect className="db-chart-track" x={50 + i * ancho + ancho * .2} y="22" width={ancho * .6} height="162" rx="5" fill="#f3f6f3" /><rect tabIndex={0} aria-label={etiqueta} x={50 + i * ancho + ancho * .2} y={184 - Math.max(altura, 2)} width={ancho * .6} height={Math.max(altura, 2)} rx="5" fill={s[metrica] ? "url(#db-bar-fill)" : "#d8e0dd"}><title>{etiqueta}</title></rect><text x={50 + i * ancho + ancho / 2} y="211" textAnchor="middle">{s.etiqueta}</text></g>;
          })}
        </svg></div><p className="db-chart-note">{metrica === "ingresos" ? "Montos en colones. Incluye únicamente pagos confirmados; excluye pendientes, rechazados y anulados." : "Cuenta las reservas por su mes de inicio, incluidas las canceladas."}{totalPeriodo === 0 && datos && " No hay registros en este periodo."}</p>
      </article>
      <article className="db-panel db-distribution"><header className="db-panel-header"><div><span className="dashboard-eyebrow">ESTADO DEL HISTORIAL</span><h2>Reservas, de un vistazo</h2></div></header><div className="db-donut" role="img" aria-label={distribucion.map(e => `${e.nombre}: ${e.cantidad}`).join(", ")} style={{ background: reservas.length ? `conic-gradient(${segmentos.join(",")})` : "#e9eeea" }}><div><strong>{datos ? reservas.length : "—"}</strong><span>reservas en total</span></div></div>
        <div className="db-legend">{distribucion.map(e => <div key={e.id}><span style={{ background: e.color }} /><span>{e.nombre}</span><strong>{e.cantidad}</strong><small>{reservas.length ? Math.round(e.cantidad / reservas.length * 100) : 0}%</small></div>)}</div>
      </article>
    </section>
    <section className="db-lower"><article className="db-panel"><header className="db-panel-header"><div><span className="dashboard-eyebrow">LO QUE VIENE</span><h2>Próximas reservas</h2></div><button type="button" className="db-text-link" onClick={() => navigate("/reservas")}>Ver todas <ArrowUpRight size={15} /></button></header><div className="db-upcoming">{proximas.length ? proximas.map(r => <button type="button" className="db-reservation" key={r.id} onClick={() => navigate(`/reservas?codigo=${encodeURIComponent(r.codigo)}`)}><span className="db-date"><strong>{r.fechaInicio.slice(8, 10)}</strong><small>{new Date(`${r.fechaInicio.slice(0, 10)}T12:00:00`).toLocaleDateString("es-CR", { month: "short" })}</small></span><span className="db-reservation-info"><strong>{r.espacio}</strong><small>{r.codigo} · {r.solicitante || r.responsable}</small></span><span className={`db-badge ${r.estado === "APROBADA" ? "confirmed" : "pending"}`}>{r.estado === "APROBADA" ? "Reservada" : "Pendiente"}</span><ArrowRight size={15} /></button>) : <div className="db-empty"><CalendarDays size={25} /><strong>{cargando ? "Consultando agenda…" : "Tu agenda está despejada"}</strong><span>Las reservas activas desde hoy aparecerán aquí.</span></div>}</div></article>
      <article className="db-panel"><header className="db-panel-header"><div><span className="dashboard-eyebrow">TUS ESPACIOS</span><h2>Los más reservados</h2></div><Building2 size={20} /></header><div className="db-ranking">{ranking.length ? ranking.map((e, i) => <button type="button" key={e.id} onClick={() => navigate(`/reservas?espacioId=${e.id}`)}><span className="db-rank-number">0{i + 1}</span><span className="db-rank-info"><span><strong>{e.nombre}</strong><small>{e.cantidad}</small></span><span className="db-rank-track"><span style={{ width: `${e.cantidad / maxRanking * 100}%` }} /></span></span></button>) : <p className="db-chart-note">Los espacios aparecerán al cargar el catálogo.</p>}<p className="db-chart-note">Reservas del historial, sin canceladas ni vencidas.</p></div></article></section>
    <aside className="db-attention"><span><Clock3 size={18} /><strong>{pendientes}</strong> reservas pendientes de revisión</span><button type="button" onClick={() => navigate("/notificaciones")}>Ir a notificaciones <ArrowRight size={16} /></button></aside>
  </div>;
}
