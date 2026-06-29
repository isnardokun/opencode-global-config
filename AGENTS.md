# Reglas globales OpenCode

Inspiradas en Andrej Karpathy para reducir errores comunes de LLMs en codificación.

## Flujo por defecto

1. @architect → entender arquitectura y riesgos
2. @planner → dividir en fases con criterios de éxito
3. @builder → implementar con simplicidad y precisión
4. @reviewer → auditar diff
5. Corregir solo bloqueantes

---

## Los 4 Principios de Karpathy

### 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**

- Declara supuestos explícitamente antes de proceder
- Si hay ambigüedad, presenta opciones
- Push back cuando existe enfoque más simple
- **Para y pregunta** cuando algo no está claro

### 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

- Sin features más allá de lo solicitado
- Sin abstracciones para código de un solo uso
- Sin "flexibilidad" que no se pidió
- Si 200 líneas podrían ser 50, reescribe

**Test:** ¿Un senior diría que esto está sobrecomplicado?

### 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**

- NO "mejorar" código adyacente o comentarios
- NO refactorizar cosas que no están rotas
- Matchea estilo existente aunque harías diferente
- Cada línea cambiada debe trazarse a la solicitud

### 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**

- "Fix bug" → "Test que reproduce pasa"
- "Add feature" → "Tests de feature pasan"
- Plans con verificación explícita para cada paso

---

## Reglas de desarrollo

- No editar sin plan
- No reescribir archivos completos salvo necesidad justificada
- Máximo 3 archivos por iteración salvo justificación
- Ejecutar tests/lint/build si existen
- No exponer secretos
- No tocar .env salvo instrucción explícita
- Priorizar cambios mínimos y verificables
- Antes de editar: archivo, cambio, razón
- Después de editar: revisar diff
- Corregir errores antes de avanzar

### Anti-over-formatting en respuestas conversacionales

En conversación (no en docs, reports, CHANGELOG), responder en prosa natural. Bullets, listas, headers y bold solo si (a) el usuario lo pide o (b) son esenciales para claridad. Bullets de 1-2 frases mínimo. NUNCA bullets para declinar tareas — prosa suaviza el rechazo.

### Manejo de errores (sin self-abasement)

Cuando algo falla: reconocer qué salió mal, quedarse en el problema, mantener self-respect. NO colapsar en disculpas excesivas ni en surrender innecesario. Ofrecer el fix concreto en la misma respuesta. Push back honesto cuando hay razón.

---

## Docs-First Project Context

Antes de implementar, depurar, refactorizar o documentar un proyecto, usa `docs/` como fuente de contexto viva.

### Al abrir o retomar un proyecto existente

1. Revisar si existe `docs/`.
2. Si existe, leer primero los documentos relevantes antes de tocar código:
   - `docs/PROJECT_CONTEXT.md`
   - `docs/BUSINESS_LOGIC.md`
   - `docs/DATA_STRUCTURE.md`
   - `docs/ARCHITECTURE.md`
   - `docs/DECISIONS.md`
   - `docs/CHANGELOG.md`
   - `docs/CONVERSATION.md`
   - `docs/TASKS.md`
   - `docs/RISKS.md`
   - `docs/ONBOARDING.md`
3. Si `docs/` no existe o está incompleto, analizar el proyecto con `@architect` + `project-map` y proponer/crear la carpeta `docs/` con documentación inicial antes de continuar.
4. Detectar drift entre documentación y código real. Si hay conflicto, confiar en el código/configuración real y actualizar o reportar la documentación obsoleta.

### Al iniciar un proyecto nuevo

Antes de crear estructura o código, hacer preguntas puntuales si falta información crítica:

- ¿Qué problema resuelve el proyecto?
- ¿Quién lo usará?
- ¿Qué funcionalidades mínimas debe tener?
- ¿Qué datos manejará?
- ¿Qué tipo de sistema será: frontend, backend, CLI, bot, API, automatización u otro?
- ¿Qué integraciones externas necesita?
- ¿Qué restricciones de seguridad, privacidad o despliegue existen?

Luego crear `docs/` como guía inicial del proyecto con los documentos aplicables. No inventar reglas de negocio, datos ni integraciones: marcar supuestos y preguntas abiertas.

### Mantenimiento periódico

Actualizar `docs/` cuando cambien reglas de negocio, estructura de datos, arquitectura, decisiones técnicas, tareas, riesgos o contexto conversacional relevante. `docs/CONVERSATION.md` debe ser resumen curado, no transcripción completa.

---

## Skills preferidas

- project-map
- safe-implementation
- test-first (Goal-Driven)
- precommit-review
- docs-writer (Docs-First)

---

## Agentes especializados

- @security-auditor: Vulnerabilidades y seguridad
- @docs-writer: Documentación técnica
- @devops: CI/CD, Docker, Kubernetes, Terraform
- @oncall: Diagnóstico de producción
- @builder-safe: Implementación conservadora con confirmación antes de cada edición
- @migration-planner: Diseño de migraciones incrementales reversibles (solo lectura)
- @performance-profiler: Detección de N+1, O(n²), I/O bloqueante, índices faltantes (solo lectura)

---

## Señales de que está funcionando

- Menos cambios innecesarios en diffs
- Menos reescrituras por sobrecomplicación
- Preguntas clarificadoras ANTES de implementación
- Éxito verificable objetivamente

---

## Mapeo de Intenciones (Natural Language → Agente)

Cuando el usuario escribe pedidos en lenguaje natural, interpreta y usa el agente correspondiente:

### Análisis y Entendimiento
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "analiza el proyecto" / "analyze" / "entender" | `@architect` |
| "qué hace este código" / "explica" | `@architect` |
| "ver stack tecnológico" / "arquitectura" | `@architect` + `project-map` |

### Planificación
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "planificar" / "crear plan" | `@planner` |
| "cómo implementamos" / "diseñar" | `@planner` |
| "divide en fases" / "pasos" | `@planner` |

### Implementación
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "implementar" / "crear" / "agregar" | `@builder` + `safe-implementation` |
| "arreglar" / "fix" / "corregir" | `@builder` + `test-first` |
| "modificar" / "cambiar" | `@builder` |
| "vamos a implementar" / "build" | `@builder` |

### Revisión
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "revisar código" / "review" | `@reviewer` + `precommit-review` |
| "verificar" / "check" | `@reviewer` |
| "code review" | `@reviewer` |

### Seguridad
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "auditar" / "seguridad" | `@security-auditor` |
| "buscar vulnerabilidades" | `@security-auditor` |
| "revisar credenciales" | `@security-auditor` |

### Documentación
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "documentar" / "generar docs" | `@docs-writer` |
| "crear README" / "actualizar docs" | `@docs-writer` |

### DevOps
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "docker" / "ci/cd" / "deploy" | `@devops` |
| "kubernetes" / "terraform" | `@devops` |
| "infra" / "infraestructura" | `@devops` |

### Producción
| Si el usuario dice... | Usa este agente |
|------------------------|-----------------|
| "producción" / "prod" / "error" | `@oncall` |
| "debug" / "diagnosticar" | `@oncall` |
| "logs" / "crash" / "oncall" | `@oncall` |

---

## Workflows Automáticos

Para tareas completas, encadena agentes automáticamente:

| Tarea | Pipeline |
|-------|----------|
| "nuevo proyecto" | Docs-First → `@architect` → `@planner` → `@builder` → `@docs-writer` |
| "bug hunt" | `@architect` → `@security-auditor` → `@planner` → `@builder` → `@reviewer` |
| "documentar" | `@architect` → `@docs-writer` → `@reviewer` |
| "feature nueva" | `@architect` → `@planner` → `@builder` → `@reviewer` |
| "debug prod" | `@oncall` → `@builder` → `@security-auditor` |

---

## Fundamentos de AI Coding (del dictionary-of-ai-coding)

Entender cómo funciona el modelo permite escribir mejores prompts y detectar problemas.

### Smart Zone vs Dumb Zone

Sesión nueva = smart zone (agudo, enfocado, buena memoria). Session >20 turns ≈ dumb zone (olvidadizo, errores, más [hallucinations](#hallucination) de fidelidad).

**Regla:** No empujar a través de la dumb zone. Si la sesión tiene >20 turns y el agente empieza a cometer errores, hacer [compaction](#compaction) o clear en vez de seguir.

### Attention Budget

Cada token tiene presupuesto de atención finito. Más contexto = menos señal por token. Archivos importantes perto del final del prompt reciben más atención.

**Regla:** Poner información crítica (schemas, decisiones, constraints) cerca del final del contexto. No prepender grandes bloques de documentación — usar skills y punteros en vez.

### Sycophancy

El modelo tiende a acordar con inputs confiados incluso cuando están equivocados. Inputs neutrales producen mejor análisis.

**Regla:** Escribir prompts neutrales — "revisa este código" no "este código es bueno, revísalo". Si el usuario muestra sesgo, el agente lo seguirá. Antes de pedir review, no signalar la calidad esperada.

### Non-determinism

Mismo prompt ≠ mismo output. Sin cambio en el código, los resultados pueden variar entre ejecuciones. Los "malos días" del modelo son distribución, no regresión.

**Regla:** Si un resultado parece peor que ayer, intentar de nuevo antes de culpar al modelo. Regenerar o reformular es válido.

### Hallucination

Dos tipos:
- **Factual:** inventa facts (API que no existe). Fix: cargar docs en contexto.
- **De fidelidad:** se desvía del contexto cargado. Sintoma de [attention degradation](#attention-budget). Fix: clear o compact.

**Regla:** "Me inventó el método" → agregar docs al contexto. "Dejó de leer los docs que le di" → sesión muy larga, compactar.

### Compaction

Resumir historia de sesión en un prompt fresco. Lossy pero necesario cuando el contexto se acerca al límite.

**Regla:** `oc --compact` antes de continuar una sesión larga. Guardar lo load-bearing en docs/memory/ para persistencia cross-session.

### Non-determinism

Output del modelo varía incluso con input idéntico. Same prompt → different outputs across runs. No hay setting para eliminarlo.

**Regla:** Si el agente "empeoró" un día, probar de nuevo antes de buscar causas. Los malos días son distribución normal, no regresión.

### Sycophancy

El modelo соглашается con inputs confiados incluso incorrectos. Training lo hizo asociar "acuerdo" con "recompensa".

**Síntomas:**
- Cede ante pushback sin razón
- Alaba planesrotos porque el usuario sounds confident
- Sesgo en review (positivo si el usuario sounds like author, negativo si sounds como otro)

**Fix:** Escribir prompts neutrales. "analiza este código" no "es buen código?". Diagnostic: ¿el modelo habría dicho esto sin tu tono/señal?

### Contextual vs Parametric Knowledge

- **Parametric:** lo que el modelo "sabe" de training. Fuera de contexto = blur en temas raros.
- **Contextual:** lo que el agente puede leer directo del window. En contexto = preciso.

**Regla:** Si el modelo inventa sobre APIs internas → cargar docs en contexto. Si知道了 el schema pero ignora lo cargado → sesión muy larga, compactar.

### Handoff

Transferir contexto de una sesión a otra. No es clearing (que borra todo), es carry.

**Regla:** Para sesiones largas, escribir handoff artifact (resumen de decisiones, files, constraints) antes de clear. El agente nuevo empieza con el artifact como contexto inicial.

---

## Tradeoff

Estas reglas bias hacia **precisión sobre velocidad**. Para tareas triviales, usar juicio - no cada cambio necesita rigor completo. El objetivo es reducir errores costosos en trabajo no trivial.

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` to keep the graph current
