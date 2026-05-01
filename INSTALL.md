# Instalación

## Requisitos

- [OpenCode CLI](https://opencode.ai) instalado
- Git
- fzf (para modo interactivo)
- Linux/macOS (Fedora 43+ compatible)

## Instalación Rápida (One-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
```

## Instalación Manual

```bash
# 1. Clonar repositorio
git clone https://github.com/isnardokun/opencode-global-config.git /tmp/opencode-config

# 2. Respaldar configuración existente
[ -d ~/.config/opencode ] && cp -r ~/.config/opencode ~/.config/opencode.backup.$(date +%Y%m%d-%H%M%S)

# 3. Instalar configuración global (sobrescribe agentes, skills, profiles)
cp -r /tmp/opencode-config/* ~/.config/opencode/

# 4. Instalar comando oc (wrapper con workflows)
mkdir -p ~/.local/bin
cp /tmp/opencode-config/oc ~/.local/bin/oc
chmod +x ~/.local/bin/oc

# 5. Agregar al PATH si no existe
grep -q '~/.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 6. Instalar fzf (modo interactivo)
dnf install -y fzf 2>/dev/null || brew install fzf 2>/dev/null || echo "Instala fzf manualmente"
```

## Qué se instala

### Agentes (reemplazan los internos de OpenCode)
| Agente | Descripción | Permisos |
|--------|-------------|----------|
| `@architect` | Análisis de arquitectura y riesgos | read-only |
| `@planner` | Planificación con fases verificables | read-only |
| `@builder` | Implementación con Karpathy principles | edit + bash(ask) |
| `@reviewer` | Code review con precommit-review | read-only |
| `@security-auditor` | Auditoría de vulnerabilidades | read-only |
| `@docs-writer` | Documentación técnica | edit |
| `@devops` |Infraestructura y CI/CD | edit + bash |
| `@oncall` | Diagnóstico de producción | bash(ask) |

### Skills
- `project-map` - Análisis de estructura de proyecto
- `safe-implementation` - Cambios mínimos y verificables
- `test-first` - Goal-Driven Execution
- `precommit-review` - Revisión de diff antes de commit
- `memory-retrieval` - 3-layer progressive disclosure
- `docs-writer` - Documentación técnica

### Sistema de Memoria
- 3-layer retrieval: search → timeline → get
- Observation format con tipos: bugfix, feature, decision, note, config
- Privacy tags para contenido sensible

### Perfiles (7 niveles de confianza)
`deny` → `plan` → `review` → `default` → `auto` → `trusted` → `devops`

### Intent Mapping (Natural Language → Agente)
Ya no necesitas comandos. Solo dime:
- "analiza el proyecto" → @architect + project-map
- "implementa auth con JWT" → @builder + safe-implementation
- "revisame el código" → @reviewer + precommit-review
- "busca vulnerabilidades" → @security-auditor
- "genera documentación" → @docs-writer
- "diagnostica el error en prod" → @oncall

## Verificar Instalación

```bash
# Verificar que todo está cargado
opencode debug config | grep -A2 instructions
opencode agent list | grep -E "architect|builder|planner|reviewer|security|docs|devops|oncall"

# Probar intent mapping
opencode run "analiza /home/tu/proyecto y dime el stack tecnológico"

# Probar workflow
oc --workflow document /home/tu/proyecto
```

## Uso

### Modo Natural (recomendado)
```bash
opencode
# Luego escribe:
"analiza el proyecto actual"
"implementa autenticación con Google OAuth"
"revisame los cambios antes de commit"
"busca errores de seguridad"
```

### Modo Comandos
```bash
oc analyze ~/proyecto           # @architect + project-map
oc plan "nueva feature"         # @planner
oc build "implementar X"       # @builder + test-first
oc review                       # @reviewer + precommit-review
oc secure                       # @security-auditor
oc docs                         # @docs-writer
oc devops "crear Dockerfile"    # @devops
oc oncall                       # @oncall
```

### Workflows Automáticos
```bash
oc --workflow bug-hunt ~/proyecto     # 5 fases
oc --workflow document ~/proyecto     # 3 fases
oc --workflow feature "auth" ~/api    # 4 fases
oc --workflow new-project "mi-api"    # 4 fases
oc --workflow debug "fix error"       # 3 fases
```

## Actualización

```bash
cd ~/.config/opencode
git pull origin main
```

## Desinstalación

```bash
# Restaurar backup si existe
[ -d ~/.config/opencode.backup.* ] && cp -r ~/.config/opencode.backup.*/* ~/.config/opencode/

# O remover completamente
rm -rf ~/.config/opencode
rm -f ~/.local/bin/oc
rm -f ~/.local/bin/oc-*

# Limpiar PATH del bashrc (editar manualmente)
```

## Solución de Problemas

### "command not found: oc"
```bash
export PATH="$HOME/.local/bin:$PATH"
which oc
```

### "No such file or directory: AGENTS.md"
```bash
# Verificar que AGENTS.md existe
ls -la ~/.config/opencode/AGENTS.md

# Si no existe, reinstalar
cp /tmp/opencode-config/AGENTS.md ~/.config/opencode/
```

### Conflictos con configuración anterior
```bash
# Respaldar y limpiar
cp -r ~/.config/opencode ~/.config/opencode.backup.$(date +%Y%m%d)
rm -rf ~/.config/opencode
# Reinstalar
cp -r /tmp/opencode-config/* ~/.config/opencode/
```