import { beforeEach, describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { LanguageSwitcher } from './LanguageSwitcher';
import SettingsDialog from './SettingsDialog';
import { useT } from '@/i18n';
import { readPreferences, writePreferences } from '@/lib/preferences';

function LocalizedContent() {
  const t = useT();
  return <p data-testid="translated-content">{t('Generate AI repair')}</p>;
}

beforeEach(() => localStorage.clear());

describe('website language selection', () => {
  it('updates all selectors and visible translations, and preserves the choice after remounting', () => {
    const view = render(<><LanguageSwitcher id="language-header" /><LanguageSwitcher id="language-ide" /><LocalizedContent /></>);
    fireEvent.change(screen.getByTestId('language-header'), { target: { value: 'vi' } });
    expect((screen.getByTestId('language-ide') as HTMLSelectElement).value).toBe('vi');
    expect(screen.getByTestId('translated-content').textContent).toBe('Tạo bản sửa AI');
    expect(readPreferences().language).toBe('vi');
    view.unmount();
    render(<><LanguageSwitcher id="language-header" /><LocalizedContent /></>);
    expect((screen.getByTestId('language-header') as HTMLSelectElement).value).toBe('vi');
    fireEvent.change(screen.getByTestId('language-header'), { target: { value: 'en' } });
    expect(screen.getByTestId('translated-content').textContent).toBe('Generate AI repair');
    expect(readPreferences().language).toBe('en');
  });

  it('stays synchronized with the existing language setting without resetting other preferences', () => {
    writePreferences({ animateScans: false, startPage: '/project' });
    render(<><LanguageSwitcher id="language-header" /><SettingsDialog open onOpenChange={() => {}} /></>);
    const vietnamese = document.getElementById('lang-vi');
    expect(vietnamese).not.toBeNull();
    fireEvent.click(vietnamese!);
    expect((screen.getByTestId('language-header') as HTMLSelectElement).value).toBe('vi');
    expect(readPreferences()).toMatchObject({ language: 'vi', animateScans: false, startPage: '/project' });
  });
});
