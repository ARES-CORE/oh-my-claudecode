#!/usr/bin/env bash
# Instala oh-my-claudecode desde el paquete offline como plugin local de Claude Code.
# Ejecutar como el USUARIO que usará Claude Code (no root), desde el paquete extraído:
#   tar -xzf oh-my-claudecode-*-bundle.tar.gz && oh-my-claudecode/deploy-cluster/install-offline.sh
#
# Variables opcionales:
#   PREFIX            destino del plugin              (def: ~/.local/share/oh-my-claudecode)
#
# Las configuraciones y skills privadas NO viven en este repositorio: se
# instalan aparte con el kit del clúster (install-kit.sh), que solo existe en el host.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$HERE/.." && pwd)"
PREFIX="${PREFIX:-$HOME/.local/share/oh-my-claudecode}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

command -v node >/dev/null || { echo "✗ Node.js 20+ requerido"; exit 1; }
[ "$(node -p 'process.versions.node.split(".")[0]')" -ge 20 ] || { echo "✗ Node.js 20+ requerido"; exit 1; }

echo "→ Copiando plugin a $PREFIX"
mkdir -p "$PREFIX"
cp -a "$SRC/." "$PREFIX/"
node "$PREFIX/bridge/cli.cjs" --version >/dev/null && echo "✔ CLI omc operativo"

if command -v claude >/dev/null; then
  echo "→ Registrando marketplace local (sin GitHub)"
  claude plugin marketplace add "$PREFIX" || true
  claude plugin install oh-my-claudecode@omc || true
else
  echo "⚠ 'claude' no está en PATH. Luego ejecuta:"
  echo "    claude plugin marketplace add $PREFIX"
  echo "    claude plugin install oh-my-claudecode@omc"
fi

echo "✔ Listo. Verifica con: claude plugin list"
