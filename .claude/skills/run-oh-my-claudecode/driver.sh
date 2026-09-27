#!/usr/bin/env bash
# Driver de oh-my-claudecode para agentes. Ejecutar desde la raíz del repo.
# Usa un HOME aislado (.omc-run/home) para no tocar la config real.
#   setup                     npm ci (deps de ejecución, build y test)
#   build                     npm run build (regenera dist/ y bridge/)
#   cli                       smoke del CLI: versión, config, bloqueos del modo estricto
#   mcp list                  lista las herramientas del MCP del plugin (bridge/mcp-server.cjs)
#   mcp call <tool> ['json']  llama una herramienta MCP dentro de un proyecto temporal
#   security [strict]         política de seguridad efectiva (import directo de dist/)
#   test [ficheros...]        vitest run (por defecto: tests de auto-update y security)
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
HERE="$ROOT/.claude/skills/run-oh-my-claudecode"
RUN="$ROOT/.omc-run"; mkdir -p "$RUN/home" "$RUN/proj"
[ -d "$RUN/proj/.git" ] || git -C "$RUN/proj" init -q
export HOME="$RUN/home"
CLI=(node "$ROOT/bridge/cli.cjs")

case "${1:-}" in
  setup) HOME=${REAL_HOME:-/root} npm ci --no-audit --no-fund ;;
  build) npm run build ;;
  cli)
    fail=0
    "${CLI[@]}" --version
    "${CLI[@]}" config | head -3
    out=$(OMC_SECURITY=strict "${CLI[@]}" ask codex "hola" 2>&1 || true)
    grep -q "blocked by security policy" <<<"$out" && echo "ok   ask codex bloqueado (disableExternalLLM)" || { echo "FAIL ask codex no bloqueado"; fail=1; }
    out=$(OMC_SECURITY=strict "${CLI[@]}" update --check 2>&1 || true)
    grep -q "No network request was made" <<<"$out" && echo "ok   update bloqueado sin red (disableAutoUpdate)" || { echo "FAIL update salió a la red: $out"; fail=1; }
    out=$(echo '{"session_id":"drv","cwd":"'"$RUN/proj"'","hook_event_name":"SessionStart"}' | \
      OMC_SECURITY=strict CLAUDE_CONFIG_DIR="$HOME/.claude" CLAUDE_PLUGIN_ROOT="$ROOT" \
      node --import "$HERE/fetchlog.mjs" "$ROOT/scripts/session-start.mjs" 2>&1 >/dev/null | grep FETCH || true)
    [ -z "$out" ] && echo "ok   session-start sin red (disableAutoUpdate)" || { echo "FAIL session-start salió a la red: $out"; fail=1; }
    exit $fail ;;
  mcp)
    shift
    cd "$RUN/proj" && python3 "$HERE/mcp_call.py" node "$ROOT/bridge/mcp-server.cjs" -- "$@" ;;
  security)
    [ "${2:-}" = strict ] && export OMC_SECURITY=strict
    node --input-type=module -e "const m=await import('$ROOT/dist/lib/security-config.js'); console.log(JSON.stringify(m.getSecurityConfig(), null, 2))" ;;
  test)
    shift; HOME=${REAL_HOME:-/root} npx vitest run "${@:-src/__tests__/auto-update.test.ts}" ;;
  *) sed -n '2,12p' "$0"; exit 2 ;;
esac
