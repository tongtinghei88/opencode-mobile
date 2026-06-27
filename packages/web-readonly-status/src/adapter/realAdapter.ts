/**
 * Web Spike 3P: read-only browser client with one fixed summary endpoint.
 *
 * This package must never expand into chat, terminal, git mutation, provider,
 * filesystem, auth, or direct 4096 access without a separate approved review.
 */
export const REAL_ADAPTER_READONLY_MODE = true;

export const REAL_ADAPTER_SUMMARY_URL =
  "http://192.168.50.202:8790/api/local/v0/summary";

export function assertRealAdapterSummaryUrl(
  summaryUrl: string = REAL_ADAPTER_SUMMARY_URL,
): void {
  const url = new URL(summaryUrl);
  if (url.protocol !== "http:") {
    throw new Error(`real adapter refuses non-http protocol: ${url.protocol}`);
  }
  if (url.username || url.password) {
    throw new Error("real adapter refuses embedded credentials");
  }
  if (url.hostname !== "192.168.50.202") {
    throw new Error(`real adapter refuses unexpected host: ${url.hostname}`);
  }
  if (url.port !== "8790") {
    throw new Error(`real adapter refuses unexpected port: ${url.port}`);
  }
  if (url.pathname !== "/api/local/v0/summary") {
    throw new Error(`real adapter refuses unexpected path: ${url.pathname}`);
  }
}
