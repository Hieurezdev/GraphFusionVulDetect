import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { LegalText } from "@/components/LegalText";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Wordmark } from "@/components/Wordmark";
import { useAuth } from "@/contexts/AuthContext";
import AuthService, { type LegalDocument } from "@/services/auth";
import { readPreferences } from "@/lib/preferences";
import { toast } from "sonner";
import { useT } from "@/i18n";

/** First sign-in (or a new version of a text): accept the required texts; a workspace admin also decides on training data. */
const Consent = () => {
  const t = useT();
  const navigate = useNavigate();
  const { user, can, setProfile, logout } = useAuth();
  const [docs, setDocs] = useState<LegalDocument[] | null>(null);
  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const [training, setTraining] = useState(false);
  const [busy, setBusy] = useState(false);
  const admin = can("manage_organization");

  useEffect(() => {
    AuthService.legal(t.language).then(setDocs).catch(() => setDocs([]));
  }, [t.language]);  // eslint-disable-line react-hooks/exhaustive-deps

  const required = (docs ?? []).filter(d => d.required);
  const ready = required.length > 0 && required.every(d => checked[d.key]);

  const submit = async () => {
    setBusy(true);
    try {
      const profile = await AuthService.submitConsents({
        terms: !!checked.terms, privacy: !!checked.privacy, upload_rights: !!checked.upload_rights,
        ...(admin ? { training_data: training } : {}),
      });
      setProfile(profile);
      navigate(readPreferences().startPage || "/analysis", { replace: true });
    } catch (e) {
      toast.error(e instanceof Error ? e.message : t("Could not save your answers"));
    } finally {
      setBusy(false);
    }
  };

  const optional = (docs ?? []).find(d => d.key === "training_data");

  return (
    <div className="min-h-dvh bg-background">
      <main id="main" className="shell max-w-3xl py-10 lg:py-14">
        <Wordmark />
        <h1 className="mt-8 text-3xl leading-tight">{t("Before you start")}</h1>
        <p className="mt-3 text-ink-2">
          {t("Read and accept the texts below to use ScanGuard. Nothing is pre-selected. You can read them again and withdraw the optional choice later, under Privacy in your profile.")}
        </p>
        {user?.organization_name && !user.personal_workspace && (
          <p className="mt-2 text-sm text-muted-foreground">{t("Workspace: {name}", { name: user.organization_name })}</p>
        )}

        {docs === null ? (
          <p className="mt-8 text-sm text-muted-foreground" role="status">{t("Loading…")}</p>
        ) : (
          <div className="mt-8 space-y-6">
            {required.map(doc => (
              <section key={doc.key} className="panel p-5" aria-labelledby={`doc-${doc.key}`}>
                <h2 id={`doc-${doc.key}`} className="text-lg">{doc.title}</h2>
                <div className="mt-3 max-h-64 max-w-none overflow-y-auto border-y border-rule py-3 text-ink-2" tabIndex={0}>
                  <LegalText content={doc.content} />
                </div>
                <div className="mt-3 flex items-center gap-3">
                  <Checkbox id={`accept-${doc.key}`} checked={!!checked[doc.key]}
                    onCheckedChange={v => setChecked(c => ({ ...c, [doc.key]: v === true }))} />
                  <Label htmlFor={`accept-${doc.key}`} className="text-sm text-ink">{t("I have read and accept: {title}", { title: doc.title })}</Label>
                </div>
              </section>
            ))}

            {optional && (
              <section className="panel p-5" aria-labelledby="doc-training">
                <h2 id="doc-training" className="text-lg">{optional.title} <span className="text-xs text-muted-foreground">{t("optional")}</span></h2>
                <div className="mt-3 max-h-48 max-w-none overflow-y-auto border-y border-rule py-3 text-ink-2" tabIndex={0}>
                  <LegalText content={optional.content} />
                </div>
                {admin ? (
                  <div className="mt-3 flex items-center justify-between gap-6">
                    <Label htmlFor="training" className="text-sm text-ink">{t("Allow this workspace's code to be used as training data")}</Label>
                    <Switch id="training" checked={training} onCheckedChange={setTraining} />
                  </div>
                ) : (
                  <p className="mt-3 text-sm text-ink-2">
                    {user?.policy?.training_data
                      ? t("Your workspace admin has turned this on for the workspace.")
                      : t("Your workspace admin has turned this off for the workspace.")}
                  </p>
                )}
              </section>
            )}

            <div className="flex flex-wrap items-center gap-3">
              <Button onClick={submit} disabled={!ready || busy}>{t("Accept and continue")}</Button>
              <Button variant="outline" onClick={logout} disabled={busy}>{t("Decline and sign out")}</Button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
};

export default Consent;
