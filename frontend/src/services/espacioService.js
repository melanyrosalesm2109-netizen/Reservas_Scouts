import { apiFetch as fetch } from "./api";

const API_URL =
  "http://localhost:8080/api/espacios";

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
export async function listarEspacios(
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

  if (filtros.ubicacion?.trim()) {
    parametros.append(
      "ubicacion",
      filtros.ubicacion.trim()
    );
  }

  if (filtros.estado) {
    parametros.append(
      "estado",
      filtros.estado
    );
  }

  if (filtros.capacidadMinima) {
    parametros.append(
      "capacidadMinima",
      filtros.capacidadMinima
    );
  }

  if (filtros.costoMaximo) {
    parametros.append(
      "costoMaximo",
      filtros.costoMaximo
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
// BUSCAR POR ID
// =====================================================
export async function buscarEspacioPorId(
  id
) {
  const response =
    await fetch(
      `${API_URL}/${id}`
    );

  return procesarRespuesta(response);
}

// =====================================================
// INSERTAR
// =====================================================
export async function crearEspacio(
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
export async function actualizarEspacio(
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
export async function eliminarEspacio(
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