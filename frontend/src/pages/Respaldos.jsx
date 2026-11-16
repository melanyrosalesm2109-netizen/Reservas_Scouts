import { useEffect, useState } from "react";
import { AlertTriangle, HardDrive, RefreshCw } from "lucide-react";
import {
  crearRespaldo,
  listarRespaldos,
  restaurarRespaldo
} from "../services/respaldoService";
import "./Respaldos.css";
import ResultadoOperacion from "../components/ResultadoOperacion";


function Respaldos() {
  const [respaldos, setRespaldos] = useState([]);
  const [seleccionado, setSeleccionado] = useState("");
  const [cargando, setCargando] = useState(true);
  const [operando, setOperando] = useState(false);
  const [resultado, setResultado] = useState(null);
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
    if (operando) return;
    setOperando(true);
    setResultado(null);
    setError("");
    try {
      const nuevo = await crearRespaldo();
      setResultado({ tipo: "exito", titulo: "Respaldo creado", mensaje: "La copia de seguridad se creó y se verificó correctamente." });
      try { setRespaldos(await listarRespaldos()); }
      catch { setError("La copia se creó correctamente, pero no se pudo actualizar la lista. Pulsa Actualizar."); }
      setSeleccionado(nuevo.nombre);
    } catch (err) {
      setResultado({ tipo: "error", titulo: "No se pudo crear el respaldo", mensaje: err.message || "Intenta crear la copia nuevamente." });
    } finally {
      setOperando(false);
    }
  };

  const handleRestaurar = async () => {
    if (!seleccionado || operando) {
      return;
    }

    setOperando(true);
    setResultado(null);
    setError("");
    try {
      const resultado = await restaurarRespaldo(seleccionado);
      setResultado({ tipo: "exito", titulo: "Base de datos restaurada", mensaje: resultado.mensaje || "La versión seleccionada se recuperó correctamente." });
      try { setRespaldos(await listarRespaldos()); }
      catch { setError("La restauración terminó correctamente, pero no se pudo actualizar la lista. Pulsa Actualizar."); }
    } catch (err) {
      setResultado({ tipo: "error", titulo: "No se pudo completar la restauración", mensaje: err.message || "No se confirmó la restauración. Revisa la auditoría antes de volver a intentarlo." });
    } finally {
      setOperando(false);
    }
  };

  return (
    <section className="backup-page">
      {resultado && <ResultadoOperacion resultado={resultado} onCerrar={() => setResultado(null)} />}
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
        <p>La restauración reemplaza la base actual. Selecciona la versión que deseas recuperar antes de restaurar.</p>
      </div>

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
            <select disabled={operando} value={seleccionado} onChange={(event) => setSeleccionado(event.target.value)}>
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

        <button
          className="backup-restore-button"
          type="button"
          onClick={() => void handleRestaurar()}
          disabled={operando || cargando || !seleccionado}
        >
          {operando ? "Procesando…" : "Restaurar base de datos"}
        </button>
      </section>
    </section>
  );
}

export default Respaldos;
