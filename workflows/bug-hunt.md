Ejecuta el siguiente workflow completo para: {{target}}

EXIT_CONDITIONS:
- Maximum 8 agent turns total across all phases
- If no bugs found after Phase 2, stop and report
- After Phase 5, respond with exactly: WORKFLOW_COMPLETE=true

FASE 1 - @architect con project-map:
Analiza el proyecto en: {{target}}
Identifica archivos críticos y posibles áreas con bugs.
Reporta: stack detectado, estructura, riesgos.

FASE 2 - @security-auditor:
Revisa el código buscando: errores lógicos, variables indefinidas, imports rotos, memory leaks, edge cases no manejados.
No modifiques nada. Lista todos los problemas encontrados con severidad.

FASE 3 - @planner:
Basado en los problemas encontrados, crea plan de corrección con fases verificables.
Ordena por prioridad: crítico → alto → bajo.

FASE 4 - @builder con safe-implementation y test-first:
Implementa las correcciones planificadas en: {{target}}
Máximo 3 archivos por iteración. Agrega tests para cada fix.

FASE 5 - @reviewer con precommit-review:
Verifica que los fixes funcionan correctamente.
Confirma que no se introdujeron nuevos errores.
Reporta resultado final.

Ejecuta todas las fases en secuencia. Reporta resultados de cada fase antes de continuar a la siguiente.
