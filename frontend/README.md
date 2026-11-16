# Frontend · Reservas Scouts

Interfaz React con Vite. Incluye acceso público, perfiles, reservas, calendario,
pagos, auditoría y respaldos, con navegación según el rol de la sesión.

## Ejecutar

Desde esta carpeta:

```powershell
npm ci
npm run dev
```

Vite usa `http://localhost:5173`. El backend local se consulta en
`http://localhost:8080`. Para otro servidor, definir `VITE_API_URL` siguiendo
[.env.example](.env.example). Esta variable es pública: no contiene contraseñas.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `src/pages/` | Pantallas y estilos propios de cada módulo. |
| `src/components/` | Componentes compartidos y flujos de pago. |
| `src/layouts/` | Cabecera y navegación de la aplicación. |
| `src/context/` | Sesión y sincronización de notificaciones. |
| `src/services/` | Llamadas al backend; `api.js` incluye la cookie de sesión. |
| `src/styles/` | Adaptación compartida a distintos tamaños de pantalla. |
| `public/` | Favicon y recursos públicos utilizados por la interfaz. |
| `e2e/` | Pruebas de navegador y sus instrucciones. |

`src/index.css` define estilos base y variables. Cada pantalla conserva su CSS
específico; `Responsive.css` aplica los ajustes compartidos.

## Verificar

```powershell
npm run lint
npm run build
```

La compilación genera `dist/`. No se versionan `node_modules/`, `dist/`,
resultados de Playwright ni capturas temporales. Para pruebas de navegador,
consultar [e2e/README.md](e2e/README.md).

Las instrucciones de instalación y base de datos están en el
[README principal](../README.md).