import { Badge } from "@/components/ui/badge";
import { useT } from "@/i18n";

export const AiResultNotice = ({ score, kind }: { score?: string; kind: "prediction" | "explanation" }) => {
  const t = useT();
  return <aside className="space-y-2 border-l-2 border-signal bg-paper-2 px-3 py-3 text-xs" aria-label={t("AI result information")}>
    <div className="flex flex-wrap items-center gap-2"><Badge variant="outline">{t('AI-generated content')}</Badge></div>
    <p className="text-ink-2">{kind === "prediction" ? `${t("Model score — not calibrated")}: ${score || t("Unavailable")}` : t("LLM confidence has not been calibrated; no reliable percentage is available.")}</p>
    <p className="text-muted-foreground">{t("AI may miss vulnerabilities or flag safe code. Review the evidence and test changes before applying them. Model confidence is not vulnerability severity.")}</p>
  </aside>;
};
