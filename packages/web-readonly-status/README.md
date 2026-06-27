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

## Install Dependencies

From the monorepo root:

```bash
bun install
```

This repo uses Bun workspaces at the root, so package dependencies are expected to be installed from the monorepo root rather than inside this folder alone.

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

If you want to serve the built files with another static server, build first and then serve the `dist` directory with your preferred static host.

This package does not claim Vite dev-server browser sanity because Vite dev mode injects HMR-related behavior that is outside the production-only sanity target.

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
