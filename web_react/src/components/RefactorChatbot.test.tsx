import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { RefactorChatbot } from './RefactorChatbot';
import type { EditorFile, EditorJump, EditorSelection } from './RefactorCodeEditor';
import { RefactorResponse, RefactorThread, VerificationResult, refactorBotService } from '@/services/refactorbot';

// Monaco requires a browser layout engine. Keep the editor boundary deterministic
// while testing the real workspace, review controls and API interactions.
vi.mock('@/components/RefactorCodeEditor', () => ({ default: (props: {
  file: EditorFile; source: string; draft: string; tests: string; readOnly: boolean; jump: EditorJump | null;
  onDraftChange: (value: string) => void; onTestsChange: (value: string) => void; onSelection: (value: EditorSelection | null) => void;
}) => <div data-testid="refactor-code-editor"><textarea data-testid={'mock-editor-' + props.file} readOnly={props.file === 'original' || props.readOnly} value={props.file === 'original' ? props.source : props.file === 'tests' ? props.tests : props.draft} onChange={event => props.file === 'tests' ? props.onTestsChange(event.target.value) : props.onDraftChange(event.target.value)} /><button data-testid="mock-select-code" onClick={() => props.onSelection({ file: props.file, startLine: 1, endLine: props.draft.split('\n').length, text: props.draft })}>Select code</button><output data-testid="mock-editor-jump">{props.jump ? props.jump.file + ':' + props.jump.line + ':' + props.jump.column : ''}</output></div> }));

const original = 'pragma solidity ^0.8.20;\ncontract Demo { function set() public {} }';
const proposal = 'pragma solidity ^0.8.20;\ncontract Demo { function set() external {} }';
const harness = 'pragma solidity ^0.8.20;\nimport "Contract.sol";\ncontract Tests { function testSet() public {} }';
const finding = { function_name: 'Demo.set()', function_code: 'function set() public {}', prediction: 1, confidence: '91.00%' };

function verification(): VerificationResult {
  return { status: 'passed', message: 'Compilation passed', compiler: '0.8.20', warnings: [], security_verified: false, source_sha256: '1'.repeat(64), diagnostics: [], tests: { status: 'passed', message: 'Fixture assertions passed', cases: [{ name: 'Tests.testSet', status: 'passed', message: 'Fixture' }], test_source_sha256: '2'.repeat(64) } };
}
function response(): RefactorResponse {
  return { thread_id: 'thread-one', explanation: 'Review caller authorization.', bot_message: 'Review caller authorization.', suggested_code: proposal, suggestions: [], verification: verification(), repair_attempts: 1, proposal_origin: 'ai', proposal_review: null,
    disclosure: { ai_generated: true, model: 'byok/astral-x/claude-haiku-5-5', confidence: null, confidence_calibrated: false, warning: 'Review required' },
    finding_review: { thread_id: 'thread-one', decision: 'confirmed', start_line: 2, end_line: 2, evidence_note: 'Synthetic reviewer evidence', qualified_reviewer: true, reviewer_id: 'fixture-user', reviewed_at: '2026-01-01T00:00:00Z', source_sha256: '0'.repeat(64), qualification: 'self_attested' } };
}
function thread(): RefactorThread {
  return { thread_id: 'thread-one', context_id: 'session:Demo.set()', code: original, conversation_history: [{ role: 'assistant', content: 'Review caller authorization.' }], response: response(), test_source: harness };
}
async function openWorkspace() {
  render(<RefactorChatbot vulnerableFunctions={[finding]} sessionId="session" hasFinding />);
  fireEvent.click(screen.getByTestId('refactor-open'));
  fireEvent.click(screen.getByTestId('finding-Demo.set()'));
  await screen.findByTestId('refactor-code-editor');
  await waitFor(() => expect((screen.getByTestId('ide-compile') as HTMLButtonElement).disabled).toBe(false));
}

function mockPayloadReview() {
  return vi.spyOn(refactorBotService, 'review').mockImplementation(async payload => ({ payload, findings: [], blocked: false, review_token: 'test-review-token', provider: 'token.astralx.com.vn', model: 'byok/astral-x/claude-haiku-5-5', encrypted_transport: true }));
}

function explanationThread(): RefactorThread {
  const saved = thread();
  saved.response.suggested_code = null;
  saved.response.verification = { ...verification(), status: 'not_run', tests: { ...verification().tests, status: 'not_run', cases: [] } };
  saved.test_source = null;
  return saved;
}

beforeEach(() => {
  vi.restoreAllMocks();
  localStorage.clear();
  vi.spyOn(refactorBotService, 'getThread').mockResolvedValue(thread());
});

describe('Refactor IDE', () => {
  it('switches the IDE to Vietnamese and requests new AI replies in that language', async () => {
    const review = mockPayloadReview();
    await openWorkspace();
    fireEvent.change(screen.getByTestId('language-select-ide'), { target: { value: 'vi' } });
    expect(screen.getByTestId('ide-regenerate-repair').textContent).toBe('Tạo bản sửa khác');
    fireEvent.click(screen.getByTestId('ide-regenerate-repair'));
    await waitFor(() => expect(review).toHaveBeenCalled());
    expect(review.mock.calls[0][0].language).toBe('vi');
    expect(review.mock.calls[0][0].code).toBe(original);
  });

  it('opens a saved repair in Diff instead of leaving the original source selected', async () => {
    await openWorkspace();
    expect(screen.getByTestId('editor-tab-diff').getAttribute('aria-selected')).toBe('true');
    expect((await screen.findByTestId('mock-editor-diff') as HTMLTextAreaElement).value).toBe(proposal);
    fireEvent.click(screen.getByTestId('editor-tab-original'));
    expect((await screen.findByTestId('mock-editor-original') as HTMLTextAreaElement).value).toBe(original);
    expect((screen.getByTestId('mock-editor-original') as HTMLTextAreaElement).readOnly).toBe(true);
    fireEvent.click(screen.getByTestId('ide-view-repair'));
    expect((await screen.findByTestId('mock-editor-diff') as HTMLTextAreaElement).value).toBe(proposal);
  });

  it('requires finding confirmation and sending consent, then updates the editor with the generated repair', async () => {
    const saved = explanationThread();
    saved.response.finding_review = null;
    vi.mocked(refactorBotService.getThread).mockResolvedValue(saved);
    const review = mockPayloadReview();
    const send = vi.spyOn(refactorBotService, 'send').mockResolvedValue(response());
    vi.spyOn(refactorBotService, 'reviewFinding').mockResolvedValue(response().finding_review!);
    await openWorkspace();
    expect((screen.getByTestId('ide-regenerate-repair') as HTMLButtonElement).disabled).toBe(true);
    expect(review).not.toHaveBeenCalled();
    fireEvent.click(screen.getByTestId('ide-confirm-finding'));
    fireEvent.click(screen.getByTestId('qualified-reviewer'));
    fireEvent.change(screen.getByTestId('review-evidence-note'), { target: { value: 'Synthetic reviewer confirmed caller authorization evidence.' } });
    fireEvent.change(screen.getByTestId('review-start-line'), { target: { value: '2' } });
    fireEvent.change(screen.getByTestId('review-end-line'), { target: { value: '2' } });
    fireEvent.click(screen.getByTestId('finding-confirmed'));
    fireEvent.click(await screen.findByTestId('ide-generate-repair'));
    await screen.findByTestId('ai-consent-dialog');
    await waitFor(() => expect((screen.getByTestId('ai-consent-send') as HTMLButtonElement).disabled).toBe(false));
    expect(send).not.toHaveBeenCalled();
    expect(screen.queryByText('byok/astral-x/claude-haiku-5-5')).toBeNull();
    expect(screen.getByText('token.astralx.com.vn')).toBeTruthy();
    const payload = review.mock.calls[0][0];
    expect(payload.operation).toBe('conversation');
    expect(payload.code).toBe(original);
    expect(payload.conversation_history[payload.conversation_history.length - 1].content).toContain('Synthetic reviewer evidence');
    fireEvent.click(screen.getByTestId('ai-consent-send'));
    await waitFor(() => expect(send).toHaveBeenCalledTimes(1));
    expect((await screen.findByTestId('mock-editor-diff') as HTMLTextAreaElement).value).toBe(proposal);
    fireEvent.click(screen.getByTestId('editor-tab-original'));
    expect((await screen.findByTestId('mock-editor-original') as HTMLTextAreaElement).value).toBe(original);
  });

  it.each([
    [null, 'did not return a code proposal'],
    [original, 'returned unchanged code'],
  ])('reports a missing or unchanged repair instead of claiming the editor was fixed (%s)', async (code, expected) => {
    vi.mocked(refactorBotService.getThread).mockResolvedValue(explanationThread());
    mockPayloadReview();
    vi.spyOn(refactorBotService, 'send').mockResolvedValue({ ...response(), suggested_code: code });
    await openWorkspace();
    fireEvent.click(screen.getByTestId('ide-generate-repair'));
    await screen.findByTestId('ai-consent-dialog');
    await waitFor(() => expect((screen.getByTestId('ai-consent-send') as HTMLButtonElement).disabled).toBe(false));
    fireEvent.click(screen.getByTestId('ai-consent-send'));
    await waitFor(() => expect(screen.getByRole('alert').textContent).toContain(expected));
    expect(screen.queryByTestId('ide-view-repair')).toBeNull();
  });

  it('previews the complete large selected context and history without trimming', async () => {
    const longProposal = proposal + '\n' + '// complete workspace evidence\n'.repeat(4000);
    const saved = thread();
    saved.response.suggested_code = longProposal;
    saved.conversation_history = Array.from({ length: 81 }, (_, index) => ({ role: index % 2 ? 'user' : 'assistant', content: 'Earlier discussion ' + index }));
    vi.mocked(refactorBotService.getThread).mockResolvedValue(saved);
    const review = vi.spyOn(refactorBotService, 'review').mockImplementation(async payload => ({ payload, findings: [], blocked: false, review_token: 'test-review-token', provider: 'token.astralx.com.vn', model: 'byok/astral-x/claude-haiku-5-5', encrypted_transport: true }));
    await openWorkspace();
    fireEvent.click(screen.getByTestId('editor-tab-proposal'));
    fireEvent.click(await screen.findByTestId('mock-select-code'));
    fireEvent.click(screen.getByTestId('ide-ask-selection'));
    expect((screen.getByTestId('refactor-message') as HTMLTextAreaElement).value.endsWith(longProposal)).toBe(true);
    fireEvent.click(screen.getByTestId('refactor-send'));
    await waitFor(() => expect(review).toHaveBeenCalled());
    const payload = review.mock.calls[0][0];
    expect(payload.code).toBe(original);
    expect(payload.conversation_history).toHaveLength(82);
    expect(payload.conversation_history[payload.conversation_history.length - 1].content.endsWith(longProposal)).toBe(true);
  });

  it('edits a separate proposal and invalidates the previous verification on save', async () => {
    const changed = proposal.replace('external', 'external payable');
    const pending = { ...response(), suggested_code: changed, proposal_origin: 'human_edit' as const, verification: { ...verification(), status: 'not_run' as const, message: 'Editor changed; rerun checks', tests: { ...verification().tests, status: 'not_run' as const, cases: [] } } };
    const save = vi.spyOn(refactorBotService, 'saveProposal').mockResolvedValue(pending);
    await openWorkspace();
    fireEvent.click(screen.getByTestId('ide-review-tab'));
    fireEvent.click(screen.getByTestId('qualified-reviewer'));
    fireEvent.change(screen.getByTestId('review-evidence-note'), { target: { value: 'Reviewed behavior and remaining domain risks.' } });
    expect((screen.getByTestId('proposal-accepted_for_manual_application') as HTMLButtonElement).disabled).toBe(false);
    fireEvent.click(screen.getByTestId('editor-tab-proposal'));
    fireEvent.change(await screen.findByTestId('mock-editor-proposal'), { target: { value: changed } });
    expect((screen.getByTestId('proposal-accepted_for_manual_application') as HTMLButtonElement).disabled).toBe(true);
    fireEvent.click(screen.getByTestId('ide-save-proposal'));
    await waitFor(() => expect(save).toHaveBeenCalledWith({ thread_id: 'thread-one', previous_proposal: proposal, proposed_code: changed }));
    await screen.findByText('Editor changed; rerun checks');
    fireEvent.click(screen.getByTestId('editor-tab-original'));
    expect((await screen.findByTestId('mock-editor-original') as HTMLTextAreaElement).value).toBe(original);
    expect((screen.getByTestId('proposal-accepted_for_manual_application') as HTMLButtonElement).disabled).toBe(true);
  });

  it('navigates real compiler locations and disables stale diagnostics after editing', async () => {
    const failed = { ...verification(), status: 'failed' as const, message: 'Test syntax error', diagnostics: [{ severity: 'error' as const, message: 'Expected expression', source_file: 'Tests.sol', start_line: 3, start_column: 7, end_line: 3, end_column: 8 }] };
    const compile = vi.spyOn(refactorBotService, 'validateRefactoring').mockResolvedValue(failed);
    await openWorkspace();
    fireEvent.click(screen.getByTestId('run-behavioral-tests'));
    await waitFor(() => expect(compile).toHaveBeenCalledWith(original, proposal, 'thread-one', harness));
    fireEvent.click(await screen.findByTestId('compiler-diagnostic-0'));
    await screen.findByTestId('mock-editor-tests');
    expect(screen.getByTestId('mock-editor-jump').textContent).toBe('tests:3:7');
    fireEvent.change(screen.getByTestId('mock-editor-tests'), { target: { value: harness + '\n// Changed assertions' } });
    expect((screen.getByTestId('compiler-diagnostic-0') as HTMLButtonElement).disabled).toBe(true);
    expect((screen.getByTestId('proposal-accepted_for_manual_application') as HTMLButtonElement).disabled).toBe(true);
  });

  it('retains unsaved editor buffers when closing and reopening the assistant', async () => {
    await openWorkspace();
    fireEvent.click(screen.getByTestId('editor-tab-proposal'));
    const changed = proposal + '\n// Local review draft';
    fireEvent.change(await screen.findByTestId('mock-editor-proposal'), { target: { value: changed } });
    fireEvent.click(screen.getByTestId('refactor-close'));
    fireEvent.click(screen.getByTestId('refactor-open'));
    expect((await screen.findByTestId('mock-editor-proposal') as HTMLTextAreaElement).value).toBe(changed);
    expect(refactorBotService.getThread).toHaveBeenCalledTimes(1);
  });
});
