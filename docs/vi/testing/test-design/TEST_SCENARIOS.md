# KỊCH BẢN KIỂM THỬ TỔNG QUAN (TEST SCENARIOS SPECIFICATION)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Tập trung:** 02 Chức năng Cốt lõi (Function A: Registration & Team Recruitment; Function B: Multi-modal Check-in)  
**Người lập:** QA Testing Architect (Solo Developer)  
**Ngày cập nhật:** 15/10/2026  

---

## 1. DANH MỤC KỊCH BẢN KIỂM THỬ CHO CHỨC NĂNG A: ĐĂNG KÝ GIẢI ĐẤU & TUYỂN QUÂN

| Mã Kịch bản (Scenario ID) | Tên Kịch bản Kiểm thử (Test Scenario Title) | Mô tả Ngữ cảnh Nghiệp vụ | Mức độ Ưu tiên | Tầng Kiểm thử (Tier) |
|---|---|---|:---:|:---:|
| **TS-REG-01** | Đăng ký giải đấu cá nhân thành công với biểu mẫu động hợp lệ | Thí sinh đã duyệt KYC nộp đơn đăng ký cho bộ môn thi đấu cá nhân (TFT/Solo) với các trường in-game hợp lệ. | High | Unit, API, Web UI |
| **TS-REG-02** | Khởi tạo đội thi đấu và bật chế độ tuyển quân thành công | Đội trưởng đã duyệt KYC tạo đội thi đấu đồng đội, nộp đơn thành công và bật cờ `is_recruiting = true`. | High | API, Web UI |
| **TS-REG-03** | Chặn đăng ký khi giải đấu chưa mở hoặc đã đóng cổng | Thí sinh cố tình gọi API đăng ký khi giải đấu ở trạng thái `draft`, `closed_registration` hoặc `ongoing`. | High | API, Web UI |
| **TS-REG-04** | Chặn tài khoản chưa được phê duyệt KYC tham gia đăng ký giải | Thí sinh có `kyc_status = 'pending'` hoặc `'rejected'` gửi đơn đăng ký thi đấu. | High | API, Security |
| **TS-REG-05** | Chặn một thí sinh đăng ký tham gia 2 đội khác nhau trong cùng một giải | Thí sinh đã là đội trưởng hoặc thành viên của Đội 1 cố tình nộp đơn hoặc được thêm vào Đội 2. | Critical | API, Concurrency |
| **TS-REG-06** | VĐV tự do gửi yêu cầu xin gia nhập đội đang tuyển quân | VĐV tự do (đã duyệt KYC) tìm kiếm đội tuyển và gửi `team_join_request` thành công. | High | API, Web UI |
| **TS-REG-07** | Đội trưởng duyệt yêu cầu gia nhập và tự động cập nhật sĩ số | Đội trưởng chấp nhận yêu cầu của VĐV, hệ thống thêm thành viên vào đội và tăng sĩ số. | High | Unit, API, Web UI |
| **TS-REG-08** | Tự động tắt cờ tuyển quân khi đội đạt sĩ số tối đa (`max_team_size`) | Khi thành viên được chấp nhận khiến đội đạt đủ sĩ số quy định, hệ thống tự động chuyển `is_recruiting = false`. | High | Unit, API |
| **TS-REG-09** | Xử lý xung đột đồng thời khi 2 đội trưởng cùng duyệt 1 thí sinh (Race Condition) | Hai giao dịch chấp nhận gia nhập cho cùng 1 thí sinh diễn ra đồng thời tại cùng mili-giây. | Critical | API, Concurrency |
| **TS-REG-10** | Chặn sửa đổi cấu hình thể thức giải đấu khi đã mở cổng đăng ký (BR-TRN-LOCK) | Admin gọi API cập nhật `max_team_size` hoặc `game_category` khi giải đấu đã mở đăng ký. | High | API, Security |

---

## 2. DANH MỤC KỊCH BẢN KIỂM THỬ CHO CHỨC NĂNG B: ĐIỂM DANH GIẢI ĐẤU ĐA PHƯƠNG THỨC

| Mã Kịch bản (Scenario ID) | Tên Kịch bản Kiểm thử (Test Scenario Title) | Mô tả Ngữ cảnh Nghiệp vụ | Mức độ Ưu tiên | Tầng Kiểm thử (Tier) |
|---|---|---|:---:|:---:|
| **TS-CHK-01** | Sinh mã QR động xoay vòng 30 giây cho Ban tổ chức | Hệ thống tạo mã QR hợp lệ chứa `token_hash` gắn với giải đấu và tự động hết hạn sau 30 giây. | High | Unit, API |
| **TS-CHK-02** | Điểm danh thành công với QR động hợp lệ và tọa độ GPS trong bán kính Geofence | Thí sinh quét QR trong thời hạn 30s với tọa độ GPS cách tâm sàn đấu $\le 100m$ và sai số $\le 100m$. | High | API, Mobile Web |
| **TS-CHK-03** | Từ chối điểm danh khi mã QR động đã hết hạn | Thí sinh gửi yêu cầu điểm danh với token đã quá 30 giây kể từ thời điểm phát hành. | High | Unit, API |
| **TS-CHK-04** | Xử lý tọa độ GPS nằm ngoài bán kính sàn đấu (Ngoài vùng Geofence) | Thí sinh quét QR hợp lệ nhưng tọa độ GPS cách sàn đấu $> 100m$ (ví dụ cách 300m hoặc ở nhà). | High | Unit, API, Mobile Web |
| **TS-CHK-05** | Chặn điểm danh trùng lặp (Duplicate Check-in Prevention) | Thí sinh đã điểm danh thành công cố tình quét lại mã QR lần thứ 2 trong cùng giải đấu. | Critical | API, Concurrency |
| **TS-CHK-06** | Nhiều thí sinh quét cùng 1 mã QR động hiển thị trên màn chiếu sàn đấu | 50 thí sinh khác nhau cùng gửi yêu cầu điểm danh sử dụng chung 1 `token_hash` trong cửa sổ 30 giây. | Critical | API, Concurrency |
| **TS-CHK-07** | Điểm danh dự phòng: Nộp ảnh minh chứng khi lỗi cảm biến GPS hoặc thiết bị không hỗ trợ | Thí sinh nộp tệp ảnh minh chứng phòng chờ game hoặc ảnh selfie tại sàn đấu khi không bật được GPS. | High | API, Mobile Web |
| **TS-CHK-08** | Ban tổ chức đối soát tọa độ và duyệt ảnh minh chứng trên bản đồ Leaflet OSM | CTV thời vụ / Admin mở giao diện bản đồ, xem marker tọa độ và bấm duyệt thủ công hồ sơ pending. | High | Web UI, Integration |
| **TS-CHK-09** | Chặn CTV thời vụ đã bị thu hồi phân công thực hiện duyệt điểm danh (RBAC Revocation) | CTV thời vụ bị xóa khỏi bảng `tournament_organizers` cố tình gọi API duyệt điểm danh giải đấu đó. | High | API, Security |
| **TS-CHK-10** | Kiểm thử tải cao điểm: 500 yêu cầu quét QR điểm danh mỗi phút (Load Testing) | Mô phỏng lưu lượng đỉnh tại cửa sàn đấu, đo lường thời gian phản hồi p95 và tỷ lệ lỗi máy chủ. | High | Performance |

---

## 3. DANH MỤC KỊCH BẢN KIỂM THỬ TÍCH HỢP & BẢO MẬT HỖ TRỢ (RBAC & SECURITY)

| Mã Kịch bản (Scenario ID) | Tên Kịch bản Kiểm thử | Mô tả Ngữ cảnh Nghiệp vụ | Mức độ Ưu tiên | Tầng Kiểm thử (Tier) |
|---|---|---|:---:|:---:|
| **TS-SEC-01** | Xác minh tuân thủ Không CCCD (Zero CCCD Invariant) | Kiểm tra toàn bộ API và cơ sở dữ liệu để đảm bảo không có trường hoặc ảnh CCCD/CMND nào tồn tại. | Critical | Unit, Database, API |
| **TS-SEC-02** | Kiểm tra phân quyền truy cập đa tầng (RBAC Enforcement) | Thí sinh gọi API quản trị giải đấu của Admin; CTV thời vụ gọi API duyệt KYC toàn hệ thống. | Critical | API, Security |
| **TS-SEC-03** | Che giấu Dữ liệu Cá nhân (Data Masking) khi hiển thị và xuất dữ liệu | Người dùng có vai trò CTV chỉ nhìn thấy số điện thoại và email thí sinh ở dạng che mờ (`090****789`). | High | API, Security |
