import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import {
  CalendarDays,
  Building2,
  UsersRound,
  CircleDollarSign,
  ArrowRight,
  Plus,
  Clock3,
  UserRound,
  WalletCards
} from "lucide-react";

import {
  listarReservas
} from "../services/reservaService";

import {
  listarEspacios
} from "../services/espacioService";

import {
  listarPerfiles
} from "../services/perfilService";

import {
  listarPagos
} from "../services/pagoService";

import "./Dashboard.css";


function Dashboard() {

  const navigate = useNavigate();

  const [reservas, setReservas] =
    useState([]);

  const [espacios, setEspacios] =
    useState([]);

  const [perfiles, setPerfiles] =
    useState([]);

  const [pagos, setPagos] =
    useState([]);

  const [cargando, setCargando] =
    useState(true);

  const [error, setError] =
    useState("");


  // =====================================================
  // CARGAR DATOS REALES
  // =====================================================

  useEffect(() => {

    cargarDashboard();

  }, []);


  const cargarDashboard = async () => {

    try {

      setCargando(true);
      setError("");

      const [
        reservasData,
        espaciosData,
        perfilesData,
        pagosData
      ] = await Promise.all([

        listarReservas(),

        listarEspacios(),

        listarPerfiles(),

        listarPagos()

      ]);


      setReservas(
        Array.isArray(reservasData)
          ? reservasData
          : []
      );

      setEspacios(
        Array.isArray(espaciosData)
          ? espaciosData
          : []
      );

      setPerfiles(
        Array.isArray(perfilesData)
          ? perfilesData
          : []
      );

      setPagos(
        Array.isArray(pagosData)
          ? pagosData
          : []
      );


    } catch (err) {

      setError(
        err.message ||
        "No se pudo cargar el dashboard."
      );

    } finally {

      setCargando(false);
    }
  };


  // =====================================================
  // ESTADÍSTICAS
  // =====================================================

  const totalReservas =
    reservas.length;


  const espaciosDisponibles =
    espacios.filter(
      (espacio) =>
        espacio.estado ===
        "DISPONIBLE"
    ).length;


  const totalPerfiles =
    perfiles.length;


  const totalPagado =
    pagos
      .filter(
        (pago) =>
          pago.estado ===
          "PAGADO"
      )
      .reduce(
        (total, pago) =>
          total +
          Number(
            pago.monto || 0
          ),
        0
      );


  // =====================================================
  // PRÓXIMAS RESERVAS
  // =====================================================

  const proximasReservas =
    [...reservas]
      .filter(
        (reserva) =>
          reserva.estado !==
          "CANCELADA"
      )
      .sort(
        (a, b) => {

          const fechaA =
            new Date(
              a.fechaInicio ||
              a.fecha ||
              0
            );

          const fechaB =
            new Date(
              b.fechaInicio ||
              b.fecha ||
              0
            );

          return fechaA - fechaB;
        }
      )
      .slice(0, 4);


  const formatearFecha = (
    fecha
  ) => {

    if (!fecha) {
      return "Sin fecha";
    }

    const date =
      new Date(fecha);

    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return fecha;
    }

    return date.toLocaleString(
      "es-CR",
      {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit"
      }
    );
  };


  return (

    <div className="dashboard-page">

      {/* =================================================
          ENCABEZADO
      ================================================= */}

      <div className="dashboard-top">

        <div>

          <span className="dashboard-eyebrow">
            SISTEMA ADMINISTRATIVO
          </span>

          <h1>
            Buenos días
          </h1>

          <p>
            Aquí tienes un resumen de la
            actividad de Reservas Scouts.
          </p>

        </div>


        <button
          type="button"
          className="dashboard-new"
          onClick={() =>
            navigate(
              "/reservas"
            )
          }
        >

          <Plus size={19} />

          Nueva reserva

        </button>

      </div>


      {/* ERROR */}

      {error && (

        <div className="dashboard-error">

          {error}

        </div>

      )}


      {/* =================================================
          BANNER
      ================================================= */}

      <section className="dashboard-hero">

        <div className="dashboard-hero-content">

          <span>
            RESERVAS SCOUTS
          </span>

          <h2>
            Gestiona cada reserva
            <br />
            desde un solo lugar
          </h2>

          <p>
            Controla espacios, clientes,
            pagos y disponibilidad de manera
            sencilla y organizada.
          </p>


          <button
            type="button"
            onClick={() =>
              navigate(
                "/reservas"
              )
            }
          >

            Ver reservas

            <ArrowRight
              size={18}
            />

          </button>

        </div>


        <div className="dashboard-hero-icon">

          <div className="hero-circle hero-circle-1">

            <div className="hero-circle hero-circle-2">

              <div className="hero-circle hero-circle-3">

                <CalendarDays
                  size={61}
                />

              </div>

            </div>

          </div>

        </div>

      </section>


      {/* =================================================
          ESTADÍSTICAS
      ================================================= */}

      <section className="dashboard-stats">

        {/* RESERVAS */}

        <div className="dashboard-stat-card">

          <div className="dashboard-stat-icon reservas">

            <CalendarDays
              size={23}
            />

          </div>


          <div className="dashboard-stat-content">

            <span>
              Reservas totales
            </span>

            <strong>

              {cargando
                ? "..."
                : totalReservas}

            </strong>

            <small>
              Total registrado
            </small>

          </div>

        </div>


        {/* ESPACIOS */}

        <div className="dashboard-stat-card">

          <div className="dashboard-stat-icon espacios">

            <Building2
              size={23}
            />

          </div>


          <div className="dashboard-stat-content">

            <span>
              Espacios
            </span>

            <strong>

              {cargando
                ? "..."
                : espaciosDisponibles}

            </strong>

            <small>
              Disponibles para reservar
            </small>

          </div>

        </div>


        {/* PERFILES */}

        <div className="dashboard-stat-card">

          <div className="dashboard-stat-icon perfiles">

            <UsersRound
              size={23}
            />

          </div>


          <div className="dashboard-stat-content">

            <span>
              Perfiles
            </span>

            <strong>

              {cargando
                ? "..."
                : totalPerfiles}

            </strong>

            <small>
              Clientes registrados
            </small>

          </div>

        </div>


        {/* PAGOS */}

        <div className="dashboard-stat-card">

          <div className="dashboard-stat-icon pagos">

            <CircleDollarSign
              size={23}
            />

          </div>


          <div className="dashboard-stat-content">

            <span>
              Pagos
            </span>

            <strong className="dashboard-money">

              {cargando
                ? "..."
                : `₡${totalPagado.toLocaleString(
                    "es-CR"
                  )}`}

            </strong>

            <small>
              Total recibido
            </small>

          </div>

        </div>

      </section>


      {/* =================================================
          PARTE INFERIOR
      ================================================= */}

      <section className="dashboard-bottom-grid">


        {/* PRÓXIMAS RESERVAS */}

        <div className="dashboard-box">

          <div className="dashboard-box-header">

            <div>

              <h3>
                Próximas reservas
              </h3>

              <p>
                Reservaciones más cercanas
              </p>

            </div>


            <button
              type="button"
              onClick={() =>
                navigate(
                  "/reservas"
                )
              }
            >

              Ver todas

            </button>

          </div>


          <div className="dashboard-reservas-list">

            {cargando ? (

              <div className="dashboard-empty">

                Cargando reservas...

              </div>

            ) : proximasReservas.length === 0 ? (

              <div className="dashboard-empty">

                <CalendarDays
                  size={31}
                />

                <strong>
                  No hay reservas registradas
                </strong>

                <span>
                  Las próximas reservas
                  aparecerán aquí.
                </span>

              </div>

            ) : (

              proximasReservas.map(
                (reserva) => (

                  <div
                    className="dashboard-reserva"
                    key={reserva.id}
                  >

                    <div className="dashboard-reserva-icon">

                      <CalendarDays
                        size={19}
                      />

                    </div>


                    <div className="dashboard-reserva-info">

                      <strong>

                        {reserva.codigo ||
                          `Reserva #${reserva.id}`}

                      </strong>

                      <span>

                        {reserva.espacio ||
                          "Espacio"}

                      </span>

                    </div>


                    <div className="dashboard-reserva-persona">

                      <UserRound
                        size={15}
                      />

                      <span>

                        {reserva.solicitante ||
                          reserva.responsable ||
                          "Sin solicitante"}

                      </span>

                    </div>


                    <div className="dashboard-reserva-fecha">

                      <Clock3
                        size={15}
                      />

                      <span>

                        {formatearFecha(
                          reserva.fechaInicio ||
                          reserva.fecha
                        )}

                      </span>

                    </div>


                    <span
                      className={`dashboard-status ${
                        reserva.estado
                          ?.toLowerCase() ||
                        ""
                      }`}
                    >

                      {reserva.estado ||
                        "PENDIENTE"}

                    </span>

                  </div>

                )
              )

            )}

          </div>

        </div>


        {/* ACCESOS RÁPIDOS */}

        <div className="dashboard-box dashboard-shortcuts">

          <div className="dashboard-box-header">

            <div>

              <h3>
                Accesos rápidos
              </h3>

              <p>
                Operaciones frecuentes
              </p>

            </div>

          </div>


          <button
            type="button"
            onClick={() =>
              navigate(
                "/reservas"
              )
            }
          >

            <div className="shortcut-icon">

              <CalendarDays
                size={20}
              />

            </div>

            <div>

              <strong>
                Reservas
              </strong>

              <span>
                Administrar reservaciones
              </span>

            </div>

            <ArrowRight
              size={17}
            />

          </button>


          <button
            type="button"
            onClick={() =>
              navigate(
                "/espacios"
              )
            }
          >

            <div className="shortcut-icon">

              <Building2
                size={20}
              />

            </div>

            <div>

              <strong>
                Espacios
              </strong>

              <span>
                Revisar disponibilidad
              </span>

            </div>

            <ArrowRight
              size={17}
            />

          </button>


          <button
            type="button"
            onClick={() =>
              navigate(
                "/pagos"
              )
            }
          >

            <div className="shortcut-icon">

              <WalletCards
                size={20}
              />

            </div>

            <div>

              <strong>
                Pagos
              </strong>

              <span>
                Consultar pagos
              </span>

            </div>

            <ArrowRight
              size={17}
            />

          </button>

        </div>

      </section>

    </div>
  );
}

export default Dashboard;