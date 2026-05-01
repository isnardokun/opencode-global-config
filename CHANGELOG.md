# Changelog

Todos los cambios notables de este proyecto se documentarán en este archivo.

## [1.5.0] - 2026-05-01

### Agregado

#### Workflow System
Sistema de workflows que encadenan agentes en secuencia:

| Workflow | Fases | Agentes |
|----------|-------|---------|
| `bug-hunt` | 5 | architect → security-auditor → planner → builder → reviewer |
| `new-project` | 4 | architect → planner → builder → docs-writer |
| `debug` | 3 | oncall → builder → security-auditor |
| `document` | 3 | architect → docs-writer → reviewer |
| `feature` | 4 | architect → planner → builder → reviewer |

#### Comandos
```bash
oc --workflow bug-hunt ~/proyecto
oc --workflow new-project "mi-api"
oc --workflow debug "fix error"
oc --workflow document ~/proyecto
oc --workflow feature "add auth" ~/proyecto
oc --workflow --interactive bug-hunt ~/proyecto  # Con confirmación entre fases
```

#### Modo Interactivo
`--interactive` flag para pedir confirmación entre fases.

#### Workflows Custom
Sistema extensible via `~/.config/opencode/workflows/<nombre>.json`

## [1.4.0] - 2026-05-01

### Agregado

#### Memory Retrieval Skill (3-Layer Workflow)
Inspirado en claude-mem (70.7k stars):
- **Capa 1: search** - Resultados compactos con IDs (~50-100 tokens)
- **Capa 2: timeline** - Contexto cronológico (~200 tokens)
- **Capa 3: get_observations** - Detalle completo (~500-1000 tokens)
- **~10x token savings** vs cargar todo de una vez

#### Observation Format
```markdown
---
id: obs_XXX
date: 2026-05-01 14:30:00
project: mi-api
type: bugfix|feature|decision|note|config|refactor|review
summary: Título corto
tokens_est: 500
---

Contenido completo...
```

#### Privacy Tags
`<private>...</private>` excluye contenido de resúmenes y búsquedas.

#### Auto-capture Functions
- `generate_obs_id()` - Genera IDs únicos
- `create_observation()` - Crea observation files
- `search_memory()` - Búsqueda con filtros
- `get_observations()` - Carga detalles por ID
- `get_timeline()` - Contexto cronológico
- `capture_session()` - Captura estado de sesión

#### Observation Types
- bugfix, feature, decision, note, config
- refactor, review, investigation, success

### Modificado

- Script `oc` ahora tiene 3-layer memory retrieval integrado
- Help actualizado con nuevos comandos de memory

## [1.3.0] - 2026-05-01

### Agregado

#### 7 Perfiles con Deny-First Gradient
Inspirado en Claude Code's 7 permission modes:
- `deny.json` - Solo análisis estático
- `plan.json` - Planificación sin modificar
- `review.json` - Lectura y análisis
- `default.json` - Desarrollo general con aprobación
- `auto.json` - ML classifier approval automation
- `trusted.json` - Desarrollador avanzado con checkpoints
- `devops.json` - Infraestructura con rollback

#### Context Budget Tracking
- Turns counter en sesión
- `oc --budget` para ver uso
- `oc --compact` para ejecutar compaction pipeline
- 5-layer compaction inspirada en Claude Code

#### Reversibility-Weighted Risk (@oncall)
- Tabla de acciones por reversibilidad
- Jerarquía de mitigación
- P1/P2/P3 clasificación de incidentes

#### Memory Bank Mejorado
- Header-based retrieval (no vector DB)
- INDEX.md para búsqueda rápida
- Arquitectura de 5 capas documentada

### Modificado

- @oncall ahora incluye tabla de reversibilidad
- Script `oc` ahora tracks turns y budget
- AGENTS.md actualizado con nuevas reglas

## [1.2.0] - 2026-05-01

### Modificado

- Integración de 4 principios de Karpathy:
  - Think Before Coding
  - Simplicity First
  - Surgical Changes
  - Goal-Driven Execution

- builder.md: Simplicity test, surgical changes rules
- planner.md: Success criteria con verificación
- test-first/SKILL.md: Goal-driven execution transformaciones

## [1.1.0] - 2026-05-01

### Agregado

- Modo wizard interactivo
- Menú con fzf
- Sistema de Memory Bank
- Souls/Personas
- 3 perfiles configurables (work, research, devops)
- Git hooks (pre-commit, pre-push)
- Comandos rápidos (oc-analyze, oc-plan, etc)
- Sistema oc init para proyectos

### Modificado

- Script oc mejorado con múltiples flags
- Errores con colores
- Verificación de dependencias

## [1.0.0] - 2026-05-01

### Agregado

- 8 agentes custom: architect, planner, builder, reviewer, security-auditor, docs-writer, devops, oncall
- 4 skills: project-map, safe-implementation, test-first, precommit-review
- Plugin: safety-guard.js
- Comando global: oc
- opencode.json
- AGENTS.md con reglas globales
- Documentación completa