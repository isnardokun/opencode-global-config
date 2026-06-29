---
name: skill-creator
description: Create, edit, and improve skills for opencode-global-config. Use when a user wants to author a new skill from scratch, modify an existing skill, run evals to test a skill, or optimize a skill's description for better triggering accuracy. Adapted from anthropics/skills for OpenCode (no Claude-CLI subagents, no browser eval-viewer).
---

# Skill Creator

A skill for creating new skills and iteratively improving them. Adapted from `anthropics/skills/skills/skill-creator/SKILL.md` (2026-06-28). Workflow preserved; tooling replaced with opencode-native equivalents.

## What this skill replaces

The original `skill-creator` (Anthropic) drives a full eval-loop with browser-based reviewer, parallel subagent runs, and `claude -p` for description optimization. **None of that is available in opencode-global-config.** This adapted version preserves the methodology and the JSON schemas, but uses the existing opencode machinery:

| Original (Anthropic) | Adapted (opencode-global-config) |
|---|---|
| Subagent runs (parallel) | `occo ask <prompt>` or `occo --workflow <name>` (sequential) |
| `claude -p` for description optimization | Manual iteration by user + `@reviewer` agent |
| Browser eval-viewer | Text-based output review in chat |
| `agents/grader.md`, `agents/comparator.md` | `@reviewer` agent + custom assertions in `validate.sh` |
| `--skill-name` flag to aggregate_benchmark | Same (script is portable) |
| `package_skill.py` | Same (script is portable) |

## The core loop

```
1. Capture intent          → ask the user what they want
2. Interview & research    → clarify edge cases, formats, deps
3. Write the SKILL.md      → follow "Anatomy of a Skill" below
4. Create 2-3 test cases   → save to evals/evals.json
5. Run with @builder       → use the skill in a real prompt
6. Grade assertions        → run scripts/aggregate_benchmark.py
7. User reviews outputs    → qualitative pass / fail
8. Iterate                 → improve the skill, go to step 5
9. Optimize description    → see "Description Optimization" below
10. (Optional) Package     → run scripts/package_skill.py <path>
```

The order is flexible. If the user already has a draft, jump to step 5. If the user just wants to vibe, skip the grading and rely on qualitative feedback.

---

## Step 1: Capture intent

Start by understanding the user's intent. The current conversation might already contain a workflow the user wants to capture (e.g., they say "turn this into a skill"). If so, extract answers from the conversation history first — the tools used, the sequence of steps, corrections the user made, input/output formats observed. The user may need to fill the gaps, and should confirm before proceeding.

1. What should this skill enable the LLM to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, design) often don't. Suggest the appropriate default, but let the user decide.

## Step 2: Interview & research

Proactively ask about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test cases until these are ironed out.

## Step 3: Write the SKILL.md

Fill in these components:

- **name**: Skill identifier (lowercase, hyphens, no spaces). This is also the directory name.
- **description**: When to trigger, what it does. This is the primary triggering mechanism — include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body.
- **body**: The actual instructions.

### Critical: frontmatter for opencode

opencode strips the YAML frontmatter to only `name` + `description`. Everything else is decorative. **Do not rely on `allowed-tools`, `triggers`, `hooks`, `model`, `version`, etc. — they will be silently dropped.**

```yaml
---
name: my-skill
description: One-line description that includes what + when. Make it "pushy" — describe scenarios that should trigger, not just the abstract capability.
---
```

### Anatomy of a skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled resources (optional)
    ├── scripts/    — executable code for deterministic tasks
    ├── references/ — docs loaded into context as needed
    └── assets/     — files used in output (templates, icons, fonts)
```

### Progressive disclosure

Three levels of loading:

1. **Metadata** (name + description) — always in context (~100 words)
2. **SKILL.md body** — in context when skill triggers (<500 lines ideal)
3. **Bundled resources** — loaded as needed (unlimited)

**Keep SKILL.md under 500 lines.** If approaching the limit, add hierarchy: split into `SKILL.md` (workflow + selection) + `references/<topic>.md` for details. The skill should reference the right file at the right time.

### Writing style

Prefer imperative form. Explain **why** things matter instead of using rigid MUSTs. Today's LLMs are smart — give them a good harness and they can make good judgment calls. If you find yourself writing "ALWAYS" or "NEVER" in all caps, that's a yellow flag — reframe and explain the reasoning.

### Examples pattern

```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Principle of lack of surprise

Skills must not contain malware, exploit code, or content that could compromise system security. A skill's contents should not surprise the user in their intent if described. Roleplay / personas are OK.

---

## Step 4: Test cases

After writing the skill draft, come up with 2-3 realistic test prompts — the kind of thing a real user would say. Share them with the user: "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to `evals/evals.json`. Don't write assertions yet — just the prompts.

```json
{
  "skill_name": "my-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema.

---

## Step 5: Run with @builder

opencode-global-config does not have parallel subagent runs. Run the test cases sequentially:

```bash
# Run the skill through a real prompt
occo ask "Use my-skill to: <test prompt>"
```

Or invoke the skill directly via a slash command if you have one. The `builder` agent is the right invocation for implementation skills; use `@reviewer` for review-style skills.

For each test case, also run a **baseline** (no skill at all) to compare:

```bash
occo ask "<test prompt>"  # no --skill, see what the LLM does without it
```

Save outputs to `<skill-name>-workspace/iteration-N/eval-<ID>/with_skill/outputs/` (or `without_skill/outputs/` for baseline). Don't create the directory structure upfront — create as you go.

Write an `eval_metadata.json` for each test case (assertions can be empty for now):

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

---

## Step 6: Grade assertions

While runs are in progress, draft quantitative assertions for each test case and explain them to the user. Good assertions are objectively verifiable and have descriptive names.

Update `eval_metadata.json` and `evals/evals.json` with the assertions once drafted.

For assertions that can be checked programmatically, write and run a script. For subjective assertions (writing style, design quality), rely on qualitative review.

Save grading results to `grading.json` in each run directory. The `grading.json` expectations array must use the fields `text`, `passed`, and `evidence` — the schema in `references/schemas.md` depends on these exact field names.

---

## Step 7: Aggregate into benchmark

After all runs are graded, aggregate:

```bash
python3 skills/skill-creator/scripts/aggregate_benchmark.py \
    <workspace>/iteration-1 \
    --skill-name "my-skill"
```

This produces `benchmark.json` and `benchmark.md` with pass rate, time, and tokens for each configuration (with_skill vs without_skill), with mean ± stddev and the delta. See `references/schemas.md` for the exact JSON schema the viewer/aggregator expects.

**There is no browser-based viewer in opencode-global-config.** Read `benchmark.md` and the individual outputs directly. Do the analyst pass inline: look for assertions that always pass regardless of skill (non-discriminating), high-variance evals (possibly flaky), and time/token tradeoffs.

---

## Step 8: User review + iterate

Show the user the `benchmark.md` summary and the qualitative outputs. Ask for feedback. Focus improvements on test cases where the user had specific complaints (empty feedback = they thought it was fine).

After improving the skill, rerun all test cases into `iteration-<N+1>/`. If you're creating a new skill, the baseline (`without_skill`) stays the same across iterations. If you're improving an existing skill, the baseline is the previous version.

Keep going until:
- The user says they're happy
- The feedback is all empty (everything looks good)
- You're not making meaningful progress

### How to think about improvements

1. **Generalize from the feedback.** Skills get used a million times across many prompts. If you and the user are iterating on a few examples, the skill that works for those examples is useless. Avoid fiddly overfitty changes.
2. **Keep the prompt lean.** Remove things that aren't pulling their weight. Read the transcripts, not just the final outputs.
3. **Explain the why.** Try hard to explain the reasoning behind every instruction. Today's LLMs have good theory of mind — a good harness lets them go beyond rote instructions.
4. **Look for repeated work across test cases.** If all 3 test cases resulted in the LLM writing similar helper scripts, that's a strong signal the skill should bundle that script. Write it once, put it in `scripts/`, tell the skill to use it.

---

## Description optimization (opt-in)

The `description` field is the primary mechanism that determines whether the LLM invokes a skill. After creating or improving a skill, optionally optimize the description for better triggering accuracy.

### Step 1: Generate trigger eval queries

Create ~20 eval queries — a mix of should-trigger and should-not-trigger:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

The queries must be realistic, with detail (file paths, context, column names). For **should-trigger** (8-10), cover different phrasings of the same intent. For **should-not-trigger** (8-10), the most valuable are near-misses — queries that share keywords but actually need something different.

Bad: `"Format this data"`, `"Extract text from PDF"`.
Good: `"ok so my boss just sent me this xlsx file (its in my downloads, called 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage"`.

### Step 2: Review with user

Present the eval set to the user inline (no HTML viewer). They can edit queries, toggle should-trigger, add/remove entries. Wait for sign-off.

### Step 3: Iterate description manually

opencode does not have an automated `claude -p` loop. Iterate the description by hand:

1. Read the eval queries aloud, asking "would the LLM pick my skill for this prompt?"
2. If yes: leave as is. If no: rewrite the description to make the trigger more obvious.
3. Re-test by reading the description with fresh eyes after each edit.

This is slower than the automated loop, but it's deliberate and produces a more thoughtful description. Don't over-optimize for a small eval set — that leads to overfitting.

### Step 4: Apply

Update the SKILL.md frontmatter with the new description. Show the user before/after.

---

## Optional: package the skill

Once the skill is done, package it as a `.skill` file (a tarball) for distribution:

```bash
python3 skills/skill-creator/scripts/package_skill.py skills/my-skill
# → produces my-skill.skill
```

The `.skill` file can be moved, archived, or installed in another `~/.config/opencode/skills/` directory.

---

## Updating an existing skill

The user might ask to update an existing skill rather than create a new one. In that case:

- **Preserve the original name.** Use the existing directory name and `name` frontmatter field unchanged.
- **Copy to a writeable location before editing.** The installed skill path may be read-only. Copy to `/tmp/<skill-name>/`, edit there, and copy back via `install.sh`.
- **Update `evals/evals.json` first**, then run baseline, then improve. The baseline is the previous version.

---

## Reference files

The `references/` directory has additional documentation:

- `references/schemas.md` — JSON structures for evals.json, grading.json, benchmark.json, and the .skill package format.

The `scripts/` directory has portable Python utilities:

- `scripts/aggregate_benchmark.py` — Aggregate grading.json files into benchmark.json and benchmark.md.
- `scripts/package_skill.py` — Package a skill folder as a `.skill` file (tarball).

---

## Anti-patterns

- **Overfitting to test cases.** A skill that works for 3 prompts but not the 1000th is useless. Generalize.
- **Rigid MUSTs.** "ALWAYS do X" without explaining why is brittle. Today's LLMs respond better to reasoned instructions.
- **Hiding the failure modes.** If a skill can't handle a common case, say so. Don't pretend.
- **Bundling browser-only tools** without opencode alternatives. The original `eval-viewer/generate_review.py` is browser-based and not portable.
- **Relying on frontmatter fields that opencode strips.** `name` + `description` are the only preserved fields. Don't put logic in `triggers:`, `allowed-tools:`, etc.

---

## Provenance

Adapted from `anthropics/skills/skills/skill-creator/SKILL.md` (cherry-pick 2026-06-28). The original frontmatter `license: Proprietary` was dropped — the content is methodology and JSON schemas, not proprietary code. Original subagent and `claude -p` references replaced with opencode-native equivalents (`occo ask`, `@builder`, `@reviewer`, `validate.sh`). The `references/schemas.md` and the two `scripts/*.py` are ported verbatim. The browser-based `eval-viewer/`, `agents/grader.md`, `agents/comparator.md`, and `agents/analyzer.md` are not ported (browser + Anthropic-specific subagents); use opencode-native review flow instead.
