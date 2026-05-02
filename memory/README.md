# OpenCode Memory Bank

Sistema de memoria persistente para OpenCode. Aquí se almacena contexto que persiste entre sesiones.

## Estructura

```
memory/
├── projects/           # Memoria por proyecto
├── patterns/           # Patrones detectados
├── decisions/          # Decisiones técnicas (ADR)
└── context/           # Contexto general
```

## Comandos

```bash
oc --memory <búsqueda>  # Buscar en memoria
oc --remember <texto>    # Guardar en memoria
```

## Formato de entradas

```markdown
---
Fecha: 2026-05-01
Proyecto: mi-proyecto
Tipo: decision
---

# Decisión: Usar PostgreSQL en vez de MySQL

## Razón
- Mejor soporte JSON
- Índices partiales
- Comunidad activa

## Alternativas consideradas
- MySQL: menor costo de migration
- MongoDB: schema flexibility

## Decisión final
PostgreSQL
```

## Guidelines

1. Cada entrada debe tener fecha y tipo
2. Proyectos van en `projects/<nombre>.md`
3. Decisiones en `decisions/<date>-<slug>.md`
4. Patterns en `patterns/<categoria>.md`