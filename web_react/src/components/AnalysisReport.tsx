import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Download } from "lucide-react";
import { ContractVisualization } from "./ContractVisualization";
import { StreamingResults, downloadSarif } from "./StreamingResults";
import { FindingWorkflow } from "./FindingWorkflow";
import type { FunctionReview } from "@/services/project";
import { VULNERABILITY_LABELS, flaggedFunctions, resultsFor, scannedVulnerabilities, summaryOf, type AnalysisSummary } from "@/lib/findings";
import { useT } from "@/i18n";

interface Props {
  results: any[];
  isStreaming: boolean;
  sessionId?: string;
  reviews?: FunctionReview[];
  onReviewed?: (reviews: FunctionReview[]) => void;
}

const CONCLUSION: Record<AnalysisSummary["conclusion"], string> = {
  alerts: "At least one scan raised an alert. Each alert needs an expert's verdict before anything is fixed.",
  manual_review: "No alert was raised, but a scan could not finish. The contract needs a manual review.",
  no_alerts: "No scan raised an alert. That is not proof the contract is safe: it still needs a manual audit.",
};

const STATUS: Record<AnalysisSummary["vulnerabilities"][string]["status"], { label: string; variant: "destructive" | "ok" | "outline" | "signal" }> = {
  flagged: { label: "Flagged", variant: "destructive" },
  flagged_no_function: { label: "Flagged, no function located", variant: "signal" },
  not_flagged: { label: "Not flagged", variant: "ok" },
  failed: { label: "Scan failed", variant: "outline" },
};

const REASON = {
  analysis_failed: "the scan could not run on this contract (often a compile failure), so there is no result",
  contract_flagged_no_function: "the contract was flagged but no function was located; an auditor has to find the cause",
};

// One sentence a non-developer can read, per vulnerability type.
const PLAIN: Record<string, string> = {
  timestamp: "The contract's behaviour depends on the block's clock, which whoever produces the block can shift by a few seconds. It matters when time decides who gets paid or who wins.",
  reentrancy: "The contract may send money out before updating its own records, so a malicious receiver could call back in and withdraw more than once.",
};

const NEXT_STEP: Record<AnalysisSummary["conclusion"], string> = {
  alerts: "If you do not read code: treat this as a reason to look for an independent audit report of this contract before putting money in. It does not mean the contract is unsafe.",
  manual_review: "If you do not read code: this tool could not check the contract. Look for an independent audit report before relying on it.",
  no_alerts: "If you do not read code: the two checks found nothing, but they cover only two kinds of bug. Look for an independent audit report before relying on this contract.",
};

const scanFinished = (scan: any[]) =>
  scan.some(r => r.node === "explain_vulnerability_func" || r.node === "error"
    || (r.node === "detect_vulnerability_src" && r.output?.predicted_class !== "Vulnerable"));

/** The whole result of an analysis: one conclusion, then each vulnerability scan, then the fix workflow. */
export const AnalysisReport = ({ results, isStreaming, sessionId, reviews, onReviewed }: Props) => {
  const t = useT();
  if (results.length === 0 && !isStreaming) return null;
  const summary = summaryOf(results);
  const scanned = scannedVulnerabilities(results);
  // While scanning, every scan shows its progress; once done, only scans with at least one vulnerable function keep their detail (the conclusion still lists all).
  const vulnerabilities = isStreaming ? scanned : scanned.filter(v => flaggedFunctions(resultsFor(results, v)).length > 0);

  return (
    <div className="space-y-10">
      <section className="panel p-6 lg:p-8" aria-labelledby="conclusion-head">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <h2 id="conclusion-head" className="text-xl">{t("Conclusion")}</h2>
          {isStreaming ? (
            <Badge variant="signal" role="status">
              <span className="stage__spin keep-motion" aria-hidden="true" />
              {t("Analyzing…")}
            </Badge>
          ) : sessionId && (
            <Button size="sm" variant="outline" onClick={() => downloadSarif(sessionId, t)}
              title={t("Open in VS Code with the SARIF Viewer extension, or upload to GitHub code scanning")}>
              <Download className="h-3 w-3" aria-hidden="true" />
              {t("Download SARIF (IDE/CI)")}
            </Button>
          )}
        </div>
        {summary ? (
          <>
            <p className="mt-3 text-ink-2">{t(CONCLUSION[summary.conclusion])}</p>
            <p className="mt-2 text-sm text-ink-2">{t(NEXT_STEP[summary.conclusion])}</p>
            <ul className="mt-4 grid gap-3 sm:grid-cols-2">
              {Object.entries(summary.vulnerabilities).map(([vulnerability, v]) => (
                <li key={vulnerability} className="well px-4 py-3 text-sm">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                  {vulnerabilities.includes(vulnerability)
                    ? <a href={`#scan-${vulnerability}`} className="text-ink hover:text-signal">{t(VULNERABILITY_LABELS[vulnerability] ?? v.label)}</a>
                    : <span className="text-ink">{t(VULNERABILITY_LABELS[vulnerability] ?? v.label)}</span>}
                  <span className="flex items-center gap-3">
                    {v.confidence != null && <span className="measured text-cool" title={t("How sure the model is of this verdict, not how safe the contract is")}>{t("{p}% model confidence", { p: (v.confidence * 100).toFixed(0) })}</span>}
                    {v.status === "flagged" && <span className="text-xs text-muted-foreground">{t("{n} function(s)", { n: v.flagged_functions })}</span>}
                    <Badge variant={STATUS[v.status].variant}>{t(STATUS[v.status].label)}</Badge>
                  </span>
                  </div>
                  {PLAIN[vulnerability] && <p className="mt-2 text-xs text-muted-foreground">{t(PLAIN[vulnerability])}</p>}
                </li>
              ))}
            </ul>
            {summary.manual_review.length > 0 && (
              <div className="mt-4 rounded-md bg-bad-soft p-4 text-sm" role="note">
                <h3 className="text-ink">{t("Needs manual review")}</h3>
                <ul className="mt-1 list-disc pl-5 text-ink-2">
                  {summary.manual_review.map(m => (
                    <li key={m.vulnerability + m.reason}>
                      {t(VULNERABILITY_LABELS[m.vulnerability] ?? m.vulnerability)}: {t(REASON[m.reason])}
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </>
        ) : (
          <p className="mt-3 text-sm text-muted-foreground">
            {isStreaming
              ? t("The contract is scanned for each vulnerability type side by side. The conclusion appears when every scan has finished.")
              : t("This analysis was stored without a combined conclusion; see each scan below.")}
          </p>
        )}
        <p className="mt-4 text-xs text-muted-foreground">
          {t("Alerts and their absence are model output, not proof: an expert must confirm each alert, and an unflagged contract still needs a manual audit.")}
        </p>
      </section>

      {vulnerabilities.map(vulnerability => {
        const scan = resultsFor(results, vulnerability);
        const running = isStreaming && !summary && !scanFinished(scan);
        return (
          <section key={vulnerability} id={`scan-${vulnerability}`} className="space-y-6" aria-labelledby={`scan-head-${vulnerability}`}>
            <h2 id={`scan-head-${vulnerability}`} className="border-b border-rule pb-3 text-2xl">
              {t(VULNERABILITY_LABELS[vulnerability] ?? vulnerability)}
            </h2>
            <ContractVisualization data={scan} isStreaming={running} />
            <StreamingResults embedded results={scan} isStreaming={running} vulnerability={vulnerability}
              sessionId={sessionId} reviews={reviews} onReviewed={onReviewed} />
          </section>
        );
      })}

      {!isStreaming && sessionId && <FindingWorkflow key={sessionId} sessionId={sessionId} />}
    </div>
  );
};
