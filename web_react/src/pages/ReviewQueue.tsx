import { lazy, Suspense, useEffect, useState } from "react";
import Header from "@/components/Header";
import { AnalysisReport } from "@/components/AnalysisReport";
import { findReview, flaggedFunctions, sessionResults } from "@/lib/findings";
import { TruncatedText } from "@/components/TruncatedText";
import { useAuth } from "@/contexts/AuthContext";
import { projectService, AnalysisSession, FunctionReview } from "@/services/project";
import { toast } from "sonner";
import { useT } from "@/i18n";

const ContractIDE = lazy(() => import("@/components/ContractIDE"));

const toResults = sessionResults;

const pendingCount = (session: AnalysisSession) =>
  flaggedFunctions(toResults(session))
    .filter(p => (findReview(session.reviews, p.vulnerability, p.function_name)?.status ?? "pending") === "pending").length;

/** Expert worklist: every analysis (from any user) with alerts, newest first. */
const ReviewQueue = () => {
  const t = useT();
  const { user } = useAuth();
  const [sessions, setSessions] = useState<AnalysisSession[] | null>(null);
  const [selected, setSelected] = useState<AnalysisSession | null>(null);

  useEffect(() => {
    if (user?.role !== "expert") return;
    projectService.getReviewQueue()
      .then(list => { setSessions(list); setSelected(list[0] ?? null); })
      .catch(e => { setSessions([]); toast.error(e instanceof Error ? e.message : t("Could not load the review queue")); });
  }, [user?.role]);

  const handleReviewed = (reviews: FunctionReview[]) => {
    if (!selected) return;
    const updated = { ...selected, reviews };
    setSelected(updated);
    setSessions(prev => prev?.map(s => (s.id === updated.id ? updated : s)) ?? null);
  };

  return (
    <div className="min-h-dvh bg-background">
      <Header />
      <main id="main" className="shell py-10 lg:py-12">
        <h1 className="text-4xl leading-none">{t("Expert review")}</h1>
        {user?.role !== "expert" ? (
          <p className="mt-6 text-ink-2">{t("Only an expert account can open the review queue.")}</p>
        ) : sessions === null ? (
          <p className="mt-6 text-sm text-muted-foreground" role="status">{t("Loading…")}</p>
        ) : sessions.length === 0 ? (
          <p className="mt-6 text-ink-2">{t("No analysis has flagged functions to review.")}</p>
        ) : (
          <div className="mt-10 grid gap-10 lg:grid-cols-[minmax(0,17rem)_minmax(0,1fr)] lg:gap-12">
            <aside aria-labelledby="queue-head" className="min-w-0">
              <h2 id="queue-head" className="text-sm text-muted-foreground">{t("Analyses with alerts")}</h2>
              <ol className="mt-4 border-l border-rule-2">
                {sessions.map(session => {
                  const pending = pendingCount(session);
                  return (
                    <li key={session.id}>
                      <button
                        type="button"
                        aria-current={selected?.id === session.id ? "true" : undefined}
                        className={`relative -ml-px block w-full border-l py-3 pl-4 pr-2 text-left transition-colors duration-200 hover:bg-paper-2 ${
                          selected?.id === session.id ? "border-signal bg-paper-2" : "border-transparent"
                        }`}
                        onClick={() => setSelected(session)}
                      >
                        <TruncatedText text={session.filename} maxLines={1} className="code-text text-sm text-ink" showTooltip={false} />
                        <span className={`mt-1 block text-xs ${pending ? "text-bad" : "text-muted-foreground"}`}>
                          {pending ? t("{n} awaiting review", { n: pending }) : t("All reviewed")}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ol>
            </aside>

            {selected && (
              <div className="min-w-0 space-y-10">
                <h2 className="text-sm text-muted-foreground">
                  {t("Analysis Results:")} <span className="code-text text-ink">{selected.filename}</span>
                </h2>
                <AnalysisReport results={toResults(selected)} isStreaming={false} sessionId={selected.id}
                  reviews={selected.reviews || []} onReviewed={handleReviewed} />
                <Suspense fallback={null}>
                  <ContractIDE key={selected.id} sessionId={selected.id} results={toResults(selected)}
                    reviews={selected.reviews || []} onReviewed={handleReviewed} />
                </Suspense>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
};

export default ReviewQueue;
