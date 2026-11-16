# Backend · Reservas Scouts

API Spring Boot con Java 21 y SQL Server. La persistencia utiliza JDBC y
procedimientos almacenados. La autorización se aplica por sesión y rol.

## Preparación

1. Instalar la base siguiendo [db/README.md](../db/README.md).
2. Configurar `RESERVASSCOUTS_DB_PASSWORD` para el login `reservas_app`.
3. Configurar `RESERVASSCOUTS_MAINTENANCE_PASSWORD` para crear y restaurar
   respaldos; `RESERVASSCOUTS_BACKUP_DIRECTORY` permite cambiar su carpeta.
4. Ejecutar desde esta carpeta:

```powershell
.\mvnw.cmd spring-boot:run
```

También se puede utilizar `mvn spring-boot:run` con Maven instalado.
Spring recibe las variables del entorno del proceso; no carga archivos `.env`
automáticamente. La configuración está en `src/main/resources/application.properties`.
La API local utiliza el puerto `8080`.

## Estructura

| Paquete | Responsabilidad |
| --- | --- |
| `controller` | Rutas HTTP, sesión y validación de solicitudes. |
| `service` | Reglas de negocio, transacciones y vencimientos. |
| `repository` | Ejecución de procedimientos y mapeo de resultados. |
| `dto` | Contratos y validaciones de entrada. |
| `model` | Datos de respuesta y resultados de consultas. |
| `config` | Autorización y configuración de la aplicación. |
| `exception` | Respuestas consistentes ante errores. |

`src/test/java/` contiene las pruebas. `target/` es generado por Maven y no se
versiona. Se conservan ambos wrappers (`mvnw` y `mvnw.cmd`) para Unix y Windows.

## Verificar

```powershell
.\mvnw.cmd test
```

Las pruebas SQL se activan expresamente mediante `RESERVAS_SQL_TEST=true` y
los IDs de las cuentas, perfil y espacio de prueba. Las pruebas de vencimiento
y restauración requieren, además, sus helpers y variables específicas;
consultar [db/tests/README.md](../db/tests/README.md).

La restauración se prueba en una base temporal, nunca sobre datos reales.
No guardar contraseñas en código, documentación o archivos versionados.
