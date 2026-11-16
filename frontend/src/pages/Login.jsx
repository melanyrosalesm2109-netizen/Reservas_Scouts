import { useState } from "react";

import {
  useNavigate
} from "react-router-dom";

import {
  Mail,
  LockKeyhole,
  UserRound,
  Phone,
  MapPin,
  CreditCard,
  ArrowLeft
} from "lucide-react";

import {
  iniciarSesion,
  registrarUsuario
} from "../services/authService";

import {
  useAuth
} from "../context/useAuth";

import "./Login.css";
import LoginPresentation from "../components/LoginPresentation";


const registroVacio = {

  nombre: "",

  identificacion: "",

  telefono: "",

  email: "",

  direccion: "",

  password: "",

  confirmarPassword: ""
};


function Login() {

  const navigate =
    useNavigate();

  const { setUsuario } =
    useAuth();


  const [modoRegistro, setModoRegistro] =
    useState(false);


  const [email, setEmail] =
    useState("");

  const [password, setPassword] =
    useState("");


  const [
    registro,
    setRegistro
  ] = useState(
    registroVacio
  );


  const [error, setError] =
    useState("");

  const [mensaje, setMensaje] =
    useState("");

  const [cargando, setCargando] =
    useState(false);


  // =====================================================
  // LOGIN
  // =====================================================

  const handleSubmit = async (
    event
  ) => {

    event.preventDefault();

    setError("");
    setMensaje("");


    if (!email.trim()) {

      setError(
        "Ingrese su usuario o correo."
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


      setUsuario(
        usuario
      );


      navigate(

        usuario.rol ===
        "Administrador"

          ? "/dashboard"

          : "/reservas",

        {
          replace: true
        }
      );


    } catch (err) {

      setError(
        err.message
      );


    } finally {

      setCargando(false);
    }
  };


  // =====================================================
  // CAMBIOS DEL REGISTRO
  // =====================================================

  const handleRegistroChange = (
    event
  ) => {

    const {
      name,
      value
    } = event.target;


    setRegistro(
      anterior => ({

        ...anterior,

        [name]:
          value
      })
    );
  };


  // =====================================================
  // CREAR CUENTA
  // =====================================================

  const handleRegistro = async (
    event
  ) => {

    event.preventDefault();

    setError("");
    setMensaje("");


    if (!registro.nombre.trim()) {

      setError(
        "Ingrese su nombre."
      );

      return;
    }


    if (!registro.email.trim()) {

      setError(
        "Ingrese su correo."
      );

      return;
    }


    if (
      registro.password.length < 6
    ) {

      setError(
        "La contraseña debe tener al menos 6 caracteres."
      );

      return;
    }


    if (
      registro.password !==
      registro.confirmarPassword
    ) {

      setError(
        "Las contraseñas no coinciden."
      );

      return;
    }


    try {

      setCargando(true);


      await registrarUsuario({

        nombre:
          registro.nombre.trim(),

        identificacion:
          registro.identificacion.trim(),

        telefono:
          registro.telefono.trim(),

        email:
          registro.email.trim(),

        direccion:
          registro.direccion.trim(),

        password:
          registro.password,

        confirmarPassword:
          registro.confirmarPassword
      });


      setMensaje(
        "Cuenta creada correctamente. Ahora puede iniciar sesión."
      );


      setEmail(
        registro.email.trim()
      );

      setPassword("");

      setRegistro(
        registroVacio
      );

      setModoRegistro(
        false
      );


    } catch (err) {

      setError(
        err.message
      );


    } finally {

      setCargando(false);
    }
  };


  // =====================================================
  // CAMBIAR MODO
  // =====================================================

  const abrirRegistro = () => {

    setError("");
    setMensaje("");

    setModoRegistro(
      true
    );
  };


  const volverLogin = () => {

    setError("");
    setMensaje("");

    setModoRegistro(
      false
    );
  };


  // =====================================================
  // INTERFAZ
  // =====================================================

  return (

    <LoginPresentation>

      <div
        className={
          `login-card ${
            modoRegistro
              ? "login-card-register"
              : ""
          }`
        }
      >


        <div className="login-brand">

          <span>
            RESERVAS SCOUTS
          </span>


          <h2>

            {modoRegistro
              ? "Crear cuenta"
              : "Bienvenido"}

          </h2>


          <p>

            {modoRegistro
              ? "Regístrese para realizar reservaciones"
              : "Inicia sesión para continuar"}

          </p>

        </div>


        {mensaje && (

          <div className="login-success">

            {mensaje}

          </div>
        )}


        {error && (

          <div className="login-error">

            {error}

          </div>
        )}


        {!modoRegistro ? (

          <form
            onSubmit={handleSubmit}
            className="login-form"
          >
              <p className="required-fields-note"><span className="required-mark">*</span> indica un campo obligatorio.</p>


            <div className="login-field">

              <label>
                Usuario o correo <span className="required-mark" aria-hidden="true">*</span>
</label>


              <div className="login-input">

                <Mail size={18} />


                <input
                  type="text"
                  value={email}
                  onChange={
                    event =>
                      setEmail(
                        event.target.value
                      )
                  }
                  required placeholder="Ingrese su usuario o correo"
                />

              </div>

            </div>


            <div className="login-field">

              <label>
                Contraseña <span className="required-mark" aria-hidden="true">*</span>
</label>


              <div className="login-input">

                <LockKeyhole
                  size={18}
                />


                <input
                  type="password"
                  value={password}
                  onChange={
                    event =>
                      setPassword(
                        event.target.value
                      )
                  }
                  required placeholder="Ingrese su contraseña"
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


            <div className="login-register-section">

              <span>
                ¿No tienes una cuenta?
              </span>


              <button
                type="button"
                className="login-register-button"
                onClick={abrirRegistro}
              >

                Crear cuenta

              </button>

            </div>

          </form>


        ) : (


          <form
            onSubmit={handleRegistro}
            className="login-form"
          >
              <p className="required-fields-note"><span className="required-mark">*</span> indica un campo obligatorio.</p>


            <div className="register-grid">


              <div className="login-field register-full">

                <label>
                  Nombre completo <span className="required-mark" aria-hidden="true">*</span>
                </label>


                <div className="login-input">

                  <UserRound
                    size={18}
                  />


                  <input
                    name="nombre"
                    value={
                      registro.nombre
                    }
                    onChange={
                      handleRegistroChange
                    }
                    maxLength={160}
                    placeholder="Nombre completo"
                    required
                  />

                </div>

              </div>


              <div className="login-field">

                <label>
                  Identificación
                </label>


                <div className="login-input">

                  <CreditCard
                    size={18}
                  />


                  <input
                    name="identificacion"
                    value={
                      registro.identificacion
                    }
                    onChange={
                      handleRegistroChange
                    }
                    maxLength={30}
                    placeholder="Identificación"
                  />

                </div>

              </div>


              <div className="login-field">

                <label>
                  Teléfono
                </label>


                <div className="login-input">

                  <Phone
                    size={18}
                  />


                  <input
                    name="telefono"
                    value={
                      registro.telefono
                    }
                    onChange={
                      handleRegistroChange
                    }
                    maxLength={30}
                    placeholder="Ej: 88888888"
                  />

                </div>

              </div>


              <div className="login-field register-full">

                <label>
                  Correo electrónico <span className="required-mark" aria-hidden="true">*</span>
                </label>


                <div className="login-input">

                  <Mail
                    size={18}
                  />


                  <input
                    type="email"
                    name="email"
                    value={
                      registro.email
                    }
                    onChange={
                      handleRegistroChange
                    }
                    maxLength={160}
                    placeholder="correo@ejemplo.com"
                    required
                  />

                </div>

              </div>


              <div className="login-field register-full">

                <label>
                  Dirección
                </label>


                <div className="login-input">

                  <MapPin
                    size={18}
                  />


                  <input
                    name="direccion"
                    value={
                      registro.direccion
                    }
                    onChange={
                      handleRegistroChange
                    }
                    maxLength={255}
                    placeholder="Dirección"
                  />

                </div>

              </div>


              <div className="login-field">

                <label>
                  Contraseña <span className="required-mark" aria-hidden="true">*</span>
                </label>


                <div className="login-input">

                  <LockKeyhole
                    size={18}
                  />


                  <input
                    type="password"
                    name="password"
                    value={
                      registro.password
                    }
                    onChange={
                      handleRegistroChange
                    }
                    minLength={6}
                    placeholder="Mínimo 6 caracteres"
                    required
                  />

                </div>

              </div>


              <div className="login-field">

                <label>
                  Confirmar contraseña <span className="required-mark" aria-hidden="true">*</span>
                </label>


                <div className="login-input">

                  <LockKeyhole
                    size={18}
                  />


                  <input
                    type="password"
                    name="confirmarPassword"
                    value={
                      registro.confirmarPassword
                    }
                    onChange={
                      handleRegistroChange
                    }
                    minLength={6}
                    placeholder="Repita la contraseña"
                    required
                  />

                </div>

              </div>


            </div>


            <button
              type="submit"
              className="login-button"
              disabled={cargando}
            >

              {cargando
                ? "Creando cuenta..."
                : "Crear cuenta"}

            </button>


            <button
              type="button"
              className="login-back-button"
              onClick={volverLogin}
            >

              <ArrowLeft
                size={17}
              />

              Volver al inicio de sesión

            </button>

          </form>
        )}

      </div>

    </LoginPresentation>
  );
}


export default Login;