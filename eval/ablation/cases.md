## 3. Nhận xét về bảng

- **Ngữ nghĩa là thành phần quyết định.** Bỏ embedding CodeBERT làm macro-F1 giảm từ 0,85 xuống 0,76 ở timestamp (p = 0,01) và từ 0,73 xuống 0,68 ở reentrancy (p = 0,35, chưa đạt ý nghĩa thống kê).
- **Bước fine-tune theo lỗ hổng đóng góp rõ ở cả hai.** Thay bằng CodeBERT gốc làm giảm 6 điểm ở timestamp (p = 0,03) và 11 điểm ở reentrancy (p = 0,03). Ở reentrancy, CodeBERT gốc còn kém bản chỉ dùng đặc trưng cấu trúc, tức embedding tổng quát không tự mang lại lợi ích.
- **GFD vượt phân tích tĩnh.** So với Slither: hơn 10 điểm ở timestamp (p = 0,007); ở reentrancy hơn 18 điểm so với mọi detector reentrancy-* (p = 0,003) và hơn 11 điểm so với reentrancy-eth (p = 0,07).
- **Tính chất lỗi khác nhau.** Ở reentrancy, Slither với mọi detector có recall lớp có lỗi 0,93 nhưng recall lớp không lỗi chỉ 0,27 (báo nhầm nhiều); GFD cân bằng hơn (0,85 và 0,63).
- **Chi phí.** GFD mất 0,36–0,65 giây mỗi hợp đồng cho bước dựng đồ thị và embedding, cộng vài mili giây cho GNN; Slither mất 0,23–0,28 giây. Huấn luyện GNN mất 31 giây (timestamp) và 93 giây (reentrancy) trên GPU.

## 4. Phân tích trường hợp cải thiện và suy giảm

Dự đoán lấy từ runs/; 1 = báo có lỗi. Đường dẫn file tính từ `SourceCodeSyntaxDataset/<bộ>/Test/`.

| # | Lỗ hổng | File | Nhãn | GFD | Bỏ ngữ nghĩa | CodeBERT gốc | Slither |
|---|---|---|---|---|---|---|---|
| 1 | timestamp | NonVulnerable/0xde29140943dd13fdcf782d51854b5042fd640d99.sol | 0 | 0 | 1 | 0 | 0 |
| 2 | reentrancy | Vulnerable/0x98fe1d52649a3a13863647c6789f16e46e090377.sol | 1 | 1 | 0 | 0 | 0 (reentrancy-eth) |
| 3 | timestamp | Vulnerable/0xe46786c25bd4d042e7acf518a225c1896a01129e.sol | 1 | 0 | 1 | 0 | 1 |
| 4 | reentrancy | NonVulnerable/simple_dao_fixed.sol | 0 | 1 | 1 | 1 | 0 |

### Ca 1 (cải thiện nhờ ngữ nghĩa)
Hợp đồng chỉ dùng `block.timestamp / (1 days)` làm tham số của `emit LogStore` (dòng 25, 29). Các hệ thống có embedding đều báo không lỗi; bản chỉ có 5 đặc trưng cấu trúc báo lỗi vì không đọc được nội dung hàm. Trên tập test timestamp có 28 hợp đồng GFD đúng mà bản bỏ ngữ nghĩa sai, và 11 hợp đồng ngược lại.

### Ca 2 (cải thiện so với phân tích tĩnh và nhờ fine-tune)
`WalletWithEmergencyTransfer.call` (dòng 34–37): `addr.call.value(amount)(data)` với địa chỉ và dữ liệu do người gọi truyền vào. Detector reentrancy-eth không báo vì sau lời gọi không có ghi trạng thái; GFD báo đúng, còn bản bỏ ngữ nghĩa và CodeBERT gốc đều sai. Trên tập test reentrancy có 38 hợp đồng GFD đúng mà reentrancy-eth sai, và 23 hợp đồng ngược lại.

### Ca 3 (suy giảm: GFD bỏ sót, Slither bắt được)
`GiftEth.withdraw`: `require(now >= lockTs)` (dòng 16) đứng ngay trước lệnh chuyển tiền. Slither bắt được bằng luật; GFD và bản CodeBERT gốc bỏ sót. Trên tập test timestamp có 13 hợp đồng Slither đúng mà GFD sai.

### Ca 4 (suy giảm: mọi mô hình học đều báo nhầm)
`simple_dao_fixed.withdraw`: trừ `credit` (dòng 9) rồi mới `call.value` (dòng 10), tức đã sửa đúng theo checks-effects-interactions. Cả ba biến thể học máy vẫn báo lỗi; Slither không báo vì nó kiểm tra thứ tự ghi trạng thái so với lời gọi ngoài. Đây là giới hạn rõ nhất của hướng embedding: mô hình nhận ra sự có mặt của `call.value` chứ không nhận ra thứ tự câu lệnh. Ca này cần chuyên gia hoặc công cụ tĩnh xác nhận.

## 5. Giới hạn

- Mỗi biến thể chạy một seed; chênh lệch 2–3 điểm không nên diễn giải.
- 6 hợp đồng timestamp và 3 hợp đồng reentrancy của tập test bị loại vì không dựng được đồ thị (Slither cũng lỗi trên chúng).
- Chỉ so với một công cụ phân tích tĩnh (Slither 0.8.0, bản sản phẩm đang dùng).
- Nhãn ở mức hợp đồng; bảng không đánh giá việc định vị hàm.
