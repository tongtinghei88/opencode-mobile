# Web Read-Only Status Daily Launch Pack

This launch pack starts, stops, and checks the accepted Web Read-Only Status MVP
from Windows PowerShell 5.1.

## Daily Commands

From the repository root:

```powershell
.\packages\web-readonly-status\scripts\start-readonly-status.ps1
.\packages\web-readonly-status\scripts\status-readonly-status.ps1 -TimeoutSec 5
.\packages\web-readonly-status\scripts\stop-readonly-status.ps1
```

Equivalent Bun aliases:

```powershell
bun run --cwd packages/web-readonly-status launch:start
bun run --cwd packages/web-readonly-status launch:status -- -TimeoutSec 5
bun run --cwd packages/web-readonly-status launch:stop
```

## URLs

- LAN app URL: `http://192.168.50.202:4173/`
- Approved adapter endpoint: `http://192.168.50.202:8790/api/local/v0/summary`

Open the LAN app URL from phones or computers on the same Wi-Fi/LAN.

## Requirements

- This PC must currently hold IP `192.168.50.202`.
- Ports `4173` and `8790` must be free before start.
- `node` and `bun` must be available on PATH.
- The existing adapter file must exist at
  `C:\Codex-Recovery\opencode-local-adapter-spike3O\server.mjs`.

The scripts store PID files and logs outside the repo under
`%TEMP%\web-readonly-status\`.
The status script supports `-TimeoutSec` and returns bounded local status checks.

## Safety Behavior

- The start script runs a production build before serving.
- The app is served with production preview/static serving only.
- The scripts do not use the Vite dev server.
- The scripts do not start `opencode serve`.
- The scripts do not add firewall rules.
- The scripts do not modify the backend repo.
- The scripts do not modify adapter server code.
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
