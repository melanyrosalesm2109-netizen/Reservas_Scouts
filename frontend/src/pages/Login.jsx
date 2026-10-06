import { useState } from "react";

import {
  useNavigate
} from "react-router-dom";

import {
  Mail,
  LockKeyhole
} from "lucide-react";

import {
  iniciarSesion
} from "../services/authService";
import { useAuth } from "../context/useAuth";

import "./Login.css";

function Login() {

  const navigate =
    useNavigate();
  const { setUsuario } = useAuth();

  const [email, setEmail] =
    useState("");

  const [password, setPassword] =
    useState("");

  const [error, setError] =
    useState("");

  const [cargando, setCargando] =
    useState(false);


  const handleSubmit = async (
    event
  ) => {

    event.preventDefault();

    setError("");


    if (!email.trim()) {

      setError(
        "Ingrese su correo electrónico."
      );

      return;
    }


    if (!password) {

      setError(
        "Ingrese su contraseña."
      );

      return;
    }


    try {

      setCargando(true);

      const usuario =
        await iniciarSesion(
          email.trim(),
          password
        );

      setUsuario(usuario);

      navigate(
        usuario.rol === "Administrador" ? "/dashboard" : "/reservas",
        { replace: true }
      );

    } catch (err) {

      setError(
        err.message
      );

    } finally {

      setCargando(false);
    }
  };


  return (

    <div className="login-page">

      <div className="login-card">

        <div className="login-brand">

          <span>
            RESERVAS SCOUTS
          </span>

          <h1>
            Bienvenido
          </h1>

          <p>
            Inicia sesión para continuar
          </p>

        </div>


        {error && (

          <div className="login-error">
            {error}
          </div>

        )}


        <form
          onSubmit={handleSubmit}
          className="login-form"
        >

          <div className="login-field">

            <label>
              Correo electrónico
            </label>

            <div className="login-input">

              <Mail size={18} />

              <input
                type="email"
                value={email}
                onChange={
                  (event) =>
                    setEmail(
                      event.target.value
                    )
                }
                placeholder="Ingrese su correo"
              />

            </div>

          </div>


          <div className="login-field">

            <label>
              Contraseña
            </label>

            <div className="login-input">

              <LockKeyhole
                size={18}
              />

              <input
                type="password"
                value={password}
                onChange={
                  (event) =>
                    setPassword(
                      event.target.value
                    )
                }
                placeholder="Ingrese su contraseña"
              />

            </div>

          </div>


          <button
            type="submit"
            className="login-button"
            disabled={cargando}
          >

            {cargando
              ? "Ingresando..."
              : "Iniciar sesión"}

          </button>

        </form>

      </div>

    </div>
  );
}

export default Login;