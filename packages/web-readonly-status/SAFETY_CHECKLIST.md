# Web Read-Only Status Safety Checklist

Use this checklist before expanding or shipping changes in `packages/web-readonly-status`.

## Boundary

- The only executable endpoint is `GET http://192.168.50.202:8790/api/local/v0/summary`.
- The request keeps `method: "GET"`.
- The request keeps `credentials: "omit"`.
- Defensive URL validation remains enabled.

## Forbidden Additions

- No direct executable `4096` access.
- No `POST`, `PUT`, `PATCH`, or `DELETE`.
- No auth headers, cookies, bearer tokens, provider keys, or embedded credentials.
- No `localStorage` or `sessionStorage`.
- No `WebSocket`, `EventSource`, `SSE`, or polling.
- No chat, agent, terminal, git, provider, or filesystem UI.
- No server code.

## Host / IP / Port Change Policy

- The approved host (`192.168.50.202`) and port (`8790`) are locked in source.
- Changing either value is a **safety-boundary change** — it must not be done without a separate review that covers the new host/port, the associated `assertRealAdapterSummaryUrl` validation, and a full production browser sanity check targeting the updated endpoint.
- Do not change the host or port as part of a UI-only or documentation change.

## Verification

- Review the diff and confirm changes stay under `packages/web-readonly-status`.
- Run production build and typecheck if dependencies are available.
- For daily use, start only with `scripts/start-readonly-status.ps1`, check with `scripts/status-readonly-status.ps1`, and stop with `scripts/stop-readonly-status.ps1`.
- Use `scripts/status-readonly-status.ps1 -TimeoutSec 5` for bounded diagnostics during routine checks.
- Confirm launch logs and PID files stay outside the repo under `%TEMP%\web-readonly-status\`.
- Confirm the launch scripts do not start `opencode serve`, do not add firewall rules, and do not modify backend repo or adapter code.
- If using `start-opencode-local.ps1`, confirm it binds only to `127.0.0.1:4096`, does not add a firewall rule, and remains separate from the read-only status app boundary.
- **After any UI change or network-boundary change, always rerun production browser sanity** using production build + preview/static serving (not the Vite dev server).
- If the adapter request fails, confirm the app fails closed and does not fall back to another endpoint.
- Confirm no `@vite/client`, React Refresh, HMR, `WebSocket`, `EventSource`, `setInterval`, `localStorage`, `sessionStorage`, or executable `:4096` references appear in the built artifacts.
