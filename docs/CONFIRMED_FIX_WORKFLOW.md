# Quy trình phát hiện → giải thích → sửa → biên dịch/kiểm tra, có chuyên gia xác nhận

Tài liệu này mô tả luồng hoạt động của ScanGuard sau khi bổ sung quét song song hai lỗ hổng và lưu vết bản sửa. Bản ghi một lượt chạy thật: `demo/transcript.txt`; ảnh giao diện: `demo/screenshots/`; script chạy lại: `demo/run_demo.py`.

## 1. Luồng tổng thể

```
Tải lên / tìm token
        │
        ▼
POST /api/v1/analyze ──► sự kiện "start" (danh sách lỗ hổng được quét)
        │
        ├── luồng timestamp:   dựng đồ thị → mô hình hợp đồng → mô hình hàm → giải thích
        └── luồng reentrancy:  dựng đồ thị → mô hình hợp đồng → mô hình hàm → giải thích
        │        (hai luồng chạy đồng thời; mỗi sự kiện mang trường "vulnerability")
        ▼
sự kiện "summary": kết luận chung + danh sách việc cần rà soát thủ công
        │
        ▼
Chuyên gia xét từng cảnh báo ──► dương tính giả ──► đóng
        │                     └► cần rà soát thủ công ──► dừng ở con người
        ▼ đã xác nhận
Đề xuất bản sửa (RefactorBot hoặc sửa tay trong IDE)
        │
        ▼
Biên dịch bằng solc theo pragma + chạy lại Slither ──► không biên dịch được ──► sửa lại
        │ biên dịch được: kết quả được lưu vào cảnh báo
        ▼
Chuyên gia chấp nhận / từ chối / chuyển rà soát thủ công
```

## 2. Quét song song và kết luận

- Mỗi lỗ hổng có bộ ba mô hình riêng (encoder CodeBERT, GNN mức hợp đồng, GNN mức hàm), nạp một lần khi khởi động (`src/workflows/gfd_workflow/workflow.py`). Bộ nào thiếu checkpoint thì bị bỏ qua và ghi log.
- `VulnerabilityAnalysisService.analyze_solidity_file` chạy mỗi lỗ hổng trong một luồng riêng, ghi file đồ thị vào thư mục riêng, và phát sự kiện ngay khi có.
- Một luồng lỗi không che kết quả luồng kia: nó phát sự kiện `error` có gắn lỗ hổng. Chỉ khi mọi luồng đều lỗi thì phiên mới bị đánh dấu thất bại.
- Sự kiện `summary` (`src/services/findings.py: summarize`) cho mỗi lỗ hổng một trong bốn trạng thái và rút ra một kết luận:

| Trạng thái từng luồng | Ý nghĩa |
|---|---|
| `flagged` | hợp đồng bị gắn cờ và có hàm được định vị |
| `flagged_no_function` | hợp đồng bị gắn cờ nhưng không định vị được hàm → cần rà soát thủ công |
| `not_flagged` | không có cảnh báo (không phải bằng chứng an toàn) |
| `failed` | không chạy được (thường do không biên dịch được) → cần rà soát thủ công |

| Kết luận | Điều kiện |
|---|---|
| `alerts` | có ít nhất một luồng gắn cờ |
| `manual_review` | không luồng nào gắn cờ, nhưng có luồng thất bại |
| `no_alerts` | mọi luồng chạy xong và không gắn cờ |

## 3. Cảnh báo và vòng đời của nó

Một cảnh báo được định danh bằng cặp (lỗ hổng, tên hàm): cùng một hàm có thể bị cả hai luồng gắn cờ và được xét riêng. Trạng thái (`findings.py: stage`):

| Trạng thái | Ai chuyển tiếp | Bước kế tiếp |
|---|---|---|
| `awaiting_review` | chuyên gia | xác nhận, bác bỏ, hoặc chuyển rà soát thủ công |
| `closed_false_positive` | – | đóng; vẫn nằm trong SARIF dưới dạng đã suppress để lưu vết |
| `manual_review` | con người | ngoài phạm vi tự động |
| `awaiting_fix` | người dùng | đề xuất bản sửa rồi bấm kiểm tra |
| `fix_failed_check` | người dùng | sửa lại; không thể chấp nhận |
| `awaiting_fix_approval` | chuyên gia | chấp nhận hoặc từ chối đúng bản đã biên dịch |
| `fix_accepted` | – | chạy bộ test của dự án và audit trước khi triển khai |

## 4. Các quy tắc được máy chủ thực thi

| Quy tắc | Nơi thực thi | Kết quả khi vi phạm |
|---|---|---|
| Chỉ tài khoản expert được xác nhận/bác bỏ cảnh báo | `PUT /sessions/{id}/reviews` | 403 |
| Mọi tài khoản được đề xuất và kiểm tra bản sửa cho hàm bị gắn cờ; kết quả được lưu để chuyên gia xem | `POST /refactor/validate` | – |
| Chỉ chấp nhận được bản sửa của cảnh báo đã được xác nhận | `PUT /sessions/{id}/fixes` | 409 |
| Chỉ expert được quyết định bản sửa | `PUT /sessions/{id}/fixes` | 403 |
| Chỉ chấp nhận được bản sửa đã biên dịch | `PUT /sessions/{id}/fixes` | 409 |
| Kiểm tra lại bản sửa mới thì quyết định cũ bị xoá | `POST /refactor/validate` | bản ghi quay về `proposed` |

Tài khoản thường dùng được RefactorBot cho mọi hàm bị gắn cờ, nhưng không ghi được nhận xét của chuyên gia; tài khoản chuyên gia làm được cả hai. Các quy tắc trên không phụ thuộc vào giao diện.

## 5. Các trường hợp phải rà soát thủ công

1. Hợp đồng không biên dịch được hoặc thiếu file import: luồng quét báo `failed`.
2. Hợp đồng bị gắn cờ nhưng không hàm nào được định vị.
3. Chuyên gia chọn "cần rà soát thủ công" cho một cảnh báo hoặc một bản sửa.
4. Không có cảnh báo nào: giao diện và SARIF đều ghi rõ đây không phải bằng chứng an toàn.
5. Bản sửa đã được chấp nhận: biên dịch được và Slither không báo thêm không chứng minh bản sửa đúng; vẫn cần bộ test của dự án và audit.

## 6. API liên quan

| Endpoint | Việc |
|---|---|
| `POST /api/v1/analyze` | quét song song, stream NDJSON: `start`, các sự kiện có `vulnerability`, `summary` |
| `GET /api/v1/sessions/{id}/findings` | mọi cảnh báo kèm review, bản sửa và trạng thái |
| `PUT /api/v1/sessions/{id}/reviews` | kết luận của chuyên gia cho (lỗ hổng, hàm) |
| `POST /api/v1/refactor/validate` | ghép bản sửa vào hợp đồng, biên dịch, chạy Slither, lưu kết quả |
| `PUT /api/v1/sessions/{id}/fixes` | chuyên gia chấp nhận/từ chối bản sửa |
| `GET /api/v1/sessions/{id}/sarif` | xuất SARIF cho IDE/CI, quy tắc riêng cho từng lỗ hổng (GFD-TS-*, GFD-RE-*), kèm trạng thái quy trình |

Phiên phân tích lưu trước thay đổi này không có trường lỗ hổng trên từng bước; chúng được đọc như phiên timestamp.

## 7. Chạy demo

```
BASE=http://<api> USER_LOGIN=<user>:<pass> EXPERT_LOGIN=<expert>:<pass> python demo/run_demo.py
```

Hợp đồng demo là `demo/EtherStore.sol` (ví dụ reentrancy kinh điển). Cả hai luồng gắn cờ `withdrawFunds`: cảnh báo reentrancy được xác nhận và sửa; cảnh báo timestamp (giới hạn rút theo tuần) bị chuyên gia đánh dấu dương tính giả. Script thoát với mã lỗi nếu một quy tắc ở mục 4 không được thực thi.

## 8. Giới hạn đã biết

- Mô hình có tỉ lệ bỏ sót và báo nhầm đáng kể trên dự án thật (xem `eval/generalization/report.md`); đó là lý do mọi bước quyết định đều qua chuyên gia.
- "Kiểm tra" hiện gồm biên dịch và Slither. Hệ thống không chạy bộ test của dự án người dùng.
- Mô hình reentrancy nhận ra cú pháp `call.value(...)` của Solidity 0.4/0.5, chưa nhận ra `call{value: ...}`.
- Hai luồng dựng đồ thị độc lập nên Slither chạy hai lần cho mỗi hợp đồng.
