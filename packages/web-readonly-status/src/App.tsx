import { useEffect, useState } from "react";
import {
  REAL_ADAPTER_SUMMARY_URL,
  assertRealAdapterSummaryUrl,
} from "./adapter/realAdapter";
import {
  type RealAdapterSummary,
  fetchRealAdapterSummary,
} from "./adapter/realAdapterClient";

type LoadState = "idle" | "loading" | "ready" | "error";

function formatBoolean(value: boolean | null): string {
  if (value === true) {
    return "true";
  }
  if (value === false) {
    return "false";
  }
  return "unknown";
}

function formatStatusCode(value: number | null): string {
  return value === null ? "unknown" : String(value);
}

function formatTagCount(value: number | null): string {
  return value === null ? "unknown" : String(value);
}

function formatTimestamp(value: string | null): string {
  if (!value) {
    return "Not refreshed yet";
  }
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? value : date.toLocaleString();
}

function App() {
  const [loadState, setLoadState] = useState<LoadState>("idle");
  const [summary, setSummary] = useState<RealAdapterSummary | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [lastRefreshedAt, setLastRefreshedAt] = useState<string | null>(null);

  async function refreshSummary(): Promise<void> {
    try {
      setLoadState("loading");
      setErrorMessage(null);
      assertRealAdapterSummaryUrl();
      const nextSummary = await fetchRealAdapterSummary();
      setSummary(nextSummary);
      setLastRefreshedAt(new Date().toISOString());
      setLoadState("ready");
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Unknown error");
      setLastRefreshedAt(new Date().toISOString());
      setLoadState("error");
    }
  }

  useEffect(() => {
    void refreshSummary();
  }, []);

  return (
    <main className="shell">
      <section className="hero">
        <p className="eyebrow">Spike 3P browser milestone</p>
        <h1>Real OpenCode Adapter - Read Only</h1>
        <p className="lede">
          This page is limited to one approved browser request and displays
          status only.
        </p>
        <div className="boundary">
          <span className="boundary-label">Allowed endpoint</span>
          <code>{REAL_ADAPTER_SUMMARY_URL}</code>
        </div>
        <div className="toolbar">
          <button
            className="refreshButton"
            type="button"
            onClick={() => {
              void refreshSummary();
            }}
            disabled={loadState === "loading"}
          >
            {loadState === "loading" ? "Refreshing..." : "Refresh status"}
          </button>
          <p className="timestamp">
            Last refreshed: {formatTimestamp(lastRefreshedAt)}
          </p>
        </div>
      </section>

      <section className="grid" aria-label="Read-only adapter summary">
        <article className="card accent">
          <header>
            <h2>Adapter</h2>
            <span className={`pill pill-${loadState}`}>{loadState}</span>
          </header>
          <dl>
            <div>
              <dt>Status</dt>
              <dd>{summary?.adapterStatus ?? "unknown"}</dd>
            </div>
            <div>
              <dt>OpenCode reachable</dt>
              <dd>{summary?.opencodeReachable ? "true" : "false"}</dd>
            </div>
            <div>
              <dt>OpenCode HTTP status</dt>
              <dd>{formatStatusCode(summary?.opencodeStatus ?? null)}</dd>
            </div>
          </dl>
        </article>

        <article className="card">
          <header>
            <h2>Repository</h2>
            <span className="subtle">Display only</span>
          </header>
          <dl>
            <div>
              <dt>Branch</dt>
              <dd>{summary?.repoBranch ?? "unknown"}</dd>
            </div>
            <div>
              <dt>HEAD</dt>
              <dd className="mono">{summary?.repoHead ?? "unknown"}</dd>
            </div>
            <div>
              <dt>Clean</dt>
              <dd>{formatBoolean(summary?.repoClean ?? null)}</dd>
            </div>
            <div>
              <dt>Stage 3 tag count</dt>
              <dd>{formatTagCount(summary?.repoStage3TagCount ?? null)}</dd>
            </div>
          </dl>
        </article>

        <article className="card warning">
          <header>
            <h2>Safety boundary</h2>
            <span className="subtle">Hard-coded</span>
          </header>
          <ul className="guardList">
            <li>No direct 4096 browser egress</li>
            <li>No chat, agent, terminal, git, or file actions</li>
            <li>No provider setup, auth, cookies, or embedded credentials</li>
            <li>No POST, PUT, PATCH, or DELETE routes</li>
          </ul>
        </article>
      </section>

      {errorMessage ? (
        <section className="errorPanel" role="alert">
          <h2>Adapter request failed</h2>
          <p>{errorMessage}</p>
          <p>
            This page should fail closed and must not fall back to any other
            endpoint.
          </p>
        </section>
      ) : null}
    </main>
  );
}

export default App;
