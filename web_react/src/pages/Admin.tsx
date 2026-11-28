import { useEffect, useState } from "react";
import Header from "@/components/Header";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ROLE_LABELS } from "@/components/PrivacyDialog";
import { useAuth } from "@/contexts/AuthContext";
import type { DataPolicy, Role } from "@/services/auth";
import { organizationService, type AuditEntry, type DeletionEntry, type Member, type OrgProject, type Overview } from "@/services/organization";
import { projectService } from "@/services/project";
import { VULNERABILITY_LABELS } from "@/lib/findings";
import { toast } from "sonner";
import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Label as ChartLabel, LabelList, Pie, PieChart, XAxis, YAxis } from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";
import { FolderKanban, HardDrive, ScanLine, ShieldAlert, Users, Wrench } from "lucide-react";
import { useT } from "@/i18n";

const ROLES: Role[] = ["admin", "developer", "non_tech", "expert"];
const ACTIONS = ["view_source", "export_sarif", "access_denied", "request_review", "delete_session", "delete_project", "delete_account",
  "member_add", "member_update", "member_remove", "policy_change", "consent"];
const ACTION_LABELS: Record<string, string> = {
  view_source: "Opened source code", export_sarif: "Exported SARIF", access_denied: "Access denied", request_review: "Sent for review",
  delete_session: "Deleted a scan", delete_project: "Deleted a project", delete_account: "Deleted an account", member_add: "Added a member",
  member_update: "Changed a member", member_remove: "Removed a member", policy_change: "Changed the data policy", consent: "Accepted the terms",
};
const REMOVED: Record<string, string> = { sessions: "{n} scan(s)", files: "{n} file(s)", knowledge_items: "{n} knowledge-base item(s)", label_events_scrubbed: "{n} label-log event(s) scrubbed", label_events_pseudonymised: "{n} label-log event(s) pseudonymised" };
const REASONS: Record<string, string> = { manual: "By hand", retention: "Retention period ended", project_deleted: "Project deleted", account_deleted: "Account deleted" };

const fail = (t: ReturnType<typeof useT>) => (e: unknown) => toast.error(e instanceof Error ? e.message : t("Request failed"));
const size = (b: number) => (b > 1e6 ? `${(b / 1e6).toFixed(1)} MB` : `${Math.ceil(b / 1e3)} KB`);
const when = (t: ReturnType<typeof useT>, d?: string | null) => (d ? new Date(d).toLocaleString(t.locale) : "–");
const detailText = (d?: Record<string, unknown>) =>
  d && Object.keys(d).length ? Object.entries(d).map(([k, v]) => `${k}: ${typeof v === "object" ? JSON.stringify(v) : v}`).join(", ") : "";

// Chart series keys are prefixed with s-: the chart sets --color-<key>, which must never shadow a theme token.
const C = { accent: "var(--color-accent)", cool: "var(--color-cool)", bad: "var(--color-bad)", ok: "var(--color-ok)", muted: "var(--color-muted)", rule: "var(--color-rule-2)" };

const Stat = ({ label, value, icon: Icon, tone = "ink", note }: { label: string; value: string | number; icon: typeof Users; tone?: "ink" | "bad" | "ok" | "cool"; note?: string }) => (
  <div className="panel flex items-start gap-4 p-5 transition-transform duration-200 hover:-translate-y-0.5">
    <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-full ${tone === "bad" ? "bg-bad-soft text-bad" : tone === "ok" ? "bg-ok-soft text-ok" : tone === "cool" ? "bg-cool-soft text-cool" : "bg-signal-soft text-signal"}`}>
      <Icon className="h-5 w-5" aria-hidden="true" />
    </span>
    <div className="min-w-0">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="measured mt-1 text-3xl leading-none text-ink">{value}</p>
      {note && <p className="mt-1 text-xs text-muted-foreground">{note}</p>}
    </div>
  </div>
);

const ChartPanel = ({ title, children, className = "" }: { title: string; children: React.ReactNode; className?: string }) => (
  <section className={`panel p-5 ${className}`}>
    <h3 className="text-sm text-ink">{title}</h3>
    <div className="mt-4">{children}</div>
  </section>
);

const Donut = ({ data, config, total, label }: { data: { key: string; value: number }[]; config: ChartConfig; total: number; label: string }) => (
  <div className="flex flex-wrap items-center gap-6">
    <ChartContainer config={config} className="aspect-square h-44">
      <PieChart>
        <ChartTooltip content={<ChartTooltipContent nameKey="key" hideLabel />} />
        <Pie data={total ? data : [{ key: "s-empty", value: 1 }]} dataKey="value" nameKey="key" innerRadius={52} outerRadius={78} strokeWidth={2} stroke="var(--color-paper-2)">
          {(total ? data : [{ key: "s-empty" }]).map(d => <Cell key={d.key} fill={total ? `var(--color-${d.key})` : C.rule} />)}
          <ChartLabel content={({ viewBox }) => viewBox && "cx" in viewBox ? (
            <text x={viewBox.cx} y={viewBox.cy} textAnchor="middle" dominantBaseline="middle">
              <tspan x={viewBox.cx} y={viewBox.cy} className="fill-current text-2xl text-ink" style={{ fill: "var(--color-ink)" }}>{total}</tspan>
              <tspan x={viewBox.cx} y={(viewBox.cy ?? 0) + 20} style={{ fill: "var(--color-muted)", fontSize: 12 }}>{label}</tspan>
            </text>) : null} />
        </Pie>
      </PieChart>
    </ChartContainer>
    <ul className="space-y-2 text-sm">
      {data.map(d => (
        <li key={d.key} className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full" style={{ background: config[d.key]?.color }} aria-hidden="true" />
          <span className="text-ink-2">{config[d.key]?.label}</span>
          <span className="measured ml-auto pl-4 text-ink">{d.value}</span>
        </li>
      ))}
    </ul>
  </div>
);

const OverviewTab = ({ data }: { data: Overview | null }) => {
  const t = useT();
  if (!data) return <p className="text-sm text-muted-foreground" role="status">{t("Loading…")}</p>;
  const s = data.stats;
  const short = (d: string) => new Date(d + "T00:00:00").toLocaleDateString(t.locale, { day: "2-digit", month: "2-digit" });
  const activity: ChartConfig = { "s-scans": { label: t("Scans"), color: C.cool }, "s-flagged": { label: t("Scans with alerts"), color: C.bad } };
  const days = s.scans_by_day.map(d => ({ day: short(d.day), "s-scans": d.scans, "s-flagged": d.flagged }));
  const vulnConfig: ChartConfig = { count: { label: t("Alerts"), color: C.bad } };
  const vulns = Object.entries(s.alerts_by_vulnerability).map(([v, n]) => ({ name: t(VULNERABILITY_LABELS[v] ?? v), count: n }));
  const verdictConfig: ChartConfig = {
    "s-confirmed": { label: t("Confirmed"), color: C.bad }, "s-rejected": { label: t("Not a real problem"), color: C.ok },
    "s-manual": { label: t("Needs manual review"), color: C.cool }, "s-pending": { label: t("Awaiting review"), color: C.muted },
  };
  const verdicts = [
    { key: "s-confirmed", value: s.verdicts.confirmed ?? 0 }, { key: "s-rejected", value: s.verdicts.false_positive ?? 0 },
    { key: "s-manual", value: s.verdicts.needs_manual_review ?? 0 }, { key: "s-pending", value: s.alerts_pending_review },
  ];
  const roleConfig: ChartConfig = {
    "s-admin": { label: t("Admin"), color: C.accent }, "s-developer": { label: t("Developer"), color: C.cool },
    "s-non_tech": { label: t("Non-tech"), color: C.ok }, "s-expert": { label: t("Expert"), color: C.bad },
  };
  const roles = Object.keys(roleConfig).map(k => ({ key: k, value: s.members_by_role[k.slice(2)] ?? 0 }));
  const totalScans = s.scans_by_day.reduce((a, d) => a + d.scans, 0);
  return (
    <div className="space-y-6">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Stat icon={ScanLine} tone="cool" label={t("Scans this month")} value={s.scans_this_month} note={t("{n} in the last 30 days", { n: totalScans })} />
        <Stat icon={ShieldAlert} tone="bad" label={t("Alerts awaiting review")} value={s.alerts_pending_review} />
        <Stat icon={Wrench} tone="ok" label={t("Fixes accepted")} value={s.fixes_accepted} />
        <Stat icon={HardDrive} label={t("Code stored")} value={size(s.storage_bytes)} note={t("{n} scan(s) deleted in the next 7 days", { n: s.scans_expiring_in_7_days })} />
      </div>
      <div className="grid gap-4 lg:grid-cols-3">
        <ChartPanel title={t("Scans in the last 30 days")} className="lg:col-span-2">
          <ChartContainer config={activity} className="h-64 w-full">
            <AreaChart data={days} margin={{ left: 0, right: 8, top: 8 }}>
              <defs>
                {(["s-scans", "s-flagged"] as const).map(k => (
                  <linearGradient key={k} id={`fill-${k}`} x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={`var(--color-${k})`} stopOpacity={0.35} />
                    <stop offset="95%" stopColor={`var(--color-${k})`} stopOpacity={0.02} />
                  </linearGradient>
                ))}
              </defs>
              <CartesianGrid vertical={false} stroke="var(--color-rule)" />
              <XAxis dataKey="day" tickLine={false} axisLine={false} tickMargin={8} minTickGap={24} />
              <YAxis allowDecimals={false} tickLine={false} axisLine={false} width={28} />
              <ChartTooltip content={<ChartTooltipContent indicator="line" />} />
              <Area dataKey="s-scans" type="monotone" stroke="var(--color-s-scans)" fill="url(#fill-s-scans)" strokeWidth={2} />
              <Area dataKey="s-flagged" type="monotone" stroke="var(--color-s-flagged)" fill="url(#fill-s-flagged)" strokeWidth={2} />
            </AreaChart>
          </ChartContainer>
        </ChartPanel>
        <ChartPanel title={t("Alerts by kind of problem")}>
          {vulns.length ? (
            <ChartContainer config={vulnConfig} className="h-64 w-full">
              <BarChart data={vulns} layout="vertical" margin={{ left: 8, right: 16 }}>
                <XAxis type="number" allowDecimals={false} domain={[0, "dataMax"]} hide />
                <YAxis type="category" dataKey="name" tickLine={false} axisLine={false} width={130} />
                <ChartTooltip content={<ChartTooltipContent hideLabel />} />
                <Bar dataKey="count" fill="var(--color-count)" radius={4} barSize={28}>
                  <LabelList dataKey="count" position="insideRight" style={{ fill: "var(--color-paper-2)", fontSize: 13 }} />
                </Bar>
              </BarChart>
            </ChartContainer>
          ) : <p className="grid h-64 place-items-center text-sm text-muted-foreground">{t("No alert yet.")}</p>}
        </ChartPanel>
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <ChartPanel title={t("Expert verdicts on alerts")}>
          <Donut data={verdicts} config={verdictConfig} total={verdicts.reduce((a, d) => a + d.value, 0)} label={t("alerts")} />
        </ChartPanel>
        {!data.organization.personal ? (
          <ChartPanel title={t("Members by role")}>
            <Donut data={roles} config={roleConfig} total={s.members} label={t("members")} />
          </ChartPanel>
        ) : (
          <ChartPanel title={t("Projects")}>
            <div className="flex items-center gap-4">
              <span className="grid h-12 w-12 place-items-center rounded-full bg-signal-soft text-signal"><FolderKanban className="h-6 w-6" aria-hidden="true" /></span>
              <p className="measured text-4xl text-ink">{s.projects}</p>
            </div>
          </ChartPanel>
        )}
      </div>
    </div>
  );
};

const MembersTab = ({ me }: { me?: string }) => {
  const t = useT();
  const [members, setMembers] = useState<Member[] | null>(null);
  const [form, setForm] = useState({ username: "", email: "", full_name: "", password: "", role: "developer" as Role });
  const load = () => organizationService.members().then(setMembers).catch(fail(t));
  useEffect(() => { load(); }, []);  // eslint-disable-line react-hooks/exhaustive-deps

  const add = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await organizationService.addMember({ ...form, full_name: form.full_name || undefined });
      toast.success(t("Member added. They accept the terms at their first sign-in."));
      setForm({ username: "", email: "", full_name: "", password: "", role: "developer" });
      load();
    } catch (err) { fail(t)(err); }
  };
  const update = (m: Member, body: { role?: Role; is_active?: boolean }) =>
    organizationService.updateMember(m.id, body).then(load).catch(fail(t));
  const remove = (m: Member) => {
    if (!window.confirm(t("Remove {name} from the workspace? Their scans stay in the workspace.", { name: m.username }))) return;
    organizationService.removeMember(m.id).then(load).catch(fail(t));
  };

  return (
    <div className="space-y-8">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>{t("Member")}</TableHead><TableHead>{t("Role")}</TableHead><TableHead>{t("Terms")}</TableHead>
            <TableHead>{t("Last sign-in")}</TableHead><TableHead>{t("Active")}</TableHead><TableHead><span className="sr-only">{t("Actions")}</span></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {(members ?? []).map(m => (
            <TableRow key={m.id}>
              <TableCell><span className="text-ink">{m.full_name || m.username}</span><span className="block text-xs text-muted-foreground">{m.email}</span></TableCell>
              <TableCell>
                <Select value={m.role} onValueChange={v => update(m, { role: v as Role })}>
                  <SelectTrigger className="h-8 w-36" aria-label={t("Role of {name}", { name: m.username })}><SelectValue /></SelectTrigger>
                  <SelectContent>{ROLES.map(r => <SelectItem key={r} value={r}>{t(ROLE_LABELS[r])}</SelectItem>)}</SelectContent>
                </Select>
              </TableCell>
              <TableCell>{m.consents_ok ? <Badge variant="ok">{t("Accepted")}</Badge> : <Badge variant="outline">{t("Not yet")}</Badge>}</TableCell>
              <TableCell className="text-xs">{when(t, m.last_login)}</TableCell>
              <TableCell><Switch checked={m.is_active} onCheckedChange={v => update(m, { is_active: v })} aria-label={t("{name} can sign in", { name: m.username })} /></TableCell>
              <TableCell>{m.id !== me && <Button size="sm" variant="outline" onClick={() => remove(m)}>{t("Remove")}</Button>}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <form onSubmit={add} className="panel grid gap-4 p-5 sm:grid-cols-2 lg:grid-cols-5" aria-labelledby="add-member">
        <h3 id="add-member" className="text-base sm:col-span-2 lg:col-span-5">{t("Add a member")}</h3>
        <div className="space-y-1"><Label htmlFor="m-user">{t("Username")}</Label><Input id="m-user" required value={form.username} onChange={e => setForm({ ...form, username: e.target.value })} /></div>
        <div className="space-y-1"><Label htmlFor="m-email">{t("Email")}</Label><Input id="m-email" type="email" required value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} /></div>
        <div className="space-y-1"><Label htmlFor="m-name">{t("Full name")}</Label><Input id="m-name" value={form.full_name} onChange={e => setForm({ ...form, full_name: e.target.value })} /></div>
        <div className="space-y-1"><Label htmlFor="m-pass">{t("Initial password")}</Label><Input id="m-pass" type="password" minLength={6} required autoComplete="new-password" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} /></div>
        <div className="space-y-1">
          <Label htmlFor="m-role">{t("Role")}</Label>
          <Select value={form.role} onValueChange={v => setForm({ ...form, role: v as Role })}>
            <SelectTrigger id="m-role"><SelectValue /></SelectTrigger>
            <SelectContent>{ROLES.map(r => <SelectItem key={r} value={r}>{t(ROLE_LABELS[r])}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div className="sm:col-span-2 lg:col-span-5"><Button type="submit">{t("Add member")}</Button></div>
      </form>
    </div>
  );
};

const ProjectsTab = () => {
  const t = useT();
  const [projects, setProjects] = useState<OrgProject[] | null>(null);
  const load = () => organizationService.projects().then(setProjects).catch(fail(t));
  useEffect(() => { load(); }, []);  // eslint-disable-line react-hooks/exhaustive-deps
  const remove = async (p: OrgProject) => {
    if (!window.confirm(t("Delete the project “{name}”? Its files and analysis results are removed for good.", { name: p.name }))) return;
    try { await projectService.deleteProject(p.id); toast.success(t("Project “{name}” deleted", { name: p.name })); load(); } catch (e) { fail(t)(e); }
  };
  const top = (projects ?? []).slice().sort((a, b) => b.scans - a.scans).slice(0, 8).map(p => ({ name: p.name.length > 22 ? p.name.slice(0, 21) + "…" : p.name, scans: p.scans - p.alerts, alerts: p.alerts }));
  const cfg: ChartConfig = { scans: { label: t("Scans without alerts"), color: C.cool }, alerts: { label: t("Scans with alerts"), color: C.bad } };
  return (
    <div className="space-y-6">
    {top.length > 0 && (
      <ChartPanel title={t("Scans per project")}>
        <ChartContainer config={cfg} className="w-full" style={{ height: Math.max(120, top.length * 40) }}>
          <BarChart data={top} layout="vertical" margin={{ left: 8, right: 16 }}>
            <XAxis type="number" allowDecimals={false} domain={[0, "dataMax"]} hide />
            <YAxis type="category" dataKey="name" tickLine={false} axisLine={false} width={170} />
            <ChartTooltip content={<ChartTooltipContent />} />
            <Bar dataKey="scans" stackId="p" fill="var(--color-scans)" barSize={22} />
            <Bar dataKey="alerts" stackId="p" fill="var(--color-alerts)" radius={[0, 4, 4, 0]} barSize={22} />
          </BarChart>
        </ChartContainer>
      </ChartPanel>
    )}
    <Table>
      <TableHeader><TableRow>
        <TableHead>{t("Project")}</TableHead><TableHead>{t("Scans")}</TableHead><TableHead>{t("Scans with alerts")}</TableHead>
        <TableHead>{t("Code stored")}</TableHead><TableHead>{t("Updated")}</TableHead><TableHead><span className="sr-only">{t("Actions")}</span></TableHead>
      </TableRow></TableHeader>
      <TableBody>
        {(projects ?? []).map(p => (
          <TableRow key={p.id}>
            <TableCell className="text-ink">{p.name}</TableCell><TableCell>{p.scans}</TableCell><TableCell>{p.alerts}</TableCell>
            <TableCell>{size(p.storage_bytes)}</TableCell><TableCell className="text-xs">{when(t, p.updated_at)}</TableCell>
            <TableCell><Button size="sm" variant="outline" onClick={() => remove(p)}>{t("Delete")}</Button></TableCell>
          </TableRow>
        ))}
        {projects?.length === 0 && <TableRow><TableCell colSpan={6} className="text-muted-foreground">{t("No project yet.")}</TableCell></TableRow>}
      </TableBody>
    </Table>
    </div>
  );
};

const PolicyTab = ({ policy, onChange, llmExternal }: { policy?: DataPolicy; onChange: (p: DataPolicy) => void; llmExternal?: boolean }) => {
  const t = useT();
  const [days, setDays] = useState(String(policy?.retention_days ?? 30));
  useEffect(() => { if (policy) setDays(String(policy.retention_days)); }, [policy?.retention_days]);  // eslint-disable-line react-hooks/exhaustive-deps
  if (!policy) return null;
  const save = (change: Partial<DataPolicy>) =>
    organizationService.updatePolicy(change).then(p => { onChange(p); toast.success(t("Data policy saved")); }).catch(fail(t));
  const Row = ({ id, title, note, value, field }: { id: string; title: string; note: string; value: boolean; field: keyof DataPolicy }) => (
    <div className="flex items-start justify-between gap-6 border-b border-rule py-4">
      <div><Label htmlFor={id} className="text-sm text-ink">{title}</Label><p className="mt-1 max-w-[70ch] text-xs text-muted-foreground">{note}</p></div>
      <Switch id={id} checked={value} onCheckedChange={v => save({ [field]: v })} />
    </div>
  );
  return (
    <div className="max-w-3xl">
      <div className="flex flex-wrap items-end gap-3 border-b border-rule py-4">
        <div className="space-y-1">
          <Label htmlFor="retention" className="text-sm text-ink">{t("Retention period (days)")}</Label>
          <p className="text-xs text-muted-foreground">{t("Scans older than this are deleted automatically with their code (1–365).")}</p>
          <Input id="retention" type="number" min={1} max={365} className="w-28" value={days} onChange={e => setDays(e.target.value)} />
        </div>
        <Button variant="outline" onClick={() => save({ retention_days: Number(days) })} disabled={!(Number(days) >= 1 && Number(days) <= 365)}>{t("Save")}</Button>
      </div>
      <Row id="p-llm" field="external_llm" value={policy.external_llm} title={t("Send flagged function code to the external AI service")}
        note={llmExternal ? t("Used for explanations, RefactorBot and the repair agent. Off: those features are not available to the workspace; detection still runs on the server.")
          : t("This server runs its AI model itself: no code leaves the server either way.")} />
      <Row id="p-training" field="training_data" value={policy.training_data} title={t("Allow the workspace's code to be used as training data")}
        note={t("Reviewed functions, verdicts and accepted fixes may retrain the models and serve as reference cases. Turning it off removes the workspace's code from the knowledge base at once.")} />
      <Row id="p-experts" field="platform_experts" value={policy.platform_experts} title={t("Let ScanGuard reviewers open scans sent for review")}
        note={t("Off: only the workspace's own experts review its scans.")} />
    </div>
  );
};

const AuditChart = ({ rows }: { rows: AuditEntry[] }) => {
  const t = useT();
  const by = new Map<string, { day: string; code: number; denied: number; other: number }>();
  for (const r of rows.slice().reverse()) {
    const day = new Date(r.at).toLocaleDateString(t.locale, { day: "2-digit", month: "2-digit" });
    const e = by.get(day) ?? { day, code: 0, denied: 0, other: 0 };
    if (r.action === "access_denied") e.denied += 1;
    else if (r.action === "view_source" || r.action === "export_sarif") e.code += 1;
    else e.other += 1;
    by.set(day, e);
  }
  const cfg: ChartConfig = { code: { label: t("Opened source code"), color: C.cool }, denied: { label: t("Access denied"), color: C.bad }, other: { label: t("Other actions"), color: C.muted } };
  return (
    <ChartPanel title={t("Activity by day")}>
      <ChartContainer config={cfg} className="h-48 w-full">
        <BarChart data={[...by.values()]} margin={{ left: 0, right: 8 }} maxBarSize={44}>
          <CartesianGrid vertical={false} stroke="var(--color-rule)" />
          <XAxis dataKey="day" tickLine={false} axisLine={false} tickMargin={8} />
          <YAxis allowDecimals={false} tickLine={false} axisLine={false} width={28} />
          <ChartTooltip content={<ChartTooltipContent />} />
          <Bar dataKey="code" stackId="a" fill="var(--color-code)" />
          <Bar dataKey="other" stackId="a" fill="var(--color-other)" />
          <Bar dataKey="denied" stackId="a" fill="var(--color-denied)" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ChartContainer>
    </ChartPanel>
  );
};

const AuditTab = () => {
  const t = useT();
  const [rows, setRows] = useState<AuditEntry[] | null>(null);
  const [filters, setFilters] = useState({ actor: "", action: "", since: "", until: "" });
  const load = () => organizationService.audit(filters).then(setRows).catch(fail(t));
  useEffect(() => { load(); }, []);  // eslint-disable-line react-hooks/exhaustive-deps
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end gap-3">
        <div className="space-y-1"><Label htmlFor="a-actor">{t("Person")}</Label><Input id="a-actor" className="w-40" value={filters.actor} onChange={e => setFilters({ ...filters, actor: e.target.value })} /></div>
        <div className="space-y-1">
          <Label htmlFor="a-action">{t("Action")}</Label>
          <Select value={filters.action || "all"} onValueChange={v => setFilters({ ...filters, action: v === "all" ? "" : v })}>
            <SelectTrigger id="a-action" className="w-52"><SelectValue /></SelectTrigger>
            <SelectContent><SelectItem value="all">{t("All")}</SelectItem>{ACTIONS.map(a => <SelectItem key={a} value={a}>{t(ACTION_LABELS[a])}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div className="space-y-1"><Label htmlFor="a-since">{t("From")}</Label><Input id="a-since" type="date" value={filters.since} onChange={e => setFilters({ ...filters, since: e.target.value })} /></div>
        <div className="space-y-1"><Label htmlFor="a-until">{t("To")}</Label><Input id="a-until" type="date" value={filters.until} onChange={e => setFilters({ ...filters, until: e.target.value })} /></div>
        <Button variant="outline" onClick={load}>{t("Filter")}</Button>
        <Button variant="outline" onClick={() => organizationService.download("audit", filters).catch(fail(t))}>{t("Export CSV")}</Button>
      </div>
      {rows && rows.length > 0 && <AuditChart rows={rows} />}
      <Table>
        <TableHeader><TableRow><TableHead>{t("Time")}</TableHead><TableHead>{t("Person")}</TableHead><TableHead>{t("Action")}</TableHead><TableHead>{t("Target")}</TableHead><TableHead>{t("Detail")}</TableHead></TableRow></TableHeader>
        <TableBody>
          {(rows ?? []).map((r, i) => (
            <TableRow key={i}>
              <TableCell className="whitespace-nowrap text-xs">{when(t, r.at)}</TableCell>
              <TableCell>{r.actor}{r.actor_role && <span className="block text-xs text-muted-foreground">{t(ROLE_LABELS[r.actor_role] ?? r.actor_role)}</span>}</TableCell>
              <TableCell>{r.action === "access_denied" ? <Badge variant="destructive">{t(ACTION_LABELS[r.action])}</Badge> : t(ACTION_LABELS[r.action] ?? r.action)}</TableCell>
              <TableCell className="text-xs">{r.target}</TableCell>
              <TableCell className="max-w-[28rem] break-words text-xs text-ink-2">{detailText(r.detail)}</TableCell>
            </TableRow>
          ))}
          {rows?.length === 0 && <TableRow><TableCell colSpan={5} className="text-muted-foreground">{t("Nothing recorded yet.")}</TableCell></TableRow>}
        </TableBody>
      </Table>
    </div>
  );
};

const DeletionsTab = () => {
  const t = useT();
  const [rows, setRows] = useState<DeletionEntry[] | null>(null);
  useEffect(() => { organizationService.deletions().then(setRows).catch(fail(t)); }, []);  // eslint-disable-line react-hooks/exhaustive-deps
  return (
    <div className="space-y-4">
      <Button variant="outline" onClick={() => organizationService.download("deletions").catch(fail(t))}>{t("Export CSV")}</Button>
      <Table>
        <TableHeader><TableRow><TableHead>{t("Time")}</TableHead><TableHead>{t("What")}</TableHead><TableHead>{t("By")}</TableHead><TableHead>{t("Reason")}</TableHead><TableHead>{t("Removed")}</TableHead></TableRow></TableHeader>
        <TableBody>
          {(rows ?? []).map((r, i) => (
            <TableRow key={i}>
              <TableCell className="whitespace-nowrap text-xs">{when(t, r.at)}</TableCell>
              <TableCell>{t(r.kind === "session" ? "Scan" : r.kind === "project" ? "Project" : "Account")}: {r.filename || r.name || r.target_id}</TableCell>
              <TableCell>{r.actor === "system" ? t("Automatic") : r.actor}</TableCell>
              <TableCell>{t(REASONS[r.reason] ?? r.reason)}</TableCell>
              <TableCell className="text-xs text-ink-2">{Object.entries(r.removed ?? {}).map(([k, n]) => t(REMOVED[k] ?? `${k}: {n}`, { n })).join(", ")}</TableCell>
            </TableRow>
          ))}
          {rows?.length === 0 && <TableRow><TableCell colSpan={5} className="text-muted-foreground">{t("Nothing deleted yet.")}</TableCell></TableRow>}
        </TableBody>
      </Table>
    </div>
  );
};

/** The workspace admin's dashboard: figures, members and roles, projects, data policy, audit log, deletion history. */
const Admin = () => {
  const t = useT();
  const { user, can, refreshUser } = useAuth();
  const [overview, setOverview] = useState<Overview | null>(null);
  useEffect(() => { if (can("manage_organization")) organizationService.overview().then(setOverview).catch(fail(t)); }, []);  // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="min-h-dvh bg-background">
      <Header />
      <main id="main" className="shell py-10 lg:py-12">
        <h1 className="text-4xl leading-none">{user?.personal_workspace ? t("Data settings") : t("Workspace admin")}</h1>
        {!can("manage_organization") ? (
          <p className="mt-6 text-ink-2">{t("Only the workspace admin can open this page.")}</p>
        ) : (
          <>
            <p className="mt-3 text-ink-2">{overview?.organization.name ?? user?.organization_name}</p>
            <Tabs defaultValue="overview" className="mt-8">
              <TabsList className="flex h-auto flex-wrap justify-start">
                <TabsTrigger value="overview">{t("Overview")}</TabsTrigger>
                {!user?.personal_workspace && <TabsTrigger value="members">{t("Members")}</TabsTrigger>}
                <TabsTrigger value="projects">{t("Projects")}</TabsTrigger>
                <TabsTrigger value="policy">{t("Data policy")}</TabsTrigger>
                <TabsTrigger value="audit">{t("Audit log")}</TabsTrigger>
                <TabsTrigger value="deletions">{t("Deletion history")}</TabsTrigger>
              </TabsList>
              <TabsContent value="overview" className="mt-6"><OverviewTab data={overview} /></TabsContent>
              {!user?.personal_workspace && <TabsContent value="members" className="mt-6"><MembersTab me={user?.id} /></TabsContent>}
              <TabsContent value="projects" className="mt-6"><ProjectsTab /></TabsContent>
              <TabsContent value="policy" className="mt-6">
                <PolicyTab policy={overview?.policy} llmExternal={user?.llm_external}
                  onChange={p => { setOverview(o => (o ? { ...o, policy: p } : o)); refreshUser(); }} />
              </TabsContent>
              <TabsContent value="audit" className="mt-6"><AuditTab /></TabsContent>
              <TabsContent value="deletions" className="mt-6"><DeletionsTab /></TabsContent>
            </Tabs>
          </>
        )}
      </main>
    </div>
  );
};

export default Admin;
