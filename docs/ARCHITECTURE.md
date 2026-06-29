# Arquitectura — opencode-global-config

> **Nota:** Este archivo documenta la arquitectura técnica. Para decisiones, contexto, y bitácora, ver `DECISIONS.md`, `PROJECT_CONTEXT.md`, y `CONTEXTO_PROYECTO.md` (raíz).

## Visión general

opencode-global-config es un **paquete de configuración** que se superpone a OpenCode CLI. No hace fork ni modifica OpenCode — funciona enteramente a través de archivos de configuración, definiciones de agentes, un script wrapper (`occo`), y un sistema de memoria persistente.

```
┌─────────────────────────────────────────────────────────────┐
│  User                                                        │
│    │                                                         │
│    ▼                                                         │
│  occo (wrapper bash, ~106 KB / 2965 líneas)                   │
│    │                                                         │
│    ├── Profile enforcement (prompt injection, 9 perfiles)    │
│    ├── Memory operations (3-layer retrieval, JSONL)          │
│    ├── Workflow orchestration (5 single-pass workflows)       │
│    ├── Natural language router (occo ask)                    │
│    ├── Self-Improvement (auto-compact, auto-reflect)         │
│    ├── Hooks management (occo --init)                       │
│    └── Slash command runner (occo <command>)                 │
│    │                                                         │
│    ▼                                                         │
│  opencode (CLI)                                              │
│    │                                                         │
│    ├── loads ~/.config/opencode/opencode.json               │
│    ├── loads AGENTS.md + CLAUDE.md as instructions          │
│    ├── loads skills/ (22), commands/ (14), agents/ (11)     │
│    ├── loads plugins/safety-guard.js (ESM)                  │
│    └── runs agents, executes slash commands                  │
└─────────────────────────────────────────────────────────────┘
```

## Componentes principales

### `occo` — Wrapper Script

Script bash principal (~106 KB, 2965 líneas) instalado en `~/.local/bin/occo`. Funciones principales:

| Función | Descripción |
|---------|-------------|
| `track_turn()` | Contador de sesiones con persistencia en `~/.config/opencode/.session` |
| `auto_compact_if_needed()` | Auto-compact cuando turns > 20 (configurable) |
| `detect_project()` | Auto-detecta proyecto desde PWD o git remote |
| `create_observation()` | Crea observaciones con frontmatter YAML quoting |
| `search_memory()` | Búsqueda de 3 capas (search/timeline/get) |
| `get_profile_rules()` | Lee JSON y genera instrucciones LLM en inglés |
| `run_workflow_prompt()` | Orchestrates single-pass workflows (bug-hunt, new-project, etc.) |
| `ask_route()` | Natural language intent mapping a agentes/workflows |
| `safety_guard_validate()` | Verifica el plugin safety-guard.js antes de cargar |
| `doctor` | Diagnóstico completo del sistema |

Entry points:
- `occo` (sin args) — menú interactivo fzf o help
- `occo <command>` — comando explícito (analyze, review, secure, etc.)
- `occo ask "<prompt>"` — natural language router
- `occo --workflow <name>` — single-pass workflow
- `occo --remember "..."` — crear observación de memoria
- `occo --memory "query"` — buscar en memoria
- `occo --init [path]` — inicializar proyecto con `.opencode/`
- `occo --doctor` — diagnóstico
- `occo --compact` — forzar compactación

### Agentes (11)

| Agente | Permisos | Skills cargadas | Rol |
|--------|----------|-----------------|-----|
| `@architect` | read-only | project-map | Análisis, stack, riesgos |
| `@planner` | read-only | plan-eng-review | Planes con criterios de éxito verificables |
| `@builder` | edit + bash(ask) | safe-implementation, test-first | Implementación con principios Karpathy |
| `@builder-safe` | edit: ask, bash: ask | safe-implementation | Implementación conservadora |
| `@reviewer` | read-only | precommit-review | Code review con precommit-review |
| `@security-auditor` | read-only | — | Auditoría de seguridad OWASP |
| `@docs-writer` | edit | docs-writer | Documentación técnica |
| `@devops` | edit + bash | — | Docker, CI/CD, infra |
| `@oncall` | bash(ask) | investigate | Producción, debug, logs |
| `@migration-planner` | read-only | — | Migraciones reversibles |
| `@performance-profiler` | read-only | — | N+1, O(n²), I/O bloqueante |

### Slash Commands (14)

| Comando | Skill | Agente |
|---------|-------|--------|
| `/analyze` | project-map | @architect |
| `/review` | precommit-review | @reviewer |
| `/secure` | — | @security-auditor |
| `/feature` | workflow: architect → planner → builder → reviewer | multi |
| `/bug-hunt` | workflow: architect → security-auditor → planner → builder → reviewer | multi |
| `/docs` | docs-writer | @docs-writer |
| `/devops` | — | @devops |
| `/oncall` | — | @oncall |
| `/office-hours` | office-hours | @planner |
| `/investigate` | investigate | @oncall |
| `/plan-eng-review` | plan-eng-review | @planner |
| `/qa-web` | qa-web | @builder + @reviewer |
| `/web-verify` | web-verify | runtime-agnostic |
| `/setup-deploy` | setup-deploy | detect-only |

### Skills (22)

**Originales (11):** ai-coding-rules, caveman, design-md, diagnose, docs-writer, grill-with-docs, memory-retrieval, precommit-review, project-map, safe-implementation, test-first.

**Cherry-pick de garrytan/gstack (6):** plan-eng-review, office-hours, investigate, qa-web, web-verify, setup-deploy. (v1.11.0)

**Cherry-pick de anthropics/skills (4):** pdf, skill-creator, docx, xlsx. (v1.12.0 – v1.14.0)

**Cherry-pick de safishamsi/graphify (1):** graphify. (v1.15.0)

### Perfiles (9 — deny-first gradient)

```
deny → plan → review → default → work → research → auto → trusted → devops
```

| Perfil | Permisos | Cuándo usar |
|--------|----------|-------------|
| `deny` | Solo lectura estática | Análisis pasivo, no ediciones |
| `plan` | Lectura + planning, no edición | Diseñar antes de tocar código |
| `review` | Lectura + revisión | Code review, auditoría |
| `default` | Desarrollo general con aprobación | Uso cotidiano |
| `work` | Trabajo profesional conservador | Implementación con gates |
| `research` | Investigación con web habilitada | Búsquedas online |
| `auto` | Modo asistido con tracking | Decisiones autónomas |
| `trusted` | Direct edits, bash permitido | Desarrollador avanzado |
| `devops` | Infraestructura con rollback | Deploy, CI/CD |

### Rubrics (4)

- `code-review.md` — blocking criteria, required evidence, output shape, Pass 1 CRITICAL (5 checks), Pass 2 INFORMATIONAL (7 checks), Fix-First Heuristic
- `security-review.md` — severity levels, remediation gates
- `plan-review.md` — verifiable planning and design criteria
- `grilling.md` — alignment/grilling gates para design discussions

### Plugin: `safety-guard.js` (ESM)

Localizado en `plugins/safety-guard.js`. Función:
- Bloquea comandos destructivos via regex (con hardened variants)
- Audita cada bash call a `~/.config/opencode/logs/safety-guard.jsonl`
- Redacta secretos conocidos (GITHUB_TOKEN, OPENAI_API_KEY, NPM_TOKEN, etc.)
- Lock permissions: log dir 0700, log file 0600

### Hooks git: `pre-commit` + `pre-push`

Fail-closed. Lógica:
1. Lee el diff (staged o contra upstream)
2. Pasa al LLM via `occo` o fallback `opencode run`
3. LLM responde con `HOOK_REVIEW_RESULT=pass|fail`
4. El hook permite o bloquea según la última línea exacta
5. Opcionalmente corre `gitleaks` si está instalado
6. Exit 0 = allow, exit !=0 = block

### Memory System

- `~/.config/opencode/memory/INDEX.md` — índice markdown para humanos
- `~/.config/opencode/memory/index.jsonl` — índice JSONL para queries
- `~/.config/opencode/memory/projects/<name>/*.md` — observaciones por proyecto
- `~/.config/opencode/memory/outcomes/*.json` — outcomes de workflows
- 3-layer retrieval: search (resúmenes), timeline (cronología), get (contenido completo)

### `install.sh` — Instalador

Flags disponibles:
- `--dry-run` — print plan sin modificar nada
- `--with-playwright` — opt-in: instala Playwright + Chromium (~170 MB), registra skill, sin auto-build
- `--with-graphify` — opt-in: instala graphifyy via uv/pipx/pip (~50 MB), registra skill en opencode, auto-graphify de `~/.config/opencode/`
- `--help` / `-h` — usage documentado

El base install es zero-deps (solo `cp -r` de archivos). Playwright y graphify son opt-in explícitos.

## Validación

`validate.sh` corre:

1. Required files/directories existen
2. Required agents (11), commands (14), skills (22), rubrics (4)
3. JSON syntax (perfiles, opencode.json, plugins/package.json)
4. Shell syntax (install.sh, uninstall.sh, hooks, occo)
5. Plugin JavaScript syntax (`node --check`)
6. Custom linter:
   - No hardcoded secrets/credentials (con whitelist para `qpdf|gpg|openssl`)
   - TODOs requieren issue ref
7. Frontmatter check (presence of `---` fences)
8. Documentation consistency (version match, profile/agent/skill counts)
9. Memory project flag support
10. Legacy CLI calls (no `opencode -p` o `opencode --profile`)

`tests/run.sh` corre 14 smoke tests:
- Memory search/parse/filter
- `--remember` creation con JSONL válido
- Timeline lookup
- Profile switching (clean names, reject invalid)
- Hooks fail-closed behavior
- `occo --init` genera hooks fail-closed
- `occo --compact` resetea counter
- Workflow success requiere `WORKFLOW_COMPLETE=true`
- Session tracking handles clean and corrupt state
- `occo ask` dry-run routes natural language
- `occo --doctor`/`--installed` validation
- `occo dashboard --apply` parameter order
- Installer dry-run y uninstaller con temp paths
- Safety guard blocks critical rm variants, redacts secrets, locks log permissions
