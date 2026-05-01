# Instalación

## Requisitos

- [OpenCode CLI](https://opencode.ai) instalado
- Git
- Linux/macOS/Fedora (compatibilidad verificada en Fedora 43)

## Instalación Rápida

```bash
git clone https://github.com/isnardokun/opencode-global-config.git ~/.config/opencode
```

O copia manual:

```bash
# Clonar o copiar contenido en ~/.config/opencode/
cp -r agents/ ~/.config/opencode/
cp -r skills/ ~/.config/opencode/
cp -r plugins/ ~/.config/opencode/
cp opencode.json ~/.config/opencode/
cp AGENTS.md ~/.config/opencode/
```

## Instalar Comando Global `oc`

```bash
# Crear directorio bin si no existe
mkdir -p ~/.local/bin

# Copiar script oc
cp oc ~/.local/bin/
chmod +x ~/.local/bin/oc

# Agregar al PATH (si no está)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Verificar Instalación

```bash
# Verificar comando oc
command -v oc

# Verificar configuración
find ~/.config/opencode -maxdepth 3 -type f | sort
```

## Uso

```bash
# Análisis de proyecto
oc "@architect analiza este proyecto"

# Planificación
oc "@planner divide esta tarea en fases"

# Implementación
oc "@builder implementa el cambio X"

# Revisión
oc "@reviewer revisa los cambios"

# Seguridad
oc "@security-auditor busca vulnerabilidades"

# Documentación
oc "@docs-writer genera README"

# DevOps
oc "@devops crea dockerfile"

# Producción
oc "@oncall diagnostica el problema"
```

## Desinstalación

```bash
rm -rf ~/.config/opencode
rm ~/.local/bin/oc
# Remover línea de PATH de ~/.bashrc
```

## Soporte

Abre un issue en el repositorio para reportar problemas o sugerir mejoras.