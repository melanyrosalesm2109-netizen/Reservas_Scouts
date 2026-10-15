import { useEffect, useState } from "react";
import { AlertTriangle, HardDrive, RefreshCw } from "lucide-react";
import {
  crearRespaldo,
  listarRespaldos,
  restaurarRespaldo
} from "../services/respaldoService";
import "./Respaldos.css";

const CONFIRMACION_RESTAURAR = "RESTAURAR reservasScouts";

function Respaldos() {
  const [respaldos, setRespaldos] = useState([]);
  const [seleccionado, setSeleccionado] = useState("");
  const [confirmacion, setConfirmacion] = useState("");
  const [cargando, setCargando] = useState(true);
  const [operando, setOperando] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  const cargarRespaldos = async () => {
    setCargando(true);
    setError("");
    try {
      const datos = await listarRespaldos();
      setRespaldos(datos);
      setSeleccionado((actual) =>
        datos.some((respaldo) => respaldo.nombre === actual)
          ? actual
          : datos[0]?.nombre || ""
      );
    } catch (err) {
      setError(err.message || "No se pudo cargar la lista de respaldos.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    let vigente = true;
    listarRespaldos()
      .then((datos) => {
        if (vigente) {
          setRespaldos(datos);
          setSeleccionado(datos[0]?.nombre || "");
        }
      })
      .catch((err) => {
        if (vigente) {
          setError(err.message || "No se pudo cargar la lista de respaldos.");
        }
      })
      .finally(() => {
        if (vigente) {
          setCargando(false);
        }
      });
    return () => {
      vigente = false;
    };
  }, []);

  const handleCrear = async () => {
    setOperando(true);
    setMensaje("");
    setError("");
    try {
      const nuevo = await crearRespaldo();
      setMensaje(`Respaldo creado y verificado: ${nuevo.nombre}`);
      const actualizados = await listarRespaldos();
      setRespaldos(actualizados);
      setSeleccionado(nuevo.nombre);
    } catch (err) {
      setError(err.message || "No se pudo crear el respaldo.");
    } finally {
      setOperando(false);
    }
  };

  const handleRestaurar = async () => {
    if (!seleccionado || confirmacion !== CONFIRMACION_RESTAURAR) {
      return;
    }
    if (!window.confirm(`Se reemplazarán los datos actuales de reservasScouts con "${seleccionado}". ¿Continuar?`)) {
      return;
    }

    setOperando(true);
    setMensaje("");
    setError("");
    try {
      const resultado = await restaurarRespaldo(seleccionado, confirmacion);
      setMensaje(resultado.mensaje);
      setConfirmacion("");
      const actualizados = await listarRespaldos();
      setRespaldos(actualizados);
    } catch (err) {
      setError(err.message || "No se pudo restaurar el respaldo.");
    } finally {
      setOperando(false);
    }
  };

  return (
    <section className="backup-page">
      <header className="backup-heading">
        <div>
          <span>ADMINISTRACIÓN</span>
          <h1><HardDrive size={25} /> Respaldos</h1>
          <p>Las copias se guardan en la carpeta configurada en SQL Server.</p>
        </div>
        <button type="button" onClick={() => void cargarRespaldos()} disabled={cargando || operando}>
          <RefreshCw size={16} /> Actualizar
        </button>
      </header>

      <div className="backup-warning" role="note">
        <AlertTriangle size={19} />
        <p>La restauración reemplaza la base actual. Verifica el archivo y confirma el texto solicitado antes de continuar.</p>
      </div>

      {mensaje && <p className="backup-success" role="status">{mensaje}</p>}
      {error && <p className="backup-error" role="alert">{error}</p>}

      <section className="backup-card">
        <h2>Copias disponibles</h2>
        {cargando ? (
          <p role="status">Cargando respaldos...</p>
        ) : respaldos.length === 0 ? (
          <p>No hay copias creadas desde esta aplicación.</p>
        ) : (
          <label>
            Selecciona un respaldo
            <select value={seleccionado} onChange={(event) => setSeleccionado(event.target.value)}>
              {respaldos.map((respaldo) => (
                <option key={respaldo.nombre} value={respaldo.nombre}>
                  {respaldo.nombre} — {new Date(respaldo.creadoEn).toLocaleString("es-CR")}
                </option>
              ))}
            </select>
          </label>
        )}

        <button type="button" onClick={() => void handleCrear()} disabled={operando}>
          Crear y verificar respaldo
        </button>

        <label>
          Para restaurar, escribe exactamente <code>{CONFIRMACION_RESTAURAR}</code>
          <input
            value={confirmacion}
            onChange={(event) => setConfirmacion(event.target.value)}
            autoComplete="off"
            spellCheck="false"
          />
        </label>
        <button
          className="backup-restore-button"
          type="button"
          onClick={() => void handleRestaurar()}
          disabled={operando || !seleccionado || confirmacion !== CONFIRMACION_RESTAURAR}
        >
          Restaurar base de datos
        </button>
      </section>
    </section>
  );
}

export default Respaldos;
