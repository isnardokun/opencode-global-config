---
name: design-md
description: Lint, diff, and suggest DESIGN.md files for visual consistency in coding agent projects. Includes a "Design Philosophy" section (anti-AI-slop principles) adapted from anthropics/skills/frontend-design: ground in subject, typography carries personality, structure is information, avoid the 3 AI-defaults. Use when the user mentions design tokens, colors, spacing, typography, or wants to review generated UI for AI slop patterns.
license: MIT
compatibility: opencode
---

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

---

## Design Philosophy (anti-AI-slop) — adapted from `frontend-design`

The following principles are cherry-picked from `anthropics/skills/skills/frontend-design/SKILL.md` (8 KB manifesto, 2026-06-28). The original is a design-lead-at-a-small-studio philosophy. This summary extracts what is useful for the LLM when generating or reviewing UI code.

### Ground it in the subject

If the brief does not pin down what the product or subject is, **pin it yourself before designing**: name one concrete subject, its audience, and the page's single job, and state your choice. The subject's own world — its materials, instruments, artifacts, and vernacular — is where distinctive choices come from. Build with the brief's real content and subject matter throughout.

### Design principles

- **For web designs, the hero is a thesis.** Open with the most characteristic thing in the subject's world, in whatever form makes sense for it: a headline, an image, an animation, a live demo, an interactive moment. Be deliberate: a "big number + small label + supporting stats + gradient accent" is the template answer. Use it only if that's truly the best option.
- **Typography carries the personality of the page.** Pair display and body faces deliberately, not the same families you would reach for on any other project. Set a clear type scale with intentional weights, widths, and spacing. Make the type treatment itself a memorable part of the design.
- **Structure is information.** Numbered markers (01 / 02 / 03), eyebrows, dividers, labels — these should encode something true about the content, not decorate it. Use numbered markers only if the content actually is a sequence (a real process, a typed timeline where order carries information the reader needs).
- **Leverage motion deliberately.** Page-load sequences, scroll-triggered reveals, hover micro-interactions. An orchestrated moment usually lands harder than scattered effects. Sometimes less is more — extra animation contributes to the feeling that the design is AI-generated.
- **Match complexity to the vision.** Maximalist directions need elaborate execution; minimal directions need precision in spacing, type, and detail. Elegance is executing the chosen vision well.
- **Treat written content carefully.** Copy can make a design feel as templated as the design itself. Write from the end user's side of the screen. Name things by what people control and recognize, never by how the system is built. Use active voice as default.

### Restraint and self-critique

- **Spend your boldness in one place.** Let the signature element be the one memorable thing; keep everything around it quiet and disciplined. Cut any decoration that does not serve the brief.
- **Build to a quality floor without announcing it.** Responsive down to mobile, visible keyboard focus, reduced motion respected.
- **Critique your own work as you build.** Take screenshots if the environment supports it — a picture is worth 1000 tokens. Consider Chanel's advice: before leaving the house, take a look in the mirror and remove one accessory.

### The three AI-generated design defaults (avoid them as defaults)

For calibration: AI-generated design right now clusters around three looks:

1. **Warm cream background** (near `#F4F1EA`) with a high-contrast serif display and a terracotta accent
2. **Near-black background** with a single bright acid-green or vermilion accent
3. **Broadsheet-style layout** with hairline rules, zero border-radius, and dense newspaper-like columns

All three are legitimate for some briefs, but **they are defaults rather than choices, and they appear regardless of subject**. Where the brief pins down a visual direction, follow it exactly — the brief's own words always win, including when it asks for one of these looks. Where it leaves an axis free, don't spend that freedom on one of these defaults. Just like a human designer who's hired, there's often a careful balance between doing what you're good at and taking each project as a chance to experiment.

### Process: brainstorm, plan, critique, build, critique again

Work in two passes. First, brainstorm a short design plan: a compact token system with color, type, layout, and signature.

- **Color**: describe the palette as 4–6 named hex values
- **Type**: the typefaces for 2+ roles (a characterful display face used with restraint, a complementary body face, a utility face for captions or data if needed)
- **Layout**: a layout concept, using one-sentence prose descriptions and ASCII wireframes
- **Signature**: the single unique element this page will be remembered by

Then review the plan against the brief before building: **if any part reads like the generic default you would produce for any similar page rather than a choice made for this specific brief, revise that part** and say what you changed and why. Only after confirming the relative uniqueness of the design plan should you start to write the code, following the revised plan exactly and deriving every color and type decision from it.

### Provenance

Adapted from `anthropics/skills/skills/frontend-design/SKILL.md` (8 KB, cherry-pick 2026-06-28). The original is a standalone skill; in opencode-global-config it is integrated into `design-md` as a "Design Philosophy" section because (a) the LLM is the same agent in both cases, (b) anti-AI-slop principles are most useful when paired with the concrete lint/diff tooling that `design-md` already provides, and (c) creating a separate skill would just trigger the same agent to read both files.