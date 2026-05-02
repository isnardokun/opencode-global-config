const fs = require("fs")
const os = require("os")
const path = require("path")

function audit(event) {
  const logDir = path.join(os.homedir(), ".config", "opencode", "logs")
  try {
    fs.mkdirSync(logDir, { recursive: true })
    const line = JSON.stringify({
      ts: new Date().toISOString(),
      cwd: process.cwd(),
      ...event
    })
    fs.appendFileSync(path.join(logDir, "safety-guard.jsonl"), line + "\n")
  } catch (_) {
    // Never let logging fail a command
  }
}

export const SafetyGuard = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return

      const raw = String(output.args.command || "")
      // Normalize whitespace before matching — prevents bypass via extra spaces/tabs
      const cmd = raw.replace(/\s+/g, " ").trim()

      const blocked = [
        // Recursive delete of filesystem roots
        /\brm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+(\/[\s$]|~[\s$]|\/home|\/root|\/etc|\/usr|\/bin|\/var)/,
        /\brm\s+-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*\s+(\/[\s$]|~[\s$]|\/home|\/root|\/etc|\/usr|\/bin|\/var)/,
        // Wipe filesystem / disk
        /\bmkfs\b/,
        /\bdd\s+if=/,
        // World-writable on root paths
        /\bchmod\s+-[Rr]\s+[0-9]*7[0-9]*[0-9]*\s+\//,
        // Fork bomb
        /:\s*\(\s*\)\s*\{/,
        // Overwrite MBR/disk device directly
        />\s*\/dev\/(s|h|v|xv|nv)d[a-z]\b/,
        // Truncate critical system files
        />\s*\/etc\/(passwd|shadow|sudoers|hosts)\b/,
      ]

      const match = blocked.find((rx) => rx.test(cmd))
      if (match) {
        audit({ type: "blocked", command: raw, reason: match.toString() })
        throw new Error(`Comando bloqueado por seguridad: ${raw}`)
      }

      // Audit allowed commands (only log bash calls for visibility)
      audit({ type: "allowed", command: raw })
    },
  }
}
