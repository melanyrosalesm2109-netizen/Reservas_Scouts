import { Navigate } from "react-router-dom";
import { useAuth } from "../context/useAuth";

function ProtectedRoute({ children, requiredRole }) {
  const { usuario, cargando, error, recargarSesion } = useAuth();

  if (cargando) {
    return <p role="status">Verificando sesión...</p>;
  }

  if (error) {
    return (
      <div role="alert">
        <p>{error}</p>
        <button type="button" onClick={() => void recargarSesion()}>
          Reintentar
        </button>
      </div>
    );
  }

  if (!usuario) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRole && usuario.rol !== requiredRole) {
    return <Navigate to="/reservas" replace />;
  }

  return children;
}

export default ProtectedRoute;