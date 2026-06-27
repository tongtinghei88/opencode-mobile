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

## Verification

- Review the diff and confirm changes stay under `packages/web-readonly-status`.
- Run production build and typecheck if dependencies are available.
- Use production build or static serving for sanity checks, not the Vite dev server.
- If the adapter request fails, confirm the app fails closed and does not fall back to another endpoint.
