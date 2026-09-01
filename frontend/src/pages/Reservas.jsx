import { useEffect, useState } from "react";

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
  Users
} from "lucide-react";

import {
  listarReservas,
  buscarReservaPorId,
  crearReserva,
  actualizarReserva,
  eliminarReserva
} from "../services/reservaService";

import {
  listarEspacios
} from "../services/espacioService";

import {
  listarPerfiles
} from "../services/perfilService";

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

function Reservas() {

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

  // =====================================================
  // CARGAR DATOS AL INICIAR
  // =====================================================

  useEffect(() => {
    cargarInicial();
  }, []);

  const cargarInicial = async () => {

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
        listarPerfiles()
      ]);

      setReservas(reservasData);
      setTodasReservas(reservasData);

      setEspacios(espaciosData);
      setPerfiles(perfilesData);

    } catch (err) {

      setError(err.message);

    } finally {

      setCargando(false);
    }
  };

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
  // NUEVA RESERVA
  // =====================================================

  const abrirNueva = () => {

    setEditandoId(null);

    setFormulario(
      reservaVacia
    );

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

    // Cuando cambia el espacio
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

    setFormulario({
      ...formulario,
      [name]: value
    });
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

  // Para reservas nuevas solo mostramos disponibles.
  // En edición se permite también conservar el espacio
  // que ya estaba asociado a la reserva.
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

  // =====================================================
  // GUARDAR RESERVA
  // =====================================================

  const guardarReserva = async (
    event
  ) => {

    event.preventDefault();

    // ===================================================
    // VALIDACIONES DEL FRONTEND
    // Estas NO cierran el modal.
    // ===================================================

    setError("");
    setMensaje("");

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

    // ===================================================
    // DATOS PARA SPRING BOOT
    // ===================================================

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

      // Todavía no conectamos Usuarios
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
        formulario.estado,

      observaciones:
        formulario.observaciones
          .trim() || null
    };

    // ===================================================
    // AQUÍ LLAMAMOS AL BACKEND
    // Si SQL Server devuelve un error,
    // el catch cierra el modal.
    // ===================================================

    try {

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
          "Reserva creada correctamente."
        );
      }

      setFiltros(
        filtrosVacios
      );

      await cargarInicial();

    } catch (err) {

      // Si SQL Server rechaza la operación,
      // cerramos el formulario para mostrar
      // claramente el mensaje en la pantalla.

      cerrarModal();

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
  // INTERFAZ
  // =====================================================

  return (

    <div className="reservas-page">

      {/* CABECERA */}

      <div className="reservas-header">

        <div>

          <span className="reservas-section-label">
            GESTIÓN DE RESERVAS
          </span>

          <h1>
            Reservas
          </h1>

          <p>
            Gestiona las reservaciones
            de los espacios Scouts.
          </p>

        </div>

        <button
          className="reservas-primary-button"
          onClick={abrirNueva}
        >
          <Plus size={18} />
          Nueva reserva
        </button>

      </div>

      {/* MENSAJES */}

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

      {/* ESTADÍSTICAS */}

      <div className="reservas-summary">

        <div>

          <CalendarDays size={21} />

          <span>
            Total
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

      {/* PANEL */}

      <section className="reservas-panel">

        {/* FILTROS */}

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

        <div className="reservas-table-footer">
          Mostrando {reservas.length} reserva(s)
        </div>

        {/* TABLA */}

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
                <th>Acciones</th>
              </tr>

            </thead>

            <tbody>

              {cargando ? (

                <tr>

                  <td
                    colSpan="8"
                    className="reservas-empty"
                  >
                    Cargando reservas...
                  </td>

                </tr>

              ) : reservas.length === 0 ? (

                <tr>

                  <td
                    colSpan="8"
                    className="reservas-empty"
                  >

                    <CalendarDays size={36} />

                    <strong>
                      No hay reservas registradas
                    </strong>

                    <span>
                      Crea la primera reserva
                      usando el botón superior.
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
                        {
                          reserva.responsable
                        }
                      </td>

                      <td>

                        <span className="reservation-time">

                          <Users size={14} />

                          {
                            reserva.participantes
                          }

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

                    </tr>

                  )
                )

              )}

            </tbody>

          </table>

        </div>

      </section>

      {/* MODAL */}

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

                {/* CÓDIGO */}

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

                {/* ESTADO */}

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

                {/* ESPACIO */}

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
                          Capacidad:
                          {" "}
                          {espacio.capacidad}
                        </option>

                      )
                    )}

                  </select>

                </div>

                {/* SOLICITANTE */}

                <div className="reservation-field">

                  <label>
                    Solicitante *
                  </label>

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
                          {
                            perfil.nombre
                          }
                        </option>

                      )
                    )}

                  </select>

                </div>

                {/* RESPONSABLE */}

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

                {/* GRUPO */}

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

                {/* TELÉFONO */}

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

                {/* CORREO */}

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

                {/* PARTICIPANTES */}

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

                {/* TIPO ACTIVIDAD */}

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

                {/* FECHA INICIO */}

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

                {/* FECHA FINAL */}

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

                {/* OBSERVACIONES */}

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

              {/* BOTONES */}

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