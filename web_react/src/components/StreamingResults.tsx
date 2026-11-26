import { Badge } from "@/components/ui/badge";
import { AlertTriangle, Download, XCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { toast } from "sonner";
import { projectService } from "@/services/project";
import { Accordion, AccordionItem, AccordionContent, AccordionTrigger } from "@/components/ui/accordion";
import { FunctionGraphVisualization } from "./FunctionGraphVisualization";
import { PipelineTrail, StageResult } from "./Pipeline";
import { useT } from "@/i18n";
import { FunctionReviewControl, REVIEW_LABELS } from "./FunctionReviewControl";
import type { FunctionReview } from "@/services/project";
import { DEFAULT_VULNERABILITY, findReview } from "@/lib/findings";

interface ReviewProps {
  sessionId?: string;
  /** The scan these results belong to; reviews are looked up per scan. */
  vulnerability?: string;
  reviews?: FunctionReview[];
  onReviewed?: (reviews: FunctionReview[]) => void;
}

interface StreamingResultsProps extends ReviewProps {
  results: any[];
  isStreaming: boolean;
  /** Inside AnalysisReport: no heading, export button or disclaimer of its own. */
  embedded?: boolean;
}

const lineLabel = (lines?: number[]) => (lines && lines.length === 2 ? `L${lines[0]}–L${lines[1]}` : "");

const renderDetail = (result: StageResult, t: ReturnType<typeof useT>, review: ReviewProps) => {
  const output = result.output;
  if (!output) return null;

  if (result.node === "convert_to_fcg") return null;  // its output is a server file path: nothing a user can act on

  if (result.node === "detect_vulnerability_src") {
    const vulnerable = output.predicted_class === "Vulnerable";
    return (
      <dl className="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm">
        <div className="flex items-center gap-2">
          <dt className="text-muted-foreground">{t("Prediction")}</dt>
          <dd><Badge variant={vulnerable ? "destructive" : "ok"}>{vulnerable ? t("Vulnerable") : t("Not flagged")}</Badge></dd>
        </div>
        <div className="flex items-baseline gap-2">
          <dt className="text-muted-foreground">{t("Confidence")}</dt>
          <dd className="measured text-cool">{(output.confidence_score * 100).toFixed(2)}%</dd>
        </div>
      </dl>
    );
  }

  if (result.node === "detect_vulnerability_func") {
    return (
      <div className="space-y-6">
        {output.fcg_edges && output.func_vulnerability_predictions && (
          <FunctionGraphVisualization
            fcgEdges={output.fcg_edges}
            funcVulnerabilityPredictions={output.func_vulnerability_predictions}
          />
        )}

        {output.func_vulnerability_predictions && (
          <div>
            <h4 className="mb-2 text-sm text-muted-foreground">{t("Function Vulnerability Predictions")}</h4>
            <Accordion type="single" collapsible className="border-t border-rule">
              {output.func_vulnerability_predictions.map((func: any, idx: number) => (
                <AccordionItem key={idx} value={`function-${idx}`} className="border-rule">
                  <AccordionTrigger className="min-w-0 flex-wrap gap-x-3 gap-y-1 px-2 py-3 hover:bg-paper-2 hover:no-underline sm:flex-nowrap">
                    {/* Narrow screens: the name gets its own line, the line range, badges and score wrap below it. */}
                    <span className="code-text min-w-0 basis-full truncate text-left text-sm text-ink sm:flex-1 sm:basis-0">{func.function_name}</span>
                    <span className="code-text text-xs text-muted-foreground">{lineLabel(func.lines)}</span>
                    {func.prediction === 1 && (() => {
                      const status = findReview(review.reviews, review.vulnerability ?? DEFAULT_VULNERABILITY, func.function_name)?.status ?? "pending";
                      return <Badge variant="outline">{t(REVIEW_LABELS[status])}</Badge>;
                    })()}
                    <Badge variant={func.prediction === 1 ? "destructive" : "ok"}>
                      {func.prediction === 1 ? t("Vulnerable") : t("Not flagged")}
                    </Badge>
                    <span className="measured w-12 text-right text-sm text-cool">{func.confidence}</span>
                  </AccordionTrigger>
                  <AccordionContent className="px-2">
                    <pre className="code-text well overflow-x-auto p-4 text-xs leading-relaxed text-ink-2">{
                      func.lines?.length === 2
                        ? (func.function_code as string).split("\n").map((line, i) => `${String(func.lines[0] + i).padStart(4)} | ${line}`).join("\n")
                        : func.function_code
                    }</pre>
                    {func.prediction === 1 && review.onReviewed && (
                      <FunctionReviewControl
                        key={review.sessionId}
                        sessionId={review.sessionId}
                        vulnerability={review.vulnerability}
                        functionName={func.function_name}
                        review={findReview(review.reviews, review.vulnerability ?? DEFAULT_VULNERABILITY, func.function_name)}
                        onReviewed={review.onReviewed}
                      />
                    )}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </div>
        )}

        {output.fcg_edges && (
          <details className="text-sm">
            <summary className="cursor-pointer text-muted-foreground hover:text-ink">{t("Function Call Graph Edges")}</summary>
            <p className="code-text well mt-2 break-all p-3 text-xs text-ink-2">{JSON.stringify(output.fcg_edges)}</p>
          </details>
        )}
      </div>
    );
  }

  if (result.node === "explain_vulnerability_func" && output.explanations) {
    return (
      <ul className="space-y-3">
        {output.explanations.map((explanation: any, idx: number) => (
          <li key={idx} className="rounded-md bg-bad-soft p-4">
            <div className="flex items-start gap-3">
              <AlertTriangle className="mt-0.5 h-4 w-4 flex-shrink-0 text-bad" aria-hidden="true" />
              <div className="min-w-0">
                <h4 className="code-text break-words text-sm text-ink">{explanation.function_name}</h4>
                <div className="chat-prose mt-2">
                  <ReactMarkdown remarkPlugins={[remarkGfm]}>{explanation.explanation}</ReactMarkdown>
                </div>
              </div>
            </div>
          </li>
        ))}
      </ul>
    );
  }

  return null;
};

export const downloadSarif = async (sessionId: string, t: ReturnType<typeof useT>) => {
  try {
    const sarif = await projectService.getSessionSarif(sessionId);
    const url = URL.createObjectURL(new Blob([JSON.stringify(sarif, null, 2)], { type: "application/sarif+json" }));
    const a = Object.assign(document.createElement("a"), { href: url, download: `graphfusion-${sessionId}.sarif` });
    a.click();
    URL.revokeObjectURL(url);
  } catch (error) {
    toast.error(error instanceof Error ? error.message : t("Could not export SARIF"));
  }
};

export const StreamingResults = ({ results, isStreaming, embedded = false, ...review }: StreamingResultsProps) => {
  const t = useT();
  if (results.length === 0 && !isStreaming) {
    return null;
  }

  const errors = results.filter((r) => r.node === "error" && r.output?.error);

  return (
    <section className="space-y-6" aria-labelledby={embedded ? undefined : "analysis-results-head"}>
      {!embedded && <div className="flex items-center justify-between gap-4">
        <h2 id="analysis-results-head" className="text-xl">{t("Analysis Results")}</h2>
        {!isStreaming && review.sessionId && (
          <Button
            size="sm"
            variant="outline"
            onClick={() => downloadSarif(review.sessionId!, t)}
            title={t("Open in VS Code with the SARIF Viewer extension, or upload to GitHub code scanning")}
          >
            <Download className="h-3 w-3" aria-hidden="true" />
            {t("Download SARIF (IDE/CI)")}
          </Button>
        )}
        {isStreaming && (
          <Badge variant="signal" role="status">
            <span className="stage__spin keep-motion" aria-hidden="true" />
            {t("Analyzing…")}
          </Badge>
        )}
      </div>}

      <PipelineTrail results={results} isStreaming={isStreaming} renderDetail={(r) => renderDetail(r, t, review)} />

      {!embedded && <p className="text-xs text-muted-foreground">
        {t("Alerts and their absence are model output, not proof: an expert must confirm each alert, and an unflagged contract still needs a manual audit.")}
      </p>}

      {errors.map((error, idx) => (
        <div key={idx} role="alert" className="flex items-start gap-3 rounded-md bg-bad-soft p-4">
          <XCircle className="mt-0.5 h-5 w-5 flex-shrink-0 text-bad" aria-hidden="true" />
          <div>
            <h3 className="text-base text-bad">{t("Analysis Error")}</h3>
            <p className="mt-1 text-sm text-ink-2">{error.output.error}</p>
          </div>
        </div>
      ))}
    </section>
  );
};
