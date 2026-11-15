import { useCallback, useEffect, useRef, useState } from "react";
import { listarNotificaciones } from "../services/notificacionService";

export function useNotificaciones(habilitado) {
  const [notificaciones, setNotificaciones] = useState([]);
  const [cargando, setCargando] = useState(habilitado);
  const [error, setError] = useState("");
  const [actualizado, setActualizado] = useState(null);
  const solicitud = useRef(0);
  const invalidarSolicitudes = useCallback(() => { solicitud.current += 1; }, []);
  const refrescar = useCallback(async () => {
    if (!habilitado) return;
    const turno = ++solicitud.current;
    try {
      const datos = await listarNotificaciones();
      if (turno === solicitud.current) { setNotificaciones(datos); setError(""); setActualizado(new Date()); }
    } catch (err) { if (turno === solicitud.current) setError(err.message); }
    finally { if (turno === solicitud.current) setCargando(false); }
  }, [habilitado]);
  useEffect(() => {
    if (!habilitado) return;
    const cargar = () => { if (document.visibilityState !== "hidden") void refrescar(); };
    const almacenar = event => { if (event.key === "reservas-pagos-actualizados") cargar(); };
    queueMicrotask(() => { void refrescar(); });
    const timer = setInterval(cargar, 5000);
    window.addEventListener("focus", cargar);
    window.addEventListener("reservas-pagos-actualizados", cargar);
    window.addEventListener("storage", almacenar);
    document.addEventListener("visibilitychange", cargar);
    return () => {
      invalidarSolicitudes();
      clearInterval(timer);
      window.removeEventListener("focus", cargar);
      window.removeEventListener("reservas-pagos-actualizados", cargar);
      window.removeEventListener("storage", almacenar);
      document.removeEventListener("visibilitychange", cargar);
    };
  }, [habilitado, refrescar, invalidarSolicitudes]);
  return { notificaciones, cargando, error, actualizado, refrescar };
}
