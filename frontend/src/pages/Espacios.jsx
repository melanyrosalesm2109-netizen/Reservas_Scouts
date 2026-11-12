import { useCallback, useEffect, useState } from "react";
import {
  Building2,
  Plus,
  Search,
  Pencil,
  Trash2,
  X,
  MapPin,
  Users,
  RotateCcw
} from "lucide-react";

import {
  listarEspacios,
  crearEspacio,
  actualizarEspacio,
  eliminarEspacio
} from "../services/espacioService";
import { useAuth } from "../context/useAuth";

import "./Espacios.css";

const espacioVacio = {
  nombre: "",
  descripcion: "",
  ubicacion: "",
  capacidad: "",
  costo: "",
  estado: "DISPONIBLE",
  imagen: ""
};

const filtrosVacios = {
  nombre: "",
  ubicacion: "",
  estado: "",
  capacidadMinima: "",
  costoMaximo: ""
};

const imagenesCatalogo = ["/images/espacios/campo-demo.png", "/images/espacios/sede-demo.png", "/images/espacios/centro-demo.png"];

function GaleriaEspacio({ espacio }) {
  const imagenes = [...new Set([espacio.imagen, ...imagenesCatalogo].filter(Boolean))];
  const [indice, setIndice] = useState(0);
  const [pausada, setPausada] = useState(false);
  useEffect(() => {
    if (pausada || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const timer = window.setInterval(() => setIndice(actual => (actual + 1) % imagenes.length), 6000);
    return () => window.clearInterval(timer);
  }, [pausada, imagenes.length]);
  return (
    <div className="espacio-card-cover" onMouseEnter={() => setPausada(true)} onMouseLeave={() => setPausada(false)} onFocus={() => setPausada(true)} onBlur={(event) => { if (!event.currentTarget.contains(event.relatedTarget)) setPausada(false); }}>
      <img src={imagenes[indice % imagenes.length]} alt={espacio.nombre} loading="lazy" onError={(event) => { if (!event.currentTarget.src.endsWith("/images/espacios/campo-demo.png")) event.currentTarget.src = "/images/espacios/campo-demo.png"; }} />
      <span className={"space-status " + espacio.estado?.toLowerCase()}>{espacio.estado}</span>
      <div className="espacio-gallery-controls">
        <button type="button" aria-label={"Imagen anterior de " + espacio.nombre} onClick={() => setIndice(actual => (actual - 1 + imagenes.length) % imagenes.length)}>‹</button>
        <span>{indice % imagenes.length + 1} / {imagenes.length}</span>
        <button type="button" aria-label={"Siguiente imagen de " + espacio.nombre} onClick={() => setIndice(actual => (actual + 1) % imagenes.length)}>›</button>
      </div>
    </div>
  );
}

function Espacios() {
  const { usuario } = useAuth();
  const puedeAdministrarEspacios = usuario?.rol === "Administrador";
  const [espacios, setEspacios] = useState([]);
  const [todosEspacios, setTodosEspacios] = useState([]);

  const [filtros, setFiltros] = useState(filtrosVacios);

  const [modalAbierto, setModalAbierto] = useState(false);
  const [editandoId, setEditandoId] = useState(null);

  const [formulario, setFormulario] = useState(espacioVacio);

  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(true);

  // =====================================================
  // CARGAR TODOS
  // =====================================================
  const cargarTodosLosEspacios = useCallback(async () => {
    try {
      setCargando(true);
      setError("");

      const datos = await listarEspacios();

      setEspacios(datos);
      setTodosEspacios(datos);
    } catch (err) {
      setError(err.message);
    } finally {
      setCargando(false);
    }
  }, []);

  // =====================================================
  // CARGAR ESPACIOS AL ABRIR LA PÁGINA
  // =====================================================
  useEffect(() => {
    queueMicrotask(() => {
      void cargarTodosLosEspacios();
    });
  }, [cargarTodosLosEspacios]);

  // =====================================================
  // CARGAR USANDO FILTROS DEL BACKEND
  // =====================================================
  const cargarEspaciosFiltrados = async (filtrosAplicados) => {
    try {
      setCargando(true);
      setError("");

      const datos = await listarEspacios(filtrosAplicados);

      setEspacios(datos);
    } catch (err) {
      setError(err.message);
    } finally {
      setCargando(false);
    }
  };

  // =====================================================
  // FILTROS
  // =====================================================
  const handleFiltroChange = (event) => {
    const { name, value } = event.target;

    setFiltros({
      ...filtros,
      [name]: value
    });
  };

  const aplicarFiltros = async (event) => {
    event.preventDefault();

    await cargarEspaciosFiltrados(filtros);
  };

  const limpiarFiltros = async () => {
    setFiltros(filtrosVacios);

    await cargarTodosLosEspacios();
  };

  // =====================================================
  // ABRIR NUEVO
  // =====================================================
  const abrirNuevo = () => {
    setEditandoId(null);
    setFormulario(espacioVacio);

    setError("");
    setMensaje("");

    setModalAbierto(true);
  };

  // =====================================================
  // ABRIR EDITAR
  // =====================================================
  const abrirEditar = (espacio) => {
    setEditandoId(espacio.id);

    setFormulario({
      nombre: espacio.nombre || "",
      descripcion: espacio.descripcion || "",
      ubicacion: espacio.ubicacion || "",
      capacidad: espacio.capacidad ?? "",
      costo: espacio.costo ?? "",
      estado: espacio.estado || "DISPONIBLE",
      imagen: espacio.imagen || ""
    });

    setError("");
    setMensaje("");

    setModalAbierto(true);
  };

  // =====================================================
  // CERRAR MODAL
  // =====================================================
  const cerrarModal = () => {
    setModalAbierto(false);
    setEditandoId(null);
    setFormulario(espacioVacio);
  };

  // =====================================================
  // CAMBIAR DATOS DEL FORMULARIO
  // =====================================================
  const handleChange = (event) => {
    const { name, value } = event.target;

    setFormulario({
      ...formulario,
      [name]: value
    });
  };

  // =====================================================
  // INSERTAR / ACTUALIZAR
  // =====================================================
  const guardarEspacio = async (event) => {
    event.preventDefault();

    try {
      setError("");
      setMensaje("");

      const datos = {
        nombre: formulario.nombre.trim(),

        descripcion:
          formulario.descripcion.trim() || null,

        ubicacion: formulario.ubicacion.trim(),

        capacidad: Number(formulario.capacidad),

        costo: Number(formulario.costo),

        estado: formulario.estado,

        imagen:
          formulario.imagen.trim() || null
      };

      if (editandoId !== null) {
        await actualizarEspacio(editandoId, datos);

        setMensaje(
          "Espacio actualizado correctamente."
        );
      } else {
        await crearEspacio(datos);

        setMensaje(
          "Espacio creado correctamente."
        );
      }

      cerrarModal();

      // Refresca todos los datos reales de SQL Server
      await cargarTodosLosEspacios();

      // Limpia filtros después de crear/actualizar
      setFiltros(filtrosVacios);
    } catch (err) {
      setError(err.message);
    }
  };

  // =====================================================
  // ELIMINAR
  // =====================================================
  const borrarEspacio = async (espacio) => {
    const confirmar = window.confirm(
      `¿Deseas eliminar el espacio "${espacio.nombre}"?`
    );

    if (!confirmar) {
      return;
    }

    try {
      setError("");
      setMensaje("");

      await eliminarEspacio(espacio.id);

      setMensaje(
        "Espacio eliminado correctamente."
      );

      setFiltros(filtrosVacios);

      await cargarTodosLosEspacios();
    } catch (err) {
      setError(err.message);
    }
  };

  // =====================================================
  // ESTADÍSTICAS
  // =====================================================
  const disponibles = todosEspacios.filter(
    (espacio) =>
      espacio.estado === "DISPONIBLE"
  ).length;

  const mantenimiento = todosEspacios.filter(
    (espacio) =>
      espacio.estado === "MANTENIMIENTO"
  ).length;

  // =====================================================
  // INTERFAZ
  // =====================================================
  return (
    <div className="espacios-page">

      {/* CABECERA */}
      <div className="espacios-header">

        <div>
          <span className="espacios-label">
            GESTIÓN DE ESPACIOS
          </span>

          <h1>Espacios</h1>

          <p>
            {puedeAdministrarEspacios ? "Administra los espacios disponibles para las reservas." : "Explora los espacios disponibles para tus actividades."}
          </p>
        </div>

        {puedeAdministrarEspacios && <button
          className="espacios-add-button"
          onClick={abrirNuevo}
        >
          <Plus size={18} />
          Nuevo espacio
        </button>}

      </div>

      {/* MENSAJE CORRECTO */}
      {mensaje && (
        <div className="mensaje-exito">
          {mensaje}
        </div>
      )}

      {/* MENSAJE ERROR */}
      {error && (
        <div className="mensaje-error">
          {error}
        </div>
      )}

      {/* ESTADÍSTICAS */}
      <div className="espacios-stats">

        <div className="espacio-stat">

          <div className="espacio-stat-icon blue">
            <Building2 size={22} />
          </div>

          <div>
            <span>Total de espacios</span>

            <strong>
              {todosEspacios.length}
            </strong>
          </div>

        </div>

        <div className="espacio-stat">

          <div className="espacio-stat-icon green">
            <Building2 size={22} />
          </div>

          <div>
            <span>Disponibles</span>

            <strong>
              {disponibles}
            </strong>
          </div>

        </div>

        <div className="espacio-stat">

          <div className="espacio-stat-icon gold">
            <Building2 size={22} />
          </div>

          <div>
            <span>En mantenimiento</span>

            <strong>
              {mantenimiento}
            </strong>
          </div>

        </div>

      </div>

      {/* PANEL */}
      <section className="espacios-panel">

        {/* FILTROS REALES */}
        <form
          className="espacios-filtros-reales"
          onSubmit={aplicarFiltros}
        >

          <div className="espacios-search-real">

            <Search size={18} />

            <input
              type="text"
              name="nombre"
              placeholder="Nombre del espacio..."
              value={filtros.nombre}
              onChange={handleFiltroChange}
            />

          </div>

          <input
            type="text"
            name="ubicacion"
            placeholder="Ubicación..."
            value={filtros.ubicacion}
            onChange={handleFiltroChange}
          />

          <select
            name="estado"
            value={filtros.estado}
            onChange={handleFiltroChange}
          >

            <option value="">
              Todos los estados
            </option>

            <option value="DISPONIBLE">
              Disponible
            </option>

            <option value="MANTENIMIENTO">
              Mantenimiento
            </option>

            <option value="INACTIVO">
              Inactivo
            </option>

          </select>

          <input
            type="number"
            name="capacidadMinima"
            min="1"
            placeholder="Capacidad mínima"
            value={filtros.capacidadMinima}
            onChange={handleFiltroChange}
          />

          <input
            type="number"
            name="costoMaximo"
            min="0"
            step="0.01"
            placeholder="Costo máximo"
            value={filtros.costoMaximo}
            onChange={handleFiltroChange}
          />

          <button
            type="submit"
            className="espacios-filter-button"
          >
            Buscar
          </button>

          <button
            type="button"
            className="espacios-clear-button"
            onClick={limpiarFiltros}
            title="Limpiar filtros"
          >
            <RotateCcw size={16} />
            Limpiar
          </button>

        </form>

        {/* CANTIDAD DE RESULTADOS */}
        <div className="espacios-results-info">
          Mostrando {espacios.length} espacio(s)
        </div>

        <div className="espacios-catalogo" aria-live="polite" aria-busy={cargando}>
          {cargando ? <p className="espacios-empty">Cargando espacios...</p> : espacios.length === 0 ? (
            <div className="espacios-empty"><Building2 size={35} /><strong>No se encontraron espacios</strong><span>Puedes cambiar los filtros o crear un nuevo espacio.</span></div>
          ) : espacios.map((espacio) => {
            const esDemo = espacio.descripcion?.includes("Datos de demostración");
            const tipo = esDemo ? espacio.descripcion.split(". ")[0] : "Espacio Scout";
            return (
              <article className="espacio-card" key={espacio.id}>
                <GaleriaEspacio key={espacio.imagen} espacio={espacio} />
                <div className="espacio-card-body">
                  <span className="espacio-card-type">{tipo}</span>
                  <h2>{espacio.nombre}</h2>
                  <p className="espacio-card-location"><MapPin size={15} />{espacio.ubicacion}</p>
                  <p className="espacio-card-capacity"><Users size={16} />Hasta {espacio.capacidad} personas</p>
                  <div className="espacio-card-footer">
                    <div><span>Costo</span><strong>{Number(espacio.costo).toLocaleString("es-CR", { style: "currency", currency: "CRC", maximumFractionDigits: 0 })}</strong></div>
                    {puedeAdministrarEspacios ? <div className="space-actions">
                      <button type="button" className="space-edit" onClick={() => abrirEditar(espacio)} aria-label={"Editar " + espacio.nombre} title="Editar espacio"><Pencil size={16} /></button>
                      <button type="button" className="space-delete" onClick={() => borrarEspacio(espacio)} aria-label={"Eliminar " + espacio.nombre} title="Eliminar espacio"><Trash2 size={16} /></button>
                    </div> : <span className="espacio-readonly">Solo lectura</span>}
                  </div>
                </div>
              </article>
            );
          })}
        </div>

      </section>

      {/* MODAL CREAR / EDITAR */}
      {modalAbierto && (

        <div className="espacio-modal-overlay">

          <div className="espacio-modal">

            {/* CABECERA MODAL */}
            <div className="espacio-modal-header">

              <div>

                <span>
                  RESERVAS SCOUTS
                </span>

                <h2>
                  {editandoId !== null
                    ? "Editar espacio"
                    : "Nuevo espacio"}
                </h2>

                <p>
                  Complete la información del espacio.
                </p>

              </div>

              <button
                type="button"
                onClick={cerrarModal}
              >
                <X size={21} />
              </button>

            </div>

            {/* FORMULARIO */}
            <form
              className="espacio-form"
              onSubmit={guardarEspacio}
            >

              <div className="espacio-form-grid">

                {/* NOMBRE */}
                <div className="espacio-field">

                  <label>
                    Nombre *
                  </label>

                  <input
                    type="text"
                    name="nombre"
                    maxLength="120"
                    required
                    value={formulario.nombre}
                    onChange={handleChange}
                    placeholder="Ej: Salón Principal"
                  />

                </div>

                {/* UBICACIÓN */}
                <div className="espacio-field">

                  <label>
                    Ubicación *
                  </label>

                  <input
                    type="text"
                    name="ubicacion"
                    maxLength="160"
                    required
                    value={formulario.ubicacion}
                    onChange={handleChange}
                    placeholder="Ej: Liberia"
                  />

                </div>

                {/* CAPACIDAD */}
                <div className="espacio-field">

                  <label>
                    Capacidad *
                  </label>

                  <input
                    type="number"
                    name="capacidad"
                    min="1"
                    required
                    value={formulario.capacidad}
                    onChange={handleChange}
                    placeholder="Ej: 100"
                  />

                </div>

                {/* COSTO */}
                <div className="espacio-field">

                  <label>
                    Costo *
                  </label>

                  <input
                    type="number"
                    name="costo"
                    min="0"
                    step="0.01"
                    required
                    value={formulario.costo}
                    onChange={handleChange}
                    placeholder="Ej: 50000"
                  />

                </div>

                {/* ESTADO */}
                <div className="espacio-field">

                  <label>
                    Estado *
                  </label>

                  <select
                    name="estado"
                    value={formulario.estado}
                    onChange={handleChange}
                  >

                    <option value="DISPONIBLE">
                      Disponible
                    </option>

                    <option value="MANTENIMIENTO">
                      Mantenimiento
                    </option>

                    <option value="INACTIVO">
                      Inactivo
                    </option>

                  </select>

                </div>

                {/* IMAGEN */}
                <div className="espacio-field">

                  <label>
                    Imagen / URL
                  </label>

                  <input
                    type="text"
                    name="imagen"
                    maxLength="255"
                    value={formulario.imagen}
                    onChange={handleChange}
                    placeholder="URL de la imagen"
                  />

                </div>

                {/* DESCRIPCIÓN */}
                <div className="espacio-field full">

                  <label>
                    Descripción
                  </label>

                  <textarea
                    name="descripcion"
                    rows="4"
                    value={formulario.descripcion}
                    onChange={handleChange}
                    placeholder="Descripción del espacio..."
                  />

                </div>

              </div>

              {/* BOTONES */}
              <div className="espacio-form-actions">

                <button
                  type="button"
                  className="space-cancel"
                  onClick={cerrarModal}
                >
                  Cancelar
                </button>

                <button
                  type="submit"
                  className="space-save"
                >
                  {editandoId !== null
                    ? "Guardar cambios"
                    : "Crear espacio"}
                </button>

              </div>

            </form>

          </div>

        </div>

      )}

    </div>
  );
}

export default Espacios;