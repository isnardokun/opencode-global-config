# Instalación

## Requisitos

- [OpenCode CLI](https://opencode.ai) instalado
- Git
- fzf (para modo interactivo)
- Linux/macOS (Fedora 43 compatible)

## Instalación Rápida

```bash
# Clonar repositorio
git clone https://github.com/isnardokun/opencode-global-config.git /tmp/opencode-config

# Copiar configuración global
cp -r /tmp/opencode-config/* ~/.config/opencode/

# Instalar comando oc y aliases
mkdir -p ~/.local/bin
cp /tmp/opencode-config/oc ~/.local/bin/
chmod +x ~/.local/bin/oc

# Crear symlinks para comandos rápidos
cd ~/.local/bin
ln -sf oc oc-analyze
ln -sf oc oc-plan
ln -sf oc oc-build
ln -sf oc oc-review
ln -sf oc oc-secure
ln -sf oc oc-docs
ln -sf oc oc-devops
ln -sf oc oc-oncall

# Agregar al PATH (si no existe)
grep -q '~/.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Instalar fzf si no está
dnf install -y fzf
```

## Verificar Instalación

```bash
# Verificar comandos
command -v oc
oc --help

# Verificar configuración
find ~/.config/opencode -maxdepth 3 -type f | sort

# Probar modo interactivo
oc --interactive
```

## Instalación de Git Hooks (opcional)

```bash
# Para un proyecto existente
cd ~/mi-proyecto
oc --init

# O manualmente
cp ~/.config/opencode/hooks/pre-commit ~/.git/hooks/
chmod +x ~/.git/hooks/pre-commit
```

## Actualización

```bash
cd ~/.config/opencode
git pull origin main
```

## Desinstalación

```bash
# Remover configuración
rm -rf ~/.config/opencode

# Remover comando
rm ~/.local/bin/oc
rm ~/.local/bin/oc-*

# Remover línea de PATH de ~/.bashrc y ~/.zshrc
# (editar manualmente)
```

## Solución de Problemas

### "command not found: oc"

```bash
# Verificar que ~/.local/bin está en PATH
echo $PATH | grep -q '.local/bin' && echo "OK" || echo "Missing"

# Agregar manualmente si falta
export PATH="$HOME/.local/bin:$PATH"
```

### "fzf not found"

```bash
# Fedora
sudo dnf install fzf

# macOS
brew install fzf
```

### Permiso denegado en ~/.local/bin/oc

```bash
chmod +x ~/.local/bin/oc
```