import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { UserRound, CalendarDays, Clock3 } from "lucide-react";
import { useAuth } from "../context/useAuth";
import { consultarMiPerfil } from "../services/perfilService";
import { listarReservas } from "../services/reservaService";
import "./MiPerfil.css";
export default function MiPerfil() {
  const { usuario } = useAuth();
  const [perfil, setPerfil] = useState(null);
  const [reservas, setReservas] = useState([]);
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(true);
  useEffect(() => {
    let vigente = true;
    const cargar = async () => {
      try {
        const [perfiles, datos] = await Promise.all([consultarMiPerfil(), listarReservas()]);
        if (vigente) { setPerfil(perfiles[0] || null); setReservas(datos); setError(""); }
      } catch (err) { if (vigente) setError(err.message); }
      finally { if (vigente) setCargando(false); }
    };
    void cargar();
    const timer = window.setInterval(cargar, 10000);
    window.addEventListener("focus", cargar);
    return () => { vigente = false; clearInterval(timer); window.removeEventListener("focus", cargar); };
  }, []);
  const pendientes = reservas.filter(r => r.estado === "PENDIENTE");
  return <div className="mi-perfil-page"><header><span>MI CUENTA</span><h1>Mi perfil</h1><p>Tus datos y tus reservas, en un solo lugar.</p></header>
    {error && <p role="alert">{error}</p>}
    {cargando ? <p role="status">Cargando tu perfil…</p> : <>
      <section className="mi-perfil-datos"><UserRound size={30} /><div><h2>{perfil?.nombre || usuario.email}</h2><p>{perfil?.correoContacto || usuario.email}</p>{perfil?.telefono && <p>{perfil.telefono}</p>}</div><Link to="/espacios">Buscar un espacio</Link></section>
      <section className="mi-perfil-resumen"><div><CalendarDays size={20} /><strong>{reservas.length}</strong><span>Mis reservas</span></div><div><Clock3 size={20} /><strong>{pendientes.length}</strong><span>Pendientes</span></div></section>
      <section className="mi-perfil-reservas"><div className="mi-perfil-cabecera"><h2>Mis reservas pendientes</h2><Link to="/reservas">Ver todas mis reservas</Link></div>
        {pendientes.length === 0 ? <p>No tienes reservas pendientes.</p> : pendientes.map(r => <article key={r.id}><div><small>{r.codigo}</small><h3>{r.espacio}</h3><p>{new Date(r.fechaInicio).toLocaleString("es-CR")}</p></div><span>Pendiente</span><Link to={`/reservas?codigo=${encodeURIComponent(r.codigo)}`}>Ver reserva</Link></article>)}
      </section>
    </>}
  </div>;
}
