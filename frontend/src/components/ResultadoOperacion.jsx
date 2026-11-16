import { useEffect, useRef } from "react";
import { CircleCheck, CircleX, X } from "lucide-react";
import "./ResultadoOperacion.css";

export default function ResultadoOperacion({ resultado, onCerrar }) {
  const ref = useRef(null);
  const correcto = resultado.tipo === "exito";
  const Icono = correcto ? CircleCheck : CircleX;
  useEffect(() => {
    const dialog = ref.current;
    dialog.showModal();
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { document.body.style.overflow = overflow; dialog.close(); };
  }, []);
  return <dialog ref={ref} className={`resultado-operacion ${correcto ? "resultado-exito" : "resultado-error"}`}
    aria-labelledby="resultado-titulo" aria-describedby="resultado-mensaje"
    onCancel={event => { event.preventDefault(); onCerrar(); }}>
    <button type="button" className="resultado-cerrar" aria-label="Cerrar resultado" onClick={onCerrar}><X size={20} /></button>
    <div className="resultado-icono" aria-hidden="true"><Icono size={48} strokeWidth={1.8} /></div>
    <span className="resultado-etiqueta">{correcto ? "OPERACIÓN COMPLETADA" : "NO SE PUDO COMPLETAR"}</span>
    <h2 id="resultado-titulo">{resultado.titulo}</h2>
    <p id="resultado-mensaje" role={correcto ? "status" : "alert"}>{resultado.mensaje}</p>
    <button type="button" className="resultado-entendido" onClick={onCerrar} autoFocus>Entendido</button>
  </dialog>;
}
