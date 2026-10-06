import { useCallback, useEffect, useState } from "react";

import {
  Plus,
  Search,
  Pencil,
  Trash2,
  X,
  RotateCcw,
  ShieldCheck,
  UserRound,
  UsersRound,
  UserCheck,
  UserX,
  Mail,
  KeyRound
} from "lucide-react";

import {
  listarUsuarios,
  listarRoles,
  buscarUsuarioPorId,
  crearUsuario,
  actualizarUsuario,
  eliminarUsuario
} from "../services/usuarioService";

import "./Usuarios.css";


const usuarioVacio = {
  rolId: "",
  email: "",
  password: "",
  estado: "ACTIVO"
};


const filtrosVacios = {
  email: "",
  rolId: "",
  estado: ""
};


function Usuarios() {

  const [usuarios, setUsuarios] =
    useState([]);

  const [todosUsuarios, setTodosUsuarios] =
    useState([]);

  const [roles, setRoles] =
    useState([]);

  const [filtros, setFiltros] =
    useState(filtrosVacios);

  const [formulario, setFormulario] =
    useState(usuarioVacio);

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
  // CARGAR DATOS
  // =====================================================

  const cargarInicial = useCallback(async () => {

    try {

      setCargando(true);
      setError("");

      const [
        usuariosData,
        rolesData
      ] = await Promise.all([
        listarUsuarios(),
        listarRoles()
      ]);

      setUsuarios(
        usuariosData
      );

      setTodosUsuarios(
        usuariosData
      );

      setRoles(
        rolesData
      );

    } catch (err) {

      setError(
        err.message
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
  // FILTROS
  // =====================================================

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
        await listarUsuarios(
          filtros
        );

      setUsuarios(
        datos
      );

    } catch (err) {

      setError(
        err.message
      );

    } finally {

      setCargando(false);
    }
  };


  const limpiarFiltros = async () => {

    setFiltros(
      filtrosVacios
    );

    try {

      setCargando(true);

      const datos =
        await listarUsuarios();

      setUsuarios(
        datos
      );

    } catch (err) {

      setError(
        err.message
      );

    } finally {

      setCargando(false);
    }
  };


  // =====================================================
  // NUEVO USUARIO
  // =====================================================

  const abrirNuevo = () => {

    setEditandoId(null);

    setFormulario(
      usuarioVacio
    );

    setError("");
    setMensaje("");

    setModalAbierto(true);
  };


  // =====================================================
  // EDITAR
  // =====================================================

  const abrirEditar = async (
    usuario
  ) => {

    try {

      setError("");
      setMensaje("");

      const detalle =
        await buscarUsuarioPorId(
          usuario.id
        );

      setEditandoId(
        detalle.id
      );

      setFormulario({

        rolId:
          detalle.rolId || "",

        email:
          detalle.email || "",

        // Al editar NO mostramos
        // ni recuperamos el password hash.
        password: "",

        estado:
          detalle.estado ||
          "ACTIVO"
      });

      setModalAbierto(true);

    } catch (err) {

      setError(
        err.message
      );
    }
  };


  // =====================================================
  // CERRAR MODAL
  // =====================================================

  const cerrarModal = () => {

    setModalAbierto(false);

    setEditandoId(null);

    setFormulario(
      usuarioVacio
    );
  };


  // =====================================================
  // FORMULARIO
  // =====================================================

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


  // =====================================================
  // GUARDAR
  // =====================================================

  const guardarUsuario = async (
    event
  ) => {

    event.preventDefault();

    setError("");
    setMensaje("");


    // ---------------------------
    // VALIDACIONES FRONTEND
    // ---------------------------

    if (!formulario.rolId) {

      setError(
        "Debe seleccionar un rol."
      );

      return;
    }


    if (!formulario.email.trim()) {

      setError(
        "El correo es obligatorio."
      );

      return;
    }


    if (
      !formulario.email.includes("@")
    ) {

      setError(
        "Debe ingresar un correo válido."
      );

      return;
    }


    // Contraseña obligatoria
    // solamente cuando creamos.
    if (
      editandoId === null &&
      !formulario.password
    ) {

      setError(
        "La contraseña es obligatoria."
      );

      return;
    }


    if (
      formulario.password &&
      formulario.password.length < 6
    ) {

      setError(
        "La contraseña debe tener al menos 6 caracteres."
      );

      return;
    }


    const datos = {

      rolId:
        Number(
          formulario.rolId
        ),

      email:
        formulario.email
          .trim(),

      password:
        formulario.password ||
        null,

      estado:
        formulario.estado
    };


    try {

      // ---------------------------
      // ACTUALIZAR
      // ---------------------------

      if (editandoId !== null) {

        await actualizarUsuario(
          editandoId,
          datos
        );

        cerrarModal();

        setMensaje(
          "Usuario actualizado correctamente."
        );

      }

      // ---------------------------
      // INSERTAR
      // ---------------------------

      else {

        await crearUsuario(
          datos
        );

        cerrarModal();

        setMensaje(
          "Usuario creado correctamente."
        );
      }


      setFiltros(
        filtrosVacios
      );

      await cargarInicial();


    } catch (err) {

      // Igual que Reservas:
      // si SQL Server rechaza algo,
      // cerramos modal y mostramos
      // claramente el mensaje.

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

  const borrarUsuario = async (
    usuario
  ) => {

    const confirmar =
      window.confirm(
        `¿Deseas eliminar el usuario "${usuario.email}"?`
      );

    if (!confirmar) {
      return;
    }


    try {

      setError("");
      setMensaje("");

      await eliminarUsuario(
        usuario.id
      );

      setMensaje(
        "Usuario eliminado correctamente."
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

  const activos =
    todosUsuarios.filter(
      (usuario) =>
        usuario.estado ===
        "ACTIVO"
    ).length;


  const inactivos =
    todosUsuarios.filter(
      (usuario) =>
        usuario.estado ===
        "INACTIVO"
    ).length;


  const administradores =
    todosUsuarios.filter(
      (usuario) =>
        usuario.rol
          ?.toLowerCase()
          .includes(
            "administrador"
          )
    ).length;


  // =====================================================
  // INTERFAZ
  // =====================================================

  return (

    <div className="usuarios-page">

      {/* CABECERA */}

      <div className="usuarios-header">

        <div>

          <span className="usuarios-label">
            GESTIÓN DE USUARIOS
          </span>

          <h1>
            Usuarios
          </h1>

          <p>
            Administra las cuentas y
            accesos al sistema.
          </p>

        </div>

        <button
          type="button"
          className="usuarios-add-button"
          onClick={abrirNuevo}
        >
          <Plus size={18} />

          Nuevo usuario
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

      <div className="usuarios-stats">

        <div className="usuario-stat">

          <UsersRound size={22} />

          <div>

            <span>
              Total de usuarios
            </span>

            <strong>
              {todosUsuarios.length}
            </strong>

          </div>

        </div>


        <div className="usuario-stat usuario-activo">

          <UserCheck size={22} />

          <div>

            <span>
              Activos
            </span>

            <strong>
              {activos}
            </strong>

          </div>

        </div>


        <div className="usuario-stat usuario-inactivo">

          <UserX size={22} />

          <div>

            <span>
              Inactivos
            </span>

            <strong>
              {inactivos}
            </strong>

          </div>

        </div>


        <div className="usuario-stat usuario-admin">

          <ShieldCheck size={22} />

          <div>

            <span>
              Administradores
            </span>

            <strong>
              {administradores}
            </strong>

          </div>

        </div>

      </div>


      {/* PANEL */}

      <section className="usuarios-panel">


        {/* FILTROS */}

        <form
          className="usuarios-filtros"
          onSubmit={aplicarFiltros}
        >

          <div className="usuarios-search">

            <Search size={17} />

            <input
              name="email"
              placeholder="Buscar por correo..."
              value={
                filtros.email
              }
              onChange={
                handleFiltroChange
              }
            />

          </div>


          <select
            name="rolId"
            value={
              filtros.rolId
            }
            onChange={
              handleFiltroChange
            }
          >

            <option value="">
              Todos los roles
            </option>

            {roles.map(
              (rol) => (

                <option
                  key={rol.id}
                  value={rol.id}
                >
                  {rol.nombre}
                </option>

              )
            )}

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

            <option value="ACTIVO">
              Activo
            </option>

            <option value="INACTIVO">
              Inactivo
            </option>

          </select>


          <button
            type="submit"
            className="usuarios-filter-button"
          >
            Buscar
          </button>


          <button
            type="button"
            className="usuarios-clear-button"
            onClick={
              limpiarFiltros
            }
          >

            <RotateCcw size={16} />

            Limpiar

          </button>

        </form>


        <div className="usuarios-resultados">

          Mostrando {usuarios.length} usuario(s)

        </div>


        {/* TABLA */}

        <div className="usuarios-table-wrapper">

          <table className="usuarios-table">

            <thead>

              <tr>

                <th>
                  Usuario
                </th>

                <th>
                  Rol
                </th>

                <th>
                  Estado
                </th>

                <th>
                  Fecha de creación
                </th>

                <th>
                  Acciones
                </th>

              </tr>

            </thead>


            <tbody>

              {cargando ? (

                <tr>

                  <td
                    colSpan="5"
                    className="usuarios-empty"
                  >
                    Cargando usuarios...
                  </td>

                </tr>

              ) : usuarios.length === 0 ? (

                <tr>

                  <td
                    colSpan="5"
                    className="usuarios-empty"
                  >

                    <UserRound size={38} />

                    <strong>
                      No hay usuarios registrados
                    </strong>

                    <span>
                      Crea el primer usuario
                      usando el botón superior.
                    </span>

                  </td>

                </tr>

              ) : (

                usuarios.map(
                  (usuario) => (

                    <tr
                      key={usuario.id}
                    >

                      {/* USUARIO */}

                      <td>

                        <div className="usuario-info">

                          <div className="usuario-avatar">

                            {usuario.email
                              ?.charAt(0)
                              .toUpperCase()}

                          </div>

                          <div>

                            <strong>
                              {usuario.email}
                            </strong>

                            <span>
                              ID #{usuario.id}
                            </span>

                          </div>

                        </div>

                      </td>


                      {/* ROL */}

                      <td>

                        <div className="usuario-role">

                          <ShieldCheck
                            size={15}
                          />

                          {usuario.rol}

                        </div>

                      </td>


                      {/* ESTADO */}

                      <td>

                        <span
                          className={`usuario-status ${
                            usuario.estado ===
                            "ACTIVO"
                              ? "activo"
                              : "inactivo"
                          }`}
                        >
                          {usuario.estado}
                        </span>

                      </td>


                      {/* FECHA */}

                      <td>

                        {usuario.createdAt
                          ? new Date(
                              usuario.createdAt
                            ).toLocaleDateString(
                              "es-CR"
                            )
                          : "-"}

                      </td>


                      {/* ACCIONES */}

                      <td>

                        <div className="usuario-actions">

                          <button
                            type="button"
                            className="usuario-edit"
                            title="Editar usuario"
                            onClick={() =>
                              abrirEditar(
                                usuario
                              )
                            }
                          >

                            <Pencil
                              size={16}
                            />

                          </button>


                          <button
                            type="button"
                            className="usuario-delete"
                            title="Eliminar usuario"
                            onClick={() =>
                              borrarUsuario(
                                usuario
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


      {/* =================================================
          MODAL
      ================================================= */}

      {modalAbierto && (

        <div className="usuario-modal-overlay">

          <div className="usuario-modal">


            {/* CABECERA */}

            <div className="usuario-modal-header">

              <div>

                <span>
                  RESERVAS SCOUTS
                </span>

                <h2>

                  {editandoId !== null
                    ? "Editar usuario"
                    : "Nuevo usuario"}

                </h2>

                <p>

                  Administra el acceso
                  del usuario al sistema.

                </p>

              </div>


              <button
                type="button"
                className="usuario-modal-close"
                onClick={cerrarModal}
              >

                <X size={21} />

              </button>

            </div>


            {/* FORMULARIO */}

            <form
              className="usuario-form"
              onSubmit={
                guardarUsuario
              }
            >


              <div className="usuario-form-grid">


                {/* EMAIL */}

                <div className="usuario-field usuario-full">

                  <label>
                    Correo electrónico *
                  </label>

                  <div className="usuario-input-icon">

                    <Mail size={17} />

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
                      placeholder="usuario@correo.com"
                    />

                  </div>

                </div>


                {/* ROL */}

                <div className="usuario-field">

                  <label>
                    Rol *
                  </label>

                  <select
                    name="rolId"
                    required
                    value={
                      formulario.rolId
                    }
                    onChange={
                      handleChange
                    }
                  >

                    <option value="">
                      Seleccione un rol
                    </option>

                    {roles.map(
                      (rol) => (

                        <option
                          key={rol.id}
                          value={rol.id}
                        >
                          {rol.nombre}
                        </option>

                      )
                    )}

                  </select>

                </div>


                {/* ESTADO */}

                <div className="usuario-field">

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

                    <option value="ACTIVO">
                      Activo
                    </option>

                    <option value="INACTIVO">
                      Inactivo
                    </option>

                  </select>

                </div>


                {/* CONTRASEÑA */}

                <div className="usuario-field usuario-full">

                  <label>

                    {editandoId !== null
                      ? "Nueva contraseña"
                      : "Contraseña *"}

                  </label>


                  <div className="usuario-input-icon">

                    <KeyRound size={17} />

                    <input
                      type="password"
                      name="password"
                      minLength="6"
                      maxLength="100"

                      required={
                        editandoId === null
                      }

                      value={
                        formulario.password
                      }

                      onChange={
                        handleChange
                      }

                      placeholder={
                        editandoId !== null
                          ? "Déjela vacía para conservar la contraseña actual"
                          : "Mínimo 6 caracteres"
                      }
                    />

                  </div>


                  {editandoId !== null && (

                    <small className="password-help">

                      Si no deseas cambiar
                      la contraseña, deja
                      este campo vacío.

                    </small>

                  )}

                </div>

              </div>


              {/* BOTONES */}

              <div className="usuario-form-actions">

                <button
                  type="button"
                  className="usuario-cancel"
                  onClick={cerrarModal}
                >
                  Cancelar
                </button>


                <button
                  type="submit"
                  className="usuario-save"
                >

                  {editandoId !== null
                    ? "Guardar cambios"
                    : "Crear usuario"}

                </button>

              </div>

            </form>

          </div>

        </div>

      )}

    </div>
  );
}


export default Usuarios;