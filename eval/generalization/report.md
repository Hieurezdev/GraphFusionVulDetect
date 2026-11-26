# Yêu cầu 2: khả năng khái quát và ca khó

## Timestamp dependency

### A. Dự án chưa thấy (DAppSCAN, nhãn từ báo cáo audit)

- 36 file, dựng được đồ thị 17/36 (47%); theo phiên bản Solidity: {'0.4': '5/12', '0.5': '5/6', '0.6': '0/2', '0.7': '0/1', '0.8': '7/15'}.
- 210/1371 hàm (15.3%) trùng nguyên văn với một hàm trong tập huấn luyện.
- 65 vị trí audit chỉ ra: không dựng được đồ thị: 36; bỏ sót (hợp đồng có cờ, hàm không): 8; hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn): 8; phát hiện đúng hàm: 6; bỏ sót (hợp đồng bị xếp không lỗi): 4; dòng nằm ngoài mọi hàm: 3.
- Mô hình hiển thị 30 hàm bị gắn cờ, trong đó 6 trùng một vị trí audit.

### B. Hợp đồng lớn (cùng bộ DAppSCAN, chia theo kích thước sau flatten)

| Kích thước | File | Dựng được đồ thị | Số hàm (trung vị) | Giây/file (trung vị) | Giây/file (lớn nhất) | Hàm dài hơn 512 token | Vị trí audit tìm được |
|---|---|---|---|---|---|---|---|
| dưới 500 dòng | 12 | 3 | 55 | 0.7 | 0.91 | 0/130 | 1/3 |
| 500–2.000 dòng | 20 | 13 | 72 | 1.4 | 6.36 | 16/1086 | 5/24 |
| trên 2.000 dòng | 4 | 1 | 155 | 2.3 | 2.3 | 6/155 | 0/2 |

### C. Mã đối kháng (168/193 hợp đồng test được xếp đúng trước khi biến đổi)

| Phép biến đổi | Sinh ra | Không biên dịch được | So sánh được | Có lỗi → bị bỏ sót | Không lỗi → bị cảnh báo | Tỉ lệ đổi kết luận | Thay đổi p trung bình | Hàm bị gắn cờ (trước → sau) |
|---|---|---|---|---|---|---|---|---|
| rename | 80 | 4 | 66 | 0/34 | 2/32 | 3.0% | 0.084 | 65 -> 60 |
| comment_pad | 52 | 2 | 40 | 11/33 | 0/7 | 27.5% | 0.235 | 64 -> 9 |
| dead_code | 52 | 13 | 33 | 0/27 | 0/6 | 0.0% | 0.028 | 47 -> 47 |
| decoy | 80 | 2 | 67 | 0/35 | 26/32 | 38.8% | 0.297 | 66 -> 101 |
| time_wrapper | 40 | 2 | 31 | 0/17 | 13/14 | 41.9% | 0.363 | 30 -> 18 |

Hàm mồi nhử ZDecoy.info bị gắn cờ trong 67 hợp đồng.

### D. Ca dương và ca âm khó (CGT, nhãn gán tay)

- 60 hợp đồng, dựng được đồ thị 58/60 (97%); 45.3% số hàm trùng nguyên văn với tập huấn luyện.
- Ca dương: phát hiện 29/30 (97%), bỏ sót 1.
- Ca âm khó (không lỗi nhưng có cú pháp nhạy cảm): cảnh báo nhầm 27/28 (96%).
- Precision 0.518, recall 0.967.

| Nguồn nhãn | Phát hiện | Bỏ sót | Cảnh báo nhầm | Đúng (không cảnh báo) |
|---|---|---|---|---|
| CodeSmells | 10 | 0 | 27 | 1 |
| ContractFuzzer | 19 | 1 | 0 | 0 |

## Reentrancy

### A. Dự án chưa thấy (DAppSCAN, nhãn từ báo cáo audit)

- 114 file, dựng được đồ thị 71/114 (62%); theo phiên bản Solidity: {'0.4': '5/9', '0.5': '10/14', '0.6': '28/43', '0.7': '6/15', '0.8': '21/30', '0.?': '1/3'}.
- 415/9885 hàm (4.2%) trùng nguyên văn với một hàm trong tập huấn luyện.
- 138 vị trí audit chỉ ra: bỏ sót (hợp đồng bị xếp không lỗi): 82; không dựng được đồ thị: 53; phát hiện đúng hàm: 1; dòng nằm ngoài mọi hàm: 1; bỏ sót (hợp đồng có cờ, hàm không): 1.
- Mô hình hiển thị 1 hàm bị gắn cờ, trong đó 1 trùng một vị trí audit.

### B. Hợp đồng lớn (cùng bộ DAppSCAN, chia theo kích thước sau flatten)

| Kích thước | File | Dựng được đồ thị | Số hàm (trung vị) | Giây/file (trung vị) | Giây/file (lớn nhất) | Hàm dài hơn 512 token | Vị trí audit tìm được |
|---|---|---|---|---|---|---|---|
| dưới 500 dòng | 18 | 9 | 29 | 1.0 | 3.25 | 3/323 | 1/9 |
| 500–2.000 dòng | 62 | 46 | 95 | 2.1 | 8.14 | 90/4583 | 0/59 |
| trên 2.000 dòng | 34 | 16 | 220 | 6.9 | 51.66 | 126/4979 | 0/17 |

### C. Mã đối kháng (64/80 hợp đồng test được xếp đúng trước khi biến đổi)

| Phép biến đổi | Sinh ra | Không biên dịch được | So sánh được | Có lỗi → bị bỏ sót | Không lỗi → bị cảnh báo | Tỉ lệ đổi kết luận | Thay đổi p trung bình | Hàm bị gắn cờ (trước → sau) |
|---|---|---|---|---|---|---|---|---|
| comment_pad | 80 | 0 | 64 | 17/33 | 0/31 | 26.6% | 0.186 | 40 -> 3 |
| dead_code | 80 | 21 | 48 | 7/19 | 0/29 | 14.6% | 0.09 | 27 -> 15 |
| decoy | 80 | 1 | 64 | 0/33 | 0/31 | 0.0% | 0.005 | 40 -> 40 |

Hàm mồi nhử ZDecoy.info bị gắn cờ trong 0 hợp đồng.

### D. Ca dương và ca âm khó (CGT, nhãn gán tay)

- 32 hợp đồng, dựng được đồ thị 29/32 (91%); 66.5% số hàm trùng nguyên văn với tập huấn luyện.
- Ca dương: phát hiện 3/14 (21%), bỏ sót 11.
- Ca âm khó (không lỗi nhưng có cú pháp nhạy cảm): cảnh báo nhầm 6/15 (40%).
- Precision 0.333, recall 0.214.

| Nguồn nhãn | Phát hiện | Bỏ sót | Cảnh báo nhầm | Đúng (không cảnh báo) |
|---|---|---|---|---|
| CodeSmells | 0 | 2 | 4 | 3 |
| ContractFuzzer | 2 | 0 | 0 | 0 |
| Doublade | 1 | 3 | 2 | 6 |
| JiuZhou | 0 | 1 | 0 | 0 |
| NPChecker | 0 | 0 | 0 | 1 |
| NotSoSmartC | 0 | 1 | 0 | 0 |
| Zeus | 0 | 4 | 0 | 0 |
| eThor | 0 | 1 | 0 | 0 |

## Phân tích cảnh báo nhầm và bỏ sót

Mô hình dùng để chấm: timestamp = bộ đang triển khai; reentrancy = `best_model_GAT_2L_max_reentrancy.pt` và `best_node_classifier_model_reentrancy.pt`. Mọi hợp đồng đi qua đúng bước `convert_to_fcg` của sản phẩm (score.py). Kết quả từng ca kèm vị trí dòng: results_dappscan.md, results_hard.md, results_adversarial.md.

### 1. Dự án chưa thấy: rào cản đầu tiên là dựng đồ thị, không phải mô hình
- Chỉ 88/150 file DAppSCAN dựng được đồ thị. Nguyên nhân đã phân loại ở eval/dappscan: bộ dữ liệu thiếu file import (33), sản phẩm chọn bản solc thấp nhất thoả pragma (13), file flatten không biên dịch (10), Slither 0.8.0 lỗi sau khi biên dịch được (5), thiếu bản solc (1). 89/203 vị trí audit rơi vào các file này và không được chấm.
- Timestamp, 29 vị trí được chấm: 6 phát hiện đúng hàm (ví dụ `wHakka.unstake`, dòng 580 theo audit, mô hình gắn cờ L578–595, p = 1,00; `Sliced.sendTokens` dòng 72). 8 vị trí hàm được gắn cờ đúng nhưng bị ẩn vì mô hình mức hợp đồng xếp "không lỗi" (cả 5 vị trí của SamuraiLegendsStaking nằm trong nhóm này hoặc nhóm bỏ sót). 12 vị trí bỏ sót thật.
- Reentrancy, 85 vị trí được chấm: chỉ 1 phát hiện đúng. Mô hình mức hợp đồng chỉ gắn cờ 2/71 hợp đồng. Lý do: dữ liệu huấn luyện định nghĩa reentrancy qua cú pháp `call.value(...)` của Solidity 0.4; mã từ 0.6 trở lên viết `call{value: ...}` hoặc gọi qua interface/token, nên mô hình không nhận ra. Đây là giới hạn phạm vi, cần nói rõ: mô hình reentrancy hiện chỉ áp dụng cho mã kiểu 0.4/0.5.

### 2. Hợp đồng lớn
- Thời gian tăng theo số hàm nhưng vẫn chấp nhận được: trung vị 6,9 giây cho file trên 2.000 dòng (220 hàm), lớn nhất 52 giây.
- 2–3% số hàm dài hơn 512 token và bị cắt khi sinh embedding (126/4.979 hàm ở nhóm lớn nhất); phần bị cắt không được mô hình nhìn thấy.
- Trong 76 vị trí audit reentrancy thuộc file từ 500 dòng trở lên, không vị trí nào được tìm thấy.

### 3. Mã đối kháng (biến đổi giữ nguyên ngữ nghĩa, nhãn gốc không đổi)
- **Chèn comment dài ở đầu hàm (comment_pad)** là phép hiệu quả nhất để che lỗi: 11/33 hợp đồng timestamp và 17/33 hợp đồng reentrancy có lỗi bị chuyển thành "không lỗi"; số hàm bị gắn cờ giảm từ 64 xuống 9 và từ 40 xuống 3. Nguyên nhân trực tiếp là giới hạn 512 token: comment đẩy dòng nguy hiểm ra ngoài phần được mã hoá. Ví dụ: `Vulnerable__0x0a7d11ea…650d.sol`, p từ 0,93 xuống 0,49.
- **Thêm một hàm mồi nhử (decoy)** có nhắc `block.timestamp` trong comment: 26/32 hợp đồng timestamp không lỗi bị chuyển thành "có lỗi", và hàm mồi `ZDecoy.info` bị gắn cờ trong cả 67 hợp đồng. Mô hình timestamp phản ứng với sự xuất hiện của từ khoá, kể cả trong comment. Mô hình reentrancy không bị ảnh hưởng (0/31).
- **Đọc thời gian qua hàm thư viện (time_wrapper)**: không hợp đồng có lỗi nào bị bỏ sót (0/17), nhưng số hàm bị gắn cờ giảm từ 30 xuống 18, tức việc định vị hàm kém đi. 13/14 hợp đồng không lỗi bị cảnh báo vì phép này thêm một hàm đọc `block.timestamp` vào file, cùng cơ chế với mồi nhử.
- **Đổi tên hàm (rename)** gần như không ảnh hưởng (2/66 đổi kết luận). **Chèn mã chết (dead_code)**: timestamp không đổi; reentrancy bỏ sót 7/19. Lưu ý 34/132 file dead_code không biên dịch được và bị loại.

### 4. Ca dương và ca âm khó (nhãn gán tay từ CGT)
- Timestamp: phát hiện 29/30 ca dương, nhưng cảnh báo nhầm 27/28 ca âm khó (hợp đồng có dùng thời gian và được chuyên gia xác nhận không lỗi). Ví dụ: `IcoContract.createTokens` L281–306 (địa chỉ 0x52e3…07d5, nguồn CodeSmells) bị gắn cờ với p = 1,00. Với hợp đồng có dùng timestamp, mô hình gần như luôn báo lỗi: recall cao, khả năng phân biệt thấp.
- Reentrancy: phát hiện 3/14 ca dương, cảnh báo nhầm 6/15 ca âm khó. Các ca dương của Zeus (4/4) và Doublade (3/4) bị bỏ sót.
- 45% (timestamp) và 66% (reentrancy) số hàm trong bộ CGT trùng nguyên văn với tập huấn luyện (thư viện dùng chung như SafeMath, ERC20), nên bộ này không hoàn toàn "chưa thấy"; DAppSCAN sạch hơn (15% và 4%).

### 5. Hệ quả cho sản phẩm
- Không dùng kết quả "không có cảnh báo" làm bằng chứng an toàn: tỉ lệ bỏ sót trên dự án thật là cao, và một comment dài đủ để che lỗi.
- Cảnh báo timestamp cần chuyên gia xác nhận trước khi sửa: 27/28 ca âm khó bị báo nhầm.
- Ba việc cải thiện trực tiếp rút ra từ kết quả: bỏ comment trước khi sinh embedding (vô hiệu hoá comment_pad và mồi nhử trong comment); chọn bản solc cao nhất thoả pragma (cứu 13 file); bổ sung dữ liệu reentrancy với cú pháp `call{value:}` trước khi tuyên bố hỗ trợ Solidity từ 0.6.

### 6. Giới hạn của phép thử
- Bộ đối kháng là mẫu 80 hợp đồng test mỗi lỗ hổng; bộ CGT là mẫu 60 (timestamp) và 32 (reentrancy) hợp đồng. Cỡ mẫu nhỏ, tỉ lệ nên đọc như chỉ báo.
- Nhãn DAppSCAN chỉ có ca dương: hàm không bị audit nêu tên không được coi là an toàn, nên không tính precision ở mức hàm.
- "Phát hiện đúng hàm" nghĩa là hàm bị gắn cờ chứa dòng audit chỉ ra; mô hình không chỉ tới từng dòng.
- Máy chấm bị quá tải trong lúc đo nên số giây/file ở mục B cao hơn điều kiện bình thường.
