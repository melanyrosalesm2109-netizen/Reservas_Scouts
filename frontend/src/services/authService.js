import { apiFetch } from "./api";

const API_URL =
  `${import.meta.env.VITE_API_URL || (import.meta.env.DEV ? "http://localhost:8080" : "")}/api/usuarios`;


async function mensajeError(response) {

  const data =
    await response.json().catch(
      () => null
    );

  return (
    data?.mensaje ||
    data?.message ||
    data?.detail
  );
}


// =====================================================
// INICIAR SESIÓN
// =====================================================

export async function iniciarSesion(
  email,
  password
) {

  const response =
    await apiFetch(
      `${API_URL}/login`,
      {
        method: "POST",

        headers: {
          "Content-Type":
            "application/json"
        },

        body:
          JSON.stringify({
            email,
            password
          })
      }
    );


  if (!response.ok) {

    throw new Error(
      await mensajeError(response) ||
      "Correo o contraseña incorrectos."
    );
  }


  return response.json();
}


// =====================================================
// REGISTRAR USUARIO
// =====================================================

export async function registrarUsuario(
  datos
) {

  const response =
    await apiFetch(
      `${API_URL}/registro`,
      {
        method: "POST",

        headers: {
          "Content-Type":
            "application/json"
        },

        body:
          JSON.stringify(datos)
      }
    );


  if (!response.ok) {

    throw new Error(
      await mensajeError(response) ||
      "No se pudo crear la cuenta."
    );
  }


  return response.json();
}


// =====================================================
// OBTENER SESIÓN
// =====================================================

export async function obtenerSesion() {

  const response =
    await apiFetch(
      `${API_URL}/sesion`
    );


  if (
    response.status === 401
  ) {

    return null;
  }


  if (!response.ok) {

    throw new Error(
      await mensajeError(response) ||
      "No se pudo verificar la sesión."
    );
  }


  return response.json();
}


// =====================================================
// CERRAR SESIÓN
// =====================================================

export async function cerrarSesion() {

  const response =
    await apiFetch(
      `${API_URL}/logout`,
      {
        method: "POST"
      }
    );


  if (!response.ok) {

    throw new Error(
      await mensajeError(response) ||
      "No se pudo cerrar la sesión."
    );
  }
}