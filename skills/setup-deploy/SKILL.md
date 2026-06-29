---
name: setup-deploy
description: Detect deployment platform and persist config to CLAUDE.md. Supports Fly, Vercel, Render, Netlify, Railway, Heroku, and GitHub Actions. Adapted from garrytan/gstack for OpenCode.
---

# Setup Deploy

Detect the deployment platform of a project, capture the production URL and deploy command, and persist this as a discoverable block in `CLAUDE.md` (project root) so future sessions know where the app ships.

## When to invoke

- After cloning a new repo
- After the user says "set up deploy" or "where does this ship?"
- Before running `/qa-web` (need to know the staging/prod URL)
- Before running any task that produces deployable output

## Detection logic

Run all of these in parallel and use the first match. Order matters — most specific first.

```bash
echo "FLY=$(test -f fly.toml && echo yes || echo no)"
echo "VERCEL=$(test -f vercel.json || [ -d .vercel ] && echo yes || echo no)"
echo "RENDER=$(test -f render.yaml && echo yes || echo no)"
echo "NETLIFY=$(test -f netlify.toml && echo yes || echo no)"
echo "RAILWAY=$(test -f railway.json || test -f railway.toml && echo yes || echo no)"
echo "HEROKU=$(test -f Procfile && echo yes || echo no)"
echo "GHA=$(test -d .github/workflows && echo yes || echo no)"
echo "DOCKER=$(test -f Dockerfile && echo yes || echo no)"
```

If multiple match, prefer the most managed (Fly > Vercel > Render > Netlify > Railway > Heroku > GH Actions > Docker).

## Captured fields

For each platform, capture:

| Field | Source |
|-------|--------|
| Platform | detected from file above |
| Production URL | ask user (not in repo) |
| Staging URL | ask user if exists |
| Deploy command | platform-specific (see below) |
| Health check URL | `/health`, `/`, or ask |

### Platform-specific deploy commands

- **Fly:** `fly deploy` (requires `flyctl`)
- **Vercel:** `vercel --prod` (or auto on push to main if configured)
- **Render:** push to main triggers deploy
- **Netlify:** push to main triggers deploy
- **Railway:** `railway up` (requires `railway` CLI)
- **Heroku:** `git push heroku main`
- **GitHub Actions:** read `.github/workflows/deploy.yml` to find the trigger
- **Docker:** `docker build -t app . && docker push registry/app` (varies)

## Output — block to append to CLAUDE.md

If `CLAUDE.md` exists in the project root, append this block. If it does not exist, create it with just this block and warn the user.

```markdown

## Deploy Configuration

Detected by opencode-global-config setup-deploy skill.

- **Platform:** <platform>
- **Production URL:** <url or "unknown">
- **Staging URL:** <url or "none">
- **Deploy command:** <cmd>
- **Health check URL:** <url or "unknown">

Last updated: <YYYY-MM-DD>
```

If a `## Deploy Configuration` block already exists in CLAUDE.md, **update it in place** rather than appending a duplicate. Use a marker comment to find the block:

```bash
# Look for existing block
grep -n "## Deploy Configuration" CLAUDE.md 2>/dev/null
```

If found, replace from that line to the next `## ` heading or EOF, whichever comes first. If not, append.

## What you do NOT do

- Do not commit the change automatically. The deploy URL may include staging secrets or internal hostnames.
- Do not run the actual deploy command. This skill is detect-and-document, not deploy.
- Do not modify platform config files (fly.toml, vercel.json, etc.). They are the source of truth.

## When to refuse

If the user wants to actually deploy from this skill: "Setup-deploy is detect-and-document only. To deploy, run the platform-specific command (e.g. `fly deploy`, `vercel --prod`) directly. To verify the deploy worked, use `/qa-web <url>`."

If multiple platforms match and the user has not clarified which is primary: ask. Do not guess.

## What to do if no platform is detected

Some projects are not deployed at all (libraries, internal tools, desktop apps). If no file matches:

- Ask the user: "I did not detect a deploy platform. Is this project deployed anywhere? If so, where?"
- If the user says no, document the absence in CLAUDE.md:

```markdown

## Deploy Configuration

This project is not currently deployed. Update this section if a platform is added.
```

- If the user names a platform not in the detection list (e.g., Cloudflare Workers, AWS Amplify, Google Cloud Run), add a one-time check for the platform-specific config file and document the result.

## Output

End with: `SETUP_DEPLOY_RESULT=ok|skipped|manual`.
