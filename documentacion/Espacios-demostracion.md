# Espacios de demostración

Las tres imágenes PNG de `frontend/public/images/espacios` fueron generadas con IA para este proyecto: campo, sede y centro. Son ilustraciones ficticias; no son fotografías ni representaciones verificadas de las instalaciones de la Asociación. Se reutilizan en una galería que alterna cada seis segundos y permite navegación manual. Las aclaraciones sobre su procedencia se conservan en este documento.

Los seis nombres y ubicaciones fueron proporcionados para el proyecto. Capacidades (40 a 120 personas), costos (₡15.000 a ₡35.000) y disponibilidad son valores ficticios para demostración, no tarifas, aforos ni disponibilidad oficiales.

La migración `db/migrations/005_espacios_demostracion.sql` agrega solo nombres ausentes a `reservasScouts`, sin cambiar el esquema ni sobrescribir registros. También se incluyen en `db/datos.sql` para futuras instalaciones. Los dos espacios demo anteriores y sus reservas se conservan.

## Aplicación

En una base existente, ejecutar primero `db/migrations/006_limpiar_nombres_visibles.sql` y después `db/migrations/005_espacios_demostracion.sql`. La limpieza conserva los IDs y relaciones. En una instalación nueva, `db/datos.sql` ya incluye los nombres actualizados y los seis espacios. No ejecutar los datos de ejemplo sobre producción sin revisar previamente su contenido.

El menú muestra las secciones en horizontal desde 1280 px y se despliega en pantallas menores. Los usuarios autenticados pueden consultar Espacios; crear, editar y eliminar siguen reservados al administrador.
