---
name: ai-coding-rules
description: Fundamentos de AI coding — smart zone, attention budget, sycophancy, non-determinism, hallucination.
license: MIT
compatibility: opencode
---

Skill para entender y optimizar el comportamiento del modelo durante sesiones de coding.

## Conceptos clave

### Smart Zone vs Dumb Zone

**Sesión nueva = Smart zone** (turns 0-20):
- Agudo, enfocado, buena memoria
- Atención alta, few hallucinations
- Priorizar trabajo complejo aquí

**Sesión >20 turns ≈ Dumb zone**:
- Olvidadizo, errores aumenta
- Más hallucinations de fidelidad
- Attention degradation: cada token tiene menos señal

**Regla:** No empujar a través de dumb zone. Si el agente empieza a cometer errores, hacer `oc --compact` o clear.

### Attention Budget

Cada token tiene presupuesto de atención finito. Contexto crece, signal por token baja.

**En la práctica:**
- Archivos críticos (schemas, decisiones) → poner near end del contexto
- Docs grandes → NO prepender todo, usar punteros o skills
- Información load-bearing → asegurar que esté visible al final

**Fix de attention degradation:**
1. Compactar sesión (`oc --compact`)
2. Guardar contexto crítico en docs/ (persiste cross-session)
3. Reiniciar sesión con artifact como punto de partida

### Sycophancy

El modelo tiende a acordar con inputs confiados aunque estén equivocados.

**Síntomas:**
- Cede ante pushback sin razón técnica
- Alaba planes rotos porque el usuario suena confiado
- Review sesgado (positivo si suena como usuario, negativo si suena como otro)

**Diagnóstico:** ¿El modelo habría dicho esto sin tu tono/señal?

**Fix:**
- Escribir prompts neutrales: "revisa este código" no "es buen código?"
- Ocultar preferencias del usuario
- Preguntar por qué antes de asumir

### Non-determinism

Mismo prompt ≠ mismo output. Output varía entre ejecuciones sin cambio en código.

- No es "el modelo empeoró" — es distribución normal
- Malos días son random, no regresión
- Regenerar o reformular es válido

**Regla:** Si el resultado parece peor que ayer, intentar de nuevo antes de buscar causas.

### Hallucination — Dos tipos

**1. Factual (parametrics):**
- Inventa facts (API que no existe, versión wrong)
- Causa: conocimiento outdated o falta de docs en contexto
- Fix: cargar docs正确的 en contexto

**2. Fidelity (attention degradation):**
- Se desvía del contexto cargado (ignora schema, olvida decisiones)
- Causa: sesión muy larga, context overload
- Fix: clear o compactar

**Diagnóstico:**
- "¿Me inventó algo?" → cargar docs en contexto
- "¿Dejó de leer los docs?" → sesión larga, compactar

### Compaction

Resumir historia de sesión en prompt fresco. Lossy pero necesario.

```bash
oc --compact  # Resume session + reset turn counter
```

**Cuándo usar:**
- Antes de continuar sesión >20 turns
- Cuando agente empieza a cometer errores
- Antes de trabajo complejo en dumb zone

### Handoff

Transferir contexto de una sesión a otra (no es clear, es carry).

**Para sesiones largas:**
1. Escribir handoff artifact (resumen de decisiones, files, constraints)
2. Clear sesión
3. Nueva sesión empieza con artifact como contexto

### Loop Detection

El agente puede stuck en patrones repetitivos.

**Señales:**
- Mismo tool call 3+ veces
- Alternating pattern (A, B, A, B)
- Sin progreso entre iterations

**Regla:** `oc --compact` rompe el loop reseteando contexto.

## Reglas de usage

1. **Sesión nueva = trabajo complejo**: hacer lo más difícil primero
2. **>20 turns**: verificar si compactar ayuda
3. **Prompts neutrales**: evitar sycophancy en reviews
4. **Docs load-bearing**: guardar decisiones críticas en docs/ (persiste)
5. **Schema/API en contexto**: siempre cargar docs directas, no asumir

## Integración con skills

- `project-map`: carga docs/ al inicio
- `safe-implementation`: mínimo change, verifica después
- `test-first`: criterios objetivos verificables
- `grilling`: cuestiona antes de implementar