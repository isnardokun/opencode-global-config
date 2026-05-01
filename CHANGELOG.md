# Changelog

Todos los cambios notables de este proyecto se documentarán en este archivo.

## [1.7.0] - 2026-05-01

### Fixes críticos (`oc` script)

- **Eliminado `set -e`** — causaba exit silencioso cuando `search_memory`/`check_budget` retornaban 1 (señal "no encontrado")
- **Corregido `local` fuera de función** en bloques `--workflow`, `--type`, `--remember`, `--memory` del `case` — generaba `bash: local: can only be used in a function`
- **Corregido workflow `feature`** — `feature_desc` capturaba el flag `--interactive` en lugar de la descripción; dispatcher ahora pasa 4 argumentos correctamente
- **Corregido `run_interactive`** — fzf parsing extraía `║` del ASCII art del menú; reemplazado por lista limpia donde `awk '{print $1}'` extrae la letra de opción
- **Corregido `generate_obs_id`** — `head -c 12` truncaba a `YYYYMMDD-HH` causando colisiones por hora; ahora timestamp completo + 4 bytes de `/dev/urandom`
- **Eliminado placeholder `<private>` falso** — cada observación creada incluía boilerplate vacío "Contenido sensible aqui"

### Mejoras funcionales

- **Perfiles funcionales** — `switch_profile` exporta `OPENCODE_PROFILE`; wrapper `_oc_run()` propaga perfil activo a todos los comandos (`quick_*`, `run_agent`, workflows)
- **`check_deps` simplificado** — `opencode` requerido al startup; `fzf` verificado solo al usar `--interactive`
- **Workflows single-pass implementados** — un único prompt por workflow con todas las fases; el agente mantiene contexto completo sin timeout inter-fases
- **`--compact` honesto** — resetea contador de turns y advierte que el resumen manual es necesario para sesiones largas (no simula pipeline inexistente)

### Seguridad (`safety-guard.js`)

- **Reemplazado substring matching por regex** con normalización de whitespace — `rm  -rf /` (espacios extra) y `rm -r -f /` ahora bloqueados
- **Ampliados patrones bloqueados** — escritura directa a discos (`> /dev/sda`), truncado de archivos críticos (`> /etc/passwd`, `/etc/shadow`, `/etc/sudoers`, `/etc/hosts`), `chmod -R` world-writable en paths de sistema

### Documentación

- **Añadido docs-writer skill** — skill de documentación técnica para generar README, ARCHITECTURE, API y DEPLOY
- **Corregido "6 skills" → 6 skills** — ahora con docs-writer skill incluido
- **Eliminada tabla de compaction ficticia** — reemplazada por descripción honesta del contador de turns
- **Actualizada sintaxis `--workflow feature`** — documenta los 2 argumentos obligatorios (descripción + path)
- **Changelog honesto** — separado lo que v1.6 documentó vs lo que v1.7 realmente implementó

### Modificado

#### Automatic Single-Pass Workflows
- **Problema**: Workflows ejecutaban múltiples llamadas `opencode run` con timeout de 60s por fase
- **Solución**: Un solo `opencode run` con todas las fases codificadas en el prompt
- **Resultado**: workflows ejecutan 3-5 fases en ~3-5 min sin timeout

```bash
# Antes (timeout por fase)
oc --workflow document ~/proyecto  # fallaba en fase 2

# Ahora (single-pass)
oc --workflow document ~/proyecto  # ✅ completa en ~3min
```

#### 5 Workflows Actualizados
- `bug-hunt`: architect → security → planner → builder → reviewer
- `new-project`: architect → planner → builder → docs
- `debug`: oncall → builder → security
- `document`: architect → docs-writer → reviewer
- `feature`: architect → planner → builder → reviewer

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