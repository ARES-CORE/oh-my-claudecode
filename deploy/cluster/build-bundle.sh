#!/usr/bin/env bash
# Empaqueta oh-my-claudecode como plugin OFFLINE para el clúster.
# Se ejecuta en una máquina de build con internet y Node 20+.
# El destino solo necesita Node 20+ y Claude Code: no usa GitHub ni el registro npm.
#
# Uso: deploy/cluster/build-bundle.sh [salida.tar.gz]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(node -p "require('$ROOT/package.json').version")"
OUT="${1:-$ROOT/oh-my-claudecode-$VERSION-bundle.tar.gz}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/oh-my-claudecode"
mkdir -p "$STAGE"

echo "→ Copiando artefactos precompilados (dist/ y bridge/ ya vienen compilados)"
# Mismo contenido que publica npm ("files" en package.json).
( cd "$ROOT" && node -e '
  const p = require("./package.json");
  for (const f of new Set(p.files)) console.log(f);
' | while read -r f; do [ -e "$ROOT/$f" ] && cp -r --parents "$f" "$STAGE/" || true; done )
cp "$ROOT/package.json" "$ROOT/package-lock.json" "$STAGE/"
find "$STAGE" -name '__pycache__' -prune -exec rm -rf {} +
find "$STAGE" -name '__tests__' -prune -exec rm -rf {} +

echo "→ Instalando SOLO dependencias de ejecución (sin devDependencies)"
( cd "$STAGE" && npm ci --omit=dev --no-audit --no-fund )

echo "→ Podando binarios de otra libc y fuentes de compilación"
if ldd --version 2>&1 | grep -qi musl; then DROP=gnu; else DROP=musl; fi
find "$STAGE/node_modules/@ast-grep" "$STAGE/node_modules/@img" -maxdepth 1 \
  -name "*-$DROP*" -exec rm -rf {} + 2>/dev/null || true
if [ "$DROP" = musl ]; then
  rm -rf "$STAGE/node_modules/@img/"*linuxmusl*
else
  rm -rf "$STAGE/node_modules/@img/sharp-linux-"* "$STAGE/node_modules/@img/sharp-libvips-linux-"*
fi
rm -rf "$STAGE/node_modules/better-sqlite3/deps" "$STAGE/node_modules/better-sqlite3/src"

cp -r "$ROOT/deploy/cluster" "$STAGE/deploy-cluster"
rm -f "$STAGE/deploy-cluster/build-bundle.sh"

tar -C "$WORK" -czf "$OUT" oh-my-claudecode
( cd "$(dirname "$OUT")" && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256" )
echo "✔ Paquete: $OUT (+ .sha256)"
echo "  Módulos nativos (better-sqlite3, @ast-grep/napi) compilados para $(uname -m)."
echo "  Construye en la misma arquitectura/libc que el destino."
