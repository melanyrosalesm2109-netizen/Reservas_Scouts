import { useEffect, useMemo, useState } from "react";

import {
  Activity,
  Database,
  Eye,
  FileClock,
  LogIn,
  RefreshCw,
  Search,
  X,
} from "lucide-react";

import {
  obtenerDetalleAuditoria,
  obtenerResumenAuditoria,
} from "../services/auditoriaService";

import "./Auditoria.css";


function Auditoria() {

  const [resumen, setResumen] = useState([]);
  const [eventos, setEventos] = useState([]);

  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const [busqueda, setBusqueda] = useState("");
  const [origen, setOrigen] = useState("");
  const [evento, setEvento] = useState("");
  const [desde, setDesde] = useState("");
  const [hasta, setHasta] = useState("");

  const [seleccionado, setSeleccionado] = useState(null);


  // =====================================================
  // CARGAR AUDITORÍA
  // =====================================================

  const cargarAuditoria = async () => {

    setCargando(true);
    setError("");

    try {

      const [resumenData, detalleData] =
        await Promise.all([
          obtenerResumenAuditoria(),
          obtenerDetalleAuditoria(),
        ]);


      setResumen(
        Array.isArray(resumenData)
          ? resumenData
          : []
      );


      setEventos(
        Array.isArray(detalleData)
          ? detalleData
          : []
      );

    } catch (err) {

      setError(
        err.message ||
        "No se pudo cargar la auditoría."
      );

    } finally {

      setCargando(false);
    }
  };


  useEffect(() => {

    void cargarAuditoria();

  }, []);


  // =====================================================
  // OPCIONES DE FILTRO
  // =====================================================

  const origenes = useMemo(() => {

    return [
      ...new Set(
        eventos
          .map((item) => item.origen)
          .filter(Boolean)
      ),
    ].sort();

  }, [eventos]);


  const tiposEvento = useMemo(() => {

    return [
      ...new Set(
        eventos
          .map((item) => item.evento)
          .filter(Boolean)
      ),
    ].sort();

  }, [eventos]);


  // =====================================================
  // FILTRAR EVENTOS
  // =====================================================

  const eventosFiltrados = useMemo(() => {

    const texto =
      busqueda
        .trim()
        .toLowerCase();


    return eventos.filter((item) => {

      const coincideOrigen =
        !origen ||
        item.origen === origen;


      const coincideEvento =
        !evento ||
        item.evento === evento;


      const fecha =
        item.creadoEn
          ? new Date(item.creadoEn)
          : null;


      const fechaValida =
        fecha &&
        !Number.isNaN(
          fecha.getTime()
        );


      const coincideDesde =
        !desde ||
        (
          fechaValida &&
          fecha >=
          new Date(`${desde}T00:00:00`)
        );


      const coincideHasta =
        !hasta ||
        (
          fechaValida &&
          fecha <=
          new Date(`${hasta}T23:59:59`)
        );


      const contenido = [

        item.origen,
        item.evento,
        item.registroId,
        item.usuario,
        item.usuarioBd,
        item.detalle,

      ]
        .filter(
          (valor) =>
            valor !== null &&
            valor !== undefined
        )
        .join(" ")
        .toLowerCase();


      const coincideBusqueda =
        !texto ||
        contenido.includes(texto);


      return (
        coincideOrigen &&
        coincideEvento &&
        coincideDesde &&
        coincideHasta &&
        coincideBusqueda
      );
    });

  }, [
    eventos,
    busqueda,
    origen,
    evento,
    desde,
    hasta,
  ]);


  // =====================================================
  // INDICADORES
  // =====================================================

  const totalEventos = useMemo(() => {

    return resumen.reduce(
      (total, item) =>
        total +
        Number(item.totalEventos || 0),
      0
    );

  }, [resumen]);


  const cambiosDatos = useMemo(() => {

    return resumen
      .filter((item) =>
        [
          "INSERT",
          "UPDATE",
          "DELETE",
        ].includes(item.evento)
      )
      .reduce(
        (total, item) =>
          total +
          Number(item.totalEventos || 0),
        0
      );

  }, [resumen]);


  const eventosAcceso = useMemo(() => {

    return resumen
      .filter(
        (item) =>
          item.origen === "accesos" ||
          item.origen === "auditoriaAccesos"
      )
      .reduce(
        (total, item) =>
          total +
          Number(item.totalEventos || 0),
        0
      );

  }, [resumen]);


  const ultimaActividad = useMemo(() => {

    const fechas =
      resumen
        .map(
          (item) =>
            new Date(item.ultimoEvento)
        )
        .filter(
          (fecha) =>
            !Number.isNaN(
              fecha.getTime()
            )
        );


    if (fechas.length === 0) {

      return "Sin actividad";
    }


    const ultima =
      new Date(
        Math.max(
          ...fechas.map(
            (fecha) =>
              fecha.getTime()
          )
        )
      );


    return ultima.toLocaleString(
      "es-CR"
    );

  }, [resumen]);


  // =====================================================
  // UTILIDADES
  // =====================================================

  const limpiarFiltros = () => {

    setBusqueda("");
    setOrigen("");
    setEvento("");
    setDesde("");
    setHasta("");
  };


  const nombreOrigen = (valor) => {

    const nombres = {

      reservas: "Reservas",
      pagos: "Pagos",
      usuarios: "Usuarios",
      espacios: "Espacios",
      perfilesUsuario: "Perfiles",
      accesos: "Accesos",
      auditoriaAccesos: "Accesos",

    };


    return (
      nombres[valor] ||
      valor ||
      "Sin origen"
    );
  };


  const claseEvento = (valor) => {

    switch (valor) {

      case "INSERT":
        return "audit-badge audit-insert";

      case "UPDATE":
        return "audit-badge audit-update";

      case "DELETE":
        return "audit-badge audit-delete";

      case "LOGIN":
        return "audit-badge audit-login";

      case "LOGIN_FALLIDO":
        return "audit-badge audit-delete";

      case "BACKUP":
        return "audit-badge audit-backup";

      case "RESTORE":
        return "audit-badge audit-restore";

      default:
        return "audit-badge";
    }
  };


  const formatearJson = (valor) => {

    if (!valor) {

      return "";
    }


    try {

      return JSON.stringify(
        JSON.parse(valor),
        null,
        2
      );

    } catch {

      return valor;
    }
  };


  // =====================================================
  // INTERFAZ
  // =====================================================

  return (

    <section className="audit-page">

      <header className="audit-heading">

        <div>

          <span className="audit-eyebrow">
            CONTROL DEL SISTEMA
          </span>

          <h1>

            <Activity size={29} />

            Auditoría

          </h1>

          <p>
            Consulta quién realizó cada operación,
            cuándo ocurrió y qué información fue modificada.
          </p>

        </div>


        <button
          className="audit-refresh"
          type="button"
          onClick={() =>
            void cargarAuditoria()
          }
          disabled={cargando}
        >

          <RefreshCw size={17} />

          Actualizar

        </button>

      </header>


      {error && (

        <div
          className="audit-error"
          role="alert"
        >
          {error}
        </div>

      )}


      {/* INDICADORES */}

      <div className="audit-stats">

        <article className="audit-stat">

          <div className="audit-stat-icon">
            <Activity size={22} />
          </div>

          <div>

            <span>
              Eventos registrados
            </span>

            <strong>
              {totalEventos}
            </strong>

          </div>

        </article>


        <article className="audit-stat">

          <div className="audit-stat-icon">
            <Database size={22} />
          </div>

          <div>

            <span>
              Cambios de datos
            </span>

            <strong>
              {cambiosDatos}
            </strong>

          </div>

        </article>


        <article className="audit-stat">

          <div className="audit-stat-icon">
            <LogIn size={22} />
          </div>

          <div>

            <span>
              Eventos de acceso
            </span>

            <strong>
              {eventosAcceso}
            </strong>

          </div>

        </article>


        <article className="audit-stat">

          <div className="audit-stat-icon">
            <FileClock size={22} />
          </div>

          <div>

            <span>
              Última actividad
            </span>

            <strong className="audit-last-date">
              {ultimaActividad}
            </strong>

          </div>

        </article>

      </div>


      {/* HISTORIAL */}

      <div className="audit-panel">

        <div className="audit-panel-heading">

          <div>

            <span className="audit-eyebrow">
              HISTORIAL
            </span>

            <h2>
              Eventos del sistema
            </h2>

          </div>


          <span className="audit-count">

            {eventosFiltrados.length}

            {" "}

            resultado
            {eventosFiltrados.length === 1
              ? ""
              : "s"}

          </span>

        </div>


        {/* FILTROS */}

        <div className="audit-filters">

          <div className="audit-search">

            <Search size={18} />

            <input
              type="search"
              placeholder="Buscar usuario, tabla o evento..."
              value={busqueda}
              onChange={(e) =>
                setBusqueda(
                  e.target.value
                )
              }
            />

          </div>


          <select
            value={origen}
            onChange={(e) =>
              setOrigen(
                e.target.value
              )
            }
          >

            <option value="">
              Todos los módulos
            </option>

            {origenes.map((item) => (

              <option
                key={item}
                value={item}
              >
                {nombreOrigen(item)}
              </option>

            ))}

          </select>


          <select
            value={evento}
            onChange={(e) =>
              setEvento(
                e.target.value
              )
            }
          >

            <option value="">
              Todos los eventos
            </option>

            {tiposEvento.map((item) => (

              <option
                key={item}
                value={item}
              >
                {item}
              </option>

            ))}

          </select>


          <input
            type="date"
            value={desde}
            title="Desde"
            onChange={(e) =>
              setDesde(
                e.target.value
              )
            }
          />


          <input
            type="date"
            value={hasta}
            title="Hasta"
            onChange={(e) =>
              setHasta(
                e.target.value
              )
            }
          />


          <button
            type="button"
            className="audit-clear"
            onClick={limpiarFiltros}
          >
            Limpiar
          </button>

        </div>


        {cargando ? (

          <div className="audit-empty">
            Cargando auditoría...
          </div>

        ) : (

          <div className="audit-table-wrap">

            <table className="audit-table">

              <thead>

                <tr>

                  <th>Fecha y hora</th>
                  <th>Módulo</th>
                  <th>Evento</th>
                  <th>Usuario</th>
                  <th>Registro</th>
                  <th>Detalle</th>

                </tr>

              </thead>


              <tbody>

                {eventosFiltrados.length === 0 ? (

                  <tr>

                    <td
                      colSpan="6"
                      className="audit-empty"
                    >
                      No hay eventos que coincidan
                      con los filtros.
                    </td>

                  </tr>

                ) : (

                  eventosFiltrados.map(
                    (fila) => (

                      <tr
                        key={
                          `${fila.origen}-${fila.idAuditoria}-${fila.creadoEn}`
                        }
                      >

                        <td className="audit-date">

                          {fila.creadoEn
                            ? new Date(
                                fila.creadoEn
                              ).toLocaleString(
                                "es-CR"
                              )
                            : "—"}

                        </td>


                        <td>

                          <strong>
                            {nombreOrigen(
                              fila.origen
                            )}
                          </strong>

                        </td>


                        <td>

                          <span
                            className={
                              claseEvento(
                                fila.evento
                              )
                            }
                          >
                            {fila.evento}
                          </span>

                        </td>


                        <td>

                          <div className="audit-user">

                            <strong>
                              {fila.usuario ||
                                "No identificado"}
                            </strong>

                            {fila.usuarioBd && (

                              <span>
                                BD: {fila.usuarioBd}
                              </span>

                            )}

                          </div>

                        </td>


                        <td>

                          {fila.registroId != null
                            ? `#${fila.registroId}`
                            : "—"}

                        </td>


                        <td>

                          <button
                            type="button"
                            className="audit-detail-button"
                            onClick={() =>
                              setSeleccionado(
                                fila
                              )
                            }
                          >

                            <Eye size={16} />

                            Ver detalle

                          </button>

                        </td>

                      </tr>

                    )
                  )

                )}

              </tbody>

            </table>

          </div>

        )}

      </div>


      {/* MODAL DE DETALLE */}

      {seleccionado && (

        <div
          className="audit-modal-backdrop"

          onMouseDown={(e) => {

            if (
              e.target ===
              e.currentTarget
            ) {

              setSeleccionado(null);
            }
          }}
        >

          <div className="audit-modal">

            <div className="audit-modal-heading">

              <div>

                <span className="audit-eyebrow">
                  DETALLE DEL EVENTO
                </span>

                <h2>

                  {nombreOrigen(
                    seleccionado.origen
                  )}

                  {" · "}

                  {seleccionado.evento}

                </h2>

              </div>


              <button
                type="button"
                onClick={() =>
                  setSeleccionado(null)
                }
              >

                <X size={21} />

              </button>

            </div>


            <div className="audit-modal-info">

              <div>

                <span>
                  Fecha
                </span>

                <strong>

                  {seleccionado.creadoEn
                    ? new Date(
                        seleccionado.creadoEn
                      ).toLocaleString(
                        "es-CR"
                      )
                    : "—"}

                </strong>

              </div>


              <div>

                <span>
                  Usuario
                </span>

                <strong>
                  {seleccionado.usuario ||
                    "No identificado"}
                </strong>

              </div>


              <div>

                <span>
                  Usuario BD
                </span>

                <strong>
                  {seleccionado.usuarioBd ||
                    "—"}
                </strong>

              </div>


              <div>

                <span>
                  Registro
                </span>

                <strong>

                  {seleccionado.registroId != null
                    ? `#${seleccionado.registroId}`
                    : "—"}

                </strong>

              </div>

            </div>


            {seleccionado.detalle && (

              <div className="audit-json">

                <h3>
                  Información del evento
                </h3>

                <pre>
                  {formatearJson(
                    seleccionado.detalle
                  )}
                </pre>

              </div>

            )}


            {(seleccionado.valoresAnteriores ||
              seleccionado.valoresNuevos) && (

              <div className="audit-changes">

                <div className="audit-json">

                  <h3>
                    Antes
                  </h3>

                  <pre>

                    {seleccionado.valoresAnteriores
                      ? formatearJson(
                          seleccionado.valoresAnteriores
                        )
                      : "Sin valores anteriores."}

                  </pre>

                </div>


                <div className="audit-json">

                  <h3>
                    Después
                  </h3>

                  <pre>

                    {seleccionado.valoresNuevos
                      ? formatearJson(
                          seleccionado.valoresNuevos
                        )
                      : "Sin valores nuevos."}

                  </pre>

                </div>

              </div>

            )}

          </div>

        </div>

      )}

    </section>
  );
}


export default Auditoria;