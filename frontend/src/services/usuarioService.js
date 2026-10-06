import { apiFetch as fetch } from "./api";

const API_URL =
  "http://localhost:8080/api/usuarios";

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


// =====================================================
// LISTAR / FILTRAR
// =====================================================

export async function listarUsuarios(
  filtros = {}
) {

  const parametros =
    new URLSearchParams();

  if (filtros.email?.trim()) {
    parametros.append(
      "email",
      filtros.email.trim()
    );
  }

  if (filtros.rolId) {
    parametros.append(
      "rolId",
      filtros.rolId
    );
  }

  if (filtros.estado) {
    parametros.append(
      "estado",
      filtros.estado
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


// =====================================================
// ROLES
// =====================================================

export async function listarRoles() {

  const response =
    await fetch(
      `${API_URL}/roles`
    );

  return procesarRespuesta(response);
}


// =====================================================
// BUSCAR POR ID
// =====================================================

export async function buscarUsuarioPorId(
  id
) {

  const response =
    await fetch(
      `${API_URL}/${id}`
    );

  return procesarRespuesta(response);
}


// =====================================================
// CREAR
// =====================================================

export async function crearUsuario(
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


// =====================================================
// ACTUALIZAR
// =====================================================

export async function actualizarUsuario(
  id,
  datos
) {

  const response =
    await fetch(
      `${API_URL}/${id}`,
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


// =====================================================
// ELIMINAR
// =====================================================

export async function eliminarUsuario(
  id
) {

  const response =
    await fetch(
      `${API_URL}/${id}`,
      {
        method: "DELETE"
      }
    );

  return procesarRespuesta(response);
}