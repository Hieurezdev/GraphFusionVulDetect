import { useState } from 'react';
import { AlertCircle, CheckCircle2, FlaskConical } from 'lucide-react';
import { CompilerDiagnostic, VerificationResult } from '@/services/refactorbot';
import { useT } from '@/i18n';

export interface WorkspaceVerification { target: 'original' | 'proposal'; code: string; testSource: string; result: VerificationResult }
interface Props { run: WorkspaceVerification | null; stale: boolean; onDiagnostic: (item: CompilerDiagnostic) => void; onTests: () => void }

export function RefactorVerificationPanel({ run, stale, onDiagnostic, onTests }: Props) {
  const t = useT();
  const [tab, setTab] = useState<'problems' | 'tests'>('problems');
  const result = run?.result;
  const diagnostics = result?.diagnostics || [];
  return <section className="flex h-full min-h-0 flex-col bg-paper-2" aria-label={t('Compiler and test results')} data-testid="refactor-verification">
    <div className="flex shrink-0 items-center gap-4 border-y border-rule px-3 text-xs">
      <button type="button" data-testid="compiler-problems-tab" onClick={() => setTab('problems')} className={`flex min-h-10 items-center gap-2 border-b-2 ${tab === 'problems' ? 'border-accent text-ink' : 'border-transparent text-muted-foreground'}`}><AlertCircle className="h-3.5 w-3.5" />{t('Problems')} <span className="measured">{diagnostics.length}</span></button>
      <button type="button" data-testid="compiler-tests-tab" onClick={() => setTab('tests')} className={`flex min-h-10 items-center gap-2 border-b-2 ${tab === 'tests' ? 'border-accent text-ink' : 'border-transparent text-muted-foreground'}`}><FlaskConical className="h-3.5 w-3.5" />{t('Tests')} <span className="measured">{result?.tests?.cases.length || 0}</span></button>
      {run && <span className="ml-auto truncate text-muted-foreground">{run.target === 'original' ? 'Original.sol' : 'Proposal.sol'}{result?.compiler ? ` · solc ${result.compiler}` : ''}</span>}
    </div>
    <div className="min-h-0 flex-1 space-y-2 overflow-auto p-3 text-xs">
      {stale && <p role="status" className="text-bad">{t('Files changed after this run. Diagnostics and test results are out of date; run verification again.')}</p>}
      {!result ? <p className="py-3 text-muted-foreground">{t('Run the compiler or behavioral tests. Editor highlighting does not verify the contract.')}</p> : tab === 'problems' ? <>
        <p className="flex items-center gap-2 font-medium">{result.status === 'passed' ? <CheckCircle2 className="h-3.5 w-3.5 text-ok" /> : <AlertCircle className="h-3.5 w-3.5 text-bad" />}{t('Compiler verification')}: {t(result.status === 'passed' ? 'Compilation passed' : result.status === 'failed' ? 'Compilation failed' : 'Not compiled')}</p>
        <p className="whitespace-pre-wrap text-muted-foreground">{t(result.message)}</p>
        {diagnostics.map((item, index) => <button key={index} type="button" data-testid={`compiler-diagnostic-${index}`} disabled={stale || !item.start_line || !['Contract.sol', 'Tests.sol'].includes(item.source_file || '')} onClick={() => onDiagnostic(item)} className="flex w-full gap-3 rounded-sm border border-rule p-2 text-left hover:bg-paper-3 disabled:cursor-default disabled:hover:bg-transparent">
          <span className={item.severity === 'error' ? 'text-bad' : 'text-muted-foreground'}>{t(item.severity)}</span><span className="min-w-0 flex-1 whitespace-pre-wrap">{item.message}</span><span className="code-text shrink-0 text-muted-foreground">{item.source_file === 'Contract.sol' ? run.target === 'original' ? 'Original.sol' : 'Proposal.sol' : item.source_file}{item.start_line ? `:${item.start_line}:${item.start_column || 1}` : ''}</span>
        </button>)}
        {!diagnostics.length && result.warnings.map((warning, index) => <p key={index} className="text-muted-foreground">{t(warning)}</p>)}
      </> : <>
        <p className="font-medium">{t('Behavioral tests')}: {t(result.tests?.status || 'not_run')}</p>
        <p className="text-muted-foreground">{t(result.tests?.message || 'No behavioral tests were supplied. Expert review is required.')}</p>
        {result.tests?.cases.map(item => <div key={item.name} className="border-b border-rule py-2"><p className="code-text"><span className={item.status === 'passed' ? 'text-ok' : 'text-bad'}>{t(item.status)}</span> · {item.name}</p><p className="mt-1 text-muted-foreground">{t(item.message)}</p></div>)}
        <button type="button" className="min-h-8 text-accent underline underline-offset-4" onClick={onTests}>{t('Open Tests.sol')}</button>
      </>}
    </div>
    <p className="shrink-0 border-t border-rule px-3 py-2 text-[11px] text-muted-foreground">{t('Compiler success does not prove security. Inspect the separate behavioral test report and obtain expert review before applying the proposal.')}</p>
  </section>;
}
