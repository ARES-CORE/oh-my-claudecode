---
name: run-oh-my-claudecode
description: Run, build, test or smoke-test oh-my-claudecode (the omc CLI and the plugin's MCP server). Use to exercise the CLI, call MCP tools (notepad, state, LSP, ast-grep, memory) over stdio, check the effective security policy, or verify that strict mode blocks external LLMs and network updates.
---

# Run oh-my-claudecode

Claude Code plugin + `omc` CLI. `dist/` and `bridge/` are committed build output,
so the CLI and MCP server run straight from the checkout. Agents drive it with
`.claude/skills/run-oh-my-claudecode/driver.sh`, which uses an isolated `HOME`
(`.omc-run/home`) and a throwaway git project (`.omc-run/proj`) so it never
touches the real Claude config. Paths are relative to the repo root.

## Prerequisites

Node 20+, git, python3 (for the MCP client).

## Build

```bash
.claude/skills/run-oh-my-claudecode/driver.sh setup    # npm ci
.claude/skills/run-oh-my-claudecode/driver.sh build    # regenerates dist/ + bridge/
```

Only needed after editing `src/`; commit the regenerated `dist/` and `bridge/`.

## Run (agent path)

```bash
D=.claude/skills/run-oh-my-claudecode/driver.sh
$D cli                                              # version, config, strict-mode blocks (ask, update, session-start)
$D mcp list                                         # 49 local tools
$D mcp call notepad_write_working '{"content":"x"}' # real tool call in .omc-run/proj
$D mcp call notepad_read
$D security strict                                  # effective policy under OMC_SECURITY=strict
```

`mcp_call.py` is a generic stdio MCP client: `mcp_call.py <server cmd...> -- list`
or `-- call <tool> '<json>'`. It works for any MCP server.

## Direct invocation

The policy module can be imported directly, and so can any other `dist/` module:

```bash
node --input-type=module -e "const m=await import('./dist/lib/security-config.js'); console.log(m.getSecurityConfig())"
```

## Test

```bash
.claude/skills/run-oh-my-claudecode/driver.sh test                    # auto-update tests (19)
.claude/skills/run-oh-my-claudecode/driver.sh test src/__tests__/     # or any path
npx vitest run                                                        # full: 8956 passed, 8 skipped, ~2 min
```

## No external egress

Set in `~/.config/claude-omc/config.jsonc` (or `OMC_SECURITY=strict` for everything):

```jsonc
{ "security": { "disableAutoUpdate": true, "disableRemoteMcp": true, "disableExternalLLM": true } }
```

- `disableExternalLLM`: `omc ask codex|gemini` is refused and only `claude` is allowed.
- `disableAutoUpdate`: blocks the silent auto-update, `omc update` (exit 1, no network)
  **and** the npm registry check in `scripts/session-start.mjs` (it used to query
  `registry.npmjs.org` on every session start and announce upstream versions).
- Updates come from `github:ARES-CORE/oh-my-claudecode` (the fork) when allowed,
  never from the upstream npm package.

## Gotchas

- The MCP server stores state per project (`.omc/` in the cwd); the driver runs it
  inside `.omc-run/proj`, which is a git repo on purpose.
- `omc ask codex` under strict mode is refused with an uncaught `Error` and a Node
  stack trace. The block works; the message is `blocked by security policy`.
- Before this change `omc update --check` still called GitHub under strict mode
  (`403 Forbidden` behind the sandbox proxy); now it is refused locally.
- `omc config` does not print the `security` section; use `driver.sh security`.
- To detect network calls from any script: `node --import ./.claude/skills/run-oh-my-claudecode/fetchlog.mjs <script>`,
  which prints `FETCH <url>` to stderr for every `fetch()`.
- `.gitignore` ignores `.claude/*` except `.claude/skills/`.

## Troubleshooting

- `Update failed: Failed to fetch release info: 403 Forbidden` → a network update was
  attempted; enable `disableAutoUpdate` or use the offline bundle (`deploy/cluster/`).
