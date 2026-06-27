# opencode-mobile-fork-mainline Handoff

## ⏯️ 上次做到哪（2026-06-27 — MVP readiness sprint PASS + pushed）

- Final label: `WEB_READONLY_STATUS_FAST_TRACK_MVP_READINESS_PUSHED`
- Branch: `web-app-mainline`
- HEAD: `c8747b5508d87630da470652ce7a2aebf819629d` (`Polish web readonly MVP readiness`)
- Push: `origin/web-app-mainline` at `c8747b5`. `upstream` not pushed.
- Working tree: clean.
- Production browser sanity PASS (desktop + tablet + mobile).

### What changed

Files modified (all under `packages/web-readonly-status`):
- `src/App.tsx` — added LAN readiness panel (host/port/endpoint/4 notes).
- `src/styles.css` — `.lanReadiness`/`.lanNotes` styles; `card header flex-wrap`; responsive 3-col LAN dl at 760px+.
- `README.md` — LAN caveat, fast local run, production preview guidance, safety-boundary warning.
- `SAFETY_CHECKLIST.md` — host/IP/port change policy; browser sanity requirement.

Safety boundary unchanged: only `GET http://192.168.50.202:8790/api/local/v0/summary`, `credentials:"omit"`.

## ➡️ 下一步

- **Immediate next task (interrupted this session):** create annotated tag `web-readonly-status-mvp-v0.1.0` at `c8747b5` and push to `origin`.
  - Tag message: `Web Read-Only Status MVP v0.1.0`
  - No source change needed — tag only.
  - Dry-run first: `git push --dry-run origin web-readonly-status-mvp-v0.1.0`
  - Then: `git push origin web-readonly-status-mvp-v0.1.0`
  - Write release tag report to `G:\我的雲端硬碟\Codex-Work\opencode app\reports\web-readonly-status-mvp-v0.1.0-release-tag.md`
  - Final label on success: `WEB_READONLY_STATUS_MVP_V0_1_0_TAGGED`
- After tagging: `PLAN_MVP_RELEASE_CHECKPOINT` → plan next web MVP feature.
- Any change to `packages/web-readonly-status` must preserve the read-only / browser-only / single-endpoint boundary.
- Read this handoff before next session.

## 📌 必讀 handoff

- `packages/web-readonly-status/src/adapter/realAdapter.ts`
- `packages/web-readonly-status/src/adapter/realAdapterClient.ts`
- `packages/web-readonly-status/README.md`
- `packages/web-readonly-status/SAFETY_CHECKLIST.md`

## 🕳️ 踩坑筆記

- 這個 package 的安全邊界靠 source code 直接保護，不能只靠 README。
- Vite dev server 不適合作為 browser sanity 的最終證據，production build + preview/static serving 才算數。
- `dist/` 會由 build 產生，但目前被 git ignore，不需要納入版本控制。
- 後續如果再加 diagnostics，要避免引入自動輪詢、`setInterval`、WebSocket、SSE 或任何新的寫入行為。
