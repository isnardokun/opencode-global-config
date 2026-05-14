# Deployment and Release Operations

This repository does not deploy a server, container, or long-running service. "Deployment" means publishing and installing a global OpenCode configuration into `~/.config/opencode/` and `~/.local/bin/oc`.

Docker is not present. CI/CD is present through GitHub Actions at `.github/workflows/validate.yml`.

## Runtime paths

| Path | Purpose |
|------|---------|
| `~/.config/opencode/` | Installed OpenCode global configuration |
| `~/.config/opencode/opencode.json` | Generated config with absolute paths |
| `~/.config/opencode/memory/` | File-based memory bank and outcomes |
| `~/.config/opencode/logs/safety-guard.jsonl` | Security plugin audit log (`0600`) |
| `~/.local/bin/oc` | Installed wrapper command |

## Environment variables

The scripts primarily use standard shell environment variables.

| Variable | Used by | Notes |
|----------|---------|-------|
| `HOME` | All scripts | Determines install location and memory/log paths |
| `PATH` | All scripts | Must include `~/.local/bin` after install for `oc` |
| `OPENCODE_PROFILE` | `oc` | Active profile override/session state |
| `OC_AUTO_COMPACT_RUNNING` | `oc` | Internal reentrancy guard for auto-compact |

Test-only variables used by `tests/run.sh` fixtures include `OC_FAKE_OUTPUT`, `OC_FAKE_EXIT`, `OC_CAPTURE`, `OC_CALL_COUNT_FILE`, and `OC_TEST_MARKER`.

## Local validation before release

```bash
make check
make test
./validate.sh
bash install.sh --dry-run
git diff --check
```

If optional tools are installed, also run:

```bash
shellcheck --severity=error install.sh oc hooks/pre-commit hooks/pre-push uninstall.sh validate.sh
shfmt -w -i 2 -ci install.sh oc validate.sh uninstall.sh hooks/pre-commit hooks/pre-push
```

## CI pipeline

GitHub Actions runs on pushes and pull requests to `main`:

```text
checkout
setup-node@v4 (Node 20)
apt install jq shellcheck
bash validate.sh
bash tests/run.sh
shellcheck install.sh oc hooks uninstall.sh validate.sh
check agents do not hardcode model:
check foreign-language artifact patterns
```

## Installation deployment

Recommended installation from the public repository:

```bash
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
oc --doctor
```

Safer manual flow:

```bash
git clone https://github.com/isnardokun/opencode-global-config /tmp/opencode-global-config
cd /tmp/opencode-global-config
bash install.sh --dry-run
bash install.sh
./validate.sh --installed
oc --doctor
```

## Rollback / uninstall

The installer backs up existing `~/.config/opencode` before replacing it. To remove the installed configuration:

```bash
bash uninstall.sh
```

Use `bash uninstall.sh --force` for non-interactive removal in automation.
