# CLI Reference

This project does **not** expose an HTTP API, routes, or a network service. Its public surface is the `oc` command installed at `~/.local/bin/oc` plus native OpenCode slash commands under `commands/`.

## `oc` command surface

```bash
oc [option] [command] [arguments]
```

### Quick commands

| Command | Purpose | Example |
|---------|---------|---------|
| `oc ask <request>` | Route natural language to the most likely agent/workflow | `oc ask "documenta este proyecto"` |
| `oc ask --dry-run <request>` | Show route and prompt without running OpenCode | `oc ask --dry-run "revisa seguridad"` |
| `oc analyze <path>` | Run `@architect` with `project-map` | `oc analyze .` |
| `oc plan <task>` | Run `@planner` | `oc plan "migrate to PostgreSQL"` |
| `oc build <change>` | Run `@builder` with `test-first` | `oc build "add pagination"` |
| `oc review [path]` | Run `@reviewer` with `precommit-review` | `oc review src/` |
| `oc secure [path]` | Run `@security-auditor` | `oc secure src/auth/` |
| `oc docs [path]` | Run `@docs-writer` | `oc docs .` |
| `oc devops <task>` | Run `@devops` | `oc devops "configura CI"` |
| `oc oncall [context]` | Run `@oncall` | `oc oncall "build failing"` |

### Workflows

Workflows are single-pass prompts sent to `opencode run`. Successful workflows must end with the exact marker `WORKFLOW_COMPLETE=true`; otherwise `oc` returns non-zero and does not record a successful outcome.

```bash
oc --workflow bug-hunt ~/project              # 5 phases
oc --workflow new-project "my-api"            # 4 phases
oc --workflow debug "JWT failing"             # 3 phases
oc --workflow document ~/project              # 3 phases
oc --workflow feature "add auth" ~/api        # 4 phases
```

### Memory commands

```bash
oc --memory "auth" -p my-api -t decision
oc --timeline 20260501-143022-a1b2c3d4
oc --get obs_20260501-143022-a1b2c3d4
oc --remember -p my-api -t decision "Chose Redis for cache"
oc --list-templates
```

### Session and installation diagnostics

```bash
oc --compact          # Summarize current session and reset turn counter
oc --budget           # Show session turn count
oc --status           # Show profile, project, hooks, memory status
oc --save-all         # Store outcome/reflection in memory
oc --doctor           # Validate installed OpenCode config health
```

### Profiles and initialization

```bash
oc --profile trusted
oc --list-profiles
oc --init ~/my-project
oc --detect-skills ~/my-project
oc --install-skills-registry
```

## Native OpenCode slash commands

Files in `commands/` are loaded by OpenCode and used inside the TUI:

```text
/analyze
/review
/secure
/feature
/bug-hunt
/docs
/devops
/oncall
```

## Exit markers

Automation relies on exact markers in command output:

| Marker | Used by | Behavior |
|--------|---------|----------|
| `WORKFLOW_COMPLETE=true` | `oc --workflow ...` | Required for workflow success and outcome tracking |
| `BLOCKING_FINDINGS=false` | Git hooks | Required to pass pre-commit/pre-push review gates |
| `BLOCKING_FINDINGS=true` | Git hooks | Blocks commit/push |
