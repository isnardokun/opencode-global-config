---
description: Generate or update technical documentation for the current project
---

Use @docs-writer with docs-writer skill.

Generate or update documentation for the current project.

Check what documentation already exists, then create or update:

1. **README.md** — description, stack, installation, usage, examples, structure
2. **ARCHITECTURE.md** — component diagram, data flow, technical decisions
3. **API.md** — if the project exposes endpoints: routes, methods, request/response formats
4. **DEPLOY.md** — if Docker/CI/CD is detected: environment variables, deployment commands

Rules:
- Content must reflect actual code, not boilerplate
- Include working command examples
- Do not invent features that don't exist
- Match existing documentation style if present

Report: files created or updated, sections that need human input.
