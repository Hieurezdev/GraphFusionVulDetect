# Điều khoản sử dụng và giấy phép phần mềm

## 1. Dịch vụ

ScanGuard phân tích mã nguồn hợp đồng thông minh Solidity để phát hiện các dấu hiệu lỗ hổng phụ thuộc thời gian khối (timestamp dependency) và tái nhập (reentrancy), giải thích cảnh báo và hỗ trợ sửa lỗi.

## 2. Giới hạn của kết quả

- Kết quả do mô hình học máy và công cụ phân tích tĩnh tạo ra. Chúng là cảnh báo cần chuyên gia xác nhận, không phải kết luận về mức an toàn.
- Việc không có cảnh báo **không** có nghĩa là hợp đồng an toàn. Hệ thống không thay thế một cuộc kiểm toán bảo mật đầy đủ.
- Bản sửa do trợ lý hoặc repair agent đề xuất phải được chuyên gia duyệt và được kiểm thử bằng bộ test của chính dự án trước khi triển khai.

## 3. Giấy phép sử dụng phần mềm

- Người dùng được cấp quyền sử dụng không độc quyền, không chuyển nhượng đối với dịch vụ trong thời gian tài khoản còn hiệu lực.
- Người dùng không được dò quét, tấn công, vượt qua cơ chế phân quyền của hệ thống, hoặc dùng dịch vụ để phân tích mã mà mình không có quyền sử dụng.
- Báo cáo, tệp SARIF và bản sửa tạo ra từ mã của người dùng thuộc về người dùng (hoặc doanh nghiệp của người dùng).

## 4. Tài khoản và vai trò

- Mỗi tài khoản thuộc một không gian làm việc: không gian cá nhân (khách) hoặc không gian của một doanh nghiệp. Admin của doanh nghiệp quản lý thành viên, vai trò và chính sách dữ liệu.
- Người dùng chịu trách nhiệm giữ bí mật mật khẩu và các thao tác thực hiện bằng tài khoản của mình.

## 5. Chấm dứt

Người dùng có thể xóa tài khoản bất cứ lúc nào trong mục Quyền riêng tư. ScanGuard có thể khóa tài khoản vi phạm mục 3.

## 6. Thay đổi điều khoản

Khi điều khoản thay đổi, phiên bản mới được hiển thị và người dùng phải xác nhận lại ở lần đăng nhập kế tiếp.
