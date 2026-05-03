# Changelog

Todos los cambios notables de este proyecto se documentarán en este archivo.

## [Unreleased] - Bug-hunt hardening

### Seguridad y confiabilidad

- **`plugins/safety-guard.js`** — bloquea variantes destructivas adicionales de `rm -rf` con `$HOME`, `${HOME}`, rutas HOME entrecomilladas, subpaths críticos absolutos (`/home/*`, `/etc/*`, `/var/*`, `/root/*`) y separadores shell posteriores al target.
- **`oc`** — `track_turn` crea el directorio de configuración si falta y se recupera de `.session` corrupto/no numérico.
- **`oc --memory`** — búsquedas multi-palabra sin flags usan toda la query en lugar de interpretar palabras extra como proyecto/tipo posicional.
- **`install.sh`** — usa `mktemp -d` para workspace temporal y matching de PATH delimitado por `:`.
- **`uninstall.sh`** — solo muestra instrucciones de restore cuando realmente se creó backup.
- **`tests/run.sh`** — agrega regresiones para safety guard, memoria multi-palabra, sesión corrupta, instalador y uninstall sin backup.

## [1.9.4] - 2026-05-02

Release de hardening y readiness: smoke tests funcionales ampliados, gates reutilizables por rubrics, validación instalada más estricta y documentación alineada al comportamiento real.

### Tests y validación

- **`tests/run.sh`** — amplía smoke tests funcionales para memory parser, `--remember -p/-t`, timeline, perfiles, hooks fail-closed, `oc --init`, `--compact`, `--doctor`, `validate.sh --installed`, `install.sh --dry-run` y `safety-guard.js`.
- **`Makefile`** — `check` valida hooks y `plugins/package.json`; `test` ejecuta la suite funcional.
- **`validate.sh`** — agrega consistencia documental: `VERSION`, conteo real de perfiles/agentes/skills y presencia de soporte documentado para memory project flags.
- **`.github/workflows/validate.yml`** — ejecuta smoke tests funcionales en CI.
- **`rubrics/`** — agrega gates formales para code review, security review y plan review; `validate.sh` verifica los archivos requeridos.

### Seguridad

- **Hooks Git** — integran `gitleaks` de forma opcional si está disponible; si no existe, mantienen flujo actual sin romper entornos locales.
- **`plugins/safety-guard.js`** — audit log con permisos restrictivos y redacción ampliada para headers, flags, URLs con credenciales y tokens comunes.
- **`plugins/package.json`** — declara `type: module` para cargar el plugin ESM sin warning `MODULE_TYPELESS_PACKAGE_JSON`.

### CLI y documentación

- **`oc ask`** — agrega router opcional de lenguaje natural con `--dry-run`, `--explain` y `--clarify`; asigna agentes/workflows sin quitar comandos explícitos.
- **`oc`** — soporta `--remember -p project` y `--memory -p project -t type`; `oc --init` genera `pre-commit` y `pre-push` fail-closed.
- **`VERSION`** — añade fuente simple de versión actual para validaciones.
- **Docs** — alinea conteos visibles a 9 perfiles y registra `CONTEXTO_PROYECTO.md` como bitácora viva.
- **Agentes reviewer/security/planner** — referencian rubrics reutilizables para exigir evidencia, severidad y criterios de éxito verificables.

## [1.9.3] - 2026-05-01

### Compatibilidad OpenCode 1.14

- **`oc` — `_oc_run()` migrado a `opencode run`** — `opencode -p` fue removido en OpenCode 1.14; sin este fix todos los perfiles y hooks estaban silenciosamente rotos en producción
- **`oc` — eliminado `opencode --profile`** — no soportado por OpenCode; perfiles aplicados exclusivamente por prompt injection en `_oc_run()`
- **`hooks/pre-commit`, `hooks/pre-push`** — migrados a `opencode run`

### Fixes

- **`profiles/auto.json`** — `edit: auto, bash: auto` → `edit: ask, bash: ask`; `auto` nunca fue valor válido (`ask|allow|deny` son los únicos valores permitidos)
- **`install.sh --dry-run`** — ahora sale inmediatamente tras mostrar el plan; antes ejecutaba verificaciones primero, violando el contrato de dry-run
- **`install.sh`** — banner actualizado a v1.9.1

### Validación

- **`validate.sh`** — detecta llamadas legacy `opencode -p` / `opencode --profile`; validator Python valida acciones de permisos contra `ask|allow|deny`; `opencode.strict.json` incluido en validación JSON
- **`.github/workflows/validate.yml`** — shellcheck en `validate.sh`; artifact scan extendido a `skills/`
- **`README.md`, `README.es.md`, `INSTALL.md`** — conteos correctos, comandos obsoletos removidos, snippets corregidos

## [1.9.2] - 2026-05-01

### validate.sh hardening

- **Line count sanity check** — falla si scripts críticos tienen menos de 5 líneas; detecta minificación accidental
- **Markdown frontmatter validation** — verifica YAML multilínea en todos los `agents/*.md` y `commands/*.md`
- **Artifact scan extendido** — cubre `skills/`; agrega patrón `发现问题`

### Makefile

- **Target `format`** — `shfmt` en todos los scripts shell + `jq` para re-formatear configs JSON
- **Target `check`** — agrega `jq empty opencode.strict.json`

## [1.9.1] - 2026-05-01

### Herramientas de desarrollo

- **`.editorconfig`** — UTF-8, LF, 2 espacios, final de línea, sin trailing whitespace
- **`Makefile`** — targets: `validate`, `check`, `install`, `dry-run`, `uninstall`, `doctor`
- **`opencode.strict.json`** — perfil paranoid: `webfetch: deny`, `websearch: deny`, `external_directory: deny`
- **`agents/builder-safe.md`** — nuevo agente conservador con `edit: ask, bash: ask`; misma lógica que `@builder` pero confirma antes de cada edición

## [1.9.0] - 2026-05-01

### Permisos nativos OpenCode

- **`opencode.json` reescrito** — permisos nativos: `read/list/glob/grep: allow`, `edit/bash/webfetch/websearch: ask`, `autoupdate: false`, `watcher.ignore` completo
- **Perfiles reestructurados** — separación limpia entre `opencode.permission` (OpenCode nativo) y `policy` (reglas inyectadas en prompt)

### Nuevos agentes

- **`agents/migration-planner.md`** — diseño de migraciones incrementales reversibles; solo lectura (`edit: deny, bash: deny`); tabla de riesgos, fases, rollback por fase
- **`agents/performance-profiler.md`** — detección de N+1, O(n²), I/O bloqueante, índices faltantes; severidad CRITICAL/HIGH/MEDIUM/LOW; solo lectura

### Slash commands nativos

- **`commands/` (8 archivos)** — analyze, review, secure, feature, bug-hunt, docs, devops, oncall; carga automática en OpenCode TUI sin wrapper `oc`

### Infraestructura

- **`validate.sh`** — valida estructura (15 ítems), 11 agentes, 8 comandos, 6 skills, JSON, bash syntax, sin modelos hardcodeados, sin artifacts de idioma; flag `--installed`
- **`uninstall.sh`** — remoción segura con backup a `opencode.removed.TIMESTAMP`
- **`install.sh --dry-run`** — simula instalación sin modificar nada
- **`plugins/safety-guard.js`** — audit log: cada comando bash logueado a `~/.config/opencode/logs/safety-guard.jsonl`
- **`oc --doctor`** — diagnóstico: verifica opencode, oc, config, dirs, JSON, fzf, perfil, audit log
- **`.github/workflows/validate.yml`** — CI: validate.sh, shellcheck, sin modelo hardcodeado, sin artifacts de idioma
- **`README.md` y `README.es.md`** — bilingüe; documentación completa de v1.9

### Limpieza

- **Eliminado `model:` de 8 agentes** — opencode usa el modelo seleccionado por el usuario en UI
- **Artifacts de idioma corregidos** — `No容忍` → `Zero tolerance`, `基础设施` → `Infrastructure`, `средний` → `medium`, `密码` eliminado, `迁移` → `migration`
- **`memory/ARCHITECTURE.md` reescrito** — eliminada tabla de compaction ficticia de 5 capas; descripción honesta del sistema real

## [1.8.0] - 2026-05-01

### Cross-platform & hardening

#### install.sh
- **Añadido `trap 'rm -rf "$INSTALL_DIR"' EXIT`** — limpieza garantizada incluso si el script falla a mitad
- **Eliminado `set -e`** — reemplazado por chequeos explícitos con mensajes de error claros
- **Rutas absolutas en opencode.json** — el script genera el archivo con `$HOME` expandido en lugar de copiar `~` literal que JSON no expande
- **Soporte macOS completo** — detecta y actualiza `.bash_profile` (bash en macOS), `.zshrc` (zsh, default desde Catalina), `.bashrc` (Linux), y `fish/config.fish`
- **Verificación de instalación mejorada** — comprueba 5 artefactos (AGENTS.md, opencode.json, oc, agents/, skills/) en lugar de solo 2
- **Suprimido `2>/dev/null` en git clone** — los errores de red ahora son visibles

#### oc script
- **`generate_obs_id` usa `od` en lugar de `xxd`** — `od` es POSIX y disponible en Linux y macOS sin dependencias extras; `xxd` no está garantizado en todas las distros

#### CLAUDE.md
- **Eliminado artefacto `密码`** (chino, residuo de generación LLM)
- **Eliminada duplicación de intent mapping** — las tablas completas viven solo en AGENTS.md; CLAUDE.md ahora es un resumen compacto de 40 líneas
- **Desacoplamiento CLAUDE.md / AGENTS.md** — un solo lugar para actualizar el mapeo de intenciones

#### skills/docs-writer/SKILL.md
- **Corregidas code fences anidadas** — los templates de markdown usaban ` ```markdown ` con bloques ` ```bash ` internos sin escapar, rompiendo el renderizado en GitHub; reemplazados por bloques indentados con 4 espacios

#### INSTALL.md
- **Corregida sección "Actualización"** — `git pull` en `~/.config/opencode` no funciona (no es un repo git); reemplazado por one-liner del instalador o instrucciones manuales explícitas
- **Corregida sección "Desinstalación"** — glob `[ -d ~/.config/opencode.backup.* ]` no expande en `[ ]`; reemplazado por `ls -d` con `sort | tail -1`
- **Eliminados comandos inexistentes** — `opencode debug config` y `opencode agent list` reemplazados por `ls` sobre los directorios instalados
- **Corregida instalación manual** — `cp -r /tmp/opencode-config/*` copiaba archivos de docs (README, CHANGELOG) al config dir; ahora usa loop explícito sobre los directorios de config
- **Hints de fzf multi-distro** — instrucciones para apt (Ubuntu/Debian), dnf (Fedora), pacman (Arch), brew (macOS)
- **Añadida sección "opencode.json no carga agentes"** — con comando de regeneración de rutas

#### README.md
- **Quick Start reemplazado** — el `cp -r *` copiaba basura al config dir; ahora apunta al one-liner del instalador
- **Modo Natural clarificado** — ahora explica explícitamente que es dentro de sesión `opencode` interactiva, no un comando `oc`

## [1.7.0] - 2026-05-01

### Nuevas funcionalidades

- **Intent Mapping Natural Language → Agente**: El sistema ahora detecta automáticamente qué agente usar según el pedido del usuario. Ya no necesitas memorizar comandos.
- **Script de instalación automática** (`install.sh`): Instalación en un paso con backup automático de configuración previa.
- **Actualización de INSTALL.md**: Documentación completa de instalación, uso natural y solución de problemas.

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
