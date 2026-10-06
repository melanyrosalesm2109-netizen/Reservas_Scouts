const API_URL =
  "http://localhost:8080/api/perfiles";

async function procesarRespuesta(response) {
  const data = await response.json().catch(() => null);

  if (!response.ok) {
    throw new Error(
      data?.mensaje ||
      "Ocurrió un error al procesar la solicitud."
    );
  }

  return data;
}

// LISTAR Y FILTRAR
export async function listarPerfiles(
  filtros = {}
) {
  const parametros =
    new URLSearchParams();

  if (filtros.nombre?.trim()) {
    parametros.append(
      "nombre",
      filtros.nombre.trim()
    );
  }

  if (filtros.identificacion?.trim()) {
    parametros.append(
      "identificacion",
      filtros.identificacion.trim()
    );
  }

  if (filtros.correoContacto?.trim()) {
    parametros.append(
      "correoContacto",
      filtros.correoContacto.trim()
    );
  }

  if (filtros.tipoPerfil) {
    parametros.append(
      "tipoPerfil",
      filtros.tipoPerfil
    );
  }

  if (filtros.usuarioId) {
    parametros.append(
      "usuarioId",
      filtros.usuarioId
    );
  }

  const url =
    parametros.toString()
      ? `${API_URL}?${parametros.toString()}`
      : API_URL;

  const response =
    await fetch(url);

  return procesarRespuesta(response);
}

// BUSCAR POR ID
export async function buscarPerfilPorId(
  idPerfil
) {

  const response =
    await fetch(
      `${API_URL}/${idPerfil}`
    );

  return procesarRespuesta(response);
}

// INSERTAR
export async function crearPerfil(
  datos
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
          JSON.stringify(datos)
      }
    );

  return procesarRespuesta(response);
}

// ACTUALIZAR
export async function actualizarPerfil(
  idPerfil,
  datos
) {

  const response =
    await fetch(
      `${API_URL}/${idPerfil}`,
      {
        method: "PUT",

        headers: {
          "Content-Type":
            "application/json"
        },

        body:
          JSON.stringify(datos)
      }
    );

  return procesarRespuesta(response);
}

// ELIMINAR
export async function eliminarPerfil(
  idPerfil
) {

  const response =
    await fetch(
      `${API_URL}/${idPerfil}`,
      {
        method: "DELETE"
      }
    );

  return procesarRespuesta(response);
}