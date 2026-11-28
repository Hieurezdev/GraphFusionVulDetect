import { useEffect, useMemo, useRef, useState } from "react";
import * as monaco from "monaco-editor";
import EditorWorker from "monaco-editor/editor/editor.worker?worker";
import Editor, { loader } from "@monaco-editor/react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { CheckCircle, Crosshair, Loader2, RotateCcw } from "lucide-react";
import { toast } from "sonner";
import { projectService, FunctionReview } from "@/services/project";
import { refactorBotService, ValidationResponse } from "@/services/refactorbot";
import { FunctionReviewControl, REVIEW_LABELS } from "./FunctionReviewControl";
import { FindingList } from "./RefactorChatbot";
import { useT } from "@/i18n";
import { useResolvedTheme } from "@/lib/preferences";
import { VULNERABILITY_LABELS, explanationsByFinding, findReview, findingKey, flaggedFunctions } from "@/lib/findings";

// Bundle Monaco locally (no CDN); Solidity needs only the base editor worker.
self.MonacoEnvironment = { getWorker: () => new EditorWorker() };
loader.config({ monaco });

interface Props {
  sessionId: string;
  results: any[];
  reviews: FunctionReview[];
  onReviewed: (reviews: FunctionReview[]) => void;
}

const SEVERITY = {
  confirmed: monaco.MarkerSeverity.Error,
  pending: monaco.MarkerSeverity.Warning,
  needs_manual_review: monaco.MarkerSeverity.Warning,
  false_positive: monaco.MarkerSeverity.Hint,
} as const;

// e.g. "bank.sol:9:9: Error: Expected ';' but got identifier"
const COMPILER_LINE = /^[^:\n]+\.sol:(\d+):(\d+):\s*(\w*Error|Warning):\s*(.+)$/gm;

/** In-browser IDE: the whole contract with alerts on their lines, expert review beside them, and compile + Slither re-check of edits. */
const ContractIDE = ({ sessionId, results, reviews, onReviewed }: Props) => {
  const t = useT();
  const editorTheme = useResolvedTheme();
  const [original, setOriginal] = useState<string | null>(null);
  const [code, setCode] = useState("");
  const [checking, setChecking] = useState(false);
  const [check, setCheck] = useState<ValidationResponse | null>(null);
  const editorRef = useRef<monaco.editor.IStandaloneCodeEditor | null>(null);
  const decorationsRef = useRef<monaco.editor.IEditorDecorationsCollection | null>(null);

  const flagged = useMemo(
    () => flaggedFunctions(results).filter((p: any) => p.lines?.length === 2),
    [results],
  );
  const explanations = useMemo(() => explanationsByFinding(results), [results]);
  const reviewOf = (p: any) => findReview(reviews, p.vulnerability, p.function_name);
  const statusOf = (p: any) => reviewOf(p)?.status ?? "pending";
  const labelOf = (p: any) => t(VULNERABILITY_LABELS[p.vulnerability] ?? p.vulnerability);

  useEffect(() => {
    projectService.getSessionSource(sessionId)
      .then(({ source }) => { setOriginal(source); setCode(source); })
      .catch(e => toast.error(e instanceof Error ? e.message : t("Could not load the contract source")));
  }, [sessionId]);

  // Alert markers: squiggles, gutter and hover text on the flagged lines.
  const paintAlerts = () => {
    const model = editorRef.current?.getModel();
    if (!model) return;
    monaco.editor.setModelMarkers(model, "graphfusion", flagged.map((p: any) => ({
      severity: SEVERITY[statusOf(p)],
      startLineNumber: p.lines[0], startColumn: 1,
      endLineNumber: p.lines[1], endColumn: model.getLineMaxColumn(Math.min(p.lines[1], model.getLineCount())),
      source: "GraphFusion",
      message: `${p.function_name}: ${labelOf(p)}, ${t("flagged")} (${p.confidence}) · ${t(REVIEW_LABELS[statusOf(p)])}`
        + (explanations[findingKey(p.vulnerability, p.function_name)] ? `\n\n${explanations[findingKey(p.vulnerability, p.function_name)]}` : ""),
    })));
    // Red band over each flagged function (not ones an expert rejected), plus a red mark in the gutter and the scrollbar.
    decorationsRef.current?.clear();
    decorationsRef.current = editorRef.current!.createDecorationsCollection(
      flagged.filter((p: any) => statusOf(p) !== "false_positive").map((p: any) => ({
        range: new monaco.Range(p.lines[0], 1, p.lines[1], 1),
        options: {
          isWholeLine: true,
          className: "gfd-flagged-line",
          linesDecorationsClassName: "gfd-flagged-gutter",
          overviewRuler: { color: "#ef4444", position: monaco.editor.OverviewRulerLane.Full },
          minimap: { color: "#ef4444", position: monaco.editor.MinimapPosition.Inline },
        },
      })),
    );
  };
  useEffect(paintAlerts, [flagged, reviews, explanations, original]);

  const goTo = (line: number) => {
    editorRef.current?.revealLineInCenter(line);
    editorRef.current?.setPosition({ lineNumber: line, column: 1 });
    editorRef.current?.focus();
  };

  const runCheck = async () => {
    if (!original) return;
    setChecking(true);
    try {
      const res = await refactorBotService.validateRefactoring(original, code, sessionId);
      setCheck(res);
      const model = editorRef.current?.getModel();
      if (model) {
        const compilerMarkers = [...(res.compiler_output || "").matchAll(COMPILER_LINE)].map(m => ({
          severity: m[3] === "Warning" ? monaco.MarkerSeverity.Warning : monaco.MarkerSeverity.Error,
          startLineNumber: +m[1], startColumn: +m[2], endLineNumber: +m[1], endColumn: model.getLineMaxColumn(Math.min(+m[1], model.getLineCount())),
          source: "solc", message: m[4],
        }));
        const slitherMarkers = res.findings_after.map(f => ({
          severity: f.impact === "High" || f.impact === "Medium" ? monaco.MarkerSeverity.Warning : monaco.MarkerSeverity.Info,
          startLineNumber: f.lines[0], startColumn: 1, endLineNumber: f.lines[f.lines.length - 1], endColumn: 1,
          source: `Slither ${f.check}`, message: f.description,
        }));
        monaco.editor.setModelMarkers(model, "check", [...compilerMarkers, ...slitherMarkers]);
      }
    } catch (e) {
      toast.error(e instanceof Error ? e.message : t("Failed to validate code"));
    } finally {
      setChecking(false);
    }
  };

  const reset = () => {
    if (original == null) return;
    setCode(original);
    setCheck(null);
    const model = editorRef.current?.getModel();
    if (model) monaco.editor.setModelMarkers(model, "check", []);
  };

  return (
    <section className="panel overflow-hidden" aria-labelledby="ide-head">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-rule px-4 py-3">
        <h2 id="ide-head" className="text-lg">{t("Contract IDE")}</h2>
        <div className="flex flex-wrap gap-2">
          <Button size="sm" variant="outline" onClick={reset} disabled={original == null || code === original}>
            <RotateCcw className="h-3 w-3" aria-hidden="true" />{t("Reset")}
          </Button>
          <Button size="sm" onClick={runCheck} disabled={original == null || checking} aria-busy={checking}>
            {checking ? <Loader2 className="keep-motion h-3 w-3 animate-spin" aria-hidden="true" /> : <CheckCircle className="h-3 w-3" aria-hidden="true" />}
            {t("Compile & re-check (solc + Slither)")}
          </Button>
        </div>
      </div>

      <div className="grid lg:grid-cols-[minmax(0,1fr)_20rem]">
        <div className="h-[32rem] min-w-0 border-b border-rule lg:border-b-0 lg:border-r">
          {original == null ? (
            <p className="flex h-full items-center justify-center gap-2 text-sm text-muted-foreground" role="status">
              <Loader2 className="keep-motion h-4 w-4 animate-spin" aria-hidden="true" />{t("Loading the contract…")}
            </p>
          ) : (
            <Editor
              language="sol"
              theme={editorTheme === "light" ? "light" : "vs-dark"}
              value={code}
              onChange={v => setCode(v ?? "")}
              onMount={editor => { editorRef.current = editor; paintAlerts(); }}
              options={{ minimap: { enabled: false }, fontSize: 13, scrollBeyondLastLine: false, glyphMargin: true, automaticLayout: true }}
            />
          )}
        </div>

        <div className="max-h-[32rem] space-y-4 overflow-y-auto p-4">
          <div>
            <h3 className="text-sm text-muted-foreground">{t("Alerts")} ({flagged.length})</h3>
            {flagged.length === 0 && <p className="mt-1 text-sm text-ink-2">{t("No function was flagged. That is not proof the contract is safe: review it manually.")}</p>}
            <ul className="mt-2 space-y-3">
              {flagged.map((p: any) => (
                <li key={findingKey(p.vulnerability, p.function_name)} className="border-t border-rule pt-3">
                  <button
                    type="button"
                    onClick={() => goTo(p.lines[0])}
                    className="flex w-full items-center gap-2 text-left text-sm hover:text-signal"
                    aria-label={t("Go to line {n}", { n: p.lines[0] })}
                  >
                    <Crosshair className="h-3 w-3 flex-shrink-0" aria-hidden="true" />
                    <span className="code-text min-w-0 flex-1 truncate">{p.function_name}</span>
                    <span className="code-text text-xs text-muted-foreground">L{p.lines[0]}–L{p.lines[1]}</span>
                  </button>
                  <p className="mt-1 text-xs text-muted-foreground">{labelOf(p)}</p>
                  <Badge variant="outline" className="mt-1">{t(REVIEW_LABELS[statusOf(p)])}</Badge>
                  <FunctionReviewControl
                    sessionId={sessionId}
                    vulnerability={p.vulnerability}
                    functionName={p.function_name}
                    review={reviewOf(p)}
                    onReviewed={onReviewed}
                  />
                </li>
              ))}
            </ul>
          </div>

          {check && (
            <div className="space-y-2 border-t border-rule pt-3" role="status">
              <p className={`text-sm ${check.is_valid ? "text-ok" : "text-bad"}`}>{check.message}</p>
              {check.compiled != null && (
                <>
                  <FindingList title={t("Slither findings before the fix")} findings={check.findings_before} />
                  <FindingList title={t("Slither findings after the fix")} findings={check.findings_after} />
                            {check.slither_error && (
                              <pre className="code-text whitespace-pre-wrap text-xs text-bad">{check.slither_error}</pre>
                            )}
                </>
              )}
            </div>
          )}

          <p className="border-t border-rule pt-3 text-xs text-muted-foreground">
            {t("A passing check is not proof the fix is correct. Have an expert review the change and run the contract's tests before deploying.")}
          </p>
        </div>
      </div>
    </section>
  );
};

export default ContractIDE;
