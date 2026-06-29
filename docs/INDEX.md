# opencode-global-config — Documentation Index

Esta carpeta `docs/` contiene la documentación estructurada. Sigue el patrón **Docs-First** definido en `AGENTS.md` raíz. Hay dos niveles:

1. **Documentación canónica en la raíz** — `README.md`, `ARCHITECTURE.md`, `CHANGELOG.md`, `CONTEXTO_PROYECTO.md`, `INSTALL.md`, `AGENTS.md`, `CLAUDE.md`. Son la fuente de verdad.
2. **Documentación estructurada en `docs/`** — refleja, resume, y categoriza la documentación canónica. Útil para onboardings y vistas de conjunto.

## Tabla de contenidos

| Archivo | Propósito | Tamaño |
|---------|-----------|--------|
| [`INDEX.md`](INDEX.md) | Este archivo (índice de la documentación) | 3 KB |
| [`DECISIONS.md`](DECISIONS.md) | Decisiones arquitectónicas (20+ decisiones, 11 anti-criterios explícitos) | 5 KB |
| [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) | Resumen ejecutivo del proyecto, estado actual v1.15.0, estructura | 5 KB |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Arquitectura técnica detallada: occo, agents, skills, profiles, hooks, memory, install | 8 KB |
| [`BUSINESS_LOGIC.md`](BUSINESS_LOGIC.md) | Reglas de negocio (deny-first gradient, iron laws de las cherry-picks) | <1 KB |
| [`DATA_STRUCTURE.md`](DATA_STRUCTURE.md) | Modelos de datos (memory JSONL, profiles, observations frontmatter) | <1 KB |
| [`RISKS.md`](RISKS.md) | Registro de riesgos conocidos | <1 KB |
| [`TASKS.md`](TASKS.md) | Tracking de tareas | <1 KB |
| [`CONVERSATION.md`](CONVERSATION.md) | Resumen de conversación de la sesión | <1 KB |
| [`ONBOARDING.md`](ONBOARDING.md) | Onboarding para nuevos devs | <1 KB |
| [`memory/`](memory/) | Observaciones de memoria por proyecto (sincronizadas desde `~/.config/opencode/memory/`) | variable |

**Nota:** El changelog canónico es `../CHANGELOG.md` (raíz). Existía un `docs/CHANGELOG.md` duplicado en v1.9.6 que fue removido para evitar divergencia.

## Fuente de verdad (raíz del repo)

| Archivo | Para qué |
|---------|----------|
| `../README.md` | English documentation, quick start, features, commands |
| `../README.es.md` | Documentación en español |
| `../INSTALL.md` | Guía de instalación paso a paso |
| `../CHANGELOG.md` | Historial formal de releases (v1.0.0 a v1.15.0) |
| `../CONTEXTO_PROYECTO.md` | Bitácora viva de sesiones, decisiones tácticas, riesgos residuales |
| `../AGENTS.md` | Reglas globales + intent mapping de los 11 agentes |
| `../CLAUDE.md` | System prompt compacto para Claude Code (también funciona en opencode) |
| `../ARCHITECTURE.md` | Architecture overview con diagramas (English) |
| `../VERSION` | Versión actual (`1.15.0`) |

## Diferencia entre docs/ y raíz

| Aspecto | Raíz (`/`) | `docs/` |
|---------|------------|---------|
| Audiencia | Usuarios + contribuidores | Contribuidores nuevos |
| Estilo | Narrativo, ejemplos | Estructurado, tabular |
| Tamaño | Más largo, más completo | Resumen ejecutivo + pointers |
| Mantenimiento | Manual por sesión | Refleja raíz; sin divergencia intencional |
| Frecuencia de cambio | Cada release / sesión | Solo cuando cambia la raíz |

## Flujo de lectura recomendado para nuevos contribuidores

1. Lee `../README.md` (10 min) — qué es y cómo instalarlo
2. Lee `../AGENTS.md` (5 min) — reglas globales y mapeo de agentes
3. Lee [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) (5 min) — estado actual y stack
4. Lee [`ARCHITECTURE.md`](ARCHITECTURE.md) (15 min) — cómo encaja todo
5. Lee [`DECISIONS.md`](DECISIONS.md) (5 min) — qué se decidió y por qué
6. Lee `../CONTEXTO_PROYECTO.md` (15 min, opcional) — historia reciente
7. Ejecuta `bash install.sh --dry-run` — ver el plan
8. Ejecuta `bash validate.sh` — ver el estado local

Total: ~55 minutos para entender el proyecto end-to-end.

## Estado de la documentación

| Estado | Archivos |
|--------|----------|
| ✅ Completo y actualizado a v1.15.0 | `DECISIONS.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, `INDEX.md` |
| 🟡 Esqueleto (10 líneas) | `BUSINESS_LOGIC.md`, `DATA_STRUCTURE.md`, `RISKS.md`, `TASKS.md`, `CONVERSATION.md`, `ONBOARDING.md` |

Los esqueletos se llenan on-demand cuando haya cambios específicos que ameriten documentación. La fuente de verdad sigue siendo la raíz.
