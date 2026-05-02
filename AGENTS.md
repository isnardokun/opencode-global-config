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

---

## Skills preferidas

- project-map
- safe-implementation
- test-first (Goal-Driven)
- precommit-review

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
| "nuevo proyecto" | `@architect` → `@planner` → `@builder` → `@docs-writer` |
| "bug hunt" | `@architect` → `@security-auditor` → `@planner` → `@builder` → `@reviewer` |
| "documentar" | `@architect` → `@docs-writer` → `@reviewer` |
| "feature nueva" | `@architect` → `@planner` → `@builder` → `@reviewer` |
| "debug prod" | `@oncall` → `@builder` → `@security-auditor` |

---

## Tradeoff

Estas reglas bias hacia **precisión sobre velocidad**. Para tareas triviales, usar juicio - no cada cambio necesita rigor completo. El objetivo es reducir errores costosos en trabajo no trivial.