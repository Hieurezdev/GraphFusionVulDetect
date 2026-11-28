
import json, time
from playwright.sync_api import sync_playwright
B="http://127.0.0.1:18530"; OUT="/out"; H={"X-Requested-With":"ScanGuard"}
PREF="localStorage.setItem('gf_preferences', JSON.stringify({language:'vi', theme:'light', animateScans:false, collapseFinishedSteps:true, startPage:'/project'}))"
def ctx_for(b, user):
    c=b.new_context(viewport={"width":1400,"height":950}, locale="vi-VN", color_scheme="light"); c.add_init_script(PREF)
    time.sleep(7); r=c.request.post(f"{B}/api/v1/auth/login", data={"username":user,"password":"secret12"}); assert r.ok,(user,r.status,r.text()); return c
def api(c,m,p,**kw):
    r=c.request.fetch(f"{B}/api/v1{p}",method=m,headers=H,**kw); return r.status,(r.json() if "json" in (r.headers.get("content-type") or "") else r.text())
def shot(pg,name,full=False):
    pg.wait_for_timeout(800); pg.screenshot(path=f"{OUT}/{name}-light.png", full_page=full); print("shot",name,flush=True)
with sync_playwright() as p:
    b=p.chromium.launch()
    reg=b.new_context(viewport={"width":1400,"height":950}, color_scheme="light"); reg.add_init_script(PREF)
    rp=reg.new_page(); rp.goto(f"{B}/register"); rp.click("#acct-business"); rp.fill("#organization","Công ty Demo"); shot(rp,"00-register-account-type")
    n=f"light{int(time.time())%100000}"
    r=p.request.new_context().post(f"{B}/api/v1/auth/register", data={"username":n,"email":f"{n}@example.com","password":"secret12","full_name":"Khách Demo"}); print("register",r.status)
    g=ctx_for(b,n); pg=g.new_page(); pg.goto(f"{B}/project"); pg.wait_for_url("**/consent"); pg.wait_for_selector("text=Trước khi bắt đầu")
    shot(pg,"01-consent",True)
    for k in ("terms","privacy","upload_rights"): pg.click(f"#accept-{k}")
    shot(pg,"02-consent-checked")
    sep=ctx_for(b,"sep.demo"); admin=ctx_for(b,"admin.demo")
    s,proj=api(sep,"POST","/projects/",data={"name":"Ví điện tử EtherStore (sáng)","description":"Demo bảo vệ mã nguồn"}); print("project",s)
    src=open("/demo/EtherStore.sol","rb").read()
    r=sep.request.post(f"{B}/api/v1/analyze",headers=H,multipart={"file":{"name":"EtherStore.sol","mimeType":"text/plain","buffer":src},"project_id":proj["id"],"language":"vi"},timeout=600000)
    print("scan",r.status,r.headers.get("x-session-id"))
    p2=sep.new_page(); p2.goto(f"{B}/project/{proj['id']}"); p2.wait_for_selector("text=Gửi chuyên gia rà soát",timeout=60000)
    shot(p2,"04-nontech-result"); p2.mouse.wheel(0,900); shot(p2,"04b-nontech-result-detail")
    pa=admin.new_page(); pa.goto(f"{B}/admin"); pa.wait_for_selector("text=Lượt quét trong tháng"); shot(pa,"05-admin-overview")
    pa.click("role=tab[name='Thành viên']"); pa.wait_for_selector("text=dev.demo@example.com"); shot(pa,"06-admin-members",True)
    pa.click("role=tab[name='Chính sách dữ liệu']"); pa.wait_for_selector("text=Thời hạn lưu (ngày)"); shot(pa,"07-admin-policy")
    pa.click("role=tab[name='Nhật ký kiểm toán']"); pa.wait_for_selector("text=Mở mã nguồn"); shot(pa,"08-admin-audit",True)
    pd=admin.new_page(); pd.goto(f"{B}/project/{proj['id']}"); pd.wait_for_selector("text=Xóa lượt quét",timeout=60000)
    pd.click("text=Xóa lượt quét"); pd.wait_for_selector("text=Xóa lượt quét này?"); shot(pd,"09-delete-confirm")
    pd.click("role=alertdialog >> role=button[name='Xóa']"); pd.wait_for_timeout(2500)
    pa.reload(); pa.click("role=tab[name='Lịch sử xóa']"); pa.wait_for_selector("text=EtherStore.sol"); shot(pa,"10-admin-deletions")
    b.close()
