---
name: safe-implementation
description: Implementa cambios pequeños, verificables y reversibles. surgical changes, no overcomplication.
license: MIT
compatibility: opencode
---

Skill para implementación de cambios mínimos y verificables.

## Principio

**Minimum code that solves the problem. Nothing speculative.**

Si 200 líneas podrían ser 50, reescribe. Si 3 archivos podrían ser 1, simplifica.

## Procedimiento

### 1. Antes de editar — Declarar

Para cada cambio:
```
archivo: <path>
cambio: <qué se改变>
razón: <por qué esta solución y no otra>
```

No proceder si no se puede explicar el "por qué".

### 2. Clasificar tipo de cambio

| Tipo | Scope | Regla |
|------|-------|-------|
| **Fix** | 1 archivo, <20 líneas | Directo, sin feature |
| **Feature** | 1-3 archivos | Verificar necesidad real |
| **Refactor** | 1-5 archivos | Tests antes y después |
| **Config** | archivos de config | No romper backwards |
| **Migration** | DB/schema | Siempre reversible |

### 3. Implementar en pasos mínimos

```
1. [Cambio más pequeño que resuelve el problema]
2. [Verificar que no rompe nada]
3. [Si hay más que cambiar, siguiente paso]
```

**Nunca:** implementar todo de una vez sin verificar entre pasos.

### 4. Reglas de sintaxis

- Usar estilo existente del archivo (indentation, naming)
- No agregar comments excepto donde el código es oscuro
- No "mejorar" código adyacente que no está en scope
- Variables: snake_case en Python, camelCase en JS/TS, kebab-case en Shell

### 5. Después de editar

```
1. git diff — revisar solo los cambios necesarios
2. Ejecutar: test / lint / typecheck
3. Si falla: revertir y corregir
4. Si pasa: commit mínimo con mensaje claro
```

### 6. Si algo no está claro

- Preguntar antes de asumir
- Proponer 2-3 opciones con tradeoffs
- Nunca "emporary fix" — o es correcto o no se hace

## Cambios quirúrgicos

### Agregar código

```bash
# No: crear archivo completo con boilerplate
# Sí: agregar solo la función/clase que falta

# Verificar que no exista ya
grep -r "functionName" src/

# Agregar en el lugar correcto (no al final del archivo)
```

### Modificar código

```bash
# Antes: entender el contexto completo
# Durante: cambiar solo lo necesario
# Después: verificar que no hay side effects
```

### Eliminar código

Solo si:
- La funcionalidad ya no existe
- Fue reemplazada por mejor implementación
- No tiene tests que la cubran

Verificar que no hay referencias antes de eliminar:
```bash
grep -r "codeToDelete" src/ tests/ docs/
```

## Reversibilidad

Antes de cada cambio, preguntar:
- ¿Cómo se revierte esto?
- ¿Existe backup del estado anterior?
- ¿Los tests cubren el cambio?

Si no hay forma de revertir: no hacer el cambio.

## Señales de éxito

- Diff pequeño (<20 líneas para un fix)
- Tests pasan
- No hay "TODO" o "FIXME" en el diff
- Mensaje de commit describe el qué y el por qué

## Señales de alerta

- Más de 3 archivos en una iteración
- Diff >100 líneas sin justificación
- Commits tipo "WIP" o "more changes"
- Cambios sin tests en proyecto que tiene tests
- Código comentado en lugar de eliminado