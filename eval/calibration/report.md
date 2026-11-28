# Hiệu chỉnh độ tin cậy (bước 1.7)

Chạy ngày 2026-11-28 trên máy chỉ có CPU; xác suất tính lại bằng `collect_probs.py` với đúng mô hình đang chạy.
Tập validation của nhóm không có sẵn ở máy này, nên dùng tập test với **cross-fitting 2 phần**: nhiệt độ tìm trên một nửa, ECE đo trên nửa còn lại, rồi đổi vai. Nhiệt độ đưa vào sản phẩm được tìm trên toàn tập test. Hiệu chỉnh nhiệt độ không đổi lớp dự đoán, nên accuracy và F1 không đổi.

## timestamp

- 168 hợp đồng chấm được / 193 (còn lại không dựng được đồ thị). Accuracy 0.935, độ tin cậy trung bình trước hiệu chỉnh 0.843.
- Nhiệt độ hai lần cross-fit: 0.350 và 0.704; tìm trên toàn tập: 0.561.
- **ECE trên nửa giữ riêng: 0.103 → 0.019.**
- **Áp dụng T = 0.561** (mô hình tự tin thấp hơn thực tế, hiệu chỉnh làm xác suất sắc hơn).

| Khoảng độ tin cậy | Số hợp đồng | Độ tin cậy TB (trước) | Accuracy | Độ tin cậy TB (sau) |
|---|---|---|---|---|
| 0.5–0.6 | 8 | 0.539 | 0.875 | 0.569 |
| 0.6–0.7 | 17 | 0.647 | 0.588 | 0.745 |
| 0.7–0.8 | 20 | 0.768 | 1.000 | 0.892 |
| 0.8–0.9 | 62 | 0.851 | 0.968 | 0.956 |
| 0.9–1.0 | 61 | 0.954 | 0.984 | 0.994 |

## reentrancy

- 119 hợp đồng chấm được / 147 (còn lại không dựng được đồ thị). Accuracy 0.739, độ tin cậy trung bình trước hiệu chỉnh 0.748.
- Nhiệt độ hai lần cross-fit: 1.751 và 0.576; tìm trên toàn tập: 1.086.
- **ECE trên nửa giữ riêng: 0.035 → 0.139.**
- **Không áp dụng** (giữ T = 1): hiệu chỉnh làm ECE trên phần giữ riêng tệ hơn, và hai nhiệt độ cross-fit chênh nhau nhiều, tức ước lượng không ổn định trên số mẫu này.

| Khoảng độ tin cậy | Số hợp đồng | Độ tin cậy TB (trước) | Accuracy | Độ tin cậy TB (sau) |
|---|---|---|---|---|
| 0.5–0.6 | 20 | 0.560 | 0.600 | 0.560 |
| 0.6–0.7 | 20 | 0.654 | 0.600 | 0.654 |
| 0.7–0.8 | 37 | 0.763 | 0.730 | 0.763 |
| 0.8–0.9 | 30 | 0.841 | 0.867 | 0.841 |
| 0.9–1.0 | 12 | 0.938 | 0.917 | 0.938 |

