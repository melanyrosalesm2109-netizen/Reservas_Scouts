const API_URL =
  "http://localhost:8080/api/reservas";

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

// LISTAR / FILTRAR
export async function listarReservas(
  filtros = {}
) {
  const parametros =
    new URLSearchParams();

  if (filtros.codigo?.trim()) {
    parametros.append(
      "codigo",
      filtros.codigo.trim()
    );
  }

  if (filtros.responsable?.trim()) {
    parametros.append(
      "responsable",
      filtros.responsable.trim()
    );
  }

  if (filtros.estado) {
    parametros.append(
      "estado",
      filtros.estado
    );
  }

  if (filtros.espacioId) {
    parametros.append(
      "espacioId",
      filtros.espacioId
    );
  }

  if (filtros.solicitantePerfilId) {
    parametros.append(
      "solicitantePerfilId",
      filtros.solicitantePerfilId
    );
  }

  if (filtros.fechaDesde) {
    parametros.append(
      "fechaDesde",
      filtros.fechaDesde
    );
  }

  if (filtros.fechaHasta) {
    parametros.append(
      "fechaHasta",
      filtros.fechaHasta
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

// BUSCAR ID
export async function buscarReservaPorId(id) {

  const response =
    await fetch(
      `${API_URL}/${id}`
    );

  return procesarRespuesta(response);
}

// INSERTAR
export async function crearReserva(datos) {

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
export async function actualizarReserva(
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

// ELIMINAR
export async function eliminarReserva(id) {

  const response =
    await fetch(
      `${API_URL}/${id}`,
      {
        method: "DELETE"
      }
    );

  return procesarRespuesta(response);
}