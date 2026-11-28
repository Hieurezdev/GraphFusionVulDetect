import { apiFetch, CSRF_HEADERS } from './api';
import { readPreferences } from "@/lib/preferences";

export interface ProjectCreate {
  name: string;
  description?: string;
}

export interface ProjectUpdate {
  name?: string;
  description?: string;
  status?: 'created' | 'analyzing' | 'completed' | 'failed';
}

export interface ProjectFile {
  filename: string;
  file_size: number;
  file_path: string;
  file_hash: string;
  uploaded_at: string;
}

export interface Project {
  id: string;
  name: string;
  description?: string;
  user_id: string;
  status: 'created' | 'analyzing' | 'completed' | 'failed';
  files: ProjectFile[];
  analysis_count: number;
  created_at: string;
  updated_at: string;
}

export interface ProjectResponse {
  id: string;
  name: string;
  description?: string;
  status: 'created' | 'analyzing' | 'completed' | 'failed';
  files_count: number;
  analysis_count: number;
  created_at: string;
  updated_at: string;
}

export interface AnalysisStep {
  step_name: string;
  vulnerability?: string | null;
  status: string;
  result_data: Record<string, any>;
  started_at: string;
  completed_at?: string;
  error_message?: string;
}

export interface RepairAgentResult {
  function_name: string;
  vulnerability: string;
  rounds: number;
  tool_calls: number;
  seconds: number;
  stopped: "submitted" | "round limit" | "token budget";
  fix?: string | null;
  summary?: string | null;
  recorded?: boolean;
  first_attempt_compiled?: boolean;
  verification?: { compiled: boolean; findings_after: number; function_still_flagged?: boolean; contract_verdict?: string; holds: boolean };
  note: string;
}

export interface AnalysisSession {
  id: string;
  project_id?: string;
  user_id: string;
  file_path: string;
  filename: string;
  status: 'created' | 'processing' | 'completed' | 'failed';
  steps: AnalysisStep[];
  started_at: string;
  completed_at?: string;
  error_message?: string;
  reviews?: FunctionReview[];
  fixes?: FunctionFix[];
  /** Unflagged functions sampled at random for a blind expert check (consenting uploads only). */
  random_audits?: { vulnerability: string; function_name: string; lines: number[]; span: number[] }[];
  training_consent?: boolean;
  model_versions?: Record<string, string | null>;
}

export type ReviewStatus = 'pending' | 'confirmed' | 'false_positive' | 'needs_manual_review';

export type FixDecision = 'proposed' | 'accepted' | 'rejected' | 'needs_manual_review';

export interface FunctionFix {
  vulnerability: string;
  function_name: string;
  suggested_code: string;
  compiled: boolean;
  solc_version?: string | null;
  findings_before: number;
  findings_after: number;
  checked_by: string;
  checked_at: string;
  decision: FixDecision;
  decided_by?: string | null;
  decided_at?: string | null;
  note?: string | null;
}

export type FindingStage = 'awaiting_review' | 'closed_false_positive' | 'manual_review' | 'awaiting_fix' | 'fix_failed_check' | 'awaiting_fix_approval' | 'fix_accepted';

export interface Finding {
  vulnerability: string;
  vulnerability_label: string;
  function_name: string;
  lines: number[];
  confidence: string;
  explanation?: string | null;
  review?: FunctionReview | null;
  fix?: FunctionFix | null;
  stage: FindingStage;
}

export interface FunctionReview {
  vulnerability?: string | null;
  function_name: string;
  status: ReviewStatus;
  note?: string | null;
  reviewer: string;
  reviewed_at: string;
}

class ProjectService {
  /**
   * Create a new project
   */
  async createProject(projectData: ProjectCreate): Promise<ProjectResponse> {
    return await apiFetch<ProjectResponse>('/api/v1/projects/', {  // trailing slash = the route itself, no 307 redirect
      method: 'POST',
      body: projectData,
      requireAuth: true,
    });
  }

  /**
   * Get list of user's projects
   */
  async listProjects(
    skip = 0,
    limit = 20,
    status?: string
  ): Promise<ProjectResponse[]> {
    const params = new URLSearchParams({
      skip: skip.toString(),
      limit: limit.toString(),
    });
    
    if (status) {
      params.append('status', status);
    }

    return await apiFetch<ProjectResponse[]>(`/api/v1/projects/?${params}`, {
      requireAuth: true,
    });
  }

  /**
   * Get a specific project
   */
  async getProject(projectId: string): Promise<Project> {
    return await apiFetch<Project>(`/api/v1/projects/${projectId}`, {
      requireAuth: true,
    });
  }

  /**
   * Update a project
   */
  async updateProject(
    projectId: string,
    updateData: ProjectUpdate
  ): Promise<ProjectResponse> {
    return await apiFetch<ProjectResponse>(`/api/v1/projects/${projectId}`, {
      method: 'PUT',
      body: updateData,
      requireAuth: true,
    });
  }

  /**
   * Delete a project
   */
  async deleteProject(projectId: string): Promise<void> {
    await apiFetch<void>(`/api/v1/projects/${projectId}`, {
      method: 'DELETE',
      requireAuth: true,
    });
  }

  /**
   * Add a file to a project
   */
  async addFileToProject(projectId: string, file: File): Promise<ProjectFile> {
    const formData = new FormData();
    formData.append('file', file);

    // For file upload, we need to use fetch directly to handle FormData (the session cookie goes along)
    const response = await fetch(`/api/v1/projects/${projectId}/files`, {
      method: 'POST',
      headers: { ...CSRF_HEADERS },
      credentials: 'include',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Upload failed: ${response.statusText}`);
    }

    return await response.json();
  }

  /**
   * List files in a project
   */
  async listProjectFiles(projectId: string): Promise<ProjectFile[]> {
    return await apiFetch<ProjectFile[]>(`/api/v1/projects/${projectId}/files`, {
      requireAuth: true,
    });
  }

  /**
   * Start analysis with project association
   */
  async analyzeWithProject(
    file: File,
    projectId?: string
  ): Promise<{ sessionId: string; stream: ReadableStream }> {
    const formData = new FormData();
    formData.append('file', file);
    
    if (projectId) {
      formData.append('project_id', projectId);
    }
    formData.append('language', readPreferences().language);
    formData.append('training_consent', String(readPreferences().trainingConsent));

    const response = await fetch('/api/v1/analyze', {
      method: 'POST',
      headers: { ...CSRF_HEADERS },
      credentials: 'include',  // the httpOnly session cookie (step 2.5)
      body: formData,
    });

    if (!response.ok) {
      if (response.status === 401) {
        // Clear invalid token and redirect to login
        localStorage.removeItem('auth_user');
        throw new Error('Authentication failed. Please login again.');
      }
      throw new Error(`Analysis failed: ${response.statusText}`);
    }

    const sessionId = response.headers.get('X-Session-ID') || '';
    
    if (!response.body) {
      throw new Error('No response body received');
    }

    return {
      sessionId,
      stream: response.body,
    };
  }

  /**
   * Follow an analysis that is running or finished, from its `start`-th event (after a reload or a dropped connection).
   * The analysis runs on the server whether or not anyone is following it.
   */
  async followSession(sessionId: string, start = 0): Promise<ReadableStream> {
    const response = await fetch(`/api/v1/sessions/${sessionId}/events?start=${start}`, { credentials: 'include' });
    if (!response.ok || !response.body) {
      throw new Error(`Could not reopen the analysis: ${response.statusText || response.status}`);
    }
    return response.body;
  }

  /**
   * Get analysis sessions
   */
  async getAnalysisSessions(
    projectId?: string,
    skip = 0,
    limit = 20
  ): Promise<AnalysisSession[]> {
    const params = new URLSearchParams({
      skip: skip.toString(),
      limit: limit.toString(),
    });

    if (projectId) {
      params.append('project_id', projectId);
    }

    return await apiFetch<AnalysisSession[]>(`/api/v1/analyze/sessions?${params}`, {
      requireAuth: true,
    });
  }

  /**
   * Get analysis sessions for a specific project
   */
  async getProjectAnalysisSessions(
    projectId: string,
    skip = 0,
    limit = 20
  ): Promise<AnalysisSession[]> {
    const params = new URLSearchParams({
      skip: skip.toString(),
      limit: limit.toString(),
    });

    return await apiFetch<AnalysisSession[]>(`/api/v1/projects/${projectId}/sessions?${params}`, {
      requireAuth: true,
    });
  }

  /**
   * Get a specific analysis session
   */
  async reviewFunction(sessionId: string, vulnerability: string, functionName: string, status: ReviewStatus, note?: string): Promise<FunctionReview[]> {
    return await apiFetch<FunctionReview[]>(`/api/v1/sessions/${sessionId}/reviews`, {
      method: 'PUT',
      body: { vulnerability, function_name: functionName, status, note },
      requireAuth: true,
    });
  }

  /** Every flagged function with its review, its fix and its stage in the workflow. */
  async getFindings(sessionId: string): Promise<Finding[]> {
    return await apiFetch<Finding[]>(`/api/v1/sessions/${sessionId}/findings`, { requireAuth: true });
  }

  /** `suggestedCode` is the fix the expert looked at: the server refuses (409) if a different one was recorded since. */
  async decideFix(sessionId: string, vulnerability: string, functionName: string, decision: FixDecision, suggestedCode: string, note?: string): Promise<FunctionFix[]> {
    return await apiFetch<FunctionFix[]>(`/api/v1/sessions/${sessionId}/fixes`, {
      method: 'PUT',
      body: { vulnerability, function_name: functionName, decision, suggested_code: suggestedCode, note },
      requireAuth: true,
    });
  }

  /** Step 2.1: the repair agent proposes a fix and checks it (compile, Slither, re-scan); the fix waits for an expert. */
  async runRepairAgent(sessionId: string, vulnerability: string, functionName: string): Promise<RepairAgentResult> {
    return await apiFetch<RepairAgentResult>(`/api/v1/refactor/agent`, {
      method: 'POST',
      body: { session_id: sessionId, vulnerability, function_name: functionName, language: readPreferences().language },
      requireAuth: true,
    });
  }

  /** Expert worklist: sessions from any user with at least one flagged function. */
  async getReviewQueue(): Promise<AnalysisSession[]> {
    return await apiFetch<AnalysisSession[]>(`/api/v1/reviews/queue`, { requireAuth: true });
  }

  async getSessionSource(sessionId: string): Promise<{ filename: string; source: string }> {
    return await apiFetch(`/api/v1/sessions/${sessionId}/source`, { requireAuth: true });
  }

  /** SARIF for VS Code (SARIF Viewer) and GitHub code scanning. */
  async getSessionSarif(sessionId: string): Promise<unknown> {
    return await apiFetch<unknown>(`/api/v1/sessions/${sessionId}/sarif`, { requireAuth: true });
  }

  async getAnalysisSession(sessionId: string): Promise<AnalysisSession> {
    return await apiFetch<AnalysisSession>(`/api/v1/analyze/sessions/${sessionId}`, {
      requireAuth: true,
    });
  }
}

export const projectService = new ProjectService();
