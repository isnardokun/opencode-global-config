# OpenCode Global Configuration

Configuración global personalizada para OpenCode CLI con agentes especializados, sistema de memoria, perfiles y flujo de trabajo estructurado.

## Tabla de Contenidos

- [Descripción](#descripción)
- [Quick Start](#quick-start)
- [Comandos Rápidos](#comandos-rápidos)
- [Modo Interactivo](#modo-interactivo)
- [Modo Wizard](#modo-wizard)
- [Memory Bank](#memory-bank)
- [Souls/Personas](#soulspersonas)
- [Perfiles](#perfiles)
- [Git Hooks](#git-hooks)
- [Inicializar Proyecto](#inicializar-proyecto)
- [Estructura](#estructura)
- [Inspiración](#inspiración)

---

## Descripción

Este repositorio contiene una configuración avanzada para [OpenCode CLI](https://opencode.ai) inspirada en Claude Code y proyectos de código abierto.

### Características Principales

- **8 agentes especializados** con permisos y temperature optimizados
- **4 skills** para análisis y validación
- **1 plugin de seguridad** que bloquea comandos peligrosos
- **Sistema de Memory Bank** para persistencia entre sesiones
- **Souls/Personas** para diferentes contextos
- **3 perfiles** (work, research, devops)
- **Git Hooks** para revisión automática
- **Comandos rápidos** para acceso directo
- **Modo Wizard** guiado paso a paso
- **Menú interactivo** con fzf

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
oc build "nuevo feature"   # @builder + test-first
oc review                  # @reviewer + precommit-review

# Especializados
oc secure                  # @security-auditor
oc docs                    # @docs-writer
oc devops "dockerfile"     # @devops
oc oncall                  # @oncall

# Directos
oc "cualquier tarea"        # Envía directamente a OpenCode
```

### Alias como comandos separados

```bash
oc-analyze ~/proyecto      # Equivalente a oc analyze
oc-build "feature"         # Equivalente a oc build
oc-secure                  # Equivalente a oc secure
# etc.
```

---

## Modo Interactivo

Menú visual con fzf para seleccionar agentes y tareas:

```bash
oc --interactive
# o simplemente
oc -i
```

```
╔════════════════════════════════════════════════════════════╗
║              OpenCode Global Config - Menú                ║
╠════════════════════════════════════════════════════════════╣
║  [a]  @architect    - Analizar arquitectura y riesgos    ║
║  [p]  @planner      - Planificar tarea en fases          ║
║  [b]  @builder      - Implementar cambios                ║
║  [r]  @reviewer     - Revisar código                     ║
║  [s]  @security     - Auditoría de seguridad             ║
║  [d]  @docs         - Generar documentación              ║
║  [v]  @devops       - Tareas DevOps                       ║
║  [o]  @oncall       - Diagnosticar producción            ║
║  [w]  Wizard        - Modo guiado paso a paso            ║
║  [i]  Init          - Inicializar proyecto                ║
║  [m]  Memory        - Buscar en memoria                  ║
║  [t]  Memory+Task   - Recordar + nueva tarea             ║
║  [q]  Quit                                               ║
╚════════════════════════════════════════════════════════════╝
```

---

## Modo Wizard

Flujo guiado paso a paso donde cada fase requiere aprobación:

```bash
oc --wizard
# o
oc -w
```

El wizard pregunta en cada fase:
1. Tipo de tarea (analizar/planificar/implementar/revisar)
2. Descripción
3. Ejecuta el agente correspondiente
4. Pregunta si continuar a la siguiente fase
5. Repite hasta completar el flujo

---

## Memory Bank

Sistema de memoria persistente que sobrevive entre sesiones.

```bash
# Buscar en memoria
oc --memory "docker compose"
oc --memory "autenticación JWT"

# Recordar algo para después
oc --remember "El servidor de prod usa PostgreSQL 15"

# Recordar + inmediatamente trabajar en algo
oc -t "usuario quiere dark mode" "implementa theme toggle"
```

### Estructura del Memory Bank

```
~/.config/opencode/memory/
├── projects/           # Memoria específica por proyecto
├── patterns/           # Patrones detectados
├── decisions/          # Decisiones técnicas (ADR)
├── context/            # Contexto general
└── README.md
```

### Formato de entradas

```markdown
---
Fecha: 2026-05-01
Proyecto: mi-api
Tipo: decision
---

# Decisión: Usar Redis para caché de sesiones

## Razón
- Menor latencia que PostgreSQL
- TTL nativo
-集群 soporte

## Alternativas
- Memcached: menos features
- PostgreSQL: más simple pero más lento

## Decisión
Redis
```

---

## Souls/Personas

Cambia el "carácter" del asistente según la situación:

```bash
# Usa un soul específico
opencode -p "Usa el soul security-auditor. Revisa este código"
```

### Souls disponibles

| Soul | Descripción |
|------|-------------|
| `senior-developer` | 15+ años experiencia, código limpio |
| `security-auditor` | Ciberseguridad, CISSP, CEH |
| `devops-sre` | SRE, IaC, Kubernetes, monitoreo |
| `code-reviewer` | Revisor estricto con checklist |
| `tech-lead` | Liderazgo técnico, mentoring |

### Personalizar Souls

Edita `souls/souls.md` para crear o modificar personalidades:

```yaml
---
name: mi-custom-persona
description: Descripción
system: |
  Tu sistema de prompts aquí...
---
```

---

## Perfiles

Cambia configuración según el contexto:

```bash
# Cambiar perfil
oc --profile work      # Productivo (temp 0.1, máx 3 files)
oc --profile research  # Investigación (temp 0.3, máx 10 files)
oc --profile devops    # DevOps (security required)

# Listar perfiles
oc --list-profiles
```

### Perfiles disponibles

| Perfil | Temp | Max Files | Tests | Security Review |
|--------|------|-----------|-------|-----------------|
| work | 0.1 | 3 | Required | Optional |
| research | 0.3 | 10 | Optional | No |
| devops | 0.05 | 5 | Required | Required |

### Crear perfil personalizado

```json
{
  "name": "mi-perfil",
  "description": "Descripción",
  "model": "minimax-coding-plan/MiniMax-M2.7",
  "temperature": 0.15,
  "agents": {
    "default": ["architect", "planner", "builder", "reviewer"]
  },
  "rules": {
    "maxFilesPerIteration": 5,
    "allowEnvEdit": false,
    "requireTests": true
  }
}
```

Guardar en `~/.config/opencode/profiles/mi-perfil.json`

---

## Git Hooks

Integración automática con git para revisar código antes de commit/push.

### Pre-commit Hook

Se ejecuta antes de cada commit:

```bash
oc --init ~/proyecto
# Esto configura .git/hooks/pre-commit automáticamente
```

El hook ejecuta `@reviewer` con `precommit-review` para:
- Verificar sintaxis
- Detectar errores comunes
- Asegurar tests pasan
- Revisar estilos

### Pre-push Hook

Se ejecuta antes de hacer push:

```bash
cp ~/.config/opencode/hooks/pre-push ~/.git/hooks/
chmod +x ~/.git/hooks/pre-push
```

El hook ejecuta `@security-auditor` para:
- Detectar secretos hardcodeados
- Verificar credenciales
- Revisar configuración insegura

---

## Inicializar Proyecto

Crea estructura `.opencode/` local para un proyecto específico:

```bash
oc --init ~/mi-proyecto
# o
oc init
```

Esto crea:

```
mi-proyecto/.opencode/
├── opencode.json      # Config que hereda de ~/.config/opencode/
├── CLAUDE.md          # Documentación del proyecto
├── agents/            # Agentes específicos del proyecto (opcional)
├── skills/            # Skills específicas del proyecto (opcional)
└── mcp/               # MCP servers locales (opcional)

mi-proyecto/.git/hooks/
└── pre-commit         # Hook de revisión automática
```

### Configuración por proyecto

El `opencode.json` local hereda del global pero puede sobrescribir:

```json
{
  "extends": "~/.config/opencode/opencode.json",
  "project": {
    "name": "mi-proyecto",
    "stack": ["Python", "FastAPI", "PostgreSQL"],
    "entrypoints": ["src/main.py"]
  }
}
```

---

## Estructura

```
opencode-global-config/
├── oc                      # Script principal
├── agents/
│   ├── architect.md         # Agente arquitecto
│   ├── planner.md          # Agente planificador
│   ├── builder.md          # Agente implementador
│   ├── reviewer.md         # Agente revisor
│   ├── security-auditor.md
│   ├── docs-writer.md
│   ├── devops.md
│   └── oncall.md
├── skills/
│   ├── project-map/
│   ├── safe-implementation/
│   ├── test-first/
│   └── precommit-review/
├── plugins/
│   └── safety-guard.js
├── memory/                  # Sistema de memoria
│   ├── README.md
│   ├── projects/
│   ├── patterns/
│   ├── decisions/
│   └── context/
├── profiles/               # Perfiles de configuración
│   ├── work.json
│   ├── research.json
│   └── devops.json
├── souls/                  # Personas/characters
│   └── souls.md
├── prompts/                # Templates de prompts
├── hooks/                  # Git hooks
│   ├── pre-commit
│   └── pre-push
├── mcp/                    # MCP server configs
├── README.md
├── INSTALL.md
├── CHANGELOG.md
└── LICENSE
```

---

## Inspiración y Fuentes

Esta configuración fue inspirada y mejorada con ideas de:

### Claude Code Leaked/Reverse Engineered
- [AnukarOP/claude-code-leaked](https://github.com/AnukarOP/claude-code-leaked) - Full source reconstruction
- [nblintao/awesome-claude-code-postleak-insights](https://github.com/nblintao/awesome-claude-code-postleak-insights) - High-signal analyses
- [Piebald-AI/claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts) - 9806 stars - System prompts completos

### OpenCode Enhancements
- [joelhooks/opencode-config](https://github.com/joelhooks/opencode-config) - 350 stars - Personal config
- [Microck/opencode-studio](https://github.com/Microck/opencode-studio) - 324 stars - Web UI
- [sdwolf4103/opencode-agenthub](https://github.com/sdwolf4103/opencode-agenthub) - Agent orchestration
- [pyramidheadshark/opencode-scaffold](https://github.com/pyramidheadshark/opencode-scaffold) - Bootstrap con memory-bank, MCP, hooks
- [zhylq/yuan-skills](https://github.com/zhylq/yuan-skills) - Multi-platform skills

### Memory & Persistence
- [kunickiaj/codemem](https://github.com/kunickiaj/codemem) - Persistent memory para OpenCode
- [dr-code/tessera](https://github.com/dr-code/tessera) - MCP server para memory
- [swarmclawai/swarmvault](https://github.com/swarmclawai/swarmvault) - RAG knowledge base (295 stars)

### Skills & Plugins Marketplace
- [jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) - 2077 stars - 423 plugins, 2849 skills
- [daymade/claude-code-skills](https://github.com/daymade/claude-code-skills) - 965 stars - Marketplace

### CLI Enhancements
- [junhoyeo/tokscale](https://github.com/junhoyeo/tokscale) - 2442 stars - Token usage tracking
- [LocalKinAI/kin-code](https://github.com/LocalKinAI/kin-code) - Soul files, MCP, sub-agents

### Alternativas Claude Code
- [ducan-ne/opencoder](https://github.com/ducan-ne/opencoder) - 376 stars - Claude Code alternative

---

## Licencia

MIT License - ver [LICENSE](LICENSE)

---

## Changelog

Ver [CHANGELOG.md](CHANGELOG.md) para historial completo de cambios.

### v1.1.0 (2026-05-01)
- Agregado: Modo wizard interactivo
- Agregado: Menú con fzf
- Agregado: Sistema de Memory Bank
- Agregado: Souls/Personas
- Agregado: 3 perfiles configurables
- Agregado: Git hooks (pre-commit, pre-push)
- Agregado: Comandos rápidos (oc-analyze, oc-plan, etc)
- Agregado: Sistema oc init para proyectos