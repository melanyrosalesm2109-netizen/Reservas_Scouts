import { useEffect, useState } from "react";

import {
  UsersRound,
  UserPlus,
  Search,
  Pencil,
  Trash2,
  X,
  Mail,
  Phone,
  CreditCard,
  RotateCcw,
  MapPin
} from "lucide-react";

import {
  listarPerfiles,
  crearPerfil,
  actualizarPerfil,
  eliminarPerfil
} from "../services/perfilService";

import "./Perfiles.css";

const perfilVacio = {
  usuarioId: "",
  nombre: "",
  identificacion: "",
  telefono: "",
  correoContacto: "",
  tipoPerfil: "Persona",
  direccion: ""
};

const filtrosVacios = {
  nombre: "",
  identificacion: "",
  correoContacto: "",
  tipoPerfil: ""
};

function Perfiles() {

  const [perfiles, setPerfiles] =
    useState([]);

  const [todosPerfiles, setTodosPerfiles] =
    useState([]);

  const [filtros, setFiltros] =
    useState(filtrosVacios);

  const [formulario, setFormulario] =
    useState(perfilVacio);

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

  useEffect(() => {
    cargarTodos();
  }, []);

  const cargarTodos = async () => {

    try {
      setCargando(true);
      setError("");

      const datos =
        await listarPerfiles();

      setPerfiles(datos);
      setTodosPerfiles(datos);

    } catch (err) {

      setError(err.message);

    } finally {

      setCargando(false);
    }
  };

  const handleFiltroChange = (
    event
  ) => {

    const { name, value } =
      event.target;

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
        await listarPerfiles(
          filtros
        );

      setPerfiles(datos);

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

    await cargarTodos();
  };

  const abrirNuevo = () => {

    setEditandoId(null);

    setFormulario(
      perfilVacio
    );

    setError("");
    setMensaje("");

    setModalAbierto(true);
  };

  const abrirEditar = (perfil) => {

    setEditandoId(
      perfil.idPerfil
    );

    setFormulario({

      usuarioId:
        perfil.usuarioId ?? "",

      nombre:
        perfil.nombre || "",

      identificacion:
        perfil.identificacion || "",

      telefono:
        perfil.telefono || "",

      correoContacto:
        perfil.correoContacto || "",

      tipoPerfil:
        perfil.tipoPerfil || "Persona",

      direccion:
        perfil.direccion || ""
    });

    setModalAbierto(true);
  };

  const cerrarModal = () => {

    setModalAbierto(false);

    setEditandoId(null);

    setFormulario(
      perfilVacio
    );
  };

  const handleChange = (
    event
  ) => {

    const { name, value } =
      event.target;

    setFormulario({
      ...formulario,
      [name]: value
    });
  };

  const guardarPerfil = async (
    event
  ) => {

    event.preventDefault();

    try {

      setError("");
      setMensaje("");

      const datos = {

        usuarioId:
          formulario.usuarioId
            ? Number(
                formulario.usuarioId
              )
            : null,

        nombre:
          formulario.nombre.trim(),

        identificacion:
          formulario.identificacion
            .trim() || null,

        telefono:
          formulario.telefono
            .trim() || null,

        correoContacto:
          formulario.correoContacto
            .trim(),

        tipoPerfil:
          formulario.tipoPerfil,

        direccion:
          formulario.direccion
            .trim() || null
      };

      if (editandoId !== null) {

        await actualizarPerfil(
          editandoId,
          datos
        );

        setMensaje(
          "Perfil actualizado correctamente."
        );

      } else {

        await crearPerfil(
          datos
        );

        setMensaje(
          "Perfil creado correctamente."
        );
      }

      cerrarModal();

      setFiltros(
        filtrosVacios
      );

      await cargarTodos();

    } catch (err) {

      setError(
        err.message
      );
    }
  };

  const borrarPerfil = async (
    perfil
  ) => {

    const confirmar =
      window.confirm(
        `¿Deseas eliminar el perfil "${perfil.nombre}"?`
      );

    if (!confirmar) {
      return;
    }

    try {

      setError("");
      setMensaje("");

      await eliminarPerfil(
        perfil.idPerfil
      );

      setMensaje(
        "Perfil eliminado correctamente."
      );

      await cargarTodos();

    } catch (err) {

      setError(
        err.message
      );
    }
  };

  const personas =
    todosPerfiles.filter(
      (perfil) =>
        perfil.tipoPerfil ===
        "Persona"
    ).length;

  const instituciones =
    todosPerfiles.filter(
      (perfil) =>
        perfil.tipoPerfil ===
        "Institucion"
    ).length;

  const grupos =
    todosPerfiles.filter(
      (perfil) =>
        perfil.tipoPerfil ===
        "Grupo Scout"
    ).length;

  return (
    <div className="perfiles-page">

      {/* CABECERA */}

      <div className="perfiles-header">

        <div>

          <span className="perfiles-label">
            GESTIÓN DE PERFILES
          </span>

          <h1>Perfiles</h1>

          <p>
            Administra personas,
            instituciones y grupos Scout.
          </p>

        </div>

        <button
          className="perfiles-add-button"
          onClick={abrirNuevo}
        >
          <UserPlus size={18} />
          Nuevo perfil
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

      <div className="perfiles-stats">

        <div className="perfil-stat">

          <UsersRound size={22} />

          <div>
            <span>Total</span>
            <strong>
              {todosPerfiles.length}
            </strong>
          </div>

        </div>

        <div className="perfil-stat">

          <UsersRound size={22} />

          <div>
            <span>Personas</span>
            <strong>
              {personas}
            </strong>
          </div>

        </div>

        <div className="perfil-stat">

          <UsersRound size={22} />

          <div>
            <span>Instituciones</span>
            <strong>
              {instituciones}
            </strong>
          </div>

        </div>

        <div className="perfil-stat">

          <UsersRound size={22} />

          <div>
            <span>Grupos Scout</span>
            <strong>
              {grupos}
            </strong>
          </div>

        </div>

      </div>

      {/* PANEL */}

      <section className="perfiles-panel">

        <form
          className="perfiles-filtros"
          onSubmit={aplicarFiltros}
        >

          <div className="perfil-search">

            <Search size={18} />

            <input
              type="text"
              name="nombre"
              placeholder="Nombre..."
              value={filtros.nombre}
              onChange={
                handleFiltroChange
              }
            />

          </div>

          <input
            type="text"
            name="identificacion"
            placeholder="Identificación..."
            value={
              filtros.identificacion
            }
            onChange={
              handleFiltroChange
            }
          />

          <input
            type="text"
            name="correoContacto"
            placeholder="Correo..."
            value={
              filtros.correoContacto
            }
            onChange={
              handleFiltroChange
            }
          />

          <select
            name="tipoPerfil"
            value={
              filtros.tipoPerfil
            }
            onChange={
              handleFiltroChange
            }
          >

            <option value="">
              Todos los tipos
            </option>

            <option value="Persona">
              Persona
            </option>

            <option value="Institucion">
              Institución
            </option>

            <option value="Grupo Scout">
              Grupo Scout
            </option>

          </select>

          <button
            type="submit"
            className="perfil-filter-button"
          >
            Buscar
          </button>

          <button
            type="button"
            className="perfil-clear-button"
            onClick={limpiarFiltros}
          >
            <RotateCcw size={16} />
            Limpiar
          </button>

        </form>

        <div className="perfiles-resultados">
          Mostrando {perfiles.length} perfil(es)
        </div>

        {/* TABLA */}

        <div className="perfiles-table-wrapper">

          <table className="perfiles-table">

            <thead>

              <tr>
                <th>Perfil</th>
                <th>Identificación</th>
                <th>Contacto</th>
                <th>Tipo</th>
                <th>Dirección</th>
                <th>Acciones</th>
              </tr>

            </thead>

            <tbody>

              {cargando ? (

                <tr>

                  <td
                    colSpan="6"
                    className="perfiles-empty"
                  >
                    Cargando perfiles...
                  </td>

                </tr>

              ) : perfiles.length === 0 ? (

                <tr>

                  <td
                    colSpan="6"
                    className="perfiles-empty"
                  >

                    <UsersRound size={34} />

                    <strong>
                      No hay perfiles registrados
                    </strong>

                    <span>
                      Crea el primer perfil
                      usando el botón superior.
                    </span>

                  </td>

                </tr>

              ) : (

                perfiles.map(
                  (perfil) => (

                    <tr
                      key={
                        perfil.idPerfil
                      }
                    >

                      <td>

                        <div className="perfil-name">

                          <div>
                            <UsersRound
                              size={17}
                            />
                          </div>

                          <div>

                            <strong>
                              {perfil.nombre}
                            </strong>

                            <small>
                              ID #
                              {perfil.idPerfil}
                            </small>

                          </div>

                        </div>

                      </td>

                      <td>

                        <span className="perfil-detail">

                          <CreditCard
                            size={14}
                          />

                          {perfil.identificacion ||
                            "Sin identificación"}

                        </span>

                      </td>

                      <td>

                        <div className="perfil-contact">

                          <span>
                            <Mail size={13} />

                            {
                              perfil.correoContacto
                            }
                          </span>

                          <span>
                            <Phone size={13} />

                            {perfil.telefono ||
                              "Sin teléfono"}
                          </span>

                        </div>

                      </td>

                      <td>

                        <span
                          className={`perfil-tipo ${
                            perfil.tipoPerfil ===
                            "Persona"
                              ? "persona"
                              : perfil.tipoPerfil ===
                                "Institucion"
                              ? "institucion"
                              : "grupo"
                          }`}
                        >
                          {
                            perfil.tipoPerfil
                          }
                        </span>

                      </td>

                      <td>

                        <span className="perfil-detail">

                          <MapPin size={14} />

                          {perfil.direccion ||
                            "Sin dirección"}

                        </span>

                      </td>

                      <td>

                        <div className="perfil-actions">

                          <button
                            type="button"
                            className="perfil-edit"
                            onClick={() =>
                              abrirEditar(
                                perfil
                              )
                            }
                          >
                            <Pencil
                              size={16}
                            />
                          </button>

                          <button
                            type="button"
                            className="perfil-delete"
                            onClick={() =>
                              borrarPerfil(
                                perfil
                              )
                            }
                          >
                            <Trash2
                              size={16}
                            />
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

        <div className="perfil-modal-overlay">

          <div className="perfil-modal">

            <div className="perfil-modal-header">

              <div>

                <span>
                  RESERVAS SCOUTS
                </span>

                <h2>
                  {editandoId !== null
                    ? "Editar perfil"
                    : "Nuevo perfil"}
                </h2>

                <p>
                  Complete la información
                  del perfil.
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
              className="perfil-form"
              onSubmit={
                guardarPerfil
              }
            >

              <div className="perfil-form-grid">

                <div className="perfil-field">

                  <label>
                    Nombre *
                  </label>

                  <input
                    type="text"
                    name="nombre"
                    maxLength="160"
                    required
                    value={
                      formulario.nombre
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>

                <div className="perfil-field">

                  <label>
                    Tipo de perfil *
                  </label>

                  <select
                    name="tipoPerfil"
                    value={
                      formulario.tipoPerfil
                    }
                    onChange={
                      handleChange
                    }
                  >

                    <option value="Persona">
                      Persona
                    </option>

                    <option value="Institucion">
                      Institución
                    </option>

                    <option value="Grupo Scout">
                      Grupo Scout
                    </option>

                  </select>

                </div>

                <div className="perfil-field">

                  <label>
                    Identificación
                  </label>

                  <input
                    type="text"
                    name="identificacion"
                    maxLength="30"
                    value={
                      formulario.identificacion
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>

                <div className="perfil-field">

                  <label>
                    Teléfono
                  </label>

                  <input
                    type="text"
                    name="telefono"
                    maxLength="30"
                    value={
                      formulario.telefono
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>

                <div className="perfil-field">

                  <label>
                    Correo de contacto *
                  </label>

                  <input
                    type="email"
                    name="correoContacto"
                    maxLength="160"
                    required
                    value={
                      formulario.correoContacto
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>

                <div className="perfil-field">

                  <label>
                    Usuario ID
                  </label>

                  <input
                    type="number"
                    name="usuarioId"
                    min="1"
                    placeholder="Opcional"
                    value={
                      formulario.usuarioId
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>

                <div className="perfil-field full">

                  <label>
                    Dirección
                  </label>

                  <textarea
                    name="direccion"
                    maxLength="255"
                    rows="3"
                    value={
                      formulario.direccion
                    }
                    onChange={
                      handleChange
                    }
                  />

                </div>

              </div>

              <div className="perfil-form-actions">

                <button
                  type="button"
                  className="perfil-cancel"
                  onClick={
                    cerrarModal
                  }
                >
                  Cancelar
                </button>

                <button
                  type="submit"
                  className="perfil-save"
                >
                  {editandoId !== null
                    ? "Guardar cambios"
                    : "Crear perfil"}
                </button>

              </div>

            </form>

          </div>

        </div>

      )}

    </div>
  );
}

export default Perfiles;