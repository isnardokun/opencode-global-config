Ejecuta el siguiente workflow de documentación para: {{target}}

EXIT_CONDITIONS:
- Maximum 6 agent turns total across all phases
- If docs/ already complete and no drift detected, skip to Phase 3
- After Phase 3, respond with exactly: WORKFLOW_COMPLETE=true

FASE 0 - Docs-First:
Revisa si existe docs/. Si existe, léelo primero y detecta drift con el código real. Si no existe, crea o propone la carpeta docs/ como fuente de contexto viva.

FASE 1 - @architect con project-map:
Análisis completo de: {{target}}
Documenta: stack tecnológico, estructura de archivos, entry points, APIs, dependencias, configuraciones.

FASE 2 - @docs-writer:
Genera documentación completa para: {{target}}
Crea o actualiza docs/ con:
- PROJECT_CONTEXT.md
- BUSINESS_LOGIC.md
- DATA_STRUCTURE.md
- ARCHITECTURE.md
- DECISIONS.md
- CHANGELOG.md
- CONVERSATION.md
- TASKS.md
- RISKS.md
- ONBOARDING.md
También actualiza README.md, API.md o DEPLOY.md si aplican al proyecto real.
No inventes features. Si falta información de negocio o datos, deja preguntas abiertas.

FASE 3 - @reviewer:
Verifica que la documentación:
- Refleja el código real (accurate)
- Cubre casos importantes (completa)
- No tiene información obsoleta (actualizada)
Reporta solo problemas encontrados.

Ejecuta todas las fases en secuencia.
