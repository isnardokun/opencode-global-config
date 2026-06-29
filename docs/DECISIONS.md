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
