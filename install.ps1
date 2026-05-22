# OpenCode Global Config - Windows Installer (PowerShell)
# Usage:
#   irm https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.ps1 | iex
#   .\install.ps1 [-DryRun]

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$REPO_URL = "https://github.com/isnardokun/opencode-global-config.git"
$INSTALL_DIR = Join-Path $env:TEMP "opencode-config-install-$(Get-Random)"
$CONFIG_DIR = "$env:USERPROFILE\.config\opencode"
$BIN_DIR = "$env:USERPROFILE\.local\bin"
$BIN_NAME = "occo"
$BACKUP_DIR = "$env:USERPROFILE\.config\opencode.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$GREEN = "`e[0;32m"
$BLUE = "`e[0;34m"
$YELLOW = "`e[1;33m"
$RED = "`e[0;31m"
$NC = "`e[0m"

function info($msg) { Write-Host "${BLUE}[INFO]${NC} $msg" }
function success($msg) { Write-Host "${GREEN}[OK]${NC} $msg" }
function warn($msg) { Write-Host "${YELLOW}[WARN]${NC} $msg" }
function error($msg) { Write-Host "${RED}[ERROR]${NC} $msg"; exit 1" }

function command_status($name, $desc) {
    $path = Get-Command $name -ErrorAction SilentlyContinue
    if ($path) {
        Write-Host "  [OK]      $(-10)$name $desc ($($path.Source))"
        return 0
    }
    Write-Host "  [MISSING] $(-10)$name $desc"
    return 1
}

Write-Host "${BLUE}"
Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║     OpenCode Global Config - Windows Installer v1.9.7      ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host "${NC}"

if ($DryRun) {
    warn "DRY-RUN: no files will be modified"
    Write-Host ""
    Write-Host "Plan:"
    Write-Host "  - Clone $REPO_URL into $INSTALL_DIR"
    Write-Host "  - Backup existing $CONFIG_DIR if present"
    Write-Host "  - Install config to $CONFIG_DIR"
    Write-Host "  - Install occo to $BIN_DIR"
    Write-Host "  - Add $BIN_DIR to User PATH (current shell only)"
    Write-Host ""
    success "Dry-run complete: no files were modified"
    exit 0
}

# 1. Check prerequisites
info "Checking prerequisites..."
$missing = 0

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    warn "git not found"
    Write-Host "    - Install git: https://git-scm.com/download/win"
    $missing++
}

$opencode = Get-Command opencode -ErrorAction SilentlyContinue
if (-not $opencode) {
    warn "opencode not found"
    Write-Host "    - Install OpenCode: https://opencode.ai"
    $missing++
}

if ($missing -gt 0) {
    error "Install missing prerequisites and try again."
}
success "Prerequisites verified"

# 2. Clone repo
info "Downloading configuration..."
git clone --depth 1 $REPO_URL $INSTALL_DIR
if ($LASTEXITCODE -ne 0) { error "Failed to clone repository" }
success "Download complete"

# 3. Backup existing config
if (Test-Path $CONFIG_DIR) {
    warn "Existing config detected at $CONFIG_DIR"
    info "Creating backup at $BACKUP_DIR"
    Copy-Item -Recurse $CONFIG_DIR $BACKUP_DIR
    success "Backup created"
}

# 4. Install config files
info "Installing configuration..."
New-Item -ItemType Directory -Force -Path $CONFIG_DIR | Out-Null

$dirs = @("agents", "skills", "profiles", "plugins", "hooks", "memory", "souls", "commands", "rubrics")
foreach ($dir in $dirs) {
    $src = Join-Path $INSTALL_DIR $dir
    if (Test-Path $src) {
        Copy-Item -Recurse $src "$CONFIG_DIR\"
        success "Installed: $dir\"
    }
}

foreach ($file in @("AGENTS.md", "CLAUDE.md")) {
    $src = Join-Path $INSTALL_DIR $file
    if (Test-Path $src) {
        Copy-Item $src "$CONFIG_DIR\"
        success "Installed: $file"
    }
}

# 5. Generate opencode.json
info "Generating opencode.json..."
$homePath = $env:USERPROFILE -replace '\\', '\\'
$json = @"
{
  "`$schema": "https://opencode.ai/config.json",
  "autoupdate": false,
  "instructions": [
    "${homePath}\.config\opencode\AGENTS.md",
    "${homePath}\.config\opencode\CLAUDE.md"
  ],
  "plugin": [
    "${homePath}\.config\opencode\plugins\safety-guard.js"
  ],
  "permission": {
    "read": "allow",
    "list": "allow",
    "glob": "allow",
    "grep": "allow",
    "edit": "ask",
    "bash": "ask",
    "webfetch": "ask",
    "websearch": "ask",
    "skill": { "*": "allow" }
  },
  "watcher": {
    "ignore": [
      ".git/**", "node_modules/**", "dist/**", "build/**",
      ".venv/**", "venv/**", "__pycache__/**", ".next/**",
      ".turbo/**", "coverage/**", "*.log"
    ]
  }
}
"@
$json | Set-Content (Join-Path $CONFIG_DIR "opencode.json") -Encoding UTF8
success "Installed: opencode.json"

# 6. Install occo command
info "Installing occo command..."
New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null
Copy-Item (Join-Path $INSTALL_DIR "oc") "$BIN_DIR\$BIN_NAME"
if ($LASTEXITCODE -ne 0) { error "Failed to install occo to $BIN_DIR" }
success "Installed: $BIN_DIR\$BIN_NAME"

# 7. Add to User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathLine = "$BIN_DIR"
if ($userPath -notlike "*$BIN_DIR*") {
    info "Adding $BIN_DIR to User PATH..."
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$BIN_DIR", "User")
    $env:Path = "$userPath;$BIN_DIR"
    success "Added $BIN_DIR to User PATH (persistent)"
    Write-Host "    Note: Restart your terminal for PATH changes to take effect."
} else {
    info "$BIN_DIR already in User PATH"
}

# 8. Verify installation
info "Verifying installation..."
$ok = 1
$checks = @(
    (Join-Path $CONFIG_DIR "AGENTS.md"),
    (Join-Path $CONFIG_DIR "CLAUDE.md"),
    (Join-Path $CONFIG_DIR "opencode.json"),
    (Join-Path $BIN_DIR $BIN_NAME)
)
$dirChecks = @("agents", "skills", "commands", "plugins", "rubrics")

foreach ($check in $checks) {
    if (-not (Test-Path $check)) {
        warn "Missing: $check"
        $ok = 0
    }
}
foreach ($dir in $dirChecks) {
    if (-not (Test-Path (Join-Path $CONFIG_DIR $dir))) {
        warn "Missing: $dir\"
        $ok = 0
    }
}

if ($ok -eq 1) {
    success "Installation verified (12 artifacts)"
} else {
    error "Installation incomplete"
}

# 9. Summary
Write-Host ""
Write-Host "${GREEN}╔════════════════════════════════════════════════════════════╗"
Write-Host "║           Installation successful!                        ║"
Write-Host "╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart your terminal (or refresh environment)"
Write-Host "     - Close and reopen PowerShell/CMD"
Write-Host "     - Or: `$env:Path = [Environment]::GetEnvironmentVariable('Path','User')"
Write-Host "  2. Run: occo --doctor"
Write-Host ""
if (Test-Path $BACKUP_DIR) {
    Write-Host "Backup stored at: $BACKUP_DIR"
}
Write-Host "Docs: https://github.com/isnardokun/opencode-global-config"
Write-Host ""

# Cleanup
Remove-Item -Recurse -Force $INSTALL_DIR -ErrorAction SilentlyContinue