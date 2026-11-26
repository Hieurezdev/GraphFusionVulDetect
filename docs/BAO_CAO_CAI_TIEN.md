# Báo cáo cải tiến sản phẩm

**ScanGuard / GraphFusionDetect: phát hiện lỗ hổng hợp đồng thông minh bằng CodeBERT và mạng nơ-ron đồ thị**

Vòng chung kết cuộc thi Sáng tạo trẻ Quốc gia trong lĩnh vực Trí tuệ nhân tạo năm 2026. Tháng 11 năm 2026.

---

## 1. Chứng minh đóng góp của kiến trúc kết hợp

> **Vấn đề:** Các chỉ số F1 hiện gắn với bộ đánh giá đã mô tả, chưa đủ xác định từng thành phần tạo ra mức cải thiện bao nhiêu.
>
> **Yêu cầu:** So công cụ phân tích tĩnh và các bản bỏ đồ thị/bỏ ngữ nghĩa trên cùng tập, phần cứng; đo F1 theo lớp, thời gian và tài nguyên.
>
> **Minh chứng:** Bảng benchmark và ablation có cấu hình tái hiện, phân tích trường hợp cải thiện hoặc suy giảm.

### 1.1. Cấu hình tái hiện

- **Dữ liệu huấn luyện và kiểm thử chuẩn:** bộ dữ liệu của bài báo, đã loại trùng hàm giữa hai tập, giữ nguyên cách chia. Timestamp: 807 hợp đồng huấn luyện, 193 kiểm thử. Reentrancy: 611 huấn luyện, 147 kiểm thử.
- **Phần cứng:** GPU NVIDIA L40S (46 GB), CPU Intel Xeon Gold 6542Y, 32 luồng. Mọi hệ thống trong cùng một bảng chạy trên cùng máy này.
- **Phần mềm:** PyTorch 2.4.0, DGL 2.4.0 (CUDA 12.1), Slither 0.8.0, trình biên dịch solc chọn theo `pragma` của từng hợp đồng.
- **Tái hiện:** `eval/ablation/run_all.sh` (yêu cầu 1), `eval/generalization/run_all.sh` và `report.py` (yêu cầu 2), `demo/run_demo.py` (yêu cầu 3). Phiên bản thư viện ghi trong `eval/ablation/requirements-gpu.txt`.

### 1.2. Các hệ thống được so sánh

Bốn hệ thống được so sánh trên cùng tập kiểm thử:

- **GFD đầy đủ:** CodeBERT fine-tune theo lỗ hổng, đồ thị gọi hàm và GNN.
- **Bỏ ngữ nghĩa:** giữ đồ thị và GNN; mỗi hàm chỉ còn 5 đặc trưng cấu trúc (bậc vào, bậc ra, Katz, closeness, hệ số phân cụm).
- **Ngữ nghĩa chưa fine-tune:** như GFD đầy đủ nhưng vector hàm lấy từ `microsoft/codebert-base`.
- **Slither 0.8.0:** công cụ phân tích tĩnh, dùng detector của chính nó cho từng lỗ hổng.

Để so sánh công bằng, mọi biến thể học máy được huấn luyện lại theo cùng một quy trình: siêu tham số theo notebook của nhóm, tối ưu Adam, seed 42, tách 20% tập huấn luyện làm tập validation và chọn epoch theo macro-F1 trên validation, không dùng tập kiểm thử để chọn. Hợp đồng được chấm từng cái một, đúng cách API của sản phẩm hoạt động. Chỉ những hợp đồng mà mọi hệ thống đều chấm được mới được tính (187/193 và 144/147). Ý nghĩa thống kê được kiểm bằng kiểm định McNemar chính xác hai phía so với GFD đầy đủ.

### 1.3. Bảng benchmark và ablation: F1 theo từng lớp

**Timestamp dependency: 187 hợp đồng kiểm thử (96 có lỗi)**

| Hệ thống | P không lỗi | R không lỗi | F1 không lỗi | P có lỗi | R có lỗi | F1 có lỗi | Macro-F1 | Accuracy | p McNemar |
|---|---|---|---|---|---|---|---|---|---|
| GFD đầy đủ | 0,83 | 0,87 | 0,85 | 0,87 | 0,83 | 0,85 | **0,85** | 0,85 | – |
| Bỏ ngữ nghĩa | 0,78 | 0,70 | 0,74 | 0,74 | 0,81 | 0,78 | 0,76 | 0,76 | 0,010 |
| Ngữ nghĩa chưa fine-tune | 0,75 | 0,86 | 0,80 | 0,84 | 0,73 | 0,78 | 0,79 | 0,79 | 0,027 |
| Slither (`timestamp`) | 0,75 | 0,73 | 0,74 | 0,75 | 0,77 | 0,76 | 0,75 | 0,75 | 0,007 |

**Reentrancy: 144 hợp đồng kiểm thử (71 có lỗi)**

| Hệ thống | P không lỗi | R không lỗi | F1 không lỗi | P có lỗi | R có lỗi | F1 có lỗi | Macro-F1 | Accuracy | p McNemar |
|---|---|---|---|---|---|---|---|---|---|
| GFD đầy đủ | 0,81 | 0,63 | 0,71 | 0,69 | 0,85 | 0,76 | **0,73** | 0,74 | – |
| Bỏ ngữ nghĩa | 0,66 | 0,77 | 0,71 | 0,71 | 0,59 | 0,65 | 0,68 | 0,68 | 0,350 |
| Ngữ nghĩa chưa fine-tune | 0,76 | 0,43 | 0,54 | 0,59 | 0,86 | 0,70 | 0,62 | 0,64 | 0,034 |
| Slither (mọi `reentrancy-*`) | 0,80 | 0,27 | 0,41 | 0,56 | 0,93 | 0,70 | 0,55 | 0,60 | 0,003 |
| Slither (`reentrancy-eth`) | 0,60 | 0,81 | 0,69 | 0,70 | 0,45 | 0,55 | 0,62 | 0,63 | 0,072 |

Khi loại các hợp đồng gần trùng nhau (cùng nhãn, cùng số hàm, cùng số cạnh), thứ tự các hệ thống không đổi: macro-F1 của GFD đầy đủ là 0,84 trên 156 hợp đồng timestamp và 0,73 trên 123 hợp đồng reentrancy.

### 1.4. Mức đóng góp của từng thành phần

- **Ngữ nghĩa.** Bỏ vector CodeBERT làm macro-F1 giảm 9 điểm ở timestamp (p = 0,010) và 6 điểm ở reentrancy (p = 0,35, chưa đạt ý nghĩa thống kê).
- **Bước fine-tune theo lỗ hổng.** Thay bằng CodeBERT gốc làm giảm 6 điểm ở timestamp (p = 0,027) và 11 điểm ở reentrancy (p = 0,034). Ở reentrancy, CodeBERT gốc còn kém bản chỉ dùng đặc trưng cấu trúc: embedding mã nguồn tổng quát không tự mang lại lợi ích, chính bước fine-tune mới tạo ra giá trị.
- **So với phân tích tĩnh.** GFD hơn Slither 10 điểm ở timestamp (p = 0,007). Ở reentrancy, GFD hơn 18 điểm so với tập hợp mọi detector `reentrancy-*` (p = 0,003) và 11 điểm so với `reentrancy-eth` (p = 0,072).
- **Tính chất lỗi khác nhau.** Với reentrancy, Slither dùng mọi detector có recall lớp có lỗi 0,93 nhưng recall lớp không lỗi chỉ 0,27; GFD cân bằng hơn (0,85 và 0,63).

### 1.5. Thời gian và tài nguyên

| | Timestamp | Reentrancy |
|---|---|---|
| Số tham số GNN mức hợp đồng | 6,3 triệu | 55,1 triệu |
| Số hợp đồng dùng để huấn luyện (sau khi tách validation) | 610 | 452 |
| Thời gian huấn luyện GNN (GFD đầy đủ) | 31 giây | 93 giây |
| Bộ nhớ GPU đỉnh khi huấn luyện | 0,46 GB | 4,4 GB |
| Dựng đồ thị và mã hoá hàm, trung vị mỗi hợp đồng | 0,65 giây | 0,36 giây |
| Suy luận GNN, mỗi hợp đồng | 2,5 ms | 6,4 ms |
| Slither, trung vị mỗi hợp đồng | 0,28 giây | 0,23 giây |

GFD chậm hơn Slither khoảng 1,5 đến 2,3 lần cho mỗi hợp đồng; gần như toàn bộ thời gian nằm ở bước dựng đồ thị và mã hoá hàm, bước này dùng chung cho mọi biến thể.

### 1.6. Phân tích trường hợp cải thiện và suy giảm

Mục này phân tích bảng ở mục 1.3 theo từng cặp so sánh với GFD đầy đủ: chỉ số nào cải thiện, chỉ số nào suy giảm, và nguyên nhân. Lớp có lỗi được coi là lớp dương; FP là dương tính giả, FN là âm tính giả.

**Bỏ ngữ nghĩa: suy giảm ở cả hai lỗ hổng, theo hai kiểu lỗi khác nhau.**

- **Timestamp, suy giảm do tăng FP.** Recall lớp có lỗi gần như không đổi (0,83 xuống 0,81), nhưng precision lớp có lỗi giảm từ 0,87 xuống 0,74 và recall lớp không lỗi giảm từ 0,87 xuống 0,70. Đặc trưng cấu trúc không mã hoá cách hàm sử dụng thời gian khối, nên hợp đồng dùng thời gian khối trong điều kiện ra quyết định và hợp đồng chỉ lưu thời gian có biểu diễn đồ thị tương đương.
- **Reentrancy, suy giảm do tăng FN.** Recall lớp có lỗi giảm từ 0,85 xuống 0,59. Dấu hiệu của reentrancy nằm trong thân hàm thực hiện lời gọi ngoài, là thông tin mà đồ thị gọi hàm không biểu diễn.
- **Cải thiện cục bộ.** Recall lớp không lỗi ở reentrancy tăng từ 0,63 lên 0,77. Mức tăng này đến từ việc mô hình dự đoán lớp dương ít hơn, không phải từ khả năng phân biệt tốt hơn: macro-F1 vẫn giảm 5 điểm.

**Ngữ nghĩa chưa fine-tune: suy giảm, ở reentrancy thấp hơn cả bản bỏ ngữ nghĩa.**

- **Timestamp, suy giảm do tăng FN.** Recall lớp có lỗi giảm từ 0,83 xuống 0,73. Embedding của CodeBERT gốc phản ánh độ tương đồng mã nguồn nói chung, nên các hàm chỉ khác nhau ở việc có phụ thuộc thời gian khối hay không nằm gần nhau trong không gian biểu diễn.
- **Reentrancy, suy giảm do tăng FP.** Recall lớp có lỗi giữ ở 0,86 nhưng recall lớp không lỗi giảm từ 0,63 xuống 0,43. Mô hình thiên về dự đoán lớp dương khi hợp đồng có lời gọi ngoài kèm chuyển ETH, không tách được mẫu sử dụng an toàn.
- **Nhận định.** Phần cải thiện của GFD đến từ bước fine-tune theo từng lỗ hổng, không phải từ việc bổ sung một mô hình ngôn ngữ tiền huấn luyện bất kỳ.

**Slither: suy giảm ở timestamp, đánh đổi precision–recall ở reentrancy.**

- **Timestamp, suy giảm ở cả hai lớp.** F1 là 0,74 và 0,76 so với 0,85 và 0,85 của GFD. Detector dựa trên mẫu so sánh với thời gian khối: sinh FN khi thời gian khối được dùng ngoài phép so sánh, và sinh FP khi phép so sánh không ảnh hưởng tới luồng tiền hay quyền truy cập.
- **Reentrancy, cải thiện ở từng chỉ số riêng lẻ tuỳ cấu hình.** Với mọi detector `reentrancy-*`, recall lớp có lỗi đạt 0,93 (GFD 0,85) nhưng recall lớp không lỗi chỉ 0,27. Với riêng `reentrancy-eth`, recall lớp không lỗi đạt 0,81 (GFD 0,63) nhưng recall lớp có lỗi chỉ 0,45.
- **Nguyên nhân.** Quy tắc tĩnh có ngưỡng quyết định cố định: quy tắc rộng tối ưu recall và chấp nhận FP cao, quy tắc hẹp tối ưu precision và chấp nhận FN cao. GFD học ranh giới quyết định từ dữ liệu nên cân bằng hơn giữa hai lớp (0,85 và 0,63) và đạt macro-F1 cao nhất.

**GFD: suy giảm ở reentrancy so với timestamp (macro-F1 0,73 so với 0,85).**

- **Nguồn suy giảm chính là FP.** Recall lớp không lỗi là 0,63. Reentrancy phụ thuộc vào thứ tự giữa thao tác cập nhật trạng thái và lời gọi ngoài, trong khi embedding mức hàm chủ yếu phản ánh sự có mặt của lời gọi ngoài. Hợp đồng đã áp dụng đúng mẫu checks-effects-interactions vì thế vẫn có thể bị phân loại là có lỗi.
- **Dữ liệu huấn luyện ít hơn.** Reentrancy có 452 hợp đồng huấn luyện so với 610 của timestamp.
- **Hệ quả thiết kế.** Đây là cơ sở để sản phẩm yêu cầu chuyên gia xác nhận từng cảnh báo ở mục 3.

**Mức độ bất đồng giữa GFD và từng phương pháp.** Bảng dưới đếm số hợp đồng mà chỉ một trong hai phương pháp kết luận đúng. Ở mọi cặp, số hợp đồng GFD đúng còn phương pháp kia sai đều lớn hơn chiều ngược lại.

| So với GFD | Timestamp: GFD đúng, phương pháp sai | Timestamp: GFD sai, phương pháp đúng | Reentrancy: GFD đúng, phương pháp sai | Reentrancy: GFD sai, phương pháp đúng |
|---|---|---|---|---|
| Bỏ ngữ nghĩa | 28 | 11 | 32 | 24 |
| CodeBERT gốc | 16 | 5 | 26 | 12 |
| Slither | 32 | 13 | 38 | 23 |

Cột "GFD sai, phương pháp đúng" không rỗng: không phương pháp nào bao trùm phương pháp khác. GFD kết luận sai 28/187 hợp đồng timestamp và 38/144 hợp đồng reentrancy.

---|---|---|---|---|---|---|---|
| 1 | timestamp | `0xde29…0d99.sol` | không lỗi | đúng | sai | đúng | đúng |
| 2 | timestamp | `0x57f8…1932.sol` | có lỗi | đúng | đúng | sai | đúng |
| 3 | timestamp | `0x98c1…3cd8.sol` | có lỗi | đúng | đúng | đúng | sai |
| 4 | reentrancy | `0x6805…9fd0.sol` | không lỗi | đúng | sai | đúng | đúng |
| 5 | reentrancy | `0xc8d9…b611.sol` | không lỗi | đúng | sai | sai | đúng |
| 6 | reentrancy | `0x6091…3b36.sol` | không lỗi | đúng | đúng | đúng | sai |
| 7 | reentrancy | `0x98fe…0377.sol` | có lỗi | đúng | sai | sai | sai |

Giải thích từng trường hợp:

1. **Bỏ ngữ nghĩa thì báo nhầm.** Hợp đồng chỉ ghi thời gian khối vào nhật ký sự kiện để tra cứu; thời gian này không quyết định điều kiện nào và không ảnh hưởng tới tiền hay trạng thái. Bản bỏ ngữ nghĩa chỉ thấy cấu trúc đồ thị, không đọc được nội dung hàm, nên báo có lỗi. Các phương pháp còn lại kết luận đúng.
2. **CodeBERT gốc bỏ sót.** Hàm nhận tiền của hợp đồng bán trước token chỉ chạy khi một hàm phụ xác nhận đợt bán đang mở, và hàm phụ đó so sánh thời gian khối với thời điểm mở, đóng. Việc nhận tiền vì thế phụ thuộc vào thời gian khối, nhưng phép so sánh không nằm trong chính hàm nhận tiền. CodeBERT chưa fine-tune bỏ sót; GFD, bản bỏ ngữ nghĩa và Slither phát hiện đúng.
3. **Slither bỏ sót.** Hợp đồng ghi thẳng thời gian khối vào dữ liệu lưu trữ, không qua phép so sánh nào. Quy tắc của Slither chỉ bắt các phép so sánh với thời gian khối nên không báo. GFD và hai biến thể ablation phát hiện đúng theo nhãn.
4. **Bỏ ngữ nghĩa thì báo nhầm.** Hợp đồng có một câu lệnh trông giống lệnh gửi tiền ra ngoài nhưng viết thiếu phần gọi hàm, nên thực tế không có lời gọi ra ngoài nào và không thể bị gọi lại. Bản bỏ ngữ nghĩa báo có lỗi; các phương pháp còn lại kết luận đúng.
5. **Cả hai biến thể ablation báo nhầm.** Hàm chỉ chuyển tiếp số tiền vừa nhận tới địa chỉ đích. Hợp đồng không lưu số dư của người dùng, nên gọi lại hàm cũng không rút thêm được gì. Bản bỏ ngữ nghĩa và CodeBERT gốc báo có lỗi vì thấy lệnh gửi tiền; GFD và Slither kết luận đúng.
6. **Slither báo nhầm.** Đây là một hàm nội bộ của thư viện, chỉ bọc lệnh gọi ra ngoài để các hàm khác dùng lại và không tự quản lý số dư nào. Quy tắc reentrancy của Slither báo có lỗi; GFD và hai biến thể ablation kết luận không lỗi, đúng với nhãn.
7. **Chỉ GFD đúng.** Hàm gửi tiền tới một địa chỉ bất kỳ, kèm dữ liệu gọi hàm do người gọi truyền vào. Slither không báo vì sau lệnh gửi tiền không có thao tác ghi trạng thái; bản bỏ ngữ nghĩa và CodeBERT gốc cũng bỏ sót.

**Tổng hợp trên toàn bộ tập kiểm thử.** Bảy hợp đồng trên là các trường hợp được chọn, không phải toàn cảnh. Số hợp đồng mà GFD và từng phương pháp bất đồng về đúng/sai:

| So với GFD | Timestamp: GFD đúng, phương pháp sai | Timestamp: GFD sai, phương pháp đúng | Reentrancy: GFD đúng, phương pháp sai | Reentrancy: GFD sai, phương pháp đúng |
|---|---|---|---|---|
| Bỏ ngữ nghĩa | 28 | 11 | 32 | 24 |
| CodeBERT gốc | 16 | 5 | 26 | 12 |
| Slither | 32 | 13 | 38 | 23 |

GFD kết luận sai 28/187 hợp đồng timestamp và 38/144 hợp đồng reentrancy. Một ví dụ: `simple_dao_fixed.sol` đã trừ số dư trước khi gọi `call.value`, nhưng cả ba biến thể học máy vẫn báo lỗi còn Slither thì không, vì mô hình nhận ra sự có mặt của `call.value` chứ không nhận ra thứ tự câu lệnh. Đây là lý do sản phẩm yêu cầu chuyên gia xác nhận ở mục 3.

---

## 2. Kiểm thử khả năng khái quát và ca khó

> **Vấn đề:** Lỗ hổng trên hợp đồng lớn hoặc mã cố tình gây nhiễu có thể khác benchmark.
>
> **Yêu cầu:** Thử dự án chưa thấy, hợp đồng lớn, mã đối kháng và ca dương/âm khó; phân tích cảnh báo nhầm/bỏ sót.
>
> **Minh chứng:** Bộ ví dụ mã, vị trí dòng và kết quả so với đánh giá chuyên môn.

### 2.1. Cách đánh giá và bộ ví dụ mã

**Tiêu chí đánh giá là F1, không chỉ recall.** Với hai lỗ hổng này, một bộ lọc cú pháp (báo lỗi mọi hợp đồng có `now`, `block.timestamp` hoặc `call.value`) đã đạt recall xấp xỉ 100%. Giá trị của mô hình nằm ở phần còn lại: phân biệt được hợp đồng có cú pháp nhạy cảm nhưng không có lỗ hổng. Vì vậy mọi phép thử dưới đây báo cả hai chiều, bỏ sót và cảnh báo nhầm.

**Hai nhóm dữ liệu kiểm thử.**

| Nhóm | Bộ mã | Nguồn nhãn chuyên môn | Quan hệ với dữ liệu huấn luyện |
|---|---|---|---|
| Cùng phân phối | Tập kiểm thử của bài báo: 193 hợp đồng timestamp, 147 hợp đồng reentrancy | Nhãn của bộ dữ liệu bài báo | Cùng nguồn, cùng phiên bản Solidity và cùng cách gán nhãn; không trùng hàm nào với tập huấn luyện |
| Hoàn toàn mới | DAppSCAN (IEEE TSE 2024): 36 file timestamp, 114 file reentrancy | Báo cáo audit của các công ty bảo mật, có tên hàm và số dòng (65 và 138 vị trí) | Khác nguồn, khác phiên bản Solidity, khác cách định nghĩa lỗ hổng |

Hợp đồng lớn, mã đối kháng và ca dương/âm khó được thử trên nhóm cùng phân phối, để đo đúng yếu tố cần đo mà không lẫn với khác biệt về dữ liệu. Dự án chưa thấy được thử trên nhóm hoàn toàn mới. Mọi hợp đồng đi qua đúng các bước của sản phẩm.

**Bộ ví dụ mã và kết quả từng ca** (tên file, hàm, vị trí dòng, kết luận của mô hình so với nhãn):

- `eval/ablation/runs/`: dự đoán từng hợp đồng trên tập kiểm thử của bài báo.
- `eval/generalization/results_adversarial.md`: từng hợp đồng đổi kết luận; mã gốc và mã biến đổi ở `eval/generalization/adversarial/`.
- `eval/generalization/results_dappscan.md`: từng vị trí audit của DAppSCAN; mã ở `eval/dappscan/flat/`.

### 2.2. Ca dương và ca âm khó

Ca âm khó là hợp đồng có chứa cú pháp nhạy cảm nhưng nhãn là không lỗi. Trong tập kiểm thử của bài báo có 32 ca như vậy ở timestamp và 73 ca ở reentrancy (toàn bộ hợp đồng không lỗi của reentrancy đều chứa `call.value`).

| Lỗ hổng | Hệ thống | Ca dương phát hiện được | Ca âm khó nhận đúng | Precision | Recall | F1 |
|---|---|---|---|---|---|---|
| Timestamp (128 hợp đồng có cú pháp) | GFD | 80/96 | 21/32 | 0,88 | 0,83 | 0,86 |
| | Bộ lọc cú pháp | 96/96 | 0/32 | 0,75 | 1,00 | 0,86 |
| | Slither | 74/96 | 7/32 | 0,75 | 0,77 | 0,76 |
| Reentrancy (144 hợp đồng có cú pháp) | GFD | 60/71 | 46/73 | 0,69 | 0,85 | 0,76 |
| | Bộ lọc cú pháp | 71/71 | 0/73 | 0,49 | 1,00 | 0,66 |
| | Slither (`reentrancy-eth`) | 32/71 | 59/73 | 0,70 | 0,45 | 0,55 |

- **GFD nhận đúng 21/32 và 46/73 ca âm khó**, trong khi bộ lọc cú pháp không nhận đúng ca nào. Đây là phần mà cú pháp đơn thuần không làm được.
- **Ở reentrancy, GFD có F1 cao nhất** (0,76 so với 0,66 và 0,55): giữ recall 0,85 mà precision cao hơn bộ lọc cú pháp 20 điểm.
- **Ở timestamp, F1 của GFD bằng bộ lọc cú pháp** (0,86), nhưng đạt được bằng precision cao hơn (0,88 so với 0,75) thay vì báo lỗi mọi hợp đồng.
- **Cảnh báo nhầm còn lại:** 11/32 (timestamp) và 27/73 (reentrancy) ca âm khó vẫn bị báo lỗi. **Bỏ sót:** 16/96 và 11/71 ca dương.

### 2.3. Hợp đồng lớn

Tập kiểm thử của bài báo được chia theo số dòng. Mô hình là GFD đầy đủ ở mục 1.

| Lỗ hổng | Kích thước | Hợp đồng | Số hàm (trung vị) | Accuracy | Có lỗi: phát hiện được | Không lỗi: nhận đúng | Giây/hợp đồng (trung vị / lớn nhất) |
|---|---|---|---|---|---|---|---|
| Timestamp | Dưới 200 dòng | 81 | 16 | 0,74 | 42/54 | 18/27 | 0,2 / 1,0 |
| Timestamp | 200–500 dòng | 98 | 55 | 0,95 | 34/37 | 59/61 | 0,9 / 3,7 |
| Timestamp | Trên 500 dòng | 8 | 109 | 0,75 | 4/5 | 2/3 | 1,7 / 9,8 |
| Reentrancy | Dưới 200 dòng | 68 | 18 | 0,75 | 29/37 | 22/31 | 0,2 / 1,0 |
| Reentrancy | 200–500 dòng | 50 | 43 | 0,76 | 18/20 | 20/30 | 0,5 / 1,4 |
| Reentrancy | Trên 500 dòng | 26 | 98 | 0,65 | 13/14 | 4/12 | 2,0 / 5,1 |

- **Kích thước không làm mô hình bỏ sót lỗi:** ở nhóm trên 500 dòng, mô hình phát hiện 4/5 (timestamp) và 13/14 (reentrancy) hợp đồng có lỗi. Hợp đồng lớn nhất của tập timestamp (`6454.sol`, 2.053 dòng, 328 hàm) được kết luận đúng.
- **Accuracy không giảm theo kích thước ở timestamp:** nhóm 200–500 dòng đạt 0,95, cao hơn nhóm dưới 200 dòng (0,74).
- **Thời gian vẫn thấp:** hợp đồng trên 500 dòng mất trung vị 1,7–2,0 giây, lâu nhất 9,8 giây.
- **Cảnh báo nhầm:** ở reentrancy, 8/12 hợp đồng lớn không lỗi bị báo lỗi, gồm bốn trong năm hợp đồng lớn nhất (1.934–2.101 dòng, hơn 300 hàm). Nhóm trên 500 dòng của timestamp chỉ có 8 hợp đồng, nên tỉ lệ ở đó mang tính chỉ báo.

### 2.4. Mã đối kháng

Năm phép biến đổi giữ nguyên ngữ nghĩa được áp dụng lên các hợp đồng kiểm thử mà mô hình vốn kết luận đúng (mẫu 80 hợp đồng mỗi lỗ hổng). Ngữ nghĩa không đổi nên nhãn gốc vẫn đúng. Sản phẩm loại comment khỏi mã hàm trước khi mã hoá, còn mã hiển thị cho người dùng giữ nguyên comment và số dòng.

| Lỗ hổng | Phép biến đổi | Có lỗi → bị bỏ sót | Không lỗi → bị cảnh báo |
|---|---|---|---|
| Timestamp | Đổi tên hàm | 0/34 | 2/32 |
| Timestamp | Chèn comment dài ở đầu hàm | 0/33 | 1/7 |
| Timestamp | Chèn mã chết | 0/27 | 0/6 |
| Timestamp | Hợp đồng mồi nhử nhắc từ khoá trong comment | 0/35 | 0/32 |
| Timestamp | Đọc thời gian qua hàm thư viện | 0/17 | 13/14 |
| Reentrancy | Chèn comment dài ở đầu hàm | 1/33 | 1/31 |
| Reentrancy | Chèn mã chết | 7/19 | 0/29 |
| Reentrancy | Hợp đồng mồi nhử nhắc từ khoá trong comment | 0/33 | 0/31 |

- **Mô hình giữ nguyên kết luận trong sáu trên tám phép thử:** đổi tên hàm, chèn comment dài, chèn mã chết (timestamp) và mồi nhử trong comment gần như không làm đổi kết luận ở cả hai chiều.
- **Không phép biến đổi nào che được lỗi ở timestamp:** số ca có lỗi bị bỏ sót là 0 trong cả năm phép.
- **Hai trường hợp còn đổi kết luận:**
  - Đọc thời gian qua hàm thư viện làm 13/14 hợp đồng timestamp không lỗi bị cảnh báo, vì phép này thêm vào file một hàm đọc `block.timestamp`.
  - Chèn mã chết làm 7/19 hợp đồng reentrancy có lỗi bị bỏ sót.

### 2.5. Dự án chưa thấy: bộ dữ liệu hoàn toàn mới

DAppSCAN khác dữ liệu huấn luyện ở ba điểm, nên kết quả ở mục này đo khoảng cách giữa hai loại dữ liệu nhiều hơn là đo khả năng của mô hình trong phạm vi nó được huấn luyện:

- **Phiên bản và cú pháp.** 95% dữ liệu huấn luyện là Solidity 0.4.x, trong đó reentrancy được nhận diện qua `call.value(...)`. Phần lớn DAppSCAN là Solidity 0.6–0.8, viết `call{value: ...}` hoặc gọi qua interface, và `now` đã bị bỏ từ 0.7.
- **Cấu trúc dự án.** Dữ liệu huấn luyện là hợp đồng một file; DAppSCAN là dự án nhiều file có import.
- **Định nghĩa nhãn.** Dữ liệu huấn luyện gán nhãn theo cú pháp của hai lỗ hổng. Nhãn audit rộng hơn (ví dụ reentrancy qua callback của token hoặc qua interface).

**Kết quả so với vị trí do auditor chỉ ra:**

| | Timestamp | Reentrancy |
|---|---|---|
| Số file / số file dựng được đồ thị | 36 / 17 | 114 / 71 |
| Riêng Solidity 0.8: dựng được đồ thị | 7/15 | 21/30 |
| Tỉ lệ hàm trùng nguyên văn với tập huấn luyện | 15,3% | 4,2% |
| Số vị trí audit | 65 | 138 |
| – nằm trong file không dựng được đồ thị | 36 | 53 |
| – phát hiện đúng hàm | 6 | 1 |
| – hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi | 8 | 0 |
| – bỏ sót | 12 | 83 |
| – dòng nằm ngoài mọi hàm | 3 | 1 |

Ví dụ phát hiện đúng, đối chiếu với dòng trong báo cáo audit:

- `wHakka.unstake`: audit chỉ dòng 580, mô hình gắn cờ hàm ở dòng 578–595 với xác suất 1,00.
- `Sliced.sendTokens`: audit chỉ dòng 72, mô hình gắn cờ đúng hàm.
- `OrderBook.cancelExpiredOrders`: audit chỉ dòng 145, mô hình gắn cờ với xác suất 0,90.

Phân tích bỏ sót:

- **89/203 vị trí không được chấm** vì file không dựng được đồ thị: bộ dữ liệu thiếu file import (33 file), chọn bản solc thấp nhất thoả `pragma` (13), file gộp không biên dịch (10), Slither 0.8.0 không đọc được cú pháp mới (5), thiếu bản solc (1). Đây là giới hạn của bước tiền xử lý với dự án nhiều file, không phải của mô hình.
- **Ở timestamp, mô hình mức hàm gắn cờ đúng 14/29 vị trí được chấm**; 8 vị trí trong số đó không hiển thị vì mô hình mức hợp đồng xếp hợp đồng là không lỗi (ví dụ `SamuraiLegendsStaking`).
- **Ở reentrancy, mô hình chỉ gắn cờ 2/71 hợp đồng** và bỏ sót 83 vị trí. Các hợp đồng này dùng cú pháp chuyển tiền không có trong dữ liệu huấn luyện, nên mô hình chưa từng thấy mẫu cần nhận diện.

Chia DAppSCAN (reentrancy) theo kích thước cho thấy kết quả thấp ở mọi nhóm, kể cả file nhỏ, tức nguyên nhân là khác biệt dữ liệu chứ không phải kích thước:

| Kích thước | File | Dựng được đồ thị | Số hàm (trung vị) | Giây/file (trung vị / lớn nhất) | Vị trí audit tìm được |
|---|---|---|---|---|---|
| Dưới 500 dòng | 18 | 9 | 29 | 1,0 / 3,3 | 1/9 |
| 500–2.000 dòng | 62 | 46 | 95 | 2,1 / 8,1 | 0/59 |
| Trên 2.000 dòng | 34 | 16 | 220 | 6,9 / 51,7 | 0/17 |

**Nhận định.** Trên dữ liệu cùng phân phối (mục 2.2 đến 2.4), mô hình giữ được F1 và phân biệt được ca âm khó. Kết quả thấp chỉ xuất hiện trên bộ dữ liệu hoàn toàn mới, nơi phiên bản Solidity, cấu trúc dự án và định nghĩa nhãn đều khác dữ liệu huấn luyện. Vì vậy đây là giới hạn về phạm vi dữ liệu huấn luyện: để áp dụng cho dự án Solidity từ 0.6 trở lên, mô hình cần được huấn luyện bổ sung với dữ liệu thuộc loại này.

---

## 3. Quy trình sửa lỗi có người xác nhận

> **Vấn đề:** Cảnh báo hoặc không có cảnh báo đều không đủ chứng minh hợp đồng an toàn.
>
> **Yêu cầu:** Đưa bằng chứng và dòng mã vào IDE/CI nếu khả thi; yêu cầu chuyên gia xác nhận cảnh báo và chạy biên dịch/kiểm thử khi đề xuất sửa, không tự khẳng định 'an toàn tuyệt đối'.
>
> **Minh chứng:** Demo phát hiện → giải thích → sửa → biên dịch/test và trường hợp cần rà soát thủ công.

### 3.1. Không khẳng định an toàn tuyệt đối

Kết quả ở mục 1 và mục 2 cho thấy cả cảnh báo lẫn việc không có cảnh báo đều không đủ để kết luận về an toàn. Vì vậy sản phẩm coi đầu ra của mô hình là manh mối cho con người, và mọi bước quyết định đều do chuyên gia thực hiện. Giao diện, bản xuất SARIF và lời giải thích của mô hình ngôn ngữ đều ghi rõ: cảnh báo cần chuyên gia xác nhận, và hợp đồng không bị cảnh báo vẫn cần audit thủ công.

### 3.2. Bằng chứng theo dòng mã trong IDE và CI

- **Giải thích có trích dòng.** Với mỗi hàm bị gắn cờ, mô hình ngôn ngữ nhận mã hàm đã đánh số dòng theo file gốc và phải trích đúng dòng làm bằng chứng, nêu tác động, và nêu những gì auditor còn phải kiểm tra. Prompt cấm khẳng định mã an toàn và yêu cầu nói rõ khi cảnh báo có vẻ là dương tính giả.
- **IDE trong trình duyệt.** Toàn bộ hợp đồng được mở trong trình soạn thảo, các hàm bị gắn cờ được tô trên đúng dòng, kèm lời giải thích khi rê chuột và ô để chuyên gia ghi kết luận.
- **CI và IDE bên ngoài.** Mỗi phiên phân tích xuất được ra SARIF 2.1.0, mở được trong VS Code và GitHub code scanning. Mỗi lỗ hổng có quy tắc riêng (`GFD-TS-*`, `GFD-RE-*`); mỗi kết quả mang dòng bắt đầu và kết thúc, kết luận của chuyên gia và trạng thái trong quy trình. Cảnh báo bị chuyên gia bác vẫn nằm trong file ở dạng đã suppress để lưu vết. Kho mã có sẵn một GitHub Action mẫu (`integrations/github-actions/scanguard.yml`).

### 3.3. Chuyên gia xác nhận cảnh báo

| Việc | Tài khoản thường | Tài khoản chuyên gia |
|---|---|---|
| Dùng trợ lý sửa mã cho hàm bị gắn cờ | được | được |
| Biên dịch và kiểm tra lại bản sửa | được | được |
| Ghi kết luận vào phần đánh giá của chuyên gia | không, chỉ xem | được |
| Chấp nhận hoặc từ chối bản sửa | không | được |

| Quy tắc (không phụ thuộc giao diện) | Kết quả khi vi phạm |
|---|---|
| Chỉ tài khoản chuyên gia được xác nhận hoặc bác bỏ cảnh báo | HTTP 403 |
| Chỉ chuyên gia được quyết định về bản sửa | HTTP 403 |
| Chỉ chấp nhận được bản sửa của cảnh báo đã được xác nhận | HTTP 409 |
| Chỉ chấp nhận được bản sửa đã biên dịch thành công | HTTP 409 |
| Quyết định chỉ áp dụng cho đúng bản sửa chuyên gia đã xem | HTTP 409 nếu bản sửa đã đổi |

### 3.4. Biên dịch và kiểm tra lại khi đề xuất sửa

- **Trợ lý sửa mã** nhận mã hàm, loại lỗ hổng, trạng thái xác nhận của chuyên gia và phiên bản `pragma` của hợp đồng, để bản sửa đúng cú pháp của trình biên dịch đang dùng.
- **Kiểm tra bản sửa.** Hệ thống ghép bản sửa vào đúng vị trí hàm trong hợp đồng gốc, biên dịch bằng bản solc theo `pragma`, rồi chạy toàn bộ detector của Slither trên bản gốc và bản đã sửa để so sánh số phát hiện trên các dòng của hàm.
- **Lưu vết.** Kết quả được lưu vào cảnh báo để chuyên gia duyệt đúng bản đã kiểm tra. Thông báo trả về luôn kèm câu: kết quả đạt không chứng minh bản sửa đúng.

### 3.5. Demo: phát hiện → giải thích → sửa → biên dịch/kiểm tra

Demo chạy bằng `demo/run_demo.py` trên hợp đồng `demo/EtherStore.sol`; bản ghi đầy đủ ở `demo/transcript.txt`. Script dừng với mã lỗi nếu một quy tắc ở mục 3.3 không được thực thi.

1. **Phát hiện.** Hai luồng chạy song song. Timestamp: hợp đồng bị gắn cờ (92%), hàm `withdrawFunds` dòng 9–16. Reentrancy: hợp đồng bị gắn cờ (84%), cùng hàm, xác suất 99,99%.
2. **Giải thích.** Với reentrancy, lời giải thích trích dòng 13 (lời gọi ngoài) đứng trước dòng 14 (cập nhật số dư). Với timestamp, nó trích dòng 12 (giới hạn rút theo tuần) và tự nhận định cảnh báo có vẻ là dương tính giả.
3. **Người dùng thường.** Thử xác nhận cảnh báo: bị từ chối (403). Đề xuất và kiểm tra một bản sửa trước khi có chuyên gia: bản sửa biên dịch được và được lưu, nhưng cảnh báo vẫn ở trạng thái chờ chuyên gia xét.
4. **Chuyên gia xét.** Cảnh báo reentrancy được xác nhận. Cảnh báo timestamp bị đánh dấu dương tính giả, vì độ lệch vài giây của thời gian khối không ảnh hưởng tới giới hạn một tuần.
5. **Sửa và biên dịch.** Một bản sửa hỏng không biên dịch được với solc 0.4.10; chuyên gia thử chấp nhận thì bị từ chối (409). Bản sửa đúng (cập nhật số dư trước khi chuyển tiền) biên dịch được và được lưu.
6. **Duyệt.** Người dùng thường thử chấp nhận: bị từ chối (403). Chuyên gia chấp nhận.
7. **Kết quả.** Reentrancy: bản sửa được chấp nhận. Timestamp: đã đóng, dương tính giả. SARIF ghi mức `error` cho cảnh báo đã xác nhận và `note` kèm suppress cho cảnh báo bị bác.

Ngoài script, luồng hội thoại thật với trợ lý sửa mã đã được kiểm thử qua giao diện bằng tài khoản thường: trợ lý trả lời trong khoảng 8 giây, bản sửa đầu tiên biên dịch được với solc 0.4.10, và một yêu cầu tiếp theo (giữ `call.value`, thêm khoá chống tái nhập) cũng cho bản sửa biên dịch được.

### 3.6. Các trường hợp cần rà soát thủ công

1. Hợp đồng không biên dịch được hoặc thiếu file import: luồng quét báo thất bại kèm lý do. Đã kiểm thử bằng một hợp đồng sai cú pháp.
2. Hợp đồng bị gắn cờ nhưng không hàm nào được định vị. Đã kiểm thử: với `simple_dao.sol`, luồng timestamp rơi vào trường hợp này trong khi luồng reentrancy định vị được hàm `withdraw`.
3. Chuyên gia chọn "cần rà soát thủ công" cho một cảnh báo hoặc một bản sửa.
4. Không có cảnh báo nào: giao diện và SARIF ghi rõ đây không phải bằng chứng an toàn.
5. Bản sửa đã được chấp nhận: vẫn cần bộ test của dự án và audit trước khi triển khai.

---

## 4. Hướng cải thiện

Phần này nêu các việc dự kiến làm tiếp, rút ra từ kết quả kiểm thử và đánh giá ở ba phần trên. Đây là kế hoạch, chưa được triển khai.

### 4.1. Thu thập thêm dữ liệu để huấn luyện mô hình

Mục 2.5 cho thấy mô hình hoạt động trong phạm vi dữ liệu nó được huấn luyện (hợp đồng một file, Solidity 0.4.x) và chưa nhận diện được lỗ hổng trong các dự án Solidity từ 0.6 trở lên. Hướng xử lý là mở rộng dữ liệu huấn luyện:

- **Bổ sung hợp đồng Solidity 0.6–0.8**, có cú pháp chuyển tiền mới (`call{value: ...}`, gọi qua interface) và các mẫu dùng thời gian khối hiện hành.
- **Bổ sung dự án nhiều file**, kèm bước gộp file theo thứ tự phụ thuộc, vì đây là dạng phổ biến của mã triển khai thực tế.
- **Bổ sung ca âm khó:** hợp đồng có cú pháp nhạy cảm nhưng không có lỗ hổng. Mục 2.2 cho thấy đây là nơi mô hình còn báo nhầm (11/32 và 27/73), và mục 2.3 cho thấy báo nhầm tăng ở hợp đồng reentrancy lớn.
- **Giữ nguyên tắc tách tập của bài báo:** không để hàm nào xuất hiện ở cả tập huấn luyện và tập kiểm thử, và giữ một bộ dự án đã audit làm tập kiểm thử độc lập, không dùng để huấn luyện.

### 4.2. Hệ thống tự cải thiện từ phản hồi của chuyên gia

Quy trình ở phần 3 đã lưu lại, cho từng cảnh báo, kết luận của chuyên gia (xác nhận, dương tính giả, cần rà soát thủ công) và bản sửa đã được biên dịch và duyệt. Mỗi kết luận như vậy là một nhãn do chuyên gia gán trên mã thật, nên có thể dùng lại theo vòng lặp sau:

1. **Thu nhận.** Mỗi cảnh báo đã có kết luận được ghi thành một mẫu: mã hàm, đồ thị gọi hàm, loại lỗ hổng, dự đoán của mô hình và nhãn của chuyên gia. Cảnh báo bị bác là ca âm khó; cảnh báo được xác nhận là ca dương đã kiểm chứng.
2. **Xây bộ đánh giá chuẩn.** Các mẫu này được gom thành một bộ dữ liệu có nhãn chuyên gia, lớn dần theo thời gian sử dụng. Một phần được giữ riêng làm tập kiểm thử, không bao giờ dùng để huấn luyện.
3. **Huấn luyện lại định kỳ.** Mô hình được huấn luyện lại với dữ liệu gốc cộng phần phản hồi dành cho huấn luyện.
4. **Chỉ thay mô hình khi tốt hơn.** Bản mới chỉ được đưa vào sử dụng nếu F1 theo từng lớp trên tập kiểm thử chuẩn và trên tập phản hồi giữ riêng không thấp hơn bản đang chạy.

Cần lưu ý hai điểm khi thiết kế vòng lặp này: người dùng phải đồng ý cho dùng mã của họ làm dữ liệu huấn luyện, và nhãn nên được ít nhất hai chuyên gia thống nhất trước khi đưa vào bộ đánh giá chuẩn.

### 4.3. Giảm dần mức phụ thuộc bắt buộc vào chuyên gia

Hiện tại mọi cảnh báo đều phải qua chuyên gia, vì kết quả đo cho thấy mô hình còn báo nhầm và bỏ sót. Khi bộ dữ liệu phản hồi đủ lớn để đo được độ tin cậy của mô hình, khối lượng việc của chuyên gia có thể giảm theo từng bước, mỗi bước chỉ được áp dụng khi số liệu cho phép:

- **Bước 1: sắp xếp thứ tự.** Cảnh báo được xếp theo xác suất của mô hình và theo lịch sử phản hồi, để chuyên gia xem trước các cảnh báo có khả năng đúng cao.
- **Bước 2: hiệu chỉnh độ tin cậy.** Xác suất của mô hình được hiệu chỉnh trên dữ liệu phản hồi, để con số 90% thực sự tương ứng với khoảng 90% cảnh báo được chuyên gia xác nhận.
- **Bước 3: xử lý tự động theo ngưỡng.** Với nhóm cảnh báo mà tỉ lệ đồng thuận giữa mô hình và chuyên gia vượt một ngưỡng đã định trên tập giữ riêng, chuyên gia chỉ cần kiểm tra theo mẫu thay vì xem từng cảnh báo.

Việc duyệt bản sửa trước khi triển khai và kết luận về mức an toàn của hợp đồng vẫn do con người thực hiện; mục tiêu là giảm khối lượng rà soát lặp lại của chuyên gia, không phải thay thế bước xác nhận.

