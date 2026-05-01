# OpenCode Workflows

Sistema de workflows que encadenan agentes en secuencia para tareas completas.

## Workflows Disponibles

### 1. Bug Hunt Pipeline
**Comando:** `oc --workflow bug-hunt ~/proyecto`
**Fases:** 5
**Agentes:** @architect → @security-auditor → @planner → @builder → @reviewer

**Uso:**
- Encontrar y corregir bugs
- Análisis de vulnerabilidades
- Planeación de fixes
- Implementación controlada
- Verificación final

### 2. New Project Setup
**Comando:** `oc --workflow new-project "mi-proyecto"`
**Fases:** 4
**Agentes:** @architect → @planner → @builder → @docs-writer

**Uso:**
- Inicializar nuevos proyectos
- Definir estructura
- Scaffold inicial
- Documentación automática

### 3. Production Debug
**Comando:** `oc --workflow debug "fix error 500"`
**Fases:** 3
**Agentes:** @oncall → @builder → @security-auditor

**Uso:**
- Diagnosticar problemas en producción
- Implementar hotfixes
- Verificar seguridad post-fix

### 4. Codebase Documentation
**Comando:** `oc --workflow document ~/proyecto`
**Fases:** 3
**Agentes:** @architect → @docs-writer → @reviewer

**Uso:**
- Generar README.md
- Crear ARCHITECTURE.md
- Documentar APIs
- Verificar accuracy de docs

### 5. Feature Development
**Comando:** `oc --workflow feature "add auth" ~/proyecto`
**Fases:** 4
**Agentes:** @architect → @planner → @builder → @reviewer

**Uso:**
- Desarrollo estructurado de features
- Análisis de impacto
- Planificación
- Implementación con tests
- Revisión final

## Modo Interactivo

Agregar `--interactive` para pedir confirmación entre fases:

```bash
oc --workflow bug-hunt ~/proyecto --interactive
```

## Crear Workflow Custom

Crear archivo en `~/.config/opencode/workflows/<nombre>.json`:

```json
{
  "name": "mi-workflow",
  "description": "Descripción del workflow",
  "phases": [
    {
      "name": "Phase 1",
      "agent": "architect",
      "skill": "project-map",
      "prompt": "Analiza el proyecto..."
    },
    {
      "name": "Phase 2",
      "agent": "planner",
      "prompt": "Planifica..."
    }
  ]
}
```

## Future Enhancements

- Workflow registry en `~/.config/opencode/workflows/`
- `oc --workflow install <nombre>` para instalar workflows compartidos
- Workflows específicos por stack (Node, Python, Go, etc.)