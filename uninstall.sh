#!/usr/bin/env bash
# Uninstall opencode-global-config
# Usage: bash uninstall.sh [--force]

set -u

CONFIG_DIR="${HOME}/.config/opencode"
BIN="${HOME}/.local/bin/oc"
FORCE=0

for _arg in "$@"; do
    case "$_arg" in
        --force) FORCE=1 ;;
    esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         OpenCode Global Config — Uninstaller               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "This will remove:"
echo "  - ${CONFIG_DIR}  (config, agents, skills, plugins, memory)"
echo "  - ${BIN}  (oc command)"
echo ""
warn "A backup will be created before deletion."
echo ""

if [ "$FORCE" -eq 0 ]; then
    read -r -p "Continue? [y/N]: " confirm
    case "$confirm" in
        y|Y|yes|YES) ;;
        *) echo "Cancelled."; exit 0 ;;
    esac
fi

BACKUP_DIR="${HOME}/.config/opencode.removed.$(date +%Y%m%d-%H%M%S)"

if [ -d "$CONFIG_DIR" ]; then
    mv "$CONFIG_DIR" "$BACKUP_DIR"
    success "Config backed up to: $BACKUP_DIR"
else
    info "Config directory not found: $CONFIG_DIR"
fi

if [ -f "$BIN" ]; then
    rm -f "$BIN"
    success "Removed: $BIN"
else
    info "oc not found at: $BIN"
fi

echo ""
echo "PATH cleanup: remove this line from your shell config manually:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
success "Uninstall complete."
echo ""
echo "To restore: mv '$BACKUP_DIR' '$CONFIG_DIR'"
