#!/usr/bin/env bash
# Install script for opencode-global-config
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
#   bash install.sh [--dry-run] [--with-playwright] [--with-graphify] [--with-codebase-memory]

# Base repo location. Override with OPENCODE_GLOBAL_CONFIG_BASE_REPO_URL for
# internal mirrors or forks; defaults to isnardokun/opencode-global-config.
DEFAULT_BASE_REPO_URL="https://github.com/isnardokun/opencode-global-config"
BASE_REPO_URL="${OPENCODE_GLOBAL_CONFIG_BASE_REPO_URL:-$DEFAULT_BASE_REPO_URL}"

DRY_RUN=0
WITH_PLAYWRIGHT=0
WITH_GRAPHIFY=0
WITH_CODEBASE_MEMORY=0
for _arg in "$@"; do
    case "$_arg" in
        --dry-run) DRY_RUN=1 ;;
        --with-playwright) WITH_PLAYWRIGHT=1 ;;
        --with-graphify) WITH_GRAPHIFY=1 ;;
        --with-codebase-memory) WITH_CODEBASE_MEMORY=1 ;;
        --help|-h)
            echo "Usage: bash install.sh [--dry-run] [--with-playwright] [--with-graphify] [--with-codebase-memory]"
            echo ""
            echo "Options:"
            echo "  --dry-run             Print the plan without modifying anything"
            echo "  --with-playwright     After install, offer to install Playwright + Chromium"
            echo "                        (~170 MB). Optional and non-default. Enables full"
            echo "                        browser automation for /qa-web and /web-verify."
            echo "  --with-graphify       After install, offer to install graphifyy via uv tool"
            echo "                        (size depends on optional extras). Optional and non-"
            echo "                        default. Enables knowledge graph building and AGENTS.md"
            echo "                        query-first behavior."
            echo "  --with-codebase-memory After install, download codebase-memory-mcp binary from"
            echo "                        GitHub releases (~30 MB) and register it as an MCP"
            echo "                        server for opencode. Complements graphify with"
            echo "                        type-aware call-graph queries across 158 languages."
            exit 0
            ;;
    esac
done

REPO_URL="${BASE_REPO_URL}.git"
INSTALL_DIR="$(mktemp -d "${TMPDIR:-/tmp}/opencode-config-install.XXXXXX")"
CONFIG_DIR="${HOME}/.config/opencode"
BIN_DIR="${HOME}/.local/bin"
BIN_NAME="occo"
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

command_status() {
    local name="$1"
    local description="$2"
    if command -v "$name" >/dev/null 2>&1; then
        printf "  [OK]      %-10s %s (%s)\n" "$name" "$description" "$(command -v "$name")"
        return 0
    fi
    printf "  [MISSING] %-10s %s\n" "$name" "$description"
    return 1
}

install_hint() {
    local cmd="$1"
    case "$cmd" in
        opencode)
            echo "    - OpenCode: https://opencode.ai"
            ;;
        git|jq|python3|node|fzf|gitleaks|shellcheck|shfmt)
            if command -v apt >/dev/null 2>&1; then
                case "$cmd" in
                    node) echo "    - sudo apt install nodejs" ;;
                    shfmt) echo "    - shfmt: install from https://github.com/mvdan/sh" ;;
                    *) echo "    - sudo apt install $cmd" ;;
                esac
            elif command -v dnf >/dev/null 2>&1; then
                case "$cmd" in
                    node) echo "    - sudo dnf install nodejs" ;;
                    shfmt) echo "    - sudo dnf install shfmt" ;;
                    *) echo "    - sudo dnf install $cmd" ;;
                esac
            elif command -v brew >/dev/null 2>&1; then
                case "$cmd" in
                    python3) echo "    - brew install python" ;;
                    node) echo "    - brew install node" ;;
                    *) echo "    - brew install $cmd" ;;
                esac
            else
                echo "    - Install $cmd with your system package manager"
            fi
            ;;
    esac
}

print_requirements() {
    echo "Requisitos del sistema:"
    echo "  Requeridos:"
    local missing_required=0
    command_status git "clonar/actualizar configuración" || missing_required=$((missing_required + 1))
    command_status opencode "ejecutar agentes y CLI OpenCode" || missing_required=$((missing_required + 1))

    echo "  Recomendados:"
    command_status python3 "memoria JSONL/frontmatter robusto" || true
    command_status jq "validación JSON y doctor" || true
    command_status node "validar/cargar plugin safety-guard.js" || true

    echo "  Opcionales:"
    command_status fzf "oc --interactive" || true
    command_status gitleaks "escaneo de secretos en hooks" || true
    command_status shellcheck "lint shell en desarrollo/CI" || true
    command_status shfmt "formateo shell con make format" || true
    command_status playwright "browser automation para /qa-web y /web-verify (full mode)" || true
    command_status lynx "text rendering para /web-verify (tier 2)" || true
    command_status html2text "fallback text rendering para /web-verify (tier 2, Python)" || true
    command_status uv "graphify installer (uv tool install graphifyy)" || true
    command_status graphify "knowledge graph builder para mapear el codebase" || true

    if [ "$missing_required" -gt 0 ]; then
        echo ""
        warn "Faltan requisitos requeridos: $missing_required"
        echo "Sugerencias de instalación:"
        command -v git >/dev/null 2>&1 || install_hint git
        command -v opencode >/dev/null 2>&1 || install_hint opencode
    fi

    return "$missing_required"
}

check_requirements() {
    print_requirements
    local missing_required=$?
    if [ "$missing_required" -gt 0 ]; then
        error "Instala los requisitos requeridos y vuelve a ejecutar el instalador."
    fi
    success "Requisitos requeridos verificados"
}

# Cleanup on any exit (success or failure)
trap 'rm -rf "$INSTALL_DIR"' EXIT

if [ "$DRY_RUN" -eq 1 ]; then
    warn "MODO DRY-RUN: ningún archivo será modificado"
fi

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     OpenCode Global Config - Instalador v1.21.0            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$DRY_RUN" -eq 1 ]; then
    print_requirements || true
    echo ""
    echo "Plan de instalación:"
    echo "  - Verificar requisitos requeridos y listar recomendados/opcionales"
    echo "  - Clonar $REPO_URL en $INSTALL_DIR"
    echo "  - Crear backup si existe $CONFIG_DIR"
    echo "  - Instalar config en $CONFIG_DIR"
    echo "  - Instalar comando ${BIN_NAME} en ${BIN_DIR}/${BIN_NAME}"
    echo "  - Agregar $BIN_DIR al PATH si falta"
    if [ "$WITH_PLAYWRIGHT" -eq 1 ]; then
        echo "  - [--with-playwright] Ofrecer instalar Playwright + Chromium"
    fi
    if [ "$WITH_GRAPHIFY" -eq 1 ]; then
        echo "  - [--with-graphify] Ofrecer instalar graphifyy via uv/pipx/pip"
        echo "  - [--with-graphify] Registrar skill graphify en opencode"
        echo "  - [--with-graphify] Generar knowledge graph de $CONFIG_DIR"
    fi
    if [ "$WITH_CODEBASE_MEMORY" -eq 1 ]; then
        echo "  - [--with-codebase-memory] Descargar binary desde GitHub releases"
        echo "  - [--with-codebase-memory] Ejecutar install.sh interno (auto-registra MCP)"
        echo "  - [--with-codebase-memory] Verificar registro MCP en opencode.json"
    fi
    echo ""
    success "Dry-run completado: ningún archivo fue modificado"
    exit 0
fi

# 1. Check requirements
info "Verificando requisitos..."
check_requirements

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

for dir in agents skills profiles plugins hooks memory souls commands rubrics; do
    if [ -d "$INSTALL_DIR/$dir" ]; then
        # Remove existing target so cp -r picks up new files AND subdirs
        # (without this, a previously-installed skill won't get new subdirs/scripts)
        if [ -d "$CONFIG_DIR/$dir" ]; then
            find "$CONFIG_DIR/$dir" -mindepth 1 -delete
        fi
        # cp -r src/. dst/ (with /. copies contents; without /. copies src inside dst)
        cp -r "$INSTALL_DIR/$dir/." "$CONFIG_DIR/$dir/"
        # Ensure hooks are executable when installing them globally. Without
        # this, hooks copied to ~/.config/opencode/hooks/ lack +x and the
        # user has to chmod manually before oc --init can copy them into
        # a project's .git/hooks/. Caught by occo --doctor in v1.20.0.
        if [ "$dir" = "hooks" ]; then
            find "$CONFIG_DIR/hooks" -type f -name 'pre-*' -exec chmod +x {} +
        fi
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
if ! cp "$INSTALL_DIR/occo" "$BIN_DIR/${BIN_NAME}"; then
    error "No se pudo instalar el comando oc en $BIN_DIR"
fi
chmod +x "$BIN_DIR/${BIN_NAME}"
    success "Comando ${BIN_NAME} instalado en ${BIN_DIR}/${BIN_NAME}"

# 6. Add BIN_DIR to PATH in shell config files
_path_line='export PATH="$HOME/.local/bin:$PATH"'
_path_added=0

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
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
    ;;
esac

# 7. Verify installation
info "Verificando instalación..."
_ok=1
[ -f "$CONFIG_DIR/AGENTS.md" ]     || { warn "Falta: AGENTS.md";    _ok=0; }
[ -f "$CONFIG_DIR/CLAUDE.md" ]     || { warn "Falta: CLAUDE.md";    _ok=0; }
[ -f "$CONFIG_DIR/opencode.json" ]  || { warn "Falta: opencode.json"; _ok=0; }
[ -f "$BIN_DIR/${BIN_NAME}" ]    || { warn "Falta: ${BIN_NAME} en $BIN_DIR"; _ok=0; }
[ -d "$CONFIG_DIR/agents" ]        || { warn "Falta: agents/"; _ok=0; }
[ -d "$CONFIG_DIR/skills" ]        || { warn "Falta: skills/"; _ok=0; }
[ -d "$CONFIG_DIR/commands" ]      || { warn "Falta: commands/"; _ok=0; }
[ -d "$CONFIG_DIR/plugins" ]       || { warn "Falta: plugins/"; _ok=0; }
[ -d "$CONFIG_DIR/rubrics" ]       || { warn "Falta: rubrics/"; _ok=0; }
for _rubric in code-review security-review plan-review; do
    [ -f "$CONFIG_DIR/rubrics/${_rubric}.md" ] || { warn "Falta: rubrics/${_rubric}.md"; _ok=0; }
done

if [ "$_ok" -eq 1 ]; then
    success "Instalación verificada (23 artefactos + opcional Playwright/Graphify)"
else
    error "Instalación incompleta. Revisa los mensajes anteriores."
fi

# 8. Optional Playwright install (browser automation for /qa-web and /web-verify)
if [ "$WITH_PLAYWRIGHT" -eq 1 ]; then
    echo ""
    info "Flag --with-playwright detectado. Verificando instalación..."
    if command -v playwright >/dev/null 2>&1; then
        success "Playwright ya está instalado: $(command -v playwright)"
    else
        warn "Playwright no está instalado. Habilita browser automation para /qa-web y /web-verify."
        echo ""
        echo "  Instalación recomendada (requiere node + npm):"
        echo "    npm install -g playwright"
        echo "    npx playwright install chromium   # ~170 MB de descarga"
        echo ""
        echo "  Sin Playwright, /web-verify funciona en modo degradado:"
        echo "    - tier 1: curl + wget (HTTP only)"
        echo "    - tier 2: + lynx (text rendering)"
        echo "    - tier 3+: requiere Playwright"
        echo ""
        if command -v npm >/dev/null 2>&1 && [ -t 0 ]; then
            printf "¿Instalar Playwright ahora? [y/N]: "
            read -r _confirm
            if [ "$_confirm" = "y" ] || [ "$_confirm" = "Y" ]; then
                info "Instalando Playwright..."
                if npm install -g playwright 2>&1 | tail -5; then
                    success "Playwright instalado"
                    info "Descargando Chromium (~170 MB)..."
                    if npx playwright install chromium 2>&1 | tail -3; then
                        success "Chromium descargado"
                    else
                        warn "Falló la descarga de Chromium. Reintentá manualmente con: npx playwright install chromium"
                    fi
                else
                    warn "Falló la instalación de Playwright. Instalá manualmente: npm install -g playwright"
                fi
            else
                info "Saltando instalación de Playwright. Podés instalarlo después con: npm install -g playwright"
            fi
        else
            info "Sin npm o sin TTY interactivo. Saltando instalación automática. Reejecutá con --with-playwright cuando tengas npm."
        fi
    fi
fi

# 7b. Optional graphify install (knowledge graph builder)
if [ "$WITH_GRAPHIFY" -eq 1 ]; then
    echo ""
    info "Flag --with-graphify detectado. Verificando instalación..."
    if command -v graphify >/dev/null 2>&1; then
        success "graphify ya está instalado: $(command -v graphify)"
    else
        warn "graphify no está instalado. Habilita knowledge graph building y AGENTS.md query-first."
        echo ""
        echo "  Instalación recomendada (requiere uv o pipx):"
        echo "    uv tool install graphifyy            # peso base ~50 MB + extras opcionales"
        echo "    # extras opcionales (vis.plugins, nlp, etc.) pueden agregar 50-200 MB"
        echo "    # o: pipx install graphifyy"
        echo "    # o: pip install --user graphifyy"
        echo ""
        echo "  Sin graphify, el resto del install funciona normalmente."
        echo ""
        if [ -t 0 ]; then
            printf "¿Instalar graphify ahora? [y/N]: "
            read -r _confirm
            if [ "$_confirm" = "y" ] || [ "$_confirm" = "Y" ]; then
                if command -v uv >/dev/null 2>&1; then
                    info "Instalando graphifyy con uv..."
                    if uv tool install graphifyy 2>&1 | tail -5; then
                        success "graphifyy instalado vía uv"
                    else
                        warn "Falló uv tool install. Probá: pipx install graphifyy"
                    fi
                elif command -v pipx >/dev/null 2>&1; then
                    info "Instalando graphifyy con pipx..."
                    if pipx install graphifyy 2>&1 | tail -5; then
                        success "graphifyy instalado vía pipx"
                    else
                        warn "Falló pipx install. Probá: pip install --user graphifyy"
                    fi
                else
                    warn "Sin uv ni pipx. Instalá manualmente: pip install --user graphifyy"
                fi
            else
                info "Saltando instalación de graphify. Podés instalarlo después con: uv tool install graphifyy"
            fi
        else
            info "Sin TTY interactivo. Saltando instalación automática. Reejecutá con --with-graphify cuando tengas TTY."
        fi
    fi

    # Register the opencode skill + AGENTS.md hook (only if graphify is now available)
    if command -v graphify >/dev/null 2>&1; then
        info "Registrando skill graphify en opencode..."
        if graphify opencode install 2>&1 | tail -3; then
            success "Skill graphify registrado en opencode"
        else
            warn "Falló el registro del skill. Reintentá manualmente: graphify opencode install"
        fi

        # Auto-graphify the installed config (snapshot of the current state)
        if [ -d "$CONFIG_DIR" ]; then
            info "Generando knowledge graph de la configuración instalada (~/.config/opencode)..."
            if (cd "$CONFIG_DIR" && graphify . --no-viz 2>&1 | tail -3); then
                success "Graph generado en $CONFIG_DIR/graphify-out/"
                if [ -f "$CONFIG_DIR/graphify-out/GRAPH_REPORT.md" ]; then
                    info "Reporte: $CONFIG_DIR/graphify-out/GRAPH_REPORT.md"
                fi
                # Generate the HTML visualization (graph.html) using our local
                # scripts/graphify_html.py. v8 graphify does not expose an
                # "html" subcommand, so we use the API directly. Stdlib only.
                if [ -f "$ROOT/skills/graphify/scripts/graphify_html.py" ]; then
                    info "Generando visualización HTML interactiva (graph.html)..."
                    if python3 "$ROOT/skills/graphify/scripts/graphify_html.py" "$CONFIG_DIR/graphify-out" 2>&1 | tail -2; then
                        success "Visualización HTML: $CONFIG_DIR/graphify-out/graph.html"
                    else
                        warn "Falló la generación de graph.html. Reintentá manualmente: python3 skills/graphify/scripts/graphify_html.py"
                    fi
                fi
            else
                warn "Falló la generación del graph. Reintentá manualmente: cd ~/.config/opencode && graphify ."
            fi
        fi
    fi
fi

# 7c. Optional codebase-memory-mcp install (type-aware structural code analysis)
if [ "$WITH_CODEBASE_MEMORY" -eq 1 ]; then
    echo ""
    info "Flag --with-codebase-memory detectado. Verificando instalación..."
    if command -v codebase-memory-mcp >/dev/null 2>&1; then
        success "codebase-memory-mcp ya está instalado: $(command -v codebase-memory-mcp)"
        # BUGFIX (v1.18.0 → v1.18.1, hardened in v1.19.1): when binary pre-exists,
        # the download+extract branch is skipped, so the MCP server is never
        # registered in opencode.json. Always run the installer's internal 'install'
        # command to ensure the MCP entry + AGENTS.md hook are present, even on re-run.
        # v1.19.1 fix: the [ -t 0 ] check was skipping the remediation in non-TTY
        # environments (e.g., this sandbox), even though 'install -y' is itself
        # non-interactive. Removed the TTY gate; 'install -y' handles stdin via -y.
        if ! grep -qF 'codebase-memory-mcp' "$CONFIG_DIR/opencode.json" 2>/dev/null; then
            warn "MCP server no registrado en opencode.json. Ejecutando registrador interno..."
            if codebase-memory-mcp install -y 2>&1 | tail -3; then
                success "MCP server registrado por el instalador interno"
            else
                warn "Falló el registro. Reintentá manualmente: codebase-memory-mcp install -y"
            fi
        fi
    else
        warn "codebase-memory-mcp no está instalado. Habilita análisis estructural de código (call graphs, dead code, type-aware) via MCP."
        echo ""
        echo "  Instalación (binary estático ~30 MB, zero deps):"
        echo "    Descarga directa desde GitHub releases:"
        echo "      OS=\$(uname -s | tr '[:upper:]' '[:lower:]')"
        echo "      ARCH=\$(uname -m | sed 's/x86_64/amd64/')"
        echo "      curl -fsSL \"https://github.com/DeusData/codebase-memory-mcp/releases/latest/download/codebase-memory-mcp-\${OS}-\${ARCH}.tar.gz\" | tar xz"
        echo "      ./codebase-memory-mcp install"
        echo ""
        echo "    O vía el instalador one-liner:"
        echo "      curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash"
        echo ""
        if [ -t 0 ] && command -v curl >/dev/null 2>&1; then
            printf "¿Descargar e instalar codebase-memory-mcp ahora? [y/N]: "
            read -r _confirm
            if [ "$_confirm" = "y" ] || [ "$_confirm" = "Y" ]; then
                _cbm_os="$(uname -s | tr '[:upper:]' '[:lower:]')"
                _cbm_arch="$(uname -m | sed 's/x86_64/amd64/')"
                _cbm_url="https://github.com/DeusData/codebase-memory-mcp/releases/latest/download/codebase-memory-mcp-${_cbm_os}-${_cbm_arch}.tar.gz"
                info "Descargando desde $_cbm_url ..."
                _cbm_tmp="$(mktemp -d)"
                if curl -fsSL "$_cbm_url" | tar -xz -C "$_cbm_tmp" 2>&1 | tail -3; then
                    info "Extrayendo y ejecutando install.sh interno..."
                    if [ -f "$_cbm_tmp/install.sh" ]; then
                        if bash "$_cbm_tmp/install.sh" 2>&1 | tail -5; then
                            success "codebase-memory-mcp instalado"
                        else
                            warn "Falló el install.sh interno. Reintentá manualmente."
                        fi
                    else
                        warn "No se encontró install.sh en el tarball. Reintentá manualmente."
                    fi
                else
                    warn "Falló la descarga desde $_cbm_url"
                    warn "Verifica tu conexión o arquitectura (${_cbm_os}-${_cbm_arch})."
                fi
                rm -rf "$_cbm_tmp"
            else
                info "Saltando instalación. Podés instalarlo después con el one-liner de arriba."
            fi
        else
            info "Sin curl o sin TTY interactivo. Saltando instalación automática."
        fi
    fi

    # Verify the MCP server is registered in opencode.json (auto-register happens
    # inside the binary's install.sh). We only warn if opencode.json exists and
    # does not mention codebase-memory-mcp — user may have disabled it on purpose.
    if [ -f "$CONFIG_DIR/opencode.json" ] && command -v codebase-memory-mcp >/dev/null 2>&1; then
        if grep -qF 'codebase-memory-mcp' "$CONFIG_DIR/opencode.json" 2>/dev/null; then
            success "MCP server 'codebase-memory-mcp' registrado en opencode.json"
        else
            warn "MCP server no aparece en opencode.json. El install.sh interno debería"
            warn "haberlo agregado. Reintentá: codebase-memory-mcp install (re-ejecuta)"
        fi
    fi
fi

# 8. Print summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗"
echo "║           Instalación exitosa!                             ║"
echo "╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Próximos pasos:"
echo "  1. Recarga tu terminal:  source ~/.bashrc  (o ~/.zshrc en zsh)"
echo "  2. Ejecutá: 'occo' (o 'oc' si agregaste el alias)"
echo "  3. Escribe: 'analiza el proyecto actual'"
echo ""
echo "  Opcional — alias para seguir usando 'oc':"
echo "    echo \"alias oc='occo'\" >> ~/.bashrc && source ~/.bashrc"
echo ""
if [ -d "$BACKUP_DIR" ]; then
    echo "Backup guardado en: $BACKUP_DIR"
fi
echo "Documentación: ${BASE_REPO_URL}"
echo ""
