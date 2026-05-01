# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-05-01

### Added

- Initial release with 8 custom agents:
  - `@architect` - Architecture analysis and risk assessment
  - `@planner` - Task decomposition into phases
  - `@builder` - Controlled implementation with verification
  - `@reviewer` - Code review with security focus
  - `@security-auditor` - Vulnerability and credentials audit
  - `@docs-writer` - Technical documentation generation
  - `@devops` - CI/CD, Docker, Kubernetes, IaC support
  - `@oncall` - Production debugging and incident response

- 4 Skills:
  - `project-map` - Project structure and stack analysis
  - `safe-implementation` - Small, verifiable, reversible changes
  - `test-first` - Test before/after modification workflow
  - `precommit-review` - Final audit checklist

- Plugin:
  - `safety-guard.js` - Blocks dangerous commands

- Global command:
  - `oc` - Shortcut for opencode with custom workflow

### Features

- Temperature-controlled agents (0.1-0.2) for focused responses
- Permission-based security model
- Max 3 files per iteration constraint
- Mandatory test/lint/build verification
- .env and secrets protection rules
- DevOps-focused workflow pipeline