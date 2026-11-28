import { useEffect, useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import { projectService, Finding, FindingStage, FixDecision, RepairAgentResult } from "@/services/project";
import { useAuth } from "@/contexts/AuthContext";
import { FINDINGS_CHANGED, VULNERABILITY_LABELS } from "@/lib/findings";
import { REVIEW_LABELS } from "./FunctionReviewControl";
import { useT } from "@/i18n";

const STEPS = ["Detect", "Explain", "Expert review", "Fix", "Compile & re-check", "Expert approval"];

const STAGE: Record<FindingStage, { label: string; variant: "outline" | "secondary" | "destructive" | "ok" | "signal" }> = {
  awaiting_review: { label: "Awaiting expert review", variant: "outline" },
  closed_false_positive: { label: "Closed: false positive", variant: "secondary" },
  manual_review: { label: "Needs manual review", variant: "signal" },
  awaiting_fix: { label: "Confirmed: awaiting a fix", variant: "destructive" },
  fix_failed_check: { label: "Fix does not compile", variant: "destructive" },
  awaiting_fix_approval: { label: "Fix compiled: awaiting expert approval", variant: "signal" },
  fix_accepted: { label: "Fix accepted by expert", variant: "ok" },
};

const DECISIONS: { decision: FixDecision; label: string }[] = [
  { decision: "accepted", label: "Accept fix" },
  { decision: "rejected", label: "Reject fix" },
  { decision: "needs_manual_review", label: "Needs manual review" },
];

/** Where every alert stands between detection and an expert-approved fix, and the expert's decision on each checked fix. */
export const FindingWorkflow = ({ sessionId }: { sessionId: string }) => {
  const t = useT();
  const { user } = useAuth();
  const [findings, setFindings] = useState<Finding[] | null>(null);
  const [saving, setSaving] = useState(false);
  const [agentRunning, setAgentRunning] = useState<string | null>(null);
  const [agentResults, setAgentResults] = useState<Record<string, RepairAgentResult>>({});

  const load = () => projectService.getFindings(sessionId).then(setFindings).catch(() => setFindings([]));
  useEffect(() => {
    load();
    window.addEventListener(FINDINGS_CHANGED, load);
    return () => window.removeEventListener(FINDINGS_CHANGED, load);
  }, [sessionId]);

  const decide = async (f: Finding, decision: FixDecision) => {
    setSaving(true);
    try {
      await projectService.decideFix(sessionId, f.vulnerability, f.function_name, decision, f.fix!.suggested_code);
      await load();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t("Could not save the decision"));
      await load();  // e.g. 409: the fix changed since it was shown, so show the current one
    } finally {
      setSaving(false);
    }
  };

  const runAgent = async (f: Finding) => {
    const key = `${f.vulnerability}|${f.function_name}`;
    setAgentRunning(key);
    try {
      const result = await projectService.runRepairAgent(sessionId, f.vulnerability, f.function_name);
      setAgentResults(prev => ({ ...prev, [key]: result }));
      if (result.verification?.holds) toast.success(t("The agent's fix passed the checks; it now waits for an expert."));
      else toast.message(t("The agent stopped without a fix that passes every check."));
      await load();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t("The repair agent failed"));
    } finally {
      setAgentRunning(null);
    }
  };

  if (!findings || findings.length === 0) return null;

  return (
    <section className="panel overflow-hidden" aria-labelledby="workflow-head">
      <div className="border-b border-rule px-4 py-3">
        <h2 id="workflow-head" className="text-lg">{t("Fix workflow")}</h2>
        <ol className="mt-1 flex flex-wrap gap-x-2 text-xs text-muted-foreground">
          {STEPS.map((step, i) => <li key={step}>{i > 0 && <span aria-hidden="true">→ </span>}{t(step)}</li>)}
        </ol>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="text-xs text-muted-foreground">
            <tr className="border-b border-rule">
              <th scope="col" className="px-4 py-2 font-normal">{t("Finding")}</th>
              <th scope="col" className="px-4 py-2 font-normal">{t("Expert review")}</th>
              <th scope="col" className="px-4 py-2 font-normal">{t("Fix check")}</th>
              <th scope="col" className="px-4 py-2 font-normal">{t("Status")}</th>
            </tr>
          </thead>
          <tbody>
            {findings.map(f => (
              <tr key={`${f.vulnerability}|${f.function_name}`} className="border-b border-rule align-top">
                <td className="px-4 py-3">
                  <span className="code-text break-all text-ink">{f.function_name}</span>
                  <span className="mt-1 block text-xs text-muted-foreground">
                    {t(VULNERABILITY_LABELS[f.vulnerability] ?? f.vulnerability_label)}
                    {f.lines.length === 2 && <> · L{f.lines[0]}–L{f.lines[1]}</>} · {f.confidence}
                  </span>
                </td>
                <td className="px-4 py-3 text-ink-2">
                  {t(REVIEW_LABELS[f.review?.status ?? "pending"])}
                  {f.review && <span className="mt-1 block text-xs text-muted-foreground">{f.review.reviewer}</span>}
                </td>
                <td className="px-4 py-3 text-ink-2">
                  {f.fix ? (
                    <>
                      {f.fix.compiled ? t("Compiles (solc {v})", { v: f.fix.solc_version ?? "?" }) : t("Does not compile")}
                      <span className="mt-1 block text-xs text-muted-foreground">
                        {t("Slither findings: {a} before, {b} after", { a: f.fix.findings_before, b: f.fix.findings_after })}
                      </span>
                    </>
                  ) : "–"}
                  {(() => {
                    const key = `${f.vulnerability}|${f.function_name}`, r = agentResults[key];
                    return (
                      <div className="mt-2">
                        {f.stage !== "fix_accepted" && f.stage !== "closed_false_positive" && (
                          <Button size="sm" variant="outline" disabled={agentRunning !== null} onClick={() => runAgent(f)}>
                            {agentRunning === key ? t("Agent working…") : t("Let the agent fix it")}
                          </Button>
                        )}
                        {r && (
                          <span className="mt-1 block text-xs text-muted-foreground">
                            {t("Agent: {n} rounds, {c} tool calls", { n: r.rounds, c: r.tool_calls })} ·{" "}
                            {r.verification ? (r.verification.holds ? t("passes compile, Slither and re-scan") : t("does not pass every check")) : t(r.stopped)}
                          </span>
                        )}
                      </div>
                    );
                  })()}
                </td>
                <td className="px-4 py-3">
                  <Badge variant={STAGE[f.stage].variant}>{t(STAGE[f.stage].label)}</Badge>
                  {f.fix?.decided_by && <span className="mt-1 block text-xs text-muted-foreground">{f.fix.decided_by}</span>}
                  {user?.role === "expert" && f.fix && f.review?.status === "confirmed" && (
                    <div className="mt-2 flex flex-wrap gap-2">
                      {DECISIONS.map(d => (
                        <Button
                          key={d.decision}
                          size="sm"
                          variant={f.fix!.decision === d.decision ? "secondary" : "outline"}
                          aria-pressed={f.fix!.decision === d.decision}
                          disabled={saving || (d.decision === "accepted" && !f.fix!.compiled)}
                          onClick={() => decide(f, d.decision)}
                        >
                          {t(d.label)}
                        </Button>
                      ))}
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="border-t border-rule px-4 py-3 text-xs text-muted-foreground">
        {t("Anyone can propose a fix and compile it. Only an expert confirms an alert, and only a fix that compiled for a confirmed alert can be accepted. An accepted fix still needs the contract's own tests and an audit before deployment.")}
      </p>
    </section>
  );
};
