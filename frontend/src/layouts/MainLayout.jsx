import ResponsiveTables from "../components/ResponsiveTables";
import { useEffect, useRef, useState } from "react";
import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import {
  LayoutDashboard, CalendarDays, Building2, UsersRound, CreditCard,
  ShieldCheck, Activity, HardDrive, LogOut, TentTree, Menu, ChevronDown, Bell
} from "lucide-react";
import { cerrarSesion as eliminarSesion } from "../services/authService";
import { useAuth } from "../context/useAuth";
import "./MainLayout.css";
import { useNotificaciones } from "../context/useNotificaciones";
import { esPendiente } from "../services/notificacionService";

const secciones = [
  { ruta: "/notificaciones", nombre: "Notificaciones", icono: Bell, roles: ["Administrador", "Recepcionista"] },
  { ruta: "/dashboard", nombre: "Dashboard", icono: LayoutDashboard, roles: ["Administrador"] },
  { ruta: "/mi-perfil", nombre: "Mi perfil", icono: UsersRound, roles: ["Usuario", "Miembro"] },
  { ruta: "/reservas", nombre: "Reservas", icono: CalendarDays },
  { ruta: "/espacios", nombre: "Espacios", icono: Building2 },
  { ruta: "/perfiles", nombre: "Perfiles", icono: UsersRound, roles: ["Administrador", "Recepcionista"] },
  { ruta: "/pagos", nombre: "Pagos", icono: CreditCard, roles: ["Administrador", "Recepcionista"] },
  { ruta: "/usuarios", nombre: "Usuarios", icono: ShieldCheck, roles: ["Administrador"] },
  { ruta: "/auditoria", nombre: "Auditoría", icono: Activity, roles: ["Administrador"] },
  { ruta: "/respaldos", nombre: "Respaldos", icono: HardDrive, roles: ["Administrador"] }
];

function MainLayout() {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const { usuario, setUsuario } = useAuth();
  const menuRef = useRef(null);
  const esPersonal = ["Administrador", "Recepcionista"].includes(usuario?.rol);
  const bandeja = useNotificaciones(esPersonal);
  const pendientes = bandeja.notificaciones.filter(esPendiente).length;
  const [errorCerrarSesion, setErrorCerrarSesion] = useState("");
  const opciones = secciones.filter((seccion) => !seccion.roles || seccion.roles.includes(usuario?.rol));
  const seccionActual = opciones.find((seccion) => seccion.ruta === pathname)?.nombre || "Menú";
  const inicial = usuario?.email?.charAt(0)?.toUpperCase() || "U";

  useEffect(() => {
    function cerrarFuera(event) {
      if (menuRef.current && !menuRef.current.contains(event.target)) menuRef.current.open = false;
    }
    function cerrarConEscape(event) {
      if (event.key === "Escape" && menuRef.current?.open) {
        menuRef.current.open = false;
        menuRef.current.querySelector("summary")?.focus();
      }
    }
    document.addEventListener("pointerdown", cerrarFuera);
    document.addEventListener("keydown", cerrarConEscape);
    const vistaAmplia = window.matchMedia("(min-width: 1280px)");
    function cerrarAlCambiarVista() {
      if (menuRef.current) menuRef.current.open = false;
    }
    vistaAmplia.addEventListener("change", cerrarAlCambiarVista);
    return () => {
      document.removeEventListener("pointerdown", cerrarFuera);
      document.removeEventListener("keydown", cerrarConEscape);
      vistaAmplia.removeEventListener("change", cerrarAlCambiarVista);
    };
  }, []);

  async function cerrarSesion() {
    setErrorCerrarSesion("");
    try {
      await eliminarSesion();
      setUsuario(null);
      navigate("/login", { replace: true });
    } catch (err) {
      setErrorCerrarSesion(err.message || "No se pudo cerrar la sesión.");
    }
  }

  return (
    <div className="main-layout">
      <header className="topbar">
        <div className="topbar-inner">
          <div className="topbar-brand">
            <div className="topbar-brand-icon"><TentTree size={27} aria-hidden="true" /></div>
            <div><h2>Reservas</h2><span>SCOUTS</span></div>
          </div>
          <nav className="topbar-desktop-nav" aria-label="Navegación principal">
            {opciones.filter(opcion => opcion.ruta !== "/notificaciones").map(({ ruta, nombre }) => (
              <NavLink key={ruta} to={ruta}>{nombre}</NavLink>
            ))}
          </nav>
          <details className="topbar-dropdown" ref={menuRef}>
            <summary aria-controls="main-navigation">
              <Menu size={19} aria-hidden="true" /><span>Menú</span>
              <span className="topbar-current">{seccionActual}</span>
              <ChevronDown className="topbar-chevron" size={17} aria-hidden="true" />
            </summary>
            <nav id="main-navigation" className="topbar-panel" aria-label="Menú principal">
              <div className="topbar-panel-label">MENÚ PRINCIPAL</div>
              <div className="topbar-links">
                {opciones.map(({ ruta, nombre, icono: Icono }) => (
                  <NavLink key={ruta} to={ruta} onClick={() => { menuRef.current.open = false; }}>
                    <Icono size={20} aria-hidden="true" /><span>{nombre}</span>
                  </NavLink>
                ))}
              </div>
            </nav>
          </details>
          <div className="topbar-account">
            {esPersonal && <NavLink to="/notificaciones" className="topbar-notifications" aria-label={"Notificaciones: " + pendientes + " pagos pendientes"} title="Notificaciones">
              <Bell size={21} aria-hidden="true" />{pendientes > 0 && <span>{pendientes > 99 ? "99+" : pendientes}</span>}
            </NavLink>}
            <div className="topbar-user">
              <div className="topbar-avatar">{inicial}</div>
              <div className="topbar-user-info">
                <strong>{usuario?.rol || "Usuario"}</strong>
                <span title={usuario?.email}>{usuario?.email || "Sesión activa"}</span>
              </div>
            </div>
            <button type="button" className="topbar-logout" onClick={() => { void cerrarSesion(); }}>
              <LogOut size={17} aria-hidden="true" /><span>Cerrar sesión</span>
            </button>
          </div>
        </div>
        {errorCerrarSesion && <p className="topbar-error" role="alert">{errorCerrarSesion}</p>}
      </header>
      <main className="main-content"><ResponsiveTables pathname={pathname} /><Outlet context={{ bandeja }} /></main>
    </div>
  );
}

export default MainLayout;
