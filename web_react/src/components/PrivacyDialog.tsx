import { useEffect, useState } from "react";
import { LegalText } from "@/components/LegalText";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/contexts/AuthContext";
import AuthService, { type LegalDocument } from "@/services/auth";
import { toast } from "sonner";
import { useT } from "@/i18n";

export const ROLE_LABELS: Record<string, string> = { admin: "Admin", developer: "Developer", non_tech: "Non-tech", expert: "Expert" };

/** Privacy: the workspace and role, the texts accepted, how the workspace handles code, and deleting the account. */
const PrivacyDialog = ({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) => {
  const t = useT();
  const { user } = useAuth();
  const [docs, setDocs] = useState<LegalDocument[]>([]);
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (open) AuthService.legal(t.language).then(setDocs).catch(() => setDocs([]));
  }, [open, t.language]);  // eslint-disable-line react-hooks/exhaustive-deps

  if (!user) return null;
  const policy = user.policy;
  const alone = user.personal_workspace;

  const deleteAccount = async () => {
    if (!window.confirm(alone
      ? t("Delete your account and your whole workspace (projects, scans, code)? This cannot be undone.")
      : t("Delete your account? Your scans stay in the workspace, which owns them. This cannot be undone."))) return;
    setBusy(true);
    try {
      await AuthService.deleteAccount(password);
      toast.success(t("Account deleted"));
      window.location.href = "/";
    } catch (e) {
      toast.error(e instanceof Error ? e.message : t("Could not delete the account"));
      setBusy(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] max-w-2xl overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{t("Privacy")}</DialogTitle>
          <DialogDescription>
            {t("Workspace: {name} · Role: {role}", { name: user.organization_name || t("ScanGuard reviewer"), role: user.personal_workspace ? t("Personal (guest)") : t(ROLE_LABELS[user.role ?? "admin"] ?? user.role ?? "") })}
          </DialogDescription>
        </DialogHeader>

        {policy && (
          <section aria-labelledby="privacy-policy">
            <h3 id="privacy-policy" className="text-sm text-muted-foreground">{t("How your workspace handles code")}</h3>
            <ul className="mt-2 space-y-1 text-sm text-ink-2">
              <li>{t("Scans and their code are deleted automatically after {d} days.", { d: policy.retention_days })}</li>
              <li>{user.llm_external && policy.external_llm ? t("Flagged function code is sent to an external AI service for explanations and fixes.") : t("No code is sent to an external AI service.")}</li>
              <li>{policy.training_data ? t("The workspace's code may be used as training data.") : t("The workspace's code is not used as training data.")}</li>
              <li>{policy.platform_experts ? t("ScanGuard reviewers may open scans sent to them for review.") : t("Only the workspace's own experts review its scans.")}</li>
            </ul>
            {!user.permissions.includes("manage_organization") && <p className="mt-2 text-xs text-muted-foreground">{t("Only the workspace admin can change these.")}</p>}
          </section>
        )}

        <section aria-labelledby="privacy-docs" className="mt-4">
          <h3 id="privacy-docs" className="text-sm text-muted-foreground">{t("Texts you accepted")}</h3>
          <Accordion type="single" collapsible className="mt-1">
            {docs.map(d => (
              <AccordionItem key={d.key} value={d.key}>
                <AccordionTrigger className="text-sm">{d.title}</AccordionTrigger>
                <AccordionContent>
                  <div className="max-w-none text-ink-2"><LegalText content={d.content} /></div>
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </section>

        <section aria-labelledby="privacy-delete" className="mt-4 border-t border-rule pt-4">
          <h3 id="privacy-delete" className="text-sm text-bad">{t("Delete account")}</h3>
          <p className="mt-1 text-xs text-ink-2">
            {alone
              ? t("You are alone in your workspace: the workspace, its projects, scans and code are deleted with the account.")
              : t("Your personal data is deleted; the scans stay with the workspace. Your name on expert verdicts becomes a pseudonym.")}
          </p>
          <div className="mt-3 flex flex-wrap items-end gap-3">
            <div className="space-y-1">
              <Label htmlFor="delete-password" className="text-xs">{t("Password")}</Label>
              <Input id="delete-password" type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} />
            </div>
            <Button variant="destructive" disabled={!password || busy} onClick={deleteAccount}>{t("Delete account")}</Button>
          </div>
        </section>
      </DialogContent>
    </Dialog>
  );
};

export default PrivacyDialog;
