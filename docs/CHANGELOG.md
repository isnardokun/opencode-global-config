# Changelog — opencode-global-config

## [1.9.6] - 2026-05-10

### Self-Improvement Agent — Automatización Total

- **`oc`** — `detect_project()` auto-detecta el proyecto desde PWD o git remote
- **`oc`** — `auto_compact_if_needed()` se ejecuta automáticamente cuando turns > 20
- **`oc`** — `auto_reflect()` crea observación automáticamente post-workflow
- **`oc`** — `analyze_outcomes()` detecta patterns de failures (3+ = warning)
- **`oc --status`** — muestra proyecto actual además de turns, perfil, hooks
- **`oc --budget`** — indica threshold de auto-compact (20 turns)

### Memory Bank — Templates

- Templates para `oc --remember`: `bugfix`, `decision`, `feature`, `config`
- `oc --list-templates` para listar templates disponibles

### Seguridad y confiabilidad

- `safety-guard.js` — bloquea `rm -rf` con variantes `$HOME`, `${HOME}`, subpaths críticos
- `track_turn` — recuperación de `.session` corrupto
- `oc --memory` — búsquedas multi-palabra sin flags

## [1.9.5] - 2026-05-03

### Harness Engineering — Exit Conditions y Observabilidad

- **`oc`** — EXIT_CONDITIONS en los 5 workflows con límites de agent turns
- **`oc`** — `oc --status` muestra session turns, profile, hooks, última observación
- **`agents/manifest.json`** — agent cards para descubrimiento y orquestación

## [1.9.4] - 2026-05-02

### Release Readiness

- Smoke tests funcionales ampliados
- Rubrics reutilizables (code-review, security-review, plan-review)
- `oc --init` genera hooks fail-closed

## [1.9.3] - 2026-05-01

### Compatibilidad OpenCode 1.14

- `_oc_run()` migrado a `opencode run`
- Perfil `auto.json` corregido (`edit: auto` → `edit: ask`)

## [1.9.0] - 2026-05-01

### Permisos nativos OpenCode

- opencode.json reescrito con permisos nativos
- 3 nuevos agentes: migration-planner, performance-profiler, builder-safe
- 8 slash commands nativos