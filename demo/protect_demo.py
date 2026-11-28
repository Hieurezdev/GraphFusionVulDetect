"""Demo of the protection of uploaded code against the local demo stack (http://127.0.0.1:18530)."""
import json, os, sys, time
from playwright.sync_api import sync_playwright

B = "http://127.0.0.1:18530"
OUT = "/demo/shots"
H = {"X-Requested-With": "ScanGuard"}
LOG = []

def log(*a):
    line = " ".join(str(x) for x in a)
    LOG.append(line); print(line, flush=True)

def ctx_for(browser, user, password="secret12"):
    ctx = browser.new_context(viewport={"width": 1400, "height": 950}, locale="vi-VN")
    ctx.add_init_script("localStorage.setItem('gf_preferences', JSON.stringify({language:'vi', animateScans:false, collapseFinishedSteps:true, startPage:'/project'}))")
    time.sleep(7)  # nginx allows ~10 sign-ins a minute per client
    r = ctx.request.post(f"{B}/api/v1/auth/login", data={"username": user, "password": password})
    assert r.ok, (user, r.status, r.text())
    return ctx

def api(ctx, method, path, **kw):
    r = ctx.request.fetch(f"{B}/api/v1{path}", method=method, headers=H, **kw)
    return r.status, (r.json() if "json" in (r.headers.get("content-type") or "") else r.text())

def accept(ctx, training=None):
    body = {"terms": True, "privacy": True, "upload_rights": True, **({} if training is None else {"training_data": training})}
    s, j = api(ctx, "POST", "/auth/consents", data=body)
    assert s == 200, (s, j)

def shot(page, name, full=False):
    page.wait_for_timeout(800)
    page.screenshot(path=f"{OUT}/{name}.png", full_page=full)
    log("screenshot", name)

with sync_playwright() as p:
    browser = p.chromium.launch()
    req = p.request.new_context()
    # 1. Sign-up of the workspace admin; the first page is the consent screen
    reg = browser.new_context(viewport={"width": 1400, "height": 950})
    reg.add_init_script("localStorage.setItem('gf_preferences', JSON.stringify({language:'vi'}))")
    rp = reg.new_page(); rp.goto(f"{B}/register"); rp.click("#acct-business"); rp.fill("#organization", "Công ty Demo")
    shot(rp, "00-register-account-type")
    r = req.post(f"{B}/api/v1/auth/register", data={"username": "admin.demo", "email": "admin.demo@example.com", "password": "secret12",
                                                    "full_name": "Quản trị Demo", "account_type": "business", "organization_name": "Công ty Demo"})
    log("register admin", r.status)
    admin = ctx_for(browser, "admin.demo")
    page = admin.new_page()
    s, j = api(admin, "GET", "/sessions")
    log("before consent GET /sessions ->", s, j)
    page.goto(f"{B}/project"); page.wait_for_url("**/consent"); page.wait_for_selector("text=Trước khi bắt đầu")
    shot(page, "01-consent", full=True)
    for key in ("terms", "privacy", "upload_rights"):
        page.click(f"#accept-{key}")
    shot(page, "02-consent-checked")
    page.click("text=Đồng ý và tiếp tục"); page.wait_for_url("**/project")
    log("admin accepted consents")
    # 2. Data policy: no code to the external LLM in this demo, retention 30 days
    log("policy", api(admin, "PUT", "/organization/policy", data={"external_llm": False, "retention_days": 30}))
    # 3. Members
    for name, role in (("dev.demo", "developer"), ("sep.demo", "non_tech"), ("expert.demo", "expert")):
        s, j = api(admin, "POST", "/organization/members", data={"username": name, "email": f"{name}@example.com", "password": "secret12", "role": role, "full_name": name})
        log("add member", name, role, s)
    dev, sep, exp = ctx_for(browser, "dev.demo"), ctx_for(browser, "sep.demo"), ctx_for(browser, "expert.demo")
    en = browser.new_context(viewport={"width": 1400, "height": 950})
    en.add_init_script("localStorage.setItem('gf_preferences', JSON.stringify({language:'en'}))")
    time.sleep(7); en.request.post(f"{B}/api/v1/auth/login", data={"username": "expert.demo", "password": "secret12"})
    pe = en.new_page(); pe.goto(f"{B}/consent"); pe.wait_for_selector("text=Before you start"); shot(pe, "02b-consent-english")
    accept(dev); accept(sep); accept(exp)
    # 4. The non-technical member uploads a contract into a project and waits for the scan
    s, proj = api(sep, "POST", "/projects/", data={"name": "Ví điện tử EtherStore", "description": "Demo bảo vệ mã nguồn"})
    log("create project", s)
    src = open("/demo/EtherStore.sol", "rb").read()
    r = sep.request.post(f"{B}/api/v1/analyze", headers=H, multipart={"file": {"name": "EtherStore.sol", "mimeType": "text/plain", "buffer": src}, "project_id": proj["id"], "language": "vi"}, timeout=600000)
    events = [json.loads(l) for l in r.text().splitlines() if l.strip()]
    sid = r.headers.get("x-session-id")
    log("scan", r.status, "session", sid, "last event", events[-1]["node"])
    s, sess = api(sep, "GET", f"/sessions/{sid}")
    storage_dir = os.path.dirname(sess["file_path"])
    log("stored at", sess["file_path"], "expires_at", sess["expires_at"])
    # 5. Screens: developer, then the non-technical uploader (same rights, everyday words)
    s, _ = api(sep, "GET", f"/sessions/{sid}/source"); log("non_tech GET source ->", s)
    s, _ = api(admin, "POST", "/refactor/chat/stream", data={"code": "x", "conversation_history": [{"role": "user", "content": "hi"}]}); log("business admin fix assistant ->", s)
    pg2 = sep.new_page(); pg2.goto(f"{B}/project/{proj['id']}"); pg2.wait_for_selector("text=Gửi chuyên gia rà soát", timeout=60000)
    shot(pg2, "04-nontech-result")
    pg2.mouse.wheel(0, 900); shot(pg2, "04b-nontech-result-detail")
    # someone from another workspace
    req.post(f"{B}/api/v1/auth/register", data={"username": "outsider", "email": "outsider@example.com", "password": "secret12"})
    out = ctx_for(browser, "outsider"); accept(out)
    s, _ = api(out, "GET", f"/sessions/{sid}/source"); log("other workspace GET source ->", s)
    s, _ = api(dev, "GET", f"/sessions/{sid}/source"); log("another member (developer) GET source ->", s)
    # 6. Admin dashboard
    pa = admin.new_page(); pa.goto(f"{B}/admin"); pa.wait_for_selector("text=Lượt quét trong tháng")
    shot(pa, "05-admin-overview")
    pa.click("role=tab[name='Thành viên']"); pa.wait_for_selector("text=dev.demo@example.com"); shot(pa, "06-admin-members", full=True)
    pa.click("role=tab[name='Chính sách dữ liệu']"); pa.wait_for_selector("text=Thời hạn lưu (ngày)"); shot(pa, "07-admin-policy")
    pa.click("role=tab[name='Nhật ký kiểm toán']"); pa.wait_for_selector("text=Mở mã nguồn"); shot(pa, "08-admin-audit", full=True)
    # 7. Delete the scan from the result page (admin), then the evidence
    log("storage before delete:", sorted(os.listdir("/storage")))
    pd = admin.new_page(); pd.goto(f"{B}/project/{proj['id']}"); pd.wait_for_selector("text=Xóa lượt quét", timeout=60000)
    pd.click("text=Xóa lượt quét"); pd.wait_for_selector("text=Xóa lượt quét này?"); shot(pd, "09-delete-confirm")
    pd.click("role=alertdialog >> role=button[name='Xóa']"); pd.wait_for_timeout(2500)
    s, j = api(admin, "GET", f"/sessions/{sid}/source"); log("after delete GET source ->", s, j)
    log("storage after delete:", sorted(os.listdir("/storage")), "dir still there:", os.path.exists("/storage/" + os.path.basename(storage_dir)))
    pa.reload(); pa.click("role=tab[name='Lịch sử xóa']"); pa.wait_for_selector("text=EtherStore.sol"); shot(pa, "10-admin-deletions")
    s, dl = api(admin, "GET", "/organization/deletions"); log("deletion log:", json.dumps(dl[0], ensure_ascii=False))
    s, au = api(admin, "GET", "/organization/audit"); log("audit:", json.dumps([(a["actor"], a["action"], a.get("detail", {}).get("reason")) for a in au], ensure_ascii=False))
    browser.close()
open("/demo/transcript.txt", "w").write("\n".join(LOG) + "\n")
