import {

  NavLink,
  Outlet,
  useNavigate

} from "react-router-dom";

import {

  LayoutDashboard,
  CalendarDays,
  Building2,
  UsersRound,
  CreditCard,
  ShieldCheck,
  LogOut,
  TentTree

} from "lucide-react";

import {

  obtenerSesion,
  cerrarSesion as eliminarSesion

} from "../services/authService";

import "./MainLayout.css";

function MainLayout() {

  const navigate =
    useNavigate();

  const usuario =
    obtenerSesion();


  // =====================================================
  // CERRAR SESIÓN
  // =====================================================

  const cerrarSesion = () => {

    eliminarSesion();

    navigate(
      "/login",
      {
        replace: true
      }
    );
  };


  // =====================================================
  // INICIAL DEL USUARIO
  // =====================================================

  const inicial =

    usuario?.email
      ?.charAt(0)
      ?.toUpperCase()
      || "U";


  return (

    <div className="main-layout">

      <aside className="sidebar">

        <div>

          {/* ==========================================
              LOGO
          ========================================== */}

          <div className="brand">

            <div className="brand-icon">

              <TentTree
                size={27}
              />

            </div>

            <div>

              <h2>
                Reservas
              </h2>

              <span>
                SCOUTS
              </span>

            </div>

          </div>


          <div className="menu-label">

            MENÚ PRINCIPAL

          </div>


          {/* ==========================================
              MENÚ
          ========================================== */}

          <nav className="sidebar-menu">

            <NavLink
              to="/dashboard"
            >

              <LayoutDashboard
                size={19}
              />

              <span>
                Dashboard
              </span>

            </NavLink>


            <NavLink
              to="/reservas"
            >

              <CalendarDays
                size={19}
              />

              <span>
                Reservas
              </span>

            </NavLink>


            <NavLink
              to="/espacios"
            >

              <Building2
                size={19}
              />

              <span>
                Espacios
              </span>

            </NavLink>


            <NavLink
              to="/perfiles"
            >

              <UsersRound
                size={19}
              />

              <span>
                Perfiles
              </span>

            </NavLink>


            <NavLink
              to="/pagos"
            >

              <CreditCard
                size={19}
              />

              <span>
                Pagos
              </span>

            </NavLink>


            {/* Solo mostramos Usuarios
                al Administrador */}

            {usuario?.rol ===
              "Administrador" && (

              <NavLink
                to="/usuarios"
              >

                <ShieldCheck
                  size={19}
                />

                <span>
                  Usuarios
                </span>

              </NavLink>

            )}

          </nav>

        </div>


        {/* ==========================================
            USUARIO ACTUAL
        ========================================== */}

        <div className="sidebar-bottom">

          <div className="user-card">

            <div className="user-avatar">

              {inicial}

            </div>


            <div className="user-info-session">

              <strong>

                {usuario?.rol ||
                  "Usuario"}

              </strong>

              <span
                title={
                  usuario?.email
                }
              >

                {usuario?.email ||
                  "Sesión activa"}

              </span>

            </div>

          </div>


          <button

            type="button"

            className="logout-button"

            onClick={
              cerrarSesion
            }

          >

            <LogOut
              size={18}
            />

            Cerrar sesión

          </button>

        </div>

      </aside>


      {/* ==========================================
          CONTENIDO
      ========================================== */}

      <main className="main-content">

        <Outlet />

      </main>

    </div>
  );
}

export default MainLayout;