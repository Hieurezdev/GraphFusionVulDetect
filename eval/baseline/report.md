# Mốc hiện trạng (bước 0.1)

Đo ngày 2026-11-28 qua API của sản phẩm (`eval/baseline/run_baseline.py`), backend chạy cục bộ.

- **Máy:** Windows 11, **chỉ CPU** (PyTorch 2.8.0+cpu, DGL 2.0.0). Máy chấm và server production có GPU, nên thời gian tuyệt đối ở đây cao hơn production; dùng để so trước/sau trên cùng máy.
- **LLM:** Claude Haiku qua Astral X (`byok/astral-x/claude-haiku-5-5`), `language=vi`.
- **Dữ liệu:** bộ đầy đủ trong `assets/datasets/full/` (807/193 timestamp, 611/147 reentrancy).

## 1. Thời gian (11 hợp đồng, `timing_baseline.jsonl`)

Gồm 6 hợp đồng timestamp test (có lỗi / không lỗi × nhỏ / vừa / lớn), 4 hợp đồng reentrancy test và `demo/EtherStore.sol`. Không có lỗi nào.

| Chỉ số | Trung vị | Lớn nhất |
|---|---|---|
| Toàn bộ một lần quét (giây) | 13,7 | 104,8 |
| Từ lúc gửi tới khi mô hình mức hàm xong (giây) | 4,6 | 49,8 |
| Thời gian LLM viết giải thích (giây) | 11,5 | 54,9 |

- **Thời gian chủ yếu là LLM.** Hợp đồng lớn nhất có 7 hàm bị gắn cờ; 7 lời giải thích được gọi **tuần tự**, mất 54,9 giây.
- Hợp đồng không bị gắn cờ không gọi LLM (7,5–14,6 giây, gần như toàn bộ là dựng đồ thị và mã hóa CodeBERT trên CPU, cho cả hai loại lỗ hổng).

## 2. Hiệu chỉnh xác suất (mô hình timestamp mức hợp đồng đang chạy)

Từ xác suất đã lưu trong `eval/ablation/deployed_inference/results.jsonl` (tính trên GPU):

| Tập | Số hợp đồng | Accuracy | Độ tin cậy trung bình | ECE (10 bin) | NLL |
|---|---|---|---|---|---|
| Test | 187 | 0,898 | 0,839 | 0,071 | 0,330 |
| Train | 99 | 0,798 | 0,844 | 0,106 | 0,305 |

Trên tập test, mô hình **tự tin thấp hơn thực tế** (0,839 so với 0,898). File này không có xác suất của mô hình reentrancy.

## 3. Ca âm khó (`hardneg_baseline.jsonl`)

14 hợp đồng timestamp test có nhãn không lỗi nhưng bị mô hình gắn cờ trong kết quả đã lưu.

- Chạy lại trên máy này, **chỉ 4/14 hợp đồng còn bị gắn cờ timestamp** (khác kết quả đã lưu, có thể do khác môi trường CPU/GPU và phiên bản thư viện; chưa tìm nguyên nhân).
- 9 lời giải thích timestamp được sinh; **7/9 đã tự nghi ngờ cảnh báo** ("dương tính giả", "cơ sở yếu"), đo bằng biểu thức trong `run_baseline.py` có loại trừ câu phủ định.
- Như vậy dư địa để RAG (bước 1.8) cải thiện chỉ số này nhỏ, và mẫu chỉ có 9 lời giải thích.
