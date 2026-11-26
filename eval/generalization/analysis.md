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
