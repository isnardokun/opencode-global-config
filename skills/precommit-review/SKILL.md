---
name: precommit-review
description: Auditoría final antes de commit o entrega.
license: MIT
compatibility: opencode
---

Checklist:

- diff completo
- sintaxis
- imports
- tipado
- variables indefinidas
- manejo de errores
- seguridad básica
- secretos expuestos
- pruebas faltantes
- documentación mínima

Salida:
1. Resumen de cambios
2. Hallazgos críticos
3. Hallazgos medios
4. Pruebas ejecutadas
5. Recomendación final: aprobar / corregir