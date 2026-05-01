# OpenCode Global Configuration

Configuración global personalizada para OpenCode CLI con agentes especializados, sistema de memoria, perfiles y flujo de trabajo estructurado.

Inspirado en análisis de Claude Code (VILA-Lab/Dive-into-Claude-Code) y directrices de Andrej Karpathy.

## Tabla de Contenidos

- [Descripción](#descripción)
- [Quick Start](#quick-start)
- [Comandos Rápidos](#comandos-rápidos)
- [Modo Interactivo](#modo-interactivo)
- [Modo Wizard](#modo-wizard)
- [Memory Bank](#memory-bank)
- [Souls/Personas](#soulspersonas)
- [Perfiles y Niveles de Confianza](#perfiles-y-niveles-de-confianza)
- [Git Hooks](#git-hooks)
- [Inicializar Proyecto](#inicializar-proyecto)
- [Context Budget Tracking](#context-budget-tracking)
- [Reversibility-Weighted Risk](#reversibility-weighted-risk)
- [Estructura](#estructura)
- [Inspiración](#inspiración)

---

## Descripción

Este repositorio contiene una configuración avanzada para [OpenCode CLI](https://opencode.ai) inspirada en Claude Code y proyectos de código abierto.

### Características Principales (v1.6)

- **8 agentes especializados** con permisos y temperature optimizados
- **6 skills** para análisis, implementación, validación y memoria
- **1 plugin de seguridad** que bloquea comandos peligrosos
- **Sistema de Memory Bank** con 3-layer retrieval (search/timeline/get)
- **5 workflows automáticos** (bug-hunt, new-project, debug, document, feature)
- **Souls/Personas** para diferentes contextos
- **7 perfiles** (deny → plan → review → default → auto → trusted → devops)
- **Git Hooks** para revisión automática
- **Comandos rápidos** para acceso directo
- **Modo Wizard** guiado paso a paso
- **Menú interactivo** con fzf
- **Context Budget Tracking** para evitar overflow
- **Reversibility-Weighted Risk Assessment** en @oncall
- **Karpathy Principles** (Think, Simplicity, Surgical, Goal-Driven)

---

## Quick Start

```bash
# Clonar e instalar
git clone https://github.com/isnardokun/opencode-global-config.git /tmp/opencode-config
cp -r /tmp/opencode-config/* ~/.config/opencode/
mkdir -p ~/.local/bin && cp /tmp/opencode-config/oc ~/.local/bin/ && chmod +x ~/.local/bin/oc

# Verificar
oc --help
```

---

## Comandos Rápidos

```bash
# Análisis
oc analyze ~/proyecto       # @architect + project-map
oc plan "tarea compleja"    # @planner
oc build "nuevo feature"    # @builder + test-first
oc review                   # @reviewer + precommit-review

# Especializados
oc secure                   # @security-auditor
oc docs                     # @docs-writer
oc devops "dockerfile"      # @devops
oc oncall                   # @oncall

# Perfiles
oc --profile deny          # Máximo restrictivo
oc --profile plan          # Solo planificación
oc --profile auto         # ML classifier approval
oc --profile devops       # Infra con rollback

# Memory y Budget
oc --memory "query"       # Buscar en memory bank
oc --remember "nota"      # Guardar en memory
oc --compact              # Compaction pipeline
oc --budget               # Ver uso de sesión

# Directos
oc "cualquier tarea"       # Envía directamente a OpenCode
```

---

## Perfiles y Niveles de Confianza

Sistema de 7 perfiles con Deny-First gradient (inspirado en Claude Code's 7 permission modes):

| Perfil | Descripción | Temp | Archivos/iter | Edit | Bash | Destructive |
|--------|-------------|------|---------------|------|------|-------------|
| `deny` | Solo análisis estático | 0.0 | 0 | ❌ | ❌ | ❌ |
| `plan` | Planificación, no modificar | 0.1 | 10 | ❌ | ❌ | ❌ |
| `review` | Lectura y análisis | 0.1 | 15 | ❌ | ask | ❌ |
| `default` | Desarrollo general | 0.2 | 3 | ask | ask | ask |
| `auto` | ML classifier approval | 0.2 | 5 | auto | auto | ask |
| `trusted` | Desarrollador avanzado | 0.3 | 10 | ✅ | ✅ | ✅ |
| `devops` | Infra con rollback | 0.05 | 20 | ✅ | ✅ | ✅ + checkpoint |

### Perfil Auto (ML Classifier)

El perfil `auto` simula el comportamiento de Claude Code Auto Mode:
- Approvals basados en historial de decisiones
- Security review requerido para archivos sensibles
- Track de decisiones para aprendizaje

### Cambiar Perfil

```bash
oc --profile work      # Productivo (equivale a default)
oc --profile plan     # Solo planificación
oc --profile devops   # DevOps con rollback
oc --profile deny     # Máximo restrictivo
oc --list-profiles    # Ver todos disponibles
```

---

## Context Budget Tracking

Inspirado en la arquitectura de 5-layer compaction de Claude Code:

```bash
oc --budget           # Ver uso actual
oc --compact          # Ejecutar compaction pipeline
```

### 5-Layer Compaction Pipeline

| Capa | Función | Cuándo |
|------|---------|--------|
| **Budget Reduction** | Resumen agresivo | Turns > 50 |
| **Snip** | Recortar secciones | Context > 70% |
| **Microcompact** | Comprimir archivos | Context > 85% |
| **Context Collapse** | Proyección en lectura | Context > 95% |
| **Auto-Compact** | Full summary | Overflow |

---

## Reversibility-Weighted Risk

@oncall ahora evalúa acciones por reversibilidad:

| Acción | Reversible? | Approbación |
|--------|-------------|-------------|
| Restart servicio | ✅ | Mínimo |
| Clear cache | ✅ | Mínimo |
| Rollback deployment | ✅ | средний |
| Escalado | ✅ | Mínimo |
| Edit config (runtime) | ⚠️ | Confirmación |
| Delete datos | ❌ | +1 reviewer + backup |
| Drop table | ❌ | Emergency protocol |

---

## Memory Bank (3-Layer Retrieval)

Sistema de memoria persistente con búsqueda por headers e **Progressive Disclosure** (3 camadas):

```bash
# Capa 1: Search (~50-100 tokens/resultado)
oc --memory "docker" -p mi-api -t decision

# Capa 2: Timeline (~200 tokens)
oc --memory --timeline obs_001

# Capa 3: Get full detail (~500-1000 tokens)
oc --memory --get obs_001,obs_002

# Crear observación
oc --remember -t bugfix "Fixed JWT expiration bug"
oc --remember "Nota general"
```

### Formato de Observations

```markdown
---
id: obs_XXX
date: 2026-05-01 14:30:00
project: mi-api
type: bugfix
summary: Fix JWT expiration bug
tokens_est: 500
---

Contenido completo de la observación...


```bash
# Buscar
oc --memory "docker"           # Busca en headers
oc --memory -p proyecto "auth" # Busca en proyecto específico

# Guardar
oc --remember "nota"          # Guarda en contexto global
oc --remember -p proyecto "decisión" # Guarda en proyecto

# Formato
---
date: 2026-05-01
project: mi-proyecto
type: decision
tags: [auth, jwt]
summary: Usamos Redis para sesiones
---
```

---

## Workflows (Automatic Single-Pass)

Sistema de workflows que ejecutan **todas las fases automáticamente en una sola pasada** de OpenCode. Sin intervención del usuario.

```bash
# Ejecución automática (sin confirmación entre fases)
oc --workflow bug-hunt ~/proyecto           # 5 fases
oc --workflow new-project "mi-api"          # 4 fases
oc --workflow debug "fix memory leak"      # 3 fases
oc --workflow document ~/proyecto           # 3 fases
oc --workflow feature "add auth" ~/api      # 4 fases
```

### Workflows Disponibles

| Workflow | Fases | Agentes | Tiempo |
|----------|-------|---------|--------|
| `bug-hunt` | 5 | architect → security → planner → builder → reviewer | ~5min |
| `new-project` | 4 | architect → planner → builder → docs | ~4min |
| `debug` | 3 | oncall → builder → security | ~3min |
| `document` | 3 | architect → docs-writer → reviewer | ~3min |
| `feature` | 4 | architect → planner → builder → reviewer | ~4min |

### Cómo Funciona

Cada workflow envía **un solo comando `opencode run`** con todas las fases codificadas en el prompt:

```
opencode run "Ejecuta el workflow COMPLETO de document para: $target

FASE 1 - @architect con project-map:
- Analiza el proyecto en: $target
- Documenta: stack, estructura, entry points, APIs

FASE 2 - @docs-writer genera documentación:
- Crea README.md, ARCHITECTURE.md, API.md

FASE 3 - @reviewer verifica documentación
..."
```

El agente ejecuta todas las fases secuencialmente y crea los archivos en el proyecto objetivo.

---

## Estructura

```
opencode-global-config/
├── oc                      # Script principal con workflows y 3-layer memory
├── agents/
│   ├── architect.md         # + Tradeoffs declarations
│   ├── planner.md          # + Success criteria
│   ├── builder.md          # + Karpathy principles
│   ├── reviewer.md
│   ├── security-auditor.md
│   ├── docs-writer.md
│   ├── devops.md
│   └── oncall.md           # + Reversibility-weighted risk
├── skills/
│   ├── project-map/
│   ├── safe-implementation/
│   ├── test-first/          # + Goal-Driven Execution
│   └── precommit-review/
├── plugins/
│   └── safety-guard.js
├── memory/
│   ├── INDEX.md            # Header index
│   ├── ARCHITECTURE.md      # 5-layer compaction
│   ├── projects/
│   ├── decisions/
│   └── patterns/
├── profiles/               # 7 trust levels
│   ├── deny.json
│   ├── plan.json
│   ├── review.json
│   ├── default.json
│   ├── auto.json           # ML classifier
│   ├── trusted.json
│   └── devops.json
├── souls/
│   └── souls.md
├── hooks/
│   ├── pre-commit
│   └── pre-push
├── CLAUDE.md               # Karpathy guidelines
├── AGENTS.md               # Reglas globales actualizadas
├── README.md
├── INSTALL.md
├── CHANGELOG.md
└── LICENSE
```

---

## Inspiración y Fuentes

### Análisis de Arquitectura Claude Code
- [VILA-Lab/Dive-into-Claude-Code](https://github.com/VILA-Lab/Dive-into-Claude-Code) (929 stars) - Paper académico: "98.4% infrastructure, 1.6% AI"
- [Piebald-AI/claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts) (9806 stars)

### Directrices Karpathy
- [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (105k stars)

### Memory Systems
- [kunickiaj/codemem](https://github.com/kunickiaj/codemem)
- [swarmclawai/swarmvault](https://github.com/swarmclawai/swarmvault) (295 stars)

### Skills & Plugins
- [jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) (2077 stars)

---

## Changelog

### v1.6 (2026-05-01)
- **Workflows automático single-pass**: Todas las fases ejecutan en una sola llamada a `opencode run`
- Timeout extendido a 300s para proyectos grandes
- 5 workflows funcionando sin intervención del usuario

### v1.5 (2026-05-01)
- Sistema de workflows con 5 pipelines pre-configurados
- Modo interactivo opcional con `--interactive`

### v1.4 (2026-05-01)
- 3-layer memory retrieval (search/timeline/get)
- Observation format con privacy tags
- Auto-capture functions

### v1.3 (2026-05-01)
- 7 perfiles con Deny-First gradient
- Reversibility-weighted risk en @oncall
- Context budget tracking (turns counter)
- 5-layer compaction pipeline
- Memory bank con header-based retrieval

### v1.2 (2026-05-01)
- Integración de 4 principios de Karpathy

### v1.1 (2026-05-01)
- Wizard, interactive menu, memory bank, souls, profiles, hooks, quick commands

### v1.0 (2026-05-01)
- Initial release - 8 agents, 4 skills, safety plugin, oc command

---

## Licencia

MIT License