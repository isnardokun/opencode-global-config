#!/usr/bin/env bash
# Install script for opencode-global-config
# Usage: curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash

set -e

REPO_URL="https://github.com/isnardokun/opencode-global-config.git"
INSTALL_DIR="/tmp/opencode-config-install-$$"
CONFIG_DIR="${HOME}/.config/opencode"
BIN_DIR="${HOME}/.local/bin"
BACKUP_DIR="${HOME}/.config/opencode.backup.$(date +%Y%m%d-%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     OpenCode Global Config - Instalador v1.7              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 1. Check requirements
info "Verificando requisitos..."

if ! command -v git &>/dev/null; then
    error "Git no está instalado. Instálalo con: dnf install git"
fi

if ! command -v opencode &>/dev/null; then
    error "OpenCode no está instalado. Instálalo desde: https://opencode.ai"
fi

success "Requisitos verificados"

# 2. Clone repo
info "Descargando configuración..."
git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>/dev/null || {
    error "No se pudo clonar el repositorio. Verifica tu conexión a internet."
}
success "Descarga completada"

# 3. Backup existing config
if [ -d "$CONFIG_DIR" ]; then
    warn "Configuración existente detectada en $CONFIG_DIR"
    info "Creando backup en $BACKUP_DIR"
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
    success "Backup creado"
fi

# 4. Install config files
info "Instalando configuración global..."
mkdir -p "$CONFIG_DIR"

# Copy agents, skills, profiles, etc.
for dir in agents skills profiles plugins hooks memory souls; do
    if [ -d "$INSTALL_DIR/$dir" ]; then
        cp -r "$INSTALL_DIR/$dir" "$CONFIG_DIR/"
        success "Instalado: $dir/"
    fi
done

# Copy config files
for file in AGENTS.md CLAUDE.md opencode.json; do
    if [ -f "$INSTALL_DIR/$file" ]; then
        cp "$INSTALL_DIR/$file" "$CONFIG_DIR/"
        success "Instalado: $file"
    fi
done

# Copy oc wrapper script
info "Instalando comando oc..."
mkdir -p "$BIN_DIR"
cp "$INSTALL_DIR/oc" "$BIN_DIR/oc"
chmod +x "$BIN_DIR/oc"
success "Comando oc instalado"

# 5. Add to PATH if needed
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    info "Agregando ~/.local/bin al PATH..."
    if [ -f "${HOME}/.bashrc" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "${HOME}/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
            info "Añadido a ~/.bashrc"
        fi
    fi
    if [ -f "${HOME}/.zshrc" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "${HOME}/.zshrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
            info "Añadido a ~/.zshrc"
        fi
    fi
    export PATH="$BIN_DIR:$PATH"
fi

# 6. Verify installation
info "Verificando instalación..."
if [ -f "$CONFIG_DIR/AGENTS.md" ] && [ -f "$BIN_DIR/oc" ]; then
    success "Instalación completada"
else
    error "La instalación no se completó correctamente"
fi

# 7. Cleanup
rm -rf "$INSTALL_DIR"

# 8. Print summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗"
echo "║           Instalación exitosa!                             ║"
echo "╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Próximos pasos:"
echo "  1. Cierra y vuelve a abrir tu terminal"
echo "  2. Ejecuta: opencode"
echo "  3. Escribe: 'analiza el proyecto actual'"
echo ""
echo "Documentación: https://github.com/isnardokun/opencode-global-config"
echo "Backup guardado en: $BACKUP_DIR"
echo ""