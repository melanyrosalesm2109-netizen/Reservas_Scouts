const API_URL =
  "http://localhost:8080/api/usuarios/login";

export async function iniciarSesion(
  email,
  password
) {

  const response =
    await fetch(
      API_URL,
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

  const data = await response.json().catch(() => null);

  if (!response.ok) {

    throw new Error(
      data?.mensaje ||
      data?.message ||
      "Correo o contraseña incorrectos."
    );
  }

  return data;
}

export function guardarSesion(
  usuario
) {

  localStorage.setItem(
    "usuario",
    JSON.stringify(usuario)
  );
}

export function obtenerSesion() {

  const datos =
    localStorage.getItem(
      "usuario"
    );

  if (!datos) {
    return null;
  }

  try {
    return JSON.parse(datos);
  } catch {
    return null;
  }
}

export function cerrarSesion() {

  localStorage.removeItem(
    "usuario"
  );
}