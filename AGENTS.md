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

---

## Señales de que está funcionando

- Menos cambios innecesarios en diffs
- Menos reescrituras por sobrecomplicación
- Preguntas clarificadoras ANTES de implementación
- Éxito verificable objetivamente

---

## Tradeoff

Estas reglas bias hacia **precisión sobre velocidad**. Para tareas triviales, usar juicio - no cada cambio necesita rigor completo. El objetivo es reducir errores costosos en trabajo no trivial.