import { useEffect, useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { listarFechasOcupadas } from "../services/reservaService";
import "./CalendarioDisponibilidad.css";
import { listarBloqueos } from "../services/reservaPagoService";

const fechaLocal = fecha => `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, "0")}-${String(fecha.getDate()).padStart(2, "0")}`;
const formatoFecha = new Intl.DateTimeFormat("es-CR", { day: "numeric", month: "long", year: "numeric" });
const formatoHora = new Intl.DateTimeFormat("es-CR", { hour: "2-digit", minute: "2-digit", hour12: false });

export default function CalendarioDisponibilidad({ espacio, fechaInicio, onSeleccionar }) {
  const [mes, setMes] = useState(() => {
    const fecha = fechaInicio ? new Date(fechaInicio) : new Date();
    return new Date(fecha.getFullYear(), fecha.getMonth(), 1);
  });
  const [dia, setDia] = useState(fechaInicio?.slice(0, 10) || "");
  const [ocupadas, setOcupadas] = useState([]);
  const [estado, setEstado] = useState("cargando");
  const [intento, setIntento] = useState(0);

  useEffect(() => {
    if (!espacio) return;
    let vigente = true;
    const cargar = () => Promise.all([listarFechasOcupadas(), listarBloqueos()]).then(([reservas, bloqueos]) => {
      if (vigente) { setOcupadas([...reservas, ...bloqueos].filter(r => Number(r.espacioId) === Number(espacio.id))); setEstado("listo"); }
    }).catch(() => { if (vigente) setEstado("error"); });
    void cargar();
    const timer = setInterval(cargar, 5000);
    return () => { vigente = false; clearInterval(timer); };
  }, [espacio, intento]);

  if (!espacio) return <p className="disponibilidad-calendario">Selecciona un espacio para ver su calendario de disponibilidad.</p>;

  // Los intervalos son [inicio, fin): una salida a medianoche no ocupa el día siguiente.
  const reservasDelDia = fecha => {
    const inicio = new Date(`${fecha}T00:00`);
    const fin = new Date(inicio);
    fin.setDate(fin.getDate() + 1);
    return ocupadas.filter(r => new Date(r.fechaInicio) < fin && new Date(r.fechaFin) > inicio)
      .sort((a, b) => a.fechaInicio.localeCompare(b.fechaInicio));
  };
  const diasMes = new Date(mes.getFullYear(), mes.getMonth() + 1, 0).getDate();
  const offset = (mes.getDay() + 6) % 7;
  const hoy = new Intl.DateTimeFormat("sv-SE", { timeZone: "America/Costa_Rica" }).format(new Date());
  const seleccion = dia ? reservasDelDia(dia) : [];

  return <section className="disponibilidad-calendario" aria-label={`Disponibilidad de ${espacio.nombre}`}>
    <h3>Disponibilidad de {espacio.nombre}</h3>
    <p>Selecciona un día para ver los horarios ocupados y elegir la fecha de tu reserva.</p>
    <div className="calendario-mes">
      <button type="button" aria-label="Mes anterior" onClick={() => setMes(new Date(mes.getFullYear(), mes.getMonth() - 1, 1))}><ChevronLeft size={18} /></button>
      <strong aria-live="polite">{mes.toLocaleDateString("es-CR", { month: "long", year: "numeric" })}</strong>
      <button type="button" aria-label="Mes siguiente" onClick={() => setMes(new Date(mes.getFullYear(), mes.getMonth() + 1, 1))}><ChevronRight size={18} /></button>
    </div>
    {estado === "cargando" && <p role="status">Cargando disponibilidad…</p>}
    {estado === "error" && <div role="alert">No se pudo cargar la disponibilidad. <button type="button" onClick={() => { setEstado("cargando"); setIntento(i => i + 1); }}>Reintentar</button></div>}
    <div className="calendario-grid">
      {["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"].map(d => <span className="calendario-semana" key={d}>{d}</span>)}
      {Array.from({ length: offset }, (_, i) => <span key={`vacio-${i}`} />)}
      {Array.from({ length: diasMes }, (_, i) => {
        const fecha = fechaLocal(new Date(mes.getFullYear(), mes.getMonth(), i + 1));
        const ocupado = reservasDelDia(fecha).length > 0;
        const pasado = fecha < hoy;
        return <button type="button" key={fecha} disabled={estado !== "listo"}
          className={`calendario-dia ${ocupado ? "ocupado" : estado === "listo" ? "libre" : ""} ${pasado ? "pasado" : ""}`}
          aria-label={`${fecha}: ${estado !== "listo" ? "sin consultar" : pasado ? "fecha pasada" : ocupado ? "con horarios ocupados" : "disponible"}`}
          aria-pressed={dia === fecha} onClick={() => { setDia(fecha); onSeleccionar(fecha); }}>
          <span>{i + 1}</span><small>{estado !== "listo" ? "…" : pasado ? "Pasado" : ocupado ? "Ocupado" : "Libre"}</small>
        </button>;
      })}
    </div>
    <p className="calendario-leyenda"><span>● Libre</span><span>● Con horarios ocupados</span></p>
    <p>Un día marcado como ocupado puede tener horas libres. El horario exacto se valida al guardar.</p>
    {dia && estado === "listo" && <div className="calendario-horarios" aria-live="polite">
      <strong>{formatoFecha.format(new Date(`${dia}T12:00`))}</strong>
      {seleccion.length ? <ul>{seleccion.map((r, i) => <li key={i}>Ocupado: {formatoFecha.format(new Date(r.fechaInicio))}, {formatoHora.format(new Date(r.fechaInicio))} – {formatoFecha.format(new Date(r.fechaFin))}, {formatoHora.format(new Date(r.fechaFin))}</li>)}</ul> : <p>Sin reservas registradas para este día.</p>}
    </div>}
  </section>;
}
