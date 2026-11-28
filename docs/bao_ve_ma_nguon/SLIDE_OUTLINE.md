# Dàn ý trình bày: Bảo vệ mã nguồn tải lên

Thời lượng khoảng 5 phút, 7 slide.

## Slide 1. Đề bài và kết quả

- Vấn đề: hợp đồng chưa công bố có thể chứa thông tin cần bảo vệ.
- Ba yêu cầu: giới hạn quyền, thời gian lưu, khả năng xóa; mô tả xử lý tại máy chủ và dịch vụ ngoài.
- Cả ba yêu cầu và ba minh chứng đã hoàn thành, chạy trên production.

Hình: bảng đối chiếu ở mục 1 của báo cáo.

Lời nói: "Đề yêu cầu ba việc và ba minh chứng. Nhóm đã làm đủ, và mọi thứ em trình bày hôm nay đang chạy trên scanguard.ptitai.org."

## Slide 2. Mã nguồn đi đâu

- Tệp `.sol` đầy đủ chỉ nằm trên máy chủ ScanGuard.
- Mọi yêu cầu đi qua cổng kiểm soát quyền; người ngoài nhận 404.
- Chỉ mã hàm bị gắn cờ được gửi tới LLM ngoài; Admin tắt được.

Hình: `so-do-luong-xu-ly.png`

Lời nói: "Từ trái sang phải: người dùng tải mã qua HTTPS, đi qua cổng kiểm soát quyền màu cam, được phân tích và lưu ngay tại máy chủ. Thứ duy nhất có thể rời máy chủ là đoạn mã của hàm bị gắn cờ, và Admin có thể tắt hẳn luồng đó."

## Slide 3. Ai được làm gì

- Bốn vai trò: Admin, Developer, Non-tech, Expert.
- Developer và Non-tech chỉ thấy mã của chính mình.
- Quyền được kiểm tra ở máy chủ; đổi vai trò thì phiên cũ hết hiệu lực ngay.

Hình: bảng quyền (mục 3.3) và ảnh `06-admin-members.png`

Lời nói: "Bảng quyền nằm ở một chỗ trong mã nguồn và máy chủ kiểm tra ở mọi API, nên ẩn nút trên giao diện không phải là lớp bảo vệ duy nhất."

## Slide 4. Thời gian lưu

- Mặc định 30 ngày, Admin chỉnh từ 1 đến 365 ngày.
- Tác vụ nền mỗi giờ tự xóa lượt quét quá hạn.
- Người dùng thấy ngày tự xóa trên từng kết quả.

Hình: `07-admin-policy.png`

Lời nói: "Mỗi lượt quét có ngày hết hạn. Đến hạn, hệ thống tự xóa mà không cần ai bấm nút."

## Slide 5. Một hàm xóa cho mọi nơi lưu mã

- Xóa tay và hết hạn dùng chung một hàm.
- Mã bị xóa ở bốn nơi: thư mục, MongoDB, kho tri thức, nhật ký nhãn.
- Lịch sử xóa ghi ai, khi nào, lý do; không chứa mã.

Hình: `so-do-luong-xoa.png`

Lời nói: "Dù người dùng bấm xóa hay hết thời hạn lưu, mọi lệnh xóa đều đi qua một hàm duy nhất. Nhờ vậy không có nơi nào bị sót mã."

## Slide 6. Demo xóa tệp

- Trước khi xóa: API trả 200, thư mục còn.
- Sau khi xóa: API trả 404, thư mục không còn, lịch sử xóa ghi 5 tệp.
- Người ngoài doanh nghiệp và Developer khác đều nhận 404.

Hình: `09-delete-confirm.png` và `10-admin-deletions.png`

Lời nói: "Đây là kịch bản tự động trên trình duyệt. Sau khi Admin xác nhận xóa, gọi lại API thì nhận 404 và thư mục lưu tệp đã biến mất."

## Slide 7. Kiểm thử và giới hạn

- 81/81 bài kiểm thử backend đạt; bộ bảo vệ mã chạy trên MongoDB thật.
- Giới hạn: LLM ngoài mặc định bật; bản sao lưu chưa xoay vòng; chưa mã hóa khi lưu.
- Hướng tiếp: mặc định tắt LLM ngoài, sao lưu xoay vòng, mã hóa ổ đĩa.

Hình: bảng ở mục 10 của báo cáo.

Lời nói: "Nhóm đã kiểm thử tự động toàn bộ luồng này. Ba giới hạn còn lại đã có hướng xử lý cụ thể."
