import { useCallback, useEffect, useState } from "react";

import {
  CalendarDays,
  Plus,
  Search,
  Pencil,
  Trash2,
  X,
  Clock3,
  UserRound,
  Building2,
  RotateCcw,
  Users,
  MapPin,
  CircleDollarSign,
  CheckCircle2,
  XCircle
} from "lucide-react";

import {
  listarReservas,
  buscarReservaPorId,
  crearReserva,
  actualizarReserva,
  eliminarReserva,
  consultarDisponibilidad
} from "../services/reservaService";

import {
  listarEspacios
} from "../services/espacioService";

import {
  listarPerfilesParaReserva
} from "../services/perfilService";

import { useAuth } from "../context/useAuth";

import "./Reservas.css";


const reservaVacia = {
  codigo: "",
  espacioId: "",
  solicitantePerfilId: "",
  creadoPorUsuarioId: null,
  grupo: "",
  responsable: "",
  telefono: "",
  email: "",
  participantes: "",
  tipoActividad: "",
  fechaInicio: "",
  fechaFin: "",
  estado: "PENDIENTE",
  observaciones: ""
};


const filtrosVacios = {
  codigo: "",
  responsable: "",
  estado: "",
  espacioId: "",
  solicitantePerfilId: "",
  fechaDesde: "",
  fechaHasta: ""
};


const consultaVacia = {
  fechaInicio: "",
  fechaFin: ""
};


function Reservas() {

  const { usuario } = useAuth();

  const puedeGestionarReservas =
    usuario?.rol === "Administrador" ||
    usuario?.rol === "Recepcionista";

  const esUsuarioFinal =
    usuario?.rol === "Usuario" ||
    usuario?.rol === "Miembro";


  const [reservas, setReservas] =
    useState([]);

  const [todasReservas, setTodasReservas] =
    useState([]);

  const [espacios, setEspacios] =
    useState([]);

  const [perfiles, setPerfiles] =
    useState([]);

  const [filtros, setFiltros] =
    useState(filtrosVacios);

  const [formulario, setFormulario] =
    useState(reservaVacia);

  const [modalAbierto, setModalAbierto] =
    useState(false);

  const [editandoId, setEditandoId] =
    useState(null);

  const [cargando, setCargando] =
    useState(true);

  const [mensaje, setMensaje] =
    useState("");

  const [error, setError] =
    useState("");

  const [
    consultaFechas,
    setConsultaFechas
  ] = useState(consultaVacia);

  const [
    disponibilidadEspacios,
    setDisponibilidadEspacios
  ] = useState({});

  const [
    consultandoDisponibilidad,
    setConsultandoDisponibilidad
  ] = useState(false);


  // =====================================================
  // CARGAR DATOS AL INICIAR
  // =====================================================

  const cargarInicial = useCallback(async () => {

    try {

      setCargando(true);
      setError("");

      const [
        reservasData,
        espaciosData,
        perfilesData
      ] = await Promise.all([
        listarReservas(),
        listarEspacios(),
        listarPerfilesParaReserva()
      ]);

      setReservas(reservasData);
      setTodasReservas(reservasData);
      setEspacios(espaciosData);
      setPerfiles(perfilesData);

    } catch (err) {

      setError(
        err.message ||
        "No se pudieron cargar los datos."
      );

    } finally {

      setCargando(false);
    }

  }, []);


  useEffect(() => {

    queueMicrotask(() => {
      void cargarInicial();
    });

  }, [cargarInicial]);


  // =====================================================
  // FILTRAR RESERVAS
  // =====================================================

  const cargarReservas = async (
    filtrosAplicados = {}
  ) => {

    try {

      setCargando(true);
      setError("");

      const datos =
        await listarReservas(
          filtrosAplicados
        );

      setReservas(datos);

    } catch (err) {

      setError(err.message);

    } finally {

      setCargando(false);
    }
  };


  const handleFiltroChange = (
    event
  ) => {

    const {
      name,
      value
    } = event.target;

    setFiltros({
      ...filtros,
      [name]: value
    });
  };


  const aplicarFiltros = async (
    event
  ) => {

    event.preventDefault();

    await cargarReservas(
      filtros
    );
  };


  const limpiarFiltros = async () => {

    setFiltros(
      filtrosVacios
    );

    await cargarReservas();
  };


  // =====================================================
  // CONSULTAR DISPONIBILIDAD DE ESPACIOS
  // =====================================================

  const handleConsultaFechas = (
    event
  ) => {

    const {
      name,
      value
    } = event.target;

    setConsultaFechas(
      (anterior) => ({
        ...anterior,
        [name]: value
      })
    );

    setDisponibilidadEspacios({});
  };


  const consultarEspaciosDisponibles = async (
    event
  ) => {

    event?.preventDefault();

    setError("");
    setMensaje("");

    if (
      !consultaFechas.fechaInicio ||
      !consultaFechas.fechaFin
    ) {

      setError(
        "Debe indicar la fecha y hora de inicio y final."
      );

      return;
    }

    if (
      new Date(consultaFechas.fechaFin) <=
      new Date(consultaFechas.fechaInicio)
    ) {

      setError(
        "La fecha final debe ser mayor que la fecha inicial."
      );

      return;
    }

    try {

      setConsultandoDisponibilidad(true);

      const resultados = {};

      await Promise.all(
        espacios.map(async (espacio) => {

          if (
            espacio.estado !== "DISPONIBLE"
          ) {

            resultados[espacio.id] = false;
            return;
          }

          const respuesta =
            await consultarDisponibilidad(
              espacio.id,
              consultaFechas.fechaInicio,
              consultaFechas.fechaFin
            );

          resultados[espacio.id] =
            Boolean(respuesta?.disponible);
        })
      );

      setDisponibilidadEspacios(
        resultados
      );

    } catch (err) {

      setError(
        err.message ||
        "No se pudo consultar la disponibilidad."
      );

    } finally {

      setConsultandoDisponibilidad(false);
    }
  };


  // =====================================================
  // NUEVA RESERVA
  // =====================================================

  const generarCodigoReserva = () => {

    return `RES-${Date.now()}`;
  };


  const abrirNueva = (
    espacio = null
  ) => {

    setEditandoId(null);

    const perfilPorDefecto =
      esUsuarioFinal &&
      perfiles.length === 1
        ? perfiles[0].idPerfil
        : "";

    setFormulario({
      ...reservaVacia,

      codigo:
        esUsuarioFinal
          ? generarCodigoReserva()
          : "",

      espacioId:
        espacio?.id || "",

      solicitantePerfilId:
        perfilPorDefecto,

      fechaInicio:
        esUsuarioFinal
          ? consultaFechas.fechaInicio
          : "",

      fechaFin:
        esUsuarioFinal
          ? consultaFechas.fechaFin
          : "",

      estado: "PENDIENTE"
    });

    setError("");
    setMensaje("");
    setModalAbierto(true);
  };


  // =====================================================
  // EDITAR RESERVA
  // =====================================================

  const abrirEditar = async (
    reserva
  ) => {

    try {

      setError("");
      setMensaje("");

      const detalle =
        await buscarReservaPorId(
          reserva.id
        );

      setEditandoId(
        detalle.id
      );

      setFormulario({

        codigo:
          detalle.codigo || "",

        espacioId:
          detalle.espacioId || "",

        solicitantePerfilId:
          detalle.solicitantePerfilId || "",

        creadoPorUsuarioId:
          null,

        grupo:
          detalle.grupo || "",

        responsable:
          detalle.responsable || "",

        telefono:
          detalle.telefono || "",

        email:
          detalle.email || "",

        participantes:
          detalle.participantes || "",

        tipoActividad:
          detalle.tipoActividad || "",

        fechaInicio:
          detalle.fechaInicio
            ? detalle.fechaInicio.slice(
                0,
                16
              )
            : "",

        fechaFin:
          detalle.fechaFin
            ? detalle.fechaFin.slice(
                0,
                16
              )
            : "",

        estado:
          detalle.estado ||
          "PENDIENTE",

        observaciones:
          detalle.observaciones || ""
      });

      setModalAbierto(true);

    } catch (err) {

      setError(err.message);
    }
  };


  // =====================================================
  // CERRAR MODAL
  // =====================================================

  const cerrarModal = () => {

    setModalAbierto(false);
    setEditandoId(null);
    setFormulario(
      reservaVacia
    );
  };


  // =====================================================
  // CAMBIOS DEL FORMULARIO
  // =====================================================

  const handleChange = (
    event
  ) => {

    const {
      name,
      value
    } = event.target;

    if (name === "espacioId") {

      const espacioNuevo =
        espacios.find(
          (espacio) =>
            espacio.id ===
            Number(value)
        );

      const capacidad =
        espacioNuevo?.capacidad ||
        null;

      setFormulario(
        (anterior) => ({

          ...anterior,

          espacioId: value,

          participantes:
            capacidad &&
            Number(
              anterior.participantes
            ) > capacidad
              ? ""
              : anterior.participantes
        })
      );

      return;
    }

    setFormulario(
      (anterior) => ({
        ...anterior,
        [name]: value
      })
    );
  };


  // =====================================================
  // ESPACIO SELECCIONADO
  // =====================================================

  const espacioSeleccionado =
    espacios.find(
      (espacio) =>
        espacio.id ===
        Number(
          formulario.espacioId
        )
    );


  const capacidadMaxima =
    espacioSeleccionado?.capacidad ||
    null;


  const espaciosDisponibles =
    espacios.filter(
      (espacio) =>
        espacio.estado ===
          "DISPONIBLE" ||
        espacio.id ===
          Number(
            formulario.espacioId
          )
    );


  const perfilSeleccionado =
    perfiles.find(
      (perfil) =>
        perfil.idPerfil ===
        Number(
          formulario.solicitantePerfilId
        )
    );


  // =====================================================
  // GUARDAR RESERVA
  // =====================================================

  const guardarReserva = async (
    event
  ) => {

    event.preventDefault();

    setError("");
    setMensaje("");


    if (!formulario.codigo.trim()) {

      setError(
        "No se pudo generar el código de la reserva."
      );

      return;
    }


    if (!formulario.espacioId) {

      setError(
        "Debe seleccionar un espacio."
      );

      return;
    }


    if (
      !formulario.solicitantePerfilId
    ) {

      setError(
        "Debe seleccionar un solicitante."
      );

      return;
    }


    if (
      !formulario.participantes ||
      Number(
        formulario.participantes
      ) < 1
    ) {

      setError(
        "Debe indicar al menos un participante."
      );

      return;
    }


    if (
      capacidadMaxima &&
      Number(
        formulario.participantes
      ) > capacidadMaxima
    ) {

      setError(
        `Este espacio permite un máximo de ${capacidadMaxima} participante(s).`
      );

      return;
    }


    if (
      !formulario.fechaInicio ||
      !formulario.fechaFin
    ) {

      setError(
        "Debe indicar la fecha de inicio y la fecha final."
      );

      return;
    }


    if (
      new Date(
        formulario.fechaFin
      ) <=
      new Date(
        formulario.fechaInicio
      )
    ) {

      setError(
        "La fecha final debe ser mayor que la fecha inicial."
      );

      return;
    }


    try {

      /*
       * Para Usuario/Miembro volvemos a consultar justo antes
       * de guardar, porque otro usuario pudo reservar el mismo
       * espacio después de la consulta inicial.
       */
      if (
        esUsuarioFinal &&
        editandoId === null
      ) {

        const respuestaDisponibilidad =
          await consultarDisponibilidad(
            Number(formulario.espacioId),
            formulario.fechaInicio,
            formulario.fechaFin
          );

        if (
          !respuestaDisponibilidad?.disponible
        ) {

          setError(
            "El espacio ya no está disponible en ese rango de fecha y hora. Consulte otra fecha."
          );

          return;
        }
      }


      const datos = {

        codigo:
          formulario.codigo.trim(),

        espacioId:
          Number(
            formulario.espacioId
          ),

        solicitantePerfilId:
          Number(
            formulario.solicitantePerfilId
          ),

        creadoPorUsuarioId:
          null,

        grupo:
          formulario.grupo
            .trim() || null,

        responsable:
          formulario.responsable
            .trim(),

        telefono:
          formulario.telefono
            .trim(),

        email:
          formulario.email
            .trim(),

        participantes:
          Number(
            formulario.participantes
          ),

        tipoActividad:
          formulario.tipoActividad
            .trim(),

        fechaInicio:
          formulario.fechaInicio,

        fechaFin:
          formulario.fechaFin,

        estado:
          esUsuarioFinal
            ? "PENDIENTE"
            : formulario.estado,

        observaciones:
          formulario.observaciones
            .trim() || null
      };


      if (editandoId !== null) {

        await actualizarReserva(
          editandoId,
          datos
        );

        cerrarModal();

        setMensaje(
          "Reserva actualizada correctamente."
        );

      } else {

        await crearReserva(
          datos
        );

        cerrarModal();

        setMensaje(
          esUsuarioFinal
            ? "Solicitud de reserva enviada correctamente."
            : "Reserva creada correctamente."
        );
      }


      setFiltros(
        filtrosVacios
      );

      setDisponibilidadEspacios({});

      await cargarInicial();

    } catch (err) {

      setMensaje("");

      setError(
        err.message ||
        "No se pudo realizar la operación."
      );
    }
  };


  // =====================================================
  // ELIMINAR
  // =====================================================

  const borrarReserva = async (
    reserva
  ) => {

    const confirmar =
      window.confirm(
        `¿Deseas eliminar la reserva "${reserva.codigo}"?`
      );

    if (!confirmar) {
      return;
    }

    try {

      setError("");
      setMensaje("");

      await eliminarReserva(
        reserva.id
      );

      setMensaje(
        "Reserva eliminada correctamente."
      );

      await cargarInicial();

    } catch (err) {

      setError(
        err.message
      );
    }
  };


  // =====================================================
  // ESTADÍSTICAS
  // =====================================================

  const pendientes =
    todasReservas.filter(
      (reserva) =>
        reserva.estado ===
        "PENDIENTE"
    ).length;


  const aprobadas =
    todasReservas.filter(
      (reserva) =>
        reserva.estado ===
        "APROBADA"
    ).length;


  const finalizadas =
    todasReservas.filter(
      (reserva) =>
        reserva.estado ===
        "FINALIZADA"
    ).length;


  // =====================================================
  // TABLA DE RESERVAS
  // =====================================================

  const renderTablaReservas = () => (

    <section className="reservas-panel">

      {puedeGestionarReservas && (

        <form
          className="reservas-filtros-reales"
          onSubmit={aplicarFiltros}
        >

          <div className="reservas-search-real">

            <Search size={17} />

            <input
              name="codigo"
              placeholder="Código..."
              value={filtros.codigo}
              onChange={
                handleFiltroChange
              }
            />

          </div>

          <input
            name="responsable"
            placeholder="Responsable..."
            value={
              filtros.responsable
            }
            onChange={
              handleFiltroChange
            }
          />

          <select
            name="estado"
            value={filtros.estado}
            onChange={
              handleFiltroChange
            }
          >

            <option value="">
              Todos los estados
            </option>

            <option value="PENDIENTE">
              Pendiente
            </option>

            <option value="APROBADA">
              Aprobada
            </option>

            <option value="CANCELADA">
              Cancelada
            </option>

            <option value="FINALIZADA">
              Finalizada
            </option>

          </select>

          <select
            name="espacioId"
            value={
              filtros.espacioId
            }
            onChange={
              handleFiltroChange
            }
          >

            <option value="">
              Todos los espacios
            </option>

            {espacios.map(
              (espacio) => (

                <option
                  key={espacio.id}
                  value={espacio.id}
                >
                  {espacio.nombre}
                </option>
              )
            )}

          </select>

          <input
            type="date"
            name="fechaDesde"
            value={
              filtros.fechaDesde
            }
            onChange={
              handleFiltroChange
            }
          />

          <input
            type="date"
            name="fechaHasta"
            value={
              filtros.fechaHasta
            }
            onChange={
              handleFiltroChange
            }
          />

          <button
            type="submit"
            className="reservas-filter-button"
          >
            Buscar
          </button>

          <button
            type="button"
            className="reservas-clear-button"
            onClick={
              limpiarFiltros
            }
          >
            <RotateCcw size={16} />
            Limpiar
          </button>

        </form>
      )}


      <div className="reservas-table-footer">

        {esUsuarioFinal
          ? `Mis reservas: ${reservas.length}`
          : `Mostrando ${reservas.length} reserva(s)`}

      </div>


      <div className="reservas-table-wrapper">

        <table className="reservas-table">

          <thead>

            <tr>

              <th>Código</th>
              <th>Solicitante</th>
              <th>Espacio</th>
              <th>Responsable</th>
              <th>Participantes</th>
              <th>Fecha</th>
              <th>Estado</th>

              {puedeGestionarReservas && (
                <th>Acciones</th>
              )}

            </tr>

          </thead>

          <tbody>

            {cargando ? (

              <tr>

                <td
                  colSpan={
                    puedeGestionarReservas
                      ? 8
                      : 7
                  }
                  className="reservas-empty"
                >
                  Cargando reservas...
                </td>

              </tr>

            ) : reservas.length === 0 ? (

              <tr>

                <td
                  colSpan={
                    puedeGestionarReservas
                      ? 8
                      : 7
                  }
                  className="reservas-empty"
                >

                  <CalendarDays size={36} />

                  <strong>
                    {esUsuarioFinal
                      ? "Todavía no tienes reservas"
                      : "No hay reservas registradas"}
                  </strong>

                  <span>
                    {esUsuarioFinal
                      ? "Consulta la disponibilidad de los espacios y realiza tu primera reserva."
                      : "Crea la primera reserva usando el botón superior."}
                  </span>

                </td>

              </tr>

            ) : (

              reservas.map(
                (reserva) => (

                  <tr
                    key={reserva.id}
                  >

                    <td>

                      <strong className="reservation-number">
                        {reserva.codigo}
                      </strong>

                    </td>

                    <td>

                      <div className="table-person">

                        <div>
                          <UserRound
                            size={16}
                          />
                        </div>

                        <strong>
                          {reserva.solicitante}
                        </strong>

                      </div>

                    </td>

                    <td>

                      <span className="table-space">

                        <Building2
                          size={15}
                        />

                        {reserva.espacio}

                      </span>

                    </td>

                    <td>
                      {reserva.responsable}
                    </td>

                    <td>

                      <span className="reservation-time">

                        <Users size={14} />

                        {reserva.participantes}

                      </span>

                    </td>

                    <td>

                      <span className="reservation-time">

                        <Clock3 size={14} />

                        {reserva.fechaInicio
                          ? new Date(
                              reserva.fechaInicio
                            ).toLocaleString(
                              "es-CR"
                            )
                          : ""}

                      </span>

                    </td>

                    <td>

                      <span
                        className={`reservation-status ${
                          reserva.estado ===
                          "APROBADA"
                            ? "confirmed"

                            : reserva.estado ===
                              "CANCELADA"
                            ? "cancelled"

                            : reserva.estado ===
                              "FINALIZADA"
                            ? "finished"

                            : "pending"
                        }`}
                      >
                        {reserva.estado}
                      </span>

                    </td>

                    {puedeGestionarReservas && (

                      <td>

                        <div className="table-actions">

                          <button
                            type="button"
                            className="edit-button"
                            onClick={() =>
                              abrirEditar(
                                reserva
                              )
                            }
                            title="Editar reserva"
                          >
                            <Pencil size={16} />
                          </button>

                          <button
                            type="button"
                            className="delete-button"
                            onClick={() =>
                              borrarReserva(
                                reserva
                              )
                            }
                            title="Eliminar reserva"
                          >
                            <Trash2 size={16} />
                          </button>

                        </div>

                      </td>
                    )}

                  </tr>
                )
              )
            )}

          </tbody>

        </table>

      </div>

    </section>
  );


  // =====================================================
  // INTERFAZ
  // =====================================================

  return (

    <div className="reservas-page">

      <div className="reservas-header">

        <div>

          <span className="reservas-section-label">
            {esUsuarioFinal
              ? "RESERVA DE ESPACIOS"
              : "GESTIÓN DE RESERVAS"}
          </span>

          <h1>
            Reservas
          </h1>

          <p>
            {esUsuarioFinal
              ? "Consulta los espacios Scouts disponibles y realiza tu reservación."
              : "Gestiona las reservaciones de los espacios Scouts."}
          </p>

        </div>

        {puedeGestionarReservas && (

          <button
            className="reservas-primary-button"
            onClick={() => abrirNueva()}
          >
            <Plus size={18} />
            Nueva reserva
          </button>
        )}

      </div>


      {mensaje && (

        <div className="mensaje-exito">
          {mensaje}
        </div>
      )}


      {error && (

        <div className="mensaje-error">
          {error}
        </div>
      )}


      {esUsuarioFinal && (

        <section
          style={{
            background: "#ffffff",
            border: "1px solid #e8e2d8",
            borderRadius: "18px",
            padding: "24px",
            marginBottom: "24px",
            boxShadow:
              "0 10px 28px rgba(21, 52, 72, 0.06)"
          }}
        >

          <div
            style={{
              marginBottom: "20px"
            }}
          >
            <h2
              style={{
                margin: 0,
                color: "#123b55"
              }}
            >
              Consultar disponibilidad
            </h2>

            <p
              style={{
                margin:
                  "6px 0 0 0",
                color: "#6f7780"
              }}
            >
              Selecciona la fecha y hora para ver qué espacios están libres.
            </p>
          </div>


          <form
            onSubmit={
              consultarEspaciosDisponibles
            }
            style={{
              display: "grid",
              gridTemplateColumns:
                "repeat(auto-fit, minmax(220px, 1fr))",
              gap: "14px",
              alignItems: "end",
              marginBottom: "24px"
            }}
          >

            <div>

              <label
                style={{
                  display: "block",
                  fontWeight: 700,
                  marginBottom: "7px",
                  color: "#263847"
                }}
              >
                Fecha y hora de inicio
              </label>

              <input
                type="datetime-local"
                name="fechaInicio"
                value={
                  consultaFechas.fechaInicio
                }
                onChange={
                  handleConsultaFechas
                }
                required
                style={{
                  width: "100%",
                  boxSizing:
                    "border-box",
                  minHeight: "46px",
                  padding:
                    "10px 12px",
                  border:
                    "1px solid #d9d4ca",
                  borderRadius:
                    "10px",
                  background:
                    "#fff"
                }}
              />

            </div>


            <div>

              <label
                style={{
                  display: "block",
                  fontWeight: 700,
                  marginBottom: "7px",
                  color: "#263847"
                }}
              >
                Fecha y hora final
              </label>

              <input
                type="datetime-local"
                name="fechaFin"
                value={
                  consultaFechas.fechaFin
                }
                onChange={
                  handleConsultaFechas
                }
                required
                style={{
                  width: "100%",
                  boxSizing:
                    "border-box",
                  minHeight: "46px",
                  padding:
                    "10px 12px",
                  border:
                    "1px solid #d9d4ca",
                  borderRadius:
                    "10px",
                  background:
                    "#fff"
                }}
              />

            </div>


            <button
              type="submit"
              className="reservas-primary-button"
              disabled={
                consultandoDisponibilidad
              }
              style={{
                minHeight: "46px"
              }}
            >
              <Search size={18} />

              {consultandoDisponibilidad
                ? "Consultando..."
                : "Consultar disponibilidad"}
            </button>

          </form>


          <div
            style={{
              display: "grid",
              gridTemplateColumns:
                "repeat(auto-fit, minmax(270px, 1fr))",
              gap: "18px"
            }}
          >

            {espacios.map(
              (espacio) => {

                const resultado =
                  disponibilidadEspacios[
                    espacio.id
                  ];

                const fueConsultado =
                  Object.prototype.hasOwnProperty.call(
                    disponibilidadEspacios,
                    espacio.id
                  );

                const disponible =
                  fueConsultado &&
                  resultado === true;

                return (

                  <article
                    key={espacio.id}
                    style={{
                      border:
                        "1px solid #e4ded4",
                      borderRadius:
                        "16px",
                      overflow: "hidden",
                      background:
                        "#fffaf4"
                    }}
                  >

                    {espacio.imagen ? (

                      <img
                        src={espacio.imagen}
                        alt={espacio.nombre}
                        style={{
                          width: "100%",
                          height: "170px",
                          objectFit:
                            "cover",
                          display: "block"
                        }}
                      />

                    ) : (

                      <div
                        style={{
                          height: "130px",
                          display: "flex",
                          alignItems:
                            "center",
                          justifyContent:
                            "center",
                          background:
                            "#123b55",
                          color: "#e4b65e"
                        }}
                      >
                        <Building2
                          size={42}
                        />
                      </div>
                    )}


                    <div
                      style={{
                        padding: "18px"
                      }}
                    >

                      <h3
                        style={{
                          margin:
                            "0 0 8px 0",
                          color:
                            "#123b55",
                          fontSize:
                            "20px"
                        }}
                      >
                        {espacio.nombre}
                      </h3>


                      {espacio.descripcion && (

                        <p
                          style={{
                            margin:
                              "0 0 14px 0",
                            color:
                              "#6f7780",
                            lineHeight:
                              1.45
                          }}
                        >
                          {espacio.descripcion}
                        </p>
                      )}


                      <div
                        style={{
                          display:
                            "grid",
                          gap: "9px",
                          color:
                            "#394b59",
                          marginBottom:
                            "16px"
                        }}
                      >

                        <span
                          style={{
                            display:
                              "flex",
                            gap: "8px",
                            alignItems:
                              "center"
                          }}
                        >
                          <MapPin
                            size={17}
                          />
                          {espacio.ubicacion}
                        </span>

                        <span
                          style={{
                            display:
                              "flex",
                            gap: "8px",
                            alignItems:
                              "center"
                          }}
                        >
                          <Users
                            size={17}
                          />
                          Capacidad máxima:{" "}
                          {espacio.capacidad}
                        </span>

                        <span
                          style={{
                            display:
                              "flex",
                            gap: "8px",
                            alignItems:
                              "center"
                          }}
                        >
                          <CircleDollarSign
                            size={17}
                          />

                          ₡
                          {Number(
                            espacio.costo ||
                            0
                          ).toLocaleString(
                            "es-CR"
                          )}
                        </span>

                      </div>


                      {espacio.estado !==
                        "DISPONIBLE" ? (

                        <div
                          style={{
                            display:
                              "flex",
                            gap: "7px",
                            alignItems:
                              "center",
                            fontWeight:
                              700,
                            color:
                              "#a33b3b",
                            marginBottom:
                              "14px"
                          }}
                        >
                          <XCircle
                            size={18}
                          />

                          {espacio.estado ===
                          "MANTENIMIENTO"
                            ? "En mantenimiento"
                            : "No disponible"}
                        </div>

                      ) : fueConsultado ? (

                        disponible ? (

                          <div
                            style={{
                              display:
                                "flex",
                              gap: "7px",
                              alignItems:
                                "center",
                              fontWeight:
                                700,
                              color:
                                "#2f7a49",
                              marginBottom:
                                "14px"
                            }}
                          >
                            <CheckCircle2
                              size={18}
                            />
                            Disponible para este horario
                          </div>

                        ) : (

                          <div
                            style={{
                              display:
                                "flex",
                              gap: "7px",
                              alignItems:
                                "center",
                              fontWeight:
                                700,
                              color:
                                "#a33b3b",
                              marginBottom:
                                "14px"
                            }}
                          >
                            <XCircle
                              size={18}
                            />
                            Ocupado en este horario
                          </div>
                        )

                      ) : (

                        <div
                          style={{
                            color:
                              "#826c48",
                            fontWeight:
                              600,
                            marginBottom:
                              "14px"
                          }}
                        >
                          Selecciona una fecha para consultar.
                        </div>
                      )}


                      <button
                        type="button"
                        className="reservas-primary-button"
                        disabled={
                          !disponible
                        }
                        onClick={() =>
                          abrirNueva(
                            espacio
                          )
                        }
                        style={{
                          width:
                            "100%",
                          justifyContent:
                            "center",
                          opacity:
                            disponible
                              ? 1
                              : 0.5,
                          cursor:
                            disponible
                              ? "pointer"
                              : "not-allowed"
                        }}
                      >
                        <Plus size={17} />
                        Reservar
                      </button>

                    </div>

                  </article>
                );
              }
            )}

          </div>

        </section>
      )}


      <div className="reservas-summary">

        <div>

          <CalendarDays size={21} />

          <span>
            {esUsuarioFinal
              ? "Mis reservas"
              : "Total"}
          </span>

          <strong>
            {todasReservas.length}
          </strong>

        </div>

        <div>

          <Clock3 size={21} />

          <span>
            Pendientes
          </span>

          <strong>
            {pendientes}
          </strong>

        </div>

        <div>

          <CalendarDays size={21} />

          <span>
            Aprobadas
          </span>

          <strong>
            {aprobadas}
          </strong>

        </div>

        <div>

          <CalendarDays size={21} />

          <span>
            Finalizadas
          </span>

          <strong>
            {finalizadas}
          </strong>

        </div>

      </div>


      {renderTablaReservas()}


      {modalAbierto && (

        <div className="reservation-modal-overlay">

          <div className="reservation-modal reservation-modal-large">

            <div className="reservation-modal-header">

              <div>

                <span>
                  RESERVAS SCOUTS
                </span>

                <h2>
                  {editandoId !== null
                    ? "Editar reserva"
                    : esUsuarioFinal
                    ? "Solicitar reserva"
                    : "Nueva reserva"}
                </h2>

                <p>
                  Complete los datos de la reservación.
                </p>

              </div>

              <button
                type="button"
                onClick={cerrarModal}
                className="reservation-modal-close"
              >
                <X size={22} />
              </button>

            </div>


            <form
              className="reservation-form"
              onSubmit={
                guardarReserva
              }
            >

              <div className="reservation-form-grid">


                {puedeGestionarReservas && (

                  <div className="reservation-field">

                    <label>
                      Código *
                    </label>

                    <input
                      name="codigo"
                      maxLength="20"
                      required
                      value={
                        formulario.codigo
                      }
                      onChange={
                        handleChange
                      }
                      placeholder="Ej: RES-001"
                    />

                  </div>
                )}


                {puedeGestionarReservas && (

                  <div className="reservation-field">

                    <label>
                      Estado *
                    </label>

                    <select
                      name="estado"
                      value={
                        formulario.estado
                      }
                      onChange={
                        handleChange
                      }
                    >

                      <option value="PENDIENTE">
                        Pendiente
                      </option>

                      <option value="APROBADA">
                        Aprobada
                      </option>

                      <option value="CANCELADA">
                        Cancelada
                      </option>

                      <option value="FINALIZADA">
                        Finalizada
                      </option>

                    </select>

                  </div>
                )}


                <div className="reservation-field">

                  <label>
                    Espacio *
                  </label>

                  <select
                    name="espacioId"
                    required
                    value={
                      formulario.espacioId
                    }
                    onChange={
                      handleChange
                    }
                  >

                    <option value="">
                      Seleccione un espacio
                    </option>

                    {espaciosDisponibles.map(
                      (espacio) => (

                        <option
                          key={espacio.id}
                          value={espacio.id}
                        >
                          {espacio.nombre}
                          {" - "}
                          Capacidad:{" "}
                          {espacio.capacidad}
                        </option>
                      )
                    )}

                  </select>

                </div>


                <div className="reservation-field">

                  <label>
                    Solicitante *
                  </label>

                  {esUsuarioFinal &&
                  perfiles.length === 1 ? (

                    <input
                      value={
                        perfilSeleccionado?.nombre ||
                        perfiles[0]?.nombre ||
                        ""
                      }
                      disabled
                    />

                  ) : (

                    <select
                      name="solicitantePerfilId"
                      required
                      value={
                        formulario.solicitantePerfilId
                      }
                      onChange={
                        handleChange
                      }
                    >

                      <option value="">
                        Seleccione un perfil
                      </option>

                      {perfiles.map(
                        (perfil) => (

                          <option
                            key={
                              perfil.idPerfil
                            }
                            value={
                              perfil.idPerfil
                            }
                          >
                            {perfil.nombre}
                          </option>
                        )
                      )}

                    </select>
                  )}

                </div>


                <div className="reservation-field">

                  <label>
                    Responsable *
                  </label>

                  <input
                    name="responsable"
                    maxLength="160"
                    required
                    value={
                      formulario.responsable
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Nombre del responsable"
                  />

                </div>


                <div className="reservation-field">

                  <label>
                    Grupo
                  </label>

                  <input
                    name="grupo"
                    maxLength="160"
                    value={
                      formulario.grupo
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Grupo Scout"
                  />

                </div>


                <div className="reservation-field">

                  <label>
                    Teléfono *
                  </label>

                  <input
                    name="telefono"
                    maxLength="30"
                    required
                    value={
                      formulario.telefono
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Ej: 88888888"
                  />

                </div>


                <div className="reservation-field">

                  <label>
                    Correo *
                  </label>

                  <input
                    type="email"
                    name="email"
                    maxLength="160"
                    required
                    value={
                      formulario.email
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="correo@ejemplo.com"
                  />

                </div>


                <div className="reservation-field">

                  <label>
                    Participantes *

                    {capacidadMaxima && (
                      <span className="capacidad-info">
                        {" "}— Máximo {capacidadMaxima}
                      </span>
                    )}

                  </label>

                  <input
                    type="number"
                    name="participantes"
                    min="1"
                    max={
                      capacidadMaxima ||
                      undefined
                    }
                    required
                    disabled={
                      !formulario.espacioId
                    }
                    value={
                      formulario.participantes
                    }
                    onChange={
                      handleChange
                    }
                    placeholder={
                      capacidadMaxima
                        ? `Máximo ${capacidadMaxima}`
                        : "Seleccione primero un espacio"
                    }
                  />

                </div>


                <div className="reservation-field">

                  <label>
                    Tipo de actividad *
                  </label>

                  <input
                    name="tipoActividad"
                    maxLength="120"
                    required
                    value={
                      formulario.tipoActividad
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Ej: Reunión Scout"
                  />

                </div>


                <div className="reservation-field">

                  <label>
                    Fecha y hora inicio *
                  </label>

                  <input
                    type="datetime-local"
                    name="fechaInicio"
                    required
                    value={
                      formulario.fechaInicio
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>


                <div className="reservation-field">

                  <label>
                    Fecha y hora final *
                  </label>

                  <input
                    type="datetime-local"
                    name="fechaFin"
                    required
                    value={
                      formulario.fechaFin
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>


                <div className="reservation-field reservation-full">

                  <label>
                    Observaciones
                  </label>

                  <textarea
                    name="observaciones"
                    rows="4"
                    value={
                      formulario.observaciones
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Observaciones adicionales..."
                  />

                </div>

              </div>


              <div className="reservation-form-actions">

                <button
                  type="button"
                  className="reservation-cancel"
                  onClick={
                    cerrarModal
                  }
                >
                  Cancelar
                </button>

                <button
                  type="submit"
                  className="reservation-save"
                >
                  {editandoId !== null
                    ? "Guardar cambios"
                    : esUsuarioFinal
                    ? "Enviar solicitud"
                    : "Crear reserva"}
                </button>

              </div>

            </form>

          </div>

        </div>
      )}

    </div>
  );
}


export default Reservas;
