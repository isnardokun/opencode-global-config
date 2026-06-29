---
description: Detect deployment platform and persist config to CLAUDE.md
---

Use the @setup-deploy skill.

Detect the deployment platform of this project and persist the configuration to `CLAUDE.md`.

Detection order (most managed first): Fly > Vercel > Render > Netlify > Railway > Heroku > GitHub Actions > Docker.

Detection files:
- Fly: `fly.toml`
- Vercel: `vercel.json` or `.vercel/` directory
- Render: `render.yaml`
- Netlify: `netlify.toml`
- Railway: `railway.json` or `railway.toml`
- Heroku: `Procfile`
- GitHub Actions: `.github/workflows/` directory
- Docker: `Dockerfile`

If multiple match, ask the user which is primary. If none match, ask the user where it deploys (or document that it is not deployed).

After detection, ask the user for:
- Production URL
- Staging URL (if exists)
- Deploy command (or detect from platform)

Append (or update) a `## Deploy Configuration` block in `CLAUDE.md` with the captured fields. Do NOT commit the change — the user may want to review.

Do NOT run the actual deploy command. This skill is detect-and-document only.

End with `SETUP_DEPLOY_RESULT=ok|skipped|manual`.
