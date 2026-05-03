import fs from "node:fs"
import os from "node:os"
import path from "node:path"

function redactCommand(command) {
  const secretNames = "GITHUB_TOKEN|OPENAI_API_KEY|NPM_TOKEN|GH_TOKEN|ANTHROPIC_API_KEY|AWS_ACCESS_KEY_ID|token|password|API_KEY|AWS_SECRET_ACCESS_KEY|_authToken"
  return command
    .replace(/(Authorization:\s*Bearer\s+)("[^"]*"|'[^']*'|[^\s"']+)/gi, "$1[REDACTED]")
    .replace(/((?:x-api-key|api-key):\s*)("[^"]*"|'[^']*'|[^\s"']+)/gi, "$1[REDACTED]")
    .replace(new RegExp(`\\b(${secretNames})=("[^"]*"|'[^']*'|[^\\s"']+)`, "gi"), "$1=[REDACTED]")
    .replace(/((?:--token|--password|--api-key)(?:=|\s+))("[^"]*"|'[^']*'|[^\s"']+)/gi, "$1[REDACTED]")
    .replace(/([a-z][a-z0-9+.-]*:\/\/)[^\s/@:]+:[^\s/@]+@/gi, "$1[REDACTED]@")
}

function audit(event) {
  const logDir = path.join(os.homedir(), ".config", "opencode", "logs")
  const logFile = path.join(logDir, "safety-guard.jsonl")
  try {
    fs.mkdirSync(logDir, { recursive: true, mode: 0o700 })
    fs.chmodSync(logDir, 0o700)
    const line = JSON.stringify({
      ts: new Date().toISOString(),
      cwd: process.cwd(),
      ...event
    })
    const fd = fs.openSync(logFile, "a", 0o600)
    try {
      fs.appendFileSync(fd, line + "\n")
    } finally {
      fs.closeSync(fd)
    }
    fs.chmodSync(logFile, 0o600)
  } catch (_) {
    // Never let logging fail a command
  }
}

export const SafetyGuard = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return

      const raw = String(output?.args?.command || "")
      // Normalize whitespace before matching — prevents bypass via extra spaces/tabs
      const cmd = raw.replace(/\s+/g, " ").trim()

      const blocked = [
        // Recursive delete of filesystem roots
        /\brm\b(?=[^;&|]*\s(?:-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*|-[a-zA-Z]*r[a-zA-Z]*\s+-[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*\s+-[a-zA-Z]*r[a-zA-Z]*|--recursive\s+--force|--force\s+--recursive)(?:\s|$))[^;&|]*\s(["']?(?:\/\*?|~(?:\/\*)?|\$HOME|\$\{HOME\})["']?(?:\/[^\s;&|]*)?|["']?(?:\/home|\/root|\/etc|\/usr|\/bin|\/var)(?:\/[^"'\s;&|]*)?["']?)(?=\s|$|[;&|])/,
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
        const redacted = redactCommand(raw)
        audit({ type: "blocked", command: redacted, reason: match.toString() })
        throw new Error(`Comando bloqueado por seguridad: ${redacted}`)
      }

      // Audit allowed commands (only log bash calls for visibility)
      audit({ type: "allowed", command: redactCommand(raw) })
    },
  }
}
