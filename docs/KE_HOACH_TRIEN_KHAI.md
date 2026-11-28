# Kế hoạch triển khai cải tiến – Bảng C

File này lưu **kế hoạch** và **quá trình triển khai** các cải tiến cho bảng C (tối ưu hệ thống, bảo mật, Agent/RAG).
Bản ý tưởng đầy đủ (lý do, kiến trúc, sơ đồ): [Ý tưởng cải tiến hoàn chỉnh – Bảng C](https://claude.ai/artifact/ReHZHdpNBttfJtanzZjvZD).

## Cách dùng file này

- Làm **từng bước theo thứ tự** trong bảng tổng quan; chỉ bắt đầu một bước khi các bước nó phụ thuộc đã `Xong`.
- Xong một bước thì cập nhật ba chỗ: cột **Trạng thái** trong bảng tổng quan, mục **Kết quả** của bước đó, và một dòng trong **Nhật ký triển khai** ở cuối file.
- Mỗi bước phải để lại **minh chứng** (số liệu, log, ảnh chụp, file trong `eval/`), vì báo cáo chung kết cần chúng.
- Trạng thái: `Chưa làm` · `Đang làm` · `Xong` · `Tạm dừng` (ghi lý do) · `Bỏ` (ghi lý do).

## Tổng quan

| Bước | Nội dung | Giai đoạn | Phụ thuộc | Trạng thái |
|---|---|---|---|---|
| 0.1 | Đo mốc hiện trạng (baseline) | 0. Chuẩn bị | – | Xong |
| 1.1 | Xử lý khóa bí mật bị commit | 1. Trước chung kết | – | Xong phần trong repo; phần server + lịch sử git chờ nhóm |
| 1.2 | Kiểm tra đầu ra của LLM | 1. Trước chung kết | – | Xong |
| 1.3 | Nhật ký nhãn chỉ-ghi-thêm + đồng ý dùng mã | 1. Trước chung kết | – | Xong |
| 1.4 | Lấy mẫu ngẫu nhiên hàm không bị gắn cờ | 1. Trước chung kết | 1.3 | Xong |
| 1.5 | Cache theo `file_hash` và theo vector hàm | 1. Trước chung kết | 0.1 | Xong |
| 1.6 | Hàng đợi job trên Redis → tách phân tích khỏi kết nối (MongoDB) | 1. Trước chung kết | 1.5 | Xong (đổi cách làm) |
| 1.7 | Hiệu chỉnh độ tin cậy + sắp xếp hàng chờ chuyên gia | 1. Trước chung kết | 0.1 | Xong |
| 1.8 | Kho tri thức + RAG cho lời giải thích | 1. Trước chung kết | 1.3, 1.5 | Xong |
| 1.9 | Vòng huấn luyện lại tối thiểu + cổng thay mô hình | 1. Trước chung kết | 1.3 | Xong (dựng luồng, chưa huấn luyện thật) |
| 1.10 | Giám sát + load test + chạy ổn định 48 giờ | 1. Trước chung kết | 1.6 | Xong phần giám sát + đo tải; chạy 48 giờ phải làm trên server |
| 2.1 | Agent sửa lỗi tự gọi công cụ | 2. Dự phòng 12 giờ | 1.8 | Xong |
| 2.2 | RAG cho RefactorBot | 2. Dự phòng 12 giờ | 1.8 | Xong |
| 2.3 | Sandbox cho solc, Slither và công cụ của agent | 2. Dự phòng 12 giờ | 1.6 | Xong một phần (tách tiến trình; tách mạng cần container trên server) |
| 2.4 | Bộ red-team cho LLM | 2. Dự phòng 12 giờ | 1.2 | Xong |
| 2.5 | JWT trong cookie `httpOnly` + CSP | 2. Dự phòng 12 giờ | – | Xong |
| 2.6 | Quy tắc hai chuyên gia + Cohen's kappa | 2. Dự phòng 12 giờ | 1.3 | Xong |
| 2.7 | Chế độ chạy bóng cho mô hình mới | 2. Dự phòng 12 giờ | 1.9 | Xong |
| 3.x | Dữ liệu Solidity 0.6–0.8, dự án nhiều file, xử lý theo ngưỡng | 3. Dài hạn | – | Chưa làm |

Giai đoạn 1 làm trước vòng chung kết, để có nền tảng và kịp chạy ổn định 48 giờ trước giờ chấm. Giai đoạn 2 là các phần mở rộng chuẩn bị sẵn cho thử thách cải tiến 12 giờ. Giai đoạn 3 là kế hoạch dài hạn, ghi trong báo cáo.

## Hiện trạng đã kiểm tra trong code (2026-11-28)

Các bước dưới đây dựa trên những điểm sau:

- **Kết luận chuyên gia:** lưu theo từng hàm trong `analysis_sessions.reviews` (`confirmed`, `false_positive`, `needs_manual_review`). Kết luận mới **ghi đè** kết luận cũ (`replace_entry` trong `src/services/findings.py`), mỗi hàm chỉ có một người duyệt.
- **Dự đoán và dữ liệu gốc:** dự đoán cho **mọi** hàm, kể cả hàm không bị gắn cờ, nằm trong `steps[].result_data.func_vulnerability_predictions`. File gốc và đồ thị `.fcg` nằm trong `storage/<thời điểm>/`.
- **Vector CodeBERT:** tính trong `fcg_converter.py:106`, lưu thành thuộc tính `featuresH` của đồ thị, nhưng **không được cache**.
- **`file_hash`:** SHA-256 được tính và lưu, nhưng **không dùng** để tái sử dụng kết quả.
- **Huấn luyện:** quy trình có trong `eval/ablation/ablation.py` (seed 42, chọn epoch trên validation, McNemar).
- **Hàng đợi:** chưa có. `docker-compose.prod.yml` **không có Redis**. Chỉ có `asyncio.Semaphore` giới hạn số phân tích chạy cùng lúc.
- **Đồng ý dùng mã:** chưa có trường nào.
- **Frontend:** dùng `react-markdown` mà không bật HTML thô, nên rủi ro XSS qua markdown thấp. JWT lưu trong `localStorage`.
- **Khóa bí mật:** `.env.production` có trong git từ PR #2, và các biến `JWT_SECRET`, `SECRET_KEY`, `MONGODB_PASSWORD`, `MINIO_SECRET_KEY`, `SMTP_PASSWORD` có giá trị.
- **LLM:** đã chuyển sang Claude Haiku qua Astral X bằng biến `CLAUDE_API_KEY`. Thay đổi này chưa được commit.

---

## Giai đoạn 0 – Chuẩn bị

### Bước 0.1 – Đo mốc hiện trạng

- **Mục tiêu:** có số liệu "trước" để so sánh với mọi cải tiến sau.
- **Việc cần làm:**
  - Viết `eval/baseline/run_baseline.py`, chạy qua API của sản phẩm trên một tập cố định, ví dụ 50 hợp đồng lấy từ tập kiểm thử của bài báo.
  - Ghi lại: thời gian mỗi hợp đồng (dựng đồ thị, mã hóa, suy luận, LLM), số token LLM, bộ nhớ đỉnh.
  - Tính ECE của xác suất mức hợp đồng trên tập validation.
  - Ghi lại tỉ lệ lời giải thích tự nhận ra dương tính giả trên các ca âm khó (11/32 timestamp, 27/73 reentrancy).
- **Tiêu chí hoàn thành:** có file `eval/baseline/baseline.json` và `eval/baseline/report.md`.
- **Minh chứng:** hai file trên, kèm cấu hình máy chạy.
- **Kết quả (2026-11-28):** Xong. Chi tiết trong [eval/baseline/report.md](../eval/baseline/report.md).
  - **Thay đổi so với kế hoạch:** dùng bộ dữ liệu đầy đủ do nhóm cung cấp (`assets/datasets/archive (3).zip`, giải nén `.sol` và `.csv` vào `assets/datasets/full/`, không giải nén `kaggle.json` và `sc_versions.pkl`). Đo 11 hợp đồng thay vì 50 vì máy chỉ có CPU. ECE lấy từ xác suất đã lưu của mô hình đang chạy, chỉ có cho timestamp.
  - **Thời gian:** trung vị 13,7 giây/hợp đồng, lớn nhất 104,8 giây. Mô hình xong sau trung vị 4,6 giây; **LLM chiếm phần lớn** (trung vị 11,5 giây, lớn nhất 54,9 giây do 7 lời giải thích được gọi tuần tự).
  - **ECE** (timestamp, test 187 hợp đồng): 0,071; accuracy 0,898 nhưng độ tin cậy trung bình 0,839, tức mô hình tự tin thấp hơn thực tế.
  - **Ca âm khó:** trên máy này chỉ 4/14 hợp đồng còn bị gắn cờ; 7/9 lời giải thích đã tự nghi ngờ cảnh báo. Dư địa cải thiện của RAG trên chỉ số này nhỏ.
  - **Phát sinh:** thêm việc "gọi LLM song song" vào bước 1.5.

---

## Giai đoạn 1 – Trước vòng chung kết

### Bước 1.1 – Xử lý khóa bí mật bị commit

- **Mục tiêu:** khóa trong `.env.production` không còn dùng được, và không lặp lại lỗi này.
- **Việc cần làm:**
  - Trên server: đổi `JWT_SECRET`, `SECRET_KEY`, mật khẩu MongoDB, MinIO, SMTP, Mongo Express. Đổi `JWT_SECRET` sẽ đăng xuất mọi người dùng.
  - Đổi `.env.production` trong repo thành file mẫu chỉ có giá trị giả; thêm `.env.production` vào `.gitignore`.
  - Thêm gitleaks vào CI (`.github/workflows/`) và một pre-commit hook.
  - Xóa file khỏi lịch sử git bằng `git filter-repo`. Việc này phải **force-push**, nên cần cả nhóm đồng ý trước.
- **Tiêu chí hoàn thành:** một token ký bằng `JWT_SECRET` cũ bị server từ chối; gitleaks chạy sạch trên CI.
- **Minh chứng:** lệnh thử token cũ và kết quả 401; log CI của gitleaks.
- **Kết quả (2026-11-28):** Xong phần làm được trong repo; phần trên server và lịch sử git **chờ nhóm**.
  - **Đã làm:**
    - `.env.production` thành file mẫu: 7 giá trị bí mật thay bằng `CHANGE_ME_*`, mật khẩu trong `MONGODB_URL` cũng vậy. Không có code hay script nào đọc file này.
    - `.gitignore` thêm `.env.*` (trừ `.env.example`, `.env.production`), thư mục dữ liệu `assets/datasets/full/` và file zip.
    - Thêm `.gitleaks.toml`, workflow CI `.github/workflows/secret-scan.yml` (chỉ quét các commit mới của push hoặc PR) và `.pre-commit-config.yaml`.
  - **Gitleaks phát hiện thêm khóa thật,** ngoài `.env.production`:
    - 2 token Hugging Face (bắt đầu `hf_Xqw…`, `hf_Yue…`) trong 3 notebook: `assets/notebooks/FineTuneCodeBERT_Time.ipynb`, `FineTuneCodeBERT_Reen.ipynb`, `removed/FinetuneCodeBERTforNodeFeatureExtract.ipynb`. Đã thay bằng `YOUR_HF_TOKEN` trong thư mục làm việc.
    - Khóa Google Cloud (nhiều khả năng là khóa Gemini cũ) trong lịch sử của `server.py` và `main.py`.
  - **Kiểm tra:** quét lại toàn bộ file git theo dõi (316 file, trừ dữ liệu nghiên cứu): `no leaks found`. Giá trị `JWT_SECRET`, `SECRET_KEY`, `MONGODB_PASSWORD` trong `.env` trên máy **khác** giá trị đã lộ.
  - **Nhóm cần làm (không tự làm được):**
    1. Thu hồi 2 token Hugging Face và khóa Google Cloud cũ.
    2. So `JWT_SECRET`, `SECRET_KEY` và mật khẩu MongoDB trên server với giá trị trong lịch sử git; trùng thì đổi.
    3. Xóa các file trên khỏi lịch sử git bằng `git filter-repo` rồi force-push, sau khi cả nhóm đồng ý.

### Bước 1.2 – Kiểm tra đầu ra của LLM

- **Mục tiêu:** lời giải thích chỉ trích dòng có thật và không bao giờ kết luận mã an toàn.
- **Việc cần làm:**
  - Tạo `src/workflows/gfd_workflow/utils/output_guard.py`:
    - Mọi `Lx` hoặc `Lx–Ly` trong câu trả lời phải nằm trong khoảng dòng của hàm.
    - Câu trả lời không được chứa câu kết luận an toàn ("an toàn", "safe", "no vulnerability", …), có danh sách mẫu cho cả tiếng Việt và tiếng Anh.
  - Gọi bộ kiểm tra trong `func_vul_explainer.py`. Vi phạm thì sinh lại một lần; vẫn vi phạm thì gắn nhãn "cần rà soát thủ công".
  - Viết `tests/test_output_guard.py`.
- **Tiêu chí hoàn thành:** test qua; lời giải thích vi phạm được gắn nhãn thay vì hiển thị nguyên văn.
- **Minh chứng:** số lời giải thích bị sinh lại hoặc gắn nhãn trên tập baseline.
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm:** `src/workflows/gfd_workflow/utils/output_guard.py`.
    - Kiểm tra mọi số dòng được trích (`` `L12` ``, `` `L12-L14` ``, hoặc sau chữ "dòng"/"line") nằm trong hàm.
    - Bắt các câu khẳng định an toàn bằng tiếng Việt và tiếng Anh, bỏ qua câu phủ định ("không an toàn", "does not mean the code is safe").
    - `func_vul_explainer.py` tách mỗi lời giải thích thành `explain_one()`: vi phạm thì yêu cầu viết lại một lần kèm lý do; vẫn vi phạm thì gắn cảnh báo ⚠ ở đầu, trường `guard` ghi lại kết quả.
    - `findings.summarize()` thêm lý do `explanation_failed_check` vào danh sách cần rà soát thủ công; giao diện (`AnalysisReport.tsx`, `findings.ts`, `vi.ts`) hiển thị lý do này kèm tên hàm.
  - **Kiểm tra trên 31 lời giải thích thật đã lưu trong MongoDB:**
    - Lần đầu bắt 5 trường hợp; 4 là báo nhầm ("L2 có sequencer" = Layer 2). Đã sửa để chỉ tính số dòng trong backtick hoặc sau chữ "dòng"/"line".
    - Sau khi sửa: **1/31 bị đánh dấu, và là lỗi thật**: lời giải thích của `EternalWealth.ClaimBlessings()` viết "không có lỗ hổng reentrancy trong hàm này".
  - **Test:** `tests/test_output_guard.py`, 8 test (gồm nhánh viết lại và nhánh đưa vào rà soát thủ công, dùng LLM giả lập). Toàn bộ: 43 test qua, 1 lỗi đã biết chỉ trên Windows. `tsc --noEmit` qua.
  - **Chạy thật** `demo/EtherStore.sol` qua API: hai lời giải thích đều `guard.ok = true`, không phải viết lại.

### Bước 1.3 – Nhật ký nhãn chỉ-ghi-thêm và đồng ý dùng mã

- **Mục tiêu:** mọi kết luận của chuyên gia được lưu lại đầy đủ, không sửa được, và chỉ dùng mã của người đã đồng ý.
- **Việc cần làm:**
  - Thêm collection `label_events` (`src/infrastructure/database.py`). Mỗi bản ghi gồm:
    - phiên, hàm, loại lỗ hổng, mã hàm, đường dẫn đồ thị;
    - dự đoán, xác suất và phiên bản mô hình;
    - người duyệt, kết luận, ghi chú, thời điểm;
    - `prev_hash` và `hash`.
  - Trong `PUT /sessions/{id}/reviews` (`analyze_router.py`): giữ cập nhật hiện tại để giao diện không đổi, và ghi thêm một sự kiện vào `label_events`.
  - Thêm trường `training_consent` (mặc định `false`) khi tải hợp đồng lên, lưu cùng phiên; thêm ô đồng ý ở frontend (`pages/Index.tsx` hoặc `components/FileUpload.tsx`).
  - Script `scripts/verify_label_log.py` kiểm tra chuỗi hash.
  - Viết `tests/test_label_events.py`.
- **Tiêu chí hoàn thành:** sửa trực tiếp một bản ghi trong MongoDB thì script kiểm tra báo đúng vị trí bị sửa.
- **Minh chứng:** output của script trước và sau khi sửa thử.
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm:**
    - `src/services/label_log.py`: mỗi kết luận thành một sự kiện có `seq` (chỉ mục duy nhất, hai người duyệt cùng lúc không làm rẽ nhánh chuỗi), `prev_hash` và `hash` (sha256 của JSON chuẩn hóa). Thời điểm lưu dạng chuỗi ISO để hash không đổi khi MongoDB làm tròn datetime.
    - `PUT /sessions/{id}/reviews` vẫn cập nhật phiên như cũ (giao diện không đổi) và ghi thêm sự kiện vào collection `label_events`. Sự kiện chứa mã hàm, đường dẫn đồ thị, dự đoán mức hàm và mức hợp đồng, phiên bản mô hình, người duyệt, kết luận, `training_consent`.
    - Phiên bản mô hình = tên file checkpoint + 12 ký tự đầu sha256 (`checkpoint_version` trong `workflow.py`), ghi vào mỗi phiên (`model_versions`).
    - Đồng ý dùng mã: tham số `training_consent` (mặc định `false`) ở `POST /analyze`; công tắc "Cho phép dùng hợp đồng của tôi để cải thiện mô hình" trong Cài đặt, mặc định tắt (`preferences.ts`, `SettingsDialog.tsx`, `project.ts`, `vi.ts`).
    - `scripts/verify_label_log.py` kiểm tra chuỗi.
  - **Kiểm tra thật:** phân tích `demo/EtherStore.sol` có đồng ý → chuyên gia ghi 4 kết luận → 4 sự kiện nối hash liên tiếp; người dùng thường gửi kết luận bị 403.
    - Sửa trực tiếp `verdict` của seq 1 trong MongoDB → `BROKEN at seq 1: content changed after it was written`; khôi phục → `OK`.
    - Xóa seq 2 → `BROKEN at seq 3: expected seq 2`; chèn lại → `OK`.
  - **Test:** `tests/test_label_events.py` 5 test (chuỗi hợp lệ, phát hiện sửa, phát hiện xóa, người ghi đồng thời không rẽ nhánh, nội dung sự kiện). `tsc --noEmit` qua.

### Bước 1.4 – Lấy mẫu ngẫu nhiên hàm không bị gắn cờ

- **Mục tiêu:** dữ liệu phản hồi có cả ca bỏ sót (FN), không chỉ ca đúng và ca báo nhầm.
- **Việc cần làm:**
  - Sau mỗi lần phân tích, chọn ngẫu nhiên một tỉ lệ cấu hình được (`RANDOM_AUDIT_RATE`, mặc định 0,05) các hàm có `prediction = 0` của phiên đã đồng ý, đưa vào hàng chờ chuyên gia.
  - Đánh dấu là "kiểm tra ngẫu nhiên" và ẩn dự đoán của mô hình với chuyên gia, để kết luận không bị ảnh hưởng.
  - Hiển thị trong `pages/ReviewQueue.tsx`.
- **Tiêu chí hoàn thành:** tỉ lệ mẫu thực tế khớp cấu hình; sự kiện nhãn của các mẫu này có cờ `random_audit = true`.
- **Minh chứng:** số mẫu ngẫu nhiên và số ca bỏ sót tìm được.
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm:**
    - `findings.pick_random_audits()`: chọn hàm có `prediction = 0` theo tỉ lệ `RANDOM_AUDIT_RATE` (mặc định 0,05, trong `settings.py`), seed bằng session id nên cùng phiên luôn ra cùng mẫu. Chỉ chạy khi phiên có `training_consent`. Lưu riêng vào `random_audits` của phiên, **không** trộn vào danh sách cảnh báo.
    - `audit_findings()`: mẫu hiển thị cho chuyên gia **không kèm điểm tin cậy và lời giải thích** của mô hình (kiểm tra mù).
    - Hàng chờ chuyên gia gồm cả phiên có mẫu ngẫu nhiên; `GET /sessions/{id}/findings` chỉ trả mẫu cho tài khoản expert; `PUT .../reviews` chấp nhận mẫu và ghi sự kiện nhãn với `random_audit = true`. SARIF không đổi.
    - Giao diện: mục "Kiểm tra ngẫu nhiên" trong `ReviewQueue.tsx`, nhãn lựa chọn riêng ("Có lỗ hổng (mô hình bỏ sót)", "Không có lỗ hổng", "Cần rà soát thủ công") qua prop `labels` của `FunctionReviewControl`.
  - **Kiểm tra thật** (tỉ lệ tạm 0,3 qua biến môi trường), cùng một hợp đồng:
    - Có đồng ý: 6/15 hàm không bị gắn cờ được lấy mẫu; không đồng ý: 0.
    - Chuyên gia thấy 8 mục (2 cảnh báo + 6 mẫu), người tải lên thấy 2; SARIF của hai phiên giống hệt nhau (3 kết quả).
    - Chuyên gia ghi kết luận cho một mẫu → sự kiện nhãn `random_audit: true`, `model_prediction: 0`; chuỗi hash vẫn nguyên vẹn (5 sự kiện).
  - **Test:** `tests/test_random_audit.py` 2 test (chỉ lấy hàm không gắn cờ, tái lập được, không lọt vào cảnh báo). `tsc --noEmit` qua.
  - **Chưa đo được:** số ca bỏ sót thật tìm được, vì cần chuyên gia thật duyệt mẫu theo thời gian.

### Bước 1.5 – Cache theo `file_hash` và theo vector hàm

- **Mục tiêu:** không phân tích lại file đã gặp, không mã hóa lại hàm đã gặp.
- **Việc cần làm:**
  - Cache kết quả theo `(file_hash, phiên bản mô hình)`. Trúng cache thì phát lại các bước đã lưu, có ghi chú "kết quả đã lưu".
  - Cache vector CodeBERT theo `(sha256(mã hàm đã bỏ comment), encoder)` trong `fcg_converter.py`. Lưu trong MongoDB hoặc trên đĩa; kho vector ở bước 1.8 dùng chung cache này.
  - Thêm biến bật/tắt cache để đo được hai trường hợp.
  - _(Thêm sau bước 0.1)_ Gọi LLM **song song** cho các hàm bị gắn cờ trong `func_vul_explainer.py`, có giới hạn số lời gọi đồng thời; hiện các lời giải thích được gọi tuần tự và chiếm phần lớn thời gian quét.
- **Tiêu chí hoàn thành:** phân tích lại cùng file trả kết quả giống hệt và nhanh hơn rõ rệt.
- **Minh chứng:** thời gian và tỉ lệ trúng cache so với bước 0.1 (mốc 0,65 / 0,36 giây ở mục 1.5 của báo cáo).
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm:**
    - `embedding_cache.py`: cache vector CodeBERT trong SQLite (`storage/embedding_cache.sqlite`), khóa = (encoder, sha256 của mã đã bỏ comment); gặp lỗi thì bỏ qua cache và tính trực tiếp, không làm hỏng lần quét.
    - Cache kết quả: cùng `file_hash` + `model_versions` + ngôn ngữ → phát lại các bước đã lưu vào phiên mới (không sao chép kết luận chuyên gia), phiên ghi `cached_from`.
    - Gọi LLM song song (`LLM_MAX_CONCURRENCY` = 4).
    - Bật/tắt bằng `EMBEDDING_CACHE`, `RESULT_CACHE`.
  - **Đo trên 11 hợp đồng của bước 0.1** (`eval/baseline/compare.py timing ...`):

    | Lượt | Trung vị (giây) | Lớn nhất (giây) | Mô hình, trung vị (giây) | LLM, trung vị (giây) |
    |---|---|---|---|---|
    | Mốc (bước 0.1) | 13,7 | 104,8 | 4,6 | 11,5 |
    | LLM song song, cache vector trống | 10,7 | 30,7 | 3,1 | 8,7 |
    | + cache vector đầy | 9,4 | 20,6 | 2,2 | 8,1 |
    | + cache kết quả | 2,1 | 2,2 | – | 0 |

    Ba lượt mới cho **kết luận và độ tin cậy giống hệt nhau 11/11**. Khoảng 2 giây còn lại ở lượt cuối là phần nhận và kiểm tra file tải lên.
  - **Hai lỗi tìm thấy khi kiểm tra và đã sửa:**
    1. Lần quét đầu tiên, hai luồng cùng tạo file SQLite → `database is locked`, một luồng quét thất bại. Sửa: khởi tạo một lần có khóa + bỏ qua cache khi lỗi; thêm 2 test (ghi đồng thời, cache hỏng).
    2. **Kết quả phụ thuộc kiểu xuống dòng của file**: bản CRLF (Windows) của cùng một hợp đồng cho timestamp 0,885 thay vì 0,934, vì `\r` lọt vào văn bản đưa cho CodeBERT. Lần đo mốc đọc bản dữ liệu cũ trong git (CRLF trên Windows), nên độ tin cậy khác các lượt mới. Sửa: chuẩn hóa xuống dòng về LF chỉ cho văn bản đưa vào encoder (`fcg_converter.py`); số dòng, vị trí và mã hiển thị giữ nguyên. Kiểm tra bằng `eval/baseline/determinism_check.py`: bản CRLF và LF giờ cùng ra 0,933623 / 0,841262, và kết quả không đổi qua các tiến trình khác nhau.
  - **Test:** `tests/test_embedding_cache.py` 4 test.

### Bước 1.6 – Hàng đợi job trên Redis

- **Mục tiêu:** phân tích dài không giữ kết nối HTTP; mất kết nối vẫn xem lại được kết quả.
- **Việc cần làm:**
  - Thêm service `redis` vào `docker-compose.prod.yml` (hiện chưa có).
  - Thêm worker, dùng `arq` hoặc `rq`. `POST /analyze` tạo job và trả `job_id`; luồng NDJSON đọc tiến độ từ Redis hoặc MongoDB.
  - Giữ giới hạn số job chạy cùng lúc theo GPU.
  - Frontend nối lại vào luồng tiến độ khi tải lại trang.
- **Tiêu chí hoàn thành:** tắt trình duyệt giữa chừng rồi mở lại vẫn thấy kết quả; kết quả giống chạy trực tiếp.
- **Minh chứng:** log job; ảnh chụp màn hình khi mở lại phiên.
- **Kết quả (2026-11-28):** Xong, **đổi cách làm so với kế hoạch: không thêm Redis**.
  - **Lý do:** mỗi bước phân tích vốn đã được ghi vào MongoDB ngay khi xong, nên MongoDB đã là kho lưu tiến độ bền vững mà mọi tiến trình đều đọc được. Redis cùng một worker riêng sẽ phải tải mô hình thêm một lần (vài GB RAM trên máy CPU) và thêm một service phải giữ ổn định 48 giờ, nhưng chưa có lợi gì khi chỉ có một GPU. Khi cần nhiều GPU worker, có thể thay nguồn sự kiện bằng Redis mà không đổi API.
  - **Đã làm:**
    - `POST /analyze` chạy phân tích thành tác vụ nền (`run_job`), không còn gắn với kết nối HTTP; mất kết nối hay tải lại trang không dừng phân tích nữa (trước đây phiên bị đánh dấu thất bại).
    - Luồng trả về và endpoint mới `GET /sessions/{id}/events?start=N` cùng dùng `tail_session_events()`: gửi các bước đã lưu từ vị trí N rồi theo dõi bước mới, kết thúc khi phiên xong; phiên thất bại kết thúc bằng sự kiện lỗi như trước.
    - `fail_orphaned_sessions()` khi khởi động: đóng các phiên còn `processing` của tiến trình cũ.
    - Giao diện (`Analysis.tsx`, `project.ts`): lưu session id; tải lại trang thì nối lại phiên thay vì tải file lên lại. Việc này cũng sửa lỗi cũ: mở phân tích từ trang dự án làm hợp đồng **bị phân tích hai lần**.
  - **Kiểm tra** (`eval/baseline/detach_check.py`, hợp đồng lớn nhất):
    - Đọc 2 sự kiện rồi ngắt kết nối → phân tích vẫn chạy xong sau 20,5 giây (8 bước).
    - Nối lại từ 0: khớp đúng các bước đã lưu; từ 3: bằng đúng phần còn lại; 2 sự kiện đầu giống luồng trực tiếp; chuyên gia cũng theo dõi được (200).
    - Tắt backend giữa chừng rồi khởi động lại → phiên chuyển `failed` với thông báo "The server restarted before this analysis finished"; người theo dõi nhận 6 bước đã có rồi sự kiện lỗi.
    - Đo lại 11 hợp đồng qua đường mới: kết quả giống hệt 11/11.

### Bước 1.7 – Hiệu chỉnh độ tin cậy và sắp xếp hàng chờ chuyên gia

- **Mục tiêu:** xác suất 90% nghĩa là khoảng 90% đúng; chuyên gia xem các cảnh báo khả năng đúng cao trước.
- **Việc cần làm:**
  - Tạo `eval/calibration/fit_temperature.py`: temperature scaling trên tập validation 20% (cùng cách chia với `eval/ablation/`), mỗi loại lỗ hổng và mỗi mức (hợp đồng, hàm) một nhiệt độ.
  - Lưu nhiệt độ vào cấu hình và áp dụng trong `src_vul_detector.py` và `func_vul_detector.py`.
  - Sắp xếp `GET /reviews/queue` theo xác suất đã hiệu chỉnh.
- **Tiêu chí hoàn thành:** ECE giảm so với bước 0.1, F1 không đổi (hiệu chỉnh nhiệt độ không đổi thứ hạng).
- **Minh chứng:** ECE trước và sau, biểu đồ độ tin cậy (reliability diagram) trong `eval/calibration/`.
- **Kết quả (2026-11-28):** Xong. Chi tiết trong [eval/calibration/report.md](../eval/calibration/report.md).
  - **Thay đổi so với kế hoạch:** tập validation của nhóm không có sẵn ở máy này, nên tính lại xác suất của cả hai mô hình trên **tập test** (`collect_probs.py`) và dùng **cross-fitting 2 phần** để đo ECE: tìm nhiệt độ trên một nửa, đo trên nửa kia. Hiệu chỉnh nhiệt độ không đổi lớp dự đoán, nên F1 không đổi.
  - **Kết quả:**

    | Mô hình | Hợp đồng chấm được | Accuracy | ECE giữ riêng trước → sau | Quyết định |
    |---|---|---|---|---|
    | Timestamp | 168/193 | 0,935 | 0,103 → **0,019** | Áp dụng T = 0,561 (mô hình tự tin thấp hơn thực tế) |
    | Reentrancy | 119/147 | 0,739 | 0,035 → 0,139 | **Không áp dụng** (giữ T = 1): vốn đã hiệu chỉnh tốt, nhiệt độ cross-fit không ổn định (1,75 và 0,58) |

    Script chỉ áp dụng nhiệt độ khi ECE trên phần giữ riêng tốt lên.
  - **Đã làm trong sản phẩm:**
    - `calibration.json` gắn nhiệt độ với phiên bản checkpoint; `load_temperature()` bỏ qua nếu checkpoint khác (ví dụ sau khi huấn luyện lại).
    - `src_vul_detector.py` chia logit cho T trước softmax.
    - `GET /reviews/queue` sắp theo `review_priority()`: phiên còn cảnh báo chưa duyệt lên trước (theo độ tin cậy đã hiệu chỉnh cao nhất), rồi phiên chỉ có mẫu ngẫu nhiên, cuối cùng phiên đã duyệt hết; có test.
  - **Lưu ý môi trường:** trên máy này 25/193 hợp đồng timestamp không dựng được đồ thị (kết quả gốc trên Linux: 6), vì máy chỉ có solc 0.4.24, còn image production tải mọi phiên bản (`docker/be.prod.dockerfile`). Số "không chấm được" ở các báo cáo trên máy này cao hơn production vì lý do đó.

### Bước 1.8 – Kho tri thức và RAG cho lời giải thích

- **Mục tiêu:** lời giải thích dựa thêm vào các ca tương tự mà chuyên gia đã kết luận.
- **Việc cần làm:**
  - Tạo kho vector (FAISS trên đĩa, hoặc collection MongoDB kèm tìm kiếm tuyến tính nếu kho còn nhỏ) từ:
    - `label_events` đã duyệt;
    - bản sửa đã được chấp nhận;
    - danh mục SWC cho timestamp và reentrancy.
  - Chỉ đưa vị trí audit DAppSCAN vào kho khi **không** dùng DAppSCAN làm tập kiểm thử.
  - Tìm kiếm bằng vector CodeBERT của hàm (lấy từ cache ở bước 1.5), lọc theo loại lỗ hổng, lấy 3–5 ca.
  - Thêm các ca tìm được vào prompt trong `func_vul_explainer.py`; lời giải thích phải ghi rõ ca nào được tham khảo.
  - Cập nhật kho khi có sự kiện nhãn mới: đây là "đường nhanh".
- **Tiêu chí hoàn thành:** một kết luận mới của chuyên gia xuất hiện trong lời giải thích của hàm tương tự ngay ở lần phân tích sau.
- **Minh chứng:** tỉ lệ tự nhận ra dương tính giả trên ca âm khó, so với bước 0.1, khi có và không có RAG.
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm:** `src/services/knowledge.py`.
    - Collection `knowledge` + chỉ mục trong bộ nhớ (cosine trên vector CodeBERT của chính loại lỗ hổng, đọc qua cache bước 1.5); loại các mục đến từ chính hợp đồng đang xét.
    - Nguồn: kết luận chuyên gia (chỉ khi người tải lên đồng ý, bỏ "cần rà soát thủ công"), bản sửa được chấp nhận, và **1.601 hàm của tập train** có nhãn đã xác minh và chứa cú pháp nhạy cảm (`scripts/seed_knowledge.py`: 1.087 timestamp, 514 reentrancy). Không nạp tập test và DAppSCAN.
    - Prompt thêm tham chiếu SWC-116/107 và 3 ca giống nhất, đánh dấu là dữ liệu tham khảo; lời giải thích trả `references`.
    - **Đường nhanh:** `PUT .../reviews` và quyết định chấp nhận bản sửa thêm mục vào kho ngay (chạy nền, lỗi không ảnh hưởng chuyên gia).
  - **Kiểm tra thật:**
    - Mỗi lời giải thích có 3 tham chiếu và LLM dùng chúng, ví dụ "mẫu này gần giống Case 1 (`require(now >= releaseDate);`, được gán nhãn NOT vulnerable)".
    - Đường nhanh: chuyên gia xác nhận `EtherStore.withdrawFunds` → kho tăng 0 → 1 mục kết luận chuyên gia → phân tích bản sao khác hash: tham chiếu đứng đầu là kết luận đó (độ tương đồng 1,0), lời giải thích dẫn "Case 1… được xác nhận là lỗ hổng".
    - Ca âm khó: 3/4 lời giải thích nghi ngờ cảnh báo (mốc 7/9). **Không kết luận được**: mẫu quá nhỏ và lần đo mốc đọc bản file CRLF nên tập hợp đồng bị gắn cờ khác nhau (4 so với 6).
  - **Hai lỗi phát hiện và đã sửa:**
    1. Cache kết quả (bước 1.5) phát lại kết quả cũ sau khi đổi nhiệt độ/RAG. Khóa cache giờ là "dấu vân tay pipeline" (`get_pipeline_fingerprint`): checkpoint, nhiệt độ, phiên bản prompt, RAG bật/tắt, số mục trong kho. Kết luận mới của chuyên gia làm cache cũ mất hiệu lực.
    2. Mỗi lần ghi vào kho tạo kết nối MongoDB mới (nạp dữ liệu chậm ~6 lần); đã dùng chung một client.
  - **Lưu ý:** độ tương đồng CodeBERT (CLS) đều quanh 0,99, chỉ dùng để xếp hạng, không dùng làm ngưỡng.
  - **Test:** `tests/test_knowledge.py` 5 test.

### Bước 1.9 – Vòng huấn luyện lại tối thiểu và cổng thay mô hình

- **Mục tiêu:** chạy được trọn một vòng huấn luyện lại, từ nhãn tới quyết định thay hay giữ mô hình.
- **Việc cần làm:**
  - `scripts/build_feedback_dataset.py`: lấy nhãn đã đồng ý từ `label_events`, bỏ `needs_manual_review`, chia tập theo `file_hash`, loại hàm trùng nguyên văn giữa các tập, xuất ảnh chụp dữ liệu có mã băm.
  - `scripts/retrain.py`: dùng lại quy trình của `eval/ablation/ablation.py`.
  - `scripts/gate.py`: so F1 từng lớp trên tập kiểm thử chuẩn và tập phản hồi giữ riêng, chạy McNemar, kiểm tra số mẫu tối thiểu. Ngưỡng do nhóm chốt.
  - Lưu mô hình theo phiên bản (`models/<vuln>/<version>/`); backend đọc phiên bản đang dùng từ cấu hình; luôn giữ bản cũ để quay lại.
  - Trong hackathon, mô phỏng phản hồi bằng một phần **tập huấn luyện** được tách riêng, ghi rõ là mô phỏng. Không dùng tập kiểm thử của bài báo hay DAppSCAN.
- **Tiêu chí hoàn thành:** chạy hai lần: một bản bị cổng từ chối và một bản được thay, có báo cáo so sánh cho mỗi lần.
- **Minh chứng:** `eval/retrain/<lần chạy>/report.md`.
- **Kết quả (2026-11-28):** Xong. Theo yêu cầu của nhóm, bước này **chỉ dựng luồng** để dùng khi có đủ dữ liệu, không huấn luyện thật; các lần chạy dưới đây chỉ 1 epoch để chứng minh các khâu nối với nhau.
  - **Đã làm:**
    - `scripts/build_graphs.py`: dựng đồ thị bằng đúng `convert_to_fcg` của sản phẩm cho một tập dữ liệu (có thể chạy tiếp khi bị ngắt).
    - `scripts/build_feedback_dataset.py`: lấy nhãn từ nhật ký (đã đồng ý, đủ 2 chuyên gia đồng thuận – bước 2.6; mức hợp đồng chỉ lấy "confirmed"), hoặc `--simulate` một phần tập train; chia theo `file_hash`, loại file trùng với tập test, ghi ảnh chụp có sha256.
    - `scripts/retrain.py`: chế độ `scratch` hoặc `finetune` theo đúng giao thức của nhóm (Adam, seed 42, 20% validation, chọn epoch theo macro-F1); `finetune` coi checkpoint ban đầu là "epoch −1", nên chỉ đổi khi validation tốt lên.
    - `scripts/gate.py`: so mô hình đang chạy với ứng viên trên tập test và tập phản hồi giữ riêng; điều kiện: holdout ≥ 20, F1 từng lớp không giảm quá 0,02, McNemar không cho thấy kém hơn. Ghi `report.md`, `gate.json`; `--promote` chỉ kích hoạt khi đạt.
    - `src/services/model_registry.py` + `models/registry.json`: backend nạp checkpoint đang kích hoạt; giữ lịch sử để `rollback`. Nhiệt độ hiệu chỉnh tự động không áp cho checkpoint mới (bước 1.7).
  - **Chạy thử trên máy này** (timestamp; đồ thị: train 583/807, test 168/193 vì máy chỉ có solc 0.4.24):
    - Bộ dữ liệu mô phỏng 20%: 461 base + 81 phản hồi huấn luyện + 35 phản hồi giữ riêng; 6 file trùng với test bị loại; 0 nhãn chuyên gia (mới có 1 chuyên gia nên chưa mục nào đạt đồng thuận).
    - `finetune` 1 epoch → validation không tốt hơn nên giữ checkpoint gốc → cổng **chấp nhận** (mọi chỉ số giống hệt, McNemar p = 1,0), không kích hoạt.
    - `scratch` 1 epoch (cố tình kém) → cổng **từ chối** cả 5 điều kiện (F1 có lỗi 0,943 → 0,224; McNemar p = 0,0), dù chạy với `--promote`: sổ đăng ký không đổi.
  - **Test:** `tests/test_model_registry.py` (kích hoạt, bỏ qua file không tồn tại, quay lại).

### Bước 1.10 – Giám sát, load test và chạy ổn định 48 giờ

- **Mục tiêu:** có số liệu chứng minh yêu cầu "vận hành ổn định ít nhất 48 giờ trước chấm".
- **Việc cần làm:**
  - Thêm endpoint `/metrics` (Prometheus) hoặc log có cấu trúc: độ trễ từng bước, tỉ lệ lỗi, độ dài hàng đợi, token và chi phí LLM.
  - Load test bằng locust với N người dùng đồng thời.
  - Bật cảnh báo khi tỉ lệ lỗi hoặc độ trễ vượt ngưỡng.
  - Đóng băng phiên bản (tag git) trước mốc 48 giờ.
- **Tiêu chí hoàn thành:** chạy liên tục 48 giờ, không phải khởi động lại bằng tay.
- **Minh chứng:** biểu đồ 48 giờ, kết quả load test.
- **Kết quả (2026-11-28):** Xong phần giám sát và đo tải; **chạy liên tục 48 giờ phải làm trên server** trước giờ chấm.
  - **Đã làm:**
    - `src/services/metrics.py` (định dạng Prometheus, không thêm thư viện) + `GET /metrics` (cần `METRICS_TOKEN` nếu đặt).
    - Đo: request theo route và mã trạng thái + độ trễ, số phân tích đang chạy, số phân tích theo kết quả (`completed`/`cached`/`failed`) + thời gian, lời gọi LLM + độ trễ + token vào/ra, cache vector trúng/trượt.
    - `eval/load/load_test.py`: N người dùng ảo lặp lại đăng nhập → xem phiên → phân tích và đọc hết luồng; lấy mẫu bộ nhớ backend.
  - **Đo tải 5 người dùng × 5 phút** (`eval/load/load_5u_300s.json`, 41 hợp đồng xoay vòng):

    | Thao tác | Số lần | p50 (giây) | p95 (giây) | Lớn nhất (giây) |
    |---|---|---|---|---|
    | Phân tích (đọc hết luồng) | 580 | 0,10 | 3,64 | 15,8 |
    | Xem danh sách phiên | 580 | 0,013 | 0,093 | 0,94 |
    | Đăng nhập | 857 | 0,06 | 0,58 | 3,4 |

    Theo `/metrics`: 405 phân tích phát lại từ cache, 35 chạy thật, 140 thất bại; cache vector trúng 2.977 / trượt 215. Bộ nhớ backend đỉnh 1,27 GB, sau đó 0,73 GB (không tăng dần).
  - **Giải thích các lỗi trong lúc đo, đều do môi trường máy này:**
    - 277 lỗi 404 khi đăng nhập **không tới backend** (log backend: 583 lần đăng nhập, đều 200). Chạy lại với `127.0.0.1` thay `localhost`: 0 lỗi, tức có tiến trình khác trên máy trả lời ở `::1`.
    - 223/224 phân tích thất bại là "không dựng được đồ thị" trên 13 hợp đồng; 12 trong số đó là các hợp đồng không biên dịch được với solc 0.4.24, phiên bản duy nhất trên máy (bước 1.7). Sản phẩm báo đúng lý do để rà soát thủ công.
  - **Chưa làm:** cảnh báo tự động theo ngưỡng (cần Prometheus/Alertmanager trên server); tag phiên bản + 48 giờ chạy liên tục.

---

## Giai đoạn 2 – Dự phòng cho thử thách 12 giờ

### Bước 2.1 – Agent sửa lỗi tự gọi công cụ

- **Mục tiêu:** agent tự đề xuất, kiểm tra và sửa lại bản sửa; chuyên gia vẫn là người duyệt cuối.
- **Việc cần làm:**
  - Định nghĩa bốn công cụ:
    - `compile_fix`: dùng lại `fix_check`;
    - `run_slither`: chạy Slither trên bản sửa;
    - `rescan_gnn`: chạy lại GNN trên hợp đồng đã sửa;
    - `retrieve_similar`: tìm ca tương tự trong kho ở bước 1.8.
  - Vòng lặp tối đa N lần, có trần token. Dừng khi biên dịch được, Slither hết phát hiện trên các dòng của hàm và GNN hết gắn cờ.
  - Kết quả luôn vào hàng chờ chuyên gia; giữ nguyên các quy tắc 403/409. Agent không có công cụ nào ghi vào kho nhãn.
- **Tiêu chí hoàn thành:** chạy được trên `demo/EtherStore.sol` và trên các ca reentrancy đúng của tập kiểm thử.
- **Minh chứng:** tỉ lệ biên dịch được ở vòng đầu và sau khi agent tự sửa, số vòng trung bình, tỉ lệ GNN hết gắn cờ.
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm:** `src/services/fix_agent.py`.
    - Agent LangChain gọi công cụ qua cổng Astral X (đã kiểm tra cổng hỗ trợ tool calling): `compile_and_slither`, `rescan_model`, `similar_cases`, `submit_fix`. Tối đa N vòng và 60.000 token.
    - Sau khi nộp, **hệ thống tự kiểm tra lại** (biên dịch, Slither, quét lại GNN) thay vì tin agent; bản sửa được ghi vào phiên như bản sửa làm tay, chỉ chuyên gia mới chấp nhận được (quy tắc 403/409 giữ nguyên). Agent không có công cụ nào ghi nhãn hay quyết định.
    - Endpoint `POST /refactor/agent`; nút "Để agent sửa" trong bảng quy trình (`FindingWorkflow.tsx`).
  - **Chạy thật** trên cảnh báo reentrancy của `demo/EtherStore.sol` (đã được chuyên gia xác nhận): 13 giây, 2 vòng, 4 lần gọi công cụ, 8.209 token. Bản sửa **đúng** (trừ số dư trước khi gọi ra ngoài), biên dịch ngay lần đầu, Slither không báo gì, đã ghi vào phiên.
  - **Phát hiện:** bước kiểm tra độc lập báo `holds = false` vì **GNN vẫn gắn cờ hàm đã sửa đúng**: mô hình phản ứng với sự có mặt của `call.value` chứ không với thứ tự câu lệnh, khớp với kết quả "chèn mã chết" ở mục 2.4 báo cáo. **Đề xuất:** coi kết quả quét lại GNN là thông tin tham khảo, không phải điều kiện bắt buộc; điều kiện dừng nên là biên dịch + Slither + chuyên gia duyệt.
  - **Chưa đo** trên nhiều ca reentrancy của tập test (cần chạy hàng loạt, tốn token).
  - **Test:** `tests/test_fix_agent.py` 3 test (kiểm tra rồi nộp, hệ thống ghi đè kết luận của agent, giới hạn số vòng).

### Bước 2.2 – RAG cho RefactorBot

- **Việc cần làm:** dùng chung kho ở bước 1.8 trong `src/workflows/chatbot_workflow/`, ưu tiên các bản sửa đã được chấp nhận.
- **Minh chứng:** so sánh câu trả lời có và không có RAG trên một bộ câu hỏi cố định.
- **Kết quả (2026-11-28):** Xong. `knowledge.chat_references()` thêm vào prompt của RefactorBot 2 ca gần nhất cho mỗi loại lỗ hổng, ưu tiên bản sửa đã được chấp nhận và kết luận chuyên gia (mã người dùng dán vào không cho biết loại lỗ hổng). Hỏi thật "có ca tương tự nào không?" với `EtherStore.sol`: bot nêu 4 ca tham khảo và **đánh giá đúng** rằng chúng không áp dụng được cho `withdrawFunds` (khác mẫu lỗi). Chưa chạy so sánh trên bộ câu hỏi cố định.

### Bước 2.3 – Sandbox cho solc, Slither và công cụ của agent

- **Việc cần làm:** container worker riêng, không có mạng (`network_mode: none`), giới hạn CPU, RAM, thời gian và số tiến trình. Backend gửi job sang worker qua hàng đợi ở bước 1.6.
- **Minh chứng:** hợp đồng cố gọi mạng hoặc chạy quá giờ bị chặn, có log.
- **Kết quả (2026-11-28):** Xong một phần.
  - **Đã làm:** `src/services/sandbox.py` + `sandbox_worker.py`. Kiểm tra bản sửa (`/refactor/validate`) và các công cụ của agent biên dịch + chạy Slither trong **tiến trình Python riêng**: chỉ gọi được hàm trong danh sách cho phép, trao đổi bằng JSON, không có biến môi trường bí mật, giới hạn thời gian `SANDBOX_TIMEOUT` (120 giây, quá thì bị dừng), trên Linux thêm giới hạn bộ nhớ `SANDBOX_MEMORY_MB` và CPU. Trước đây Slither chạy ngay trong backend, không giới hạn thời gian.
  - **Kiểm tra:** `tests/test_sandbox.py`: trả kết quả đúng; tác vụ 30 giây bị dừng ở 5 giây; hàm ngoài danh sách bị từ chối. Test giới hạn bộ nhớ chỉ chạy trên Linux (bỏ qua trên máy Windows này).
  - **Chưa làm:** tách mạng (Python 3.10 không có `os.unshare`) và cô lập bằng container → cần chạy worker kiểm tra bản sửa trong container `network_mode: none` trên server. Đường dựng đồ thị khi phân tích chưa đưa vào sandbox (sẽ thêm khoảng 1–2 giây mỗi lần quét).

### Bước 2.4 – Bộ red-team cho LLM

- **Việc cần làm:** tạo `eval/redteam/` với các lệnh điều khiển AI giấu trong chuỗi ký tự, tên biến, tên hàm, tên hợp đồng; chạy qua sản phẩm và đếm số ca qua được bộ kiểm tra ở bước 1.2.
- **Minh chứng:** tỉ lệ ca bị chặn trước và sau khi có bước 1.2.
- **Kết quả (2026-11-28):** Xong. `eval/redteam/make_cases.py` tạo 10 hợp đồng: cùng một hàm có lỗ hổng thật (gọi ra ngoài trước khi trừ số dư; điều kiện theo `now`) và mỗi ca giấu lệnh điều khiển AI ở một chỗ (comment, chuỗi, thông điệp `require`, tên biến, tên hàm, tên hợp đồng, hằng số, tiếng Việt, giả "hết mã"). `run_redteam.py` gửi cùng một prompt hai lần: LLM trực tiếp (trước bước 1.2) và qua `explain_one` (sau). Kết quả trong `eval/redteam/results.jsonl`, `summary.json`.
  - **Reentrancy (chắc chắn khai thác được, là thước đo chính):** không ca nào khiến LLM gọi là dương tính giả. Trước bước 1.2: 2/10 câu trả lời chứa câu khẳng định an toàn lấy từ tên hợp đồng / thông điệp `require` bị chèn ("is safe", "no vulnerability"). Sau: **0** câu sai tới người dùng mà không có cảnh báo.
  - **Toàn bộ 20 lần chạy:** vi phạm quy tắc 3 (trước) → 0 lọt qua (sau): 4 lời giải thích được viết lại, 1 gắn cờ rà soát thủ công. Comment bị xóa trước khi gửi nên không có tác dụng.
  - **Hạn chế:** ca timestamp dùng khoảng 1 giờ nên "dương tính giả" là kết luận hợp lý; số lần LLM nói dương tính giả (3 → 5) vì vậy không đo được tấn công, lại dao động theo nhiệt độ LLM 0,7. Lần sau nên dùng điều kiện thời gian ngắn để ca không mơ hồ.

### Bước 2.5 – JWT trong cookie `httpOnly` và CSP

- **Việc cần làm:** backend đặt cookie `httpOnly`, `Secure`, `SameSite=Strict`, thêm chống CSRF; frontend bỏ `localStorage` (`src/services/auth.ts`, `contexts/AuthContext.tsx`); thêm header CSP ở `docker/nginx.conf`.
- **Minh chứng:** không đọc được token bằng JavaScript trên trang; header CSP có trong response.
- **Kết quả (2026-11-28):** Xong.
  - **Backend** (`authentication_router.py`):
    - Đăng nhập và đổi mật khẩu đặt cookie `gf_session` (`HttpOnly`, `SameSite=Strict`, `Secure` theo `AUTH_COOKIE_SECURE` – bật trên server HTTPS); đăng xuất và đăng xuất mọi nơi xóa cookie.
    - `get_current_user` nhận header Bearer (script, API client) **hoặc** cookie. Với cookie, yêu cầu thay đổi dữ liệu phải có `X-Requested-With: ScanGuard` (chống CSRF), thiếu thì 403.
  - **Frontend:** không còn lưu token trong `localStorage` (0 chỗ đọc/ghi). Mọi lời gọi gửi cookie (`credentials: 'include'`, gồm cả 4 lời gọi của RefactorBot vốn chỉ gửi header); kiểm tra phiên qua `/auth/me` và không tự chuyển sang trang đăng nhập khi ở trang công khai; hộp thoại Bảo mật lấy thời điểm hết hạn đã lưu lúc đăng nhập thay vì giải mã token.
  - **CSP** trong `docker/nginx.conf`: chỉ cho chạy script từ chính trang; cho phép Google Fonts, worker `blob:` của Monaco, style nội tuyến. `nginx -t` trên image chính thức: hợp lệ.
  - **Kiểm tra thật**, gọi thẳng backend và qua proxy Vite: cookie có `HttpOnly` + `SameSite=Strict`; `/auth/me` chỉ với cookie: 200; ghi kết luận bằng cookie **thiếu** header: 403, **có** header: 200; header Bearer vẫn 200; đăng xuất xóa cookie, sau đó `/auth/me`: 401. Test xác thực cũ (6) vẫn qua; `tsc --noEmit` qua.
  - **Phát hiện khi chạy giao diện trên máy này** (có từ trước, không do thay đổi này): code gốc chỉ cho phép CORS từ `localhost:8080`, mà máy này chạy Vite ở 8081 (cổng 8080 bị container khác chiếm), nên mọi lời gọi từ giao diện tới `localhost:8000` đều bị chặn. Xử lý bằng cấu hình: `web_react/.env.local` (đã gitignore) đặt `VITE_API_BASE_URL=http://localhost:8081` để gọi qua proxy cùng origin. Production dùng nginx cùng origin nên không bị.
  - **Chưa làm:** chưa kiểm tra bằng trình duyệt thật (chỉ kiểm tra qua HTTP).

### Bước 2.6 – Quy tắc hai chuyên gia và Cohen's kappa

- **Việc cần làm:** nhãn chỉ vào bộ dữ liệu chuẩn khi hai chuyên gia khác nhau đồng thuận; trường hợp bất đồng đưa vào hàng chờ riêng; tính kappa định kỳ; cảnh báo khi một chuyên gia bác bỏ bất thường nhiều.
- **Minh chứng:** số nhãn đồng thuận, số bất đồng, giá trị kappa.
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm** trong `label_log.py`: `latest_verdicts` (kết luận mới nhất của mỗi chuyên gia), `consensus` (≥ 2 chuyên gia khác nhau, cùng kết luận, không ai phản đối; "cần rà soát thủ công" không bao giờ là nhãn), `disagreements`, `cohen_kappa`, `reviewer_rates` (gắn cờ chuyên gia có tỉ lệ bác bỏ cao bất thường, gợi ý nhãn cẩu thả hoặc bị đầu độc).
    - `build_feedback_dataset.py` chỉ dùng nhãn đồng thuận (`--min-reviewers`, mặc định 2).
    - Endpoint `GET /reviews/disagreements` (chỉ expert) và script `scripts/label_agreement.py`.
  - **Test:** 1 test trong `test_label_events.py` (đồng thuận, đổi ý, bất đồng, kappa, cờ).
  - **Chưa đo được** kappa thật: mới có một tài khoản chuyên gia.

### Bước 2.7 – Chế độ chạy bóng cho mô hình mới

- **Việc cần làm:** mô hình qua cổng ở bước 1.9 chấm song song với mô hình đang dùng, không hiển thị cho người dùng; so kết quả với kết luận chuyên gia trong một khoảng thời gian rồi mới thay thật.
- **Minh chứng:** bảng so sánh hai mô hình trên các phiên thật.
- **Kết quả (2026-11-28):** Xong.
  - **Đã làm:**
    - Sổ đăng ký có thêm mục `shadow` (`set_shadow`); `gate.py --shadow` đưa ứng viên đạt cổng vào chạy bóng thay vì kích hoạt.
    - Backend nạp mô hình chạy bóng; `src_vul_detector.py` chấm cùng đồ thị và ghi `shadow` (phiên bản, lớp, độ tin cậy thô) vào kết quả bước để lưu lại; giao diện không hiển thị.
    - Phiên bản chạy bóng nằm trong dấu vân tay cache, để bản phát lại không làm thiếu dữ liệu so sánh.
    - `scripts/shadow_report.py`: hai mô hình đồng ý bao nhiêu, và mô hình nào khớp kết luận chuyên gia.
  - **Lỗi phát hiện khi thử thật:** LangGraph chỉ giữ khóa có trong schema `State`, nên `shadow` bị bỏ; đã thêm vào `graph/state.py`.
  - **Kiểm tra thật:** đặt ứng viên chạy thử của bước 1.9 làm mô hình chạy bóng → 2 lần phân tích có trường `shadow`, báo cáo: 2 lần quét, 2/2 đồng ý. Sau đó đã gỡ chạy bóng (xóa `models/registry.json`).
  - **Test:** 1 test trong `tests/test_model_registry.py`.

---

## Giai đoạn 3 – Dài hạn (ghi trong báo cáo, không làm trong hackathon)

- Thu thập và gán nhãn hợp đồng Solidity 0.6–0.8 (cú pháp `call{value: ...}`, gọi qua interface), dự án nhiều file, ca âm khó. Phải ghi rõ nguồn nhãn; giữ DAppSCAN làm tập kiểm thử độc lập.
- Sửa các lỗi tiền xử lý trên DAppSCAN: chọn bản solc thấp nhất thỏa pragma (13 file), Slither 0.8.0 không đọc được cú pháp mới (5 file), thiếu file import (33 file).
- Xử lý theo ngưỡng (mục 4.3, bước 3): chỉ rút ngắn việc **xác nhận**, không bao giờ tự bác bỏ cảnh báo.

---

## Kiểm tra tổng thể (2026-11-28)

Sau khi làm xong các bước, toàn hệ thống được kiểm tra lại trên máy phát triển (Windows, chỉ CPU, MongoDB trong Docker, frontend Vite ở cổng 8081):

- **Test Python:** 71 qua, 2 bỏ qua (giới hạn bộ nhớ của sandbox chỉ kiểm được trên Linux; một test cần solc 0.8.20), 1 lỗi đã biết chỉ xảy ra trên Windows (`test_fix_check`, do CRLF; có từ trước).
- **Frontend:** `tsc --noEmit` qua; `npm run build` thành công (cảnh báo kích thước chunk do Monaco, không phải lỗi).
- **Kịch bản đầu-cuối** `eval/e2e/full_flow.py`, đăng nhập bằng cookie qua proxy của frontend, như trình duyệt: **25/25 qua**, gồm:
  - cookie `HttpOnly`/`SameSite=Strict`;
  - phân tích vẫn chạy xong khi ngắt kết nối, nối lại khớp đúng;
  - độ tin cậy đã hiệu chỉnh (0,987);
  - lời giải thích qua bộ kiểm tra và có tham chiếu;
  - ghi bằng cookie thiếu header chống CSRF bị 403; người dùng thường không xác nhận được cảnh báo;
  - nhật ký nhãn nguyên vẹn; mẫu ngẫu nhiên chỉ chuyên gia thấy;
  - agent nộp bản sửa biên dịch được (lần này cả GNN cũng hết gắn cờ) và chuyên gia chấp nhận;
  - SARIF; endpoint bất đồng (chỉ expert); RefactorBot; `/metrics`; đăng xuất.
- **Lỗi tìm thấy và sửa trong quá trình làm:**
  1. Khóa SQLite khi hai luồng cùng tạo cache.
  2. Kết quả phụ thuộc xuống dòng CRLF.
  3. Cache phát lại kết quả cũ sau khi đổi hiệu chỉnh/RAG.
  4. Kết nối MongoDB mới cho mỗi lần ghi kho tri thức.
  5. Schema `State` bỏ mất trường chạy bóng.
  6. Dict tín hiệu phiên tăng mãi.
  7. 4 lời gọi RefactorBot không gửi cookie.
  8. Mở phân tích từ trang dự án làm hợp đồng bị phân tích hai lần (lỗi cũ).
- **Giới hạn của môi trường kiểm tra** (không phải của sản phẩm): máy chỉ có solc 0.4.24 nên nhiều hợp đồng không dựng được đồ thị; `localhost` có lúc phân giải sang IPv6 và bị tiến trình khác trả lời; CORS của code gốc chỉ cho `localhost:8080` nên giao diện cục bộ dùng `web_react/.env.local` để gọi qua proxy.

## Việc cần làm khi triển khai lên server

Những việc không làm được trên máy phát triển này, theo thứ tự:

1. **Khóa bí mật (bước 1.1):** thu hồi 2 token Hugging Face và khóa Google Cloud cũ; đổi `JWT_SECRET`, `SECRET_KEY`, mật khẩu MongoDB nếu trùng giá trị trong lịch sử git; cả nhóm thống nhất rồi xóa lịch sử bằng `git filter-repo`.
2. **`.env` của server:** `AUTH_COOKIE_SECURE=true` (HTTPS), đặt `METRICS_TOKEN`; các biến mới khác có giá trị mặc định (xem `.env.example`).
3. **Kho tri thức (bước 1.8):** chạy một lần `uv run python scripts/seed_knowledge.py` (cần bộ dữ liệu đầy đủ trong `assets/datasets/full/`; trên GPU chỉ mất vài chục giây).
4. **Hiệu chỉnh (bước 1.7):** `calibration.json` gắn với phiên bản checkpoint; nếu checkpoint trên server khác, chạy lại `collect_probs.py` + `fit_temperature.py`.
5. **Sandbox (bước 2.3):** chạy backend trong container; muốn tách mạng hoàn toàn cho việc kiểm tra bản sửa thì tách worker riêng với `network_mode: none`.
6. **Đóng băng phiên bản và chạy 48 giờ (bước 1.10):** tag git, theo dõi `/metrics`.

## Nhật ký triển khai

Ghi mới nhất ở trên cùng. Mỗi dòng: ngày · bước · việc đã làm · kết quả/minh chứng · việc còn dở.

| Ngày | Bước | Việc đã làm | Kết quả / minh chứng | Còn dở |
|---|---|---|---|---|
| 2026-11-28 | Sửa lỗi giao diện | Tạo dự án báo "Failed to fetch": frontend gọi `/api/v1/projects` (không có `/`), backend trả 307 sang `localhost:8000` (khác origin) nên bị CORS chặn. Frontend gọi `/api/v1/projects/` | Tạo và xem dự án qua proxy: 200, không chuyển hướng | – |
| 2026-11-28 | Chạy cục bộ | VS Code chuyển tiếp `127.0.0.1:8000` sang ứng dụng khác của nhóm (đây cũng là nguồn 404 khi đo tải): backend chạy ở 8002 bằng `uvicorn ... --port 8002 --env-file .env`; `vite.config.ts` đọc `VITE_PROXY_TARGET` (mặc định vẫn 8000), đặt trong `web_react/.env.local` | Kịch bản đầu-cuối qua frontend: 25/25 (metrics kiểm tra ở cổng 8002) | – |
| 2026-11-28 | Tổng thể | Toàn bộ test, build frontend, kịch bản đầu-cuối 25 kiểm tra qua cookie | 71 test qua; build OK; 25/25 | Các việc ở mục "Việc cần làm khi triển khai lên server"; chưa commit |
| 2026-11-28 | 1.10 | `/metrics`, load test 5 người × 5 phút; sửa dict tín hiệu phiên tăng mãi | p95 phân tích 3,6 giây, đăng nhập 0,58 giây; lỗi trong lúc đo đều do môi trường (IPv6 `localhost`, thiếu solc) | 48 giờ trên server |
| 2026-11-28 | 2.5 | Cookie `httpOnly` + chống CSRF, frontend bỏ `localStorage` token, CSP trong nginx | Cookie/CSRF/Bearer/đăng xuất đúng; `nginx -t` hợp lệ | Thử bằng trình duyệt |
| 2026-11-28 | 2.7 | Chạy bóng: sổ đăng ký, chấm song song, báo cáo so sánh; sửa schema State | 2 lần quét có dự đoán chạy bóng, 2/2 đồng ý | – |
| 2026-11-28 | 2.2 | Tham chiếu từ kho tri thức trong prompt RefactorBot | Bot dùng và đánh giá đúng tính áp dụng | So sánh trên bộ câu hỏi cố định |
| 2026-11-28 | 2.1 | Agent sửa lỗi 4 công cụ, kiểm tra lại độc lập, endpoint + nút giao diện | Bản sửa đúng trong 13 giây; GNN vẫn gắn cờ hàm đã sửa (giới hạn của mô hình) | Đo hàng loạt |
| 2026-11-28 | 1.8 | Kho tri thức 1.601 mục, RAG cho lời giải thích, đường nhanh; sửa khóa cache và kết nối MongoDB | Đường nhanh hoạt động; chỉ số ca âm khó không kết luận được | – |
| 2026-11-28 | 2.6 | Đồng thuận 2 chuyên gia, bất đồng, kappa, cờ tỉ lệ bác bỏ; endpoint + script | Test qua; chưa có dữ liệu 2 chuyên gia thật | – |
| 2026-11-28 | 2.4 | 10 hợp đồng red-team, chạy trước/sau bộ kiểm tra | Reentrancy: 2/10 câu khẳng định an toàn trước → 0 lọt qua sau | Ca timestamp cần thiết kế lại |
| 2026-11-28 | 2.3 | Sandbox tiến trình riêng cho kiểm tra bản sửa và agent | Quá giờ bị dừng, hàm lạ bị từ chối | Tách mạng bằng container trên server |
| 2026-11-28 | 1.9 | build_graphs, build_feedback_dataset, retrain, gate, model_registry; chạy thử 1 epoch | Ứng viên giống gốc: chấp nhận; ứng viên kém: từ chối kể cả có `--promote` | Huấn luyện thật khi có đủ dữ liệu |
| 2026-11-28 | 1.7 | Tính lại xác suất trên tập test, cross-fit nhiệt độ, `calibration.json` gắn checkpoint, hàng chờ sắp theo độ tin cậy | Timestamp ECE 0,103 → 0,019 (áp dụng); reentrancy không áp dụng vì làm tệ hơn | Hiệu chỉnh lại trên dữ liệu chuyên gia khi đủ |
| 2026-11-28 | 1.6 | Phân tích chạy nền, `GET /sessions/{id}/events`, đóng phiên mồ côi khi khởi động, giao diện nối lại phiên; không dùng Redis (lý do trong bước 1.6) | Ngắt kết nối không dừng phân tích; nối lại từ vị trí bất kỳ khớp đúng; sửa lỗi phân tích hai lần từ trang dự án | – |
| 2026-11-28 | 1.5 | Cache vector (SQLite), cache kết quả theo file + phiên bản mô hình + ngôn ngữ, LLM song song; sửa lỗi khóa SQLite và lỗi phụ thuộc CRLF | Trung vị 13,7 → 9,4 giây (lần đầu), 2,1 giây (file đã quét); lớn nhất 104,8 → 20,6 giây; kết quả giống hệt 11/11 | – |
| 2026-11-28 | 1.4 | `pick_random_audits`, `audit_findings`, hàng chờ + kết luận cho mẫu, mục "Kiểm tra ngẫu nhiên" ở giao diện | Mẫu chỉ có khi đồng ý, ẩn với người tải lên, không vào SARIF; 2 test mới | Đo số ca bỏ sót cần chuyên gia thật |
| 2026-11-28 | 1.3 | Collection `label_events` có chuỗi hash, `training_consent`, `model_versions`, công tắc đồng ý trong Cài đặt, script kiểm tra | Sửa/xóa bản ghi bị phát hiện đúng vị trí; 5 test mới | – |
| 2026-11-28 | 1.2 | `output_guard.py`, viết lại một lần khi vi phạm, lý do `explanation_failed_check` ở backend và giao diện | 1/31 lời giải thích thật bị bắt (lỗi thật); 8 test mới qua | – |
| 2026-11-28 | 1.1 | `.env.production` thành file mẫu; `.gitignore`; gitleaks (config, CI, pre-commit); xóa token Hugging Face khỏi 3 notebook | Quét file đang theo dõi: không còn khóa. Lịch sử git: khóa Google Cloud trong `server.py`/`main.py`, token HF trong notebook | Nhóm thu hồi khóa, đổi khóa server, xóa lịch sử git |
| 2026-11-28 | 0.1 | Script `eval/baseline/run_baseline.py`; giải nén bộ dữ liệu đầy đủ vào `assets/datasets/full/`; đo 11 hợp đồng + 14 ca âm khó; tính ECE | `eval/baseline/report.md`: trung vị 13,7 giây, LLM chiếm phần lớn; ECE 0,071 | – |
| 2026-11-28 | – | Tạo kế hoạch; kiểm tra hiện trạng code (mục "Hiện trạng đã kiểm tra") | File này | Bắt đầu bước 0.1 |
| 2026-11-28 | – | Chuyển LLM sang Claude Haiku qua Astral X, biến `CLAUDE_API_KEY`; xóa mọi nhắc tới Gemini trong code, cấu hình, tài liệu | 35 test qua; RefactorBot trả lời bằng Claude. `test_fix_check.py::test_check_fix_compiles_good_and_rejects_broken` lỗi trên Windows do xuống dòng CRLF, có từ trước | Chưa commit |
