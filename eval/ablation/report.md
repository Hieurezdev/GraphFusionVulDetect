# Yêu cầu 1: benchmark và ablation của kiến trúc kết hợp

## 1. Cấu hình tái hiện

- Phần cứng: GPU NVIDIA L40S, 46068 MiB; CPU INTEL(R) XEON(R) GOLD 6542Y, 32 luồng. Mọi hệ thống chạy trên cùng máy này.
- Dữ liệu: bộ SourceCodeSyntaxDataset của bài báo (Kaggle), giữ nguyên cách chia Train/Test. Tập validation = 20% của Train (xáo trộn với seed 42).
- Đồ thị và embedding: sinh bằng chính bước convert_to_fcg của sản phẩm (Slither 0.8.0 + solc theo pragma + CodeBERT, vector [CLS] 768 chiều cho mỗi hàm).
- Huấn luyện: Adam, CrossEntropy, seed 42; epoch được chọn theo macro-F1 trên validation, không dùng tập test. Siêu tham số từng lỗ hổng ghi ở đầu mỗi mục.
- Chấm điểm: từng hợp đồng một, như API /analyze. Chỉ tính các hợp đồng test mà mọi hệ thống đều chấm được.
- Kiểm định: McNemar chính xác hai phía, so từng hệ thống với GFD đầy đủ trên cùng tập hợp đồng.
- Chạy lại toàn bộ: `SRC=<SourceCodeSyntaxDataset> PY=<python có PyTorch + DGL bản CUDA> eval/ablation/run_all.sh` từ thư mục gốc repo; phiên bản thư viện ở requirements-gpu.txt; image backend dựng từ docker/be.prod.dockerfile.
- Kết quả thô: runs/<lỗ hổng>/<biến thể>.json (dự đoán từng hợp đồng, thời gian, tài nguyên) và runs/<lỗ hổng>/baselines.jsonl (Slither, thời gian).

Các hệ thống được so sánh:

- GFD đầy đủ: CodeBERT fine-tune theo lỗ hổng + call graph + GNN.
- Bỏ ngữ nghĩa: giữ call graph và GNN, mỗi hàm chỉ còn 5 đặc trưng cấu trúc (bậc vào, bậc ra, Katz, closeness, clustering).
- Ngữ nghĩa chưa fine-tune: như GFD đầy đủ nhưng embedding lấy từ microsoft/codebert-base.
- Slither 0.8.0: công cụ phân tích tĩnh, dùng detector của chính nó cho từng lỗ hổng.

## 2. Bảng benchmark, ablation và tài nguyên

### timestamp

Tập test: 193 hợp đồng; 187 được mọi hệ thống chấm (96 có lỗi). Không dựng được đồ thị: 6; Slither lỗi: 6.

Cấu hình: {"mtype": ["GCN"], "n_gph": 0, "num_query_vectors": 2, "hfeats": [2048, 2048], "gptype": "max", "lr": 0.0005, "batch": 128, "epochs": 200}, encoder Quangnguyen711/codebert-solidity-time-dep, seed 42, torch 2.4.0+cu121, dgl 2.4.0+cu121, cuda.

| Hệ thống | P không lỗi | R không lỗi | F1 không lỗi | P có lỗi | R có lỗi | F1 có lỗi | Macro-F1 | Accuracy | GFD đúng, hệ này sai | GFD sai, hệ này đúng | McNemar p | Macro-F1 khử gần-trùng |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| GFD đầy đủ (huấn luyện lại) | 0.832 | 0.868 | 0.849 | 0.87 | 0.833 | 0.851 | 0.85 | 0.85 | 0 | 0 | 1.0 | 0.843 |
| Bỏ ngữ nghĩa (5 đặc trưng cấu trúc) | 0.78 | 0.703 | 0.74 | 0.743 | 0.812 | 0.776 | 0.758 | 0.759 | 28 | 11 | 0.0095 | 0.719 |
| Ngữ nghĩa chưa fine-tune (CodeBERT gốc) | 0.75 | 0.857 | 0.8 | 0.843 | 0.729 | 0.782 | 0.791 | 0.791 | 16 | 5 | 0.0266 | 0.768 |
| Slither 0.8.0 (detector timestamp) | 0.75 | 0.725 | 0.737 | 0.747 | 0.771 | 0.759 | 0.748 | 0.749 | 32 | 13 | 0.0066 | 0.729 |

Khử gần-trùng = 156 hợp đồng khác nhau về (nhãn, số hàm, số cạnh).

| Biến thể | Tham số | Hợp đồng huấn luyện | Thời gian huấn luyện (s) | Epoch được chọn | Macro-F1 validation | GNN ms/hợp đồng | GPU đỉnh (MB) |
|---|---|---|---|---|---|---|---|
| Ngữ nghĩa chưa fine-tune (CodeBERT gốc) | 6312386 | 610 | 35.3 | 180 | 0.831 | 2.93 | 456 |
| GFD đầy đủ (huấn luyện lại) | 6312386 | 610 | 30.9 | 151 | 0.865 | 2.48 | 456 |
| Bỏ ngữ nghĩa (5 đặc trưng cấu trúc) | 4749762 | 610 | 46.2 | 196 | 0.761 | 3.79 | 325 |

Trung vị thời gian mỗi hợp đồng: Slither 0.282 s; dựng đồ thị + embedding (bước chung của mọi biến thể GFD) 0.652 s.

### reentrancy

Tập test: 147 hợp đồng; 144 được mọi hệ thống chấm (71 có lỗi). Không dựng được đồ thị: 3; Slither lỗi: 3.

Cấu hình: {"mtype": ["GAT"], "n_gph": 2, "num_query_vectors": 1, "hfeats": [2048, 2048], "gptype": "max", "lr": 0.0001, "batch": 256, "epochs": 100}, encoder Quangnguyen711/codebert-solidity-re-entrancy, seed 42, torch 2.4.0+cu121, dgl 2.4.0+cu121, cuda.

| Hệ thống | P không lỗi | R không lỗi | F1 không lỗi | P có lỗi | R có lỗi | F1 có lỗi | Macro-F1 | Accuracy | GFD đúng, hệ này sai | GFD sai, hệ này đúng | McNemar p | Macro-F1 khử gần-trùng |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| GFD đầy đủ (huấn luyện lại) | 0.807 | 0.63 | 0.708 | 0.69 | 0.845 | 0.759 | 0.734 | 0.736 | 0 | 0 | 1.0 | 0.727 |
| Bỏ ngữ nghĩa (5 đặc trưng cấu trúc) | 0.659 | 0.767 | 0.709 | 0.712 | 0.592 | 0.646 | 0.678 | 0.681 | 32 | 24 | 0.3497 | 0.663 |
| Ngữ nghĩa chưa fine-tune (CodeBERT gốc) | 0.756 | 0.425 | 0.544 | 0.592 | 0.859 | 0.701 | 0.623 | 0.639 | 26 | 12 | 0.0336 | 0.601 |
| Slither 0.8.0 (bất kỳ reentrancy-*) | 0.8 | 0.274 | 0.408 | 0.555 | 0.93 | 0.695 | 0.551 | 0.597 | 31 | 11 | 0.0029 | 0.531 |
| Slither 0.8.0 (reentrancy-eth) | 0.602 | 0.808 | 0.69 | 0.696 | 0.451 | 0.547 | 0.619 | 0.632 | 38 | 23 | 0.0722 | 0.581 |

Khử gần-trùng = 123 hợp đồng khác nhau về (nhãn, số hàm, số cạnh).

| Biến thể | Tham số | Hợp đồng huấn luyện | Thời gian huấn luyện (s) | Epoch được chọn | Macro-F1 validation | GNN ms/hợp đồng | GPU đỉnh (MB) |
|---|---|---|---|---|---|---|---|
| Ngữ nghĩa chưa fine-tune (CodeBERT gốc) | 55134658 | 452 | 140.2 | 88 | 0.674 | 14.27 | 4378 |
| GFD đầy đủ (huấn luyện lại) | 55134658 | 452 | 93.3 | 39 | 0.814 | 6.39 | 4378 |
| Bỏ ngữ nghĩa (5 đặc trưng cấu trúc) | 42633666 | 452 | 91.7 | 28 | 0.72 | 6.05 | 4077 |

Trung vị thời gian mỗi hợp đồng: Slither 0.226 s; dựng đồ thị + embedding (bước chung của mọi biến thể GFD) 0.363 s.

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
