import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Trash2, Send } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription,
  AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { useAuth } from "@/contexts/AuthContext";
import { projectService, type AnalysisSession } from "@/services/project";
import { toast } from "sonner";
import { useT } from "@/i18n";

/** A finished scan's data controls: when it is deleted automatically, send it to the experts, delete it now. */
export const SessionActions = ({ sessionId }: { sessionId: string }) => {
  const t = useT();
  const navigate = useNavigate();
  const { user, can } = useAuth();
  const [session, setSession] = useState<AnalysisSession | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    projectService.getAnalysisSession(sessionId).then(setSession).catch(() => setSession(null));
  }, [sessionId]);

  if (!session) return null;
  const mine = session.user_id === user?.id;
  const canDelete = can("delete_any_session") || (mine && can("delete_own_session"));

  const remove = async () => {
    setBusy(true);
    try {
      const { removed } = await projectService.deleteSession(sessionId);
      toast.success(t("Scan deleted: {f} file(s), its results and {k} knowledge-base item(s) removed", { f: removed.files ?? 0, k: removed.knowledge_items ?? 0 }));
      navigate(session.project_id ? `/project/${session.project_id}` : "/project", { replace: true });
    } catch (e) {
      toast.error(e instanceof Error ? e.message : t("Could not delete the scan"));
      setBusy(false);
    }
  };

  const askReview = async () => {
    setBusy(true);
    try {
      setSession(await projectService.requestReview(sessionId));
      toast.success(t("Sent to the experts"));
    } catch (e) {
      toast.error(e instanceof Error ? e.message : t("Could not send the scan for review"));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
      {session.expires_at && (
        <span title={t("The workspace's retention period; the admin can change it")}>
          {t("Deleted automatically on {d}", { d: new Date(session.expires_at).toLocaleDateString(t.locale) })}
        </span>
      )}
      {can("request_review") && (
        session.review_requested
          ? <span>{t("Sent for expert review")}</span>
          : <Button size="sm" variant="outline" disabled={busy} onClick={askReview}><Send className="h-3 w-3" aria-hidden="true" />{t("Send for expert review")}</Button>
      )}
      {canDelete && (
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button size="sm" variant="outline" disabled={busy || session.status === "processing"}>
              <Trash2 className="h-3 w-3" aria-hidden="true" />{t("Delete scan")}
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{t("Delete this scan?")}</AlertDialogTitle>
              <AlertDialogDescription>
                {t("The uploaded file, its call graphs, the results and fixes are removed for good, the code is removed from the knowledge base and scrubbed from the label log. Expert verdicts are kept without the code.")}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t("Cancel")}</AlertDialogCancel>
              <AlertDialogAction onClick={remove}>{t("Delete")}</AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      )}
    </div>
  );
};
