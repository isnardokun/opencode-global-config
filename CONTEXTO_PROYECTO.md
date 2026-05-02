# opencode-global-config — Contexto del Proyecto

**Repo GitHub:** https://github.com/isnardokun/opencode-global-config  
**Versión actual:** 1.9.3  
**Última sesión:** 2026-05-02  
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
├── oc                     # Script wrapper (~1100 líneas) — comando global `oc`
├── install.sh             # Instalación + --dry-run
├── uninstall.sh           # Remoción segura con backup
├── validate.sh            # Validación completa + --installed
├── Makefile               # validate, check, install, dry-run, uninstall, doctor
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
│   ├── docs-writer.md
│   ├── devops.md
│   ├── oncall.md
│   ├── migration-planner.md  # Migraciones reversibles, solo lectura
│   └── performance-profiler.md  # N+1, O(n²), I/O bloqueante, solo lectura
│
├── commands/ (8 slash commands nativos en OpenCode TUI)
│   ├── analyze.md, review.md, secure.md, feature.md
│   ├── bug-hunt.md, docs.md, devops.md, oncall.md
│
├── skills/ (6 skills)
│   ├── project-map/
│   ├── safe-implementation/
│   ├── test-first/
│   ├── precommit-review/
│   ├── memory-retrieval/
│   └── docs-writer/
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
│   └── safety-guard.js    # Bloquea comandos destructivos + audit log JSONL
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
1. `switch_profile()` en `oc` exporta `OC_PROFILE`
2. `get_profile_rules()` lee el JSON del perfil activo y genera instrucciones en inglés
3. `_oc_run()` inyecta esas reglas en cada llamada no interactiva a `opencode run "..."`

Esto significa que los perfiles aplican restricciones vía LLM instructions, no vía permisos de sistema.

### Separación nativa vs prompt
- `opencode.permission` en los JSONs de perfil → matriz declarativa validada por el repo; actualmente no se aplica como perfil nativo por OpenCode
- `policy` en los JSONs de perfil → reglas inyectadas al LLM via prompt

### Slash commands
Los archivos `commands/*.md` se cargan automáticamente en el TUI de OpenCode.
No requieren el wrapper `oc`. Se usan directamente como `/analyze`, `/review`, etc.

### Memory system
- `~/.config/opencode/memory/` — observaciones en markdown con frontmatter
- `memory/index.jsonl` — índice para búsqueda rápida con `jq`/`fzf`/`ripgrep`
- Funciones en `oc`: `search_memory()`, `create_observation()`, `get_observations()`, `get_timeline()`

### Safety guard
`plugins/safety-guard.js` bloquea via regex: `rm -rf /`, `> /dev/sda`, `chmod -R 777` en paths de sistema, etc.
Además audita comandos bash permitidos/bloqueados en `~/.config/opencode/logs/safety-guard.jsonl`, con redacción parcial de secretos conocidos.

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
| **1.9.3** | Fix compat OpenCode 1.14: `opencode run` en lugar de `opencode -p`; validator de permisos en validate.sh; `--dry-run` corregido; `auto.json` permisos inválidos fijados |
| **1.9.2** | `validate.sh`: line count sanity check + frontmatter validation; `Makefile`: target `format` + `jq` strict |
| **1.9.1** | `.editorconfig`, `Makefile`, `opencode.strict.json`, `agent/builder-safe.md` |
| **1.9.0** | Matriz declarativa de permisos OpenCode, 3 agentes nuevos, 8 slash commands, `validate.sh`, `uninstall.sh`, `--dry-run`, audit log, `--doctor`, CI GitHub Actions, bilingüe README |
| **1.8.0** | Cross-platform install.sh, rutas absolutas en JSON, fix macOS, memory JSONL index, cleanup CLAUDE.md |
| **1.7.0** | Profile enforcement por prompt injection, single-pass workflows, fix args bug en `_oc_run()`, safety-guard mejorado |
| **1.6.0** | Docs, changelog honesto |
| **1.5.0** | Sistema de workflows (bug-hunt, new-project, debug, document, feature) |
| **1.4.0** | Memory retrieval 3-layer system, observation format, JSONL index |
| **1.3.0** | 7 perfiles deny-first gradient, context budget tracking, `--compact` |
| **1.2.0** | 4 principios de Karpathy integrados |
| **1.1.0** | Menú interactivo fzf, memory bank, souls, git hooks, `oc init` |
| **1.0.0** | 8 agentes, 4 skills, safety-guard plugin, comando `oc` |

---

## Bugs/decisiones importantes

### Revisión integral y bug-hunt — sesión 2026-05-02

El usuario definió explícitamente que `CONTEXTO_PROYECTO.md` debe usarse como registro de cambios, modificaciones y mejoras del proyecto. Se ejecutaron dos pasadas de bug-hunt con agentes especializados:

1. `@architect` + `project-map` — mapeo de arquitectura, entrypoints, zonas de riesgo y bugs probables.
2. `@security-auditor` — revisión de seguridad: permisos, hooks, audit log, safety guard, filesystem.
3. `@planner` — priorización de fixes por severidad y criterios de éxito.
4. `@builder-safe` — implementación quirúrgica por iteraciones.
5. `@reviewer` + `precommit-review` — revisión final del diff y validaciones.

Archivos modificados por las correcciones recientes:
- `oc`
- `validate.sh`
- `Makefile`
- `.github/workflows/validate.yml`
- `hooks/pre-commit`
- `hooks/pre-push`
- `plugins/safety-guard.js`
- `tests/run.sh`
- `install.sh`
- `README.md`, `README.es.md`, `INSTALL.md`
- `CONTEXTO_PROYECTO.md`

Estado Git observado tras las correcciones:
- Archivos modificados tracked: `oc`, `validate.sh`, `Makefile`, `.github/workflows/validate.yml`, `hooks/pre-commit`, `hooks/pre-push`, `plugins/safety-guard.js`, `install.sh`, `README.md`, `README.es.md`, `INSTALL.md`.
- `CONTEXTO_PROYECTO.md` aparece como untracked y debe versionarse si será la fuente oficial de continuidad.
- `tests/run.sh` fue creado como nueva suite funcional mínima y también debe versionarse.

#### Correcciones funcionales aplicadas

- `oc`: corregida precedencia Bash en detección Python para `pyproject.toml`, `requirements.txt` y comandos de test.
- `oc`: `oc --init` ya no crea `.git/hooks` si el target no es repo Git.
- `oc`: `oc --init` genera ruta de agentes project-local en lugar de `~/.opencode/agents`.
- `oc`: el hook generado por `oc --init` usa `oc` si existe y fallback a `opencode run`.
- `oc`: el hook generado por `oc --init` ahora es fail-closed y exige `BLOCKING_FINDINGS=false`.
- `oc`: `oc plan` preserva argumentos multi-palabra.
- `oc`: `review`, `secure`, `docs` y `oncall` pasan argumentos opcionales a sus funciones rápidas.
- `oc`: `--list-profiles` muestra nombres usables sin `.json`.
- `oc`: `switch_profile()` rechaza perfiles vacíos o inexistentes.
- `oc`: `--get` y `--timeline` aceptan IDs con o sin prefijo `obs_`.
- `oc`: JSONL de memoria se genera con `python3` y `json.dumps`, evitando corrupción por comillas, backslashes o saltos de línea.
- `oc`: `search_memory()` aplica filtros `project` y `type`.
- `oc`: búsqueda de memoria usa coincidencia literal con `grep -F`, no regex.
- `oc`: `oc --memory "query" -t type` interpreta `-t` como filtro de tipo.
- `oc`: `oc --remember -p project -t type <texto>` crea observaciones asociadas a proyecto y tipo.
- `oc`: `oc --memory <query> -p project -t type` filtra por proyecto y tipo mediante flags explícitas.
- `oc`: `create_observation()` valida `python3` antes de escribir archivos para evitar estado parcial.
- `oc`: frontmatter de memoria quotea `project`, `type` y `summary` usando JSON-compatible YAML scalars.
- `oc`: workflows `bug-hunt`, `new-project`, `debug`, `document`, `feature` y `--compact` no reportan éxito ni escriben memoria/reset si `_oc_run` falla.
- `oc`: ayuda actualizada para 9 perfiles y sintaxis `--remember [-p proyecto] [-t tipo]`.
- `oc --init`: ahora genera `pre-commit` y `pre-push` fail-closed.
- `hooks/pre-commit`: añade `git diff --cached` explícito al prompt.
- `hooks/pre-push`: añade diff contra upstream o fallback de últimos cambios al prompt.
- `install.sh`: banner alineado a v1.9.3.
- `README.md`, `README.es.md`, `INSTALL.md`: versión/conteos de perfiles alineados a v1.9.3 / 9 perfiles.
- `validate.sh`: incluye `uninstall.sh` en la validación de sintaxis Bash.
- `validate.sh`: valida sintaxis JS de `plugins/safety-guard.js` con `node --check` si `node` existe.
- `Makefile`: añade target `test` para ejecutar `tests/run.sh`.
- `.github/workflows/validate.yml`: ejecuta `tests/run.sh` como smoke tests funcionales en CI.

#### Correcciones de seguridad aplicadas

- `hooks/pre-commit` y `hooks/pre-push`: usan `oc` si está disponible y fallback a `opencode run`.
- `hooks/pre-commit` y `hooks/pre-push`: capturan output y fallan si el comando retorna non-zero.
- `hooks/pre-commit` y `hooks/pre-push`: fallan con línea exacta `BLOCKING_FINDINGS=true`.
- `hooks/pre-commit` y `hooks/pre-push`: fallan si falta línea exacta `BLOCKING_FINDINGS=false`.
- `hooks/pre-commit` y `hooks/pre-push`: aceptan fallback `RECOMMENDATION=CORRECT` como señal de bloqueo.
- `plugins/safety-guard.js`: migrado a formato ESM consistente.
- `plugins/safety-guard.js`: acceso defensivo a `output?.args?.command` para evitar `TypeError`.
- `plugins/safety-guard.js`: redacción básica de secretos antes de audit log.
- `plugins/safety-guard.js`: redacción ampliada para valores con/sin comillas y nombres comunes: `GITHUB_TOKEN`, `OPENAI_API_KEY`, `NPM_TOKEN`, `GH_TOKEN`, `ANTHROPIC_API_KEY`.
- `plugins/safety-guard.js`: redacción ampliada para headers `x-api-key`, flags `--token/--password/--api-key`, URLs con credenciales y `AWS_ACCESS_KEY_ID`.
- `plugins/safety-guard.js`: directorio de logs forzado a `0700` y `safety-guard.jsonl` a `0600`.
- `plugins/safety-guard.js`: bloqueo corregido para variantes críticas como `rm -rf /`, `rm -rf ~`, `rm -rf /*`, `rm -r -f /`, `rm --recursive --force /`.

#### Validaciones ejecutadas durante la sesión

Reportadas como OK por los agentes builder/reviewer:
- `bash -n oc`
- `bash -n oc validate.sh uninstall.sh`
- `bash -n oc hooks/pre-commit validate.sh`
- `bash -n hooks/pre-commit hooks/pre-push`
- `node --check plugins/safety-guard.js`
- `bash tests/run.sh`
- `make check`
- `./validate.sh`
- import ESM dirigido de `plugins/safety-guard.js`
- muestras dirigidas de redacción de secretos
- checks dirigidos para bloqueo de comandos destructivos en `safety-guard.js`
- simulación de lógica de hooks con `BLOCKING_FINDINGS=true`, `BLOCKING_FINDINGS=false`, marcador ausente y `RECOMMENDATION=CORRECT`
- mocks de fallo de workflows y `--compact`
- mock de parser `oc --memory "query" -t type`
- mock sin `python3` para evitar archivos parciales
- `oc --init` en repo temporal para verificar hook generado fail-closed

#### Revisiones finales

- Primer reviewer detectó bloqueantes en regex de `rm` y heurística de hooks; ambos fueron corregidos.
- Segundo reviewer detectó fail-open si faltaba `BLOCKING_FINDINGS=false`; fue corregido.
- Tercera revisión de regresiones aprobó los fixes, sin bloqueantes restantes.

### Riesgos residuales activos tras 2026-05-02

| Riesgo | Severidad | Estado | Próximo paso recomendado |
|--------|-----------|--------|--------------------------|
| `safety-guard.js` es regex-based, no sandbox | Media | Aceptado/documentar | Mantener como guardrail; añadir tests de falsos positivos/negativos si crece |
| Audit log puede no redactar todos los formatos de secreto | Media | Mitigado parcialmente | Mantener pruebas y ampliar si aparecen nuevos formatos |
| Logs/config dependen de `umask` | Baja/Media | Mitigado para audit log | Evaluar permisos explícitos en instalación/config global |
| Hooks dependen de marcador LLM | Media | Fail-closed implementado | Considerar scanners determinísticos (`gitleaks`, `detect-secrets`) |
| `oc --init` instala hooks Git | Baja | Mitigado | Ya genera `pre-commit` y `pre-push`; seguir validando en tests |
| Perfiles son prompt-enforced, no sandbox | Baja/Media | Documentado | No vender como seguridad fuerte; explorar config efectiva por perfil si OpenCode lo soporta |
| Test suite funcional inicial aún es smoke-level | Media | Mitigado parcialmente | Ampliar cobertura con más fixtures CLI/workflows |

### Pendientes nuevos detectados en revisión integral 2026-05-02

1. **`oc --remember -p` documentado y ahora soportado**
   - Se implementó `oc --remember -p <project> [-t type] <texto>`.
   - Cubierto por `tests/run.sh` con `HOME` temporal.

2. **`oc --memory -p proyecto "query"` ahora soportado**
   - Se normalizó parser con `-p|--project` y `-t|--type` cuando hay flags explícitas.
   - Se preservan formas posicionales legacy sin flags.

3. **Desalineación de versión corregida en puntos visibles**
   - `install.sh`, `README.md`, `README.es.md` e `INSTALL.md` fueron alineados a v1.9.3 donde correspondía.
   - Pendiente menor: definir fuente única automatizable de versión.

4. **Conteos documentales corregidos en puntos visibles**
   - `oc --help`, `INSTALL.md` y `README.es.md` actualizados a 9 perfiles.
   - Pendiente: añadir validación documental automática de conteos.

5. **Hooks ahora pasan diff explícito**
   - `pre-commit`: `git diff --cached`.
   - `pre-push`: diff contra upstream o fallback de últimos cambios.

6. **Validación documental insuficiente**
   - `validate.sh` aún no valida automáticamente que ejemplos públicos sigan soportados por el parser.
   - Recomendación: añadir checks ligeros para comandos/documentación críticos.

7. **Memory frontmatter puede romper YAML con contenido complejo**
   - `summary` usa substring directo del contenido.
   - Recomendación: quotear/escapar frontmatter o mover contenido sensible fuera del YAML.

8. **Test suite funcional inicial creada**
   - `tests/run.sh` cubre parser de memoria, `--remember`, hooks fail-closed y safety guard.
   - Pendiente: ampliar a workflows completos y `oc --init` con fixtures.

### Correcciones aplicadas en sesión 2026-05-01
Se hizo análisis profundo del estado del proyecto y se aplicaron correcciones funcionales y documentales:
- `oc`: migrado de `opencode -p` a `opencode run` para compatibilidad con OpenCode 1.14.31.
- `oc`: eliminado el intento de usar `opencode --profile`; los perfiles quedan explícitamente como enforcement por prompt injection.
- `hooks/pre-commit`, `hooks/pre-push` y hook generado por `oc --init`: migrados a `opencode run`.
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
- `CONTEXTO_PROYECTO.md` sigue como archivo untracked en git; fue actualizado porque es el documento de continuidad del proyecto.
- `./validate.sh --installed` falló antes de estas correcciones porque la configuración no está instalada en `~/.config/opencode` y `oc` no está en PATH en esta máquina.

### `args` bug en `_oc_run()` (resuelto v1.7)
`args=("$@")` después del while loop dejaba args vacío porque `$@` ya fue consumido.
Fix: el while loop ya llena `args`, se eliminó la línea problemática.

### Artefactos de idioma (resueltos)
LLM generó strings en chino/ruso en agentes/souls/skills. Todos corregidos con `perl -i -pe`.
El último fue `发现问题` en `skills/memory-retrieval/SKILL.md` — corregido en la última sesión.

### Dead code eliminado (última sesión)
`memory_search()` y `memory_save()` eran duplicados obsoletos de `search_memory()` y `create_observation()`. Eliminados.

### Hooks y perfil activo (actualizado 2026-05-02)
Los hooks versionados usan `oc` si está disponible y fallback a `opencode run` si no lo está. Esto mejora propagación de reglas cuando `oc` existe, pero el fallback no aplica perfil activo ni `_oc_run()`.

**Decisión actual:** mantener fallback por compatibilidad, pero documentar que el perfil activo sólo aplica cuando el hook puede invocar `oc`.

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

## Pendientes conocidos (baja prioridad)

1. **Hooks + profile propagation completa** — fallback `opencode run` no aplica perfil activo; refactor sourceable o instalación garantizada de `oc`.
2. **Ampliar test suite funcional** — cubrir workflows completos, `oc --init` y más combinaciones del parser CLI.
3. **Validación documental automática** — detectar ejemplos obsoletos, conteos de perfiles/agentes/skills y versión declarada.
4. **Fuente única de versión** — evitar drift entre `install.sh`, READMEs, changelog y help.
5. **Hardening adicional de audit log** — ampliar redacción si aparecen nuevos formatos de secretos.
6. **`opencode.strict.json` `~` paths** — OpenCode probablemente los expande, pero no verificado en runtime real.
7. **Documentar límites de seguridad** — perfiles prompt-enforced, hooks LLM-assisted y safety guard regex-based.
