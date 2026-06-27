# opencode-mobile-fork-mainline Handoff

## ⏯️ 上次做到哪

- `web-app-mainline` 已完成收工同步，最新 HEAD 是 `e21b33789d76c0201ef59a2448274bb658b7abfe`。
- 最近完成的是 `Add web readonly connection diagnostics`，只修改了 `packages/web-readonly-status/src/App.tsx` 和 `packages/web-readonly-status/src/styles.css`。
- 這個 commit 已經 push 到 user fork 的 `origin/web-app-mainline`，`upstream` 沒有被推送。
- 目前 repo 工作樹是乾淨的。

## ➡️ 下一步

- 延續 `web-app-mainline` 做下一個 web MVP 需求。
- 若要再動 `packages/web-readonly-status`，先保持 read-only 邊界不變，再做 production build / typecheck。
- 若要做更大功能，先確認是否仍需保持 browser-only、read-only、單一 summary endpoint 的約束。

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
