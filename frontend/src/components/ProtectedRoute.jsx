import {
  Navigate
} from "react-router-dom";

import {
  obtenerSesion
} from "../services/authService";

function ProtectedRoute({
  children
}) {

  const usuario =
    obtenerSesion();

  if (!usuario) {

    return (
      <Navigate
        to="/login"
        replace
      />
    );
  }

  return children;
}

export default ProtectedRoute;