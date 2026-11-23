import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { FindingReviewRequest, ProposalReviewRequest, RefactorResponse, VerificationResult, downloadEvidence, refactorBotService } from '@/services/refactorbot';
import { useT } from '@/i18n';

interface Props {
  source: string; response: RefactorResponse; verification: VerificationResult | null;
  draftChanged: boolean; testsChanged: boolean; selectedLines: { start: number; end: number } | null;
  loading: boolean; setLoading: (value: boolean) => void; onOpenTests: () => void;
  onResponse: (value: RefactorResponse) => void; onError: (value: string) => void;
}

export function HumanRepairReview({ source, response, verification, draftChanged, testsChanged, selectedLines, loading, setLoading, onOpenTests, onResponse, onError }: Props) {
  const t = useT();
  const [note, setNote] = useState('');
  const [qualified, setQualified] = useState(false);
  const [start, setStart] = useState('');
  const [end, setEnd] = useState('');
  const finding = response.finding_review;
  const canAccept = !draftChanged && !testsChanged && finding?.decision === 'confirmed' && verification?.status === 'passed' && verification.tests?.status === 'passed' && !!verification.tests.cases.length;
  const perform = async (operation: () => Promise<void>) => {
    setLoading(true); onError('');
    try { await operation(); } catch (error) { onError(error instanceof Error ? t(error.message) : t('Review could not be saved.')); }
    finally { setLoading(false); }
  };
  const reviewFinding = (decision: FindingReviewRequest['decision']) => perform(async () => {
    const review = await refactorBotService.reviewFinding({ thread_id: response.thread_id, decision, start_line: Number(start), end_line: Number(end), evidence_note: note.trim(), qualified_reviewer: true });
    onResponse({ ...response, finding_review: review, proposal_review: null }); setNote(''); setQualified(false);
  });
  const reviewProposal = (decision: ProposalReviewRequest['decision']) => perform(async () => {
    let digest = verification?.source_sha256;
    // The server also checks this digest against the current proposal.
    if (!digest && response.suggested_code && crypto.subtle) {
      digest = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(response.suggested_code)))).map(byte => byte.toString(16).padStart(2, '0')).join('');
    }
    if (!digest) throw new Error('Compile the proposal before recording its review.');
    const review = await refactorBotService.reviewProposal({ thread_id: response.thread_id, proposal_sha256: digest, decision, note: note.trim(), qualified_reviewer: true });
    onResponse({ ...response, proposal_review: review }); setNote(''); setQualified(false);
  });
  const formReady = qualified && note.trim().length >= 10 && !loading;
  return <div className="space-y-4 border-y border-rule py-4" data-testid="human-repair-review">
    <ol className="grid grid-cols-2 gap-2 text-xs text-muted-foreground sm:grid-cols-4" aria-label={t('Repair workflow')}>
      {['1. Detect and explain', '2. Expert confirms finding', '3. Repair and compile/test', '4. Expert reviews proposal'].map(step => <li key={step}>{t(step)}</li>)}
    </ol>
    <p className="text-sm font-medium">{t('Human review required')}</p>
    <p className="text-xs text-muted-foreground">{t('Warnings and absence of warnings do not prove security. Reviewer qualifications are self-attested; the application does not certify expertise.')}</p>
    {finding && <p className="text-xs" data-testid="finding-review-status">{t('Finding review')}: {t(finding.decision)} · {t('Lines')} {finding.start_line}–{finding.end_line} · {finding.reviewer_id} · {new Date(finding.reviewed_at).toLocaleString(t.locale)}<br />{finding.evidence_note}</p>}
    <div className="flex flex-wrap gap-2">
      <Button size="sm" variant="outline" disabled={loading || (!!response.suggested_code && (draftChanged || testsChanged))} onClick={() => void perform(async () => downloadEvidence('repair-review.json', await refactorBotService.getReport(response.thread_id)))}>{t('Export review evidence')}</Button>
    </div>
    {response.suggested_code && <div className="space-y-2">
      <Button size="sm" variant="outline" onClick={onOpenTests}>{t('Open Tests.sol')}</Button>
      <p className="text-xs text-muted-foreground">{t('Use the proposal pragma, import Contract.sol, and write public test*() functions with no arguments or return values. Each test gets a fresh deployment; optional setUp() runs first. No Foundry cheatcodes. Tests run locally without sending data to AI.')}</p>
      {draftChanged && <p role="status" className="text-xs text-bad">{t('Save the edited proposal and run compilation/tests again before accepting it.')}</p>}
      {testsChanged && <p role="status" className="text-xs text-bad">{t('Tests have changed since the saved verification. Run them before accepting the proposal; the previous report covers the saved harness only.')}</p>}
      <p className="text-xs" data-testid="behavioral-tests-status">{t('Behavioral tests')}: {t(verification?.tests?.status || 'not_run')}<br />{t(verification?.tests?.message || 'No behavioral tests were supplied. Expert review is required.')}</p>
      {verification?.tests?.cases.map(item => <p key={item.name} className="code-text text-xs">{item.name}: {t(item.status)} — {t(item.message)}</p>)}
    </div>}
    <label className="flex items-start gap-2 text-xs"><input type="checkbox" data-testid="qualified-reviewer" checked={qualified} onChange={event => setQualified(event.target.checked)} disabled={loading} />{t('I am qualified to review this finding and take responsibility for this assessment. This is separate from permission to send data to AI.')}</label>
    <Textarea aria-label={t('Evidence, rationale and remaining risks')} data-testid="review-evidence-note" placeholder={t('Evidence, rationale and remaining risks')} value={note} onChange={event => setNote(event.target.value)} disabled={loading} />
    <div className="flex items-end gap-2">
      <label className="text-xs">{t('Start line')}<Input type="number" min={1} max={source.split('\n').length} data-testid="review-start-line" value={start} onChange={event => setStart(event.target.value)} disabled={loading} /></label>
      <label className="text-xs">{t('End line')}<Input type="number" min={Number(start) || 1} max={source.split('\n').length} data-testid="review-end-line" value={end} onChange={event => setEnd(event.target.value)} disabled={loading} /></label>
    </div>
    {selectedLines && <Button size="sm" variant="outline" data-testid="review-use-selection" disabled={loading} onClick={() => { setStart(String(selectedLines.start)); setEnd(String(selectedLines.end)); }}>{t('Use selected original lines')} {selectedLines.start}–{selectedLines.end}</Button>}
    <div className="flex flex-wrap gap-2">{(['confirmed', 'rejected', 'manual_review'] as const).map(decision => <Button key={decision} size="sm" variant="outline" disabled={!formReady || !start || !end || Number(end) < Number(start)} data-testid={`finding-${decision}`} onClick={() => void reviewFinding(decision)}>{t(`Finding: ${decision}`)}</Button>)}</div>
    {response.suggested_code && <>
      <p className="text-xs text-muted-foreground">{t('Accepting records a human decision for manual application. It does not apply code or certify security. Missing tests, compiler support, dependencies or domain context require manual review.')}</p>
      <div className="flex flex-wrap gap-2">{(['accepted_for_manual_application', 'rejected', 'manual_review'] as const).map(decision => <Button key={decision} size="sm" variant="outline" data-testid={`proposal-${decision}`} disabled={!formReady || draftChanged || (decision === 'accepted_for_manual_application' && !canAccept)} onClick={() => void reviewProposal(decision)}>{t(`Proposal: ${decision}`)}</Button>)}</div>
      {response.proposal_review && <p role="status" className="text-xs">{t('Proposal review')}: {t(response.proposal_review.decision)} · {response.proposal_review.reviewer_id} · {new Date(response.proposal_review.reviewed_at).toLocaleString(t.locale)}<br />{response.proposal_review.note}</p>}
    </>}
  </div>;
}
