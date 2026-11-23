import { apiConfig, createAuthHeaders } from './api';

export interface ConversationMessage { role: 'user' | 'assistant'; content: string }
export interface AiPayload {
  operation: 'advice' | 'conversation';
  code: string;
  issue_description: string;
  conversation_history: ConversationMessage[];
  language: 'en' | 'vi';
  thread_id: string | null;
  context_id: string | null;
}
export interface AiReview {
  payload: AiPayload;
  findings: { category: string; count: number }[];
  blocked: boolean;
  review_token: string | null;
  provider: string;
  model: string;
  encrypted_transport: boolean;
}
export interface ApprovedAiRequest extends AiPayload { review_token: string; consent_confirmed: true }
export interface VerificationResult {
  status: 'passed' | 'failed' | 'not_run';
  message: string;
  compiler: string | null;
  warnings: string[];
  security_verified: false;
  source_sha256: string | null;
  tests: { status: 'passed' | 'failed' | 'not_run'; message: string; cases: { name: string; status: 'passed' | 'failed'; message: string }[]; test_source_sha256: string | null };
  diagnostics: CompilerDiagnostic[];
}
export interface CompilerDiagnostic { severity: 'error' | 'warning' | 'info'; message: string; source_file: string | null; start_line: number | null; start_column: number | null; end_line: number | null; end_column: number | null }
export interface ProposalEditRequest { thread_id: string; previous_proposal: string | null; proposed_code: string }
export interface FindingReviewRequest { thread_id: string; decision: 'confirmed' | 'rejected' | 'manual_review'; start_line: number; end_line: number; evidence_note: string; qualified_reviewer: true }
export interface FindingReview extends FindingReviewRequest { reviewer_id: string; reviewed_at: string; source_sha256: string; qualification: 'self_attested' }
export interface ProposalReviewRequest { thread_id: string; proposal_sha256: string; decision: 'accepted_for_manual_application' | 'rejected' | 'manual_review'; note: string; qualified_reviewer: true }
export interface ProposalReview extends ProposalReviewRequest { reviewer_id: string; reviewed_at: string; qualification: 'self_attested' }
export interface RefactoringSuggestion { type: string; description: string; code?: string; content?: string; url?: string }
export interface RefactorResponse {
  thread_id: string;
  explanation: string;
  bot_message: string;
  suggestions: RefactoringSuggestion[];
  suggested_code: string | null;
  verification: VerificationResult;
  disclosure: { ai_generated: true; model: string; confidence: null; confidence_calibrated: false; warning: string };
  repair_attempts: number;
  finding_review: FindingReview | null;
  proposal_review: ProposalReview | null;
  proposal_origin: 'ai' | 'human_edit';
}
export interface RefactorThread { thread_id: string; context_id: string | null; code: string; conversation_history: ConversationMessage[]; response: RefactorResponse; test_source: string | null }

async function request<T>(path: string, body?: AiPayload | ApprovedAiRequest | FindingReviewRequest | ProposalReviewRequest | ProposalEditRequest | { code: string; test_source?: string } | { original_code: string; suggested_code: string; thread_id?: string; test_source?: string }, signal?: AbortSignal): Promise<T> {
  const response = await fetch(`${apiConfig.baseURL}/api/v1/refactor${path}`, {
    method: body ? 'POST' : 'GET', headers: createAuthHeaders(), body: body ? JSON.stringify(body) : undefined, signal,
  });
  if (!response.ok) {
    const error: { detail?: string | { msg: string }[] } = await response.json();
    throw new Error(typeof error.detail === 'string' ? error.detail : error.detail?.map(item => item.msg).join('; ') || `AI request failed (HTTP ${response.status})`);
  }
  return response.json() as Promise<T>;
}

export const refactorBotService = {
  review: (payload: AiPayload, signal?: AbortSignal) => request<AiReview>('/review', payload, signal),
  send: (payload: ApprovedAiRequest) => request<RefactorResponse>(payload.operation === 'advice' ? '/advice' : '/conversation', payload),
  getThread: (contextId: string) => request<RefactorThread | null>(`/threads?${new URLSearchParams({ context_id: contextId })}`),
  validateRefactoring: (originalCode: string, suggestedCode: string, threadId?: string, testSource?: string) => request<VerificationResult>('/validate', { original_code: originalCode, suggested_code: suggestedCode, thread_id: threadId, test_source: testSource }),
  reviewFinding: (payload: FindingReviewRequest) => request<FindingReview>('/finding-review', payload),
  reviewProposal: (payload: ProposalReviewRequest) => request<ProposalReview>('/proposal-review', payload),
  getReport: (threadId: string) => request<RefactorThread>(`/threads/${encodeURIComponent(threadId)}/report`),
  saveProposal: (payload: ProposalEditRequest) => request<RefactorResponse>('/proposal', payload),
  compileSource: (code: string, testSource?: string) => request<VerificationResult>('/compile', { code, test_source: testSource }),
};

export function downloadEvidence(filename: string, data: object) {
  downloadFile(filename, JSON.stringify(data, null, 2), 'application/json');
}

export function downloadSource(filename: string, code: string) {
  downloadFile(filename, code, 'text/plain;charset=utf-8');
}

function downloadFile(filename: string, content: string, type: string) {
  const url = URL.createObjectURL(new Blob([content], { type }));
  const link = document.createElement('a');
  link.href = url; link.download = filename; link.click(); URL.revokeObjectURL(url);
}
