# Hướng dẫn sử dụng ScanGuard 

ScanGuard giúp bạn **kiểm tra một hợp đồng thông minh trước khi tin dùng** (ví dụ trước khi gửi tiền vào một token hay một dự án). Bạn không cần biết lập trình, không cần cài đặt gì, chỉ cần trình duyệt web.

Địa chỉ: **https://scanguard.ptitai.org**

> **Điều quan trọng nhất cần nhớ:** kết quả của ScanGuard là **gợi ý để xem xét thêm**, không phải giấy chứng nhận an toàn.
> - Có cảnh báo **không có nghĩa** hợp đồng chắc chắn lừa đảo.
> - Không có cảnh báo **không có nghĩa** hợp đồng an toàn.
>
> Trước khi bỏ nhiều tiền, hãy tìm báo cáo kiểm toán (audit) độc lập của dự án.

---

## 1. ScanGuard kiểm tra những gì?

Công cụ tìm hai loại lỗi đã biết trong hợp đồng thông minh trên mạng **Ethereum**:

| Loại lỗi | Giải thích đơn giản |
|---|---|
| **Phụ thuộc thời gian (timestamp)** | Hợp đồng dựa vào "đồng hồ" của khối để quyết định ai được trả tiền hoặc ai thắng. Người tạo khối có thể chỉnh đồng hồ này vài giây để trục lợi. |
| **Gọi lại (reentrancy)** | Hợp đồng gửi tiền đi *trước khi* ghi sổ. Kẻ xấu có thể "gọi lại" liên tục để rút tiền nhiều lần, giống lỗi đã làm mất hàng chục triệu USD trong vụ The DAO năm 2016. |

ScanGuard **không** kiểm tra các rủi ro khác như chủ dự án bỏ trốn, giá token sụp, hay các loại lỗi khác ngoài hai loại trên.

## 2. Tạo tài khoản và đăng nhập

1. Mở https://scanguard.ptitai.org, bấm **Đăng nhập**.
2. Chưa có tài khoản thì bấm **Tạo tài khoản**, rồi điền:
   - **Tên đăng nhập:** chỉ gồm chữ, số và các dấu `_` `.` `-` (không dùng dấu `@`).
   - **Email.**
   - **Mật khẩu:** ít nhất 6 ký tự.
3. Lần sau, bạn đăng nhập bằng **email** hoặc **tên đăng nhập** đều được.

Muốn đổi giao diện sang tiếng Việt: bấm vào ảnh đại diện ở góc phải trên → **Cài đặt** → **Ngôn ngữ**.

> Phiên đăng nhập tự hết hạn sau 30 phút. Nếu đang dùng mà bị đưa về trang đăng nhập, chỉ cần đăng nhập lại.

## 3. Kiểm tra một hợp đồng

Bấm **Phân tích mới** trên thanh menu. Có hai cách.

### Cách A: Tìm theo tên token (dễ nhất, không cần file)

1. Chọn thẻ **Tìm token**.
2. Gõ tên hoặc ký hiệu của token, ví dụ `Uniswap` hoặc `UNI`, rồi bấm tìm.
3. Bấm vào đúng token trong danh sách kết quả.
4. Ở ô **Chọn chain**, chọn **ethereum**.
5. Bấm **Bắt đầu phân tích**.

ScanGuard tự lấy mã nguồn đã công khai của token về để kiểm tra.

Có thể gặp các thông báo sau:
- *"Token này không có hợp đồng trên Ethereum…"*: token đó nằm trên mạng khác (BNB Chain, Solana…), hiện chưa hỗ trợ.
- *"Mã nguồn của hợp đồng này chưa được công khai…"*: chủ dự án không công bố mã nguồn, nên không kiểm tra được. Bản thân điều này đã là **một dấu hiệu nên thận trọng**.
- *"Danh mục token đang quá tải…"*: chờ khoảng một phút rồi thử lại.

### Cách B: Tải lên file mã nguồn

Dùng khi bạn có sẵn file hợp đồng (đuôi `.sol`, tối đa 10 MB), ví dụ do đội phát triển gửi.

1. Chọn thẻ **Tải file lên**.
2. Kéo thả file vào ô, hoặc bấm để chọn file.
3. Bấm **Bắt đầu phân tích**.

### Trong lúc chờ

Kết quả hiện dần theo từng bước, thường mất từ **vài giây đến khoảng một phút**. Hợp đồng lớn hoặc lúc nhiều người dùng cùng lúc có thể lâu hơn. Đừng đóng trang khi đang phân tích: đóng giữa chừng thì phân tích bị dừng và bạn phải chạy lại.

## 4. Đọc kết quả

### Phần "Kết luận" ở đầu trang

Đây là phần **quan trọng nhất** với người không đọc code. Phần này cho biết:
- Có loại lỗi nào bị phát hiện không.
- Với mỗi loại lỗi:
  - **Bị gắn cờ**: mô hình nghi ngờ có lỗi loại này.
  - **Không bị gắn cờ**: mô hình không thấy dấu hiệu, nhưng vẫn không phải bảo đảm an toàn.
  - **Độ tin cậy của mô hình** (ví dụ 88%): mô hình chắc chắn đến mức nào. Con số này **không phải** là xác suất hợp đồng bị hack.
- Một câu khuyên dành cho người không đọc code. Ví dụ: *"hãy coi đây là lý do để tìm báo cáo kiểm toán độc lập trước khi bỏ tiền vào"*.

### Các phần chi tiết bên dưới

Phần dưới dành cho người có chuyên môn: danh sách từng **hàm** (đoạn chức năng trong hợp đồng) bị gắn cờ, có số dòng, lời giải thích và trình soạn thảo mã nguồn (**IDE hợp đồng**). Trong IDE, những dòng có vấn đề được **tô đỏ**. Bạn có thể bỏ qua phần này, hoặc gửi đường dẫn cho người có chuyên môn xem giúp.

### Trạng thái của từng cảnh báo

Mỗi cảnh báo cần được một **chuyên gia** xem lại. Trạng thái bạn có thể thấy:

| Trạng thái | Ý nghĩa |
|---|---|
| **Chờ chuyên gia xác nhận** | Chưa ai xem. Hãy coi cảnh báo là *chưa chắc chắn*. |
| **Chuyên gia đã xác nhận** | Chuyên gia đồng ý đây là lỗi thật. **Nên thận trọng.** |
| **Báo nhầm** | Chuyên gia kết luận mô hình báo sai. |
| **Cần rà soát thủ công** | Chuyên gia chưa kết luận được, cần kiểm tra kỹ hơn. |

## 5. Xem lại các lần kiểm tra trước

Bấm **Dự án** trên thanh menu. Mỗi lần phân tích được lưu trong **Lịch sử phân tích**, bấm vào để xem lại kết quả. Khi chuyên gia đã xem xét, trạng thái của cảnh báo sẽ được cập nhật tại đây.

## 6. Dành cho tài khoản chuyên gia

Tài khoản chuyên gia do quản trị viên cấp; người dùng không tự chuyển được. Chuyên gia có thêm mục **Chuyên gia rà soát** trên thanh menu:

1. Bên trái là danh sách các lần phân tích có cảnh báo, kèm số cảnh báo còn chờ xem.
2. Chọn một lần phân tích, đọc lời giải thích và đoạn mã của từng hàm bị gắn cờ.
3. Ghi chú lý do (không bắt buộc), rồi chọn **Chuyên gia đã xác nhận**, **Báo nhầm** hoặc **Cần rà soát thủ công**.
4. Khi chủ hợp đồng đã đề xuất bản sửa và bản sửa biên dịch được, chuyên gia duyệt nó trong bảng **Quy trình sửa lỗi**.

## 7. Câu hỏi thường gặp

**Kết quả "Không bị gắn cờ" nghĩa là tôi yên tâm đầu tư được không?**
Không. Công cụ chỉ kiểm tra hai loại lỗi và có thể bỏ sót. Đây chỉ là một bước sàng lọc ban đầu.

**Có cảnh báo nghĩa là dự án lừa đảo?**
Không hẳn. Mô hình có thể báo nhầm. Hãy chờ chuyên gia xác nhận, hoặc hỏi đội dự án về điểm bị gắn cờ.

**Tôi tải file lên, thông báo "không dựng được đồ thị lời gọi…" là sao?**
File không biên dịch được với phiên bản ngôn ngữ ghi trong file, file tham chiếu tới file khác mà bạn không tải lên, hoặc file dùng tính năng quá mới. Trường hợp này cần người có chuyên môn kiểm tra trực tiếp.

**Báo lỗi "quá nhiều yêu cầu" (429)?**
Hệ thống giới hạn số lần thao tác mỗi phút để tránh quá tải. Chờ khoảng một phút rồi thử lại.

**Dữ liệu của tôi có bị người khác xem không?**
Người dùng khác **không** xem được các lần phân tích của bạn. Chỉ tài khoản chuyên gia xem được, để xác nhận cảnh báo. Vì vậy đừng tải lên mã nguồn bí mật mà bạn không muốn chuyên gia của hệ thống đọc.

**Quên mật khẩu thì sao?**
Hiện chưa có chức năng tự lấy lại mật khẩu. Hãy liên hệ quản trị viên. Khi đã đăng nhập, bạn có thể đổi mật khẩu ở menu ảnh đại diện → **Bảo mật**.

## 8. Cần hỗ trợ?

Liên hệ quản trị viên hệ thống hoặc nhóm phát triển. Khi báo lỗi, hãy gửi kèm:
- tên token hoặc file đã kiểm tra;
- thời điểm;
- ảnh chụp màn hình thông báo lỗi.
