---
name: test-first
description: Identifica y ejecuta pruebas antes y después de modificar código.
license: MIT
compatibility: opencode
---

Skill para Goal-Driven Execution - pruebas como verificación de éxito.

## Principio

LLMs son excepcionalmente buenos haciendo loop hasta cumplir objetivos específicos.
**No digas qué hacer, dale criterios de éxito y observa.**

## Procedimiento

### 1. Detectar framework de pruebas

Detectar qué existe:
- npm test / pnpm test / yarn test
- pytest / pytest -v
- cargo test
- go test ./...
- jest / vitest / mocha
- phpunit / php artisan test
- RSpec / minitest

### 2. Transformar tarea a objetivo verificable

| En vez de... | Usar... |
|--------------|---------|
| "Add validation" | "Tests para invalid inputs pasan" |
| "Fix the bug" | "Test que reproduce el bug pasa" |
| "Refactor X" | "Tests pasan antes y después" |
| "Add feature" | "Feature tests pasan" |

### 3. Plan de verificación con verificación explícita

Para cada paso:
```
1. [Acción] → verify: [cómo se comprueba que funcionó]
2. [Acción] → verify: [cómo se comprueba que funcionó]
```

### 4. Ejecutar pruebas antes (baseline)

- Guardar resultado
- Si fallan antes de cambios, reportar

### 5. Ejecutar pruebas después

- Comparar con baseline
- Si mejoran, éxito
- Si empeoran, revertir y corregir

## Salida

- Framework detectado
- Comando usado
- Resultado antes (baseline)
- Resultado después
- Criterios de éxito verificados: Sí/No
- Riesgos no cubiertos

## Reglas

1. No implementar sin tests si el proyecto ya tiene tests.
2. Si no hay tests, crear prueba manual mínima primero.
3. El test debe poder ejecutarse solo, sin intervención manual.
4. Success criteria deben ser objetivos, no subjetivos.

## Señales de éxito

- Tests pasan consistentemente
- Coverage no baja
- No hay tests commented out
- Errores capturados antes de deploy