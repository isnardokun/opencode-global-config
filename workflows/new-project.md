Ejecuta el siguiente workflow completo para nuevo proyecto: {{target}}

EXIT_CONDITIONS:
- Maximum 6 agent turns total across all phases
- If critical information is missing after Phase 0, stop and ask questions before proceeding
- After Phase 4, respond with exactly: WORKFLOW_COMPLETE=true

FASE 0 - Docs-First:
Antes de crear código, determina si hay información suficiente. Si faltan datos críticos, haz preguntas puntuales al usuario y espera respuesta.
Crea o propone una carpeta docs/ como guía viva del proyecto con, según aplique:
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
No inventes reglas de negocio, datos ni integraciones. Marca supuestos y preguntas abiertas.

FASE 1 - @architect:
Analiza el contexto: {{target}}
Identifica stack recomendado, dependencias y arquitectura inicial.

FASE 2 - @planner:
Planifica la estructura del proyecto. Incluye:
- Estructura de directorios
- Archivos de configuración necesarios
- Dependencias
- Tests iniciales a escribir

FASE 3 - @builder con safe-implementation:
Crea la estructura básica del proyecto: {{target}}
Genera los archivos base según el plan.

FASE 4 - @docs-writer:
Completa y alinea la documentación inicial en docs/ y README.md:
- contexto del proyecto
- lógica de negocio
- estructura de datos
- arquitectura
- decisiones
- changelog inicial
- conversación/contexto curado
- tareas, riesgos y onboarding

Ejecuta todas las fases en secuencia.
