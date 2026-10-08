import {
  BrowserRouter,
  Routes,
  Route,
  Navigate
} from "react-router-dom";

import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Reservas from "./pages/Reservas";
import Espacios from "./pages/Espacios";
import Perfiles from "./pages/Perfiles";
import Pagos from "./pages/Pagos";
import Usuarios from "./pages/Usuarios";
import Auditoria from "./pages/Auditoria";
import Respaldos from "./pages/Respaldos";

import MainLayout from "./layouts/MainLayout";
import ProtectedRoute from "./components/ProtectedRoute";
import { AuthProvider } from "./context/AuthProvider";

function App() {

  return (

    <AuthProvider>
    <BrowserRouter>

      <Routes>

        <Route
          path="/"
          element={
            <Navigate
              to="/login"
              replace
            />
          }
        />

        <Route
          path="/login"
          element={
            <Login />
          }
        />

        {/* ==========================================
            RUTAS PROTEGIDAS
        ========================================== */}

        <Route
          element={
            <ProtectedRoute>

              <MainLayout />

            </ProtectedRoute>
          }
        >

          <Route
            path="/dashboard"
            element={
              <ProtectedRoute requiredRole="Administrador">
                <Dashboard />
              </ProtectedRoute>
            }
          />

          <Route
            path="/reservas"
            element={
              <Reservas />
            }
          />

          <Route
            path="/espacios"
            element={
              <ProtectedRoute requiredRole={["Administrador", "Recepcionista"]}>
                <Espacios />
              </ProtectedRoute>
            }
          />

          <Route
            path="/perfiles"
            element={
              <ProtectedRoute requiredRole={["Administrador", "Recepcionista"]}>
                <Perfiles />
              </ProtectedRoute>
            }
          />

          <Route
            path="/pagos"
            element={
              <ProtectedRoute requiredRole={["Administrador", "Recepcionista"]}>
                <Pagos />
              </ProtectedRoute>
            }
          />

          <Route
            path="/usuarios"
            element={
              <ProtectedRoute requiredRole="Administrador">
                <Usuarios />
              </ProtectedRoute>
            }
          />

          <Route
            path="/auditoria"
            element={
              <ProtectedRoute requiredRole="Administrador">
                <Auditoria />
              </ProtectedRoute>
            }
          />

          <Route
            path="/respaldos"
            element={
              <ProtectedRoute requiredRole="Administrador">
                <Respaldos />
              </ProtectedRoute>
            }
          />

        </Route>

        {/* Si escribe una dirección inexistente */}

        <Route
          path="*"
          element={
            <Navigate
              to="/login"
              replace
            />
          }
        />

      </Routes>

    </BrowserRouter>
    </AuthProvider>
  );
}

export default App;