import {
  REAL_ADAPTER_READONLY_MODE,
  REAL_ADAPTER_SUMMARY_URL,
  assertRealAdapterSummaryUrl,
} from "./realAdapter";

interface AdapterSummaryResponse {
  adapter?: {
    status?: unknown;
  };
  opencode?: {
    reachable?: unknown;
    status?: unknown;
  };
  repo?: {
    branch?: unknown;
    head?: unknown;
    clean?: unknown;
    stage3TagCount?: unknown;
  };
}

export interface RealAdapterSummary {
  adapterStatus: string;
  opencodeReachable: boolean;
  opencodeStatus: number | null;
  repoBranch: string;
  repoHead: string;
  repoClean: boolean | null;
  repoStage3TagCount: number | null;
}

function guard(): void {
  if (!REAL_ADAPTER_READONLY_MODE) {
    throw new Error("real adapter read-only web app is disabled");
  }
  assertRealAdapterSummaryUrl(REAL_ADAPTER_SUMMARY_URL);
}

function toNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

export async function fetchRealAdapterSummary(): Promise<RealAdapterSummary> {
  guard();
  const response = await fetch(REAL_ADAPTER_SUMMARY_URL, {
    method: "GET",
    headers: {
      Accept: "application/json",
    },
    credentials: "omit",
  });

  if (!response.ok) {
    throw new Error(`real adapter GET /summary -> ${response.status}`);
  }

  const data = (await response.json()) as AdapterSummaryResponse;
  return {
    adapterStatus:
      typeof data.adapter?.status === "string" ? data.adapter.status : "unknown",
    opencodeReachable: data.opencode?.reachable === true,
    opencodeStatus: toNumber(data.opencode?.status),
    repoBranch:
      typeof data.repo?.branch === "string" ? data.repo.branch : "unknown",
    repoHead: typeof data.repo?.head === "string" ? data.repo.head : "unknown",
    repoClean: typeof data.repo?.clean === "boolean" ? data.repo.clean : null,
    repoStage3TagCount: toNumber(data.repo?.stage3TagCount),
  };
}
