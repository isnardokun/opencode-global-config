# INFORME DE AUDITORÍA — opencode-global-config

**Fecha:** 2026-06-29
**Versión auditada:** v1.19.0
**Auditor:** @architect + deep-read
**Estado:** Producto, no librería. Análisis con foco en usuario final.

---

## Resumen ejecutivo

`opencode-global-config` entrega un **instalador zero-deps + wrapper CLI `occ` + 25 skills + 11 agentes + 9 perfiles + memoria JSONL + plugin de seguridad** alrededor de OpenCode CLI. Es **funcionalmente sólido** pero tiene **deuda técnica acumulada** que afecta la confiabilidad de cara al usuario:

- **5 issues bloqueantes** que rompen parcialmente features descubiertas (descubrimiento de skills, drift de docs, install path frágil).
- **6 issues mayores** que afectan experiencia y orgullo profesional.
- **12 issues menores** que son deuda de mantenimiento.

El proyecto tiene **excelente disciplina de release versioning** (v1.11.0 → v1.19.0, 9 releases en 2 meses) y **test coverage ~14 smoke tests** pero **baja cobertura de install paths críticos** — esto explica los 3 commits en cadena para arreglar el flag `--with-codebase-memory`.

**Recomendación:** Resolver P0 en 1 release (v1.19.1 → v1.20.0). Resolver P1 en 2 releases adicionales (v1.21.0, v1.22.0). P2/P3 según banda de tiempo.

---

## Metodología

Auditoría en 5 pasadas:

1. **Inventario estructural**: archivos, conteos, dependencias.
2. **Read-through crítico**: install.sh, uninstall.sh, validate.sh, occo (completo), CLAUDE.md, AGENTS.md, opencode.json, AGENTS.md/CLAUDE.md locales vs repo, plugins/safety-guard.js, install.ps1, hooks, docs/.
3. **Comparación contra upstream**: docs OpenCode oficial (`opencode.ai/docs/cli`, `opencode.ai/docs/agents`), SKILL.md de cada cherry-pick contra sus originales citados.
4. **Live probe**: `opencode agent list`, `occo --doctor`, `occ --help`, `bash install.sh --dry-run`, `bash validate.sh`, `bash tests/run.sh`, `install.sh --with-codebase-memory` end-to-end (ya hecho hoy en la sesión).
5. **Drift detection**: VERSION ↔ CHANGELOG ↔ README ↔ docs/ ↔ install.sh ↔ validate.sh, frontmatter ↔ discoverability, hook templates en repo vs inline en occo.

---

## Findings rankeados

### P0 — Bloqueantes (rompen funcionalidad para el usuario final)

#### P0-1. `skills/design-md/SKILL.md` no tiene frontmatter válido

**Síntoma:** El archivo arranca con `# Skill: design-md` (heading Markdown) en lugar del frontmatter `---name: ..., description: ...---`. opencode **no descubre skills sin frontmatter**. El archivo es citable desde otros skills pero el `@` autocomplete y el invocador programático no lo ven.

**Impacto:** El skill está documentado en `agents/manifest.json` y reachable desde design-md-aware workflows, pero **no se invoca automáticamente** cuando el usuario describe una tarea de UI/design. **Funcionalidad muerta en el flujo normal.**

**Evidencia:**
- `agents/manifest.json` línea 179-188 lo describe como skill activo con descripción válida.
- `skills/design-md/SKILL.md` línea 1 es `# Skill: design-md`. Sin frontmatter.
- `validate.sh` solo chequea frontmatter en `agents/*.md` y `commands/*.md`, **no en `skills/*/SKILL.md`** → escape del linter.

**Fix:** agregar frontmatter mínimo `---name: design-md, description: ...---` + restaurar la sección "Design Philosophy" como bloque dentro del frontmatter o como sección inmediata. Extender `validate.sh` para también chequear `skills/*/SKILL.md`. Estimado: 30 líneas.

#### P0-2. Drift severo en `docs/` (4 versiones atrás)

**Síntoma:** `docs/PROJECT_CONTEXT.md`, `docs/INDEX.md`, y `docs/ARCHITECTURE.md` declaran v1.15.0 con 22 skills; el repo está en v1.19.0 con 25 skills. **12 referencias obsoletas** a versiones viejas en la sección `docs/`.

**Impacto:** Cualquier persona que lee `docs/` para entender el proyecto actual recibe info incorrecta. Riesgo de confusión + pérdida de credibilidad técnica. Especialmente `PROJECT_CONTEXT.md` línea 53 dice `VERSION "1.15.0"` (en un ejemplo), línea 125 dice "en producción estable (v1.15.0)", y línea 134 dice "11 skills adaptadas" — todo mentira actual.

**Fix:** regenerar `docs/PROJECT_CONTEXT.md` y `docs/INDEX.md` con `validate.sh` como fuente. Lo más simple: agregar check a `validate.sh` que verifique que si VERSION es v1.X.Y, ningún archivo en `docs/` mencione v1.X-1. (Bug-via-blanket-regex; podría dar falsos positivos en changelog. Mejor: ignorar `DECISIONS.md` y `CHANGELOG.md` que tienen refs históricos legítimas.) Estimado: 1 archivo + 1 check en validate.sh.

#### P0-3. `validate.sh` no valida frontmatter de `skills/*/SKILL.md`

**Síntoma:** El linter custom verifica frontmatter solo en `agents/*.md` y `commands/*.md`. P0-1 (design-md sin frontmatter) y otros futuros casos pasarán silenciosamente.

**Impacto:** Drift latente. Cualquier skill futuro agregado sin frontmatter será invisible.

**Fix:** Loop `for md in "${ROOT}/skills/"*/SKILL.md`. Mismo check. Estimado: 5 líneas.

#### P0-4. Install path de `--with-codebase-memory` requiere 3 commits para estar bien

**Síntoma:** v1.18.0 introdujo el flag. Tres bugs sucesivos:
- v1.18.0: si el binario pre-existe, no llama al installer interno.
- v1.18.1 (3ff24cc): añadió remediación, pero con `[ -t 0 ]` gate que no corre en entornos sin TTY.
- v1.19.1 (8aeee73): removió el `[ -t 0 ]` gate.

**Impacto:** Sin tests E2E del install path, cada release con flag de binario externo introduce regresiones que solo se descubren al reinstallar manualmente.

**Fix:** Test E2E con fixture tmpdir + curl mockeado o `CBM_URL` override. Suite mínima: download_ok / binary_already_present / mcp_already_registered / binary_installed_but_mcp_missing. Estimado: 80 líneas de test.

#### P0-5. `install.sh --help` reporta tamaño de graphify desactualizado

**Síntoma:** Línea 27 dice "~50 MB" para graphify. El binario actual graphifyy pesa distinto. La descripción en `install.sh --help` y en `INSTALL.md` debería decir "the actual size depends on the optional extras you install via uv".

**Impacto:** Usuario espera 50 MB, obtiene N MB. Confianza en docs.

**Fix:** Reemplazar con "actual size depends on optional extras" o ejecutar `uv tool install graphifyy --dry-run` y capturar el tamaño. Bajo esfuerzo.

---

### P1 — Mayores (fricción, orgullo, deuda)

#### P1-1. `occ` tiene 30 subcomandos, tests cubren ~14. Cobertura ~0.5% LOC.

**Síntoma:** `occo --help` lista 23 opciones/flags. Solo 14 de ellas tienen test (--memory, --remember, --compact, --init, --ask dry-run, profiles list, session tracking, hooks, doctor, installer dry-run, uninstall, safety-guard). Faltan tests para: `--doctor` (output exacto), `--workflow` (los 5 workflows), `--profile`, `--status`, `--budget`, `--save-all`, `--detect-skills`, `--install-skills-registry`, `--list-workflows`, `--list-templates`, `--capture`, y la lógica de auto-compact / auto-reflect / loop-detection.

**Impacto:** Regresiones en funciones no testeadas pasan al release. La regla "Validate before commit" escrita en AGENTS.md es inalcanzable sin tests.

**Fix:** Smoke tests adicionales para cada subcomando. No unit tests (demasiado esfuerzo para occ bash); smoke tests son realistas. Estimado: +20 tests (~200 líneas).

#### P1-2. `occ --doctor` no diagnostica lo más importante

**Síntoma:** Diagnostica presencia de archivos y directorios, validez de JSON, presencia de fzf, log de auditoría. **No diagnostica:**
- MCP servers registrados en `opencode.json`.
- Que `~/.local/bin/occo` sea ejecutable y apunte a una versión consistente con el repo.
- Que graphify (si instalado) responda a `--version`.
- Que codebase-memory-mcp (si instalado) esté en PATH y registrado.
- Que los hooks en `hooks/` sean ejecutables (`chmod +x`).
- Que el plugin `safety-guard.js` cargue sin error de Node (`node --input-type=module -e "import('./plugins/safety-guard.js').then(...)"`).
- Drift entre VERSION (raíz) y `occo: v1.X.Y` en el binario instalado.

**Impacto:** "Doctor" es la primera línea de defensa para el usuario cuando algo falla. Si no diagnostica los puntos más frecuentes de fallo, el usuario queda perdido.

**Fix:** Agregar ~12 chequeos adicionales. Estimado: 80 líneas.

#### P1-3. Cero tests E2E de los 3 flags opt-in

**Síntoma:** install.sh tiene 3 flags (`--with-playwright`, `--with-graphify`, `--with-codebase-memory`). Solo 1 test (de `--dry-run`). No hay test que verifique:
- Que `--with-codebase-memory` registra el MCP server en `opencode.json` correctamente (ni siquiera con CBM mockeado).
- Que `--with-graphify` no rompe cuando `uv` no está pero `pipx` sí.
- Que `--with-playwright` cae al modo degradado (warn + skip) cuando no hay npm.

**Impacto:** Cada flag puede tener regressions no detectadas. P0-4 ya demostró esto para `--with-codebase-memory`.

**Fix:** Test harness con stubs. Estimado: 200 líneas de test infra.

#### P1-4. `occ` no aprovecha subcomandos nativos de `opencode 1.x`

**Síntoma:** `occ` invoca `opencode run <prompt>`. OpenCode tiene más subcomandos útiles (>= 17):
- `opencode mcp add` — sería el método nativo para registrar MCP servers (mejor que bajarse el binario y rezar).
- `opencode session` — para tracking de sesiones (occ tiene `.session` file propio, paralelo).
- `opencode stats` — para token-usage dashboards.
- `opencode agent create` — para crear agentes via CLI.
- `opencode attach` — TUI sobre un server headless.
- `opencode db` — acceso a la SQLite nativa de opencode.
- `opencode github install` — para integrar el GitHub agent.

**Impacto:** Reinventamos la rueda con el JSONL memory, scripts de worktree, prompt-injection para tracking. Cuanto más dependamos de `occ` reinventando, más divorciados estamos del upstream. Si OpenCode evoluciona su CLI, no aprovechamos.

**Fix:** Adoptar gradualmente. P1-P2 prioridad:
1. `opencode mcp add` en lugar de descargar binario externo para `--with-codebase-memory` (reduce 80% del código install).
2. `opencode stats` opcional como `occ --stats`.
3. `opencode db` para introspección.

#### P1-5. Dos sistemas de memoria paralelos (occ JSONL + opencode sessions)

**Síntoma:** `occ` mantiene `~/.config/opencode/memory/index.jsonl` con `obs_<id>`, `outcome_*.json`, `notes/`. OpenCode tiene su propia DB SQLite para sessions, messages, todos. Ninguno se sincroniza. Si el usuario limpia `memory/` (occ), sus sesiones opencode quedan. Si limpia `~/.local/share/opencode/`, occ cree que no hay sesiones pero sí las hubo.

**Impacto:** Confusión sobre qué guardar/dónde. La regla "memory file-based JSONL" en DECISIONS.md es válida, pero duplicarla con SQLite nativa de opencode es overhead.

**Fix:** Decisión consciente: ¿occ usa opencode como "Source of truth" para sesiones (via `opencode export`) y mantiene JSONL solo para memory de proyecto? O ¿integramos más profundo? Por ahora **auditar la decisión** (entrada en DECISIONS.md o ADR). Estimado: 1 documento de 50 líneas.

#### P1-6. Prompts de workflow embebidos en `occ` son estáticos

**Síntoma:** Los 5 workflows en `run_workflow()` (occ líneas 2340-2620) tienen prompts inline de 50-100 líneas cada uno. No versionado, no reusado, no testeable. Si cambia el prompt en uno, tienes que editar occ.sh directamente. El split entre `skills/plan-eng-review/SKILL.md` (orientación, 133 líneas) y el prompt embebido en occ (otro prompt completo similar) es doble-manutención.

**Impacto:** Cambiar un workflow = release de occ. Cambiar algo en un skill SKILL.md no actualiza el flujo que occ dispara. Drift conceptual permanente.

**Fix (gradual):** Extraer prompts de workflow a archivos separados (`workflows/bug-hunt.md`, etc.), y que `occ` los lea y los inyecte. Esto desacopla occ del contenido. Estimado: +5 archivos workflow, occ pierde ~300 líneas.

---

### P2 — Medianos (deuda técnica)

#### P2-1. 20+ URLs hardcoded `isnardokun/opencode-global-config`

**Síntoma:** Documentadas arriba. README, INSTALL, install.sh, etc., todos asumen ese URL.

**Impacto:** Forkear el proyecto requiere editar 20+ lugares. No hay `BASE_REPO_URL` constante.

**Fix:** Constante `BASE_REPO_URL="${OPENCODE_GLOBAL_CONFIG_REPO:-https://github.com/isnardokun/opencode-global-config}"` en install.sh y un script para validar que `git remote get-url origin` matchea. Estimado: 50 líneas.

#### P2-2. Advertencias ruidosas de session turns

**Síntoma:** Cada `occ` invocation arranca loggeando `[WARN] Session turns: 36 (consider context compaction)`. Lo vi en mi propia sesión. Es muy ruidoso. La advertencia se dispara >20, pero una sesión normal de coding puede pasar 30-40 turns sin compactar.

**Impacto:** Noise leads to ignore. Si el usuario lo ve siempre, deja de prestarle atención; cuando REALMENTE importa (>50), ya está acostumbrado a ignorarlo.

**Fix:** Subir threshold a 30 y bajar nivel a `info` (< 40) y `warn` (> 40). Documentar en AGENTS.md. Estimado: 3 líneas.

#### P2-3. Sin ejemplo end-to-end reproducible en README

**Síntoma:** README lista features pero no muestra "podés hacer X con comando Y". Los workflows existen en occ (`bug-hunt`, `feature`) pero README no los usa en ejemplos.

**Impacto:** Feature discovery es pobre. El usuario tiene que probar `occ --help` y adivinar.

**Fix:** Una sección "Quick tour" en README con 4-5 comandos reales y outputs esperados. Estimado: 30 líneas para README + un script de fixtures que se ejecute en CI para mantener esos outputs sincronizados.

#### P2-4. `occ --workflow` API confusa

**Síntoma:** `occ --workflow <name> [target|feature_desc] [path] [--interactive]`. Tres argumentos posicionales con semantics distintas según el workflow. Algunos esperan `target` (ruta), otros `feature_desc` (texto). El usuario no sabe cuál.

**Impacto:** DX confuso. Lleva a errores.

**Fix:** Sub-comandos: `occ workflow bug-hunt <path>`, `occ workflow feature "<description>" <path>`. Estimado: 30 líneas + backward compat.

#### P2-5. `safety-guard.js` solo bloquea, no avisa

**Síntoma:** Plugin regex bloquea un set de patrones peligrosos. Pero patrones "amarillo" (e.g., `chmod 777 <file>` no-root, `git push --force` no-master, `rm -f *.conf`) los permite silenciosamente.

**Impacto:** El log de auditoría captura todo, pero el usuario no es notificado proactivamente. Patrones medios pasan sin fricción.

**Fix (opt-in):** Configurar `--safety-warn-only` con lista de patrones amarillos en lugar de rojo. Sin config por default — al menos documentar la posibilidad. Estimado: 50 líneas + docs.

#### P2-6. `--init` pisa hooks sin confirmar

**Síntoma:** `occ --init /path` escribe `.git/hooks/pre-commit` y `.git/hooks/pre-push` sin avisar si ya existe uno. Footgun para usuarios que tengan hook custom.

**Impacto:** Pierden su hook custom con un `occ --init` desprevenido.

**Fix:** Backup `pre-commit.bak.<timestamp>` antes de sobreescribir, o detectar y abortar con mensaje pidiendo `--force`. Estimado: 10 líneas.

#### P2-7. CHANGELOG manual por release

**Síntoma:** Cada release (v1.11–v1.19, 9 releases) requiere escribir ~30 líneas de CHANGELOG.md a mano. Carga cognitiva y probable drift (la prosa no es uniforme).

**Impacto:** Trabajo manual + вероятный drift + ruido para contribuidores futuros.

**Fix:** Convención de changelog auto: `git log vX.Y.Z..vX.Y+1.Z --oneline` + template. Script `scripts/bump-version.sh` que actualice VERSION y CHANGELOG en una pasada. Estimado: 1 script de 60 líneas + changelog discipline.

---

### P3 — Menores

P3-1. `oc` como alias en docs y scripts es a la vez feature y confusión. Decisión: mantener `occ` canónico, alias `oc` mencionado solo en install.sh pero nunca usado en producción.

P3-2. `octogent-inspired` comments en occ (línea 73) sin attribution real. Quitar o reemplazar con descripción concreta.

P3-3. LICENSE no se ve desde CLI cuando se instala con curl-pipe-bash. Usuario no sabe qué licencia acepta.

P3-4. Sin TypeScript / Bun / Docker dist. Zero-deps tiene el costo de no tener binario distribuible. Decisión consciente; pero no hay release artifact (`.tar.gz`, `npm`, `brew`). Listado en distros populares es un Q-elevator.

P3-5. README.es.md tiene 1 ref a v1.X.Y vs README.md que tiene 5+. Si bumpeás versión, hay que recordar. Idem CONTEXTO_PROYECTO.md.

P3-6. `occ --init` no valida que `git config user.email` esté seteado, lo que lleva a hooks que rompen silenciosamente.

P3-7. `install.sh` no verifica `HOME` no-vacío (asume `$HOME` definido; en containers raros podría no estar).

---

## Plan de mejora propuesto (3 releases, rango estimado)

### Release 1: v1.20.0 — "Descubrimiento + Confiabilidad" (P0 + P1-P2-P3 obvios)

**Scope:**
- Agregar frontmatter a `skills/design-md/SKILL.md` (P0-1).
- Extender `validate.sh` para chequear frontmatter en `skills/*/SKILL.md` (P0-3).
- Regenerar `docs/PROJECT_CONTEXT.md`, `docs/INDEX.md`, `docs/ARCHITECTURE.md` con contenido v1.20.0 (P0-2).
- Agregar tests E2E de install.sh con `--with-codebase-memory` (P0-4).
- Agregar 5 chequeos clave a `occo --doctor` (P1-2 partial).
- Subir threshold de "Session turns" warning a 30+ (P2-2).
- Backup de hooks antes de overwrite en `occ --init` (P2-6).

**Estimación:** 1 día de trabajo. 3-4 commits.

**Justificación de scope:** Este release ataca solo bloqueantes + fricción de detección. **P0-4 (install path E2E) se ataca porque cada release nuevo con flag externo ha demostrado riesgo de regresión.** P1-2 (doctor) se hace partial (chequeos clave) porque cubre los puntos que el usuario ve primero cuando algo falla.

**Lo que NO se hace acá:**
- Drastic refactor de occ a sub-comandos (P1-6) — rompe backward compat.
- Cambio de install de binario externo → `opencode mcp add` (P1-4) — requiere estudiar comportamiento exacto de opencode 1.x.

### Release 2: v1.21.0 — "Cobertura de tests"

**Scope:**
- 20 smoke tests adicionales en `tests/run.sh` cubriendo todos los subcomandos de occ + cada install flag.
- Test harness para install flags con stubs (binarios mock).
- Test del `--workflow` dispatch end-to-end con fixtures.
- Quitar "Octogent-inspired" comments sin attribution (P3-2).

**Estimación:** 2-3 días de trabajo. 5-8 commits.

**Justificación:** P1-1 + P1-3 son los más caros pero dan retorno máximo: más confianza por release, menos bugs que sobreviven al CI, contributor onboarding más rápido.

### Release 3: v1.22.0 — "OpenCode 1.x alignment"

**Scope:**
- Migrar `--with-codebase-memory` install de "curl + extract + ejecutar install.sh interno" a `opencode mcp add codebase-memory-mcp --command /home/ram/.local/bin/codebase-memory-mcp`.
- Extraer prompts de workflow a archivos separados en `workflows/*.md` (P1-6).
- Agregar ADR en docs/DECISIONS.md sobre "memory: occ JSONL vs opencode SQLite" (P1-5).
- Mover `BASE_REPO_URL` a constante en install.sh (P2-1).
- Documentar flag `--safety-warn-only` en plugin safety-guard.js (P2-5).

**Estimación:** 3-5 días. Es el release "más disruptivo" — toca superficie amplia.

**Justificación:** El proyecto tiene deuda con upstream OpenCode que crece cada día que pasa. Alinear install paths con `opencode mcp add` elimina 80+ líneas de código propio y reduce el riesgo de drift con binarios externos.

---

## Justificación para no incluir P1-5/P1-6 en release 1

**P1-5** (decisión sobre memoria occ vs opencode) es una conversación de producto más que técnica. Apropiada para una discusión abierta, no para commit silencioso. Lo dejaremos para un ADR post-release-1.

**P1-6** (extraer prompts de workflow) es refactor que rompe "surgical changes" (Karpathy #3). El beneficio es real pero el riesgo es alto. Lo agendamos en release 3 con tests de regresión para los 5 workflows.

---

## Cierre

`opencode-global-config` no está roto, pero tiene **deuda que crece más rápido que los features que se agregan**. El ciclo v1.18.0 → v1.19.1 demostró esto. El release v1.20.0 debería ser la última "release de housekeeping" antes de una v2.0 con refactor más grande (occ en TypeScript con Bun, OpenCode 1.x APIs alineadas), pero esa es una conversación separada que requiere decisión de producto.

Mientras tanto: **P0 cierra la grieta de descubribilidad + drift de docs + install path**. Eso solo ya sube la confianza del usuario final.

---

**Próximo paso:** revisar con vos y decidir scope antes de empezar a tocar código. Tengo las opciones de release 1, 2, 3 y "solo P0, dejar P1+ para más tarde" mapeadas. Decime cuál priorizar.
