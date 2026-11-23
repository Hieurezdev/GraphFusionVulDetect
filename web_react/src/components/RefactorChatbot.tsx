import { lazy, Suspense, useEffect, useMemo, useRef, useState } from 'react';
import * as DialogPrimitive from '@radix-ui/react-dialog';
import { AlertTriangle, ArrowDownToLine, FileCode2, Files, FlaskConical, GitCompare, Loader2, MessageSquare, Play, RotateCcw, Save, Send, ShieldCheck, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogDescription, DialogOverlay, DialogPortal, DialogTitle } from '@/components/ui/dialog';
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from '@/components/ui/resizable';
import { AiConsentDialog } from '@/components/AiConsentDialog';
import { AiResultNotice } from '@/components/AiResultNotice';
import { HumanRepairReview } from '@/components/HumanRepairReview';
import { LanguageSwitcher } from '@/components/LanguageSwitcher';
import { RefactorVerificationPanel, WorkspaceVerification } from '@/components/RefactorVerificationPanel';
import type { EditorFile, EditorJump, EditorSelection } from '@/components/RefactorCodeEditor';
import { AiPayload, ApprovedAiRequest, CompilerDiagnostic, ConversationMessage, RefactorResponse, downloadEvidence, downloadSource, refactorBotService } from '@/services/refactorbot';
import { apiFetch } from '@/services/api';
import { useIsMobile } from '@/hooks/use-mobile';
import { readPreferences } from '@/lib/preferences';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { useT } from '@/i18n';

const RefactorCodeEditor = lazy(() => import('@/components/RefactorCodeEditor'));
type FunctionFinding = { function_name: string; prediction: number; confidence: string; function_code: string };
interface Props { vulnerableFunctions: FunctionFinding[]; sessionId?: string; initialCode?: string; hasFinding?: boolean }
const fileNames: Record<EditorFile, string> = { original: 'Original.sol', proposal: 'Proposal.sol', tests: 'Tests.sol', diff: 'Diff' };

export const RefactorChatbot = ({ vulnerableFunctions, sessionId, initialCode, hasFinding = false }: Props) => {
  const t = useT();
  const isMobile = useIsMobile();
  const [isOpen, setIsOpen] = useState(false);
  const [selected, setSelected] = useState<FunctionFinding | null>(null);
  const [source, setSource] = useState('');
  const [draft, setDraft] = useState('');
  const [tests, setTests] = useState('');
  const [verifiedTests, setVerifiedTests] = useState('');
  const [history, setHistory] = useState<ConversationMessage[]>([]);
  const [response, setResponse] = useState<RefactorResponse | null>(null);
  const [run, setRun] = useState<WorkspaceVerification | null>(null);
  const [activeFile, setActiveFile] = useState<EditorFile>('original');
  const [rightTab, setRightTab] = useState<'chat' | 'review'>('chat');
  const [editorSelection, setEditorSelection] = useState<EditorSelection | null>(null);
  const [jump, setJump] = useState<EditorJump | null>(null);
  const [input, setInput] = useState('');
  const [chatContext, setChatContext] = useState<'workspace' | 'selection'>('workspace');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [pending, setPending] = useState<AiPayload | null>(null);
  const [requestKind, setRequestKind] = useState<'explanation' | 'discussion' | 'repair' | null>(null);
  const requestVersion = useRef(0);
  const buffers = useRef(new Map<string, { draft: string; tests: string }>());
  const flagged = vulnerableFunctions.filter(item => item.prediction === 1);
  const choices = flagged.length ? flagged : vulnerableFunctions.length ? vulnerableFunctions : [{ function_name: 'Contract-level finding', prediction: 0, confidence: '', function_code: '' }];
  const contextId = selected ? (sessionId || 'current-analysis') + ':' + selected.function_name : null;
  const draftChanged = !!selected && draft !== (response?.suggested_code || source);
  const testsChanged = tests !== verifiedTests;
  const confirmed = response?.finding_review?.decision === 'confirmed';
  const hasRepair = !!response?.suggested_code && response.suggested_code.trim() !== source.trim();
  const runStale = !!run && (run.code !== (run.target === 'original' ? source : draft) || (run.testSource !== '' && run.testSource !== tests));
  const scope = useMemo(() => {
    if (!selected?.function_code || selected.prediction !== 1) return null;
    const offset = source.indexOf(selected.function_code);
    if (offset < 0 || source.indexOf(selected.function_code, offset + 1) >= 0) return null;
    const start = source.slice(0, offset).split('\n').length;
    return { start, end: start + selected.function_code.split('\n').length - 1 };
  }, [source, selected]);

  useEffect(() => {
    if (!draftChanged && !testsChanged) return;
    const warn = (event: BeforeUnloadEvent) => { event.preventDefault(); event.returnValue = ''; };
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [draftChanged, testsChanged]);

  const choose = async (name: string) => {
    const item = choices.find(candidate => candidate.function_name === name);
    if (!item || loading) return;
    if (contextId) buffers.current.set(contextId, { draft, tests });
    const version = ++requestVersion.current;
    setSelected(item); setHistory([]); setResponse(null); setRun(null); setVerifiedTests(''); setEditorSelection(null);
    setError(''); setInput(''); setRequestKind(null); setChatContext('workspace'); setActiveFile('original'); setRightTab('chat'); setLoading(true);
    setSource(initialCode || item.function_code); setDraft(initialCode || item.function_code); setTests('');
    try {
      const context = (sessionId || 'current-analysis') + ':' + item.function_name;
      const saved = await refactorBotService.getThread(context);
      if (requestVersion.current !== version) return;
      let original = initialCode || item.function_code;
      if (saved) {
        original = saved.code;
        setHistory(saved.conversation_history); setResponse(saved.response); setVerifiedTests(saved.test_source || '');
        if (saved.response.suggested_code) setRun({ target: 'proposal', code: saved.response.suggested_code, testSource: saved.test_source || '', result: saved.response.verification });
      } else if (sessionId && !initialCode) {
        const file = await apiFetch<{ code: string; filename: string }>('/api/v1/sessions/' + sessionId + '/source', { requireAuth: true });
        if (requestVersion.current !== version) return;
        original = file.code;
      }
      const buffer = buffers.current.get(context);
      const loadedDraft = buffer?.draft ?? saved?.response.suggested_code ?? original;
      setSource(original); setDraft(loadedDraft); setTests(buffer?.tests ?? saved?.test_source ?? '');
      if (loadedDraft.trim() !== original.trim()) setActiveFile('diff');
    } catch (failure) { setError(failure instanceof Error ? t(failure.message) : t('Failed to load conversation')); }
    finally { if (requestVersion.current === version) setLoading(false); }
  };

  const prepare = (operation: 'advice' | 'conversation', text: string, context: 'workspace' | 'selection') => {
    if (!selected || !source.trim() || loading || (operation === 'conversation' && (!text.trim() || !confirmed))) return;
    let message = text;
    if (operation === 'conversation' && context === 'workspace' && draft !== source) {
      message += '\n\nCurrent workspace Proposal.sol (untrusted code, not applied):\n' + draft;
    }
    setError('');
    setRequestKind(operation === 'advice' ? 'explanation' : 'discussion');
    setPending({ operation, code: source,
      issue_description: 'Review ' + selected.function_name + '. ' + (selected.prediction === 1 ? 'The function-level model flagged this function.' : 'Only a contract-level finding is available; this function was not individually flagged.') + ' The model score is ' + (selected.confidence || 'unavailable') + ' and is uncalibrated. Confirm code evidence and missing context; do not infer security from warnings or their absence.',
      conversation_history: operation === 'conversation' ? [...history, { role: 'user', content: message }] : [],
      language: readPreferences().language, thread_id: operation === 'conversation' ? response?.thread_id || null : null, context_id: contextId });
  };

  const prepareRepair = () => {
    if (!selected || !response?.finding_review || !confirmed || loading) return;
    const review = response.finding_review;
    const message = t('Generate a complete repaired Solidity contract for the confirmed finding. Preserve the original pragma and unrelated behavior. Return the complete contract in one fenced solidity code block, explain the changes and remaining risks, and do not claim the code is secure.')
      + '\n' + t('Function') + ': ' + selected.function_name + '\n' + t('Reviewed source lines') + ': ' + review.start_line + '–' + review.end_line + '\n' + t('Reviewer evidence') + ': ' + review.evidence_note;
    prepare('conversation', message, 'workspace');
    setRequestKind('repair');
  };

  const receiveReview = (next: RefactorResponse) => {
    setResponse(next);
    if (!confirmed && next.finding_review?.decision === 'confirmed') setRightTab('chat');
  };

  const approve = async (approved: ApprovedAiRequest) => {
    const expectsRepair = requestKind === 'repair';
    setPending(null); setLoading(true); setError('');
    try {
      const result = await refactorBotService.send(approved);
      setSource(approved.code); setResponse(result); setVerifiedTests('');
      setHistory([...approved.conversation_history, { role: 'assistant', content: result.bot_message }]); setInput('');
      if (result.suggested_code) {
        setDraft(result.suggested_code); setActiveFile('diff'); setEditorSelection(null);
        setRun({ target: 'proposal', code: result.suggested_code, testSource: '', result: result.verification });
        if (expectsRepair && result.suggested_code.trim() === approved.code.trim()) setError(t('The AI returned unchanged code. No repair was made; review the evidence or request a revised proposal.'));
      } else if (approved.operation === 'advice') { setRightTab('review'); }
      else if (expectsRepair) { setError(t('The AI did not return a code proposal. The editor has not received a repair; review the answer and request a complete Solidity contract.')); setRightTab('chat'); }
    } catch (failure) { setError(failure instanceof Error ? t(failure.message) : t('Failed to send message')); }
    finally { setLoading(false); setRequestKind(null); }
  };

  const persistDraft = async (): Promise<RefactorResponse> => {
    if (!response || !confirmed) throw new Error('Confirm the finding before saving a repair proposal.');
    if (draft === response.suggested_code) return response;
    const saved = await refactorBotService.saveProposal({ thread_id: response.thread_id, previous_proposal: response.suggested_code, proposed_code: draft });
    setResponse(saved); setRun({ target: 'proposal', code: draft, testSource: '', result: saved.verification });
    return saved;
  };
  const save = async () => {
    if (loading || !draft.trim()) return;
    setLoading(true); setError('');
    try { await persistDraft(); } catch (failure) { setError(failure instanceof Error ? t(failure.message) : t('Review could not be saved.')); }
    finally { setLoading(false); }
  };
  const verify = async (target: 'original' | 'proposal', harness: string | undefined) => {
    if (loading || !(target === 'original' ? source : draft).trim()) return;
    setLoading(true); setError('');
    try {
      const code = target === 'original' ? source : draft;
      if (harness !== undefined && !harness.trim()) throw new Error('Write behavioral assertions in Tests.sol before running tests.');
      let result;
      if (target === 'proposal' && response && confirmed) {
        const saved = await persistDraft();
        result = await refactorBotService.validateRefactoring(source, draft, saved.thread_id, harness);
        setResponse({ ...saved, verification: result, proposal_review: null }); setVerifiedTests(harness || '');
      } else { result = await refactorBotService.compileSource(code, harness); }
      setRun({ target, code, testSource: harness || '', result });
    } catch (failure) { setError(failure instanceof Error ? t(failure.message) : t('Failed to validate code')); }
    finally { setLoading(false); }
  };
  const compileCurrent = () => { if (activeFile === 'tests') void verify('proposal', tests); else void verify(activeFile === 'original' ? 'original' : 'proposal', undefined); };
  const openFile = (file: EditorFile) => { setActiveFile(file); setEditorSelection(null); };
  const reveal = (file: EditorFile, line: number, column = 1) => {
    openFile(file); setJump(previous => ({ file, line, column, sequence: (previous?.sequence || 0) + 1 }));
  };
  const diagnostic = (item: CompilerDiagnostic) => reveal(item.source_file === 'Tests.sol' ? 'tests' : run?.target === 'original' ? 'original' : 'proposal', item.start_line || 1, item.start_column || 1);
  const exportSarif = async () => {
    if (!sessionId || loading) return;
    setLoading(true); setError('');
    try { downloadEvidence('graphfusion.sarif', await apiFetch<object>('/api/v1/sessions/' + sessionId + '/sarif', { requireAuth: true })); }
    catch (failure) { setError(failure instanceof Error ? t(failure.message) : t('Review could not be saved.')); }
    finally { setLoading(false); }
  };
  const askSelection = () => {
    if (!editorSelection?.text) return;
    const excerpt = editorSelection.text;
    setInput(t('Explain the evidence') + ' — ' + fileNames[editorSelection.file] + ', ' + t('Lines') + ' ' + editorSelection.startLine + '–' + editorSelection.endLine + ':\n' + excerpt); setChatContext('selection'); setRightTab('chat');
  };
  const markerDiagnostics = !runStale && run && ((activeFile === 'original' && run.target === 'original') || (activeFile !== 'original' && run.target === 'proposal')) ? run.result.diagnostics || [] : [];

  if (!hasFinding && flagged.length === 0) return null;
  return <>
    {!isOpen && <Button onClick={() => setIsOpen(true)} variant="secondary" className="fixed bottom-6 right-6 z-40 h-12 gap-2 px-5" aria-label={t('Open Refactor Assistant')} data-testid="refactor-open"><MessageSquare className="h-4 w-4" />{t('Refactor Assistant')}<span className="code-text rounded-sm bg-paper-3 px-1.5 text-xs">IDE</span></Button>}
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogPortal>
        <DialogOverlay className="z-40" />
        <DialogPrimitive.Content data-testid="refactor-panel" className="refactor-ide fixed inset-0 z-50 flex min-h-0 flex-col overflow-hidden bg-paper text-ink md:inset-3 md:rounded-md md:border md:border-rule-2" onInteractOutside={event => event.preventDefault()} onEscapeKeyDown={event => { if (pending) event.preventDefault(); }}>
          <header className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-rule bg-paper-2 px-4 py-3">
            <div className="flex items-center gap-3"><FileCode2 className="h-5 w-5 text-accent" /><div><DialogTitle className="text-sm font-medium">{t('Refactor Assistant')} <span className="code-text ml-2 text-xs text-muted-foreground">IDE</span></DialogTitle><DialogDescription className="text-[11px] text-muted-foreground">{t('Inspect evidence, edit a proposal, run checks, then request expert review.')}</DialogDescription></div></div>
            <div className="flex items-center gap-3">{loading && <span role="status" className="flex items-center gap-2 text-xs text-muted-foreground"><Loader2 className="h-3.5 w-3.5 animate-spin" />{t('Working…')}</span>}<span className="hidden text-xs text-muted-foreground sm:block">{t('Changes are drafts until reviewed and manually applied.')}</span><LanguageSwitcher id="language-select-ide" /><Button size="icon" variant="ghost" data-testid="refactor-close" onClick={() => setIsOpen(false)} aria-label={t('Close Refactor Assistant')}><X className="h-4 w-4" /></Button></div>
          </header>
          {error && <p role="alert" className="shrink-0 border-b border-bad/30 bg-bad-soft px-4 py-2 text-xs text-bad">{error}</p>}
          <div className="flex min-h-0 flex-1">
            <aside className="hidden w-48 shrink-0 flex-col border-r border-rule bg-paper-2 xl:flex">
              <p className="flex items-center gap-2 px-4 py-3 text-xs text-muted-foreground"><Files className="h-3.5 w-3.5" />{t('Workspace files')}</p>
              {(Object.keys(fileNames) as EditorFile[]).map(file => <button key={file} type="button" data-testid={'workspace-file-' + file} disabled={!selected} onClick={() => openFile(file)} className={'flex min-h-10 items-center gap-2 border-l-2 px-4 text-left text-xs disabled:opacity-40 ' + (file === activeFile ? 'border-accent bg-paper-3 text-ink' : 'border-transparent text-muted-foreground hover:bg-paper-3')}><FileCode2 className="h-3.5 w-3.5" />{file === 'diff' ? t('Diff') : fileNames[file]}{file === 'proposal' && draftChanged && <span className="ml-auto text-accent">●</span>}{file === 'tests' && testsChanged && <span className="ml-auto text-accent">●</span>}</button>)}
              <div className="mt-4 min-h-0 flex-1 overflow-auto border-t border-rule py-3"><p className="px-4 pb-2 text-xs text-muted-foreground">{t('Findings')}</p>{choices.map(item => <button key={item.function_name} type="button" data-testid={'finding-' + item.function_name} disabled={loading} onClick={() => void choose(item.function_name)} className={'flex w-full gap-2 px-4 py-3 text-left text-xs ' + (selected?.function_name === item.function_name ? 'bg-paper-3' : 'hover:bg-paper-3')}><AlertTriangle className="mt-0.5 h-3.5 w-3.5 shrink-0 text-bad" /><span className="min-w-0 break-words">{item.function_name === 'Contract-level finding' ? t('Contract-level finding') : item.function_name}<span className="mt-1 block text-[11px] text-muted-foreground">{item.confidence ? item.confidence + ' · ' : ''}{t('Unconfirmed model finding')}</span></span></button>)}</div>
              {sessionId && <Button size="sm" variant="ghost" data-testid="export-sarif" className="m-2 text-xs" disabled={loading} onClick={() => void exportSarif()}>{t('Export SARIF for IDE/CI')}</Button>}
            </aside>
            <ResizablePanelGroup direction={isMobile ? 'vertical' : 'horizontal'} className="min-h-0 min-w-0" autoSaveId={undefined}>
              <ResizablePanel defaultSize={68} minSize={isMobile ? 35 : 35} className="flex min-h-0 min-w-0 flex-col">
                <div className="shrink-0 border-b border-rule bg-paper-2 p-2 xl:hidden"><Select value={selected?.function_name || ''} onValueChange={name => void choose(name)} disabled={loading || pending !== null}><SelectTrigger data-testid="refactor-function" aria-label={t('Finding context')}><SelectValue placeholder={t('Choose a finding to discuss')} /></SelectTrigger><SelectContent>{choices.map(item => <SelectItem key={item.function_name} value={item.function_name}>{item.function_name === 'Contract-level finding' ? t('Contract-level finding') : item.function_name}</SelectItem>)}</SelectContent></Select></div>
                {!selected ? <div className="grid min-h-0 flex-1 place-items-center p-8 text-center"><div className="max-w-md space-y-4"><FileCode2 className="mx-auto h-9 w-9 text-muted-foreground" /><p>{t('Choose a finding to open its workspace')}</p><p className="text-sm text-muted-foreground">{t('Original source, editable repair, tests and compiler diagnostics stay together here. Choosing a finding does not send code to AI.')}</p></div></div> : <>
                  <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-rule bg-paper-3 px-3 py-2.5" data-testid="ide-repair-status">
                    <p className="max-w-2xl text-xs text-ink-2">{t(loading && requestKind === 'repair' ? 'Generating the repair proposal. The editor will open Diff when the code arrives.' : !response ? 'Detection highlights the original source. Request an explanation, confirm the finding, then generate a repair.' : !confirmed ? 'Explanation ready. Confirm the finding in Expert review before generating repair code.' : hasRepair ? 'Repair proposal ready in Proposal.sol and Diff. Inspect the changes and run compilation/tests before final review.' : 'Finding confirmed. Generate a repair to update Proposal.sol and compare the changes in Diff.')}</p>
                    {!response ? <Button size="sm" variant="outline" disabled={loading || !source} data-testid="ide-explain-finding" onClick={() => prepare('advice', '', 'workspace')}>{t('Review and explain this finding')}</Button>
                      : !confirmed ? <Button size="sm" variant="outline" data-testid="ide-confirm-finding" disabled={loading} onClick={() => setRightTab('review')}>{t('Expert review')}</Button>
                        : hasRepair ? <Button size="sm" variant="outline" data-testid="ide-view-repair" onClick={() => openFile('diff')}>{t('View repair diff')}</Button>
                          : <Button size="sm" data-testid="ide-generate-repair" disabled={loading} onClick={prepareRepair}>{t('Generate AI repair')}</Button>}
                  </div>
                  <nav className="flex shrink-0 overflow-x-auto border-b border-rule bg-paper-2" aria-label={t('Workspace files')}>{(Object.keys(fileNames) as EditorFile[]).map(file => <button key={file} type="button" role="tab" aria-selected={file === activeFile} data-testid={'editor-tab-' + file} onClick={() => openFile(file)} className={'code-text flex min-h-10 shrink-0 items-center gap-2 border-r border-rule px-4 text-xs ' + (file === activeFile ? 'border-t-2 border-t-accent bg-paper text-ink' : 'border-t-2 border-t-transparent text-muted-foreground')} >{file === 'diff' ? <GitCompare className="h-3 w-3" /> : <FileCode2 className="h-3 w-3" />}{file === 'diff' ? t('Diff') : fileNames[file]}{(file === 'proposal' || file === 'diff') && draftChanged ? ' ●' : file === 'tests' && testsChanged ? ' ●' : ''}</button>)}</nav>
                  <div className="flex shrink-0 flex-wrap items-center gap-1.5 border-b border-rule px-2 py-2">
                    <Button size="sm" variant="outline" disabled={loading || !source} data-testid="ide-compile" onClick={compileCurrent}><Play className="h-3 w-3" />{t('Compile locally')}</Button>
                    <Button size="sm" variant="outline" disabled={loading || !confirmed} data-testid="ide-regenerate-repair" onClick={prepareRepair}><FileCode2 className="h-3 w-3" />{t(hasRepair ? 'Generate another repair' : 'Generate AI repair')}</Button>
                    <Button size="sm" variant="outline" disabled={loading || !draft.trim() || !tests.trim()} data-testid="run-behavioral-tests" onClick={() => void verify('proposal', tests)}><FlaskConical className="h-3 w-3" />{t('Compile and test')}</Button>
                    <Button size="sm" variant="ghost" disabled={loading || !confirmed || draft === response?.suggested_code || !draft.trim()} data-testid="ide-save-proposal" onClick={() => void save()}><Save className="h-3 w-3" />{t('Save proposal')}</Button>
                    <Button size="icon" variant="ghost" disabled={loading || activeFile === 'original'} data-testid="ide-reset" aria-label={t('Reset current file')} onClick={() => { if (activeFile === 'tests') setTests(verifiedTests); else setDraft(response?.suggested_code || source); }}><RotateCcw className="h-3.5 w-3.5" /></Button>
                    <Button size="icon" variant="ghost" data-testid="ide-download" disabled={!source} aria-label={t('Download current file')} onClick={() => downloadSource(fileNames[activeFile === 'diff' ? 'proposal' : activeFile], activeFile === 'original' ? source : activeFile === 'tests' ? tests : draft)}><ArrowDownToLine className="h-3.5 w-3.5" /></Button>
                    {editorSelection && <Button size="sm" variant="ghost" disabled={loading} data-testid="ide-ask-selection" onClick={askSelection}>{t('Ask about selection')}</Button>}
                  </div>
                  <div className="flex shrink-0 items-center justify-between gap-2 border-b border-rule px-3 py-1.5 text-[11px] text-muted-foreground">
                    <span>{activeFile === 'original' ? t('Original source — read only') : activeFile === 'tests' ? t('Tests are saved with a verification run.') : response?.proposal_origin === 'human_edit' || draftChanged ? t('Human-edited proposal — not applied') : t('Proposed changes — not applied')}</span>
                    {scope && activeFile === 'original' && <button className="shrink-0 text-accent" type="button" data-testid="ide-jump-finding" onClick={() => reveal('original', scope.start)}>{t('Finding lines')} {scope.start}–{scope.end}</button>}
                  </div>
                  <ResizablePanelGroup direction="vertical" className="min-h-0 flex-1">
                    <ResizablePanel defaultSize={70} minSize={25}><Suspense fallback={<div className="grid h-full place-items-center text-sm text-muted-foreground">{t('Loading local editor…')}</div>}><RefactorCodeEditor key={activeFile + ':' + contextId} file={activeFile} source={source} draft={draft} tests={tests} readOnly={loading || pending !== null} scope={scope} diagnostics={markerDiagnostics} jump={jump} onDraftChange={setDraft} onTestsChange={setTests} onSelection={setEditorSelection} onSave={() => { if (activeFile === 'tests') setError(t('Tests are saved with a verification run.')); else if (activeFile !== 'original') void save(); }} onCompile={compileCurrent} /></Suspense></ResizablePanel>
                    <ResizableHandle withHandle />
                    <ResizablePanel defaultSize={30} minSize={15}><RefactorVerificationPanel run={run} stale={runStale} onDiagnostic={diagnostic} onTests={() => openFile('tests')} /></ResizablePanel>
                  </ResizablePanelGroup>
                </>}
              </ResizablePanel>
              <ResizableHandle withHandle />
              <ResizablePanel defaultSize={32} minSize={isMobile ? 25 : 25} className="flex min-h-0 min-w-0 flex-col bg-paper-2">
                <div className="flex shrink-0 border-b border-rule px-3"><button type="button" data-testid="ide-assistant-tab" onClick={() => setRightTab('chat')} className={'flex min-h-11 items-center gap-2 border-b-2 px-3 text-xs ' + (rightTab === 'chat' ? 'border-accent text-ink' : 'border-transparent text-muted-foreground')}><MessageSquare className="h-3.5 w-3.5" />{t('Assistant')}</button><button type="button" data-testid="ide-review-tab" onClick={() => setRightTab('review')} className={'flex min-h-11 items-center gap-2 border-b-2 px-3 text-xs ' + (rightTab === 'review' ? 'border-accent text-ink' : 'border-transparent text-muted-foreground')}><ShieldCheck className="h-3.5 w-3.5" />{t('Expert review')}</button></div>
                <div className={rightTab === 'chat' ? 'flex min-h-0 flex-1 flex-col' : 'hidden'}>
                  <ScrollArea className="min-h-0 flex-1 p-4"><div className="space-y-5">
                    {!selected ? <p className="text-sm text-muted-foreground">{t('Choose a finding to discuss')}</p> : <>
                      <AiResultNotice kind="prediction" score={selected.confidence || undefined} />
                      {!scope && <p className="text-xs text-muted-foreground">{t('Exact function location is unavailable. Review the full source and specify the evidence lines manually.')}</p>}
                      {!response && <Button disabled={loading || !source} onClick={() => prepare('advice', '', 'workspace')} data-testid="refactor-explain">{t('Review and explain this finding')}</Button>}
                      {history.map((message, index) => <div key={index} className={message.role === 'user' ? 'rounded-md bg-paper-3 p-3 text-sm' : 'chat-prose border-l border-rule-2 pl-3'}>
                        {message.role === 'assistant' && <p className="mb-2 text-[11px] text-muted-foreground">{t('AI-generated content')}</p>}
                        <ReactMarkdown remarkPlugins={[remarkGfm]} components={{ img: () => null, a: ({ href, children }) => href?.startsWith('https://') ? <a href={href} target="_blank" rel="noopener noreferrer">{children}</a> : <span>{children}</span> }}>{message.content}</ReactMarkdown>
                      </div>)}
                      {response && <AiResultNotice kind="explanation" />}
                      {response && !confirmed && <Button variant="outline" size="sm" onClick={() => setRightTab('review')}>{t('Confirm the finding before requesting a repair')}</Button>}
                      <div className="flex flex-wrap gap-2"><Button size="sm" variant="outline" disabled={loading || !confirmed} data-testid="assistant-generate-repair" onClick={prepareRepair}>{t('Generate AI repair')}</Button><Button size="sm" variant="outline" disabled={loading || !confirmed} onClick={() => setInput(t('What tests should I run?'))}>{t('What tests should I run?')}</Button></div>
                    </>}
                  </div></ScrollArea>
                  {selected && <div className="space-y-2 border-t border-rule p-3"><div className="flex items-center justify-between gap-2 text-[11px] text-muted-foreground"><span>{t(chatContext === 'workspace' ? 'Chat context: current proposal' : 'Chat context: selected code')}</span>{chatContext === 'selection' && <button type="button" className="min-h-7 text-accent" onClick={() => setChatContext('workspace')}>{t('Include full proposal')}</button>}</div><Textarea aria-label={t('Follow-up question')} data-testid="refactor-message" placeholder={t('Ask about the finding. Replace personal data with [NAME] and [CCCD].')} value={input} onChange={event => setInput(event.target.value)} disabled={loading} className="min-h-20 resize-none text-sm" /><div className="flex items-center gap-2"><p className="flex-1 text-[11px] text-muted-foreground">{t('Your message will be checked and previewed before any AI call.')}</p><Button size="icon" data-testid="refactor-send" onClick={() => prepare('conversation', input, chatContext)} disabled={loading || !input.trim() || !source || !confirmed} aria-label={t('Review message before sending')}><Send className="h-4 w-4" /></Button></div></div>}
                </div>
                <div className={rightTab === 'review' ? 'flex min-h-0 flex-1 flex-col' : 'hidden'}><ScrollArea className="min-h-0 flex-1 p-4">{response ? <HumanRepairReview key={response.thread_id} source={source} response={response} verification={response.verification} draftChanged={draft !== response.suggested_code} testsChanged={testsChanged} selectedLines={editorSelection?.file === 'original' ? { start: editorSelection.startLine, end: editorSelection.endLine } : null} loading={loading} setLoading={setLoading} onOpenTests={() => openFile('tests')} onResponse={receiveReview} onError={setError} /> : <p className="text-sm text-muted-foreground">{t('Inspect the source and request an explanation first. Expert confirmation unlocks saving and requesting a repair.')}</p>}</ScrollArea></div>
              </ResizablePanel>
            </ResizablePanelGroup>
          </div>
          <footer className="flex shrink-0 justify-between gap-4 border-t border-rule bg-paper-3 px-3 py-1.5 text-[11px] text-muted-foreground"><span className="truncate">{selected?.function_name || t('No finding selected')}</span><span className="shrink-0">{draftChanged || testsChanged ? t('Unsaved workspace changes') : t('Local workspace')} · {t('Manual review required')}</span></footer>
        </DialogPrimitive.Content>
      </DialogPortal>
    </Dialog>
    <AiConsentDialog request={pending} onApprove={approved => void approve(approved)} onCancel={() => { setPending(null); setRequestKind(null); }} />
  </>;
};
