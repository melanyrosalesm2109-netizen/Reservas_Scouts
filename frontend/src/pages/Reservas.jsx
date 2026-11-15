import { useCallback, useEffect, useRef, useState } from "react";



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



} from "lucide-react";



import {

  listarReservas,

  buscarReservaPorId,


  actualizarReserva,

  eliminarReserva,


  listarFechasOcupadas

} from "../services/reservaService";



import {

  listarEspacios

} from "../services/espacioService";



import {

  completarPerfilPropio,
  listarPerfilesParaReserva

} from "../services/perfilService";



import { useAuth } from "../context/useAuth";



import "./Reservas.css";
import { useSearchParams } from "react-router-dom";
import CalendarioDisponibilidad from "../components/CalendarioDisponibilidad";
import PagoReserva from "../components/PagoReserva";
import { confirmarReserva } from "../services/reservaPagoService";





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





function datosSolicitante(perfil, usuario) {
  return {
    solicitantePerfilId: perfil?.idPerfil || "",
    responsable: perfil?.tipoPerfil === "Persona" ? perfil.nombre : "",
    grupo: perfil && perfil.tipoPerfil !== "Persona" ? perfil.nombre : "",
    telefono: perfil?.telefono || "",
    email: perfil?.correoContacto || (!perfil || Number(perfil.usuarioId) === Number(usuario?.id) ? usuario?.email : "") || ""
  };
}

function perfilDelUsuario(perfiles, usuario, esUsuarioFinal) {
  return perfiles.find(perfil => perfil.usuarioId != null && Number(perfil.usuarioId) === Number(usuario?.id))
    || (esUsuarioFinal ? perfiles.find(p => p.tipoPerfil === "Persona") || perfiles[0] : null);
}

function Reservas() {
  const [searchParams] = useSearchParams();
  const espacioEnlace = searchParams.get("espacioId") || "";
  const codigoEnlace = searchParams.get("codigo") || "";
  const nuevaEnlace = searchParams.get("nueva") === "1";
  const enlaceProcesado = useRef("");



  const { usuario } = useAuth();
  const [pagoReserva, setPagoReserva] = useState(null);
  const [guardando, setGuardando] = useState(false);



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



  const [
    fechasOcupadas,
    setFechasOcupadas
  ] = useState([]);



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



  const cargarInicial = useCallback(async () => {



    try {



      setCargando(true);

      setError("");



      const [

        reservasData,

        espaciosData,

        perfilesData,

        fechasOcupadasData

      ] = await Promise.all([

        listarReservas({ espacioId: espacioEnlace, codigo: codigoEnlace }),

        listarEspacios(),

        listarPerfilesParaReserva(),

        listarFechasOcupadas()

      ]);



      setReservas(reservasData);

      setTodasReservas(reservasData);

      setEspacios(espaciosData);

      setPerfiles(perfilesData);

      setFechasOcupadas(fechasOcupadasData);
      const claveEnlace = espacioEnlace + ":" + nuevaEnlace + ":" + codigoEnlace;
      if (enlaceProcesado.current !== claveEnlace) {
        enlaceProcesado.current = claveEnlace;
        setFiltros({ ...filtrosVacios, espacioId: espacioEnlace, codigo: codigoEnlace });
        const seleccionado = espaciosData.find(e => String(e.id) === espacioEnlace);
        if (nuevaEnlace && seleccionado?.estado === "DISPONIBLE") {
          setEditandoId(null);
          setFormulario({ ...reservaVacia, codigo: "RES-" + Date.now(), espacioId: seleccionado.id,
            ...datosSolicitante(perfilDelUsuario(perfilesData, usuario, esUsuarioFinal), usuario) });
          setModalAbierto(true);
        }
      }



    } catch (err) {



      setError(

        err.message ||

        "No se pudieron cargar los datos."

      );



    } finally {



      setCargando(false);

    }



  }, [esUsuarioFinal, espacioEnlace, nuevaEnlace, usuario, codigoEnlace]);





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



  const generarCodigoReserva = () => {



    return `RES-${Date.now()}`;

  };





  const abrirNueva = (

    espacio = null

  ) => {



    setEditandoId(null);



    const perfilPorDefecto = perfilDelUsuario(perfiles, usuario, esUsuarioFinal);



    setFormulario({

      ...reservaVacia,



      codigo:

        esUsuarioFinal

          ? generarCodigoReserva()

          : "",



      espacioId:

        espacio?.id || espacioEnlace || "",



      ...datosSolicitante(perfilPorDefecto, usuario),



      fechaInicio: "",



      fechaFin: "",



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

          formulario.creadoPorUsuarioId ?? null,



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



    if (name === "solicitantePerfilId") {
      const perfil = perfiles.find(p => Number(p.idPerfil) === Number(value));
      setFormulario(anterior => ({ ...anterior, ...datosSolicitante(perfil, usuario) }));
      return;
    }
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



  const inicioDiaSeleccionado = formulario.fechaInicio
    ? new Date(formulario.fechaInicio.slice(0, 10) + "T00:00") : null;
  const finDiaSeleccionado = formulario.fechaFin
    ? new Date(formulario.fechaFin.slice(0, 10) + "T00:00")
    : inicioDiaSeleccionado && new Date(inicioDiaSeleccionado);
  if (finDiaSeleccionado) {
    if (!formulario.fechaFin || formulario.fechaFin.slice(11, 16) !== "00:00") {
      finDiaSeleccionado.setDate(finDiaSeleccionado.getDate() + 1);
    }
  }
  const diaOcupado = editandoId === null && inicioDiaSeleccionado && finDiaSeleccionado &&
    fechasOcupadas.some(reserva => Number(reserva.espacioId) === Number(formulario.espacioId) &&
      new Date(reserva.fechaInicio) < finDiaSeleccionado && new Date(reserva.fechaFin) > inicioDiaSeleccionado);
  const fechaActual = new Intl.DateTimeFormat("sv-SE", { timeZone: "America/Costa_Rica" }).format(new Date());
  const fechaAnterior = Boolean(
    (formulario.fechaInicio && formulario.fechaInicio.slice(0, 10) < fechaActual) ||
    (formulario.fechaFin && formulario.fechaFin.slice(0, 10) < fechaActual)
  );
  const formularioBloqueado = Boolean(fechaAnterior || diaOcupado ||
    (espacioSeleccionado && espacioSeleccionado.estado !== "DISPONIBLE"));

  const guardarReserva = async (

    event

  ) => {



    event.preventDefault();
    if (guardando) return;
    if (editandoId === null && (!pagoReserva?.valido || pagoReserva.rango !== (formulario.espacioId + "|" + formulario.fechaInicio + "|" + formulario.fechaFin))) {
      setError("Selecciona un horario disponible y completa el pago antes de que termine el plazo.");
      return;
    }

    if (formularioBloqueado) {
      setError("Este espacio no est? disponible en las fechas seleccionadas. Selecciona un d?a libre en el calendario.");
      return;
    }



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





    if (!formulario.solicitantePerfilId && !esUsuarioFinal) {



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





    setGuardando(true);
    try {



      let solicitanteId = formulario.solicitantePerfilId;
      if (esUsuarioFinal && !solicitanteId) {
        const perfil = await completarPerfilPropio({ nombre: formulario.responsable.trim(),
          telefono: formulario.telefono.trim(), correoContacto: formulario.email.trim(), tipoPerfil: "Persona" });
        solicitanteId = perfil.idPerfil;
        setPerfiles(anteriores => [...anteriores.filter(p => p.idPerfil !== perfil.idPerfil), perfil]);
        setFormulario(anterior => ({ ...anterior, solicitantePerfilId: perfil.idPerfil }));
      }
      const datos = {



        codigo:

          formulario.codigo.trim(),



        espacioId:

          Number(

            formulario.espacioId

          ),



        solicitantePerfilId:

          Number(solicitanteId),
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



        await confirmarReserva(datos, pagoReserva);



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



      await cargarInicial();



    } catch (err) {



      setMensaje("");



      setError(

        err.message ||

        "No se pudo realizar la operación."

      );

    } finally {
      setGuardando(false);
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



        {(puedeGestionarReservas || esUsuarioFinal) && (
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



              {error && <div className="mensaje-error" role="alert">{error}</div>}
              <CalendarioDisponibilidad
                key={formulario.espacioId}
                espacio={espacioSeleccionado}
                fechaInicio={formulario.fechaInicio}
                onSeleccionar={(fecha) => setFormulario(anterior => ({
                  ...anterior,
                  fechaInicio: fecha + "T" + (anterior.fechaInicio.slice(11, 16) || "08:00"),
                  fechaFin: fecha + "T" + (anterior.fechaFin.slice(11, 16) || "17:00")
                }))}
              />
              {formularioBloqueado && <div className="reserva-bloqueada" role="status">
                {fechaAnterior ? "Solo se permiten reservas desde la fecha actual en adelante." : "Espacio no disponible"}
              </div>}
              <fieldset className="reservation-fields" disabled={formularioBloqueado || guardando}>
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



                  {esUsuarioFinal ? (
                    <div className="reserva-solicitante-propio">
                      <strong>{perfilSeleccionado?.nombre || "Tu reserva personal"}</strong>
                      <p>{perfilSeleccionado ? "La reserva quedará a tu nombre." : "Completa tu nombre y contacto. Se guardarán en tu perfil para próximas reservas."}</p>
                    </div>
                  ) : (
                    <select name="solicitantePerfilId" required value={formulario.solicitantePerfilId} onChange={handleChange}>
                      <option value="">Seleccione la persona, grupo o institución</option>
                      {perfiles.map(perfil => <option key={perfil.idPerfil} value={perfil.idPerfil}>{perfil.nombre} - {perfil.tipoPerfil}</option>)}
                    </select>
                  )}
                </div>





                <div className="reservation-field">



                  <label>

                    {perfilSeleccionado?.tipoPerfil === "Persona" || (esUsuarioFinal && !perfilSeleccionado) ? "Nombre completo *" : "Persona responsable de la actividad *"}
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





                {(perfilSeleccionado && perfilSeleccionado.tipoPerfil !== "Persona") && (
                <div className="reservation-field">



                  <label>

                    {perfilSeleccionado.tipoPerfil === "Institucion" ? "Institución" : "Grupo Scout"}
                  </label>



                  <input

                    name="grupo"
                    readOnly

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





                )}
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





              </fieldset>
              {editandoId === null && <PagoReserva
                espacio={espacioSeleccionado} inicio={formulario.fechaInicio} fin={formulario.fechaFin}
                disponible={!formularioBloqueado} procesando={guardando} onCambio={setPagoReserva}
              />}
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
                  disabled={formularioBloqueado || guardando || (editandoId === null && !pagoReserva?.valido)}

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
