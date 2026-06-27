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
type ConnectionStatus =
  | "not-checked"
  | "checking"
  | "connected"
  | "unreachable"
  | "failed-closed";

interface DiagnosticsSnapshot {
  checkedAt: string | null;
  details: string;
  status: ConnectionStatus;
}

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
    return "Not checked yet";
  }
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? value : date.toLocaleString();
}

function getConnectionLabel(status: ConnectionStatus): string {
  switch (status) {
    case "not-checked":
      return "Not checked";
    case "checking":
      return "Checking";
    case "connected":
      return "Connected";
    case "unreachable":
      return "Unreachable";
    case "failed-closed":
      return "Failed closed";
  }
}

function classifyConnectionFailure(error: unknown): DiagnosticsSnapshot {
  const message =
    error instanceof Error ? error.message : "Unknown read-only failure";
  const checkedAt = new Date().toISOString();
  const isUnreachable =
    error instanceof TypeError ||
    /failed to fetch|networkerror|load failed/i.test(message);

  return {
    checkedAt,
    details: message,
    status: isUnreachable ? "unreachable" : "failed-closed",
  };
}

function App() {
  const [loadState, setLoadState] = useState<LoadState>("idle");
  const [summary, setSummary] = useState<RealAdapterSummary | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [diagnostics, setDiagnostics] = useState<DiagnosticsSnapshot>({
    checkedAt: null,
    details: "No request has been sent yet.",
    status: "not-checked",
  });

  async function refreshSummary(): Promise<void> {
    try {
      setLoadState("loading");
      setErrorMessage(null);
      setDiagnostics({
        checkedAt: diagnostics.checkedAt,
        details:
          "Sending one approved read-only summary request to the local adapter.",
        status: "checking",
      });
      assertRealAdapterSummaryUrl();
      const nextSummary = await fetchRealAdapterSummary();
      const checkedAt = new Date().toISOString();
      setSummary(nextSummary);
      setDiagnostics({
        checkedAt,
        details:
          "Adapter summary loaded successfully from the approved endpoint.",
        status: "connected",
      });
      setLoadState("ready");
    } catch (error) {
      const failure = classifyConnectionFailure(error);
      setErrorMessage(failure.details);
      setDiagnostics(failure);
      setLoadState("error");
    }
  }

  useEffect(() => {
    void refreshSummary();
  }, []);

  return (
    <main className="shell">
      <section className="hero">
        <p className="eyebrow">Read-only local adapter view</p>
        <h1>OpenCode Read-Only Status</h1>
        <p className="lede">
          This page is limited to one approved browser request and displays
          status only.
        </p>
        <div className="boundary">
          <span className="boundary-label">Allowed endpoint</span>
          <code>{REAL_ADAPTER_SUMMARY_URL}</code>
        </div>
        <section className="diagnosticsPanel" aria-label="Connection diagnostics">
          <div className="diagnosticsRow">
            <div>
              <p className="boundary-label">Connection status</p>
              <span
                className={`pill diagnosticPill pill-${diagnostics.status}`}
              >
                {getConnectionLabel(diagnostics.status)}
              </span>
            </div>
            <div>
              <p className="boundary-label">Last checked</p>
              <p className="diagnosticValue">
                {formatTimestamp(diagnostics.checkedAt)}
              </p>
            </div>
          </div>
          <div className="diagnosticsRow">
            <div>
              <p className="boundary-label">Diagnostics detail</p>
              <p className="diagnosticValue">{diagnostics.details}</p>
            </div>
            <div>
              <p className="boundary-label">Network action</p>
              <p className="diagnosticValue">
                Manual refresh is the only repeat request action.
              </p>
            </div>
          </div>
        </section>
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
            Last checked: {formatTimestamp(diagnostics.checkedAt)}
          </p>
        </div>
      </section>

      <section className="grid" aria-label="Read-only adapter summary">
        <article className="card accent">
          <header>
            <h2>Adapter</h2>
            <span className={`pill pill-${diagnostics.status}`}>
              {getConnectionLabel(diagnostics.status)}
            </span>
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
          <dl className="errorMeta">
            <div>
              <dt>Connection status</dt>
              <dd>{getConnectionLabel(diagnostics.status)}</dd>
            </div>
            <div>
              <dt>Endpoint</dt>
              <dd className="mono">{REAL_ADAPTER_SUMMARY_URL}</dd>
            </div>
            <div>
              <dt>Last checked</dt>
              <dd>{formatTimestamp(diagnostics.checkedAt)}</dd>
            </div>
          </dl>
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
