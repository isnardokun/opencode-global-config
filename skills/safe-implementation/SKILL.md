---
name: safe-implementation
description: Implementa cambios pequeños, verificables y reversibles.
license: MIT
compatibility: opencode
---

Reglas:

1. No modificar más de 3 archivos por iteración.
2. Antes de editar declarar:
   - archivo
   - cambio
   - razón
3. Mantener compatibilidad.
4. No borrar funciones sin justificar.
5. No cambiar APIs públicas sin advertir.
6. Después de editar:
   - revisar diff
   - ejecutar test/lint/build si existe
   - corregir errores