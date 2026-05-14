# Arquitectura — opencode-global-config

## Visión general

opencode-global-config es un **paquete de configuración** que se superpone a OpenCode CLI. No hace fork ni modifica OpenCode — funciona enteramente a través de archivos de configuración, definiciones de agentes y un script wrapper (`oc`).

```
┌─────────────────────────────────────────────────────────┐
│  User                                                    │
│    │                                                     │
│    ▼                                                     │
│  oc (wrapper script ~2490 líneas)                        │
│    │                                                     │
│    ├── Profile enforcement (prompt injection)            │
│    ├── Memory operations (3-layer retrieval)              │
│    ├── Workflow orchestration (single-pass)              │
│    ├── Natural language router (oc ask)                  │
│    └── Self-Improvement (auto-compact, auto-reflect)    │
│    │                                                     │
│    ▼                                                     │
│  opencode (CLI)                                          │
│    │                                                     │
│    ├── loads ~/.config/opencode/opencode.json           │
│    ├── loads AGENTS.md + CLAUDE.md as instructions      │
│    └── runs agents/skills/profiles                      │
└─────────────────────────────────────────────────────────┘
```

## Componentes principales

### `oc` — Wrapper Script

Script bash principal (~2490 líneas) que actúa como CLI unificada. Maneja:

| Función | Descripción |
|---------|-------------|
| `track_turn()` | Contador de sesiones con auto-tracking cada 5 turns |
| `auto_compact_if_needed()` | Auto-compact cuando turns > 20 |
| `detect_project()` | Auto-detecta proyecto desde PWD o git remote |
| `create_observation()` | Crea observaciones con frontmatter YAML |
| `search_memory()` | Búsqueda de 3 capas (search/timeline/get) |
| `get_profile_rules()` | Lee JSON y genera instrucciones LLM |
| `_oc_run()` | Ejecuta OpenCode con rules injectadas |
| `run_workflow()` | Orchestrates single-pass workflows |
| `ask_route()` | Natural language intent mapping |

### Agentes (11)

| Agente | Archivo | Permisos | Rol |
|--------|---------|----------|-----|
| `@architect` | `agents/architect.md` | read-only | Análisis arquitectura y riesgos |
| `@planner` | `agents/planner.md` | read-only | Planificación en fases verificables |
| `@builder` | `agents/builder.md` | edit + bash(ask) | Implementación con Karpathy principles |
| `@builder-safe` | `agents/builder-safe.md` | edit: ask, bash: ask | Implementación conservadora |
| `@reviewer` | `agents/reviewer.md` | read-only | Code review con precommit-review |
| `@security-auditor` | `agents/security-auditor.md` | read-only | Detección de vulnerabilidades |
| `@docs-writer` | `agents/docs-writer.md` | edit | Documentación técnica |
| `@devops` | `agents/devops.md` | edit + bash | Infraestructura, CI/CD, Docker |
| `@oncall` | `agents/oncall.md` | bash(ask) | Respuesta a incidentes con riesgo reversible |
| `@migration-planner` | `agents/migration-planner.md` | read-only | Migraciones incrementales reversibles |
| `@performance-profiler` | `agents/performance-profiler.md` | read-only | N+1, O(n²), I/O bloqueante |

### Profiles (9)

Gradiente deny-first: `deny → plan → review → default → work → research → auto → trusted → devops`

Cada perfil tiene:
- `opencode.permission` — matriz declarativa (validada por el repo)
- `policy` — reglas inyectadas como instrucciones LLM via `get_profile_rules()`

### Skills (10)

| Skill | Propósito |
|-------|-----------|
| `project-map` | Análisis de estructura de proyecto |
| `safe-implementation` | Cambios mínimos, verificables, reversibles |
| `test-first` | Goal-Driven Execution |
| `precommit-review` | Revisión de diff antes de commit |
| `memory-retrieval` | 3-layer progressive disclosure |
| `docs-writer` | Generación de documentación técnica |
| `diagnose` | Loop disciplinado de debugging |
| `grill-with-docs` | Alineación con docs antes de construir |
| `caveman` | Modo de comunicación comprimida |
| `ai-coding-rules` | Reglas de comportamiento para AI coding |

### Commands (8 slash commands)

`/analyze`, `/review`, `/secure`, `/feature`, `/bug-hunt`, `/docs`, `/devops`, `/oncall` — cargados automáticamente en el TUI de OpenCode.

### Plugins

`plugins/safety-guard.js` — Plugin ESM que:
- Bloquea comandos destructivos vía regex hardening
- Audit log a `~/.config/opencode/logs/safety-guard.jsonl`
- Redacción de secretos comunes (tokens, API keys, passwords)

## Flujos de datos

### Profile Enforcement

```
oc --profile trusted build "add feature"
  → switch_profile("trusted")
  → get_profile_rules() → genera instrucciones en inglés
  → _oc_run("-p", prompt + rules)
  → opencode run "Use @builder... [Active profile rules: ...]"
```

### Memory Lifecycle

```
oc --remember -p my-api -t bugfix "JWT fails on DST"
  → create_observation()
  → genera obs_id con timestamp + urandom
  → escribe markdown en memory/projects/my-api/
  → append a index.jsonl (python3 + json.dumps)
  → sync_to_project_docs() → copia a docs/memory/ del proyecto
```

### Workflow Single-Pass

```
oc --workflow bug-hunt ~/project
  → run_workflow("bug-hunt", "~/project")
  → _oc_run() con TODAS las fases en UN solo prompt
  → opencode ejecuta secuencialmente manteniendo contexto
  → run_workflow_prompt() exige status 0 y línea exacta WORKFLOW_COMPLETE=true
  → auto_reflect() post-workflow
  → track_outcome() registra resultado
  → analyze_outcomes() detecta patterns
```

Si falta el marcador exacto `WORKFLOW_COMPLETE=true` o `opencode` termina con status distinto de cero, el workflow falla y no registra outcome exitoso.

## Decisiones técnicas

### ¿Por qué prompt injection para perfiles?

OpenCode no tiene sistema de perfiles nativo. Las reglas se injectan como instrucciones LLM explícitas:
- No requiere fork de OpenCode
- Funciona con cualquier modelo
- Es transparente (reglas visibles en prompt)

### ¿Por qué single-pass workflows?

Sistemas multi-agente tradicionales llaman a OpenCode múltiples veces con gaps de timeout. Single-pass envía todas las fases en una llamada `opencode run`, manteniendo contexto completo.

### ¿Por qué memoria basada en archivos?

- Compatible con control de versiones
- Editable directamente por humanos
- No requiere servicio externo
- Funciona offline

### ¿Por qué ESM para safety-guard?

Node.js emite `MODULE_TYPELESS_PACKAGE_JSON` cuando carga `.js` sin `package.json` hermano. Declarar `type: module` elimina este warning.

## Self-Improvement Agent

### Funciones automáticas

| Función | Trigger | Comportamiento |
|---------|---------|----------------|
| `detect_project()` | Siempre | Auto-detecta proyecto desde PWD o git remote |
| `auto_compact_if_needed()` | Cada `_oc_run()` si turns > 20 | Compacta sesión silenciosamente con guard `OC_AUTO_COMPACT_RUNNING` para evitar recursión |
| `auto_reflect()` | Post-workflow | Crea observación en proyecto correcto |
| `track_outcome()` | Post-workflow | Registra resultado en memory/outcomes/ |
| `analyze_outcomes()` | Post-workflow | Detecta patterns de failures (3+ = warning) |

### Automation Flow

```
oc --workflow bug-hunt ~/project
  → run_workflow() ejecuta con todas las fases
  → detect_project("~/project") → "project"
  → Workflow completa → auto_reflect("bug-hunt", "~/project")
  → track_outcome("bug-hunt", "success", "project")
  → analyze_outcomes() → si 3+ failures en 7 días, warn
  → auto_compact_if_needed() → si turns > 20, summary + reset
```

## Tecnologías y dependencias

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| Wrapper CLI | Bash | `oc` script principal |
| Plugin seguridad | JavaScript ESM | safety-guard.js |
| Generación config | Python 3 | JSON/YAML en memoria |
| Validación | Shell + Python | validate.sh, tests/ |
| CI/CD | GitHub Actions | validate.yml |
| Install/ uninstall | Bash | install.sh, uninstall.sh |
