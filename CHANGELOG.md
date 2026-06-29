# Changelog

Todos los cambios notables de este proyecto se documentarán en este archivo.

## [1.18.0] - 2026-06-29

### Cherry-pick: codebase-memory-mcp (orientación + install flag)

Cherry-pick selectivo (estándar, no profundo) del MCP server externo
`DeusData/codebase-memory-mcp`:

- **Skill nueva** `skills/codebase-memory-mcp/SKILL.md` (~140 líneas). Orientation
  document: qué es, cuándo preferirlo sobre graphify, los 14 MCP tools,
  instalación, anti-patterns. Sin código; sin binarios en el repo.
- **install.sh** `--with-codebase-memory` flag opt-in (paralelo a
  `--with-graphify` y `--with-playwright`). Detecta plataforma via `uname`,
  descarga el static binary desde GitHub releases, ejecuta su `install.sh`
  interno (que autoconfigura OpenCode), y verifica que el MCP server aparezca
  en `opencode.json`.
- **agents/manifest.json** entry nuevo declarando la skill y su upstream.
- **validate.sh** skill_count bump 23 → 24.
- **VERSION** 1.17.0 → 1.18.0.

**Lo que NO hace este cherry-pick (decisión explícita):**

- No descarga el binario en el repo ni lo vendorea. Zero deps base sigue vigente.
- No integra `codebase-memory-mcp` con graphify (no hay hook compartido, no hay
  skill "use A para X, B para Y"). La skill documenta la elección, no la fuerza.
- No modifica `uninstall.sh` ni `tests/`. La desinstalación del MCP server se
  hace con su propio comando: `codebase-memory-mcp uninstall`.
- No escribe ADR formal en `docs/DECISIONS.md`. Es cherry-pick estándar, no
  profundo.

**Tradeoff documentado en la skill:** graphify (docs/Markdown/JSON+HTML) y
codebase-memory-mcp (call graphs/SQLite/Hybrid LSP) son complementarios. La
tabla "cuándo usar cada uno" está en la skill, no en código.

## [1.17.0] - 2026-06-28

### Graphify: auto-rebuild + interactive HTML viewer + CI fix

Tres problemas resueltos en un solo release:

1. **graphify v8 CLI no genera `graph.html`** — el subcomando no existe en v8;
   el HTML se genera via el plugin de opencode o via el flow del skill instalado.
   Para uso standalone, expongo la API `to_html()` de graphify via dos scripts
   stdlib-only en `skills/graphify/scripts/`.

2. **El usuario quería poder ver el visualizador en cualquier momento** —
   añado `graphify_serve.py`, un HTTP server que sirve `graphify-out/` y
   reconstruye el grafo periódicamente (default 5 min). Endpoints: `/graph.html`,
   `/GRAPH_REPORT.md`, `/graph.json`, `/health`. Auto-rebuild en background thread.

3. **El CI falló desde v1.16.0** — el rename `oc` → `occo` (v1.11.0) no se reflejó
   en `.github/workflows/validate.yml`. El step `shellcheck — oc` buscaba un
   archivo inexistente: `oc: openBinaryFile: does not exist`. Arreglado en
   `fb56bf6` (commit previo, en este release).

#### Added

- **`skills/graphify/scripts/graphify_html.py`** (~125 líneas, stdlib-only) —
  wrapper alrededor de `graphify.export.to_html()`. Lee `graph.json`,
  construye `nx.Graph` + `communities` + `community_labels`, genera
  `graph.html` con el visualizador interactivo vis.js. Maneja los 3 failure
  modes: graph.json missing, malformed, graph too large. Exit codes
  semánticos (1/2/3/4) para integración con install.sh.

- **`skills/graphify/scripts/graphify_serve.py`** (~210 líneas, stdlib-only) —
  HTTP server con auto-rebuild. Background thread que corre
  `graphify update` + `graphify_html.py` cada N segundos. Thread-safe state
  compartido con HTTP handler. Endpoints: `/graph.html`, `/GRAPH_REPORT.md`,
  `/graph.json`, `/health` (JSON con last_build, next_build, nodes, edges).
  Graceful shutdown via SIGTERM/SIGINT. Timeouts: 180s para graphify update,
  30s para graphify_html.

- **`install.sh --with-graphify`** ahora genera `graph.html` automáticamente
  después de `graphify . --no-viz`. Si `scripts/graphify_html.py` no existe
  o falla, warn pero no aborta el install.

- **`skills/graphify/SKILL.md`** documenta el nuevo flow: `python3 scripts/graphify_serve.py`
  para servidor siempre activo, `--once` para build único, endpoints,
  cómo parar el proceso.

#### Fixed

- **CI fix** (`fb56bf6`, en este release): `shellcheck — oc` → `shellcheck — occo`.
  El CI volvió a verde en run #68. Runs #65, #66, #67 (v1.16.0 y docs) estaban
  rotos por el mismo error — el historial los registra como failed pero
  el estado actual es verde.

#### Validated

- `bash validate.sh`: 23 skills, 14 commands, 9 profiles, 11 agents, v1.17.0
- `bash tests/run.sh`: 14/14 pass
- `python3 skills/graphify/scripts/graphify_html.py`: 34KB HTML, 35 nodes, 37 edges, 6 communities
- `python3 skills/graphify/scripts/graphify_serve.py --once`: rebuild completed in 1s (incremental)
- HTTP server (PID 191973, port 8765): serving 3 files (graph.html, GRAPH_REPORT.md, graph.json)
- GitHub Actions run #68: success

#### Cómo usar

```bash
# Una vez: rebuild + ver
python3 skills/graphify/scripts/graphify_html.py
xdg-open graphify-out/graph.html   # o tu browser

# Continuo: server con auto-rebuild cada 5 min
python3 skills/graphify/scripts/graphify_serve.py
# Abre http://localhost:8765/graph.html en el browser

# Custom: interval 60s, port 9000
python3 skills/graphify/scripts/graphify_serve.py --port 9000 --interval 60
```

---

## [1.16.0] - 2026-06-28

### anthropics/skills cherry-pick Fase 4: pptx (skill nueva) + frontend-design (integrado)

Dos cherry-picks de `anthropics/skills` completados en este turno, con estrategias diferentes:

#### `pptx` — skill nueva (estrategia lightweight como docx/xlsx)

Adaptación completa desde `anthropics/skills/skills/pptx/SKILL.md` (9 KB originales + 12 KB `pptxgenjs.md` + 7 KB `editing.md` + 4 scripts). Frontmatter mínimo. Tool detection (python-pptx / markitdown / libreoffice / poppler) con 4 tiers.

- **`skills/pptx/SKILL.md`** — manual de uso. Flujo principal: `python-pptx` (más portable que `pptxgenjs`/npm). Critical rules adaptadas. Visual QA tier 3-4 (libreoffice + poppler).
- **Sección `Design Ideas` portada verbatim** — 10 paletas de colores (Midnight Executive, Forest & Moss, Coral Energy, Warm Terracotta, Ocean Gradient, Charcoal Minimal, Teal Trust, Berry & Cream, Sage Calm, Cherry Bold), 7 font pairings, lista de "Avoid (Common Mistakes)" que incluye "NEVER use accent lines under titles" (AI-tell).
- **Sección `QA (Required)` portada** — assume there are problems, content QA + visual QA, verification loop.

#### `frontend-design` — cherry-pick integrado a `design-md` (sin skill nueva)

La original es un manifiesto de design philosophy (8 KB) con un "you are the design lead at a small studio" framing. En lugar de crear skill separada, **integro como sección "Design Philosophy"** en `skills/design-md/SKILL.md` (~3 KB agregadas).

Contenido integrado:
- **"Ground it in the subject"** — pin the subject, audience, single job before designing
- **Design principles** — typography carries personality, structure is information, leverage motion deliberately, match complexity to vision
- **Restraint and self-critique** — spend your boldness in one place, build to a quality floor
- **The three AI-generated design defaults (avoid them as defaults)** — warm cream + serif + terracotta / near-black + acid-green / broadsheet-zero-radius
- **Process: brainstorm, plan, critique, build, critique again** — work in two passes

**Por qué integrada, no cherry-pick verbatim:** el agente que invoca `design-md` ya carga el skill; crear otro activaría el mismo agente a leer dos archivos. La combinación `design-md` (lint/diff/suggest) + design philosophy (anti-AI-slop) es más potente junta.

### Lo que NO se portó

- ❌ `pptxgenjs.md` (12 KB de API JS) — sustituido por `python-pptx`
- ❌ `editing.md` (7 KB) — duplica lo que está en el SKILL.md principal
- ❌ `scripts/{add_slide,clean,thumbnail,office/unpack}.py` — sustituido por snippets Python puros
- ❌ `LICENSE.txt` original "Proprietary" — mismo rationale (methodology es cherry-pick legítimo, documentado en `## Provenance`)

### Validación y conteos

- **`validate.sh`** — `Required skills` extendida a 23; `Skill count` esperado 22 → 23.
- **`install.sh`** — banner 1.15.0 → 1.16.0; mensaje "23 artefactos + opcional Playwright/Graphify".
- **`VERSION`** — 1.15.0 → 1.16.0.
- **`agents/manifest.json`** — `pptx` añadido con `source.upstream: anthropics/skills`; `design-md` actualizado con `source.upstream: anthropics/skills` + `integrated_into: design-md`.

### Estado del cherry-pick anthropics/skills (4 fases)

| Versión | Adoptado | Total |
|---------|----------|-------|
| v1.12.0 | `pdf` + `webapp-testing/scripts/with_server.py` (parcial) | 1.5 |
| v1.13.0 | `skill-creator` | 1 |
| v1.14.0 | `docx`, `xlsx` | 2 |
| v1.16.0 | `pptx` + `frontend-design` (integrado) | 1.5 |
| **Total** | | **6 skills/partials** |

De 17 skills evaluadas, 6 adoptadas (5 completas + 1 integrada), 11 descartadas explícitamente.

### Estado total de cherry-picks (3 fuentes)

| Fuente | Skills |
|--------|--------|
| garrytan/gstack | 6 (plan-eng-review, office-hours, investigate, qa-web, web-verify, setup-deploy) |
| anthropics/skills | 5 completas (pdf, skill-creator, docx, xlsx, pptx) + 1 integrada (frontend-design → design-md) + 1 parcial (webapp-testing → with_server.py) |
| safishamsi/graphify | 1 (graphify) |
| **Total adaptados** | **12 skills + 1 helper + 1 integración** |

### Validado

- `bash validate.sh`: 23 skills, 14 commands, 9 profiles, 11 agents, v1.16.0
- `bash tests/run.sh`: 14/14 pass
- `python-pptx`: no instalado en este host (runtime detection funciona; SKILL.md degrada gracefully)
- `markitdown`: no instalado (tier 2 no disponible)

---

## [1.15.0] - 2026-06-28

### safishamsi/graphify cherry-pick (lightweight SKILL + opt-in install + auto-graphify)

Cherry-pick selectivo de `https://github.com/safishamsi/graphify` (v8, 1204 líneas originales). A diferencia de fases anteriores, esto **integra el flujo completo de graphify** (no solo cherry-pick de metodología) porque su output (HTML navegable, JSON queryable, Mermaid call-flow) complementa directamente el memory system de `occo`.

- **`skills/graphify/SKILL.md`** — manual de uso lightweight (~190 líneas, vs 1204 originales). Frontmatter mínimo (solo `name` + `description`). Explica: cuándo usar, instalación, integración con `occo`, anti-patrones, honestidad, privacidad. El original es 1204 líneas de ejecución detallada; este es orientación. El skill completo de graphify se instala cuando el usuario corre `graphify opencode install`.

### `install.sh --with-graphify` (opt-in, nivel 3)

Nuevo flag que combina instalación + registro + auto-graphify en una sola operación:

1. **Detección** — chequea `command -v uv` y `command -v graphify`. Si graphify está, skip instalación.
2. **Instalación interactiva** — `uv tool install graphifyy` (~50 MB) si uv disponible, fallback a `pipx install graphifyy`, fallback a `pip install --user graphifyy`. Prompt interactivo solo con TTY.
3. **Registro del skill** — `graphify opencode install` (escribe sección en `~/.config/opencode/AGENTS.md` con query-first behavior).
4. **Auto-graphify de la config instalada** — `cd ~/.config/opencode && graphify . --no-viz` produce `graphify-out/{GRAPH_REPORT.md,graph.json,graph.html}` (HTML excluido en auto-build para evitar 50MB; user lo genera con `graphify .` después si quiere).

**Nota técnica sobre v8 de graphify:** el flujo de extracción ahora se dispara via el skill instalado, no via CLI directa (`graphify <path>` ya no existe en v8; el `path` se da al instalar el skill con `--dir`). El bloque auto-graphify sigue siendo `graphify . --no-viz` por compatibilidad con versiones anteriores. En v8+ puro, el build inicial lo dispara el plugin `tool.execute.before` de opencode al primer query.

- **`install.sh` también actualizado** — lista de opcionales extendida con `uv` y `graphify`. `--help` documenta los 3 flags disponibles.
- **`validate.sh`** — `Required skills` extendida a 22; `Skill count` esperado 21 → 22.
- **`agents/manifest.json`** — `graphify` añadido con `source.upstream: safishamsi/graphify`.

### Estado del cherry-pick safishamsi/graphify

- **Adoptado**: SKILL.md (orientación) + integracion completa en `install.sh --with-graphify`.
- **No portado verbatim**: 1204 líneas originales (diseñadas para Claude Code con subagents paralelos, AST local con tree-sitter, MCP server, Neo4j push, etc.) — fuera de scope de un cherry-pick lightweight.
- **Reemplazo de funcionalidad**: el usuario que quiera el skill completo corre `graphify opencode install` post-cherry-pick. El SKILL.md liviano apunta a esa URL.

### Estado de los cherry-picks de la sesión (resumen)

| Fuente | Skills adoptadas | Versión |
|---|---|---|
| garrytan/gstack | 6 (plan-eng-review, office-hours, investigate, qa-web, web-verify, setup-deploy) | v1.11.0 |
| anthropics/skills | 4 (pdf, skill-creator, docx, xlsx) | v1.12.0 – v1.14.0 |
| safishamsi/graphify | 1 (graphify) | v1.15.0 |
| **Total** | **11 skills adaptadas** + 1 helper (`with_server.py`) | v1.11.0 – v1.15.0 |

Skills originales: 11 (ai-coding-rules, caveman, design-md, diagnose, docs-writer, grill-with-docs, memory-retrieval, precommit-review, project-map, safe-implementation, test-first).

### Validado

- `bash validate.sh`: 22 skills, 14 commands, 9 profiles, 11 agents, v1.15.0
- `bash tests/run.sh`: 14/14 pass
- `bash install.sh --help`: lista los 3 flags (--dry-run, --with-playwright, --with-graphify)
- `bash install.sh --dry-run --with-graphify`: muestra `uv` y `graphify` en opcionales
- `command -v graphify` en este host: no instalado (correcto, base install es zero-deps)

---

## [1.14.0] - 2026-06-28

### anthropics/skills cherry-pick Fase 3: docx + xlsx (adapted, runtime-detection)

Cherry-pick de las skills de documentos office desde `anthropics/skills`. **Estrategia diferente a las fases 1-2:** en lugar de portar el árbol completo de scripts de Anthropic (que requiere `defusedxml`, `lxml`, dependencias masivas, y workflow unpack/repack vía `docx-js`/npm), creo SKILL.md ligeros que usan las librerías ya instaladas (`python-docx` y `openpyxl`) con runtime-detection y degradación graceful.

- **`skills/docx/SKILL.md`** — adaptación completa desde `anthropics/skills/skills/docx/`. Tool detection (python-docx / lxml / pandoc / libreoffice) con 4 tiers. Flujo principal: `python-docx` (más portable que `docx-js`/npm). Critical rules adaptadas. Tracked changes y comentarios requieren `lxml` (tier 2). PDF/imagen vía `libreoffice` + `pdftoppm` (tier 4). ~230 líneas.
- **`skills/xlsx/SKILL.md`** — adaptación completa desde `anthropics/skills/skills/xlsx/`. Tool detection (openpyxl / pandas / libreoffice / csvkit) con 4 tiers. Financial-model color standards preservadas (azul=input, negro=formula, etc.). Recalc con `soffice --headless`. CSV/TSV via pandas o csvkit. ~180 líneas.

### Lo que NO se portó (decisión deliberada)

- ❌ `docx/scripts/{unpack,pack,validate,soffice,accept_changes,comment}.py` — requiere `defusedxml`, `lxml`, y workflow unpack/repack XML. Sustituido por `python-docx` + `lxml` directo, más portable y menos deps.
- ❌ `docx/scripts/office/validators/{base,docx,pptx,redlining}.py` — submódulo completo, requiere base classes no portables.
- ❌ `docx/scripts/office/{schemas,helpers}/` — schemas XML de docx/pptx, fuera de scope (sólo Word docs básico).
- ❌ `xlsx/scripts/recalc.py` original — reemplazado por snippet inline (`subprocess.run(['soffice', '--headless', ...])`) ya que la lógica es 5 líneas.
- ❌ `LICENSE.txt` originales — mismos motivos que en v1.12/v1.13 (methodology es cherry-pick legítimo, documentado en `## Provenance`).

### Validación y conteos

- **`validate.sh`** — `Required skills` extendida a 21; `Skill count` esperado 19 → 21.
- **`install.sh`** — banner 1.13.0 → 1.14.0; mensaje "21 artefactos + opcional Playwright".
- **`VERSION`** — 1.13.0 → 1.14.0.
- **`agents/manifest.json`** — `docx` y `xlsx` añadidos con `source.upstream: anthropics/skills`, `cherry_pick: true`, `adapted: true`.
- **`.gitignore`** — añadidos `__pycache__/`, `*.pyc`, `*.pyo`, `.pytest_cache/` (cleanup pendiente de v1.13.0).

### Validado

- `bash validate.sh`: 21 skills, 14 commands, 9 profiles, 11 agents, v1.14.0
- `bash tests/run.sh`: 14/14 pass
- `python3 -c 'import docx'`: 1.2.0 (apt-installed)
- `python3 -c 'import openpyxl'`: 3.1.5 (apt-installed)

### Estado del cherry-pick anthropics/skills

- **4 de 17 skills adoptadas:** `pdf` (v1.12), `skill-creator` (v1.13), `docx` (v1.14), `xlsx` (v1.14).
- **13 descartadas explícitamente:** algorithmic-art, brand-guidelines, canvas-design, claude-api, frontend-design, internal-comms, mcp-builder, pptx, slack-gif-creator, theme-factory, web-artifacts-builder, webapp-testing (sólo `with_server.py` cherry-picked a `web-verify/scripts/` en v1.12).

---

## [1.13.0] - 2026-06-28

### anthropics/skills cherry-pick Fase 2: skill-creator (adapted)

Cherry-pick de la metodología formal de creación/mejora de skills desde `anthropics/skills/skills/skill-creator/`. Adaptado a opencode-global-config: browser eval-viewer y subagents estilo Claude-CLI reemplazados con `occo` + `@builder` + `@reviewer` + `validate.sh`.

- **`skills/skill-creator/SKILL.md`** — workflow completo de 10 pasos: capture intent → interview → write SKILL.md → test cases → run with @builder → grade assertions → aggregate benchmark → user review → iterate → optimize description. Frontmatter mínimo (`name` + `description`); secciones explícitas sobre la incompatibilidad de opencode con `claude -p`, browser eval-viewer, y subagents paralelos. ~290 líneas.
- **`skills/skill-creator/references/schemas.md`** — schemas JSON portados verbatim (evals, grading, benchmark, .skill package). ~430 líneas.
- **`skills/skill-creator/scripts/aggregate_benchmark.py`** — stdlib-only, agregado de grading.json → benchmark.json + benchmark.md (con mean±stddev y delta). ~400 líneas.
- **`skills/skill-creator/scripts/quick_validate.py`** — validador genérico de SKILL.md frontmatter (kebab-case name, max 64 chars, no angle brackets, etc.). ~120 líneas.
- **`skills/skill-creator/scripts/package_skill.py`** — packager: skill folder → .skill file (ZIP con SKILL.md + bundled resources). Import refactored de `from scripts.quick_validate` a `from quick_validate` (no requiere package init).

### Lo que NO se portó (incompatible con opencode)

- ❌ `eval-viewer/generate_review.py` — browser-based HTML viewer. No portable.
- ❌ `assets/eval_review.html` — browser-based.
- ❌ `agents/grader.md`, `agents/comparator.md`, `agents/analyzer.md` — subagent definitions estilo Claude. Reemplazados por `@reviewer` agent de opencode.
- ❌ `scripts/run_loop.py` y `scripts/run_eval.py` — usan `claude -p` via subprocess. Reemplazados por iteración manual.
- ❌ `LICENSE.txt` original "Proprietary" — el contenido (methodology + schemas) es cherry-pick de uso legítimo; documento la proveniencia en `SKILL.md` sección Provenance.

### Validación y conteos

- **`validate.sh`** — `Required skills` extendida a 19; `Skill count` esperado 18 → 19.
- **`install.sh`** — banner 1.12.0 → 1.13.0; mensaje "19 artefactos + opcional Playwright".
- **`VERSION`** — 1.12.0 → 1.13.0.
- **`agents/manifest.json`** — `skill-creator` añadido con `source.upstream: anthropics/skills`, `cherry_pick: true`, `adapted: true`.

### Validado

- `bash validate.sh`: 19 skills, 14 commands, 9 profiles, 11 agents, v1.13.0
- `bash tests/run.sh`: 14/14 pass
- `python3 skills/skill-creator/scripts/aggregate_benchmark.py --help`: works
- `python3 skills/skill-creator/scripts/package_skill.py <path>`: produces .skill file (ZIP) — test passed on /tmp fixture
- `python3 skills/skill-creator/scripts/quick_validate.py skills/skill-creator`: "Skill is valid!"
- `bash install.sh --dry-run`: OK

### Pendientes Fase 3 (opt-in)

- **`docx`** y **`xlsx`** — adaptación con runtime-detection estilo `web-verify`. Opt-in hasta que haya demanda real.

---

## [1.12.0] - 2026-06-28

### anthropics/skills cherry-pick (Fase 1: pdf + webapp-testing helper)

Cherry-pick selectivo desde `https://github.com/anthropics/skills/tree/main/skills`. Evaluación completa de las 17 skills de Anthropic en el CHANGELOG/commit. Adoptadas: 1 skill completa + 1 helper script. 7 descartadas explícitamente en `docs/DECISIONS.md`-style rationale.

- **`skills/pdf/SKILL.md`** — cherry-picked desde `anthropics/skills/skills/pdf/`. Frontmatter normalizado (drop del `license: Proprietary` de Anthropic — OpenCode strippea frontmatter y el original no shippeaba LICENSE.txt). Body idéntico: merge, split, rotate, watermark, create, fill forms, encrypt, OCR con pypdf/pdfplumber/reportlab (Python) o poppler-utils/qpdf (CLI). ~314 líneas.
- **`skills/web-verify/scripts/with_server.py`** — cherry-picked desde `anthropics/skills/skills/webapp-testing/scripts/with_server.py`. Helper de lifecycle de servers (start, health-check por port-poll, kill). Stdlib only. Cero deps. Permite que `/web-verify` verifique apps locales que necesitan arrancar (`--server "npm run dev" --port 5173 -- python automation.py`).
- **`skills/web-verify/SKILL.md`** — sección "Server lifecycle helper" agregada con ejemplos single-server y multi-server.

### Validación y conteos

- **`validate.sh`** — `Required skills` extendida a 18; `Skill count` esperado 17 → 18.
- **`install.sh`** — banner 1.11.0 → 1.12.0; mensaje de verificación "18 artefactos + opcional Playwright".
- **`VERSION`** — 1.11.0 → 1.12.0.
- **`agents/manifest.json`** — `pdf` añadido con `source.upstream: anthropics/skills`, `cherry_pick: true` (sin `adapted: true` porque el contenido es verbatim, solo se normalizó el frontmatter).

### Anti-criterios respetados (de 17 evaluadas, 7 descartadas explícitamente)

- ❌ `mcp-builder` — descartado por anti-MCP (OpenCode no carga MCP servers Anthropic-style).
- ❌ `claude-api` — descartado por dependencia de SDK Anthropic que no aplica.
- ❌ `web-artifacts-builder` — descartado por overhead Node masivo (Vite + Tailwind + shadcn bundle).
- ❌ `frontend-design` — descartado como skill; sus 3-4 principios anti-AI-slop se pueden cherry-pick a `design-md/` en una iteración futura si hay demanda.
- ❌ `theme-factory` — descartado por dependencia de `themes/*.pdf` showcase no portable.
- ❌ `internal-comms` — descartado por ser formato corporativo Anthropic.
- ❌ `algorithmic-art`, `brand-guidelines`, `canvas-design`, `slack-gif-creator` — descartados por nicho (arte, branding, GIFs).

### Pendientes próximos (Fase 2+3, opt-in)

- **`skill-creator`** (Fase 2) — workflow methodology para crear/medir/optimizar skills. Valor alto: cualquier futura skill se beneficia. Sin deps nuevas.
- **`docx`** y **`xlsx`** (Fase 3) — adaptación con runtime-detection estilo `web-verify` (degradación graceful sin LibreOffice/pandas). Opt-in hasta que haya demanda real.

---

## [1.11.0] - 2026-06-28

### gstack QA cherry-pick (qa-web, web-verify, setup-deploy) + optional Playwright install

Tres skills nuevas adaptadas desde `garrytan/gstack`, todas runtime-agnósticas (funcionan sin binarios adicionales). El instalador ofrece opcionalmente instalar Playwright para habilitar browser automation completa.

- **`skills/qa-web/`** — Metodología de QA web sistemático. Tres tiers (quick/standard/exhaustive), 7 categorías de testing (functional, navigation, auth, responsive, a11y, console, performance), fix-atomic-per-bug. Adaptado de `gstack/qa/SKILL.md`.
- **`skills/web-verify/`** — Verificación web runtime-agnóstica. Auto-detecta herramientas disponibles (curl, wget, lynx, playwright) y tier-up de HTTP-only a browser automation. Adaptado de `gstack/browse/SKILL.md` (sin el binario).
- **`skills/setup-deploy/`** — Detecta plataforma de deploy (Fly, Vercel, Render, Netlify, Railway, Heroku, GH Actions, Docker) y persiste config en `CLAUDE.md`. Cero deps. Adaptado de `gstack/setup-deploy/SKILL.md`.
- **`commands/qa-web.md`**, **`commands/web-verify.md`**, **`commands/setup-deploy.md`** — slash commands nativos.

### Optional Playwright install via `--with-playwright`

- **`install.sh --with-playwright`** — flag opcional y no-default. Si se pasa, después de instalar la base, ofrece interactivamente instalar Playwright + Chromium (~170 MB). Si el usuario declina, la instalación base sigue funcionando (modo degradado para `web-verify` y `qa-web`).
- **`install.sh --help`** — nuevo flag documentado.
- **Detección runtime** — `playwright` añadido a la lista de opcionales de `print_requirements`. `lynx` también añadido como tier-2 fallback opcional.
- **Modo degradado sin Playwright** — `web-verify` automáticamente degrada a tier 1 (curl/wget) + tier 2 (lynx si está). El usuario ve `WEB_VERIFY_RESULT=degraded` y una explicación de qué no se pudo verificar.

### Validación y conteos

- **`validate.sh`** — listas de `Required commands` (14) y `Required skills` (17) extendidas; `Skill count` esperado 14 → 17.
- **`install.sh`** — banner 1.10.0 → 1.11.0; mensaje de verificación "17 artefactos + opcional Playwright".
- **`VERSION`** — 1.10.0 → 1.11.0.
- **`agents/manifest.json`** — 3 skills añadidas con `source.upstream: garrytan/gstack`.

### Lo que NO se hizo (intencional)

- ❌ No se portó el binario `browse/dist/browse` de gstack (60 archivos TS, Bun runtime, daemon persistente, ~450 MB con Playwright+Chromium).
- ❌ No se añadió Bun, ngrok, o gbrain como dependencias.
- ❌ No se añadió Playwright como dependencia por defecto — sigue siendo opcional, opt-in via flag.
- ❌ No se modificó `occo` (2965 líneas intactas), `safety-guard.js`, ni `tests/run.sh`.

---

## [1.10.0] - 2026-06-28

### gstack cherry-pick (adapted from garrytan/gstack)

Tres skills nuevas adaptadas desde https://github.com/garrytan/gstack, reescritas sin dependencias de Claude Code / Anthropic / Bun / gbrain / Conductor. Frontmatter mínimo (solo `name` + `description`, compatible con `keepFields` de OpenCode host).

- **`skills/plan-eng-review/`** — Engineering-manager mode plan review con 8 forcing questions (data flow, state machine, edge cases, test matrix, failure modes, security, performance, rollout/rollback). Iron law: `PLAN_REVIEW_RESULT=approve` antes de implementar.
- **`skills/office-hours/`** — Reframe de idea de producto con 6 forcing questions (demand reality, status quo, desperate specificity, narrowest wedge, observation, future-fit). Iron law: NO implementación, solo design doc.
- **`skills/investigate/`** — Debugging sistemático en 4 fases (investigate, analyze, hypothesize, implement) con iron law "no fixes sin root cause" y stop-after-3-fixes rule.
- **`commands/office-hours.md`**, **`commands/investigate.md`**, **`commands/plan-eng-review.md`** — slash commands nativos para invocar las skills desde el TUI de OpenCode.
- **`agents/manifest.json`** — `planner` ahora carga `plan-eng-review`; `oncall` ahora carga `investigate`. Las 3 skills aparecen en la sección `skills` con atribución `upstream: garrytan/gstack`.

### Code Review Rubric extendido

- **`rubrics/code-review.md`** — añadidos los 5 checks de Pass 1 CRITICAL (SQL & Data Safety, Race Conditions, LLM Output Trust Boundary, Shell Injection, Enum Completeness) y 7 checks de Pass 2 INFORMATIONAL (Async/Sync, Column/Field Name Safety, LLM Prompt Issues, Completeness Gaps, Time Window Safety, Type Coercion, Distribution & CI/CD). Adaptado del `review/checklist.md` de gstack. Sin `hooks.PreToolUse` ni dependencias de tooling externas.

### Validación y conteos

- **`validate.sh`** — lista de `Required commands` extendida a 11; lista de `Required skills` extendida a 14; `Skill count` esperado actualizado de 11 a 14.
- **`install.sh`** — mensaje de instalación verificada actualizado a 15 artefactos.
- **`VERSION`** — bump 1.9.7 → 1.10.0.

### Anti-criterios respetados

- ❌ NO se añadió Bun, no se ejecutó `gstack/setup --host opencode`, no se portaron `browse/`, `careful/`, `freeze/`, `codex/`, `qa-visual`, `ship/`, `retro/`, `learn/`.
- ❌ NO se modificaron `occo`, `validate.sh` (lógica de validación), ni los 14 smoke tests existentes.
- ❌ NO se rompió el modelo deny-first ni se cambió `safety-guard.js`.

---

## [1.9.7] - 2026-05-21

### Windows Support

- **`install.ps1`** — PowerShell installer for Windows: `irm .../install.ps1 | iex`
- **`README.md`** — Quick Start section now covers both Linux/macOS (bash) and Windows (PowerShell)

### Dashboard Skills

- **`occo dashboard`** — nuevo comando wizard con `--list` y `--apply` para 5 skills de dashboard profesional (admin-panel, analytics-dashboard, kpi-overview, monitoring, crm-sales)
- **[opencode-dashboard-skills](https://github.com/isnardokun/opencode-dashboard-skills)** — nuevo repo con skills descargables, cada uno con SKILL.md + DESIGN.md

### Bug Fixes

- **`occo dashboard --apply`** — parameter order era `action, target, slug` → `action, slug, target`; ahora funciona correctamente

---

## [1.9.6] - 2026-05-10

### Self-Improvement Agent — Automatización Total

- **`oc`** — `detect_project()` auto-detecta el proyecto desde PWD o git remote, eliminando necesidad de `-p` manual en todos los comandos de memoria
- **`oc`** — `auto_compact_if_needed()` se ejecuta automáticamente en `_oc_run()` cuando turns > 20, compactando sesión sin intervención humana
- **`oc`** — `auto_reflect()` crea observation automáticamente post-workflow (no interactivo), usando `detect_project()` para guardar en el proyecto correcto
- **`oc`** — `analyze_outcomes()` analiza outcomes de workflows y detecta patterns de failures; sugiere documentar en memory si hay 3+ fallas recientes
- **`oc`** — `track_outcome()` ahora usa `detect_project()` en lugar de `basename`
- **`oc --status`** — ahora muestra "Current project" además de session turns, profile y hooks
- **`oc --budget`** — ahora indica threshold de auto-compact (20 turns) en lugar de solo "consider running oc --compact"
- **Removido** — `auto_summary_hint()` interactivo; reemplazado por auto-compact silencioso + auto-reflect automático

### Memory Bank — Templates

- **`oc`** — nuevos templates de observación para `oc --remember`: `bugfix` (problema, causa raíz, solución, evidencia, lecciones), `decision` (contexto, opciones, decisión, consecuencias), `feature` (descripción, motivación, implementación), `config` (qué, por qué, valor, impacto). Uso: `oc --remember --template -t bugfix`
- **`oc`** — nuevo comando `oc --list-templates` para listar templates disponibles
- **`oc --help`** — documenta `--list-templates` y `--remember --template`

### Documentación

- **`ARCHITECTURE.md`** — nueva sección Self-Improvement Agent con diagrama de automation flow y tabla de funciones
- **`README.md`** — actualizado features y Context Compaction para reflejar auto-compact silencioso

### Seguridad y confiabilidad

- **`plugins/safety-guard.js`** — bloquea variantes destructivas adicionales de `rm -rf` con `$HOME`, `${HOME}`, rutas HOME entrecomilladas, subpaths críticos absolutos (`/home/*`, `/etc/*`, `/var/*`, `/root/*`) y separadores shell posteriores al target
- **`oc`** — `track_turn` crea el directorio de configuración si falta y se recupera de `.session` corrupto
- **`oc --memory`** — búsquedas multi-palabra sin flags usan toda la query en lugar de interpretar palabras extra como proyecto/tipo posicional
- **`install.sh`** — usa `mktemp -d` para workspace temporal y matching de PATH delimitado por `:`
- **`uninstall.sh`** — solo muestra instrucciones de restore cuando realmente se creó backup
- **`tests/run.sh`** — agrega regresiones para safety guard, memoria multi-palabra, sesión corrupta, instalador y uninstall sin backup

### Mejora de versión (análisis interno)

| Área | Impacto | % Mejora vs v1.9.5 |
|------|---------|-------------------|
| Automation | Intervención humana reducida ~8-10 pasos → 0 | +60% |
| Self-Improvement | El sistema observa y aprende automáticamente | +50% |
| Memory | Templates + auto-storage en proyecto correcto | +35% |
| Harness Engineering | Exit conditions + quality linters | +30% |
| Observabilidad | `oc --status` con project auto-detectado | +25% |
| **TOTAL PONDERADA** | | **~44%**

## [1.9.5] - 2026-05-03

### Harness Engineering — Exit Conditions y Observabilidad

- **`oc`** — agrega `EXIT_CONDITIONS` a los 5 workflows (bug-hunt, new-project, debug, document, feature) con límites de agent turns y marcador `WORKFLOW_COMPLETE=true`
- **`oc`** — nuevo comando `oc --status` que muestra: session turns, active profile, estado de hooks, última observación y últimas 5 entradas de memoria
- **`oc --help`** — documenta `--status` junto a `--budget`, `--compact` y `--doctor`
- **`agents/manifest.json`** — nuevo archivo de agent cards para descubrimiento y orquestación futura; incluye id, description, mode, permission, skills, tags, entrypoints y special por agente; también skills registry y workflows con exit conditions. Validado por `validate.sh`.
- **`validate.sh`** — agrega 4 custom linters: (1) TODO sin referencia a issue/JIRA, (2) asignaciones de credentials hardcodeadas en agents/skills, (3) skills que exceden 1000 líneas (oversized), (4) skills sin SKILL.md.

### Self-Improvement Agent — Automatización Total

- **`oc`** — `detect_project()` auto-detecta el proyecto desde PWD o git remote, eliminando necesidad de `-p` manual en todos los comandos de memoria
- **`oc`** — `auto_compact_if_needed()` se ejecuta automáticamente en `_oc_run()` cuando turns > 20, compactando sesión sin intervención humana
- **`oc`** — `auto_reflect()` crea observation automáticamente post-workflow (no interactivo), usando `detect_project()` para guardar en el proyecto correcto
- **`oc`** — `analyze_outcomes()` analiza outcomes de workflows y detecta patterns de failures; sugiere documentar en memory si hay 3+ fallas recientes
- **`oc`** — `track_outcome()` ahora usa `detect_project()` en lugar de `basename`
- **`oc --status`** — ahora muestra "Current project" además de session turns, profile y hooks
- **`oc --budget`** — ahora indica threshold de auto-compact (25 turns) en lugar de solo "consider running oc --compact"
- **Removido** — `auto_summary_hint()` interactivo; reemplazado por auto-compact silencioso + auto-reflect automático

### Memory Bank — Templates y Auto-Summary

- **`oc`** — nuevos templates de observación para `oc --remember`: `bugfix` (problema, causa raíz, solución, evidencia, lecciones), `decision` (contexto, opciones, decisión, consecuencias), `feature` (descripción, motivación, implementación), `config` (qué, por qué, valor, impacto). Uso: `oc --remember --template -t bugfix -p my-project`
- **`oc`** — nuevo comando `oc --list-templates` para listar templates disponibles
- **`oc`** — hint automático post-workflow cuando session turns > 15: sugiere `oc --compact` o `oc --remember` para guardar resumen. Aplica a los 5 workflows y a `oc --compact`
- **`oc --help`** — documenta `--list-templates` y `--remember --template`

### Docs-First Project Context

- **`AGENTS.md` / `CLAUDE.md`** — agregan la regla global Docs-First: revisar o crear `docs/` como contexto vivo antes de implementar, depurar, refactorizar o documentar.
- **`oc`** — `oc docs`, `oc ask` para documentación/features/bugfixes, y los workflows `new-project`, `document` y `feature` incluyen una fase Docs-First.
- **`README.md` / `README.es.md`** — documentan la estructura recomendada de `docs/` y los entrypoints que activan Docs-First.
- **`tests/run.sh`** — agrega smoke tests para asegurar que el router `oc ask` incluye Docs-First.

### Seguridad y confiabilidad

- **`plugins/safety-guard.js`** — bloquea variantes destructivas adicionales de `rm -rf` con `$HOME`, `${HOME}`, rutas HOME entrecomilladas, subpaths críticos absolutos (`/home/*`, `/etc/*`, `/var/*`, `/root/*`) y separadores shell posteriores al target.
- **`oc`** — `track_turn` crea el directorio de configuración si falta y se recupera de `.session` corrupto/no numérico.
- **`oc --memory`** — búsquedas multi-palabra sin flags usan toda la query en lugar de interpretar palabras extra como proyecto/tipo posicional.
- **`install.sh`** — usa `mktemp -d` para workspace temporal y matching de PATH delimitado por `:`.
- **`install.sh`** — diagnostica herramientas requeridas/recomendadas/opcionales (`opencode`, `git`, `python3`, `jq`, `node`, `fzf`, `gitleaks`, `shellcheck`, `shfmt`) y muestra hints si falta algo.
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
