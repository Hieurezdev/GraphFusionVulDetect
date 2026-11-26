import type { AnalysisSession, FunctionReview } from "@/services/project";

// A contract is scanned once per vulnerability type; every stream event, review and fix says which scan it belongs to.
// Sessions stored before the dual scan carry no type: they were timestamp scans.
export const DEFAULT_VULNERABILITY = "timestamp";
export const VULNERABILITY_LABELS: Record<string, string> = { timestamp: "Timestamp dependency", reentrancy: "Reentrancy" };

export const vulnerabilityOf = (item?: { vulnerability?: string | null }) => item?.vulnerability || DEFAULT_VULNERABILITY;
export const findingKey = (vulnerability: string, functionName: string) => `${vulnerability}|${functionName}`;

const isMeta = (r: any) => r.node === "start" || r.node === "summary";
const isGlobalError = (r: any) => r.node === "error" && !r.vulnerability;

export const sessionResults = (session: AnalysisSession) =>
  (session.steps || []).map(step => ({ node: step.step_name, vulnerability: step.vulnerability ?? undefined, status: step.status, output: step.result_data, timestamp: step.started_at }));

export const scannedVulnerabilities = (results: any[]): string[] => {
  const announced: string[] = results.find(r => r.node === "start")?.output?.vulnerabilities || [];
  return [...new Set([...announced, ...results.filter(r => !isMeta(r) && !isGlobalError(r)).map(vulnerabilityOf)])];
};

/** One scan's events; an error that stopped the whole analysis shows in every scan. */
export const resultsFor = (results: any[], vulnerability: string) =>
  results.filter(r => !isMeta(r) && (isGlobalError(r) || vulnerabilityOf(r) === vulnerability));

export const summaryOf = (results: any[]) => results.find(r => r.node === "summary")?.output as AnalysisSummary | undefined;

export const flaggedFunctions = (results: any[]) =>
  results.flatMap(r => ((r.output?.func_vulnerability_predictions || []) as any[])
    .filter(p => p.prediction === 1)
    .map(p => ({ ...p, vulnerability: vulnerabilityOf(r) })));

export const explanationsByFinding = (results: any[]): Record<string, string> =>
  Object.fromEntries(results.flatMap(r => ((r.output?.explanations || []) as any[]).map(e => [findingKey(vulnerabilityOf(r), e.function_name), e.explanation])));

export const findReview = (reviews: FunctionReview[] | undefined, vulnerability: string, functionName: string) =>
  reviews?.find(r => vulnerabilityOf(r) === vulnerability && r.function_name === functionName);

export interface AnalysisSummary {
  vulnerabilities: Record<string, { label: string; status: "failed" | "not_flagged" | "flagged_no_function" | "flagged"; confidence: number | null; flagged_functions: number; error?: string | null }>;
  conclusion: "alerts" | "manual_review" | "no_alerts";
  manual_review: { vulnerability: string; reason: "analysis_failed" | "contract_flagged_no_function" }[];
}

/** Fired after a review, a fix check or a fix decision, so the workflow table reloads. */
export const FINDINGS_CHANGED = "gf-findings-changed";
export const notifyFindingsChanged = () => window.dispatchEvent(new Event(FINDINGS_CHANGED));
