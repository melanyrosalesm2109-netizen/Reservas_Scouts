import { useCallback, useEffect, useState } from "react";
import { obtenerSesion } from "../services/authService";
import { AuthContext } from "./authContext";

export function AuthProvider({ children }) {
  const [usuario, setUsuario] = useState(null);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const recargarSesion = useCallback(async () => {
    setCargando(true);
    setError("");
    try {
      setUsuario(await obtenerSesion());
    } catch (err) {
      setError(err.message || "No se pudo verificar la sesión.");
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => {
    let vigente = true;
    obtenerSesion()
      .then((sesion) => {
        if (vigente) {
          setUsuario(sesion);
        }
      })
      .catch((err) => {
        if (vigente) {
          setError(err.message || "No se pudo verificar la sesión.");
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

  const value = {
    usuario,
    setUsuario,
    cargando,
    error,
    recargarSesion
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}
