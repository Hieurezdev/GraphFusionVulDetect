import { useEffect, useRef, useState } from "react";
import { AlertTriangle, Loader2, ShieldCheck } from "lucide-react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { AiPayload, AiReview, ApprovedAiRequest, refactorBotService } from "@/services/refactorbot";
import { useT } from "@/i18n";

interface Props {
  request: AiPayload | null;
  onApprove: (payload: ApprovedAiRequest) => void;
  onCancel: () => void;
}

export const AiConsentDialog = ({ request, onApprove, onCancel }: Props) => {
  const t = useT();
  const [draft, setDraft] = useState<AiPayload | null>(null);
  const [review, setReview] = useState<AiReview | null>(null);
  const [loading, setLoading] = useState(false);
  const [dirty, setDirty] = useState(false);
  const [error, setError] = useState("");
  const controller = useRef<AbortController | null>(null);

  const inspect = async (payload: AiPayload) => {
    controller.current?.abort();
    const current = new AbortController();
    controller.current = current;
    setLoading(true);
    setError("");
    try {
      const result = await refactorBotService.review(payload, current.signal);
      if (!current.signal.aborted) {
        setReview(result);
        setDraft(result.payload);
        setDirty(false);
      }
    } catch (failure) {
      if (!current.signal.aborted) setError(failure instanceof Error ? t(failure.message) : t("Review failed. No content was sent to AI."));
    } finally {
      if (!current.signal.aborted) setLoading(false);
    }
  };

  useEffect(() => {
    setDraft(request);
    setReview(null);
    setDirty(false);
    if (request) void inspect(request);
    return () => controller.current?.abort();
    // A new request starts a new review; language changes do not approve existing content.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [request]);

  const edit = (change: Partial<AiPayload>) => {
    if (draft) setDraft({ ...draft, ...change });
    setDirty(true);
  };

  return (
    <Dialog open={request !== null} onOpenChange={open => { if (!open) onCancel(); }}>
      <DialogContent className="z-[60] max-h-[90dvh] w-[calc(100%-1.5rem)] max-w-3xl overflow-y-auto" data-testid="ai-consent-dialog">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2"><ShieldCheck className="h-5 w-5" />{t("Review before sending to AI")}</DialogTitle>
          <DialogDescription>{t("Only the content shown here will be sent. Names and identity numbers may be missed; review them yourself using [NAME] and [CCCD].")}</DialogDescription>
        </DialogHeader>
        {loading && <p role="status" className="flex items-center gap-2 text-sm"><Loader2 className="h-4 w-4 animate-spin" />{t("Checking locally. Nothing has been sent to the AI provider.")}</p>}
        {error && <p role="alert" className="rounded-md bg-bad-soft p-3 text-sm text-bad">{error}</p>}
        {review && <>
          <dl className="border-y border-rule py-3 text-sm">
            <div><dt className="text-muted-foreground">{t("Recipient")}</dt><dd className="break-all">{review.provider}</dd></div>
          </dl>
          {!review.encrypted_transport && <p role="alert" className="rounded-md bg-bad-soft p-3 text-sm text-bad">{t("This AI endpoint uses HTTP without TLS. Do not send personal data, credentials or confidential source code over this connection.")}</p>}
          {review.findings.length > 0 && <div className="flex flex-wrap gap-2" aria-label={t("Detected information")}>
            {review.findings.map(finding => <Badge key={finding.category} variant="outline">{t(({ NAME: "Name", CCCD: "Identity number", EMAIL: "Email", PHONE: "Phone", ADDRESS: "Home address", SECRET: "Secret", instruction_override: "Instruction override", role_spoofing: "Role spoofing", secret_exfiltration: "Secret exfiltration request" } as Record<string, string>)[finding.category] || finding.category)}: {finding.count}</Badge>)}
          </div>}
          {review.blocked && <p role="alert" className="flex gap-2 rounded-md bg-bad-soft p-3 text-sm text-bad"><AlertTriangle className="h-4 w-4 shrink-0" />{t("Sending is blocked: a secret or instruction override was detected. Remove it and check the content again.")}</p>}
        </>}
        {draft && <div className="space-y-4">
          <div className="space-y-2"><Label htmlFor="ai-reviewed-code">{t("Source sent to AI — editable redacted copy")}</Label>
            <Textarea id="ai-reviewed-code" data-testid="ai-reviewed-code" className="code-text min-h-44 text-xs" value={draft.code} disabled={loading} onChange={event => edit({ code: event.target.value })} />
          </div>
          {draft.operation === "advice" ? <div className="space-y-2"><Label htmlFor="ai-reviewed-issue">{t("Finding to discuss")}</Label>
            <Textarea id="ai-reviewed-issue" value={draft.issue_description} disabled={loading} onChange={event => edit({ issue_description: event.target.value })} />
          </div> : <div className="space-y-3">
            <p className="text-sm text-muted-foreground">{t("Conversation included in this request")}</p>
            {draft.conversation_history.map((message, index) => <div key={index} className="space-y-1">
              <Label htmlFor={`ai-reviewed-message-${index}`}>{message.role === "user" ? t("Your message") : t("Previous AI response")}</Label>
              <Textarea id={`ai-reviewed-message-${index}`} value={message.content} disabled={loading || index < draft.conversation_history.length - 1} className="max-h-32 text-xs" onChange={event => edit({ conversation_history: draft.conversation_history.map((item, position) => position === index ? { ...item, content: event.target.value } : item) })} />
            </div>)}
          </div>}
          <p className="text-xs text-muted-foreground">{t("Editing this copy does not change your uploaded contract. Only approved, redacted chat history is saved. Rule-based screening cannot detect every sensitive value or prompt injection.")}</p>
        </div>}
        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onCancel} data-testid="ai-consent-cancel">{t("Cancel")}</Button>
          {draft && (dirty || review?.blocked || error) && <Button variant="outline" disabled={loading} onClick={() => void inspect(draft)} data-testid="ai-consent-rescan">{t("Check edited content")}</Button>}
          <Button disabled={loading || dirty || !review?.review_token || review.blocked} data-testid="ai-consent-send" onClick={() => {
            if (review?.review_token && !review.blocked && !dirty) onApprove({ ...review.payload, review_token: review.review_token, consent_confirmed: true });
          }}>{t("I agree — send this content")}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
