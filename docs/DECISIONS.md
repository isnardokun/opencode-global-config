# Decisiones Técnicas

Este documento registra las decisiones arquitectónicas y de diseño tomadas para `opencode-global-config`. Es un resumen ejecutivo. El detalle de cada decisión (incluyendo tradeoffs, anti-criterios, y razonamiento) está en `CONTEXTO_PROYECTO.md` (raíz) y `CHANGELOG.md` (raíz).

| Fecha | Decisión | Justificación | Status |
|-------|----------|---------------|--------|
| 2026-05-01 | 9 perfiles deny-first gradient | OpenCode no tiene perfiles nativos; implementamos enforcement por prompt injection. | accepted |
| 2026-05-01 | Plugin safety-guard.js (ESM) en lugar de PreToolUse hooks | OpenCode strippea frontmatter hooks; usamos el plugin nativo con `tool.execute.before`. | accepted |
| 2026-05-01 | Sistema de memoria file-based (JSONL) en lugar de vector DB | Sin deps externas, versionable, auditable, offline. | accepted |
| 2026-05-01 | `occo` wrapper bash (~106 KB) en lugar de TypeScript CLI | Zero deps, audit-friendly, compatible con hooks git. | accepted |
| 2026-05-02 | Frontmatter mínimo (`name` + `description` solamente) en skills | OpenCode strippea el resto via `keepFields`. | accepted |
| 2026-05-02 | Hooks git fail-closed con gate LLM (`HOOK_REVIEW_RESULT=pass\|fail`) | Más estricto que PreToolUse agent-side; gated deterministically. | accepted |
| 2026-05-03 | Self-Improvement Agent (auto_compact, auto_reflect) | Reduce drift de sesiones largas sin intervención manual. | accepted |
| 2026-05-21 | install.ps1 (Windows) paralelo a install.sh | Mismo flujo, PowerShell en lugar de bash. | accepted |
| 2026-06-28 | Rename `oc` → `occo` (canónico) | Install.sh siempre usó `occo`; archivo local era inconsistente. | accepted (v1.11.0) |
| 2026-06-28 | Cherry-pick selectivo de `garrytan/gstack` (6 skills) | 23 skills de gstack, mayoría acopladas a Bun/Claude-CLI/Anthropic. Solo las portables se adaptaron. | accepted (v1.11.0) |
| 2026-06-28 | Tiered runtime-detection en `web-verify` | Default zero-deps; upgrade opcional a Playwright. | accepted (v1.11.0) |
| 2026-06-28 | `install.sh --with-playwright` flag opt-in | Playwright (~170 MB) no es default. Usuario decide. | accepted (v1.11.0) |
| 2026-06-28 | html2text como fallback tier 2 para `web-verify` | lynx requiere apt con sudo; html2text es Python stdlib-ish. | accepted (v1.11.x) |
| 2026-06-28 | Cherry-pick de `anthropics/skills` F1: `pdf` + `with_server.py` | `pdf` llena hueco cotidiano; `with_server.py` permite verificar apps locales. | accepted (v1.12.0) |
| 2026-06-28 | Refactor de ejemplos con passwords hardcoded a `os.environ.get()` | Custom linter detectaba falsos positivos; refactor mantiene el ejemplo. | accepted (v1.12.0) |
| 2026-06-28 | install.sh `cp -r` fix: clear dst before copy | Bug pre-existente: subdirs no se actualizaban en reinstall. | accepted (v1.12.0) |
| 2026-06-28 | Cherry-pick de `anthropics/skills` F2: `skill-creator` | Methodology para crear/medir/optimizar skills. Sin Claude-CLI deps. | accepted (v1.13.0) |
| 2026-06-28 | Cherry-pick de `anthropics/skills` F3: `docx` + `xlsx` | Estrategia lightweight con python-docx y openpyxl (más portable que unpack/repack XML). | accepted (v1.14.0) |
| 2026-06-28 | Cherry-pick de `safishamsi/graphify` v8: SKILL + auto-install | Lightweight orientation skill (~190 líneas vs 1204 originales). Skill completo via `graphify opencode install` post-cherry-pick. | accepted (v1.15.0) |
| 2026-06-28 | `install.sh --with-graphify` flag opt-in | graphifyy (~50 MB) no es default. uv tool install → pipx → pip fallback. | accepted (v1.15.0) |
| 2026-06-29 | `install.sh --with-codebase-memory` flag opt-in | code$base-memory-mcp v0.6.0 (~30 MB) no es default. Descarga binario desde GitHub releases + ejecuta su install.sh interno. | accepted (v1.18.0) |
| 2026-06-29 | Discovery validation gap: skills/*/SKILL.md frontmatter check | v1.20.0 close: validate.sh ahora cubre `skills/*/SKILL.md` además de `agents/` y `commands/`. Diseño-md había perdido frontmatter en v1.16.0 integration y el linter no lo detectó. | accepted (v1.20.0) |
| 2026-06-29 | Workflow prompts en `occo` son strings inline; extraer a `workflows/*.md` | v1.22.0: prompts de 5 workflows (bug-hunt, new-project, debug, document, feature) se mueven de bash a archivos Markdown. Enable iteración de prompts sin release de occ + tests de regresión. | accepted (v1.22.0) |
| 2026-06-29 | NO migrar install `--with-codebase-memory` a `opencode mcp add` | Probe en v1.22.0: `opencode mcp add` en OpenCode 1.x es **interactivo** (no acepta flags de nombre/comando por CLI). Su output es solo el help. Mantenemos install con curl + jq que es scriptable. Ver ADR-1. | accepted (v1.22.0) |
| 2026-06-29 | Mantener occ JSONL memory + agregar ADR sobre dual-memory | occ escribe memoria de proyecto a `~/.config/opencode/memory/index.jsonl`. opencode también tiene su propia SQLite (`~/.local/share/opencode/`). Los dos sistemas corren en paralelo, no se sincronizan, y la decisión es consciente. Ver ADR-2. | accepted (v1.22.0) |

## Architecture Decision Records (ADRs)

Detalle de las decisiones que requieren contexto extenso. Las filas de la tabla resumen; las secciones siguientes son el racional completo.

### ADR-1: install.sh mantiene curl+jq para CBM en lugar de migrar a `opencode mcp add`

**Contexto.** El plan de release v1.22.0 proponía migrar el flujo de registro del MCP server `codebase-memory-mcp` desde "descargar binario + ejecutar su install.sh interno" hacia un único comando `opencode mcp add codebase-memory-mcp --command ...`. Esto eliminaría ~80 líneas de código propio de install.sh y aprovecharía la API nativa del MCP en OpenCode 1.x.

**Decisión v1.22.0: mantener curl + jq.**

Razones:

1. `opencode mcp add` en OpenCode 1.x (probe con `opencode --version` = la del host) tiene **solo `--help/--version/--log-level/--print-logs/--pure` como flags**. No acepta `name` ni `command` por línea de comandos. Su único comportamiento al ejecutarse es imprimir su help.

2. **Es interactivo**. No descubrí flags `--non-interactive`, `--json`, ni equivalente. Pipeline stdin ni flags adicionales.

3. Mientras el comando sea interactivo, install.sh no puede registrar el MCP server de manera no-interactiva. Para preservar zero-deps + scriptable, mantenemos el flujo actual que usa `codebase-memory-mcp install -y` (que **sí** es no-interactivo), combinado con mutate de `opencode.json` vía `jq`.

**Tradeoffs aceptados:**

- ~80 líneas adicionales en install.sh.
- Drifteo potencial con el binario upstream si su `install` subcommand cambia. Mitigación: el test E2E en `tests/run.sh` verifica que install.sh llama correctamente a `install -y`.

**Trigger para re-evaluar:** cuando `opencode mcp add` acepte `--name`/`--command`/`--json` por CLI, retomar la migración y simplificar install.sh.

**Conocimiento reproducido por:** `@architect`, probe en v1.22.0 (commit actual).

### ADR-2: occ y opencode mantienen dos sistemas de memoria en paralelo

**Contexto.** `occ` mantiene un sistema de memoria de proyecto file-based: `~/.config/opencode/memory/index.jsonl` + `memory/projects/<name>/obs_<id>.md` + `memory/outcomes/`. opencode 1.x por su parte tiene su propia DB SQLite en `~/.local/share/opencode/` que guarda sessions, messages y todos.

**Decisión v1.22.0: NO sincronizar.**

Razones:

1. **Cada sistema tiene granularidad distinta.** occ es "observation/outcome/note/decision/feature" — tipos semánticos del proyecto. opencode SQLite es "session/message/todo" — runtime del LLM. Mezclar rompería el modelo mental del usuario ("¿este 'note' es occ u opencode?").

2. **Sources-of-truth distintas.** Una observation de occ sobrevive si el LLM olvida la sesión. Una session de opencode desaparece si el usuario la cierra. Si los sincronizo, al cerrar sesión perdería también la memoria del proyecto.

3. **occ mints observations desde el cliente (terminal), opencode las mints desde el LLM.** Sincronizar significaría que el LLM escribiría notes fuera del contexto donde el usuario las está creando. Confuso.

4. **Es reversible.** Si el usuario quiere un solo sistema, puede configurar `~/.local/share/opencode/` como destino y dejar de usar `--remember` de occ. O puede dejar de usar opencode CLI.

**Tradeoffs aceptados:**

- Dos sistemas que mantener. Si uno se rompe, el otro sigue (resilience, no redundancy).
- Documentación adicional explicando la diferencia. PENDIENTE para v1.23.0.

**Trigger para re-evaluar:** cuando opencode expone una API de memory que se pueda configurar a un directorio file-based compatible con el formato de occ. Ahí sincronizamos o migramos.

**Conocimiento reproducido por:** `@architect`, revisión v1.22.0.


## Anti-decisiones (explícitamente rechazadas)

| Decisión rechazada | Razón |
|--------------------|-------|
| Adoptar gstack completo (23 skills + binarios) | Binarios Bun + Playwright + Chromium rompen zero-deps. |
| Adoptar `claude-api` skill de anthropics | No aplica; opencode no invoca Claude API. |
| Adoptar `mcp-builder` skill | Anti-MCP; opencode no carga MCP servers Anthropic-style. |
| Adoptar `web-artifacts-builder` (React+Vite+Tailwind bundle) | Overhead Node masivo; `design-md` cubre. |
| Adoptar `browse/` completo (gstack) | 60 archivos TS con daemon persistente; sustituido por `web-verify` con tiered runtime detection. |
| Adoptar `qa/` binario completo (gstack) | Binario acoplado al daemon; sustituido por `qa-web` con methodology portable. |
| Auto-instalar Playwright por default | 170 MB; el usuario debe decidir. |
| Auto-instalar graphifyy por default | 50 MB; opt-in via flag. |
| Adopción verbatim de `skill-creator` (1204 líneas originales) | Diseñado para Claude-CLI con subagents paralelos; adaptado a SKIL.md lightweight. |
| Portar `docx/scripts/office/validators/` | Submódulo base classes; sustituido por python-docx + lxml inline. |
| Hacer `occo` en TypeScript con Bun | Zero deps, audit-friendly, compat con hooks git bash. |

## Principios vigentes

1. **Zero deps base** — install.sh funciona sin pip/npm/uv/Bun adicionales. Todo lo pesado es opt-in.
2. **Frontmatter mínimo en skills** — solo `name` + `description` (compatible con `keepFields` de OpenCode).
3. **Surgical changes** — cada commit hace una cosa, máx 3 archivos por iteración salvo justificación.
4. **Validate before commit** — `bash validate.sh` debe pasar antes de commit. Tests + custom linter + version match.
5. **Provenance explícita** — cherry-picks declaran source.upstream en `agents/manifest.json` y `## Provenance` en SKILL.md.
6. **Tiered runtime detection** — las skills que requieren tools externos (Playwright, graphify) detectan disponibilidad y degradan gracefully.
7. **Drift de docs es bug** — validate.sh verifica consistencia; bash --help del install.sh documenta los flags.
