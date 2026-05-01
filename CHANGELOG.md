# Changelog

Todos los cambios notables de este proyecto se documentarán en este archivo.

## [1.1.0] - 2026-05-01

### Agregado

#### Sistema de Memory Bank
- Persistencia de contexto entre sesiones
- Búsqueda por contenido
-记忆分类 (projects, patterns, decisions, context)

#### Souls/Personas
- Sistema de personalidades intercambiables
- 5 souls predefinidos: senior-developer, security-auditor, devops-sre, code-reviewer, tech-lead
- Personalizable via `souls/souls.md`

#### Perfiles de Configuración
- 3 perfiles: work, research, devops
- Temperature configurable
- Límite de archivos por iteración
- Reglas de seguridad customizables

#### Git Hooks
- `pre-commit`: Ejecuta @reviewer + precommit-review
- `pre-push`: Ejecuta @security-auditor
- Automatización via `oc --init`

#### Comandos Rápidos
- `oc-analyze`: @architect + project-map
- `oc-plan`: @planner
- `oc-build`: @builder + test-first
- `oc-review`: @reviewer + precommit-review
- `oc-secure`: @security-auditor
- `oc-docs`: @docs-writer
- `oc-devops`: @devops
- `oc-oncall`: @oncall

#### Modo Wizard
- Flujo guiado paso a paso
- Aprobación entre fases
- 6 flujos predefinidos

#### Menú Interactivo
- Menú visual con fzf
- 14 opciones de agentes/tareas
- Integración con Memory Bank

### Modificado

#### Script oc mejorado
- Soporte para múltiples flags
--help dinámico
- Errores con colores
- Verificación de dependencias

## [1.0.0] - 2026-05-01

### Agregado

- 8 agentes custom: architect, planner, builder, reviewer, security-auditor, docs-writer, devops, oncall
- 4 skills: project-map, safe-implementation, test-first, precommit-review
- Plugin: safety-guard.js (bloquea comandos peligrosos)
- Comando global: oc
- opencode.json con configuración
- AGENTS.md con reglas globales
- Documentación completa en español