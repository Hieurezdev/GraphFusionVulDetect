import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { projectService, FunctionReview, ReviewStatus } from "@/services/project";
import { useT } from "@/i18n";
import { useAuth } from "@/contexts/AuthContext";
import { DEFAULT_VULNERABILITY, notifyFindingsChanged } from "@/lib/findings";

export const AUDIT_LABELS: Record<ReviewStatus, string> = {
  pending: "Awaiting expert check",
  confirmed: "Has the vulnerability (missed by the model)",
  false_positive: "No vulnerability",
  needs_manual_review: "Needs manual review",
};

export const REVIEW_LABELS: Record<ReviewStatus, string> = {
  pending: "Awaiting expert review",
  confirmed: "Confirmed by expert",
  false_positive: "False positive",
  needs_manual_review: "Needs manual review",
};

const CHOICES: ReviewStatus[] = ["confirmed", "false_positive", "needs_manual_review"];

interface Props {
  sessionId?: string;
  vulnerability?: string;
  functionName: string;
  review?: FunctionReview;
  onReviewed: (reviews: FunctionReview[]) => void;
  /** Overrides the verdict labels, e.g. for a random audit where "confirmed" means the model missed a vulnerability. */
  labels?: Record<ReviewStatus, string>;
}

/** Expert verdict on one model alert: an alert is only a lead until a person confirms or rejects it. */
export const FunctionReviewControl = ({ sessionId, vulnerability = DEFAULT_VULNERABILITY, functionName, review, onReviewed, labels = REVIEW_LABELS }: Props) => {
  const t = useT();
  const { user, can } = useAuth();
  const [note, setNote] = useState(review?.note ?? "");
  const [saving, setSaving] = useState(false);
  const current = review?.status ?? "pending";

  const save = async (status: ReviewStatus) => {
    if (!sessionId) return;
    setSaving(true);
    try {
      onReviewed(await projectService.reviewFunction(sessionId, vulnerability, functionName, status, note.trim() || undefined));
      notifyFindingsChanged();
      toast.success(t(labels[status]));
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t("Could not save the review"));
    } finally {
      setSaving(false);
    }
  };

  if (!can("review")) {
    return (
      <div className="mt-3 border-t border-rule pt-3 text-xs text-muted-foreground">
        {t("Expert review")}: <span className="text-ink">{t(labels[current])}</span>
        {review && <> · {review.reviewer}, {new Date(review.reviewed_at).toLocaleString(t.locale)}</>}
        {review?.note && <p className="mt-1 text-ink-2">{review.note}</p>}
        {current === "pending" && <p className="mt-1">{t("Only an expert account can confirm or reject this alert.")}</p>}
      </div>
    );
  }

  return (
    <fieldset className="mt-3 space-y-2 border-t border-rule pt-3" disabled={!sessionId || saving}>
      <legend className="text-xs text-muted-foreground">
        {t("Expert review")}: <span className="text-ink">{t(labels[current])}</span>
        {review && <> · {review.reviewer}, {new Date(review.reviewed_at).toLocaleString(t.locale)}</>}
      </legend>
      <Textarea
        aria-label={t("Review note")}
        placeholder={t("Evidence or reason for your verdict (optional)")}
        value={note}
        onChange={(e) => setNote(e.target.value)}
        className="min-h-[3rem] text-sm"
      />
      <div className="flex flex-wrap gap-2">
        {CHOICES.map((status) => (
          <Button
            key={status}
            size="sm"
            variant={current === status ? "secondary" : "outline"}
            aria-pressed={current === status}
            onClick={() => save(status)}
          >
            {t(labels[status])}
          </Button>
        ))}
      </div>
      {!sessionId && <p className="text-xs text-muted-foreground">{t("Reviews are available once the analysis session is saved.")}</p>}
    </fieldset>
  );
};
