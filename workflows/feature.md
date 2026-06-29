Ejecuta el siguiente workflow para implementar: {{feature_desc}} en: {{target}}

EXIT_CONDITIONS:
- Maximum 8 agent turns total across all phases
- If critical info missing after Phase 0, stop and ask before proceeding
- After Phase 4, respond with exactly: WORKFLOW_COMPLETE=true

FASE 0 - Docs-First:
Antes de diseñar o editar, revisa docs/ si existe. Si falta docs/ o no contiene contexto suficiente para la feature, crea/actualiza documentación mínima o haz preguntas puntuales.

FASE 1 - @architect:
Analiza: {{target}} para implementar: {{feature_desc}}
Identifica:
- Archivos a modificar
- Puntos de extensión existentes
- Posibles conflictos con código existente
- Tradeoffs del approach

FASE 2 - @planner:
Planifica la implementación de: {{feature_desc}} en: {{target}}
Divide en pasos verificables con criterios de éxito claros.

FASE 3 - @builder con safe-implementation y test-first:
Implementa: {{feature_desc}}
Escribe tests primero, luego implementación.
Máximo 3 archivos por iteración.

FASE 4 - @reviewer con precommit-review:
Revisa la implementación de {{feature_desc}}
Verifica: correctitud, tests, no regresiones, código limpio.

Ejecuta todas las fases en secuencia.
