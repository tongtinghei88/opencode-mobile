# Web Read-Only Status Daily Launch Pack

This launch pack starts, stops, and checks the accepted Web Read-Only Status MVP
from Windows PowerShell 5.1.

## Daily Commands

From the repository root:

```powershell
.\packages\web-readonly-status\scripts\start-routine-local.ps1 -OpenCodePassword "choose-a-local-password"
.\packages\web-readonly-status\scripts\status-routine-local.ps1 -TimeoutSec 5
.\packages\web-readonly-status\scripts\stop-routine-local.ps1
```

Read-only-only commands remain available:

```powershell
.\packages\web-readonly-status\scripts\start-readonly-status.ps1
.\packages\web-readonly-status\scripts\status-readonly-status.ps1 -TimeoutSec 5
.\packages\web-readonly-status\scripts\stop-readonly-status.ps1
```

Equivalent Bun aliases:

```powershell
bun run --cwd packages/web-readonly-status routine:start -- -OpenCodePassword "choose-a-local-password"
bun run --cwd packages/web-readonly-status routine:status -- -TimeoutSec 5
bun run --cwd packages/web-readonly-status routine:stop
```

Read-only-only Bun aliases:

```powershell
bun run --cwd packages/web-readonly-status launch:start
bun run --cwd packages/web-readonly-status launch:status -- -TimeoutSec 5
bun run --cwd packages/web-readonly-status launch:stop
```

Separate local-only OpenCode UI helper on this PC:

```powershell
.\packages\web-readonly-status\scripts\start-opencode-local.ps1 -Password "choose-a-local-password"
.\packages\web-readonly-status\scripts\status-opencode-local.ps1 -TimeoutSec 5
.\packages\web-readonly-status\scripts\stop-opencode-local.ps1
```

Equivalent Bun aliases:

```powershell
bun run --cwd packages/web-readonly-status opencode:local:start -- -Password "choose-a-local-password"
bun run --cwd packages/web-readonly-status opencode:local:status -- -TimeoutSec 5
bun run --cwd packages/web-readonly-status opencode:local:stop
```

## URLs

- LAN app URL: `http://192.168.50.202:4173/`
- Approved adapter endpoint: `http://192.168.50.202:8790/api/local/v0/summary`
- Local OpenCode URL on this PC only: `http://127.0.0.1:4096/`

Open the LAN app URL from phones or computers on the same Wi-Fi/LAN.
Open the OpenCode URL only on this PC.

## Requirements

- This PC must currently hold IP `192.168.50.202`.
- Ports `4173` and `8790` must be free before start.
- `node` and `bun` must be available on PATH.
- The existing adapter file must exist at
  `C:\Codex-Recovery\opencode-local-adapter-spike3O\server.mjs`.

The scripts store PID files and logs outside the repo under
`%TEMP%\web-readonly-status\`.
The status script supports `-TimeoutSec` and returns bounded local status checks.
The OpenCode local helper stores PID files and logs under `%TEMP%\opencode-local\`.

## Safety Behavior

- The start script runs a production build before serving.
- The app is served with production preview/static serving only.
- The scripts do not use the Vite dev server.
- The scripts do not start `opencode serve`.
- The scripts do not add firewall rules.
- The scripts do not modify the backend repo.
- The scripts do not modify adapter server code.
- The routine scripts do not expose OpenCode to LAN.
- The routine scripts do not bind OpenCode to `192.168.50.202` or `0.0.0.0`.
- The scripts fail closed if the IP is wrong, a required port is busy, the build
  fails, the adapter cannot start, or the preview cannot start.

The app runtime still permits only:

`GET http://192.168.50.202:8790/api/local/v0/summary`

with `credentials: "omit"` and defensive URL validation.

## Troubleshooting

Phone cannot open page:

Confirm the phone is on the same Wi-Fi/LAN as this PC, run the status script,
and open `http://192.168.50.202:4173/`.

IP changed:

The start script refuses to run if this PC does not hold `192.168.50.202`.
Restore the expected LAN address or perform a separate reviewed host/port change.

Port busy:

Run the stop script first. If the port remains busy, use the status output to
identify whether another local process is already listening.

Adapter unreachable:

Run the status script and inspect `%TEMP%\web-readonly-status\adapter.log`.
The adapter endpoint must be reachable at
`http://192.168.50.202:8790/api/local/v0/summary`.

Status appears slow:

Run `.\packages\web-readonly-status\scripts\status-readonly-status.ps1 -TimeoutSec 5`.
The script now reports `LISTENING`, `NOT LISTENING`, `TIME_WAIT ONLY`,
`HTTP OK`, `HTTP FAILED`, `HTTP TIMEOUT`, `PID FILE MISSING`, and
`STALE PID FILE` without waiting indefinitely for local status checks.

Windows firewall or network profile issue:

These scripts do not add firewall rules. If another device cannot reach the app
while local checks pass, review Windows Firewall and whether the active network
profile permits same-LAN access.

Same Wi-Fi/LAN requirement:

The phone or second computer must be connected to the same local network as this
PC. VPNs or guest networks may block LAN reachability.

## Local OpenCode UI Notes

The OpenCode helper is intentionally separate from the LAN read-only status app.

- Local OpenCode URL: `http://127.0.0.1:4096/`
- Default bind: `127.0.0.1:4096` only
- No LAN bind
- No firewall rule
- Optional password via `-Password`
- Browser auth username: `opencode`

If you supply `-Password`, the browser will require the username above and the
same password value you supplied when the helper started the server.

## Routine Launcher Notes

Use the routine launcher when you want one daily command set for both systems:

- `start-routine-local.ps1 -OpenCodePassword "..."`
- `status-routine-local.ps1 -TimeoutSec 5`
- `stop-routine-local.ps1`

Optional flags:

- `-SkipReadOnlyStatus` starts only local OpenCode.
- `-SkipOpenCode` starts only the read-only status pack.

The routine scripts reuse the existing read-only launch pack and the existing local OpenCode helper.
They do not change the approved read-only endpoint, do not add direct browser access to `:4096`
inside the read-only app, do not add firewall rules, and do not modify backend repo or adapter code.
