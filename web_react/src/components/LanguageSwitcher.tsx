import { Languages } from 'lucide-react';
import { usePreferences, writePreferences } from '@/lib/preferences';
import { useT } from '@/i18n';

export function LanguageSwitcher({ id }: { id: string }) {
  const { language } = usePreferences();
  const t = useT();
  return <div className="inline-flex shrink-0 items-center gap-2 rounded-full border border-rule-2 bg-paper-2 px-3 text-ink">
    <Languages aria-hidden="true" className="h-3.5 w-3.5 text-muted-foreground" />
    <select id={id} data-testid={id} aria-label={t('Language')} value={language} className="h-9 min-w-24 cursor-pointer rounded-sm bg-transparent pr-1 text-xs outline-offset-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-ring" onChange={event => {
      const next = event.target.value;
      if (next === 'en' || next === 'vi') writePreferences({ language: next });
    }}>
      <option value="en" lang="en" className="bg-paper-2 text-ink">English</option>
      <option value="vi" lang="vi" className="bg-paper-2 text-ink">Tiếng Việt</option>
    </select>
  </div>;
}
