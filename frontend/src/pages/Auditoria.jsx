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

import { listarPerfiles } from "../services/perfilService";
import { listarEspacios } from "../services/espacioService";
import {
  listarUsuarios,
  listarRoles,
} from "../services/usuarioService";
import { listarReservas } from "../services/reservaService";

import "./Auditoria.css";


function Auditoria() {
    const convertirFechaAuditoria = (valor) => {
    if (!valor) return null;

    const texto = String(valor).trim();

    const tieneZonaHoraria =
      texto.endsWith("Z") ||
      /[+-]\d{2}:\d{2}$/.test(texto);

    const fecha = new Date(
      tieneZonaHoraria
        ? texto
        : `${texto}Z`
    );

    if (Number.isNaN(fecha.getTime())) {
      return null;
    }

    return fecha;
  };

  const formatearFechaAuditoria = (valor) => {
    const fecha =
      convertirFechaAuditoria(valor);

    if (!fecha) return "—";

    return fecha.toLocaleString("es-CR", {
      timeZone: "America/Costa_Rica",
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "numeric",
      minute: "2-digit",
      second: "2-digit",
      hour12: true
    });
  };
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

  const [catalogos, setCatalogos] = useState({
    perfiles: {},
    espacios: {},
    usuarios: {},
    reservas: {},
    roles: {},
  });


  // =====================================================
  // CARGAR AUDITORÍA Y CATÁLOGOS
  // =====================================================

  const cargarAuditoria = async () => {
    setCargando(true);
    setError("");

    try {
      const obtenerSeguro = async (funcion) => {
        try {
          const datos = await funcion();

          if (Array.isArray(datos)) {
            return datos;
          }

          if (Array.isArray(datos?.content)) {
            return datos.content;
          }

          if (Array.isArray(datos?.items)) {
            return datos.items;
          }

          return [];
        } catch {
          return [];
        }
      };


      const [
        resumenData,
        detalleData,
        perfilesData,
        espaciosData,
        usuariosData,
        reservasData,
        rolesData,
      ] = await Promise.all([
        obtenerResumenAuditoria(),
        obtenerDetalleAuditoria(),
        obtenerSeguro(() => listarPerfiles()),
        obtenerSeguro(() => listarEspacios()),
        obtenerSeguro(() => listarUsuarios()),
        obtenerSeguro(() => listarReservas()),
        obtenerSeguro(() => listarRoles()),
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


      const perfiles = {};

      perfilesData.forEach((perfil) => {
        const id =
          perfil.idPerfil ??
          perfil.id;

        if (id != null) {
          perfiles[String(id)] =
            perfil.nombre ||
            `Perfil #${id}`;
        }
      });


      const espacios = {};

      espaciosData.forEach((espacio) => {
        const id = espacio.id;

        if (id != null) {
          espacios[String(id)] =
            espacio.nombre ||
            `Espacio #${id}`;
        }
      });


      const usuarios = {};

      usuariosData.forEach((usuario) => {
        const id = usuario.id;

        if (id != null) {
          usuarios[String(id)] =
            usuario.email ||
            usuario.nombre ||
            `Usuario #${id}`;
        }
      });


      const reservas = {};

      reservasData.forEach((reserva) => {
        const id = reserva.id;

        if (id != null) {
          reservas[String(id)] =
            reserva.codigo ||
            `Reserva #${id}`;
        }
      });


      const roles = {};

      rolesData.forEach((rol) => {
        const id = rol.id;

        if (id != null) {
          roles[String(id)] =
            rol.nombre ||
            `Rol #${id}`;
        }
      });


      setCatalogos({
        perfiles,
        espacios,
        usuarios,
        reservas,
        roles,
      });

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
    queueMicrotask(() => { void cargarAuditoria(); });
  }, []);


  // =====================================================
  // NOMBRES AMIGABLES
  // =====================================================

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


  const nombreEvento = (valor) => {
    const nombres = {
      INSERT: "Creación",
      UPDATE: "Modificación",
      DELETE: "Eliminación",
      LOGIN: "Inicio de sesión",
      LOGOUT: "Cierre de sesión",
      LOGIN_FALLIDO: "Inicio de sesión fallido",
      BACKUP: "Respaldo",
      RESTORE: "Restauración",
    };

    return (
      nombres[valor] ||
      valor ||
      "Evento"
    );
  };


  const nombreCampo = (campo) => {
    const nombres = {
      codigo: "Código",
      espacioId: "Espacio",
      solicitantePerfilId: "Solicitante",
      creadoPorUsuarioId: "Creado por",
      grupo: "Grupo",
      responsable: "Responsable",
      telefono: "Teléfono",
      email: "Correo",
      participantes: "Participantes",
      tipoActividad: "Tipo de actividad",
      fechaInicio: "Fecha y hora de inicio",
      fechaFin: "Fecha y hora final",
      estado: "Estado",
      observaciones: "Observaciones",

      nombre: "Nombre",
      descripcion: "Descripción",
      ubicacion: "Ubicación",
      capacidad: "Capacidad",
      costo: "Costo",

      usuarioId: "Usuario",
      identificacion: "Identificación",
      correoContacto: "Correo de contacto",
      tipoPerfil: "Tipo de perfil",
      direccion: "Dirección",

      rolId: "Rol",

      pagoId: "Pago",
      reservaId: "Reserva",
      monto: "Monto",
      metodo: "Método de pago",
      fechaPago: "Fecha de pago",
      comprobante: "Comprobante",
      notas: "Notas",

      direccionIp: "Dirección IP",
      agenteUsuario: "Navegador / dispositivo",
    };

    return nombres[campo] || campo;
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


  // =====================================================
  // JSON / VALORES
  // =====================================================

  const parsearJson = (valor) => {
    if (!valor) {
      return null;
    }

    if (typeof valor === "object") {
      return valor;
    }

    try {
      return JSON.parse(valor);
    } catch {
      return null;
    }
  };


  const camposOcultos = [
    "createdAt",
    "updatedAt",
    "passwordHash",
  ];


  const formatearValor = (campo, valor) => {
    if (
      valor === null ||
      valor === undefined ||
      valor === ""
    ) {
      return "Sin dato";
    }


    // IDs convertidos a nombres reales

    if (campo === "espacioId") {
      return (
        catalogos.espacios[String(valor)] ||
        `Espacio #${valor}`
      );
    }


    if (campo === "solicitantePerfilId") {
      return (
        catalogos.perfiles[String(valor)] ||
        `Perfil #${valor}`
      );
    }


    if (
      campo === "creadoPorUsuarioId" ||
      campo === "usuarioId"
    ) {
      return (
        catalogos.usuarios[String(valor)] ||
        `Usuario #${valor}`
      );
    }


    if (campo === "reservaId") {
      return (
        catalogos.reservas[String(valor)] ||
        `Reserva #${valor}`
      );
    }


    if (campo === "rolId") {
      return (
        catalogos.roles[String(valor)] ||
        `Rol #${valor}`
      );
    }


    if (campo === "pagoId") {
      return `Pago #${valor}`;
    }


    // Fechas

    if (
      campo === "fechaInicio" ||
      campo === "fechaFin"
    ) {
      const fecha = new Date(valor);

      if (!Number.isNaN(fecha.getTime())) {
        return fecha.toLocaleString("es-CR");
      }
    }


    if (campo === "fechaPago") {
      const fecha =
        new Date(`${valor}T00:00:00`);

      if (!Number.isNaN(fecha.getTime())) {
        return fecha.toLocaleDateString("es-CR");
      }
    }


    // Dinero

    if (
      campo === "monto" ||
      campo === "costo"
    ) {
      const numero = Number(valor);

      if (!Number.isNaN(numero)) {
        return new Intl.NumberFormat(
          "es-CR",
          {
            style: "currency",
            currency: "CRC",
          }
        ).format(numero);
      }
    }


    // Estado

    if (
      campo === "estado" &&
      typeof valor === "string"
    ) {
      return (
        valor.charAt(0).toUpperCase() +
        valor.slice(1).toLowerCase()
      );
    }


    if (typeof valor === "boolean") {
      return valor
        ? "Sí"
        : "No";
    }


    return String(valor);
  };


  // =====================================================
  // INFORMACIÓN DE ACCESO
  // =====================================================

  const obtenerInfoAcceso = (detalle) => {
    if (!detalle) {
      return {
        ip: "No disponible",
        dispositivo: "No disponible",
        navegador: "No disponible",
      };
    }


    const ipMatch =
      detalle.match(/IP:\s*([^|]+)/i);

    const navegadorMatch =
      detalle.match(/Navegador:\s*(.+)$/i);


    const ipOriginal =
      ipMatch?.[1]?.trim() || "";

    const userAgent =
      navegadorMatch?.[1]?.trim() || "";


    let ip =
      ipOriginal ||
      "No disponible";


    if (
      ipOriginal === "0:0:0:0:0:0:0:1" ||
      ipOriginal === "::1" ||
      ipOriginal === "127.0.0.1"
    ) {
      ip = "Equipo local";
    }


    let dispositivo =
      "Otro dispositivo";


    if (/Windows/i.test(userAgent)) {
      dispositivo =
        "Computadora Windows";
    } else if (/Android/i.test(userAgent)) {
      dispositivo =
        "Dispositivo Android";
    } else if (/iPhone|iPad/i.test(userAgent)) {
      dispositivo =
        "iPhone / iPad";
    } else if (/Macintosh|Mac OS/i.test(userAgent)) {
      dispositivo =
        "Computadora macOS";
    }


    let navegador =
      "Otro navegador";


    if (/Edg\//i.test(userAgent)) {
      navegador =
        "Microsoft Edge";
    } else if (/Chrome\//i.test(userAgent)) {
      navegador =
        "Google Chrome";
    } else if (/Firefox\//i.test(userAgent)) {
      navegador =
        "Mozilla Firefox";
    } else if (/Safari\//i.test(userAgent)) {
      navegador =
        "Safari";
    }


    return {
      ip,
      dispositivo,
      navegador,
    };
  };


  // =====================================================
  // DETALLE LEGIBLE DE CAMBIOS
  // =====================================================

  const obtenerDetalleLegible = (item) => {
    if (!item) {
      return null;
    }


    const detalle =
      parsearJson(item.detalle);


    const anteriores =
      parsearJson(item.valoresAnteriores) ||
      detalle?.antes ||
      null;


    const nuevos =
      parsearJson(item.valoresNuevos) ||
      detalle?.despues ||
      null;


    // MODIFICACIÓN

    if (item.evento === "UPDATE") {
      const campos = [
        ...new Set([
          ...Object.keys(anteriores || {}),
          ...Object.keys(nuevos || {}),
        ]),
      ];


      const cambios =
        campos
          .filter(
            (campo) =>
              !camposOcultos.includes(campo)
          )
          .filter((campo) => {
            const antes =
              anteriores?.[campo];

            const despues =
              nuevos?.[campo];

            return (
              JSON.stringify(antes) !==
              JSON.stringify(despues)
            );
          })
          .map((campo) => ({
            campo,

            nombre:
              nombreCampo(campo),

            antes:
              formatearValor(
                campo,
                anteriores?.[campo]
              ),

            despues:
              formatearValor(
                campo,
                nuevos?.[campo]
              ),
          }));


      return {
        tipo: "cambios",
        titulo: "Cambios realizados",
        cambios,
      };
    }


    // CREACIÓN

    if (item.evento === "INSERT") {
      const datos =
        nuevos ||
        detalle?.despues ||
        detalle ||
        {};


      return {
        tipo: "datos",
        titulo: "Información registrada",

        datos:
          Object.entries(datos)
            .filter(
              ([campo]) =>
                !camposOcultos.includes(campo) &&
                campo !== "antes" &&
                campo !== "despues"
            )
            .map(
              ([campo, valor]) => ({
                campo,

                nombre:
                  nombreCampo(campo),

                valor:
                  formatearValor(
                    campo,
                    valor
                  ),
              })
            ),
      };
    }


    // ELIMINACIÓN

    if (item.evento === "DELETE") {
      const datos =
        anteriores ||
        detalle?.antes ||
        detalle ||
        {};


      return {
        tipo: "datos",
        titulo: "Información eliminada",

        datos:
          Object.entries(datos)
            .filter(
              ([campo]) =>
                !camposOcultos.includes(campo) &&
                campo !== "antes" &&
                campo !== "despues"
            )
            .map(
              ([campo, valor]) => ({
                campo,

                nombre:
                  nombreCampo(campo),

                valor:
                  formatearValor(
                    campo,
                    valor
                  ),
              })
            ),
      };
    }


    return null;
  };


  // NO usamos useMemo aquí porque depende
  // también de los catálogos cargados.

  const detalleSeleccionado =
    seleccionado
      ? obtenerDetalleLegible(
          seleccionado
        )
      : null;


  // =====================================================
  // FILTROS
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
  convertirFechaAuditoria(
    item.creadoEn
  );


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
          new Date(
            `${desde}T00:00:00`
          )
        );


      const coincideHasta =
        !hasta ||
        (
          fechaValida &&
          fecha <=
          new Date(
            `${hasta}T23:59:59`
          )
        );


      const contenido = [
        nombreOrigen(item.origen),
        nombreEvento(item.evento),
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
        Number(
          item.totalEventos || 0
        ),
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
          Number(
            item.totalEventos || 0
          ),
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
          Number(
            item.totalEventos || 0
          ),
        0
      );
  }, [resumen]);


 const ultimaActividad = useMemo(() => {

  const fechas =
    resumen
      .map((item) =>
        convertirFechaAuditoria(
          item.ultimoEvento
        )
      )
      .filter(Boolean);

  if (fechas.length === 0) {
    return "Sin actividad";
  }

  const ultima =
    new Date(
      Math.max(
        ...fechas.map(
          (fecha) => fecha.getTime()
        )
      )
    );

  return ultima.toLocaleString(
    "es-CR",
    {
      timeZone: "America/Costa_Rica",
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "numeric",
      minute: "2-digit",
      second: "2-digit",
      hour12: true
    }
  );

}, [resumen]);

  const limpiarFiltros = () => {
    setBusqueda("");
    setOrigen("");
    setEvento("");
    setDesde("");
    setHasta("");
  };


  // =====================================================
  // EVENTO SELECCIONADO
  // =====================================================

  const esEventoAcceso =
    seleccionado &&
    [
      "LOGIN",
      "LOGOUT",
      "LOGIN_FALLIDO",
    ].includes(
      seleccionado.evento
    );


  const infoAcceso =
    esEventoAcceso
      ? obtenerInfoAcceso(
          seleccionado.detalle
        )
      : null;


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
            {eventosFiltrados.length}{" "}
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
              placeholder="Buscar usuario, módulo o evento..."
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

            {origenes.map(
              (item) => (
                <option
                  key={item}
                  value={item}
                >
                  {nombreOrigen(item)}
                </option>
              )
            )}

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

            {tiposEvento.map(
              (item) => (
                <option
                  key={item}
                  value={item}
                >
                  {nombreEvento(item)}
                </option>
              )
            )}

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
            onClick={
              limpiarFiltros
            }
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

                          {formatearFechaAuditoria(
  fila.creadoEn
)}

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
                            {nombreEvento(
                              fila.evento
                            )}
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


      {/* MODAL */}

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

                  {nombreEvento(
                    seleccionado.evento
                  )}

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

                  {formatearFechaAuditoria(
  seleccionado.creadoEn
)}

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
                    "No aplica"}
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


            {/* EVENTOS DE ACCESO */}

            {esEventoAcceso && (

              <div className="audit-access-detail">

                <h3>
                  {nombreEvento(
                    seleccionado.evento
                  )}
                </h3>


                <p className="audit-access-description">

                  {seleccionado.evento ===
                    "LOGIN" &&
                    "El usuario inició sesión correctamente en el sistema."}

                  {seleccionado.evento ===
                    "LOGOUT" &&
                    "El usuario cerró su sesión en el sistema."}

                  {seleccionado.evento ===
                    "LOGIN_FALLIDO" &&
                    "Se registró un intento de inicio de sesión fallido."}

                </p>


                <div className="audit-access-grid">

                  <div>
                    <span>
                      Dirección IP
                    </span>

                    <strong>
                      {infoAcceso?.ip}
                    </strong>
                  </div>


                  <div>
                    <span>
                      Dispositivo
                    </span>

                    <strong>
                      {infoAcceso?.dispositivo}
                    </strong>
                  </div>


                  <div>
                    <span>
                      Navegador
                    </span>

                    <strong>
                      {infoAcceso?.navegador}
                    </strong>
                  </div>

                </div>

              </div>

            )}


            {/* CAMBIOS DE DATOS */}

            {!esEventoAcceso &&
              detalleSeleccionado && (

              <div className="audit-readable-detail">

                <div className="audit-readable-heading">

                  <span className="audit-eyebrow">
                    INFORMACIÓN DEL CAMBIO
                  </span>

                  <h3>
                    {detalleSeleccionado.titulo}
                  </h3>

                </div>


                {detalleSeleccionado.tipo ===
                  "cambios" && (

                  <div className="audit-change-list">

                    {detalleSeleccionado
                      .cambios.length === 0 ? (

                      <div className="audit-no-changes">
                        No se detectaron cambios
                        en los valores registrados.
                      </div>

                    ) : (

                      detalleSeleccionado
                        .cambios.map(
                          (cambio) => (

                            <div
                              className="audit-change-card"
                              key={cambio.campo}
                            >

                              <div className="audit-change-name">
                                {cambio.nombre}
                              </div>


                              <div className="audit-change-values">

                                <div>

                                  <span>
                                    Antes
                                  </span>

                                  <strong className="audit-before">
                                    {cambio.antes}
                                  </strong>

                                </div>


                                <div className="audit-change-arrow">
                                  →
                                </div>


                                <div>

                                  <span>
                                    Después
                                  </span>

                                  <strong className="audit-after">
                                    {cambio.despues}
                                  </strong>

                                </div>

                              </div>

                            </div>

                          )
                        )

                    )}

                  </div>

                )}


                {detalleSeleccionado.tipo ===
                  "datos" && (

                  <div className="audit-data-grid">

                    {detalleSeleccionado
                      .datos.map(
                        (dato) => (

                          <div
                            className="audit-data-item"
                            key={dato.campo}
                          >

                            <span>
                              {dato.nombre}
                            </span>

                            <strong>
                              {dato.valor}
                            </strong>

                          </div>

                        )
                      )}

                  </div>

                )}

              </div>

            )}

          </div>

        </div>

      )}

    </section>
  );
}


export default Auditoria;