# OpenCode Global Configuration

Configuración global personalizada para OpenCode CLI con agentes especializados para DevOps, seguridad y desarrollo profesional.

## Tabla de Contenidos

- [Descripción](#descripción)
- [Agentes](#agentes)
- [Skills](#skills)
- [Plugin de Seguridad](#plugin-de-seguridad)
- [Comando Global `oc`](#comando-global-oc)
- [Flujo de Trabajo](#flujo-de-trabajo)
- [Instalación](#instalación)
- [Uso](#uso)

---

## Descripción

Este repositorio contiene una configuración global para [OpenCode CLI](https://opencode.ai) que incluye:

- **8 agentes especializados** con permisos y temperature ajustados
- **4 skills** para análisis y validación
- **1 plugin de seguridad** que bloquea comandos peligrosos
- **1 comando global** `oc` para acceso rápido

Diseñado para desarrolladores y equipos DevOps que buscan un flujo de trabajo estructurado, seguro y verificable.

---

## Agentes

### Agentes Principales (Flujo de Desarrollo)

| Agente | Descripción | Permisos |
|--------|-------------|----------|
| `@architect` | Analiza arquitectura, stack y riesgos | edit: deny, bash: deny |
| `@planner` | Divide tareas en fases verificables | edit: deny, bash: deny |
| `@builder` | Implementa cambios controlados | edit: allow, bash: ask |
| `@reviewer` | Revisa bugs, seguridad y estilo | edit: deny, bash: deny |

### Agentes Especializados

| Agente | Descripción |
|--------|-------------|
| `@security-auditor` | Busca vulnerabilidades, credenciales expuestas, configuraciones inseguras |
| `@docs-writer` | Genera y mantiene documentación técnica |
| `@devops` | Docker, Kubernetes, CI/CD, Terraform, monitoreo |
| `@oncall` | Diagnostica y resuelve problemas de producción |

### Configuración de Agentes

```yaml
temperature: 0.1-0.2  # Respuestas enfocadas, baja creatividad
model: minimax-coding-plan/MiniMax-M2.7
mode: subagent o primary
```

### Reglas de Seguridad por Defecto

- Máximo 3 archivos por iteración
- No modificar `.env` salvo instrucción explícita
- No exponer secretos
- Ejecutar tests/lint/build después de editar
- Revisar diff antes de confirmar cambios

---

## Skills

Skills son módulos de conocimiento que los agentes pueden cargar para tareas específicas:

| Skill | Propósito |
|-------|-----------|
| `project-map` | Analiza estructura, stack y entrypoints |
| `safe-implementation` | Implementación de cambios pequeños y reversibles |
| `test-first` | Ejecución de pruebas antes y después |
| `precommit-review` | Auditoría final antes de commit |

---

## Plugin de Seguridad

`plugins/safety-guard.js` bloquea comandos peligrosos:

- `rm -rf /`
- `rm -rf *`
- `sudo rm -rf`
- `mkfs`
- `dd if=`
- `chmod -R 777 /`
- `chown -R`
- Fork bombs

---

## Comando Global `oc`

Ubicación: `~/.local/bin/oc`

```bash
# Con tarea
oc "analiza este proyecto"

# Sin tarea (interactivo)
oc
```

El comando `oc` ejecuta OpenCode con el flujo obligatorio:
1. `@architect` + `project-map`
2. `@planner`
3. `@builder` + `safe-implementation` + `test-first`
4. `@reviewer` + `precommit-review`
5. `@builder` corrige bloqueantes

---

## Flujo de Trabajo

```
┌─────────────────────────────────────────────────────────┐
│                    FLUJO PRINCIPAL                       │
├─────────────────────────────────────────────────────────┤
│  @architect ──► @planner ──► @builder ──► @reviewer     │
│     │             │            │            │            │
│  Diagnóstico   Fases       Implementa    Audita         │
│  Stack         Criterios   Tests         Cambios        │
│  Riesgos       Riesgos     Lint/Build    Aprueba/No     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                 FLUJO ESPECIALIZADO                      │
├─────────────────────────────────────────────────────────┤
│  @security-auditor ──► @docs-writer ──► @devops         │
│         │                    │              │           │
│   Vulnerabilidades      Documentación    CI/CD, K8s     │
│   Credenciales          API, README      Terraform      │
│   Config                                                          │
│                    ──► @oncall                              │
│                         │                                  │
│                   Producción                             │
│                   Logs, Mitigación                        │
└─────────────────────────────────────────────────────────┘
```

---

## Instalación

### Requisitos

- OpenCode CLI instalado
- Git
- Linux/macOS

### Pasos

```bash
# 1. Clonar repositorio
git clone https://github.com/isnardokun/opencode-global-config.git /tmp/opencode-config

# 2. Copiar configuración a ~/.config/opencode
cp -r /tmp/opencode-config/* ~/.config/opencode/

# 3. Instalar comando oc
mkdir -p ~/.local/bin
cp /tmp/opencode-config/oc ~/.local/bin/
chmod +x ~/.local/bin/oc

# 4. Agregar al PATH (si no existe)
grep -q '~/.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Verificar

```bash
command -v oc
find ~/.config/opencode -maxdepth 3 -type f | sort
```

---

## Uso

### Ejemplos Rápidos

```bash
# Analizar un proyecto nuevo
oc "@architect analiza /ruta/proyecto"

# Planificar una tarea compleja
oc "@planner divide 'migrar base de datos a PostgreSQL'"

# Implementar cambios
oc "@builder crea API REST con FastAPI"

# Revisión de seguridad
oc "@security-auditor revisa este código"

# Documentación
oc "@docs-writer genera README para este proyecto"

# DevOps
oc "@devops crea dockerfile y docker-compose"

# Producción
oc "@oncall hay errores 500 en producción"
```

### Para Desarrolladores

```bash
# Análisis inicial del proyecto
oc "@architect" + project-map

# Antes de implementar
oc "@planner"

# Durante implementación
oc "@builder" + safe-implementation + test-first

# Antes de commit
oc "@reviewer" + precommit-review
```

---

## Estructura de Archivos

```
opencode-global-config/
├── agents/
│   ├── architect.md        # Agente arquitecto
│   ├── planner.md         # Agente planificador
│   ├── builder.md         # Agente implementador
│   ├── reviewer.md        # Agente revisor
│   ├── security-auditor.md
│   ├── docs-writer.md
│   ├── devops.md
│   └── oncall.md
├── skills/
│   ├── project-map/SKILL.md
│   ├── safe-implementation/SKILL.md
│   ├── test-first/SKILL.md
│   └── precommit-review/SKILL.md
├── plugins/
│   └── safety-guard.js    # Plugin seguridad
├── logs/                   # Directorio para logs
├── oc                      # Comando global
├── opencode.json          # Configuración
├── AGENTS.md              # Reglas globales
├── README.md
├── INSTALL.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

---

## Comparación: Custom vs Built-in Agents

| Aspecto | Custom Agents | Built-in Agents |
|---------|--------------|-----------------|
| Temperature | 0.1-0.2 (enfoque) | No explícito |
| Protección .env | Regla explícita | No tiene |
| Límite archivos | máx 3/iteración | Sin límite |
| Verificación | tests obligatorios | Opcional |
| Pre-commit review | Checklist completo | No tiene |
| DevOps especializado | Sí (@devops, @oncall) | No |

**Veredicto:** Los agentes custom son significativamente más seguros y estructurados para trabajo DevOps.

---

## Licencia

MIT License - ver [LICENSE](LICENSE)

---

## Changelog

Ver [CHANGELOG.md](CHANGELOG.md) para historial de cambios.

---

## Contribuir

1. Fork del repositorio
2. Crear branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request