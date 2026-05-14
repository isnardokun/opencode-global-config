# Grilling Rubric

Revisión pre-implementación: cuestionar el plan antes de ejecutar.

## Secuencia de Grilling

1. **Claridad del objetivo**: ¿Qué problema resuelve? ¿Para quién?
2. **Scope creep potencial**: ¿Qué podría agregar el usuario que no pidió?
3. **Fallback plan**: ¿Qué si no funciona? ¿Cuándo abortar?
4. **Decisiones técnicas implícitas**: ¿Qué supuestos tiene el plan?
5. **Signals de sycophancy**: ¿El plan refleja necesidad real o preferencia del usuario?

## Preguntas de diagnóstico

- "¿Cuál es el criterio de éxito mínimo?" → Si no puede responder, el plan no está listo.
- "¿Qué pasa si esto falla?" → Si no hay rollback, el riesgo es alto.
- "¿Cuántos archivos cambias?" → Si >3 sin justificación, simplificar.
- "¿Por qué este approach y no otro?" → surface tradeoffs antes de proceder.

## Regla de las 3 preguntas

Antes de implementar, el agente debe hacer:
1. ¿Qué problema resuelve esto exactamente?
2. ¿Cuál es el mínimo cambio que resuelve el problema?
3. ¿Qué podría ir mal y cómo se revierte?

## Output

- Resumen del plan en 1-2 oraciones.
- 3 decisiones técnicas clave (con razón).
- 2+ riesgos potenciales (con mitigación).
- Decisión: proceed / refine / abort.

## Cuándo aplicar

- `@planner` antes de generar plan completo
- `@builder` antes de implementar feature
- Cualquier request vaga o ambigua
- Cuando el usuario sounds confident about a broken plan