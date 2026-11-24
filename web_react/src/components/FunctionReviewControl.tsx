import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { projectService, FunctionReview, ReviewStatus } from "@/services/project";
import { useT } from "@/i18n";

export const REVIEW_LABELS: Record<ReviewStatus, string> = {
  pending: "Awaiting expert review",
  confirmed: "Confirmed by expert",
  false_positive: "False positive",
  needs_manual_review: "Needs manual review",
};

const CHOICES: ReviewStatus[] = ["confirmed", "false_positive", "needs_manual_review"];

interface Props {
  sessionId?: string;
  functionName: string;
  review?: FunctionReview;
  onReviewed: (reviews: FunctionReview[]) => void;
}

/** Expert verdict on one model alert: an alert is only a lead until a person confirms or rejects it. */
export const FunctionReviewControl = ({ sessionId, functionName, review, onReviewed }: Props) => {
  const t = useT();
  const [note, setNote] = useState(review?.note ?? "");
  const [saving, setSaving] = useState(false);
  const current = review?.status ?? "pending";

  const save = async (status: ReviewStatus) => {
    if (!sessionId) return;
    setSaving(true);
    try {
      onReviewed(await projectService.reviewFunction(sessionId, functionName, status, note.trim() || undefined));
      toast.success(t(REVIEW_LABELS[status]));
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t("Could not save the review"));
    } finally {
      setSaving(false);
    }
  };

  return (
    <fieldset className="mt-3 space-y-2 border-t border-rule pt-3" disabled={!sessionId || saving}>
      <legend className="text-xs text-muted-foreground">
        {t("Expert review")}: <span className="text-ink">{t(REVIEW_LABELS[current])}</span>
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
            {t(REVIEW_LABELS[status])}
          </Button>
        ))}
      </div>
      {!sessionId && <p className="text-xs text-muted-foreground">{t("Reviews are available once the analysis session is saved.")}</p>}
    </fieldset>
  );
};
