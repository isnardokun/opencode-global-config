---
name: memory-retrieval
description: Búsqueda de memoria en 3 capas con Progressive Disclosure - search, timeline, get_observations.
license: MIT
compatibility: opencode
---

# Memory Retrieval Skill (3-Layer Workflow)

Inspirado en claude-mem: búsqueda progresiva por tokens.

## Concepto: Progressive Disclosure

No cargar todo el contexto de una vez. Revelar información en capas según necesidad.

**Capa 1 (search):** ~50-100 tokens/resultado
**Capa 2 (timeline):** ~200 tokens/resultado
**Capa 3 (get):** ~500-1000 tokens/resultado

Ahorro: ~10x en tokens vs cargar todo.

## 3-Layer Workflow

### Capa 1: SEARCH

Busca en INDEX.md devuelve resultados compactos con IDs.

```bash
oc --memory "auth bug"
# Devuelve:
# obs_001 | 2026-05-01 | mi-api | bugfix | Fix JWT expiration
# obs_002 | 2026-05-01 | auth-svc | config  | Redis connection timeout
```

Formato:
```
obs_ID | date | project | type | summary
```

### Capa 2: TIMELINE

Obtiene contexto cronológico alrededor de una observación.

```bash
oc --memory --timeline obs_001
# Devuelve:
# obs_000 (10min antes) - "User reported auth failure"
# obs_001 (ahora)      - "Fix JWT expiration bug"
# obs_002 (10min después) - "Tests pass"
```

### Capa 3: GET_OBSERVATIONS

Carga detalle completo SOLO de IDs específicos.

```bash
oc --memory --get obs_001,obs_002
# Devuelve contenido completo de obs_001 y obs_002
```

## Formato de Observation

```markdown
---
id: obs_XXX
date: YYYY-MM-DD HH:MM:SS
project: nombre-proyecto
type: bugfix|feature|decision|note|config|refactor|review
summary: Título corto
tokens_est: 500
---

Contenido completo de la observación...

<private>
Este contenido es privado y no debe incluirse en resúmenes.
</private>
```

## Privacy Tags

Contenido entre `<private>` y `</private>` nunca se incluye en:
- Resúmenes
- Inyecciones de contexto
- Búsquedas

Solo acceso directo con `--get`.

## Comandos

```bash
# Capa 1: Search
oc --memory "query"                    # Búsqueda general
oc --memory -p proyecto "query"        # Filtrar por proyecto
oc --memory -t bugfix "query"          # Filtrar por tipo

# Capa 2: Timeline
oc --memory --timeline obs_ID           # Contexto cronológico

# Capa 3: Get full detail
oc --memory --get obs_ID1,obs_ID2      # Detalle completo

# Auto-capture
oc --remember "nota"                  # Crea nueva observación
oc --capture                          # Captura estado actual del proyecto
```

## Tipos de Observations

| Type | Descripción |
|------|-------------|
| bugfix | Fix de bug |
| feature | Nueva funcionalidad |
| decision | Decisión técnica (ADR) |
| note | Nota general |
| config | Cambio de configuración |
| refactor | Refactorización |
| review | Resultado de revisión |
| investigation | Investigación de problemas |
| success | Éxito notable |

## Búsqueda Avanzada

```bash
# Por proyecto
oc --memory -p mi-api "authentication"

# Por tipo
oc --memory -t bugfix "memory leak"

# Por fecha
oc --memory --since 2026-05-01 "performance"

# Combinados
oc --memory -p mi-api -t decision "database"
```