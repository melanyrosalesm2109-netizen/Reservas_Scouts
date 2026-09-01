const API_URL =
  "http://localhost:8080/api/pagos";

async function procesarRespuesta(response) {

  let data = null;

  try {
    data = await response.json();
  } catch {
    data = null;
  }

  if (!response.ok) {

    throw new Error(
      data?.mensaje ||
      "Ocurrió un error al procesar la solicitud."
    );
  }

  return data;
}

// LISTAR / FILTRAR
export async function listarPagos(
  filtros = {}
) {

  const parametros =
    new URLSearchParams();

  if (filtros.reservaId) {
    parametros.append(
      "reservaId",
      filtros.reservaId
    );
  }

  if (filtros.codigoReserva?.trim()) {
    parametros.append(
      "codigoReserva",
      filtros.codigoReserva.trim()
    );
  }

  if (filtros.metodo) {
    parametros.append(
      "metodo",
      filtros.metodo
    );
  }

  if (filtros.estado) {
    parametros.append(
      "estado",
      filtros.estado
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

// BUSCAR POR ID
export async function buscarPagoPorId(
  id
) {

  const response =
    await fetch(
      `${API_URL}/${id}`
    );

  return procesarRespuesta(response);
}

// CREAR
export async function crearPago(
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
export async function actualizarPago(
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
export async function eliminarPago(
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