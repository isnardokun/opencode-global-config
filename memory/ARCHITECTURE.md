# OpenCode Memory Bank

Sistema de memoria persistente inspirado en la arquitectura de 5 capas de compactación de Claude Code.

## Arquitectura

### File-based Memory (sin vector DB)
- Totalmente inspeccionable
- Editable por humanos
- Version-control compatible
- Búsqueda por headers, no embeddings

### Estructura

```
memory/
├── INDEX.md              # Header index para búsqueda rápida
├── projects/            # Memoria por proyecto
│   └── [project]/
│       ├── context.md       # Contexto actual del proyecto
│       ├── decisions/      # Decisiones técnicas (ADR)
│       └── patterns/        # Patrones detectados
├── context/             # Contexto global
│   └── global.md
└── ARCHITECTURE.md      # Este archivo
```

## Sistema de Búsqueda

### Header-based retrieval
1. Leer INDEX.md
2. Buscar headers que matcheen query
3. Cargar solo archivos relevantes
4. No usar embeddings/vector similarity

### Formato de Header

```markdown
---
date: 2026-05-01
project: mi-proyecto
type: decision
tags: [auth, jwt, security]
summary: Decisión de usar Redis para sesiones
---
```

## 5-Layer Compaction Pipeline

Inspirado en Claude Code:

| Capa | Función | Cuándo |
|------|---------|--------|
| **Budget Reduction** | Resumen agresivo por token budget | Cuando se acerca a límite |
| **Snip** | Recortar secciones menos relevantes | Context > 70% full |
| **Microcompact** | Comprimir cada archivo individual | Context > 85% full |
| **Context Collapse** | Proyección en tiempo de lectura | Context > 95% full |
| **Auto-Compact** | Full model summary (last resort) | Context overflow |

## Comandos

```bash
# Buscar en memory
oc --memory "docker"           # Busca en headers
oc --memory --context "auth"   # Busca con contexto completo

# Guardar
oc --remember "nota"           # Guarda en context/global.md
oc --remember -p proyecto "nota"  # Guarda en proyecto específico

# Proyectar (compaction)
oc --compact                   # Ejecuta compaction pipeline
```

## Guía de Uso

### Memoria por Proyecto
```bash
# Iniciar memoria para proyecto
oc --remember -p mi-proyecto "Stack: FastAPI + PostgreSQL"
oc --remember -p mi-proyecto "Decisión: usar Alembic para migrations"
```

### Decisiones Técnicas (ADR)
```bash
oc --remember -p mi-proyecto -t decision "Usamos PostgreSQL porque..."
```

### Patterns
```bash
oc --remember -p mi-proyecto -t pattern "El auth JWT se valida en middleware/"
```