# OpenCode Global Configuration

Configuración global personalizada para OpenCode CLI con agentes especializados, sistema de memoria, perfiles y flujo de trabajo estructurado.

Inspirado en análisis de Claude Code (VILA-Lab/Dive-into-Claude-Code) y directrices de Andrej Karpathy.

## Tabla de Contenidos

- [Descripción](#descripción)
- [Quick Start](#quick-start)
- [Manual de Uso](#manual-de-uso)
  - [Primera vez en un proyecto desconocido](#1-primera-vez-en-un-proyecto-desconocido)
  - [Implementar una feature nueva](#2-implementar-una-feature-nueva)
  - [Bug en producción](#3-bug-en-producción--respuesta-de-urgencia)
  - [Auditoría de seguridad](#4-auditoría-de-seguridad-antes-de-deploy)
  - [Generar documentación](#5-generar-documentación-de-un-proyecto-existente)
  - [Nuevo proyecto desde cero](#6-arrancar-un-proyecto-nuevo-desde-cero)
  - [Code review pre-commit](#7-code-review-antes-de-hacer-commit)
  - [Memory Bank](#8-trabajo-con-memory-bank)
  - [Refactor controlado](#9-refactor-controlado)
  - [DevOps e infraestructura](#10-devops--infraestructura-y-deploys)
  - [Perfiles — cuándo usar cada uno](#11-flujos-por-perfil--cuándo-usar-cada-uno)
  - [Sesión larga — gestión de contexto](#12-sesión-larga--gestión-de-contexto)
  - [Modo interactivo](#13-modo-interactivo--exploración-sin-saber-qué-necesitas)
  - [Modo wizard](#14-modo-wizard--guía-paso-a-paso)
- [Comandos Rápidos](#comandos-rápidos)
- [Perfiles y Niveles de Confianza](#perfiles-y-niveles-de-confianza)
- [Context Budget Tracking](#context-budget-tracking)
- [Reversibility-Weighted Risk](#reversibility-weighted-risk)
- [Memory Bank](#memory-bank)
- [Modo Interactivo](#modo-interactivo)
- [Modo Wizard](#modo-wizard)
- [Workflows](#workflows)
- [Plugin de Seguridad](#plugin-de-seguridad)
- [Inicializar Proyecto](#inicializar-proyecto)
- [Git Hooks](#git-hooks)
- [Souls/Personas](#soulspersonas)
- [Estructura](#estructura)
- [Inspiración](#inspiración)

---

## Descripción

Este repositorio contiene una configuración avanzada para [OpenCode CLI](https://opencode.ai) inspirada en Claude Code y proyectos de código abierto.

### Características Principales (v1.7)

- **8 agentes especializados** con permisos y temperature optimizados
- **6 skills** para análisis, implementación, validación, memoria y documentación
- **1 plugin de seguridad** con regex hardening (whitespace-normalized matching)
- **Sistema de Memory Bank** con 3-layer retrieval (search/timeline/get)
- **5 workflows single-pass** (bug-hunt, new-project, debug, document, feature)
- **Souls/Personas** para diferentes contextos
- **7 perfiles** con Deny-First gradient — perfil activo propagado a todas las llamadas
- **Git Hooks** para revisión automática
- **Comandos rápidos** para acceso directo
- **Modo Wizard** guiado paso a paso
- **Menú interactivo** con fzf (parsing corregido)
- **Context Budget Tracking** con contador de turns
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

**Requisitos:** `opencode` (requerido), `fzf` (solo para `--interactive`)

---

## Modo Natural (Nuevo!) - Recomendado

Ya no necesitas comandos. Solo describe lo que quieres:

```
# Análisis
"analiza el proyecto"
"qué stack usa?"
"entender la estructura"

# Implementación
"implementa autenticación con JWT"
"crea un endpoint para usuarios"
"agrega validación de inputs"

# Revisión
"revisame el código"
"busca errores de seguridad"
"verifica los cambios"

# Documentación
"genera documentación"
"crea README para el proyecto"
"actualiza la API docs"

# Bugs
"hay bugs en el código?"
"arregla el error de login"
"por qué falla el build?"
```

El sistema detecta la intención y usa el agente adecuado automáticamente.

---

## Manual de Uso

Casos de uso reales organizados por situación. Cada sección muestra el flujo completo desde el problema hasta la solución.

---

### 1. Primera vez en un proyecto desconocido

Llegas a un repo que nunca has visto. Antes de tocar nada:

```bash
cd ~/proyectos/legacy-api

# Entender qué hace el proyecto
oc analyze .

# Output esperado de @architect:
# - Stack: Node.js 16, Express, MongoDB, Redis
# - Entry points: src/index.js, src/api/routes/
# - Archivos críticos: src/auth/middleware.js, src/db/connection.js
# - Riesgos: dependencias desactualizadas, sin tests en /api/payments
# - Plan sugerido: 3 fases
```

Ahora tienes contexto. Ningún archivo fue modificado (`@architect` tiene permisos de solo lectura).

---

### 2. Implementar una feature nueva

Flujo completo: entender → planificar → implementar → revisar.

```bash
# Opción A: workflow automático (todo en una sesión)
oc --workflow feature "agregar autenticación OAuth2 con Google" ~/mi-api

# Opción B: control manual paso a paso
oc analyze ~/mi-api                          # Entender estructura primero
oc plan "agregar OAuth2 con Google"          # Ver plan antes de ejecutar
oc build "implementar OAuth2 con Google"     # Ejecutar con test-first
oc review                                    # Revisar antes de commit
```

**Cuándo usar workflow vs manual:**
- Workflow: feature bien definida, proyecto que ya conoces
- Manual: primera vez en el codebase, feature ambigua, quieres aprobar cada paso

---

### 3. Bug en producción — respuesta de urgencia

```bash
# Paso 1: activar perfil restrictivo para diagnóstico (no toca nada)
oc --profile review

# Paso 2: diagnosticar
oc oncall
# @oncall clasifica como P1/P2/P3, identifica causa raíz,
# lista mitigaciones por reversibilidad

# Paso 3: cuando tienes el diagnóstico, activar perfil de fix
oc --profile trusted

# Paso 4: implementar fix con test
oc build "fix: JWT token validation rejecting valid tokens after DST change"

# Paso 5: verificar
oc review

# Paso 6: guardar lo que pasó en memoria para futura referencia
oc --remember -t bugfix "JWT falla en cambio de horario DST — usar UTC en token generation, no local time"
```

**Workflow alternativo (completo automático):**
```bash
oc --workflow debug "JWT token validation failing after DST change in ~/api"
```

---

### 4. Auditoría de seguridad antes de deploy

```bash
# Activar perfil máximo restrictivo (zero modificaciones)
oc --profile deny

# Auditar el codebase
oc secure

# Output esperado de @security-auditor:
# - CRÍTICO: SQL injection en /api/search?q= (sin sanitización)
# - ALTO: JWT secret hardcodeado en config/default.js línea 23
# - MEDIO: Rate limiting ausente en /api/auth/login
# - BAJO: Logs exponen emails de usuarios en error handlers

# Volver a perfil normal para corregir
oc --profile default
oc build "fix vulnerabilidades: sanitizar inputs, mover JWT secret a env var, agregar rate limiting"
```

---

### 5. Generar documentación de un proyecto existente

```bash
# Proyecto con código pero sin docs
oc --workflow document ~/mi-proyecto

# Genera automáticamente:
# - README.md (descripción, instalación, uso, ejemplos)
# - ARCHITECTURE.md (diagrama de componentes, flujo de datos)
# - API.md (endpoints, formatos, ejemplos de request/response)
# - DEPLOY.md (instrucciones de deployment si detecta Docker/CI)
```

Para documentar solo parte del proyecto:
```bash
oc docs
# @docs-writer trabaja sobre el directorio actual
# Útil cuando cd a un subdirectorio específico
```

---

### 6. Arrancar un proyecto nuevo desde cero

```bash
# Crear estructura base
oc --workflow new-project "API REST para gestión de inventario con Node.js y PostgreSQL"

# El workflow:
# Fase 1: @architect decide estructura, stack, dependencias
# Fase 2: @planner crea plan con directorios, archivos config, tests iniciales
# Fase 3: @builder genera el scaffold
# Fase 4: @docs-writer crea README, ARCHITECTURE, CONTRIBUTING

# Después del workflow, inicializar config local de OpenCode
oc --init .
# Crea .opencode/opencode.json y git hook de pre-commit
```

---

### 7. Code review antes de hacer commit

```bash
# Tienes cambios staged, quieres revisarlos antes de commitear
oc review

# @reviewer con precommit-review reporta:
# - Archivos modificados
# - Hallazgos críticos (bloqueantes)
# - Hallazgos medios (advertencias)
# - Tests presentes o ausentes
# - Recomendación: aprobar / corregir

# Si hay issues críticos:
oc build "corregir: <descripción del hallazgo crítico>"
oc review  # volver a revisar
```

El git hook instalado por `oc --init` hace esto automáticamente en cada `git commit`.

---

### 8. Trabajo con Memory Bank

El memory bank guarda contexto entre sesiones. Útil para decisiones técnicas, bugs recurrentes, patrones del proyecto.

**Guardar una decisión técnica:**
```bash
oc --remember -t decision "Elegimos CQRS sobre repositorio genérico porque los queries de reporting son muy complejos y necesitan optimización independiente"

oc --remember -t config "Redis en producción usa db=1 para sesiones, db=2 para cache, db=3 para rate limiting — no mezclar"

oc --remember -t bugfix "El worker de emails se cuelga si el subject tiene caracteres UTF-8 > 3 bytes — sanitizar antes de encolar"
```

**Recuperar contexto antes de trabajar:**
```bash
# Buscar todo lo relacionado con auth
oc --memory "auth"

# Resultado Capa 1 (rápido, ~80 tokens):
# obs_20260501-143022-a1b2 | 2026-05-01 | mi-api | decision | Elegimos JWT sobre session cookies
# obs_20260501-150344-c3d4 | 2026-05-01 | mi-api | bugfix    | JWT falla en cambio DST

# Ver contexto alrededor de una observación
oc --memory --timeline 20260501-143022-a1b2

# Ver detalle completo
oc --memory --get 20260501-143022-a1b2
```

**Flujo típico al retomar un proyecto:**
```bash
oc --memory "redis"       # ¿qué sé sobre redis en este proyecto?
oc --memory "auth"        # ¿decisiones de autenticación?
oc --memory -t bugfix ""  # ¿qué bugs ya se corrigieron?
# Ahora tienes contexto. Empieza a trabajar.
```

---

### 9. Refactor controlado

Cuando necesitas refactorizar sin romper nada:

```bash
# Fase 1: entender qué toca el código a refactorizar
oc analyze src/services/

# Fase 2: planificar con criterios de éxito explícitos
oc plan "refactorizar UserService para separar lógica de auth de lógica de perfil — tests deben pasar antes y después"

# Fase 3: implementar con perfil conservador
oc --profile default   # edit=ask — confirma cada cambio
oc build "refactorizar UserService: extraer AuthService y ProfileService"

# Fase 4: revisar diff completo
oc review
```

---

### 10. DevOps — infraestructura y deploys

```bash
# Activar perfil devops (temperature 0.05, documentación obligatoria de cambios)
oc --profile devops

# Tareas de infraestructura
oc devops "crear Dockerfile multi-stage para la API, optimizado para producción"
oc devops "configurar GitHub Actions CI/CD con tests, build y deploy a staging"
oc devops "agregar health check endpoint y configurar liveness/readiness probes para Kubernetes"

# Diagnóstico de producción
oc oncall
# @oncall con reversibility-weighted risk:
# Acciones reversibles (restart, rollback) → aprobación mínima
# Acciones destructivas (drop table) → requiere +1 reviewer + backup confirmado
```

---

### 11. Flujos por perfil — cuándo usar cada uno

```bash
# Explorar sin riesgo (cero modificaciones posibles)
oc --profile deny
oc "¿qué hace este código?"
oc analyze .

# Planificación — reunión técnica, estimación, diseño
oc --profile plan
oc plan "migrar de MongoDB a PostgreSQL"
# El agente produce plan detallado sin poder ejecutar nada

# Code review de un PR ajeno
oc --profile review
oc "revisa los cambios en src/api/ y reporta problemas"

# Desarrollo día a día
oc --profile default   # pide confirmación antes de cada cambio

# Confianza total — proyecto propio, bien conocido
oc --profile trusted
oc build "implementar paginación en todos los endpoints de listado"

# Infra y scripts de automatización
oc --profile devops
oc devops "crear script de backup automático para PostgreSQL"
```

---

### 12. Sesión larga — gestión de contexto

```bash
# Ver cuántos turns llevas en la sesión actual
oc --budget
# Session turns: 34
# Consider running: oc --compact

# Cuando llevas muchos turns y el contexto se vuelve ruidoso:
# 1. Resumir manualmente lo importante en una nota
oc --remember "Estado actual: implementando OAuth2, completadas fases 1-3, pendiente integrar con frontend"

# 2. Resetear el contador
oc --compact
# Turn counter reset to 0.
# Warning: para sesiones largas, resumir contexto clave manualmente antes de continuar.

# 3. Continuar con contexto limpio
oc --memory "OAuth2"   # recuperar el resumen que guardaste
oc build "integrar OAuth2 con el frontend React"
```

---

### 13. Modo interactivo — exploración sin saber qué necesitas

Cuando no tienes claro qué agente usar:

```bash
oc --interactive   # requiere fzf

# Aparece menú:
# a  @architect    - Analizar arquitectura y riesgos
# b  @builder      - Implementar cambios
# r  @reviewer     - Revisar código
# ...

# Selecciona con flechas, Enter ejecuta
# Los agentes que necesitan input (p, b, v) piden descripción antes de ejecutar
```

---

### 14. Modo wizard — guía paso a paso

Para tareas complejas con confirmación entre fases:

```bash
oc --wizard

# Menú:
# 1) Analizar proyecto
# 2) Planificar tarea compleja
# 3) Implementar nuevo feature
# 4) Revisar código existente
# 5) Auditoría de seguridad
# 6) DevOps

# Selecciona opción, ingresa descripción
# El wizard confirma antes de pasar a cada fase siguiente
# Puedes cancelar en cualquier punto respondiendo 'n'
```

Útil para: nuevos proyectos, features grandes, cuando quieres ver resultados de cada fase antes de continuar.

---

### Referencia rápida de agentes

| Agente | Permisos | Cuándo usarlo |
|--------|----------|---------------|
| `@architect` | read-only | Entender antes de modificar |
| `@planner` | read-only | Diseñar plan con fases verificables |
| `@builder` | edit + bash(ask) | Implementar código |
| `@reviewer` | read-only | Revisar diff antes de commit |
| `@security-auditor` | read-only | Buscar vulnerabilidades |
| `@docs-writer` | edit | Generar/actualizar documentación |
| `@devops` | edit + bash | Infraestructura, CI/CD, scripts |
| `@oncall` | bash(ask) | Diagnosticar y mitigar producción |

---



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

# Perfiles (persiste para todos los comandos siguientes)
oc --profile deny           # Máximo restrictivo
oc --profile plan           # Solo planificación
oc --profile devops         # Infra con rollback
oc --list-profiles          # Ver todos disponibles

# Memory
oc --memory "query"         # Buscar en memory bank
oc --remember "nota"        # Guardar en memory
oc --budget                 # Ver turns de sesión
oc --compact                # Resetear contador de turns

# Directo
oc "cualquier tarea"        # Envía directamente a OpenCode
```

---

## Perfiles y Niveles de Confianza

Sistema de 7 perfiles con Deny-First gradient (inspirado en Claude Code's 7 permission modes).

El perfil activo se aplica a **todos** los comandos siguientes hasta cambiar o cerrar sesión.

| Perfil | Descripción | Temp | Archivos/iter | Edit | Bash | Destructive |
|--------|-------------|------|---------------|------|------|-------------|
| `deny` | Solo análisis estático | 0.0 | 0 | ❌ | ❌ | ❌ |
| `plan` | Planificación, no modificar | 0.1 | 10 | ❌ | ❌ | ❌ |
| `review` | Lectura y análisis | 0.1 | 15 | ❌ | ask | ❌ |
| `default` | Desarrollo general | 0.2 | 3 | ask | ask | ask |
| `auto` | Aprobación automática | 0.2 | 5 | auto | auto | ask |
| `trusted` | Desarrollador avanzado | 0.3 | 10 | ✅ | ✅ | ✅ |
| `devops` | Infra con rollback | 0.05 | 20 | ✅ | ✅ | ✅ + checkpoint |

```bash
oc --profile devops   # Activar perfil
oc --list-profiles    # Ver todos disponibles
```

---

## Context Budget Tracking

Contador de turns de sesión para monitorear uso de contexto.

```bash
oc --budget    # Ver turns actuales
oc --compact   # Resetear contador (recomendado hacer resumen manual en sesiones largas)
```

Advertencia automática cuando turns > 20.

---

## Reversibility-Weighted Risk

`@oncall` evalúa acciones por reversibilidad:

| Acción | Reversible? | Aprobación |
|--------|-------------|------------|
| Restart servicio | ✅ | Mínimo |
| Clear cache | ✅ | Mínimo |
| Rollback deployment | ✅ | Confirmación |
| Escalado | ✅ | Mínimo |
| Edit config (runtime) | ⚠️ | Confirmación |
| Delete datos | ❌ | +1 reviewer + backup |
| Drop table | ❌ | Emergency protocol |

---

## Memory Bank (3-Layer Retrieval)

Sistema de memoria persistente con Progressive Disclosure — carga solo el contexto necesario.

```bash
# Capa 1: Search (~50-100 tokens/resultado)
oc --memory "docker"
oc --memory "auth" -t decision

# Capa 2: Timeline (~200 tokens)
oc --memory --timeline 20260501-143022-a1b2c3d4

# Capa 3: Detalle completo (~500-1000 tokens)
oc --memory --get 20260501-143022-a1b2c3d4

# Crear observaciones
oc --remember "Nota general"
oc --remember -t bugfix "Fixed JWT expiration bug"
oc --remember -t decision "Usamos Redis para sesiones"
```

### Tipos de observación

| Tipo | Uso |
|------|-----|
| `note` | Notas generales (default) |
| `bugfix` | Bugs corregidos |
| `feature` | Features implementadas |
| `decision` | Decisiones técnicas |
| `config` | Cambios de configuración |

### Formato interno

```markdown
---
id: obs_20260501-143022-a1b2c3d4
date: 2026-05-01 14:30:22
project: mi-api
type: bugfix
summary: Fix JWT expiration bug
tokens_est: 200
---

Contenido completo...
```

---

## Modo Interactivo

Menú seleccionable con fzf. Requiere `fzf` instalado.

```bash
oc --interactive   # o oc -i
```

Navega con flechas, Enter para seleccionar. Solicita confirmación antes de ejecutar agentes que requieren input.

---

## Modo Wizard

Guía paso a paso con confirmación entre fases.

```bash
oc --wizard   # o oc -w
```

Opciones: analizar proyecto, planificar tarea, implementar feature, revisar código, auditoría de seguridad, DevOps.

---

## Workflows (Single-Pass)

Pipelines multi-agente que ejecutan **todas las fases en una sola sesión OpenCode**. El agente mantiene contexto completo entre fases — no hay timeout entre llamadas.

```bash
oc --workflow bug-hunt ~/proyecto              # 5 fases
oc --workflow new-project "mi-api"             # 4 fases
oc --workflow debug "descripción del error"    # 3 fases
oc --workflow document ~/proyecto              # 3 fases
oc --workflow feature "add OAuth2" ~/api       # 4 fases (descripción + path)
```

### Workflows disponibles

| Workflow | Fases | Cadena de agentes |
|----------|-------|-------------------|
| `bug-hunt` | 5 | architect → security-auditor → planner → builder → reviewer |
| `new-project` | 4 | architect → planner → builder → docs-writer |
| `debug` | 3 | oncall → builder → security-auditor |
| `document` | 3 | architect → docs-writer → reviewer |
| `feature` | 4 | architect → planner → builder → reviewer |

### Nota sobre `feature` workflow

Recibe dos argumentos: descripción del feature y path del proyecto:

```bash
oc --workflow feature "add OAuth2 login" ~/myapi
#                      ↑ descripción       ↑ path
```

### Cómo funciona (single-pass)

Cada workflow construye un único prompt con todas las fases y lo envía a OpenCode en una sola llamada. El modelo ejecuta las fases secuencialmente manteniendo el contexto completo:

```
opencode -p "Ejecuta el workflow completo para: $target

FASE 1 - @architect con project-map:
  Analiza el proyecto...

FASE 2 - @docs-writer:
  Genera documentación...

FASE 3 - @reviewer:
  Verifica..."
```

---

## Plugin de Seguridad

`safety-guard.js` bloquea comandos destructivos antes de ejecución. Normaliza whitespace antes de evaluar patrones para prevenir bypasses triviales.

Comandos bloqueados:
- `rm -rf` en rutas críticas (`/`, `~`, `/home`, `/etc`, `/usr`, `/var`, `/bin`)
- `mkfs` (formateo de filesystem)
- `dd if=` (escritura directa a disco)
- Fork bomb `:(){ :|:& };:`
- Escritura directa a dispositivos de bloque (`> /dev/sda`)
- Truncado de archivos críticos (`> /etc/passwd`, `> /etc/shadow`, etc.)

---

## Inicializar Proyecto

```bash
oc --init ~/mi-proyecto   # Crea .opencode/ con config base + git hook
```

Genera:
- `.opencode/opencode.json` — config que extiende global
- `.opencode/CLAUDE.md` — contexto del proyecto
- `.git/hooks/pre-commit` — revisión automática con `@reviewer`

---

## Git Hooks

```bash
# Instalar hooks globalmente
cp hooks/pre-commit ~/.config/opencode/hooks/
cp hooks/pre-push   ~/.config/opencode/hooks/
```

`pre-commit` ejecuta `@reviewer` con `precommit-review` antes de cada commit. Bloquea el commit si hay hallazgos críticos.

---

## Souls/Personas

Personas predefinidas para diferentes contextos en `souls/souls.md`:

- `senior-developer` — 15+ años, código limpio y probado
- `security-auditor` — CISSP/CEH, zero-trust mindset
- `devops-sre` — IaC, SLOs, blameless post-mortems
- `code-reviewer` — estándares exigentes

---

## Estructura

```
opencode-global-config/
├── oc                       # Script principal (v1.7)
├── agents/
│   ├── architect.md         # Read-only, tradeoffs declarations
│   ├── planner.md           # Success criteria, fases verificables
│   ├── builder.md           # Karpathy principles (4 reglas)
│   ├── reviewer.md
│   ├── security-auditor.md
│   ├── docs-writer.md
│   ├── devops.md
│   └── oncall.md            # Reversibility-weighted risk
├── skills/
│   ├── project-map/         # Análisis de estructura
│   ├── safe-implementation/ # Cambios pequeños y verificables
│   ├── test-first/          # Goal-Driven Execution
│   ├── precommit-review/    # Revisión de diff
│   ├── memory-retrieval/    # 3-layer progressive disclosure
│   └── docs-writer/         # Documentación técnica
├── plugins/
│   └── safety-guard.js      # Regex hardening, whitespace normalization
├── memory/
│   ├── INDEX.md             # Índice de observaciones
│   ├── ARCHITECTURE.md
│   ├── projects/            # Observaciones por proyecto
│   ├── decisions/
│   └── patterns/
├── profiles/                # 7 niveles de confianza
│   ├── deny.json
│   ├── plan.json
│   ├── review.json
│   ├── default.json
│   ├── auto.json
│   ├── trusted.json
│   └── devops.json
├── souls/
│   └── souls.md             # 4 personas predefinidas
├── hooks/
│   ├── pre-commit
│   └── pre-push
├── CLAUDE.md
├── AGENTS.md                # 4 principios Karpathy globales
├── README.md
├── INSTALL.md
├── CHANGELOG.md
└── LICENSE
```

---

## Inspiración y Fuentes

### Análisis de Arquitectura Claude Code
- [VILA-Lab/Dive-into-Claude-Code](https://github.com/VILA-Lab/Dive-into-Claude-Code) — Paper académico: "98.4% infrastructure, 1.6% AI"
- [Piebald-AI/claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts)

### Directrices Karpathy
- [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)

### Memory Systems
- [kunickiaj/codemem](https://github.com/kunickiaj/codemem)
- [swarmclawai/swarmvault](https://github.com/swarmclawai/swarmvault)

### Skills & Plugins
- [jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills)

---

## Changelog

### v1.7 (2026-05-01)

#### Fixes críticos en `oc` script
- **Eliminado `set -e`** del script — causaba exit silencioso cuando `search_memory` o `check_budget` retornaban 1 (no-encontrado)
- **Corregido `local` fuera de función** en bloques `--workflow`, `--type`, `--remember`, `--memory` del `case` — generaba error `bash: local: can only be used in a function`
- **Corregido workflow `feature`** — `feature_desc` se perdía porque `${3:-}` capturaba el flag `interactive` en lugar de la descripción; ahora dispatcher pasa 4 argumentos correctamente
- **Corregido `run_interactive`** — fzf parsing usaba `awk '{print $1}'` sobre ASCII art con `║` como primer token; reemplazado por lista limpia `"a  @architect..."` donde `awk` extrae la letra correctamente
- **Corregido `generate_obs_id`** — `head -c 12` truncaba a `YYYYMMDD-HH` generando colisiones; ahora usa timestamp completo + 4 bytes de `/dev/urandom`
- **Eliminado placeholder `<private>`** falso en cada observación creada

#### Mejoras funcionales
- **Perfiles funcionales** — `switch_profile` exporta `OPENCODE_PROFILE`; todos los `quick_*`, `run_agent` y workflows leen perfil activo via `_oc_run()` wrapper
- **`check_deps` simplificado** — solo verifica `opencode` al startup; `fzf` se verifica solo al usar `--interactive`
- **Workflows single-pass implementados** — cada workflow envía un prompt único con todas las fases; el agente mantiene contexto completo entre fases sin timeout
- **`--compact` honesto** — ya no imprime pipeline falso; resetea contador y advierte que el resumen manual es necesario para sesiones largas

#### Seguridad (`safety-guard.js`)
- **Reemplazado substring matching por regex** — normaliza whitespace antes de evaluar; `rm  -rf /` (espacios extra), `rm -r -f /` no pasan
- **Ampliados patrones bloqueados** — añadidos: escritura directa a discos (`> /dev/sda`), truncado de archivos críticos (`> /etc/passwd`, `/etc/shadow`, `/etc/sudoers`), `chmod` world-writable recursivo en paths de sistema

#### Documentación
- **Corregido "6 skills"** → 5 skills (el repo tiene 5 `SKILL.md`)
- **Eliminada tabla de "5-layer compaction"** — la compaction no está implementada en código; reemplazada por descripción honesta del contador de turns
- **Actualizado workflow `feature`** con sintaxis correcta de 2 argumentos
- **Eliminada referencia a `--interactive` en workflows** — el flag existe pero la documentación lo omitía inconsistentemente

### v1.6 (2026-05-01)
- Workflows automático single-pass (documentado, implementado en v1.7)
- 5 workflows sin intervención del usuario

### v1.5 (2026-05-01)
- Sistema de workflows con 5 pipelines pre-configurados
- Flag `--interactive` para confirmación entre fases

### v1.4 (2026-05-01)
- 3-layer memory retrieval (search/timeline/get)
- Observation format con auto-capture

### v1.3 (2026-05-01)
- 7 perfiles con Deny-First gradient
- Reversibility-weighted risk en @oncall
- Context budget tracking

### v1.2 (2026-05-01)
- Integración de 4 principios de Karpathy

### v1.1 (2026-05-01)
- Wizard, interactive menu, memory bank, souls, profiles, hooks, quick commands

### v1.0 (2026-05-01)
- Initial release — 8 agents, 5 skills, safety plugin, oc command

---

## Licencia

MIT License
