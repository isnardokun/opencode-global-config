# Skill: design-md

Lint, diff, and suggest DESIGN.md files for visual consistency in coding agent projects.

## Workflow Integration

### Auto-detect in project-map

When `project-map` detects a UI project (React, Vue, Svelte, Next.js, etc.), it should:

1. Check if `DESIGN.md` exists in project root
2. If absent, suggest creating one with `oc design suggest`
3. If present, offer `oc design lint` to validate

### Trigger phrases
- "create design system"
- "visual identity"
- "design tokens"
- "DESIGN.md"
- "component library styling"

## Commands

### `oc design lint <file>`

Validate DESIGN.md structure, token references, and WCAG contrast.

```bash
npx @google/design.md lint DESIGN.md
```

Exit codes: `0` pass, `1` errors found.

### `oc design diff <before> <after>`

Compare two design files for token-level regressions.

```bash
npx @google/design.md diff DESIGN.md DESIGN-v2.md
```

### `oc design suggest`

Inspect project UI files (components, CSS, Tailwind config) and output a draft DESIGN.md.

```bash
# Detect framework and extract design tokens
# Output draft to stdout
```

### `oc design export <file> <format>`

Export tokens to Tailwind/DTCG format.

```bash
npx @google/design.md export --format json-tailwind DESIGN.md
npx @google/design.md export --format dtcg DESIGN.md
```

## Detection Logic

### UI project indicators

```
package.json contains:
- react, vue, svelte, next, nuxt, astro
- @chakra-ui, @mui/material, tailwindcss, styled-components
- component in name

File patterns:
- **/*.tsx, **/*.jsx (React/Vue components)
- tailwind.config.*, .tailwindrc*
- src/styles/, src/theme/, styles/
- components/, ui/, lib/ui/
```

## Token Extraction

### From CSS/Tailwind

Extract color values from:
- `tailwind.config.js` (theme.colors)
- CSS custom properties (--color-*)
- SCSS variables ($primary-color)

### From component files

Parse for inline styles and className patterns:
- `style={{ backgroundColor: ... }}`
- `className="bg-primary text-white"`

## Output Format

When suggesting DESIGN.md, output:

```
## Tokens Detectados

### Colors
- primary: #hex value from CSS/Tailwind
- secondary: ...
- neutral: ...

### Typography
- h1: detected from global styles or component defaults
- body: ...

## Recomendación

El proyecto tiene styling pero no DESIGN.md. Crear uno garantiza que el agente mantenga consistencia visual.

¿Crear DESIGN.md con los tokens detectados?

Opciones:
1. Crear DESIGN.md completo (recomendado)
2. Crear solo con colores básicos
3. No crear (usar valores hardcodeados)
```

## Lint Output Handling

If `lint` returns errors/warnings, present them clearly:

```
## Hallazgos de Diseño

❌ Error: broken-ref
   {colors.accent} no existe. Definiste: primary, secondary, neutral

⚠️ Warning: missing-primary
   No definiste color primary — el agente auto-generará uno

⚠️ Warning: contrast-ratio
   button-primary: textColor #ffffff on backgroundColor #1A1C1E = 15.42:1 ✓ AA

💡 Info: token-summary
   5 colors, 3 typography, 2 rounded, 2 spacing
```

## Integration with safe-implementation

When implementing UI changes:
1. Check if DESIGN.md exists
2. If yes, validate proposed colors/typography against tokens
3. If no, flag as risk ("no design system defined")
4. Suggest creating DESIGN.md if project has 5+ components with inline styles