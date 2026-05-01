---
name: test-first
description: Identifica y ejecuta pruebas antes y después de modificar código.
license: MIT
compatibility: opencode
---

Procedimiento:

1. Detectar framework de pruebas.
2. Buscar comandos:
   - npm test
   - pnpm test
   - yarn test
   - pytest
   - cargo test
   - go test ./...
3. Si no hay tests, proponer prueba manual mínima.
4. Ejecutar pruebas antes si aplica.
5. Ejecutar pruebas después.

Salida:
- Framework detectado
- Comando usado
- Resultado antes
- Resultado después
- Riesgos no cubiertos