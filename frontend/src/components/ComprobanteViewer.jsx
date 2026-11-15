import { useEffect, useRef, useState } from "react";
import { obtenerComprobante } from "../services/reservaPagoService";
import "./ComprobanteViewer.css";

export default function ComprobanteViewer({ pago, onCerrar }) {
  const dialogo = useRef(null);
  const [archivo, setArchivo] = useState(null);
  const [error, setError] = useState("");
  useEffect(() => {
    dialogo.current.showModal();
    let vigente = true;
    let url;
    obtenerComprobante(pago.id).then(datos => {
      url = datos.url;
      if (vigente) setArchivo(datos);
      else URL.revokeObjectURL(url);
    }).catch(err => { if (vigente) setError(err.message); });
    return () => { vigente = false; if (url) URL.revokeObjectURL(url); };
  }, [pago.id]);
  return <dialog ref={dialogo} className="comprobante-dialog" aria-labelledby="comprobante-titulo"
    onCancel={event => { event.preventDefault(); onCerrar(); }}>
    <header>
      <div><h2 id="comprobante-titulo">Comprobante de pago</h2><p>{pago.reservaCodigo} · {pago.metodo}</p></div>
      <button type="button" onClick={onCerrar} aria-label="Cerrar comprobante">×</button>
    </header>
    <div className="comprobante-contenido">
      {error ? <p role="alert">{error}</p> : !archivo ? <p role="status">Cargando comprobante…</p> :
        archivo.tipo === "application/pdf" ? <iframe src={archivo.url} title={`Comprobante PDF de ${pago.reservaCodigo}`} /> :
        archivo.tipo.startsWith("image/") ? <img src={archivo.url} alt={`Comprobante de ${pago.reservaCodigo}`} /> : <p>Descarga el archivo para revisarlo.</p>}
    </div>
    <footer><span>Estado del pago: {pago.estado}</span>{archivo && <a href={archivo.url} download={archivo.nombre}>Descargar comprobante</a>}
      <button type="button" onClick={onCerrar}>Cerrar</button></footer>
  </dialog>;
}
