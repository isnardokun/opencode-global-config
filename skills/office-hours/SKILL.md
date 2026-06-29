---
name: office-hours
description: Reframe a product idea through six forcing questions before any code is written. Surface hidden capabilities, challenge premises, and produce a design doc. Adapted from garrytan/gstack for OpenCode.
---

# Office Hours

Reframe a product idea before implementation. The goal is to understand the problem deeply enough that the solution almost writes itself. Adapted from the YC Office Hours methodology for use inside OpenCode.

## When to invoke

- User has a new product idea and asks "is this worth building?"
- User wants to "brainstorm" or "think through" a concept that does not exist yet
- A design conversation is happening before any code is written
- Before invoking a plan or implementation workflow on a new feature

## Iron Law

**No implementation action.** No code, no scaffold, no project files, no plan files written to disk as a side effect. The only output is a design document rendered to the user.

## The six forcing questions

Ask them in order. Each is a STOP until the user answers concretely.

### 1. Demand reality

> "Who specifically has this problem? Give me a name, a role, a moment in their day. Not a market segment — a person."

If the answer is "everyone" or "developers in general", the problem is not yet specific enough. Push back.

### 2. Status quo

> "What do they do today, before this product exists? Walk me through it step by step. What's painful about that?"

The current workflow is the competitor. If the current workflow is "fine, mostly", the pain is not yet acute enough.

### 3. Desperate specificity

> "Tell me a specific moment in the last 30 days when you personally felt this pain. What were you doing? What broke? What did you do instead?"

Vivid detail = real pain. Generic description = hypothetical pain. Only the former is worth building for.

### 4. Narrowest wedge

> "If you could ship ONE thing tomorrow — the smallest possible piece that delivers the value you described — what is it? Not the vision, the wedge."

Force the user to pick. If they cannot pick, the product is several products in a trench coat.

### 5. Observation

> "How would you know, in 7 days, that this worked? What would you see, hear, count?"

Observable signal, not vanity metrics. "People like it" is not a metric. "10 people used it twice" is.

### 6. Future-fit

> "If this works and you keep building it for a year, what does it become? Does the wedge still matter, or does it become a feature inside something bigger?"

Surfacing the long arc now prevents building a wedge that paints you into a corner.

## Mode adaptation

- **Founder mode** — apply the hard questions, push back, force specificity.
- **Builder mode** — exploratory design thinking for side projects, hackathons, learning. Softer, more "yes-and", less "no, but".

Default to founder mode unless the user signals otherwise.

## Output: design doc

After the six questions have concrete answers, produce a design doc with these sections:

```
# <Product / feature name>

## Problem
<One paragraph: the specific person, the specific moment, the specific pain.>

## Status quo
<What they do today. Why it hurts.>

## Proposed wedge
<The smallest thing that delivers the value. What is in scope, what is explicitly out.>

## Observable signal
<How we will know in 7 days this worked.>

## Why now
<What changed in the world that makes this possible / necessary.>

## Open questions
<What we still do not know.>

## Recommendation
<Ship it / narrow further / kill it. With one-line reason.>
```

Render this to the user in the response. Do not write it to disk unless explicitly asked.

## Anti-patterns

- **Hypotheticals**: "If we could..." — push for real.
- **TAM rationalization**: "There are 10 million developers, even 1%..." — irrelevant at pre-wedge stage.
- **Vision-first**: Starting from "the full product is..." — invert: start from the wedge and see if it grows.
- **Premature scope**: Adding "and it also does X" before the wedge ships.

## When to refuse

If the user wants implementation despite the iron law, say:

> "Office Hours is design-only. Once the design doc is shaped, hand it to /plan-eng-review or /plan for the implementation plan. I will not start coding from a half-shaped idea."
