# opencode-global-config — Project Context

## Resumen

Configuración global avanzada para OpenCode CLI (`~/.config/opencode/`). Paquete de configuración que agrega agentes especializados, perfiles prompt-enforced, slash commands nativos, skills de implementación, plugin de seguridad, scripts de instalación/validación y sistema de memoria persistente.

## Problema que resuelve

OpenCode CLI viene sin configuración por defecto. Este proyecto resuelve:

- **Agentes especializados** — 11 agentes predefinidos (architect, planner, builder, reviewer, security-auditor, docs-writer, devops, oncall, migration-planner, performance-profiler, builder-safe) sin hardcoded model
- **Perfiles de confianza** — 9 perfiles con gradiente deny-first que controlan permisos de forma declarativa
- **Workflows automatizados** — 5 pipelines single-pass (bug-hunt, new-project, debug, document, feature)
- **Memoria persistente** — Sistema de 3 capas (search/timeline/get) con sincronización a proyecto local
- **Self-Improvement Agent** — Auto-detección de proyecto, auto-compact a las 20 turns, auto-reflect post-workflow

## Stack tecnológico

- **Shell:** Bash (~2226 líneas el script `oc`)
- **JavaScript/ESM:** Plugins (safety-guard.js)
- **Python 3:** Generación de JSON, YAML quoting, validación de memoria
- **JSON:** Perfiles, configuración OpenCode, index de memoria
- **Markdown:** Agentes, skills, rubrics, documentación
- **Git hooks:** pre-commit + pre-push

## Equipo

Proyecto mantenido por @isnardokun. GitHub: https://github.com/isnardokun/opencode-global-config

### Contribuidores

- Solo mantenenedor principal
- CI/CD via GitHub Actions (`.github/workflows/validate.yml`)

## Estructura del repositorio

```
opencode-global-config/
├── oc                        # Wrapper script principal (~2226 líneas)
├── VERSION                   # "1.9.6"
├── opencode.json             # Config nativo OpenCode
├── opencode.strict.json      # Modo paranoid
│
├── agents/                   # 11 agentes (markdown + YAML frontmatter)
├── commands/                 # 8 slash commands para TUI
├── skills/                   # 6 skills (project-map, safe-implementation, etc.)
├── profiles/                 # 9 perfiles deny-first
├── rubrics/                  # 3 gates reutilizables
├── plugins/                  # safety-guard.js (ESM)
├── hooks/                    # Git hooks (pre-commit, pre-push)
├── souls/                    # Personas predefinidas
├── memory/                   # Sistema de memoria (INDEX.md, projects/, outcomes/)
├── workflows/                # Workflows single-pass
│
├── tests/run.sh              # Smoke tests funcionales
├── validate.sh               # Validador completo
├── install.sh                # Instalador con --dry-run
├── uninstall.sh              # Desinstalador seguro
├── Makefile                  # Targets: check, test, install, doctor
│
├── .github/workflows/        # CI: validate.sh + shellcheck
├── AGENTS.md                 # Reglas globales + intent mapping
├── CLAUDE.md                 # System prompt compacto
├── README.md                 # Documentación inglés
├── README.es.md              # Documentación español
├── INSTALL.md                # Guía de instalación
├── CHANGELOG.md              # Historial de releases
├── CONTEXTO_PROYECTO.md      # Bitácora viva
└── docs/                     # Docs-First auto-creado para proyectos
```

## Estado actual

El proyecto está en **producción estable** (v1.9.6). Todas las funcionalidades documentadas están implementadas y validadas. El sistema de Self-Improvement Agent está activo y funcional.

## Última versión

**v1.9.6** (2026-05-10) — Self-Improvement Agent con automatización total.