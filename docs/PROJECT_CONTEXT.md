# opencode-global-config — Project Context

## Resumen

Configuración global avanzada para OpenCode CLI (`~/.config/opencode/`). Paquete de configuración que agrega agentes especializados, perfiles prompt-enforced, slash commands nativos, skills de implementación, plugin de seguridad, scripts de instalación/validación y sistema de memoria persistente. Instalación zero-deps con flags opt-in para Playwright y graphify.

## Problema que resuelve

OpenCode CLI viene sin configuración por defecto. Este proyecto resuelve:

- **Agentes especializados** — 11 agentes predefinidos sin hardcoded model
- **Perfiles de confianza** — 9 perfiles con gradiente deny-first
- **Skills de implementación** — 22 skills (11 originales + 11 adaptadas de upstream)
- **Slash commands** — 14 comandos nativos para el TUI de OpenCode
- **Workflows automatizados** — 5 pipelines single-pass
- **Memoria persistente** — 3-layer retrieval (search/timeline/get)
- **Self-Improvement Agent** — auto-compact a 20 turns, auto-reflect post-workflow
- **Plugin de seguridad** — `safety-guard.js` (ESM, regex + audit log JSONL)
- **Git hooks fail-closed** — `pre-commit` y `pre-push` con gate LLM
- **Knowledge graph opt-in** — vía `install.sh --with-graphify` (safishamsi/graphify v8)

## Stack tecnológico

- **Shell:** Bash (`occo` wrapper, ~106 KB / 2965 líneas)
- **JavaScript/ESM:** Plugin `safety-guard.js`
- **Python 3:** JSONL index, YAML quoting, memoria validation
- **JSON:** Perfiles, OpenCode config, manifest registry
- **Markdown:** Agentes, skills, rubrics, comandos, documentación
- **Git hooks:** pre-commit + pre-push con `HOOK_REVIEW_RESULT=pass|fail`

### Opt-in (no incluidos en base install)

- **Playwright** (~170 MB) — para `/qa-web` y `/web-verify` tier 3-4
- **graphifyy** (~50 MB) — para knowledge graph de codebases
- **python-docx** — para `/docx` (ya instalado en este host, ~5 MB)
- **openpyxl** — para `/xlsx` (ya instalado en este host, ~5 MB)
- **pypdf, pdfplumber, reportlab, poppler-utils, qpdf** — para `/pdf`

## Equipo

Proyecto mantenido por @isnardokun. GitHub: https://github.com/isnardokun/opencode-global-config

### Contribuidores

- Solo mantenenedor principal
- CI/CD via GitHub Actions (`.github/workflows/validate.yml`)

## Estructura del repositorio

```
opencode-global-config/
├── occo                        # Wrapper script principal (~2965 líneas, v1.11+)
├── VERSION                     # "1.15.0"
├── opencode.json               # Config nativo OpenCode
├── opencode.strict.json        # Modo paranoid
│
├── agents/                     # 11 agentes (markdown + YAML frontmatter)
│   ├── architect.md            # Read-only
│   ├── planner.md              # Read-only, carga plan-eng-review
│   ├── builder.md              # Edit + bash(ask)
│   ├── builder-safe.md         # Edit: ask, bash: ask
│   ├── reviewer.md             # Read-only
│   ├── security-auditor.md     # Read-only
│   ├── docs-writer.md          # Edit
│   ├── devops.md               # Edit + bash
│   ├── oncall.md               # Bash(ask), carga investigate
│   ├── migration-planner.md    # Read-only
│   └── performance-profiler.md # Read-only
│
├── commands/                   # 14 slash commands
│   ├── analyze.md, review.md, secure.md, feature.md
│   ├── bug-hunt.md, docs.md, devops.md, oncall.md
│   ├── office-hours.md, investigate.md, plan-eng-review.md
│   ├── qa-web.md, web-verify.md, setup-deploy.md
│
├── skills/                     # 22 skills (11 originales + 11 adaptadas)
│   ├── Originales (11): ai-coding-rules, caveman, design-md, diagnose,
│   │   docs-writer, grill-with-docs, memory-retrieval, precommit-review,
│   │   project-map, safe-implementation, test-first
│   ├── gstack cherry-pick (6): plan-eng-review, office-hours, investigate,
│   │   qa-web, web-verify, setup-deploy
│   ├── anthropics cherry-pick (4): pdf, skill-creator, docx, xlsx
│   └── graphify cherry-pick (1): graphify
│
├── profiles/                   # 9 perfiles deny-first
├── rubrics/                    # 4 rubrics: code-review, security-review, plan-review, grilling
├── plugins/safety-guard.js     # ESM, regex + audit log JSONL
├── hooks/                      # pre-commit + pre-push fail-closed
├── memory/                     # Sistema de memoria (INDEX.md, projects/, outcomes/)
├── souls/                      # Personas predefinidas
│
├── agents/manifest.json        # Registry machine-readable
├── skills-registry.json        # Skills universales con atribución
│
├── tests/run.sh                # 14 smoke tests funcionales
├── validate.sh                 # Validador completo (conteos, sintaxis, frontmatter)
├── install.sh                  # Instalador con --dry-run, --with-playwright, --with-graphify
├── uninstall.sh                # Desinstalador seguro
├── Makefile                    # Targets: check, test, install, doctor, format
│
├── .github/workflows/validate.yml  # CI: validate.sh + smoke tests
│
├── AGENTS.md                   # Reglas globales + intent mapping
├── CLAUDE.md                   # System prompt compacto
├── README.md / README.es.md    # Documentación bilingüe
├── INSTALL.md                  # Guía de instalación
├── CHANGELOG.md                # Historial formal de releases
├── CONTEXTO_PROYECTO.md        # Bitácora viva de sesiones
│
└── docs/                       # Docs-First skeleton
    ├── DECISIONS.md             # Decisiones arquitectónicas (consolidado)
    ├── PROJECT_CONTEXT.md      # Este archivo
    ├── ARCHITECTURE.md          # Arquitectura técnica
    ├── BUSINESS_LOGIC.md       # Reglas de negocio
    ├── DATA_STRUCTURE.md        # Modelos de datos
    ├── RISKS.md                 # Registro de riesgos
    ├── TASKS.md                 # Tracking de tareas
    ├── CONVERSATION.md          # Resumen de conversación
    ├── ONBOARDING.md            # Onboarding para devs
    └── memory/                  # Observaciones de memoria de proyectos
```

## Estado actual

El proyecto está en **producción estable (v1.15.0)**. El base install es zero-deps; los flags `--with-playwright` y `--with-graphify` son opt-in. Los 14 smoke tests pasan; el custom linter (validate.sh) verifica conteos, sintaxis, frontmatter y consistencia documental.

### Skills: 22 (de 11 originales)

| Fuente externa | Skills | Versión |
|----------------|--------|---------|
| garrytan/gstack | 6 (plan-eng-review, office-hours, investigate, qa-web, web-verify, setup-deploy) | v1.11.0 |
| anthropics/skills | 4 (pdf, skill-creator, docx, xlsx) | v1.12.0 – v1.14.0 |
| safishamsi/graphify | 1 (graphify) | v1.15.0 |
| **Total adaptadas** | **11** | v1.11.0 – v1.15.0 |

### Última versión

**v1.15.0** (2026-06-28) — Cherry-pick de `safishamsi/graphify` con integración opt-in via `install.sh --with-graphify`. SKILL.md lightweight (~190 líneas vs 1204 originales), registro via `graphify opencode install`, auto-graphify de `~/.config/opencode/` post-install.

### Historial reciente

```
v1.15.0  safishamsi/graphify cherry-pick
v1.14.0  docx + xlsx (anthropics/skills F3)
v1.13.0  skill-creator (anthropics/skills F2)
v1.12.0  pdf + with_server.py (anthropics/skills F1)
v1.11.0  rename oc→occo + gstack cherry-pick (6 skills)
v1.10.0  (no release; cherries en develop)
v1.9.7   Windows installer + dashboard skills
v1.9.6   Self-Improvement Agent — automatización total
```

## Última versión

**v1.15.0** (2026-06-28) — `safishamsi/graphify` cherry-pick con `--with-graphify` opt-in install.
