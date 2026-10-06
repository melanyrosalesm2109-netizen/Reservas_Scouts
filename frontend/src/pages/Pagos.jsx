import { useCallback, useEffect, useState } from "react";

import {
  WalletCards,
  Plus,
  Search,
  Pencil,
  Trash2,
  X,
  CalendarDays,
  ReceiptText,
  RotateCcw,
  CircleDollarSign
} from "lucide-react";

import {
  listarPagos,
  buscarPagoPorId,
  crearPago,
  actualizarPago,
  eliminarPago
} from "../services/pagoService";

import {
  listarReservas
} from "../services/reservaService";

import "./Pagos.css";

const pagoVacio = {
  reservaId: "",
  monto: "",
  metodo: "SINPE Móvil",
  fechaPago: "",
  estado: "PENDIENTE",
  comprobante: "",
  notas: ""
};

const filtrosVacios = {
  codigoReserva: "",
  metodo: "",
  estado: "",
  fechaDesde: "",
  fechaHasta: ""
};

function Pagos() {

  const [pagos, setPagos] =
    useState([]);

  const [todosPagos, setTodosPagos] =
    useState([]);

  const [reservas, setReservas] =
    useState([]);

  const [filtros, setFiltros] =
    useState(filtrosVacios);

  const [formulario, setFormulario] =
    useState(pagoVacio);

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

  const cargarInicial = useCallback(async () => {

    try {

      setCargando(true);
      setError("");

      const [
        pagosData,
        reservasData
      ] = await Promise.all([
        listarPagos(),
        listarReservas()
      ]);

      setPagos(pagosData);
      setTodosPagos(pagosData);
      setReservas(reservasData);

    } catch (err) {

      setError(err.message);

    } finally {

      setCargando(false);
    }
  }, []);

  useEffect(() => {
    queueMicrotask(() => {
      void cargarInicial();
    });
  }, [cargarInicial]);

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

    try {

      setCargando(true);
      setError("");

      const datos =
        await listarPagos(
          filtros
        );

      setPagos(datos);

    } catch (err) {

      setError(err.message);

    } finally {

      setCargando(false);
    }
  };

  const limpiarFiltros = async () => {

    setFiltros(
      filtrosVacios
    );

    await cargarInicial();
  };

  const abrirNuevo = () => {

    setEditandoId(null);

    setFormulario({
      ...pagoVacio,

      fechaPago:
        new Date()
          .toISOString()
          .slice(0, 10)
    });

    setError("");
    setMensaje("");

    setModalAbierto(true);
  };

  const abrirEditar = async (
    pago
  ) => {

    try {

      setError("");
      setMensaje("");

      const detalle =
        await buscarPagoPorId(
          pago.id
        );

      setEditandoId(
        detalle.id
      );

      setFormulario({

        reservaId:
          detalle.reservaId || "",

        monto:
          detalle.monto || "",

        metodo:
          detalle.metodo ||
          "SINPE Móvil",

        fechaPago:
          detalle.fechaPago || "",

        estado:
          detalle.estado ||
          "PENDIENTE",

        comprobante:
          detalle.comprobante || "",

        notas:
          detalle.notas || ""
      });

      setModalAbierto(true);

    } catch (err) {

      setError(err.message);
    }
  };

  const cerrarModal = () => {

    setModalAbierto(false);

    setEditandoId(null);

    setFormulario(
      pagoVacio
    );
  };

  const handleChange = (
    event
  ) => {

    const {
      name,
      value
    } = event.target;

    setFormulario({
      ...formulario,
      [name]: value
    });
  };

  const guardarPago = async (
    event
  ) => {

    event.preventDefault();

    setError("");
    setMensaje("");

    if (!formulario.reservaId) {

      setError(
        "Debe seleccionar una reserva."
      );

      return;
    }

    if (
      !formulario.monto ||
      Number(formulario.monto) <= 0
    ) {

      setError(
        "El monto debe ser mayor que cero."
      );

      return;
    }

    if (!formulario.fechaPago) {

      setError(
        "Debe indicar la fecha del pago."
      );

      return;
    }

    const datos = {

      reservaId:
        Number(
          formulario.reservaId
        ),

      monto:
        Number(
          formulario.monto
        ),

      metodo:
        formulario.metodo,

      fechaPago:
        formulario.fechaPago,

      estado:
        formulario.estado,

      comprobante:
        formulario.comprobante
          .trim() || null,

      notas:
        formulario.notas
          .trim() || null
    };

    try {

      if (editandoId !== null) {

        await actualizarPago(
          editandoId,
          datos
        );

        cerrarModal();

        setMensaje(
          "Pago actualizado correctamente."
        );

      } else {

        await crearPago(
          datos
        );

        cerrarModal();

        setMensaje(
          "Pago registrado correctamente."
        );
      }

      setFiltros(
        filtrosVacios
      );

      await cargarInicial();

    } catch (err) {

      cerrarModal();

      setMensaje("");

      setError(
        err.message ||
        "No se pudo registrar el pago."
      );
    }
  };

  const borrarPago = async (
    pago
  ) => {

    const confirmar =
      window.confirm(
        `¿Deseas eliminar el pago de la reserva "${pago.reservaCodigo}"?`
      );

    if (!confirmar) {
      return;
    }

    try {

      setError("");
      setMensaje("");

      await eliminarPago(
        pago.id
      );

      setMensaje(
        "Pago eliminado correctamente."
      );

      await cargarInicial();

    } catch (err) {

      setError(err.message);
    }
  };

  const totalPagado =
    todosPagos
      .filter(
        (pago) =>
          pago.estado ===
          "PAGADO"
      )
      .reduce(
        (total, pago) =>
          total +
          Number(pago.monto),
        0
      );

  const pendientes =
    todosPagos.filter(
      (pago) =>
        pago.estado ===
        "PENDIENTE"
    ).length;

  const pagados =
    todosPagos.filter(
      (pago) =>
        pago.estado ===
        "PAGADO"
    ).length;

  return (

    <div className="pagos-page">

      {/* CABECERA */}

      <div className="pagos-header">

        <div>

          <span className="pagos-label">
            GESTIÓN DE PAGOS
          </span>

          <h1>
            Pagos
          </h1>

          <p>
            Administra los pagos asociados
            a las reservas.
          </p>

        </div>

        <button
          className="pagos-add-button"
          onClick={abrirNuevo}
        >
          <Plus size={18} />
          Nuevo pago
        </button>

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

      {/* ESTADÍSTICAS */}

      <div className="pagos-stats">

        <div className="pago-stat">

          <WalletCards size={22} />

          <div>
            <span>
              Total de pagos
            </span>

            <strong>
              {todosPagos.length}
            </strong>
          </div>

        </div>

        <div className="pago-stat">

          <ReceiptText size={22} />

          <div>
            <span>
              Pagados
            </span>

            <strong>
              {pagados}
            </strong>
          </div>

        </div>

        <div className="pago-stat">

          <CalendarDays size={22} />

          <div>
            <span>
              Pendientes
            </span>

            <strong>
              {pendientes}
            </strong>
          </div>

        </div>

        <div className="pago-stat">

          <CircleDollarSign size={22} />

          <div>
            <span>
              Total recibido
            </span>

            <strong>
              ₡
              {totalPagado.toLocaleString(
                "es-CR"
              )}
            </strong>
          </div>

        </div>

      </div>

      {/* PANEL */}

      <section className="pagos-panel">

        <form
          className="pagos-filtros"
          onSubmit={aplicarFiltros}
        >

          <div className="pagos-search">

            <Search size={17} />

            <input
              name="codigoReserva"
              placeholder="Código reserva..."
              value={
                filtros.codigoReserva
              }
              onChange={
                handleFiltroChange
              }
            />

          </div>

          <select
            name="metodo"
            value={
              filtros.metodo
            }
            onChange={
              handleFiltroChange
            }
          >

            <option value="">
              Todos los métodos
            </option>

            <option value="SINPE Móvil">
              SINPE Móvil
            </option>

            <option value="Transferencia bancaria">
              Transferencia bancaria
            </option>

            <option value="Efectivo">
              Efectivo
            </option>

            <option value="Tarjeta">
              Tarjeta
            </option>

          </select>

          <select
            name="estado"
            value={
              filtros.estado
            }
            onChange={
              handleFiltroChange
            }
          >

            <option value="">
              Todos los estados
            </option>

            <option value="PAGADO">
              Pagado
            </option>

            <option value="PENDIENTE">
              Pendiente
            </option>

            <option value="RECHAZADO">
              Rechazado
            </option>

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
            className="pagos-filter-button"
          >
            Buscar
          </button>

          <button
            type="button"
            className="pagos-clear-button"
            onClick={
              limpiarFiltros
            }
          >
            <RotateCcw size={16} />
            Limpiar
          </button>

        </form>

        <div className="pagos-resultados">
          Mostrando {pagos.length} pago(s)
        </div>

        <div className="pagos-table-wrapper">

          <table className="pagos-table">

            <thead>

              <tr>
                <th>Reserva</th>
                <th>Espacio</th>
                <th>Monto</th>
                <th>Método</th>
                <th>Fecha</th>
                <th>Estado</th>
                <th>Acciones</th>
              </tr>

            </thead>

            <tbody>

              {cargando ? (

                <tr>

                  <td
                    colSpan="7"
                    className="pagos-empty"
                  >
                    Cargando pagos...
                  </td>

                </tr>

              ) : pagos.length === 0 ? (

                <tr>

                  <td
                    colSpan="7"
                    className="pagos-empty"
                  >

                    <WalletCards size={36} />

                    <strong>
                      No hay pagos registrados
                    </strong>

                    <span>
                      Registra el primer pago
                      usando el botón superior.
                    </span>

                  </td>

                </tr>

              ) : (

                pagos.map(
                  (pago) => (

                    <tr key={pago.id}>

                      <td>
                        <strong className="pago-codigo">
                          {pago.reservaCodigo}
                        </strong>
                      </td>

                      <td>
                        {pago.espacio}
                      </td>

                      <td>
                        <strong>
                          ₡
                          {Number(
                            pago.monto
                          ).toLocaleString(
                            "es-CR"
                          )}
                        </strong>
                      </td>

                      <td>
                        {pago.metodo}
                      </td>

                      <td>
                        {pago.fechaPago
                          ? new Date(
                              `${pago.fechaPago}T00:00:00`
                            ).toLocaleDateString(
                              "es-CR"
                            )
                          : ""}
                      </td>

                      <td>

                        <span
                          className={`pago-status ${pago.estado.toLowerCase()}`}
                        >
                          {pago.estado}
                        </span>

                      </td>

                      <td>

                        <div className="pago-actions">

                          <button
                            type="button"
                            className="pago-edit"
                            onClick={() =>
                              abrirEditar(
                                pago
                              )
                            }
                          >
                            <Pencil size={16} />
                          </button>

                          <button
                            type="button"
                            className="pago-delete"
                            onClick={() =>
                              borrarPago(
                                pago
                              )
                            }
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

        <div className="pago-modal-overlay">

          <div className="pago-modal">

            <div className="pago-modal-header">

              <div>

                <span>
                  RESERVAS SCOUTS
                </span>

                <h2>
                  {editandoId !== null
                    ? "Editar pago"
                    : "Nuevo pago"}
                </h2>

                <p>
                  Registra la información
                  correspondiente al pago.
                </p>

              </div>

              <button
                type="button"
                onClick={cerrarModal}
              >
                <X size={21} />
              </button>

            </div>

            <form
              className="pago-form"
              onSubmit={guardarPago}
            >

              <div className="pago-form-grid">

                <div className="pago-field pago-full">

                  <label>
                    Reserva *
                  </label>

                  <select
                    name="reservaId"
                    required
                    value={
                      formulario.reservaId
                    }
                    onChange={
                      handleChange
                    }
                  >

                    <option value="">
                      Seleccione una reserva
                    </option>

                    {reservas.map(
                      (reserva) => (

                        <option
                          key={reserva.id}
                          value={reserva.id}
                        >
                          {reserva.codigo}
                          {" - "}
                          {reserva.espacio}
                          {" - "}
                          {reserva.solicitante}
                        </option>

                      )
                    )}

                  </select>

                </div>

                <div className="pago-field">

                  <label>
                    Monto *
                  </label>

                  <input
                    type="number"
                    name="monto"
                    min="0.01"
                    step="0.01"
                    required
                    value={
                      formulario.monto
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Ej: 25000"
                  />

                </div>

                <div className="pago-field">

                  <label>
                    Fecha de pago *
                  </label>

                  <input
                    type="date"
                    name="fechaPago"
                    required
                    value={
                      formulario.fechaPago
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>

                <div className="pago-field">

                  <label>
                    Método *
                  </label>

                  <select
                    name="metodo"
                    value={
                      formulario.metodo
                    }
                    onChange={
                      handleChange
                    }
                  >

                    <option value="SINPE Móvil">
                      SINPE Móvil
                    </option>

                    <option value="Transferencia bancaria">
                      Transferencia bancaria
                    </option>

                    <option value="Efectivo">
                      Efectivo
                    </option>

                    <option value="Tarjeta">
                      Tarjeta
                    </option>

                  </select>

                </div>

                <div className="pago-field">

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

                    <option value="PAGADO">
                      Pagado
                    </option>

                    <option value="RECHAZADO">
                      Rechazado
                    </option>

                  </select>

                </div>

                <div className="pago-field pago-full">

                  <label>
                    Comprobante
                  </label>

                  <input
                    type="text"
                    name="comprobante"
                    maxLength="255"
                    value={
                      formulario.comprobante
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Número o referencia del comprobante"
                  />

                </div>

                <div className="pago-field pago-full">

                  <label>
                    Notas
                  </label>

                  <textarea
                    name="notas"
                    rows="4"
                    value={
                      formulario.notas
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Observaciones del pago..."
                  />

                </div>

              </div>

              <div className="pago-form-actions">

                <button
                  type="button"
                  className="pago-cancel"
                  onClick={cerrarModal}
                >
                  Cancelar
                </button>

                <button
                  type="submit"
                  className="pago-save"
                >
                  {editandoId !== null
                    ? "Guardar cambios"
                    : "Registrar pago"}
                </button>

              </div>

            </form>

          </div>

        </div>

      )}

    </div>
  );
}

export default Pagos;