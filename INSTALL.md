# Instalación

## Requisitos

- [OpenCode CLI](https://opencode.ai) instalado
- Git
- `fzf` — solo para modo interactivo (`oc --interactive`)
- Compatible con: Linux (Ubuntu, Fedora, Debian, Arch), macOS (Intel y Apple Silicon)

## Instalación Rápida

```bash
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
```

El script:
1. Verifica que `git` y `opencode` estén instalados
2. Clona el repo en `/tmp`
3. Hace backup de `~/.config/opencode` si existe
4. Copia agentes, skills, perfiles, plugins y hooks
5. Genera `opencode.json` con rutas absolutas (sin `~`)
6. Instala el comando `oc` en `~/.local/bin`
7. Añade `~/.local/bin` al PATH en `.bashrc`, `.bash_profile` (macOS), `.zshrc`, y fish según lo que tengas
8. Limpia archivos temporales al salir (incluso en caso de error)

---

## Instalación Manual

```bash
# 1. Clonar repositorio
git clone https://github.com/isnardokun/opencode-global-config.git /tmp/opencode-config

# 2. Respaldar configuración existente (opcional)
[ -d ~/.config/opencode ] && cp -r ~/.config/opencode ~/.config/opencode.backup.$(date +%Y%m%d-%H%M%S)

# 3. Crear directorio de configuración
mkdir -p ~/.config/opencode

# 4. Copiar solo los archivos de configuración (no README, CHANGELOG, etc.)
for d in agents skills profiles plugins hooks memory souls; do
    [ -d "/tmp/opencode-config/$d" ] && cp -r "/tmp/opencode-config/$d" ~/.config/opencode/
done
cp /tmp/opencode-config/AGENTS.md ~/.config/opencode/
cp /tmp/opencode-config/CLAUDE.md  ~/.config/opencode/

# 5. Generar opencode.json con rutas absolutas
cat > ~/.config/opencode/opencode.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "permission": { "skill": { "*": "allow" } },
  "instructions": ["${HOME}/.config/opencode/AGENTS.md"],
  "plugin":       ["${HOME}/.config/opencode/plugins/safety-guard.js"]
}
EOF

# 6. Instalar comando oc
mkdir -p ~/.local/bin
cp /tmp/opencode-config/oc ~/.local/bin/oc
chmod +x ~/.local/bin/oc

# 7. Agregar al PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc   # Linux bash
# echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile  # macOS bash
# echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc          # zsh
source ~/.bashrc

# 8. Instalar fzf (opcional, solo para oc --interactive)
# Linux:   sudo apt install fzf  /  sudo dnf install fzf  /  sudo pacman -S fzf
# macOS:   brew install fzf
```

---

## Qué se instala

### Agentes

| Agente | Descripción | Permisos |
|--------|-------------|----------|
| `@architect` | Análisis de arquitectura y riesgos | read-only |
| `@planner` | Planificación con fases verificables | read-only |
| `@builder` | Implementación con Karpathy principles | edit + bash(ask) |
| `@reviewer` | Code review con precommit-review | read-only |
| `@security-auditor` | Auditoría de vulnerabilidades | read-only |
| `@docs-writer` | Documentación técnica | edit |
| `@devops` | Infraestructura y CI/CD | edit + bash |
| `@oncall` | Diagnóstico de producción | bash(ask) |

### Skills (6)

| Skill | Función |
|-------|---------|
| `project-map` | Análisis de estructura de proyecto |
| `safe-implementation` | Cambios mínimos y verificables |
| `test-first` | Goal-Driven Execution |
| `precommit-review` | Revisión de diff antes de commit |
| `memory-retrieval` | 3-layer progressive disclosure |
| `docs-writer` | Documentación técnica |

### Perfiles (7 niveles de confianza)

`deny` → `plan` → `review` → `default` → `auto` → `trusted` → `devops`

### Intent Mapping — Lenguaje Natural → Agente

El sistema detecta la intención automáticamente dentro de sesiones `opencode`:

| Lo que escribes | Agente activado |
|-----------------|-----------------|
| "analiza el proyecto" | `@architect` + project-map |
| "implementa auth con JWT" | `@builder` + safe-implementation |
| "revisame el código" | `@reviewer` + precommit-review |
| "busca vulnerabilidades" | `@security-auditor` |
| "genera documentación" | `@docs-writer` |
| "diagnostica el error en prod" | `@oncall` |

---

## Verificar Instalación

```bash
# Verificar archivos instalados
ls ~/.config/opencode/agents/
ls ~/.config/opencode/skills/
ls ~/.config/opencode/profiles/
cat ~/.config/opencode/opencode.json

# Verificar comando oc
which oc
oc --help

# Test rápido (desde un directorio con código)
oc analyze .
```

---

## Uso

### Modo Natural (dentro de sesión opencode)

```bash
opencode
# Dentro de la sesión, escribe en lenguaje natural:
# "analiza el proyecto actual"         → @architect + project-map
# "implementa autenticación con OAuth" → @builder + safe-implementation
# "revisame los cambios antes de commit" → @reviewer
# "busca errores de seguridad"         → @security-auditor
```

### Modo Comandos (desde terminal)

```bash
oc analyze ~/proyecto           # @architect + project-map
oc plan "nueva feature"         # @planner
oc build "implementar X"        # @builder + test-first
oc review                       # @reviewer + precommit-review
oc secure                       # @security-auditor
oc docs                         # @docs-writer
oc devops "crear Dockerfile"    # @devops
oc oncall                       # @oncall
```

### Workflows Automáticos

```bash
oc --workflow bug-hunt ~/proyecto              # 5 fases
oc --workflow document ~/proyecto              # 3 fases
oc --workflow feature "add auth" ~/api         # 4 fases
oc --workflow new-project "mi-api"             # 4 fases
oc --workflow debug "descripción del error"    # 3 fases
```

---

## Actualización

Volver a correr el instalador aplica la última versión con backup automático:

```bash
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
```

O manualmente:

```bash
git clone --depth 1 https://github.com/isnardokun/opencode-global-config.git /tmp/oc-update
for d in agents skills profiles plugins hooks memory souls; do
    cp -r "/tmp/oc-update/$d" ~/.config/opencode/
done
cp /tmp/oc-update/AGENTS.md /tmp/oc-update/CLAUDE.md ~/.config/opencode/
cp /tmp/oc-update/oc ~/.local/bin/oc
rm -rf /tmp/oc-update
```

---

## Desinstalación

```bash
# Restaurar backup si existe
backup=$(ls -d ~/.config/opencode.backup.* 2>/dev/null | sort | tail -1)
if [ -n "$backup" ]; then
    rm -rf ~/.config/opencode
    cp -r "$backup" ~/.config/opencode
    echo "Restaurado desde: $backup"
fi

# O eliminar completamente
rm -rf ~/.config/opencode
rm -f ~/.local/bin/oc

# Limpiar PATH (editar manualmente ~/.bashrc, ~/.zshrc, o ~/.bash_profile)
```

---

## Solución de Problemas

### `command not found: oc`

```bash
export PATH="$HOME/.local/bin:$PATH"
which oc
# Si funciona, agregar la línea a tu shell config permanentemente
```

### `No such file or directory: AGENTS.md`

```bash
ls ~/.config/opencode/AGENTS.md
# Si no existe, reinstalar:
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
```

### `opencode.json` no carga los agentes

```bash
cat ~/.config/opencode/opencode.json
# Verificar que las rutas en "instructions" y "plugin" son absolutas (no ~)
# Si contienen ~, regenerar:
cat > ~/.config/opencode/opencode.json << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "permission": { "skill": { "*": "allow" } },
  "instructions": ["${HOME}/.config/opencode/AGENTS.md"],
  "plugin":       ["${HOME}/.config/opencode/plugins/safety-guard.js"]
}
EOF
```

### Conflictos con configuración anterior

```bash
cp -r ~/.config/opencode ~/.config/opencode.backup.$(date +%Y%m%d)
rm -rf ~/.config/opencode
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
```

### macOS: `oc` no encontrado después de instalar

En macOS con zsh (default desde Catalina):

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### fzf no instalado (solo para `oc --interactive`)

```bash
# Ubuntu/Debian
sudo apt install fzf

# Fedora/RHEL
sudo dnf install fzf

# macOS
brew install fzf

# Arch
sudo pacman -S fzf
```
