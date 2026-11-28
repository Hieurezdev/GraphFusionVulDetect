# Chính sách xử lý dữ liệu cá nhân và mã nguồn

## 1. Dữ liệu cá nhân được thu thập

| Dữ liệu | Mục đích |
|---|---|
| Email, tên đăng nhập | Đăng nhập, phân quyền |
| Họ tên (không bắt buộc) | Hiển thị trong doanh nghiệp và trên kết luận rà soát |
| Thời điểm đăng nhập, các thao tác trên mã (xem mã, xóa, đổi vai trò) | Nhật ký kiểm toán cho Admin của doanh nghiệp |

Thông tin cá nhân **không** được gửi tới dịch vụ bên ngoài. Chuyên gia rà soát thấy tên người gửi yêu cầu rà soát, không thấy email.

## 2. Mã nguồn tải lên

- Mã được lưu trên máy chủ ScanGuard: tệp gốc và đồ thị trong thư mục lưu trữ, kết quả quét trong cơ sở dữ liệu.
- Mô hình phát hiện lỗ hổng (Slither, CodeBERT, GNN) chạy hoàn toàn trên máy chủ ScanGuard.
- **Dịch vụ LLM bên ngoài:** khi Admin của doanh nghiệp cho phép, mã của từng hàm bị gắn cờ (không phải toàn bộ tệp) được gửi tới dịch vụ LLM mà máy chủ được cấu hình để tạo giải thích và gợi ý sửa lỗi. Khi Admin tắt, các tính năng này dùng mô hình chạy trên máy chủ hoặc bị tắt.
- Tra cứu token chỉ gửi tên token và địa chỉ hợp đồng (dữ liệu công khai) tới CoinGecko và Etherscan.

## 3. Ai được xem mã

- Thành viên của không gian làm việc, theo vai trò của họ.
- Chuyên gia của ScanGuard chỉ xem được một lần quét khi doanh nghiệp cho phép và người dùng đã gửi yêu cầu rà soát lần quét đó.
- Mỗi lần mở mã nguồn đều được ghi vào nhật ký kiểm toán của doanh nghiệp.

## 4. Thời gian lưu và xóa

- Mã và kết quả quét được tự động xóa sau thời hạn lưu do Admin đặt (mặc định 30 ngày).
- Người dùng có quyền có thể xóa một lần quét hoặc một dự án bất cứ lúc nào; việc xóa gỡ tệp, kết quả và mục trong kho tri thức, và tẩy mã khỏi nhật ký nhãn.
- Nhật ký nhãn giữ lại kết luận của chuyên gia (không kèm mã) để bảo đảm tính toàn vẹn của dữ liệu huấn luyện.

## 5. Dữ liệu huấn luyện

Chỉ khi doanh nghiệp đồng ý (xem văn bản "Cho dùng mã làm dữ liệu huấn luyện").

## 6. Quyền của người dùng

Người dùng có quyền xem văn bản này bất cứ lúc nào, rút lại đồng ý cho dùng dữ liệu huấn luyện, và xóa tài khoản. Khi xóa tài khoản, thông tin cá nhân bị xóa và tên trên các kết luận rà soát được thay bằng mã ẩn danh.
