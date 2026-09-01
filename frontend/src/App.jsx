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

import MainLayout from "./layouts/MainLayout";
import ProtectedRoute from "./components/ProtectedRoute";

function App() {

  return (

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
              <Dashboard />
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
              <Espacios />
            }
          />

          <Route
            path="/perfiles"
            element={
              <Perfiles />
            }
          />

          <Route
            path="/pagos"
            element={
              <Pagos />
            }
          />

          <Route
            path="/usuarios"
            element={
              <Usuarios />
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
  );
}

export default App;