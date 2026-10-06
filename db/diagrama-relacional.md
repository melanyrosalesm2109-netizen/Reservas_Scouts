# Diagrama relacional - `reservasScouts`

El diagrama representa las claves primarias y foráneas del esquema activo. `auditoriaAccesos.usuarioId` se conserva como dato de auditoría y no tiene una clave foránea.

<!-- mermaid-checked: every attribute is `<type> <name> [<key>] ["<description>"]` with at most one of PK/FK/UK, no \n in descriptions, no {} in descriptions, every relationship label is double-quoted -->
```mermaid
erDiagram
    roles ||--o{ usuarios : "assigns"
    usuarios o|--o| perfilesUsuario : "owns"
    usuarios o|--o{ reservas : "creates"
    usuarios o|--o{ actividad : "performs"
    usuarios o|--o{ auditoriaReservas : "is recorded in"
    usuarios o|--o{ respaldoHistorial : "creates"
    espacios ||--o{ reservas : "hosts"
    perfilesUsuario ||--o{ reservas : "requests"
    reservas ||--o{ pagos : "has"
    roles ||--o{ rolPermisos : "grants"
    permisos ||--o{ rolPermisos : "is assigned through"
    usuarios {
        int id PK
        int rolId FK
        string email UK
        string passwordHash
    }
    roles {
        int id PK
        string nombre UK
    }
    permisos {
        int id PK
        string clave UK
    }
    rolPermisos {
        int rolId PK "also FK to roles"
        int permisoId PK "also FK to permisos"
    }
    perfilesUsuario {
        int idPerfil PK
        int usuarioId FK "optional and unique when set"
        string identificacion UK "unique when set"
    }
    espacios {
        int id PK
        int capacidad
        decimal costo
    }
    reservas {
        int id PK
        int espacioId FK
        int solicitantePerfilId FK
        int creadoPorUsuarioId FK
        string codigo UK
        datetime2 fechaInicio
        datetime2 fechaFin
    }
    pagos {
        int id PK
        int reservaId FK
        decimal monto
    }
    actividad {
        int id PK
        int usuarioId FK
        datetime2 createdAt
    }
    auditoriaReservas {
        bigint idAuditoria PK
        int usuarioAppId FK
        string tabla
        int idRegistro
    }
    auditoriaAccesos {
        bigint idAuditoriaAcceso PK
        int usuarioId "no enforced FK"
        string evento
        datetime2 creadoEn
    }
    respaldoHistorial {
        bigint idRespaldo PK
        string nombreArchivo UK
        int creadoPorUsuarioId FK
        bigint bytes
    }
```

Consulte el [diccionario de datos](./diccionarioDatos.md) para ver todos los campos, tipos SQL, nulabilidad, claves, valores predeterminados y restricciones.
