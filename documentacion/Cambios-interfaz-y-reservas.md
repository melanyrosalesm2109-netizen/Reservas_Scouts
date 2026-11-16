# Cambios de interfaz y reservas

La rama cambios incluye la portada pública con acceso en una ventana, el perfil del usuario con sus reservas pendientes, la separación visual entre personal y personas registradas, el motivo de rechazo de pagos y el espacio relacionado en auditoría. Mejora además formularios, tablas móviles y controles táctiles, manteniendo los colores del sistema.

## Actualización de una base existente

Después de traer el código, ejecutar en SQL Server las migraciones siguientes, en orden:

1. db/migrations/012_reservas_propias.sql
2. db/migrations/013_perfiles_registrados.sql

La primera permite consultar reservas creadas por la cuenta y las vinculadas a su perfil aunque las haya registrado personal del sistema. La segunda instala el procedimiento de consulta de personas registradas sin conceder lectura directa de tablas a la aplicación. No borran cuentas ni reservas. El instalador db/reservasScouts.sql ya incluye estas definiciones para instalaciones nuevas; no debe ejecutarse completo sobre una base existente.

Se presupone que las migraciones previas de jonawork ya están aplicadas, incluidas las de calendario, pagos y notificaciones (007 a 011). Conservar las variables de entorno y las configuraciones propias del equipo de destino.

## Validación local

Se verificaron las pantallas administrativas y de usuario entre 320 y 1440 píxeles, así como las vistas táctiles de móvil y tablet. Pasaron las pruebas de interfaz adaptable, formularios, inicio de sesión, reservas propias, privacidad entre usuarios, rechazo real de pago y nombre de espacio en auditoría. Los datos temporales de esas pruebas se limpiaron.

El frontend pasó lint y compilación. El backend pasó 15 pruebas; ocho pruebas adicionales con SQL requieren parámetros específicos y quedaron omitidas en esa ejecución. No equivale a una validación del hosting remoto.

## Integración

Esta rama se publica para que el equipo pueda traerla y revisarla. No se integra automáticamente a main ni activa auto-merge.
