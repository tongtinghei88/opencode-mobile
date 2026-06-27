# opencode-mobile-fork-mainline Handoff

## Shutdown note (2026-06-28 - Web Read-Only Status MVP v0.2.0 tagged)

- **Final label:** `WEB_READONLY_STATUS_MVP_V0_2_0_TAGGED`
- **Decision:** `PASS`
- **Recommendation:** `USE_DAILY_LAUNCH_PACK_FOR_ROUTINE_ACCESS`
- **Authoritative repo:** `C:\Codex-Recovery\opencode-mobile-fork-mainline`
- **Branch:** `web-app-mainline`
- **HEAD:** `9d17862d5d6b7311b065c4f67c93c588cfcb4cfd`
- **Origin:** `origin/web-app-mainline` matches local HEAD.
- **Release tag:** `web-readonly-status-mvp-v0.2.0` pushed to `origin`; peeled target is `9d17862d5d6b7311b065c4f67c93c588cfcb4cfd`.
- **Previous release tag:** `web-readonly-status-mvp-v0.1.0` remains at `c8747b5508d87630da470652ce7a2aebf819629d`.
- **Daily Launch Pack:** implemented, pushed, real-device checked, and tagged. Android and iPhone both passed page load, CONNECTED status, manual refresh, and visual layout checks at `http://192.168.50.202:4173/`.
- **Cleanup:** launch pack stopped; ports `4173`, `8790`, `5173`, `4096`, `3000`, and `8081` free; no adapter/preview process remains.
- **Reports in Google Drive:**
  - `G:\我的雲端硬碟\Codex-Work\opencode app\reports\web-readonly-status-daily-use-launch-pack.md`
  - `G:\我的雲端硬碟\Codex-Work\opencode app\reports\web-readonly-status-mvp-v0.2.0-tag.md`
- **Current daily-use commands from repo root:**
  - `.\packages\web-readonly-status\scripts\start-readonly-status.ps1`
  - `.\packages\web-readonly-status\scripts\status-readonly-status.ps1`
  - `.\packages\web-readonly-status\scripts\stop-readonly-status.ps1`
- **Safety boundary unchanged:** app still only performs `GET http://192.168.50.202:8790/api/local/v0/summary` with `credentials: "omit"`; no polling, storage, auth, chat, terminal, git, provider, filesystem, or write actions.
- **Next legal step:** use the daily launch pack for routine access, or plan a separately reviewed v0.3 scope. Any endpoint configurability, auth, polling, write action, direct `4096` path, or backend integration remains out of scope until explicitly approved.

## ⏯️ 最新狀態（2026-06-27 收工 — MVP v0.1.0 tagged + Real Device LAN Accepted）

- Final labels: `WEB_READONLY_STATUS_MVP_V0_1_0_TAGGED` → `WEB_READONLY_STATUS_V0_1_0_REAL_DEVICE_LAN_ACCEPTED`
- Branch: `web-app-mainline`, HEAD: `e8c4301bdb5f1c9892b9d00655d89b61adb9facb` (governance +1 ahead of tag)
- Release tag: `web-readonly-status-mvp-v0.1.0` → `c8747b5508d87630da470652ce7a2aebf819629d` (pushed to `origin`)
- Working tree: clean.

### Session completed

1. **Release tag**: `web-readonly-status-mvp-v0.1.0` created (annotated) at `c8747b5`, pushed to `origin`. Report: `G:\...\reports\web-readonly-status-mvp-v0.1.0-release-tag.md`.
2. **Real Device LAN Acceptance PASS**: Android phone, iPhone Safari, Windows Chrome — all PASS over same Wi-Fi / LAN at `http://192.168.50.202:4173/`. Fail-closed (UNREACHABLE) verified locally. Report: `G:\...\reports\web-readonly-status-v0.1.0-real-device-lan-acceptance.md`.
3. Both preview server (`4173`) and adapter (`8790`) were started for the test and cleanly stopped. All ports free at shutdown. No commits, source changes, or additional pushes performed.

### MVP acceptance summary

- Adapter: `C:\Codex-Recovery\opencode-local-adapter-spike3O\server.mjs` (start with `HOST=192.168.50.202 PORT=8790`)
- Preview: `bun run --cwd packages/web-readonly-status preview -- --host 192.168.50.202 --port 4173`
- Safety boundary unchanged: only `GET http://192.168.50.202:8790/api/local/v0/summary`, `credentials:"omit"`, no polling.

## ➡️ 下一步

- **MVP v0.1.0 is accepted.** Plan next feature scope:
  - Candidates: configurable adapter IP, persistent adapter daemon, basic LAN session auth, mDNS adapter discovery, richer status display (session list preview).
  - Any new feature must go through a scoped review before adding new egress, auth, or mutation capability.
- Backend Gate C / Stage 3 authorization remains independent and unchanged.

## 📌 必讀 handoff

- Release tag report: `G:\我的雲端硬碟\Codex-Work\opencode app\reports\web-readonly-status-mvp-v0.1.0-release-tag.md`
- LAN acceptance report: `G:\我的雲端硬碟\Codex-Work\opencode app\reports\web-readonly-status-v0.1.0-real-device-lan-acceptance.md`
- `packages/web-readonly-status/src/adapter/realAdapter.ts`
- `packages/web-readonly-status/src/adapter/realAdapterClient.ts`
- `packages/web-readonly-status/README.md`
- `packages/web-readonly-status/SAFETY_CHECKLIST.md`

## 🕳️ 踩坑筆記

- Vite dev server 不適合作為 browser sanity 的最終證據，production build + preview/static serving 才算數。
- 這個 package 的安全邊界靠 source code 直接保護，不能只靠 README。
- `dist/` 會由 build 產生，但目前被 git ignore，不需要納入版本控制。
- 後續如果再加 diagnostics，要避免引入自動輪詢、`setInterval`、WebSocket、SSE 或任何新的寫入行為。
- Chrome extension (Claude in Chrome MCP) was not connected during LAN acceptance; browser sanity was verified via screenshot (computer-use read tier) + curl + netstat + source/artifact scan.

---

## 歷史記錄（2026-06-27 — MVP readiness sprint PASS + pushed）

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
