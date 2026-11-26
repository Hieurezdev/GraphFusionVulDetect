# Câu 1: benchmark và ablation (timestamp dependency)

Không huấn luyện gì: mọi biến thể dùng trọng số đang triển khai, ablation thực hiện lúc suy luận.
Tái hiện: lệnh docker ở đầu `run_ablation.py`; kết quả từng hợp đồng trong `results.jsonl`, số tổng hợp trong `summary.json`.

## Cấu hình

| | |
|---|---|
| gpu | NVIDIA L40S, 46068 MiB |
| cpu | INTEL(R) XEON(R) GOLD 6542Y |
| cores | 32 |
| encoder_device | cuda |
| gnn_device | cpu |
| torch | 2.8.0+cu128 |
| dgl | 2.1.0 |
| peak_rss_mb | 2473 |
| peak_gpu_mb | 980 |
| gnn_parameters | 6312386 |
| encoder_parameters | 124645632 |
| weights | src/infrastructure/analysis_model/best_model_GCN_2L_max.pt |
| encoder | Quangnguyen711/codebert-solidity-time-dep |
| base_encoder | microsoft/codebert-base |

## Thư mục Test: 187/193 hợp đồng chấm được bởi mọi biến thể (96 có lỗi, 91 không)

| Biến thể | P không lỗi | R không lỗi | F1 không lỗi | P có lỗi | R có lỗi | F1 có lỗi | Macro-F1 [KTC 95%] | Accuracy | GFD đúng, biến thể sai | GFD sai, biến thể đúng |
|---|---|---|---|---|---|---|---|---|---|---|
| GFD đầy đủ (bản triển khai) | 0.939 | 0.846 | 0.89 | 0.867 | 0.948 | 0.905 | 0.898 [0.85, 0.936] | 0.898 | 0 | 0 |
| Bỏ đồ thị (xoá cạnh FCG) | 0.927 | 0.56 | 0.699 | 0.697 | 0.958 | 0.807 | 0.753 [0.684, 0.812] | 0.765 | 30 | 5 |
| Bỏ ngữ nghĩa fine-tune (CodeBERT gốc) | 0 | 0 | 0 | 0.513 | 1 | 0.678 | 0.339 [0.307, 0.368] | 0.513 | 77 | 5 |
| Bỏ cả hai | 0 | 0 | 0 | 0.513 | 1 | 0.678 | 0.339 [0.307, 0.368] | 0.513 | 77 | 5 |
| Đặc trưng ngẫu nhiên (sàn) | 0 | 0 | 0 | 0.513 | 1 | 0.678 | 0.339 [0.307, 0.368] | 0.513 | 77 | 5 |
| Slither 0.8.0, detector timestamp | 0.75 | 0.725 | 0.737 | 0.747 | 0.771 | 0.759 | 0.748 [0.684, 0.806] | 0.749 | 36 | 8 |
| Từ khoá block.timestamp / now | 1 | 0.648 | 0.787 | 0.75 | 1 | 0.857 | 0.822 [0.763, 0.873] | 0.829 | 20 | 7 |

Thời gian mỗi hợp đồng (giây):

| Bước | Trung vị | p95 | Lớn nhất | Tổng |
|---|---|---|---|---|
| slither | 0.329 | 0.945 | 3.487 | 77 |
| graph_and_embed | 0.522 | 1.348 | 4.19 | 112.5 |
| base_embed | 0.189 | 0.399 | 1.557 | 37.6 |
| gnn | 0.036 | 0.1627 | 0.4619 | 10.9 |

Tập con khó (chỉ hợp đồng có từ khoá thời gian) và tập đã khử gần-trùng:

| Biến thể | Macro-F1 tập khó (n=128) | Macro-F1 khử gần-trùng (n=173) |
|---|---|---|
| GFD đầy đủ (bản triển khai) | 0.808 | 0.887 |
| Bỏ đồ thị (xoá cạnh FCG) | 0.758 | 0.789 |
| Slither 0.8.0, detector timestamp | 0.494 | 0.73 |

Hợp đồng đổi dự đoán khi bỏ đồ thị (35):

| File | Nhãn | GFD (p) | Bỏ đồ thị (p) | Số hàm | Số cạnh |
|---|---|---|---|---|---|
| Test/NonVulnerable/0x1b5d56bfe749e492ae226cf9aa23c1426f828b7b.sol | 0 | 0 (0.171) | 1 (0.629) | 59 | 39 |
| Test/NonVulnerable/0x2285b7f262c741e9c555ab7df9009b87c29353cf.sol | 0 | 0 (0.17) | 1 (0.6297) | 59 | 39 |
| Test/NonVulnerable/0x34d264fadcae674c4aaea6d795b4d1448feb038b.sol | 0 | 1 (0.5974) | 0 (0.4499) | 23 | 10 |
| Test/NonVulnerable/0x3597bfd533a99c9aa083587b074434e61eb0a258.sol | 0 | 0 (0.1271) | 1 (0.5744) | 65 | 42 |
| Test/NonVulnerable/0x3d1ba9be9f66b8ee101911bc36d3fb562eac2244.sol | 0 | 0 (0.1271) | 1 (0.5744) | 65 | 42 |
| Test/NonVulnerable/0x40f4d25fb85ea9c4fc4a82e8234664108b20e2cb.sol | 0 | 0 (0.1886) | 1 (0.6323) | 61 | 44 |
| Test/NonVulnerable/0x5af2be193a6abca9c8817001f45744777db30756.sol | 0 | 0 (0.1137) | 1 (0.5711) | 62 | 41 |
| Test/NonVulnerable/0x5e6c3565c2a7b048f22e62e41fc829811d8de2ba.sol | 0 | 0 (0.4916) | 1 (0.5318) | 15 | 8 |
| Test/NonVulnerable/0x71d6a613af53a0c057f2d6833dc9ade678243267.sol | 0 | 0 (0.1756) | 1 (0.6311) | 58 | 38 |
| Test/NonVulnerable/0x8ae4bf2c33a8e667de34b54938b0ccd03eb8cc06.sol | 0 | 0 (0.2082) | 1 (0.635) | 63 | 45 |
| Test/NonVulnerable/0xa645264c5603e96c3b0b078cdab68733794b0a71.sol | 0 | 0 (0.1867) | 1 (0.6306) | 63 | 44 |
| Test/NonVulnerable/0xafcb18e95b10a18baeaf69baac1ac610df9f7d12.sol | 0 | 0 (0.4181) | 1 (0.7824) | 55 | 35 |
| Test/NonVulnerable/0xb04cfa8a26d602fb50232cee0daf29060264e04b.sol | 0 | 0 (0.1895) | 1 (0.6324) | 61 | 44 |
| Test/NonVulnerable/0xb2e59493763d0d0be2634b2d1afe066914b0fcc2.sol | 0 | 0 (0.1137) | 1 (0.5711) | 62 | 41 |
| Test/NonVulnerable/0xb62132e35a6c13ee1ee0f84dc5d40bad8d815206.sol | 0 | 0 (0.3073) | 1 (0.6205) | 45 | 35 |
| Test/NonVulnerable/0xb63b606ac810a52cca15e44bb630fd42d8d1d83d.sol | 0 | 0 (0.1137) | 1 (0.5711) | 62 | 41 |
| Test/NonVulnerable/0xc13dfb79ad78ea5dab5452299730431771802fc4.sol | 0 | 0 (0.3193) | 1 (0.6241) | 45 | 35 |
| Test/NonVulnerable/0xd14ccc72df063db59386c371e00292ca529400ac.sol | 0 | 0 (0.215) | 1 (0.6368) | 67 | 47 |
| Test/NonVulnerable/0xd2e559d39935110df3ac7e77727dc8cd88416b34.sol | 0 | 0 (0.2145) | 1 (0.6367) | 65 | 46 |
| Test/NonVulnerable/0xdd14691a124125f55956a6992df1c22fbc604a66.sol | 0 | 0 (0.2082) | 1 (0.635) | 63 | 45 |
| Test/NonVulnerable/0xf12e01c57602972302a160159c92a103ed15f171.sol | 0 | 0 (0.1886) | 1 (0.6323) | 61 | 44 |
| Test/NonVulnerable/0xf221e4dd78c08177311dec144b674b04f3b9176e.sol | 0 | 0 (0.3193) | 1 (0.6241) | 45 | 35 |
| Test/NonVulnerable/0xf53900aa32417ebb42cb182e08e0a7791da4fc7c.sol | 0 | 0 (0.4337) | 1 (0.6815) | 20 | 10 |
| Test/NonVulnerable/0xf68f16a1ea80665e0548d9fcfee435b82e92a5cc.sol | 0 | 0 (0.1271) | 1 (0.5744) | 65 | 42 |
| Test/NonVulnerable/0xf9ebc3598946e4d9fa7ebee011c8a3e2eb6715ba.sol | 0 | 0 (0.1756) | 1 (0.6311) | 58 | 38 |
| Test/NonVulnerable/0xfca47962d45adfdfd1ab2d972315db4ce7ccf094.sol | 0 | 0 (0.1174) | 1 (0.5731) | 61 | 40 |
| Test/NonVulnerable/0xfe022ed8253d921f42c980205f5a7e644fbddaa8.sol | 0 | 0 (0.1174) | 1 (0.5731) | 61 | 40 |
| Test/NonVulnerable/0xff7e960888ac6092d7b908e32750e54a16864997.sol | 0 | 0 (0.2145) | 1 (0.6367) | 65 | 46 |
| Test/NonVulnerable/11775.sol | 0 | 0 (0.4924) | 1 (0.5371) | 94 | 70 |
| Test/NonVulnerable/1518.sol | 0 | 1 (0.8298) | 0 (0.4648) | 56 | 44 |
| Test/Vulnerable/0x2e2e617e4625c6a30a3290dde5b689212ff061e8.sol | 1 | 0 (0.3401) | 1 (0.7606) | 15 | 5 |
| Test/Vulnerable/0x34a3deb32b4705018f1e543a5867cf01aff3f15b.sol | 1 | 0 (0.3547) | 1 (0.8871) | 48 | 25 |
| Test/Vulnerable/0x3d11a869c9a97c1c9c6a0ce058a98db20bb753db.sol | 1 | 1 (0.7964) | 0 (0.4793) | 27 | 13 |
| Test/Vulnerable/0x4a0a5236e4d1ae19fc00c167e1d33f37870f53b1.sol | 1 | 0 (0.3128) | 1 (0.5575) | 40 | 22 |
| Test/Vulnerable/11191.sol | 1 | 1 (0.9148) | 0 (0.2979) | 26 | 49 |

## Thư mục Train: 99/101 hợp đồng chấm được bởi mọi biến thể (50 có lỗi, 49 không)

| Biến thể | P không lỗi | R không lỗi | F1 không lỗi | P có lỗi | R có lỗi | F1 có lỗi | Macro-F1 [KTC 95%] | Accuracy | GFD đúng, biến thể sai | GFD sai, biến thể đúng |
|---|---|---|---|---|---|---|---|---|---|---|
| GFD đầy đủ (bản triển khai) | 0.968 | 0.612 | 0.75 | 0.721 | 0.98 | 0.831 | 0.79 [0.703, 0.867] | 0.798 | 0 | 0 |
| Bỏ đồ thị (xoá cạnh FCG) | 0.933 | 0.571 | 0.709 | 0.696 | 0.96 | 0.807 | 0.758 [0.667, 0.837] | 0.768 | 5 | 2 |
| Bỏ ngữ nghĩa fine-tune (CodeBERT gốc) | 0 | 0 | 0 | 0.505 | 1 | 0.671 | 0.336 [0.288, 0.377] | 0.505 | 30 | 1 |
| Bỏ cả hai | 0 | 0 | 0 | 0.505 | 1 | 0.671 | 0.336 [0.288, 0.377] | 0.505 | 30 | 1 |
| Đặc trưng ngẫu nhiên (sàn) | 0 | 0 | 0 | 0.505 | 1 | 0.671 | 0.336 [0.288, 0.377] | 0.505 | 30 | 1 |
| Slither 0.8.0, detector timestamp | 0.5 | 0.224 | 0.31 | 0.506 | 0.78 | 0.614 | 0.462 [0.359, 0.556] | 0.505 | 37 | 8 |
| Từ khoá block.timestamp / now | 1 | 0.061 | 0.115 | 0.521 | 1 | 0.685 | 0.4 [0.327, 0.481] | 0.535 | 27 | 1 |

Thời gian mỗi hợp đồng (giây):

| Bước | Trung vị | p95 | Lớn nhất | Tổng |
|---|---|---|---|---|
| slither | 0.337 | 1.312 | 3.255 | 50.8 |
| graph_and_embed | 0.482 | 1.959 | 4.177 | 70.7 |
| base_embed | 0.172 | 0.774 | 0.875 | 22.7 |
| gnn | 0.0472 | 0.1492 | 0.1795 | 5.9 |

Tập con khó (chỉ hợp đồng có từ khoá thời gian) và tập đã khử gần-trùng:

| Biến thể | Macro-F1 tập khó (n=96) | Macro-F1 khử gần-trùng (n=97) |
|---|---|---|
| GFD đầy đủ (bản triển khai) | 0.78 | 0.784 |
| Bỏ đồ thị (xoá cạnh FCG) | 0.746 | 0.75 |
| Slither 0.8.0, detector timestamp | 0.43 | 0.472 |

Hợp đồng đổi dự đoán khi bỏ đồ thị (7):

| File | Nhãn | GFD (p) | Bỏ đồ thị (p) | Số hàm | Số cạnh |
|---|---|---|---|---|---|
| Train/NonVulnerable/0xf297d09924f8fd807bdb0d9fb47b52f6826c70b1.sol | 0 | 0 (0.1867) | 1 (0.8945) | 18 | 16 |
| Train/NonVulnerable/0xf50400935bec25cf89031146b8604371197f2cae.sol | 0 | 0 (0.2046) | 1 (0.6487) | 33 | 22 |
| Train/NonVulnerable/11323.sol | 0 | 1 (0.6769) | 0 (0.452) | 29 | 20 |
| Train/NonVulnerable/15.sol | 0 | 0 (0.3128) | 1 (0.7559) | 50 | 43 |
| Train/NonVulnerable/16590.sol | 0 | 1 (0.5378) | 0 (0.44) | 144 | 109 |
| Train/NonVulnerable/6929.sol | 0 | 0 (0.4865) | 1 (0.6617) | 31 | 16 |
| Train/Vulnerable/22273.sol | 1 | 1 (0.8068) | 0 (0.4864) | 52 | 40 |

## Giới hạn

- Ablation lúc suy luận đo mức mô hình đã huấn luyện phụ thuộc vào từng thành phần, không đo một mô hình được huấn luyện lại thiếu thành phần đó.
- Không rõ checkpoint được huấn luyện trên thư mục nào; kết quả ở thư mục Test cao hơn Train.
- Chỉ timestamp dependency; chưa có checkpoint reentrancy.
