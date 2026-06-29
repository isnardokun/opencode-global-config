Ejecuta el siguiente workflow de debug para: {{target}}

EXIT_CONDITIONS:
- Maximum 5 agent turns total across all phases
- If P1 critical issue found in Phase 1, prioritize immediate mitigation before continuing
- After Phase 3, respond with exactly: WORKFLOW_COMPLETE=true

FASE 1 - @oncall:
Diagnostica el problema en: {{target}}
Clasifica por urgencia (P1/P2/P3) e identifica causa raíz.
Lista mitigaciones inmediatas disponibles.

FASE 2 - @builder con safe-implementation y test-first:
Implementa la corrección para: {{target}}
Escribe test que reproduce el bug primero, luego hazlo pasar.

FASE 3 - @security-auditor:
Verifica que la corrección no introduce vulnerabilidades.
Confirma que el fix es correcto y completo.

Ejecuta todas las fases en secuencia.
