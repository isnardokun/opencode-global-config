# opencode-global-config — Contexto del Proyecto

**Repo GitHub:** https://github.com/isnardokun/opencode-global-config  
**Versión actual:** 1.15.0
**Última sesión:** 2026-06-28 (consolidación)

---

## Índice de la bitácora

Esta bitácora documenta las decisiones tácticas, riesgos residuales, y notas de cada sesión. Para decisiones arquitectónicas formales y anti-criterios explícitos, ver `docs/DECISIONS.md`. Para el contexto actual, ver `docs/PROJECT_CONTEXT.md`.

| # | Sesión | Versión | Resumen |
|---|--------|---------|---------|
| 17 | 2026-06-28 (consolidación) | v1.15.0 | Docs consolidation: DECISIONS.md lleno, PROJECT_CONTEXT.md actualizado, INDEX.md nuevo, docs/CHANGELOG.md duplicado eliminado. |
| 16 | 2026-06-28 (graphify) | v1.15.0 | Cherry-pick de `safishamsi/graphify` con `install.sh --with-graphify` opt-in flag. SKILL.md lightweight (190 líneas) + registro en opencode + auto-graphify. |
| 15 | 2026-06-28 (docx+xlsx) | v1.14.0 | Cherry-pick de `anthropics/skills` F3: `docx` (python-docx) y `xlsx` (openpyxl), con runtime-detection. Estrategia lightweight — scripts portados como inline snippets. |
| 14 | 2026-06-28 (skill-creator) | v1.13.0 | Cherry-pick de `anthropics/skills` F2: `skill-creator` (methodology + 2 scripts). SKILL.md adaptado para opencode (sin subagents Claude-CLI). |
| 13 | 2026-06-28 (consolidación v1.12) | v1.12.0 | Fix: contador "15→17 artefactos" en install.sh, subcomando inexistente en web-verify, install.sh cp -r fix. CHANGELOG honesto. |
| 12 | 2026-06-28 (pdf+helper) | v1.12.0 | Cherry-pick de `anthropics/skills` F1: `pdf` (SKILL.md completo) + `web-verify/scripts/with_server.py` (server lifecycle helper). |
| 11 | 2026-06-28 (v1.11.x) | v1.11.0+1 | Fix html2text tier-2 fallback para web-verify (cuando lynx no está instalado). |
| 10 | 2026-06-28 (QA+playwright) | v1.11.0 | Cherry-pick F2: `qa-web`, `web-verify`, `setup-deploy` + flag `--with-playwright` en install.sh. Modo degradado para web-verify. |
| 9 | 2026-06-28 (rename+gstack) | v1.11.0 | Rename `oc` → `occo` (canónico) + cherry-pick F1 desde `garrytan/gstack`: `plan-eng-review`, `office-hours`, `investigate` + rubric extendida. |
| 8 | 2026-05-02 | — | Revisión integral y bug-hunt masivo. |
| 7-1 | 2026-05-01 a 2026-05-02 | v1.9.6 | Auto-Improvement Agent, harness engineering, memory bank, self-improvement. |

## Estado del proyecto al cierre de la sesión actual

- **22 skills** instaladas, 11 originales + 11 cherry-picked
- **14 slash commands**, **11 agents**, **4 rubrics**, **9 profiles deny-first**
- **14/14 smoke tests** verdes
- **`bash validate.sh`** pasa (conteos, sintaxis, frontmatter, version match)
- **`HEAD == origin/main`** sincronizado
- **3 fuentes externas** integradas: garrytan/gstack, anthropics/skills, safishamsi/graphify
- **2 flags opt-in** en install.sh: `--with-playwright` (~170 MB), `--with-graphify` (~50 MB)
- **Base install sigue zero-deps**  
**Directorio de trabajo en sesiones:** `/tmp/opencode-global-config` (clonar si no existe)

---

## Qué es este proyecto

Configuración global para OpenCode CLI (`~/.config/opencode/`).
Agrega: agentes custom, perfiles prompt-enforced, slash commands nativos, skills, plugin de seguridad, scripts de instalación/validación y bitácora técnica de continuidad.

**Instalar:**
```bash
git clone https://github.com/isnardokun/opencode-global-config /tmp/opencode-global-config
cd /tmp/opencode-global-config
bash install.sh
```

---

## Arquitectura actual

```
opencode-global-config/
├── opencode.json          # Config principal (permisos nativos OpenCode)
├── opencode.strict.json   # Modo paranoid: webfetch/websearch/external_dir: deny
├── occo                     # Script wrapper (~2490 líneas) — comando global `occo`
├── install.sh             # Instalación + --dry-run
├── uninstall.sh           # Remoccoión segura con backup
├── validate.sh            # Validación completa + --installed
├── Makefile               # validate, check, install, dry-run, uninstall, doccotor
├── VERSION                # Fuente simple de versión actual para validaciones
├── CHANGELOG.md           # Historial formal de releases
├── CONTEXTO_PROYECTO.md   # Bitácora viva: decisiones, sesiones, riesgos, pendientes
├── .editorconfig          # UTF-8, LF, 2 espacios
├── .github/workflows/     # CI: validate.sh + shellcheck en cada push
│
├── agents/ (11 agentes)
│   ├── architect.md       # Análisis, nunca modifica
│   ├── builder.md         # Implementa (edit: allow)
│   ├── builder-safe.md    # Implementa con confirmación (edit: ask, bash: ask)
│   ├── planner.md         # Planificación en fases
│   ├── reviewer.md        # Revisión, nunca modifica
│   ├── security-auditor.md
│   ├── doccos-writer.md
│   ├── devops.md
│   ├── oncall.md
│   ├── migration-planner.md  # Migraciones reversibles, solo lectura
│   └── performance-profiler.md  # N+1, O(n²), I/O bloqueante, solo lectura
│
├── commands/ (8 slash commands nativos en OpenCode TUI)
│   ├── analyze.md, review.md, secure.md, feature.md
│   ├── bug-hunt.md, doccos.md, devops.md, oncall.md
│
├── skills/ (10 skills)
│   ├── project-map/
│   ├── safe-implementation/
│   ├── test-first/
│   ├── precommit-review/
│   ├── memory-retrieval/
│   └── doccos-writer/
│
├── rubrics/ (3 gates reutilizables)
│   ├── code-review.md       # Criterios bloqueantes y evidencia para review
│   ├── security-review.md   # Severidad, evidencia y remediación de seguridad
│   └── plan-review.md       # Fases verificables, supuestos y tradeoffs
│
├── profiles/ (9 perfiles — deny-first gradient)
│   ├── deny.json          # Solo lectura estática
│   ├── plan.json          # Planificación sin modificar
│   ├── review.json        # Lectura y análisis
│   ├── default.json       # Desarrollo general con aprobación
│   ├── work.json          # Trabajo profesional conservador
│   ├── research.json      # Investigación con web habilitada
│   ├── auto.json          # Modo asistido con tracking de decisiones
│   ├── trusted.json       # Desarrollador avanzado
│   └── devops.json        # Infraestructura con rollback
│
├── plugins/
│   ├── safety-guard.js    # Bloquea comandos destructivos + audit log JSONL
│   └── package.json       # Declara plugins JS como ESM (`type: module`)
│
├── hooks/
│   ├── pre-commit         # @reviewer + precommit-review
│   └── pre-push           # @security-auditor
│
├── souls/souls.md         # Personas/tonos para LLM
└── memory/                # Sistema de observaciones con índice JSONL
```

---

## Conceptos clave para retomar

### Profile enforcement (cómo funciona)
OpenCode no tiene sistema de perfiles nativo. Lo implementamos mediante **inyección de reglas en el prompt**:
1. `switch_profile()` en `occo` exporta `OPENCODE_PROFILE`
2. `get_profile_rules()` lee el JSON del perfil activo y genera instrucciones en inglés
3. `_occo_run()` inyecta esas reglas en cada llamada no interactiva a `opencode run "..."`

Esto significa que los perfiles aplican restricciones vía LLM instructions, no vía permisos de sistema.

### Separación nativa vs prompt
- `opencode.permission` en los JSONs de perfil → matriz declarativa validada por el repo; actualmente no se aplica como perfil nativo por OpenCode
- `policy` en los JSONs de perfil → reglas inyectadas al LLM via prompt

### Slash commands
Los archivos `commands/*.md` se cargan automáticamente en el TUI de OpenCode.
No requieren el wrapper `occo`. Se usan directamente como `/analyze`, `/review`, etc.

### Memory system
- `~/.config/opencode/memory/` — observaciones en markdown con frontmatter
- `memory/index.jsonl` — índice para búsqueda rápida con `jq`/`fzf`/`ripgrep`
- Funciones en `occo`: `search_memory()`, `create_observation()`, `get_observations()`, `get_timeline()`

### Safety guard
`plugins/safety-guard.js` bloquea via regex: `rm -rf /`, `> /dev/sda`, `chmod -R 777` en paths de sistema, etc.
Además audita comandos bash permitidos/bloqueados en `~/.config/opencode/logs/safety-guard.jsonl`, con redacción parcial de secretos conoccoidos.

**Importante:** es un guardrail best-effort, no un sandbox. Reduce accidentes comunes, pero no reemplaza permisos nativos, revisión humana ni scanners determinísticos.

### Rol de `CONTEXTO_PROYECTO.md`
Este archivo es la **bitácora viva del proyecto**. Debe registrar:
- cambios aplicados entre sesiones;
- decisiones técnicas y tradeoffs;
- bugs encontrados y corregidos;
- validaciones ejecutadas;
- riesgos residuales aceptados;
- pendientes priorizados para próximas sesiones.

`CHANGELOG.md` queda como historial formal de releases. `CONTEXTO_PROYECTO.md` queda como memoria operativa para retomar el proyecto sin perder contexto.

---

## Historial de versiones (resumido)

| Versión | Qué cambió |
|---------|-----------|
| **1.9.6** | Self-Improvement Agent: detect_project, auto_compact, auto_reflect, track_outcome, analyze_outcomes; memory templates; Harness Engineering exit conditions; agents/manifest.json |
| **1.9.4** | Rubrics/gates reutilizables para code review, security review y plan review; validación instalada estricta; `occo --doccotor` falla con exit code si faltan artefactos críticos; release-readiness y smoke tests ampliados |
| **1.9.3** | Fix compat OpenCode 1.14: `opencode run` en lugar de `opencode -p`; validator de permisos en validate.sh; `--dry-run` corregido; `auto.json` permisos inválidos fijados |
| **1.9.2** | `validate.sh`: line count sanity check + frontmatter validation; `Makefile`: target `format` + `jq` strict |
| **1.9.1** | `.editorconfig`, `Makefile`, `opencode.strict.json`, `agent/builder-safe.md` |
| **1.9.0** | Matriz declarativa de permisos OpenCode, 3 agentes nuevos, 8 slash commands, `validate.sh`, `uninstall.sh`, `--dry-run`, audit log, `--doccotor`, CI GitHub Actions, bilingüe README |
| **1.8.0** | Cross-platform install.sh, rutas absolutas en JSON, fix macOS, memory JSONL index, cleanup CLAUDE.md |
| **1.7.0** | Profile enforcement por prompt injection, single-pass workflows, fix args bug en `_occo_run()`, safety-guard mejorado |
| **1.6.0** | Doccos, changelog honesto |
| **1.5.0** | Sistema de workflows (bug-hunt, new-project, debug, doccoument, feature) |
| **1.4.0** | Memory retrieval 3-layer system, observation format, JSONL index |
| **1.3.0** | 7 perfiles deny-first gradient, context budget tracking, `--compact` |
| **1.2.0** | 4 principios de Karpathy integrados |
| **1.1.0** | Menú interactivo fzf, memory bank, souls, git hooks, `occo init` |
| **1.0.0** | 8 agentes, 4 skills, safety-guard plugin, comando `occo` |

---

## Bugs/decisiones importantes

### gstack QA cherry-pick + Playwright opt-in — sesión 2026-06-28 (v1.11.0)

Segunda iteración del cherry-pick desde `garrytan/gstack`. Esta vez, el usuario preguntó específicamente por `browse/` y `qa/`, que en la sesión anterior (v1.10.0) se consideraron "fuera de scope por ser Bun/Playwright/Chromium". Decisión revisada: integrar la **lógica de uso** (metodología) sin los binarios, ofreciendo instalación opcional de Playwright.

#### Lo que se portó en v1.11.0

| Artefacto | Fuente gstack | Adaptación |
|---|---|---|
| `skills/qa-web/SKILL.md` | gstack `qa/SKILL.md` (31954+ bytes) | Metodología de QA web en 4 fases (discover, test, categorize, fix-and-verify). 3 tiers (quick/standard/exhaustive). 7 categorías de testing. Iron laws: no fixes sin reproducción, no bypasses, one-bug-one-commit. ~150 líneas. |
| `skills/web-verify/SKILL.md` | gstack `browse/SKILL.md` (sin el binario `browse/dist/browse`) | Auto-detección de herramientas (curl/wget/lynx/playwright) y tier-up de HTTP-only a browser automation. Tier 4 = manual checklist honesto. ~200 líneas. |
| `skills/setup-deploy/SKILL.md` | gstack `setup-deploy/SKILL.md` (8042+ bytes) | Detección de 8 plataformas (Fly, Vercel, Render, Netlify, Railway, Heroku, GHA, Docker). Persistencia en `CLAUDE.md` con update-in-place del bloque `## Deploy Configuration`. ~120 líneas. |
| `commands/qa-web.md`, `commands/web-verify.md`, `commands/setup-deploy.md` | Nuevos | Patrón `commands/analyze.md` |
| `install.sh --with-playwright` | n/a | Flag opt-in (no default). Si npm + TTY disponibles, ofrece interactivamente instalar Playwright. Degradación graceful: si falla la instalación, sigue adelante. |

#### Lo que NO se hizo (decisión explícita, no por limitación)

- ❌ NO se portó el binario `browse/dist/browse` (60 archivos TS, daemon Bun, anti-bot stealth, ngrok tunnel, SOCKS5, xvfb, cookie picker UI). Pesaba ~450 MB y rompía la promesa zero-deps del install.sh.
- ❌ NO se añadió Bun, ngrok, o gbrain como dependencias. La instalación base sigue siendo zero-deps.
- ❌ NO se instaló Playwright por defecto. Sigue siendo opt-in via flag `--with-playwright`.
- ❌ NO se modificó `occo`, `safety-guard.js`, ni `tests/run.sh`.

#### Restricciones respetadas

- Frontmatter mínimo en las 3 SKILL.md (solo `name` + `description`).
- Cero referencias host-specific (grep por `gstack/|claude -p|--disallowedTools|Conductor|MCP variant|bun |~/.claude/skills|~/.gstack|gstack-update-check|gstack-slug|gstack-config|gbrain` → 0 matches).
- `web-verify` degrada a tier 1/2 si Playwright no está disponible, con honest reporting via `WEB_VERIFY_RESULT=degraded`.
- `install.sh --with-playwright` se ofrece solo con `npm` disponible Y TTY interactivo. En `--dry-run` se absorbe silenciosamente. En CI/scripted se omite.
- `setup-deploy` no ejecuta deploys — solo detecta y documenta.

#### Validaciones ejecutadas

- `bash validate.sh` → ✅ Validation passed (17 skills, 14 commands, 9 profiles, 11 agents, version 1.11.0)
- `bash tests/run.sh` → ✅ All 14 tests passed
- `bash install.sh --dry-run` → ✅ muestra playwright/lynx en opcionales
- `bash install.sh --help` → ✅ muestra usage con `--with-playwright` documentado
- `bash -n install.sh` → syntax OK
- `bash install.sh --dry-run --with-playwright` → ✅ flag absorbido correctamente
- Reviewer final → APROBADO con 3 notas menores (todas corregidas en el mismo turno)

#### Hallazgo del reviewer (corregido en este turno)

1. `install.sh:333` decía "15 artefactos" pero ahora son 17. Corregido a "17 artefactos + opcional Playwright".
2. CHANGELOG sección v1.11.0 también mencionaba "15 artefactos". Corregido.
3. `web-verify/SKILL.md:112` tenía un subcomando inexistente (`npx playwright cr --help`). Eliminado.

#### Detección de Playwright en runtime

`web-verify` ahora detecta automáticamente qué hay disponible:

```bash
echo "TOOL_CURL=$(command -v curl >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_LYNX=$(command -v lynx >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_PLAYWRIGHT=$(command -v playwright >/dev/null 2>&1 && echo yes || echo no)"
```

Y adapta la verificación al tier máximo disponible. En este host (donde ya hay Playwright instalado), `web-verify` ofrece tier 4 (full multi-step interaction).

---

### Cherry-pick selectivo desde garrytan/gstack — sesión 2026-06-28 (v1.10.0)

Evaluación de `https://github.com/garrytan/gstack` (23 skills para Claude Code, multi-host setup). **Decisión: cherry-pick selectivo de 3 skills + 1 rubric. No adopción completa.**

#### Por qué no adopción completa

gstack depende de infraestructura que no funciona en OpenCode:
- `hooks.PreToolUse` (matcher `Bash`/`Edit`/`Write`) — OpenCode los strippea porque su host config usa `frontmatter.mode = 'allowlist'` con `keepFields: ['name','description']` solamente.
- Binarios Bun + Playwright + Chromium (`browse/` skill) — añadiría ~400MB y rompe el install.sh zero-deps.
- gbrain, Conductor, MCP variant de AskUserQuestion — tooling Anthropic-específico.
- 325 commits, ~70 directorios top-level — superficie de mantenimiento excesiva vs nuestro wrapper de 106KB.

Nuestro `plugins/safety-guard.js` (regex + audit log JSONL) ya cumple el rol de `careful`/`freeze`/`guard` con un modelo **más estricto** (gate LLM fail-closed en hooks git, no agent-side PreToolUse).

#### Lo que sí se portó (adaptado, no copy-paste)

| Artefacto | Fuente gstack | Adaptación |
|---|---|---|
| `skills/plan-eng-review/SKILL.md` | gstack `plan-eng-review/SKILL.md` (14360+ bytes) | Reescrito limpio: 8 forcing questions, cognitive patterns de eng managers, iron law con `PLAN_REVIEW_RESULT=approve\|revise\|block`. Sin preamble bash, sin gbrain, sin Conductor. ~190 líneas. |
| `skills/office-hours/SKILL.md` | gstack `office-hours/SKILL.md` (46191+ bytes) | Reescrito: 6 forcing questions (demand reality, status quo, desperate specificity, narrowest wedge, observation, future-fit) + format de design doc. Iron law: NO implementación. ~140 líneas. |
| `skills/investigate/SKILL.md` | gstack `investigate/SKILL.md` (8618+ bytes) | Reescrito: 4 fases (investigate, analyze, hypothesize, implement) + iron law "no fixes sin root cause" + stop-after-3-fixes rule. ~190 líneas. |
| `rubrics/code-review.md` | gstack `review/checklist.md` | Extendido (no reemplazado): 5 Pass 1 CRITICAL checks (SQL & Data Safety, Race Conditions, LLM Output Trust Boundary, Shell Injection, Enum Completeness) + 7 Pass 2 INFORMATIONAL checks. Estructura original preservada. +92 líneas. |
| `commands/office-hours.md`, `commands/investigate.md`, `commands/plan-eng-review.md` | (no existen en gstack como slash commands nativos — son gstack-only) | Nuevos, siguiendo patrón de `commands/analyze.md`. |
| `agents/manifest.json` | n/a | Planner ahora carga `plan-eng-review`; oncall carga `investigate`. 3 skills añadidas con `source.upstream: garrytan/gstack`. |

#### Restricciones respetadas

- **Frontmatter mínimo:** cada SKILL.md nuevo tiene solo `name` + `description` (2 líneas YAML). Sin `hooks`, `allowed-tools`, `triggers`, `preamble-tier`, `gbrain`, `version` — todos serían strippeados por el host OpenCode.
- **Cero referencias host-specific:** grep final por `gstack/|claude -p|--disallowedTools|Conductor|MCP variant|bun ` retornó 0 matches en skills/, commands/, agents/, profiles/, rubrics/.
- **Patrón commands/*.md:** los 3 nuevos siguen exactamente el shape de `commands/analyze.md` (frontmatter `description`, body "Use @X skill" + bullets + "Do NOT").
- **Modelo deny-first intacto:** no se modificó `occo`, no se cambió `safety-guard.js`, no se rompió la lógica de `validate.sh` más allá de extender las listas requeridas.
- **Tests existentes:** 14/14 siguen verdes sin tocar `tests/run.sh`.
- **Atribución:** `agents/manifest.json` declara `source.upstream: garrytan/gstack` y `license: MIT` en las 3 skills adaptadas.

#### Validaciones ejecutadas

- `bash validate.sh` → ✅ Validation passed
- `bash tests/run.sh` → ✅ All 14 tests passed
- `bash install.sh --dry-run` → ✅ Dry-run completado
- `make check` → OK
- `git diff --stat HEAD` (de este turno) → 6 archivos modificados, +171/-16 líneas, + 6 archivos nuevos (3 skills + 3 commands)

#### Pendiente nuevo identificado

- `skills/diagnose/SKILL.md:4`, `skills/grill-with-docs/SKILL.md:4`, `skills/caveman/SKILL.md:4` aún tienen `triggers:` en frontmatter (drift pre-existente, no introducido por este cherry-pick). El check de `validate.sh` solo valida presencia del fence `---`, no contenido. PR de limpieza futuro.
- README `Features` bullets ya sincronizados con los nuevos conteos (11 commands, 14 skills).

---

### Drift fix y consolidación de rename `oc` → `occo` — sesión 2026-06-28

El proyecto arrastraba un rename incompleto: el archivo en disco se llamaba `oc` pero `install.sh` lo instalaba como `occo`, y la mayoría de docs/strings internos usaban `occo`. Esto causaba drift masivo y varias regresiones funcionales.

**Decisión del usuario:** `occo` es el nombre canónico. Se renombró el archivo y se alinearon todas las referencias funcionales.

#### Cambios aplicados

- `oc` → `occo` (rename vía `git mv`, similarity 99%)
- `occo`: tres auto-referencias funcionales corregidas en línea 1455-1456, 1553-1554 y 2805-2809 (`command -v occo` + invocación `occo "$prompt"` + mensaje `--doctor`).
- `install.sh:246`: `cp "$INSTALL_DIR/oc"` → `cp "$INSTALL_DIR/occo"`. Sin este fix `bash install.sh` abortaba con `error()`.
- `hooks/pre-commit:72-73` y `hooks/pre-push:72-73`: misma pareja de auto-referencias corregidas. Los hooks versionados quedarían rotos al usar canónico.
- `Makefile:8,22,37`: `bash -n oc`, `shfmt ... oc ...`, `oc --doctor` → `occo`. Sin esto `make check`, `make format` y `make doctor` fallaban.
- `validate.sh:55,113,139,194,291-293`: cinco referencias a `oc` actualizadas a `occo` (check_file, for sh, legacy_cli grep, line count, --remember checks).
- `tests/run.sh:12,103,117,131`: dos invocaciones del wrapper y dos setups de mock renombrados a `occo` para que el path canónico quede mockeado.
- `ARCHITECTURE.md`: File Inventory actualizado (`oc` → `occo`); `VERSION` 1.9.6 → 1.9.7; sección "Skills (10 total)" → "Skills (11 total)"; "Rubrics (3 reusable gates)" → "Rubrics (4 reusable gates)"; árbol de skills en File Inventory ahora incluye `design-md/`.
- `README.md`: dos menciones documentales corregidas de "11 agents, 10 skills" → "11 agents, 11 skills".
- `README.es.md`: línea 53 `oc` → `occo`; "6 skills" → "11 skills"; "3 rubrics" → "4 rubrics".

#### Validaciones ejecutadas

- `bash validate.sh` → ✅ Validation passed
- `bash tests/run.sh` → All 14 tests passed
- `make check` → OK
- `bash install.sh --dry-run` → OK, sin modificaciones
- `git diff --stat HEAD` → 10 archivos, +43/-39 líneas, rename `oc→occo` con similarity 99%

#### Proceso de revisión

El `@reviewer` fue invocado dos veces en la misma sesión. La primera pasada detectó 3 bloqueantes funcionales (B1-B3) por auto-referencias incompletas en `occo`. Tras corregirlos, una segunda pasada detectó 4 bloqueantes adicionales (B4-B7) en `install.sh`, `hooks/*`, `Makefile` y un fix parcial en `occo:2807`. Esto subraya la importancia de revisar el rename de manera **exhaustiva en todos los call-sites funcionales**, no solo los archivos obvios.

#### Drift cosmético residual (no bloqueante, fuera de scope)

Quedan ~200 strings de ayuda/ejemplos en `occo`, `install.sh`, `README*.md`, `ARCHITECTURE.md` que aún dicen `oc` en mensajes al usuario. No rompen ejecución. Decidido: dejarlo para un PR de limpieza dedicado y no contaminar este diff surgical.

#### Pendientes nuevos identificados

1. **Drift cosmético en strings de ayuda de `occo`** — ~58 menciones en `echo`/`help`. No bloqueante. PR de limpieza futuro.
2. **Drift cosmético en docs públicas** — ~140 menciones en README.md, README.es.md, ARCHITECTURE.md. Misma decisión.
3. **Pendientes históricos siguen activos** — ver lista "Pendientes conocidos" al final del archivo.

---

### Revisión integral y bug-hunt — sesión 2026-05-02

El usuario definió explícitamente que `CONTEXTO_PROYECTO.md` debe usarse como registro de cambios, modificaciones y mejoras del proyecto. Se ejecutaron dos pasadas de bug-hunt con agentes especializados:

1. `@architect` + `project-map` — mapeo de arquitectura, entrypoints, zonas de riesgo y bugs probables.
2. `@security-auditor` — revisión de seguridad: permisos, hooks, audit log, safety guard, filesystem.
3. `@planner` — priorización de fixes por severidad y criterios de éxito.
4. `@builder-safe` — implementación quirúrgica por iteraciones.
5. `@reviewer` + `precommit-review` — revisión final del diff y validaciones.

Archivos modificados por las correcciones recientes:
- `occo`
- `validate.sh`
- `Makefile`
- `VERSION`
- `.github/workflows/validate.yml`
- `hooks/pre-commit`
- `hooks/pre-push`
- `plugins/safety-guard.js`
- `plugins/package.json`
- `tests/run.sh`
- `install.sh`
- `README.md`, `README.es.md`, `INSTALL.md`
- `CONTEXTO_PROYECTO.md`

Estado Git observado tras las correcciones:
- Archivos modificados tracked: `occo`, `validate.sh`, `Makefile`, `.github/workflows/validate.yml`, `hooks/pre-commit`, `hooks/pre-push`, `plugins/safety-guard.js`, `install.sh`, `README.md`, `README.es.md`, `INSTALL.md`.
- `CONTEXTO_PROYECTO.md` aparece como untracked y debe versionarse si será la fuente oficial de continuidad.
- `tests/run.sh` fue creado como nueva suite funcional mínima y también debe versionarse.

#### Correcciones funcionales aplicadas

- `occo`: corregida precedencia Bash en detección Python para `pyproject.toml`, `requirements.txt` y comandos de test.
- `occo`: `occo --init` ya no crea `.git/hooks` si el target no es repo Git.
- `occo`: `occo --init` genera ruta de agentes project-loccoal en lugar de `~/.opencode/agents`.
- `occo`: el hook generado por `occo --init` usa `occo` si existe y fallback a `opencode run`.
- `occo`: el hook generado por `occo --init` ahora es fail-closed y exige `BLOCKING_FINDINGS=false`.
- `occo`: `occo plan` preserva argumentos multi-palabra.
- `occo`: `review`, `secure`, `doccos` y `oncall` pasan argumentos opcionales a sus funciones rápidas.
- `occo`: `--list-profiles` muestra nombres usables sin `.json`.
- `occo`: `switch_profile()` rechaza perfiles vacíos o inexistentes.
- `occo`: `--get` y `--timeline` aceptan IDs con o sin prefijo `obs_`.
- `occo`: JSONL de memoria se genera con `python3` y `json.dumps`, evitando corrupción por comillas, backslashes o saltos de línea.
- `occo`: `search_memory()` aplica filtros `project` y `type`.
- `occo`: búsqueda de memoria usa coincidencia literal con `grep -F`, no regex.
- `occo`: `occo --memory "query" -t type` interpreta `-t` como filtro de tipo.
- `occo`: `occo --remember -p project -t type <texto>` crea observaciones asoccoiadas a proyecto y tipo.
- `occo`: `occo --memory <query> -p project -t type` filtra por proyecto y tipo mediante flags explícitas.
- `occo`: `create_observation()` valida `python3` antes de escribir archivos para evitar estado parcial.
- `occo`: frontmatter de memoria quotea `project`, `type` y `summary` usando JSON-compatible YAML scalars.
- `occo`: workflows `bug-hunt`, `new-project`, `debug`, `doccoument`, `feature` y `--compact` no reportan éxito ni escriben memoria/reset si `_occo_run` falla.
- `occo`: ayuda actualizada para 9 perfiles y sintaxis `--remember [-p proyecto] [-t tipo]`.
- `occo --init`: ahora genera `pre-commit` y `pre-push` fail-closed.
- `hooks/pre-commit`: añade `git diff --cached` explícito al prompt.
- `hooks/pre-push`: añade diff contra upstream o fallback de últimos cambios al prompt.
- `install.sh`: banner alineado a v1.9.3.
- `README.md`, `README.es.md`, `INSTALL.md`: versión/conteos de perfiles alineados a v1.9.3 / 9 perfiles.
- `validate.sh`: incluye `uninstall.sh` en la validación de sintaxis Bash.
- `validate.sh`: valida sintaxis JS de `plugins/safety-guard.js` con `node --check` si `node` existe.
- `validate.sh`: valida consistencia doccoumental de versión, conteos de perfiles/agentes/skills y soporte doccoumentado de `--remember -p`.
- `Makefile`: añade target `test` para ejecutar `tests/run.sh`.
- `Makefile`: `check` incluye `hooks/pre-commit` y `hooks/pre-push`.
- `Makefile`: `check` valida `plugins/package.json`.
- `.github/workflows/validate.yml`: ejecuta `tests/run.sh` como smoke tests funcionales en CI.
- `VERSION`: creado como fuente simple de versión actual (`1.9.3`).

#### Correcciones de seguridad aplicadas

- `hooks/pre-commit` y `hooks/pre-push`: usan `occo` si está disponible y fallback a `opencode run`.
- `hooks/pre-commit` y `hooks/pre-push`: capturan output y fallan si el comando retorna non-zero.
- `hooks/pre-commit` y `hooks/pre-push`: fallan con línea exacta `BLOCKING_FINDINGS=true`.
- `hooks/pre-commit` y `hooks/pre-push`: fallan si falta línea exacta `BLOCKING_FINDINGS=false`.
- `hooks/pre-commit` y `hooks/pre-push`: aceptan fallback `RECOMMENDATION=CORRECT` como señal de bloqueo.
- `hooks/pre-commit` y `hooks/pre-push`: ejecutan `gitleaks` si está instalado; si no, continúan con gate LLM fail-closed.
- `plugins/safety-guard.js`: migrado a formato ESM consistente.
- `plugins/safety-guard.js`: acceso defensivo a `output?.args?.command` para evitar `TypeError`.
- `plugins/safety-guard.js`: redacción básica de secretos antes de audit log.
- `plugins/safety-guard.js`: redacción ampliada para valores con/sin comillas y nombres comunes: `GITHUB_TOKEN`, `OPENAI_API_KEY`, `NPM_TOKEN`, `GH_TOKEN`, `ANTHROPIC_API_KEY`.
- `plugins/safety-guard.js`: redacción ampliada para headers `x-api-key`, flags `--token/--password/--api-key`, URLs con credenciales y `AWS_ACCESS_KEY_ID`.
- `plugins/safety-guard.js`: directorio de logs forzado a `0700` y `safety-guard.jsonl` a `0600`.
- `plugins/safety-guard.js`: bloqueo corregido para variantes críticas como `rm -rf /`, `rm -rf ~`, `rm -rf /*`, `rm -r -f /`, `rm --recursive --force /`.
- `plugins/package.json`: elimina warning Node `MODULE_TYPELESS_PACKAGE_JSON` declarando `type: module` dentro del directorio instalado de plugins.

#### Validaciones ejecutadas durante la sesión

Reportadas como OK por los agentes builder/reviewer:
- `bash -n occo`
- `bash -n occo validate.sh uninstall.sh`
- `bash -n occo hooks/pre-commit validate.sh`
- `bash -n hooks/pre-commit hooks/pre-push`
- `node --check plugins/safety-guard.js`
- `bash tests/run.sh`
- `make check`
- `./validate.sh`
- `bash install.sh --dry-run`
- `git diff --check`
- import ESM dirigido de `plugins/safety-guard.js`
- muestras dirigidas de redacción de secretos
- checks dirigidos para bloqueo de comandos destructivos en `safety-guard.js`
- simulación de lógica de hooks con `BLOCKING_FINDINGS=true`, `BLOCKING_FINDINGS=false`, marcador ausente y `RECOMMENDATION=CORRECT`
- moccoks de fallo de workflows y `--compact`
- moccok de parser `occo --memory "query" -t type`
- moccok sin `python3` para evitar archivos parciales
- `occo --init` en repo temporal para verificar hook generado fail-closed
- `occo --compact` con `opencode` moccokeado
- `occo --doccotor` contra instalación fixture
- `validate.sh --installed` contra instalación fixture
- `install.sh --dry-run`

#### Revisiones finales

- Primer reviewer detectó bloqueantes en regex de `rm` y heurística de hooks; ambos fueron corregidos.
- Segundo reviewer detectó fail-open si faltaba `BLOCKING_FINDINGS=false`; fue corregido.
- Tercera revisión de regresiones aprobó los fixes, sin bloqueantes restantes.

### Riesgos residuales activos tras 2026-05-02

| Riesgo | Severidad | Estado | Próximo paso recomendado |
|--------|-----------|--------|--------------------------|
| `safety-guard.js` es regex-based, no sandbox | Media | Aceptado/doccoumentar | Mantener como guardrail; añadir tests de falsos positivos/negativos si crece |
| Audit log puede no redactar todos los formatos de secreto | Media | Mitigado parcialmente | Mantener pruebas y ampliar si aparecen nuevos formatos |
| Logs/config dependen de `umask` | Baja/Media | Mitigado para audit log | Evaluar permisos explícitos en instalación/config global |
| Hooks dependen de marcador LLM | Media | Fail-closed + `gitleaks` opcional | Considerar scanner obligatorio/configurado para releases críticas |
| `occo --init` instala hooks Git | Baja | Mitigado | Ya genera `pre-commit` y `pre-push`; seguir validando en tests |
| Perfiles son prompt-enforced, no sandbox | Baja/Media | Doccoumentado | No vender como seguridad fuerte; explorar config efectiva por perfil si OpenCode lo soporta |
| Test suite funcional inicial aún es smoke-level | Baja/Media | Mitigado parcialmente | Ampliar cobertura con workflows completos si crece el wrapper |

### Pendientes nuevos detectados en revisión integral 2026-05-02

1. **`occo --remember -p` doccoumentado y ahora soportado**
   - Se implementó `occo --remember -p <project> [-t type] <texto>`.
   - Cubierto por `tests/run.sh` con `HOME` temporal.

2. **`occo --memory -p proyecto "query"` ahora soportado**
   - Se normalizó parser con `-p|--project` y `-t|--type` cuando hay flags explícitas.
   - Se preservan formas posicionales legacy sin flags.

3. **Desalineación de versión corregida en puntos visibles**
   - `install.sh`, `README.md`, `README.es.md` e `INSTALL.md` fueron alineados a v1.9.3 donde correspondía.
   - Pendiente menor: definir fuente única automatizable de versión.

4. **Conteos doccoumentales corregidos y validados**
   - `occo --help`, `INSTALL.md` y `README.es.md` actualizados a 9 perfiles.
   - `validate.sh` ahora valida conteos reales de perfiles/agentes/skills.

5. **Hooks ahora pasan diff explícito**
   - `pre-commit`: `git diff --cached`.
   - `pre-push`: diff contra upstream o fallback de últimos cambios.

6. **Validación doccoumental inicial implementada**
   - `validate.sh` valida versión, conteos y presencia de soporte doccoumentado para memory project flags.
   - Pendiente: ampliar a más ejemplos públicos si crece la CLI.

7. **Memory frontmatter puede romper YAML con contenido complejo**
   - `summary` usa substring directo del contenido.
   - Recomendación: quotear/escapar frontmatter o mover contenido sensible fuera del YAML.

8. **Test suite funcional inicial creada y ampliada**
   - `tests/run.sh` cubre parser de memoria, `--remember`, timeline, perfiles, hooks fail-closed, `occo --init`, `--compact`, `--doccotor`, instalación fixture y safety guard.
   - Pendiente: ampliar a workflows completos si el wrapper crece.

9. **Rubrics/gates reutilizables añadidos**
   - Inspirado por `dsifry/metaswarm`, se añadieron rubrics livianas para code review, security review y plan review.
   - Decisión: adoptar criterios formales y evidencia antes de copiar orquestación multi-CLI compleja.
   - Agentes impactados: `@reviewer`, `@security-auditor`, `@planner`.

10. **Router natural opcional `occo ask`**
   - Agrega un único comando para interpretar solicitudes en lenguaje natural y asignar agente/workflow probable.
   - Soporta `--dry-run` para previsualizar routing, `--explain` para mostrar routing antes de ejecutar y `--clarify` para pedir contexto puntual loccoal.
   - Decisión: mantener todos los comandos explícitos existentes; `occo ask` es solo una capa opcional de UX.

11. **Bug-hunt hardening posterior a v1.9.4**
   - Se corrigieron bypasses de `safety-guard.js` para `rm -rf` con `$HOME`, `${HOME}`, HOME entrecomillado, subpaths críticos absolutos y separadores shell.
   - `occo --memory` ahora soporta queries multi-palabra sin flags.
   - `track_turn` crea la config si falta y se recupera de `.session` corrupto.
   - `install.sh` usa `mktemp -d` y matching PATH delimitado; `uninstall.sh` no imprime restore si no hubo backup.
   - `install.sh` ahora diagnostica requisitos requeridos/recomendados/opcionales y muestra hints sin instalar paquetes del sistema automáticamente.
   - Tests ampliados en `tests/run.sh`; validaciones reportadas OK: `make check`, `make test`, `./validate.sh`, `bash install.sh --dry-run`, `git diff --check`.

### Correcciones aplicadas en sesión 2026-05-01
Se hizo análisis profundo del estado del proyecto y se aplicaron correcciones funcionales y doccoumentales:
- `occo`: migrado de `opencode -p` a `opencode run` para compatibilidad con OpenCode 1.14.31.
- `occo`: eliminado el intento de usar `opencode --profile`; los perfiles quedan explícitamente como enforcement por prompt injection.
- `hooks/pre-commit`, `hooks/pre-push` y hook generado por `occo --init`: migrados a `opencode run`.
- `install.sh --dry-run`: corregido para no clonar, copiar, escribir config ni modificar PATH; ahora solo muestra plan y sale.
- `install.sh`: banner fue actualizado a v1.9.1 en esa sesión; luego se alineó a v1.9.3 el 2026-05-02.
- `profiles/auto.json`: permisos inválidos `auto` cambiados a `ask`.
- `validate.sh`: ahora valida `opencode.strict.json`, detecta llamadas legacy `opencode -p` / `opencode --profile`, y valida permisos de perfiles contra `ask|allow|deny`.
- `.github/workflows/validate.yml`: añade `shellcheck` para `validate.sh` y amplía check de artefactos de idioma a `skills/`.
- `README.md`, `README.es.md`, `INSTALL.md`: corregidos conteos, explicación de perfiles, snippets de instalación manual y comandos obsoletos.

Validaciones ejecutadas y resultado:
- `./validate.sh` → OK.
- `make check` → OK.
- `bash install.sh --dry-run` → OK, sin modificaciones.
- `git diff --check` → OK.

Estado observado:
- `CONTEXTO_PROYECTO.md` sigue como archivo untracked en git; fue actualizado porque es el doccoumento de continuidad del proyecto.
- `./validate.sh --installed` falló antes de estas correcciones porque la configuración no está instalada en `~/.config/opencode` y `occo` no está en PATH en esta máquina.

### `args` bug en `_occo_run()` (resuelto v1.7)
`args=("$@")` después del while loop dejaba args vacío porque `$@` ya fue consumido.
Fix: el while loop ya llena `args`, se eliminó la línea problemática.

### Artefactos de idioma (resueltos)
LLM generó strings en chino/ruso en agentes/souls/skills. Todos corregidos con `perl -i -pe`.
El último fue `发现问题` en `skills/memory-retrieval/SKILL.md` — corregido en la última sesión.

### Dead code eliminado (última sesión)
`memory_search()` y `memory_save()` eran duplicados obsoletos de `search_memory()` y `create_observation()`. Eliminados.

### Hooks y perfil activo (actualizado 2026-05-02)
Los hooks versionados usan `occo` si está disponible y fallback a `opencode run` si no lo está. Esto mejora propagación de reglas cuando `occo` existe, pero el fallback no aplica perfil activo ni `_occo_run()`.

**Decisión actual:** mantener fallback por compatibilidad, pero doccoumentar que el perfil activo sólo aplica cuando el hook puede invoccoar `occo`.

---

## Cómo retomar trabajo

```bash
# Clonar en /tmp si no existe
[ -d /tmp/opencode-global-config ] || git clone https://github.com/isnardokun/opencode-global-config /tmp/opencode-global-config

# Verificar estado
cd /tmp/opencode-global-config
git log --oneline -10
./validate.sh

# Validar instalación existente
./validate.sh --installed
```

---

## Pendientes conoccoidos (baja prioridad)

1. **Hooks + profile propagation completa** — fallback `opencode run` no aplica perfil activo; refactor sourceable o instalación garantizada de `occo`.
2. **Ampliar test suite funcional** — cubrir workflows completos y más combinaciones del parser CLI si el wrapper crece.
3. **Validación doccoumental automática extendida** — detectar más ejemplos obsoletos y comandos públicos críticos.
4. **Fuente única de versión más automatizada** — `VERSION` existe, pero scripts/doccos aún contienen referencias literales verificadas por `validate.sh`.
5. **Hardening adicional de audit log** — ampliar redacción si aparecen nuevos formatos de secretos.
6. **`opencode.strict.json` `~` paths** — OpenCode probablemente los expande, pero no verificado en runtime real.
7. **Doccoumentar límites de seguridad** — perfiles prompt-enforced, hooks LLM-assisted y safety guard regex-based.
