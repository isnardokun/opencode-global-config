# opencode-global-config — Project Context

## Resumen

Configuración global para OpenCode CLI (`~/.config/opencode/`). Paquete que suma agentes especializados, perfiles prompt-enforced, slash commands nativos, skills de implementación, plugin de seguridad, scripts de instalación/validación y sistema de memoria persistente. Instalación **zero-deps** con flags opt-in para Playwright, graphify y codebase-memory-mcp.

## Problema que resuelve

OpenCode CLI viene sin configuración. Este proyecto entrega:

- **11 agentes** especializados (sin hardcoded model — usa el del UI de OpenCode)
- **9 perfiles** con gradiente deny-first (`auto` → `devops`)
- **25 skills** (orientación, no código): 11 originales + 12 adaptadas de upstream + cbm-graph-export + graphify orientation
- **14 slash commands** nativos del TUI
- **5 workflows** single-pass (`bug-hunt`, `new-project`, `debug`, `document`, `feature`)
- **Memoria persistente** file-based (JSONL + Markdown) con retrieval 3-capas
- **Self-Improvement** vía auto-compact a threshold dinámico de turnos
- **Plugin de seguridad** `safety-guard.js` (ESM, regex + audit log JSONL)
- **Git hooks fail-closed** `pre-commit` y `pre-push` con gate LLM opcional
- **3 install flags opt-in**: `--with-playwright`, `--with-graphify`, `--with-codebase-memory`

## Stack tecnológico

- **Shell:** Bash (`occo` wrapper, ~2965 líneas, ~106 KB)
- **JavaScript/ESM:** Plugin `safety-guard.js`
- **Python 3 stdlib:** JSONL memory, graphify-html y cbm-graph-export scripts
- **JSON:** Perfiles, OpenCode config, manifest registry
- **Markdown:** Agentes, skills, rubrics, comandos, docs
- **Git hooks:** pre-commit + pre-push fail-closed con `HOOK_REVIEW_RESULT=pass|fail`

### Opt-in externos (no incluidos en base install)

- **Playwright** (~170 MB) — para `/qa-web` y `/web-verify` tier 3-4
- **graphifyy** (~50 MB base + extras opcionales) — knowledge graphs de code/docs
- **codebase-memory-mcp** (~30 MB binary) — function-level call graph en 158 lenguajes
- **python-docx / openpyxl / python-pptx** — para `/docx` `/xlsx` `/pptx`
- **pypdf, pdfplumber, reportlab, poppler-utils, qpdf** — para `/pdf`

## Equipo

Proyecto mantenido por @isnardokun. GitHub: <https://github.com/isnardokun/opencode-global-config>

### Contribuidores

- Mantenedor único: @isnardokun
- CI/CD via GitHub Actions (`.github/workflows/validate.yml`)

## Estructura del repositorio

```
opencode-global-config/
├── occo                        # Wrapper CLI principal (~2965 líneas, canónico)
├── VERSION                     # "1.20.0"
├── opencode.json               # Config nativo OpenCode (template; install genera absoluto)
├── opencode.strict.json        # Variante paranoia
│
├── agents/                     # 11 agentes (markdown + YAML frontmatter)
│   ├── architect.md            # Read-only, subagent
│   ├── planner.md              # Read-only, carga plan-eng-review
│   ├── builder.md              # Edit + bash(ask), primary
│   ├── builder-safe.md         # Edit: ask, bash: ask
│   ├── reviewer.md             # Read-only, subagent
│   ├── security-auditor.md     # Read-only, subagent
│   ├── docs-writer.md          # Edit, subagent
│   ├── devops.md               # Edit + bash(allow), subagent
│   ├── oncall.md               # Bash(ask), subagent
│   ├── migration-planner.md    # Read-only, subagent
│   └── performance-profiler.md # Read-only, subagent
│
├── commands/                   # 14 slash commands
│   ├── analyze.md, review.md, secure.md, feature.md
│   ├── bug-hunt.md, docs.md, devops.md, oncall.md
│   ├── office-hours.md, investigate.md, plan-eng-review.md
│   ├── qa-web.md, web-verify.md, setup-deploy.md
│
├── skills/                     # 25 skills (orientación + 3 scripts)
│   ├── Originales (11): ai-coding-rules, caveman, design-md, diagnose,
│   │   docs-writer, grill-with-docs, memory-retrieval, precommit-review,
│   │   project-map, safe-implementation, test-first
│   ├── gstack cherry-pick (6): plan-eng-review, office-hours, investigate,
│   │   qa-web, web-verify, setup-deploy
│   ├── anthropics cherry-pick (5 completas + 1 integrada): pdf,
│   │   skill-creator, docx, xlsx, pptx + frontend-design → design-md
│   └── graphify cherry-pick (1): graphify
│   └── cherry-pick DeusData (1): codebase-memory-mcp
│   └── autoría interna (1): cbm-graph-export
│
├── profiles/                   # 9 perfiles deny-first
├── rubrics/                    # 4 rubrics: code-review, security-review, plan-review, grilling
├── plugins/safety-guard.js     # ESM, regex + audit log JSONL
├── hooks/                      # pre-commit + pre-push fail-closed
├── memory/                     # Sistema de memoria (INDEX.md, projects/, outcomes/)
├── souls/                      # Personas predefinidas (single souls.md)
│
├── agents/manifest.json        # Registry machine-readable
├── skills-registry.json        # Skills con atribución upstream
│
├── tests/run.sh                # 14 smoke tests funcionales (+ 1 nuevo E2E install en v1.20.0)
├── validate.sh                 # Validador: frontmatter, sintaxis, conteos, versión
├── install.sh                  # Instalador con flags opt-in
├── uninstall.sh                # Desinstalador con backup automático
├── Makefile                    # Targets: check, test, install, doctor, format
│
├── .github/workflows/validate.yml  # CI: validate.sh + smoke tests
│
├── AGENTS.md                   # Reglas globales + intent mapping
├── CLAUDE.md                   # System prompt compacto
├── README.md / README.es.md    # Documentación bilingüe
├── INSTALL.md                  # Guía de instalación paso a paso
├── CHANGELOG.md                # Historial formal de releases
├── CONTEXTO_PROYECTO.md        # Bitácora viva de sesiones (en español)
│
└── docs/                       # Docs-First skeleton
    ├── INDEX.md                # Este índice de docs/
    ├── DECISIONS.md            # Decisiones arquitectónicas
    ├── PROJECT_CONTEXT.md      # Este archivo
    ├── ARCHITECTURE.md          # Arquitectura técnica
    ├── BUSINESS_LOGIC.md       # Reglas de negocio
    ├── DATA_STRUCTURE.md        # Modelos de datos
    ├── RISKS.md                 # Registro de riesgos
    ├── TASKS.md                 # Tracking de tareas
    ├── CONVERSATION.md          # Resumen de conversación
    ├── ONBOARDING.md            # Onboarding para devs
    └── memory/                  # Observaciones de proyectos sincronizadas
```

## Estado actual (v1.20.0)

### Skills: 25 totales

| Fuente externa | Skills | Versión |
|----------------|--------|---------|
| garrytan/gstack | 6 (plan-eng-review, office-hours, investigate, qa-web, web-verify, setup-deploy) | v1.11.0 |
| anthropics/skills | 5 completas (pdf, skill-creator, docx, xlsx, pptx) + 1 integrada (frontend-design → design-md) | v1.12.0 – v1.16.0 |
| safishamsi/graphify | 1 (graphify) + 1 script propio (graphify_html) + 1 server (graphify_serve) + 1 launcher (start_graphify_serve) | v1.15.0 / v1.17.0 |
| DeusData/codebase-memory-mcp | 1 orientación (codebase-memory-mcp) | v1.18.0 |
| Autoría interna | 1 script export (cbm-graph-export) | v1.19.0 |
| **Total** | **25** | v1.11.0 – v1.20.0 |

### Última versión

**v1.20.0** — *"Descubrimiento + Confiabilidad"*. Resuelve hallazgos P0 de la auditoría:
- design-md SKILL.md recupera frontmatter válido (era invisible al autocomplete).
- validate.sh chequea frontmatter en `skills/*/SKILL.md` además de agents/commands.
- Test E2E para `install.sh --with-codebase-memory` (verifica que el path binario-externo + MCP-register no regresse en silencio).
- `install.sh --help` ya no reporta tamaño fijo de graphify (cambia con extras opcionales).
- `occo --doctor` chequea MCP servers, hooks ejecutables y binarios opt-in.
- Threshold del warn de session-turns: 20 → 40 (reducir ruido durante sesiones normales).
- `occ --init` hace backup de hooks existentes antes de sobrescribir.

### Historial reciente

```
v1.20.0  Descubrimiento + Confiabilidad (auditoría)
v1.19.0  cbm-graph-export (offline viewer para CBM SQLite)
v1.18.0  codebase-memory-mcp cherry-pick
v1.17.0  graphify auto-rebuild + HTML viewer
v1.16.0  pptx + frontend-design integrado en design-md
v1.15.0  graphify cherry-pick
v1.14.0  docx + xlsx (anthropics/skills F3)
v1.13.0  skill-creator (anthropics/skills F2)
v1.12.0  pdf + with_server.py (anthropics/skills F1)
v1.11.0  rename oc→occo + gstack cherry-pick (6 skills)
```

## Auditoría de producto

Existe un informe formal: [`INFORME_AUDITORIA_v1.19.0.md`](../INFORME_AUDITORIA_v1.19.0.md). Resume 23 findings rankeados (P0/P1/P2/P3) y propone un roadmap en 3 releases. v1.20.0 cubre los bloqueantes P0.
