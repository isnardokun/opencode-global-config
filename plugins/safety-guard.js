export const SafetyGuard = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return

      const cmd = String(output.args.command || "")

      const blocked = [
        "rm -rf /",
        "rm -rf *",
        "sudo rm -rf",
        "mkfs",
        "dd if=",
        "chmod -R 777 /",
        "chown -R",
        ":(){ :|:& };:"
      ]

      if (blocked.some(pattern => cmd.includes(pattern))) {
        throw new Error(`Comando bloqueado por seguridad: ${cmd}`)
      }
    }
  }
}