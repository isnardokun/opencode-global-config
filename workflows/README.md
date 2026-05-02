# OpenCode Workflows

Workflows encadenan agentes en un único prompt single-pass.
El agente mantiene contexto completo entre fases — sin timeout inter-fases.

## Uso

```bash
oc --workflow bug-hunt ~/proyecto
oc --workflow new-project "mi-api"
oc --workflow debug "fix error"
oc --workflow document ~/proyecto
oc --workflow feature "add auth" ~/proyecto
```

## Workflows Disponibles

| Workflow | Agentes (single-pass) |
|----------|----------------------|
| `bug-hunt` | architect → security-auditor → planner → builder → reviewer |
| `new-project` | architect → planner → builder → docs-writer |
| `debug` | oncall → builder → security-auditor |
| `document` | architect → docs-writer → reviewer |
| `feature` | architect → planner → builder → reviewer |

## Implementación

Los workflows se implementan en el script `oc` como prompts únicos.
No existe un formato JSON para workflows custom — todo el código está en `oc`.

Para agregar un workflow custom: edita la función `run_workflow()` en `oc`.
