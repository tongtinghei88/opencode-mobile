# Web Read-Only Status

This package contains a small browser-only Vite React app for viewing the approved local adapter summary endpoint in a read-only way.

It is intentionally isolated from the main `packages/web` runtime and exists as a minimal status milestone under `packages/web-readonly-status`.

## Purpose

- Show adapter and repository summary information from one approved browser request.
- Keep the UI read-only and fail closed when the adapter is unavailable or the fixed endpoint is rejected.
- Provide a production-buildable status page without introducing server code, auth flows, chat features, or write actions.

## Approved Endpoint

The app is limited to one executable request:

`GET http://192.168.50.202:8790/api/local/v0/summary`

The request is sent with:

- `method: "GET"`
- `credentials: "omit"`

## Safety Boundary

This package must preserve these rules:

- Only the fixed summary endpoint above may be called.
- Defensive URL validation must remain enabled.
- No direct executable browser access to port `4096`.
- No `POST`, `PUT`, `PATCH`, or `DELETE`.
- No auth headers, cookies, bearer tokens, provider keys, or embedded credentials.
- No `localStorage` or `sessionStorage`.
- No `WebSocket`, `EventSource`, `SSE`, or polling.
- No chat, agent, terminal, git, provider, or filesystem UI.
- No server code.

## LAN Caveat — Hard-Coded Host and Port

The approved endpoint is hard-coded in source:

```
http://192.168.50.202:8790/api/local/v0/summary
```

**Before opening this page, verify:**

- This PC currently holds IP address `192.168.50.202`.
- The read-only local adapter is listening on port `8790`.

**Warning:** Changing the approved host or port is a **safety-boundary change** that
requires a separate review and cannot be done by editing only `realAdapter.ts` without
also rerunning the full production browser sanity check.

## Fast Local Run

Daily use on Windows PowerShell 5.1:

```powershell
.\packages\web-readonly-status\scripts\start-routine-local.ps1 -OpenCodePassword "choose-a-local-password"
.\packages\web-readonly-status\scripts\status-routine-local.ps1 -TimeoutSec 5
.\packages\web-readonly-status\scripts\stop-routine-local.ps1
```

Read-only-only variants:

```powershell
.\packages\web-readonly-status\scripts\start-readonly-status.ps1
.\packages\web-readonly-status\scripts\status-readonly-status.ps1 -TimeoutSec 5
.\packages\web-readonly-status\scripts\stop-readonly-status.ps1
```

The daily launch pack serves the app at `http://192.168.50.202:4173/` and uses
the approved adapter endpoint
`http://192.168.50.202:8790/api/local/v0/summary`. It requires this PC to hold
IP `192.168.50.202`, requires ports `4173` and `8790`, stores PID files and logs
under `%TEMP%\web-readonly-status\`, adds no firewall rules, does not start
`opencode serve`, and does not modify backend repo or adapter code. The status
script supports `-TimeoutSec` so local diagnostics return promptly even when a
service is down or a local HTTP request stalls.

The routine launcher adds one convenience layer above that pack:

- `start-routine-local.ps1` can start the read-only status app, the local-only OpenCode UI, or both.
- `status-routine-local.ps1` checks both systems without hanging indefinitely.
- `stop-routine-local.ps1` stops only the managed PID-file-backed processes and then prints final port status.

The routine scripts preserve the same safety boundary:

- Phone or LAN devices should open only `http://192.168.50.202:4173/`.
- The approved adapter endpoint remains `http://192.168.50.202:8790/api/local/v0/summary`.
- OpenCode remains PC-local only at `http://127.0.0.1:4096/`.
- OpenCode Basic Auth username is `opencode`.
- OpenCode password is the value supplied to `-OpenCodePassword` on the routine start script or `-Password` on the direct OpenCode helper.
- No firewall rules are added.
- No backend repo or adapter code is modified.
- No LAN/mobile OpenCode access is enabled.

See `LAUNCH_PACK.md` for daily commands and troubleshooting.

## Local OpenCode UI On This PC Only

The read-only status app above is separate from OpenCode itself.

If you want to open the actual OpenCode browser UI on this PC only, use the
local-only helper:

```powershell
.\packages\web-readonly-status\scripts\start-opencode-local.ps1 -Password "choose-a-local-password"
.\packages\web-readonly-status\scripts\stop-opencode-local.ps1
```

Equivalent Bun aliases:

```powershell
bun run --cwd packages/web-readonly-status opencode:local:start -- -Password "choose-a-local-password"
bun run --cwd packages/web-readonly-status opencode:local:status -- -TimeoutSec 5
bun run --cwd packages/web-readonly-status opencode:local:stop
```

Open this URL on the same PC:

`http://127.0.0.1:4096/`

Important notes:

- This helper binds OpenCode only to `127.0.0.1`.
- It does not bind to `192.168.50.202` or `0.0.0.0`.
- It does not add firewall rules.
- It does not start the read-only status launch pack.
- With `-Password`, the browser uses HTTP Basic Auth.
- The tested username is `opencode`; use the password you supplied to `-Password`.
- PID files and logs stay outside the repo under `%TEMP%\opencode-local\`.

Equivalent Bun aliases for the routine launcher:

```powershell
bun run --cwd packages/web-readonly-status routine:start -- -OpenCodePassword "choose-a-local-password"
bun run --cwd packages/web-readonly-status routine:status -- -TimeoutSec 5
bun run --cwd packages/web-readonly-status routine:stop
```

Install dependencies once from the monorepo root:

```bash
bun install
```

Start the adapter (read-only, no opencode serve needed):

```bash
HOST=192.168.50.202 PORT=8790 node /path/to/opencode-local-adapter-spike3O/server.mjs
```

Build and preview in two commands:

```bash
bun run --cwd packages/web-readonly-status build
bun run --cwd packages/web-readonly-status preview
```

Open `http://localhost:4173` in a browser. The page connects to
`http://192.168.50.202:8790/api/local/v0/summary` on load.

## Useful Commands

From the monorepo root:

```bash
bun run --cwd packages/web-readonly-status build
bun run --cwd packages/web-readonly-status preview
bun run --cwd packages/web-readonly-status typecheck
```

From this package directory:

```bash
bun run build
bun run preview
bun run typecheck
```

## Production Build

Create the static production bundle with:

```bash
bun run --cwd packages/web-readonly-status build
```

The output is written to `packages/web-readonly-status/dist`.

## Production Preview or Static Serving

To preview the built files with Vite's production preview server:

```bash
bun run --cwd packages/web-readonly-status preview
```

This starts a preview server on `http://localhost:4173` by default.

If you want to serve the built files with another static server, build first and then serve the `dist` directory with your preferred static host.

**Use production preview (not dev server) for all browser sanity checks.**
This package does not use Vite dev-server for sanity because Vite dev mode injects
HMR-related behavior that is outside the production-only sanity target.

## Expected Behavior

When the adapter is available:

- The page loads the summary from the approved endpoint.
- The UI shows adapter and repository status details.
- The page remains read-only.

When the adapter is unavailable or the request fails:

- The page shows an error panel.
- The app fails closed.
- The app does not fall back to other endpoints.

## Maintenance Notes

- Keep this package isolated from the full web runtime.
- Treat `packages/web-readonly-status/src/adapter/realAdapter.ts` and `packages/web-readonly-status/src/adapter/realAdapterClient.ts` as the safety boundary.
- Re-run a production build after documentation or script changes so the package stays easy to maintain on the user-owned fork mainline.
