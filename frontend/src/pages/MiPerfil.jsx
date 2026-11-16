import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { CalendarDays, Clock3, ArrowUpRight, ArrowRight, Mail, Phone, MapPin, Check, CheckCheck, Compass, TentTree, UserRound } from "lucide-react";
import { useAuth } from "../context/useAuth";
import { consultarMiPerfil } from "../services/perfilService";
import { listarReservas } from "../services/reservaService";
import "./MiPerfil.css";
import { fechaPlazoPago } from "../services/pagoGestionService";

const hoyCR = () => new Intl.DateTimeFormat("sv-SE", { timeZone: "America/Costa_Rica" }).format(new Date());
const fecha = valor => {
  if (!valor) return "Fecha por definir";
  const date = new Date(/[Zz]$|[+-]\d{2}:\d{2}$/.test(valor) ? valor : `${valor}-06:00`);
  return Number.isNaN(date.getTime()) ? "Fecha por definir" : date.toLocaleString("es-CR", { timeZone: "America/Costa_Rica", day: "numeric", month: "long", year: "numeric", hour: "2-digit", minute: "2-digit" });
};
export default function MiPerfil() {
  const { usuario } = useAuth();
  const [perfil, setPerfil] = useState(null);
  const [reservas, setReservas] = useState([]);
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(true);
  const [vista, setVista] = useState("pendientes");
  useEffect(() => {
    let vigente = true;
    const cargar = async () => {
      try {
        const [perfiles, datos] = await Promise.all([consultarMiPerfil(), listarReservas()]);
        if (!Array.isArray(perfiles) || !Array.isArray(datos)) throw new Error("No se pudieron consultar los datos de tu cuenta.");
        if (vigente) { setPerfil(perfiles[0] || null); setReservas(datos); setError(""); }
      } catch (err) { if (vigente) setError(err.message); }
      finally { if (vigente) setCargando(false); }
    };
    void cargar();
    const timer = window.setInterval(cargar, 10000);
    window.addEventListener("focus", cargar);
    window.addEventListener("reservas-pagos-actualizados", cargar);
    return () => { vigente = false; clearInterval(timer); window.removeEventListener("focus", cargar); window.removeEventListener("reservas-pagos-actualizados", cargar); };
  }, []);
  const pendientes = reservas.filter(r => r.estado === "PENDIENTE");
  const confirmadas = reservas.filter(r => r.estado === "APROBADA");
  const finalizadas = reservas.filter(r => r.estado === "FINALIZADA");
  const proximas = confirmadas.filter(r => r.fechaInicio?.slice(0, 10) >= hoyCR()).sort((a, b) => a.fechaInicio.localeCompare(b.fechaInicio));
  const lista = vista === "pendientes" ? pendientes : proximas;
  const nombre = perfil?.nombre || usuario?.email?.split("@")[0] || "Mi cuenta";
  const iniciales = nombre.trim().split(/\s+/).slice(0, 2).map(p => p[0]).join("").toUpperCase();
  const email = perfil?.correoContacto || usuario?.email;
  const siguiente = proximas[0];
  const estadisticas = [
    { titulo: "Mis reservas", cantidad: reservas.length, icono: CalendarDays, clase: "azul", nota: "Todo tu historial" },
    { titulo: "Reservadas", cantidad: confirmadas.length, icono: CheckCheck, clase: "verde", nota: "Confirmadas por el equipo" },
    { titulo: "Pendientes", cantidad: pendientes.length, icono: Clock3, clase: "dorado", nota: "Cupo guardado · falta confirmar pago" },
    { titulo: "Finalizadas", cantidad: finalizadas.length, icono: Compass, clase: "violeta", nota: "Experiencias completadas" }
  ];
  return <div className="mi-perfil-page">
    <header className="mp-heading"><div><span className="mp-eyebrow">TU ESPACIO PERSONAL</span><h1>Mi perfil</h1><p>Todo listo para tu próxima aventura.</p></div><Link className="mp-secondary-link" to="/reservas">Mis reservas <ArrowUpRight size={16} /></Link></header>
    {error && <p className="mp-error" role="alert">{error}</p>}
    {cargando ? <p className="mp-loading" role="status">Cargando tu perfil…</p> : <>
      <section className="mp-account" aria-label="Resumen de mi cuenta"><div className="mp-account-main"><div className="mp-avatar" aria-hidden="true">{iniciales}</div><div className="mp-identity"><span className="mp-account-label"><UserRound size={12} />CUENTA PERSONAL</span><h2>{nombre}</h2><span className="mp-role">{usuario?.rol || "Usuario"}</span></div></div><div className="mp-account-bottom"><div className="mp-contact">{email && <span><Mail size={15} /><span>{email}</span></span>}{perfil?.telefono && <span><Phone size={15} />{perfil.telefono}</span>}</div><Link className="mp-explore" to="/espacios">Buscar un espacio <ArrowUpRight size={17} /></Link></div><TentTree className="mp-account-art" size={155} strokeWidth={.65} aria-hidden="true" /></section>
      {!perfil && !error && <p className="mp-incomplete">Aún no tienes un perfil de contacto. Puedes completarlo al solicitar tu primera reserva.</p>}
      <section className="mp-stats" aria-label="Resumen de mis reservas">{estadisticas.map(({ titulo, cantidad, icono: Icono, clase, nota }) => <div className={`mp-stat ${clase}`} key={titulo}><span className="mp-stat-icon"><Icono size={19} /></span><strong>{cantidad}</strong><span className="mp-stat-label">{titulo}</span><small>{nota}</small></div>)}</section>
      <div className="mp-content-grid"><section className="mi-perfil-reservas"><div className="mp-section-heading"><div><span className="mp-eyebrow">AL DÍA CON TUS PLANES</span><h2>Mis actividades</h2></div><Link to="/reservas" aria-label="Ver todas mis reservas"><ArrowUpRight size={19} /></Link></div>
        <div className="mp-tabs" role="tablist" aria-label="Mis actividades"><button type="button" role="tab" aria-selected={vista === "pendientes"} aria-controls="mp-actividades" id="mp-tab-pendientes" onClick={() => setVista("pendientes")}>Pendientes <span>{pendientes.length}</span></button><button type="button" role="tab" aria-selected={vista === "proximas"} aria-controls="mp-actividades" id="mp-tab-proximas" onClick={() => setVista("proximas")}>Próximas <span>{proximas.length}</span></button></div>
        <div id="mp-actividades" role="tabpanel" aria-labelledby={`mp-tab-${vista}`}>
          {lista.length === 0 ? <div className="mp-empty"><span className="mp-empty-icon">{vista === "pendientes" ? <Check size={30} /> : <CalendarDays size={28} />}</span><h3>{vista === "pendientes" ? "Todo al día" : "Tu próxima aventura te espera"}</h3><p>{vista === "pendientes" ? "No tienes reservas pendientes de pago o revisión. Aquí verás el estado de tus nuevas solicitudes." : "Cuando tengas una reserva confirmada desde hoy, aparecerá aquí."}</p><Link to={vista === "pendientes" ? "/reservas" : "/espacios"}>{vista === "pendientes" ? "Ver todas mis reservas" : "Explorar espacios"}<ArrowRight size={15} /></Link></div> : lista.map(r => <article className="mp-activity" key={r.id}><span className="mp-activity-icon"><CalendarDays size={21} /></span><div className="mp-activity-info"><small>{r.codigo}</small><h3>{r.espacio}</h3><p><Clock3 size={12} />{fecha(r.fechaInicio)}</p>{r.estado === "PENDIENTE" && <p className="mp-plazo">{r.metodoPagoPendiente === "Efectivo" ? "Pendiente de efectivo · cupo guardado" : "Pago pendiente de revisión · cupo guardado"}{r.pagoVenceEn ? ` · Pagar antes de ${fechaPlazoPago(r.pagoVenceEn)}` : ""}</p>}</div><span className={`mp-status ${r.estado === "APROBADA" ? "confirmed" : "pending"}`}>{r.estado === "APROBADA" ? "Reservada" : "Pendiente"}</span><Link aria-label={`Ver reserva ${r.codigo}`} to={`/reservas?codigo=${encodeURIComponent(r.codigo)}`}><ArrowUpRight size={18} /></Link></article>)}
        </div><footer className="mp-list-footer"><span>El estado se actualiza automáticamente</span><Link to="/reservas">Ver historial <ArrowRight size={14} /></Link></footer>
      </section>
      <aside className="mp-sidebar"><section className="mp-next"><span className="mp-eyebrow">EN TU AGENDA</span><h2>Tu próximo encuentro</h2>{siguiente ? <><span className="mp-next-symbol"><CalendarDays size={25} /></span><h3>{siguiente.espacio}</h3><p>{fecha(siguiente.fechaInicio)}</p><span className="mp-next-code">{siguiente.codigo}</span><Link to={`/reservas?codigo=${encodeURIComponent(siguiente.codigo)}`}>Ver mi reserva <ArrowUpRight size={16} /></Link></> : <><span className="mp-next-symbol"><Compass size={28} /></span><h3>Un lugar para tu próximo plan</h3><p>Encuentra un espacio, elige las fechas y organiza tu actividad.</p><Link to="/espacios">Explorar espacios <ArrowUpRight size={16} /></Link></>}</section>
      <section className="mp-details"><span className="mp-eyebrow">INFORMACIÓN DE CONTACTO</span><h2>Los datos de tu perfil</h2><dl><div><dt><Mail size={14} />Correo</dt><dd>{email || "Sin registrar"}</dd></div><div><dt><Phone size={14} />Teléfono</dt><dd>{perfil?.telefono || "Sin registrar"}</dd></div>{perfil?.direccion && <div><dt><MapPin size={14} />Dirección</dt><dd>{perfil.direccion}</dd></div>}</dl></section></aside></div>
    </>}
  </div>;
}
