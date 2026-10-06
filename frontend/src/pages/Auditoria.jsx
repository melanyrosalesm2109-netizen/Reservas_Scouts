import { useEffect, useState } from "react";
import { Activity, RefreshCw } from "lucide-react";
import { obtenerResumenAuditoria } from "../services/auditoriaService";
import "./Auditoria.css";

function Auditoria() {
  const [resumen, setResumen] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const cargarResumen = async () => {
    setCargando(true);
    setError("");
    try {
      setResumen(await obtenerResumenAuditoria());
    } catch (err) {
      setError(err.message || "No se pudo cargar el resumen de auditoría.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    let vigente = true;
    obtenerResumenAuditoria()
      .then((datos) => {
        if (vigente) {
          setResumen(datos);
        }
      })
      .catch((err) => {
        if (vigente) {
          setError(err.message || "No se pudo cargar el resumen de auditoría.");
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

  return (
    <section className="audit-page">
      <header className="audit-heading">
        <div>
          <span className="audit-eyebrow">CONTROL DEL SISTEMA</span>
          <h1><Activity size={25} /> Auditoría</h1>
          <p>Actividad agrupada por origen y tipo de evento.</p>
        </div>
        <button type="button" onClick={() => void cargarResumen()} disabled={cargando}>
          <RefreshCw size={16} /> Actualizar
        </button>
      </header>

      {error && <p className="audit-error" role="alert">{error}</p>}
      {cargando ? (
        <p role="status">Cargando auditoría...</p>
      ) : (
        <div className="audit-table-wrap">
          <table className="audit-table">
            <thead>
              <tr>
                <th>Origen</th>
                <th>Evento</th>
                <th>Total</th>
                <th>Último evento</th>
              </tr>
            </thead>
            <tbody>
              {resumen.length === 0 ? (
                <tr><td colSpan="4">Todavía no se han registrado eventos.</td></tr>
              ) : resumen.map((fila) => (
                <tr key={`${fila.origen}-${fila.evento}`}>
                  <td>{fila.origen}</td>
                  <td>{fila.evento}</td>
                  <td>{fila.totalEventos}</td>
                  <td>{new Date(fila.ultimoEvento).toLocaleString("es-CR")}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

export default Auditoria;
