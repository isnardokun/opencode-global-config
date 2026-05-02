#!/usr/bin/env bash
# Install script for opencode-global-config
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
#   bash install.sh [--dry-run]

DRY_RUN=0
for _arg in "$@"; do
    case "$_arg" in
        --dry-run) DRY_RUN=1 ;;
    esac
done

REPO_URL="https://github.com/isnardokun/opencode-global-config.git"
INSTALL_DIR="/tmp/opencode-config-install-$$"
CONFIG_DIR="${HOME}/.config/opencode"
BIN_DIR="${HOME}/.local/bin"
BACKUP_DIR="${HOME}/.config/opencode.backup.$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Dry-run wrapper: prints command instead of running it
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

# Cleanup on any exit (success or failure)
trap 'rm -rf "$INSTALL_DIR"' EXIT

if [ "$DRY_RUN" -eq 1 ]; then
    warn "MODO DRY-RUN: ningún archivo será modificado"
fi

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     OpenCode Global Config - Instalador v1.8              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 1. Check requirements
info "Verificando requisitos..."

if ! command -v git >/dev/null 2>&1; then
    error "Git no está instalado. Instálalo primero."
fi

if ! command -v opencode >/dev/null 2>&1; then
    error "OpenCode no está instalado. Instálalo desde: https://opencode.ai"
fi

success "Requisitos verificados"

# 2. Clone repo
info "Descargando configuración..."
if ! git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"; then
    error "No se pudo clonar el repositorio. Verifica tu conexión a internet."
fi
success "Descarga completada"

# 3. Backup existing config
if [ -d "$CONFIG_DIR" ]; then
    warn "Configuración existente detectada en $CONFIG_DIR"
    info "Creando backup en $BACKUP_DIR"
    if ! cp -r "$CONFIG_DIR" "$BACKUP_DIR"; then
        error "No se pudo crear el backup. Verifica permisos en $HOME/.config/"
    fi
    success "Backup creado en $BACKUP_DIR"
fi

# 4. Install config files
info "Instalando configuración global..."
mkdir -p "$CONFIG_DIR"

for dir in agents skills profiles plugins hooks memory souls commands; do
    if [ -d "$INSTALL_DIR/$dir" ]; then
        cp -r "$INSTALL_DIR/$dir" "$CONFIG_DIR/"
        success "Instalado: $dir/"
    fi
done

for file in AGENTS.md CLAUDE.md; do
    if [ -f "$INSTALL_DIR/$file" ]; then
        cp "$INSTALL_DIR/$file" "$CONFIG_DIR/"
        success "Instalado: $file"
    fi
done

# Generate opencode.json with fully-expanded paths (no ~ that may not expand in JSON)
info "Generando opencode.json con rutas absolutas..."
cat > "$CONFIG_DIR/opencode.json" << EOF
{
  "\$schema": "https://opencode.ai/config.json",

  "autoupdate": false,

  "instructions": [
    "${HOME}/.config/opencode/AGENTS.md",
    "${HOME}/.config/opencode/CLAUDE.md"
  ],

  "plugin": [
    "${HOME}/.config/opencode/plugins/safety-guard.js"
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

    "skill": {
      "*": "allow"
    }
  },

  "watcher": {
    "ignore": [
      ".git/**",
      "node_modules/**",
      "dist/**",
      "build/**",
      ".venv/**",
      "venv/**",
      "__pycache__/**",
      ".next/**",
      ".turbo/**",
      "coverage/**",
      "*.log"
    ]
  }
}
EOF
success "Instalado: opencode.json"

# 5. Install oc command
info "Instalando comando oc..."
mkdir -p "$BIN_DIR"
if ! cp "$INSTALL_DIR/oc" "$BIN_DIR/oc"; then
    error "No se pudo instalar el comando oc en $BIN_DIR"
fi
chmod +x "$BIN_DIR/oc"
success "Comando oc instalado en $BIN_DIR/oc"

# 6. Add BIN_DIR to PATH in shell config files
_path_line='export PATH="$HOME/.local/bin:$PATH"'
_path_added=0

if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    info "Agregando $BIN_DIR al PATH..."

    # bash on Linux
    if [ -f "${HOME}/.bashrc" ] && ! grep -qF "$_path_line" "${HOME}/.bashrc"; then
        echo "$_path_line" >> "${HOME}/.bashrc"
        info "Añadido a ~/.bashrc"
        _path_added=1
    fi

    # bash on macOS (uses .bash_profile, not .bashrc)
    if [ -f "${HOME}/.bash_profile" ] && ! grep -qF "$_path_line" "${HOME}/.bash_profile"; then
        echo "$_path_line" >> "${HOME}/.bash_profile"
        info "Añadido a ~/.bash_profile"
        _path_added=1
    fi

    # zsh (macOS default since Catalina, common on Linux too)
    if [ -f "${HOME}/.zshrc" ] && ! grep -qF "$_path_line" "${HOME}/.zshrc"; then
        echo "$_path_line" >> "${HOME}/.zshrc"
        info "Añadido a ~/.zshrc"
        _path_added=1
    fi

    # fish shell
    if [ -d "${HOME}/.config/fish" ]; then
        _fish_line='fish_add_path $HOME/.local/bin'
        _fish_cfg="${HOME}/.config/fish/config.fish"
        if ! grep -qF "$_fish_line" "$_fish_cfg" 2>/dev/null; then
            echo "$_fish_line" >> "$_fish_cfg"
            info "Añadido a ~/.config/fish/config.fish"
            _path_added=1
        fi
    fi

    if [ "$_path_added" -eq 0 ]; then
        warn "No se encontró ~/.bashrc, ~/.zshrc, ni ~/.bash_profile"
        warn "Agrega manualmente a tu shell: $_path_line"
    fi

    export PATH="$BIN_DIR:$PATH"
fi

# 7. Verify installation
info "Verificando instalación..."
_ok=1
[ -f "$CONFIG_DIR/AGENTS.md" ]     || { warn "Falta: AGENTS.md";    _ok=0; }
[ -f "$CONFIG_DIR/opencode.json" ]  || { warn "Falta: opencode.json"; _ok=0; }
[ -f "$BIN_DIR/oc" ]               || { warn "Falta: oc en $BIN_DIR"; _ok=0; }
[ -d "$CONFIG_DIR/agents" ]        || { warn "Falta: agents/"; _ok=0; }
[ -d "$CONFIG_DIR/skills" ]        || { warn "Falta: skills/"; _ok=0; }
[ -d "$CONFIG_DIR/commands" ]      || { warn "Falta: commands/"; _ok=0; }
[ -d "$CONFIG_DIR/plugins" ]       || { warn "Falta: plugins/"; _ok=0; }

if [ "$_ok" -eq 1 ]; then
    success "Instalación verificada (7 artefactos)"
else
    error "Instalación incompleta. Revisa los mensajes anteriores."
fi

# 8. Print summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗"
echo "║           Instalación exitosa!                             ║"
echo "╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Próximos pasos:"
echo "  1. Recarga tu terminal:  source ~/.bashrc  (o ~/.zshrc en zsh)"
echo "  2. Ejecuta: opencode"
echo "  3. Escribe: 'analiza el proyecto actual'"
echo ""
if [ -d "$BACKUP_DIR" ]; then
    echo "Backup guardado en: $BACKUP_DIR"
fi
echo "Documentación: https://github.com/isnardokun/opencode-global-config"
echo ""
