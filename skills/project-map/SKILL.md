---
name: project-map
description: Analiza estructura, stack, entrypoints y comandos del proyecto. Genera docs/ con Docs-First structure.
license: MIT
compatibility: opencode
---

Skill para análisis de estructura de proyecto antes de modificar.

## Procedimiento

### 1. Detectar tipo de proyecto

```
Detectar en orden:
- package.json → Node.js/npm
- requirements.txt / pyproject.toml / setup.py → Python
- go.mod → Go
- Cargo.toml → Rust
- pom.xml / build.gradle → Java/Kotlin
- composer.json → PHP
- .NET (.csproj, .sln) → C#/.NET
- Dockerfile / docker-compose.yml → Docker-based
- terraform / .tf → Terraform
- Makefile → C/C++ o build genérico
```

### 2. Mapear estructura

```
tree -L 3 -I 'node_modules|.git|dist|build|.next' .
```

Identificar:
- Directorios de código fuente (src/, lib/, app/, internal/)
- Directorios de tests (test/, tests/, __tests__/, spec/)
- Directorios de config (config/, etc/, resources/)
- Archivos de documentación (docs/, README*, CHANGELOG*)
- Entry points (.gitignore, package.json bin/, __main__.py)

### 3. Detectar stack completo

Detectar herramientas del proyecto:
- **Runtime**: Node.js, Python, Go, Rust, Java, PHP
- **Framework**: Express, FastAPI, Rails, Django, Next.js, etc.
- **Build**: webpack, vite, esbuild, rollup, cargo, gradle
- **Database**: PostgreSQL, MySQL, MongoDB, Redis, SQLite
- **Cache**: Redis, Memcached, in-memory
- **API style**: REST, GraphQL, gRPC, WebSocket

### 4. Identificar comandos disponibles

```bash
# Detectar scripts de package.json
cat package.json | jq '.scripts' 2>/dev/null

# Detectar Makefile targets
grep -E "^[a-z-]+:" Makefile 2>/dev/null | head -20

# Detectar Docker configs
ls docker-compose*.yml 2>/dev/null
docker-compose config --services 2>/dev/null
```

Comandos esperados:
- `test` / `npm test` / `pytest` / `cargo test`
- `lint` / `eslint` / `ruff` / `clippy`
- `build` / `dev` / `start`
- `typecheck` / `mypy` / `tsc`

### 5. Generar docs/ si no existe

Si `docs/` no existe o está incompleto, crear estructura Docs-First:

```
docs/
├── PROJECT_CONTEXT.md    # Qué es, para quién, problema que resuelve
├── BUSINESS_LOGIC.md     # Reglas de negocio, dominios
├── DATA_STRUCTURE.md     # Modelos, schemas, DB
├── ARCHITECTURE.md       # Stack, componentes, flujos
├── DECISIONS.md          # Decisiones técnicas registradas
├── CHANGELOG.md          # Historial de cambios
├── CONVERSATION.md       # Resumen de conversaciones/decisiones
├── TASKS.md              # Tasks pendientes y estado
├── RISKS.md              # Riesgos identificados
└── ONBOARDING.md         # Guía para nuevos devs
```

Cada archivo: skeleton con header y secciones marcadas con `TBD:` donde no se tenga info.

### 6. Identificar riesgos

- Archivos grandes (>500 líneas) sin tests
- Dependencias deprecated o con vulnerabilidades conocidas
- Config hardcodeada (tokens, credenciales)
- Falta de documentación en APIs públicas
- Migration pending sin rollback plan

## Salida

```
## Stack Detectado
- Runtime: ...
- Framework: ...
- Build: ...
- Database: ...
- Cache: ...

## Estructura
[árbol de dirs relevantes]

## Entry Points
- main: ...
- cli: ...
- config: ...

## Comandos Disponibles
- test: ...
- lint: ...
- build: ...

## Riesgos Iniciales
- ...

## Docs/
¿docs/ existe? Sí/No
¿Docs-First completo? Sí/No
```

## Reglas

1. Si docs/ existe, leer lo que hay antes de preguntar
2. No inventar contenido — marcar TODO donde no haya info
3. En proyectos nuevos, crear docs/ antes de implementar
4. Mantener docs/ sincronizado con cambios reales
5. No sobre-escribir docs existentes con información no verificada