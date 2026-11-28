import { apiFetch, apiConfig, CSRF_HEADERS } from './api';
import type { DataPolicy, Role } from './auth';

export interface Member {
  id: string;
  username: string;
  email: string;
  full_name?: string | null;
  role: Role;
  is_active: boolean;
  created_at?: string;
  last_login?: string | null;
  consents_ok: boolean;
}

export interface Overview {
  organization: { id: string; name: string; personal: boolean };
  policy: DataPolicy;
  stats: {
    projects: number; members: number; scans_this_month: number; alerts_by_vulnerability: Record<string, number>;
    alerts_pending_review: number; verdicts: Record<string, number>; fixes_accepted: number; storage_bytes: number;
    scans_expiring_in_7_days: number;
    scans_by_day: { day: string; scans: number; flagged: number }[];
    members_by_role: Record<string, number>;
  };
}

export interface OrgProject { id: string; name: string; status: string; scans: number; alerts: number; storage_bytes: number; updated_at?: string }
export interface AuditEntry { at: string; actor: string; actor_role?: string; action: string; target?: string; detail?: Record<string, unknown> }
export interface DeletionEntry { at: string; kind: string; target_id: string; filename?: string; name?: string; actor: string; reason: string; removed: Record<string, number> }

const BASE = '/api/v1/organization';
const qs = (params: Record<string, string | undefined>) => {
  const q = new URLSearchParams(Object.entries(params).filter(([, v]) => v) as [string, string][]).toString();
  return q ? `?${q}` : '';
};

export const organizationService = {
  overview: () => apiFetch<Overview>(BASE, { requireAuth: true }),
  members: () => apiFetch<Member[]>(`${BASE}/members`, { requireAuth: true }),
  addMember: (body: { username: string; email: string; password: string; full_name?: string; role: Role }) =>
    apiFetch<Member>(`${BASE}/members`, { method: 'POST', body, requireAuth: true }),
  updateMember: (id: string, body: { role?: Role; is_active?: boolean }) =>
    apiFetch<Member>(`${BASE}/members/${id}`, { method: 'PUT', body, requireAuth: true }),
  removeMember: (id: string) => apiFetch(`${BASE}/members/${id}`, { method: 'DELETE', requireAuth: true }),
  updatePolicy: (body: Partial<DataPolicy>) => apiFetch<DataPolicy>(`${BASE}/policy`, { method: 'PUT', body, requireAuth: true }),
  projects: () => apiFetch<OrgProject[]>(`${BASE}/projects`, { requireAuth: true }),
  audit: (f: { actor?: string; action?: string; since?: string; until?: string }) => apiFetch<AuditEntry[]>(`${BASE}/audit${qs(f)}`, { requireAuth: true }),
  deletions: () => apiFetch<DeletionEntry[]>(`${BASE}/deletions`, { requireAuth: true }),
  /** CSV export through the session cookie, saved as a file */
  async download(kind: 'audit' | 'deletions', filters: Record<string, string | undefined> = {}) {
    const r = await fetch(`${apiConfig.baseURL}${BASE}/${kind}${qs({ ...filters, format: 'csv' })}`, { credentials: 'include', headers: CSRF_HEADERS });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const url = URL.createObjectURL(await r.blob());
    const a = Object.assign(document.createElement('a'), { href: url, download: kind === 'audit' ? 'audit-log.csv' : 'deletions.csv' });
    a.click();
    URL.revokeObjectURL(url);
  },
};
