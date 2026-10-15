# ĐẶC TẢ CHI TIẾT CÁC CA KIỂM THỬ (DETAILED TEST CASES SPECIFICATION)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Phạm vi tập trung:** 02 Chức năng Cốt lõi (Function A: Registration & Team Recruitment; Function B: Multi-modal Check-in)  
**Tiêu chuẩn thiết kế:** ISO/IEC/IEEE 29119-3, Kỹ thuật EP, BVA, State Transition, Decision Table, Concurrency, Security  
**Người lập:** QA Testing Architect & Automation Specialist  
**Ngày cập nhật:** 15/10/2026  

---

## MỤC LỤC DANH MỤC CA KIỂM THỬ
1. [Nhóm Ca Kiểm thử Chức năng A: Đăng ký Giải đấu & Tuyển quân (TC-REG-xxx)](#1-nhóm-ca-kiểm-thử-chức-năng-a-đăng-ký-giải-đấu--tuyển-quân)
2. [Nhóm Ca Kiểm thử Chức năng B: Điểm danh Sàn đấu Đa phương thức (TC-CHK-xxx)](#2-nhóm-ca-kiểm-thử-chức-năng-b-điểm-danh-sàn-đấu-đa-phương-thức)
3. [Nhóm Ca Kiểm thử Phân quyền & Bảo mật PII (TC-SEC-xxx)](#3-nhóm-ca-kiểm-thử-phân-quyền--bảo-mật-pii)
4. [Nhóm Ca Kiểm thử Hiệu năng & Tải đồng thời (TC-PRF-xxx)](#4-nhóm-ca-kiểm-thử-hiệu-năng--tải-đồng-thời)

---

## 1. NHÓM CA KIỂM THỬ CHỨC NĂNG A: ĐĂNG KÝ GIẢI ĐẤU & TUYỂN QUÂN

---

### TC-REG-001: Đăng ký đội thi đấu hợp lệ kèm dữ liệu biểu mẫu động JSONB
- **Mã Ca Kiểm thử (Test Case ID):** `TC-REG-001`
- **Mã Yêu cầu liên quan (Requirement ID):** `FR-TRN-01`, `FR-TRN-02`, `FR-TEAM-01`
- **Kịch bản Kiểm thử:** `TS-REG-01`, `TS-REG-02`
- **Tầng Kiểm thử (Testing Level):** API / Web UI
- **Kỹ thuật Thiết kế:** Phân vùng Tương đương (Equivalence Partitioning)
- **Điều kiện Tiên quyết (Preconditions):**
  1. Giải đấu `DUT-TFT-2026` ở trạng thái `status = 'open_registration'`.
  2. Người dùng `user_captain_01` đã đăng nhập, có hồ sơ `participants` với `kyc_status = 'approved'`.
  3. Người dùng chưa đăng ký bất kỳ đội nào trong giải đấu này.
- **Dữ liệu Kiểm thử (Test Data):**
  - `tournament_id`: UUID của giải `DUT-TFT-2026`
  - `team_name`: `"Bách Khoa TFT Champions"`
  - `ingame_id`: `"DUT_Gamer#VN2"`
  - `submitted_data`: `{"rank": "Challenger", "favorite_comp": "Yordle"}`
  - `is_recruiting`: `true`
- **Các bước Thực hiện (Execution Steps):**
  1. Gửi request `POST /api/tournaments/{id}/register` với header `Authorization: Bearer <token_captain>` và payload dữ liệu trên.
  2. Kiểm tra mã trạng thái HTTP và nội dung response body.
  3. Truy vấn trực tiếp cơ sở dữ liệu trên bảng `registrations` và `registration_members`.
- **Kết quả Kỳ vọng (Expected Result):**
  1. Máy chủ trả về mã HTTP `201 Created` kèm payload `success: true` và `registration_id`.
  2. Bảng `registrations` tạo 1 bản ghi mới với `status = 'pending'`, `is_recruiting = true`.
  3. Bảng `registration_members` tạo 1 bản ghi mới với `participant_id` của đội trưởng, `is_captain = true`.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (API / Web)`
- **Rủi ro Liên quan:** Lỗi lưu sai cấu trúc JSONB biểu mẫu động.

---

### TC-REG-002: Chặn đăng ký khi người dùng chưa hoàn tất duyệt KYC
- **Mã Ca Kiểm thử:** `TC-REG-002`
- **Mã Yêu cầu liên quan:** `FR-KYC-03`, `FR-TEAM-01`
- **Kịch bản Kiểm thử:** `TS-REG-04`
- **Tầng Kiểm thử:** API Testing
- **Kỹ thuật Thiết kế:** Phân vùng Tương đương & Kiểm thử Tiêu cực (Negative Testing)
- **Điều kiện Tiên quyết:**
  1. Giải đấu đang ở trạng thái `open_registration`.
  2. Người dùng `user_unverified_01` có `kyc_status = 'pending'` (chưa được CTV duyệt ảnh thẻ SV).
- **Dữ liệu Kiểm thử:**
  - Token JWT của `user_unverified_01`
  - Payload đăng ký giải đấu hợp lệ
- **Các bước Thực hiện:**
  1. Gửi request `POST /api/tournaments/{id}/register` với token của `user_unverified_01`.
  2. Quan sát phản hồi từ API.
- **Kết quả Kỳ vọng:**
  1. Máy chủ trả về mã lỗi HTTP `403 Forbidden`.
  2. Error envelope trả về: `{"success": false, "error": {"code": "KYC_NOT_APPROVED", "message": "Hồ sơ sinh viên chưa được phê duyệt KYC"}}`.
  3. Không có bất kỳ bản ghi nào được tạo trong bảng `registrations`.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (API)`
- **Rủi ro Liên quan:** Thí sinh giả mạo danh tính tham gia giải đấu.

---

### TC-REG-003: Chặn đăng ký khi giải đấu đã đóng cổng (`closed_registration`)
- **Mã Ca Kiểm thử:** `TC-REG-003`
- **Mã Yêu cầu liên quan:** `FR-TRN-02`
- **Kịch bản Kiểm thử:** `TS-REG-03`
- **Tầng Kiểm thử:** API / Unit Testing
- **Kỹ thuật Thiết kế:** Kiểm thử Chuyển trạng thái (State Transition Testing)
- **Điều kiện Tiên quyết:**
  1. Giải đấu đã chuyển sang trạng thái `closed_registration` (hết thời hạn đăng ký).
  2. Thí sinh `user_captain_02` đã được duyệt KYC hợp lệ.
- **Các bước Thực hiện:**
  1. Gửi request `POST /api/tournaments/{id}/register`.
- **Kết quả Kỳ vọng:**
  1. Máy chủ từ chối với mã lỗi HTTP `400 Bad Request` hoặc `409 Conflict`.
  2. Thông điệp lỗi: `"REGISTRATION_CLOSED"`.
  3. Cơ sở dữ liệu không thay đổi.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (API)`
- **Rủi ro Liên quan:** Thêm thí sinh sau khi đã chốt danh sách chia cặp.

---

### TC-REG-004: Chặn một thí sinh tham gia 2 đội khác nhau trong cùng giải đấu
- **Mã Ca Kiểm thử:** `TC-REG-004`
- **Mã Yêu cầu liên quan:** `FR-TEAM-01`, `FR-TEAM-03`, `BR-TEAM-CONCURRENCY`
- **Kịch bản Kiểm thử:** `TS-REG-05`
- **Tầng Kiểm thử:** API / Database Integration
- **Kỹ thuật Thiết kế:** Kiểm thử Giá trị Biên & Ràng buộc Toàn vẹn (Integrity Testing)
- **Điều kiện Tiên quyết:**
  1. Thí sinh `user_player_01` đã là thành viên chính thức của Đội A trong Giải đấu X.
  2. Đội B trong cùng Giải đấu X đang mở tuyển quân.
- **Dữ liệu Kiểm thử:**
  - `user_player_01` gửi yêu cầu gia nhập tới Đội B hoặc Đội trưởng Đội B thêm trực tiếp `user_player_01`.
- **Các bước Thực hiện:**
  1. Đội trưởng Đội B gửi request `POST /api/team-requests/{id}/accept` để nhận `user_player_01`.
- **Kết quả Kỳ vọng:**
  1. Máy chủ từ chối với mã lỗi HTTP `409 Conflict`.
  2. Mã lỗi trả về: `"PARTICIPANT_ALREADY_IN_ANOTHER_TEAM"`.
  3. Bảng `registration_members` không chèn thêm bản ghi mới.
- **Mức độ Ưu tiên:** `Critical`
- **Khả năng Tự động hóa:** `Yes (API)`
- **Rủi ro Liên quan:** Một vận động viên thi đấu cho 2 đội đối đầu nhau trong cùng một giải.

---

### TC-REG-005: Tự động tắt cờ tuyển quân khi đội đạt sĩ số tối đa (`max_team_size`)
- **Mã Ca Kiểm thử:** `TC-REG-005`
- **Mã Yêu cầu liên quan:** `FR-TEAM-01`, `FR-TEAM-03`
- **Kịch bản Kiểm thử:** `TS-REG-08`
- **Tầng Kiểm thử:** Unit / API Testing
- **Kỹ thuật Thiết kế:** Phân tích Giá trị Biên (BVA tại `max_team_size = 5`)
- **Điều kiện Tiên quyết:**
  1. Giải đấu quy định `max_team_size = 5`.
  2. Đội X hiện đang có 4 thành viên (`is_recruiting = true`).
  3. Có 2 yêu cầu gia nhập đang ở trạng thái `pending`: Request R1 của VĐV A, Request R2 của VĐV B.
- **Các bước Thực hiện:**
  1. Đội trưởng Đội X gửi request chấp nhận Request R1 của VĐV A.
- **Kết quả Kỳ vọng:**
  1. Máy chủ trả về HTTP `200 OK`, VĐV A trở thành thành viên thứ 5 của đội.
  2. Cờ `registrations.is_recruiting` của Đội X tự động chuyển thành `false`.
  3. Yêu cầu R2 còn lại tự động bị từ chối (`status = 'rejected'`) do đội đã đầy.
  4. Đội X lập tức biến mất khỏi Bảng tin tuyển quân công khai.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (Unit / API)`
- **Rủi ro Liên quan:** Đội bị phình to quá số lượng thành viên tối đa của điều lệ giải.

---

### TC-REG-006: Xử lý Đua luồng Đồng thời khi 2 Đội trưởng cùng Duyệt 1 Thí sinh (Race Condition Test)
- **Mã Ca Kiểm thử:** `TC-REG-006`
- **Mã Yêu cầu liên quan:** `FR-TEAM-03`, `BR-TEAM-CONCURRENCY`
- **Kịch bản Kiểm thử:** `TS-REG-09`
- **Tầng Kiểm thử:** API Concurrency Testing
- **Kỹ thuật Thiết kế:** Kiểm thử Xung đột Đồng thời (Concurrency / Race Condition)
- **Điều kiện Tiên quyết:**
  1. Thí sinh `user_freelancer` gửi yêu cầu gia nhập tới cả Đội 1 và Đội 2 trong cùng giải đấu T.
  2. Cả 2 đội đều đang thiếu quân số (`is_recruiting = true`).
- **Các bước Thực hiện:**
  1. Khởi tạo 2 worker HTTP bất đồng bộ sử dụng `Promise.all`:
     - Worker 1: Gửi `POST /api/team-requests/{id_req_1}/accept` (Đội trưởng 1 duyệt).
     - Worker 2: Gửi `POST /api/team-requests/{id_req_2}/accept` (Đội trưởng 2 duyệt).
  2. Kích hoạt cả 2 request tại cùng một mili-giây.
  3. Thu thập mã phản hồi HTTP và kiểm tra dữ liệu trong CSDL.
- **Kết quả Kỳ vọng:**
  1. Chính xác 01 request nhận mã HTTP `200 OK` (Thành công).
  2. Request còn lại nhận mã HTTP `409 Conflict` với lỗi `"PARTICIPANT_ALREADY_IN_ANOTHER_TEAM"`.
  3. Bảng `registration_members` chỉ xuất hiện duy nhất 01 bản ghi cho `user_freelancer` trong giải đấu T.
  4. Không xảy ra Deadlock hoặc lỗi máy chủ `500 Internal Server Error`.
- **Mức độ Ưu tiên:** `Critical`
- **Khả năng Tự động hóa:** `Yes (API Concurrency)`
- **Rủi ro Liên quan:** Hỏng tính toàn vẹn dữ liệu thi đấu khi tải cao.

---

## 2. NHÓM CA KIỂM THỬ CHỨC NĂNG B: ĐIỂM DANH SÀN ĐẤU ĐA PHƯƠNG THỨC

---

### TC-CHK-001: Điểm danh thành công với QR động hợp lệ và tọa độ GPS trong bán kính Geofence
- **Mã Ca Kiểm thử:** `TC-CHK-001`
- **Mã Yêu cầu liên quan:** `FR-CHK-01`, `FR-CHK-02`, `NFR-PRF-01`
- **Kịch bản Kiểm thử:** `TS-CHK-02`
- **Tầng Kiểm thử:** API / Mobile Web Emulation
- **Kỹ thuật Thiết kế:** Phân vùng Tương đương & Bảng Quyết định (Decision Table)
- **Điều kiện Tiên quyết:**
  1. Giải đấu `DUT-ARENA-2026` đang mở điểm danh (`checkin_opens_at \le now() \le checkin_closes_at`).
  2. Tọa độ tâm sàn đấu (Hội trường F ĐHBK): `lat = 16.074800, lng = 108.149900`, bán kính `geofence_radius = 100m`.
  3. Thí sinh `user_athlete_01` đã đăng ký hợp lệ trong giải.
- **Dữ liệu Kiểm thử:**
  - Token QR động còn hạn (sinh trước đó 5 giây).
  - Tọa độ thiết bị gửi lên: `lat = 16.075000, lng = 108.150100` (Khoảng cách tính toán: ~31 mét, sai số GPS: `15m`).
- **Các bước Thực hiện:**
  1. Gửi request `POST /api/checkin/qr` kèm `token_hash`, `latitude`, `longitude`, `gps_accuracy`.
- **Kết quả Kỳ vọng:**
  1. Máy chủ trả về mã HTTP `200 OK`.
  2. Payload: `{"success": true, "data": {"status": "approved", "distance_meters": 31.2}}`.
  3. Bảng `check_ins` lưu bản ghi mới với `status = 'approved'`, `method = 'qr_scan'`.
  4. Thời gian phản hồi API $< 2.0$ giây tại p95.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (API / Mobile Web)`
- **Rủi ro Liên quan:** Ách tắc cổng ra vào sàn đấu nếu xác thực thất bại.

---

### TC-CHK-002: Từ chối điểm danh khi mã QR động đã hết hạn xoay vòng 30 giây
- **Mã Ca Kiểm thử:** `TC-CHK-002`
- **Mã Yêu cầu liên quan:** `FR-CHK-01`
- **Kịch bản Kiểm thử:** `TS-CHK-03`
- **Tầng Kiểm thử:** Unit / API Testing
- **Kỹ thuật Thiết kế:** Phân tích Giá trị Biên (BVA tại $t = 31$ giây)
- **Điều kiện Tiên quyết:**
  1. Token QR động được sinh tại thời điểm $t_0$.
- **Dữ liệu Kiểm thử:**
  - Gửi request tại thời điểm $t_0 + 31$ giây.
  - Tọa độ GPS hợp lệ (trong sàn đấu).
- **Các bước Thực hiện:**
  1. Gọi API `POST /api/checkin/qr` với token đã hết hạn 31 giây.
- **Kết quả Kỳ vọng:**
  1. Máy chủ từ chối với mã lỗi HTTP `400 Bad Request` hoặc `401 Unauthorized`.
  2. Mã lỗi trả về: `"QR_TOKEN_EXPIRED"`.
  3. Không có bản ghi điểm danh nào được tạo ở trạng thái `approved`.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (Unit / API)`
- **Rủi ro Liên quan:** Thí sinh chụp ảnh màn hình QR gửi cho bạn bè ở xa quét lại sau giờ khai mạc.

---

### TC-CHK-003: Xử lý tọa độ GPS nằm ngoài bán kính sàn đấu (Ngoài vùng Geofence)
- **Mã Ca Kiểm thử:** `TC-CHK-003`
- **Mã Yêu cầu liên quan:** `FR-CHK-02`, `FR-CHK-04`
- **Kịch bản Kiểm thử:** `TS-CHK-04`
- **Tầng Kiểm thử:** API / Mobile Web Emulation
- **Kỹ thuật Thiết kế:** Phân vùng Tương đương & Phân tích Biên (Khoảng cách $= 101m$ và $500m$)
- **Dữ liệu Kiểm thử:**
  - Token QR hợp lệ (còn hạn).
  - Tọa độ GPS gửi lên: `lat = 16.080000, lng = 108.155000` (Khoảng cách tính toán: ~780 mét so với Hội trường F).
- **Các bước Thực hiện:**
  1. Gọi API `POST /api/checkin/qr`.
- **Kết quả Kỳ vọng:**
  1. Máy chủ trả về mã HTTP `200 OK` hoặc `422 Unprocessable Entity` với trạng thái:
     `{"success": false, "data": {"status": "pending_review", "reason": "OUTSIDE_GEOFENCE", "allow_proof": true}}`.
  2. Bản ghi trong `check_ins` nếu được lưu sẽ có trạng thái `pending_review` (chưa được duyệt).
  3. Giao diện người dùng tự động hiển thị nút: `"Chuyển sang Nộp minh chứng hình ảnh"`.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (API / Mobile Web)`
- **Rủi ro Liên quan:** Gian lận điểm danh từ xa khi không có mặt tại sự kiện.

---

### TC-CHK-004: Chặn điểm danh trùng lặp (Duplicate Check-in Prevention)
- **Mã Ca Kiểm thử:** `TC-CHK-004`
- **Mã Yêu cầu liên quan:** `FR-CHK-01`, `FR-CHK-02`
- **Kịch bản Kiểm thử:** `TS-CHK-05`
- **Tầng Kiểm thử:** API Testing
- **Kỹ thuật Thiết kế:** Kiểm thử Hồi quy & Toàn vẹn CSDL
- **Điều kiện Tiên quyết:**
  1. Thí sinh `user_athlete_02` đã điểm danh thành công trước đó trong giải đấu (`status = 'approved'`).
- **Các bước Thực hiện:**
  1. Thí sinh `user_athlete_02` thực hiện quét mã QR mới và gửi lại request điểm danh.
- **Kết quả Kỳ vọng:**
  1. Máy chủ từ chối với mã HTTP `409 Conflict` hoặc trả về kết quả đã duyệt trước đó một cách Idempotent:
     `{"success": true, "message": "Thí sinh đã hoàn tất điểm danh", "data": {"status": "approved"}}`.
  2. Số lượng bản ghi trong bảng `check_ins` của thí sinh này trong giải đấu vẫn duy trì chính xác là `1` (Ràng buộc `uq_checkin_per_participant` bảo toàn).
- **Mức độ Ưu tiên:** `Critical`
- **Khả năng Tự động hóa:** `Yes (API)`
- **Rủi ro Liên quan:** Làm sai lệch thống kê số lượng vận động viên thực tế có mặt tại sàn đấu.

---

### TC-CHK-005: 50 thí sinh quét cùng 1 mã QR động hiển thị trên màn chiếu trong 30 giây
- **Mã Ca Kiểm thử:** `TC-CHK-005`
- **Mã Yêu cầu liên quan:** `FR-CHK-01`, `NFR-PRF-03`
- **Kịch bản Kiểm thử:** `TS-CHK-06`
- **Tầng Kiểm thử:** Concurrency / Load Testing
- **Kỹ thuật Thiết kế:** Kiểm thử Đồng thời Đa người dùng (Multi-user Concurrency)
- **Điều kiện Tiên quyết:**
  1. Một mã QR động duy nhất được tạo ra trên màn chiếu hội trường.
  2. 50 tài khoản thí sinh khác nhau, đều đã đăng ký hợp lệ và có mặt tại sàn đấu.
- **Các bước Thực hiện:**
  1. Khởi tạo 50 request điểm danh đồng thời, cùng truyền chung 1 giá trị `token_hash` của mã QR trên.
  2. Mỗi request mang theo token định danh và tọa độ GPS hợp lệ riêng của từng thí sinh.
  3. Gửi đồng thời trong vòng 5 giây.
- **Kết quả Kỳ vọng:**
  1. 100% (50/50) requests đều nhận mã phản hồi HTTP `200 OK` (`status = 'approved'`).
  2. Bảng `check_ins` ghi nhận đủ 50 bản ghi tương ứng với 50 thí sinh khác nhau.
  3. Không có thí sinh nào bị từ chối do lý do "Token đã được người khác sử dụng" (Chứng minh tính hợp lệ của việc QR động gắn với Giải đấu chứ không phải gắn với 1 người dùng đơn lẻ).
- **Mức độ Ưu tiên:** `Critical`
- **Khả năng Tự động hóa:** `Yes (API Concurrency)`
- **Rủi ro Liên quan:** Hiểu sai nghiệp vụ dẫn tới việc khóa token sau khi người đầu tiên quét.

---

### TC-CHK-006: Điểm danh Dự phòng bằng cách Nộp Ảnh Minh chứng khi Lỗi GPS
- **Mã Ca Kiểm thử:** `TC-CHK-006`
- **Mã Yêu cầu liên quan:** `FR-CHK-04`
- **Kịch bản Kiểm thử:** `TS-CHK-07`
- **Tầng Kiểm thử:** API / Web UI / Mobile Web
- **Kỹ thuật Thiết kế:** Luồng Ngoại lệ (Alternative Flow Testing)
- **Điều kiện Tiên quyết:**
  1. Thiết bị di động không bật được GPS hoặc trình duyệt bị chặn quyền Geolocation.
- **Dữ liệu Kiểm thử:**
  - Tệp ảnh minh chứng định dạng JPEG (`proof_arena_hall_f.jpg`), dung lượng 1.2 MB.
- **Các bước Thực hiện:**
  1. Thí sinh chọn "Nộp minh chứng hình ảnh".
  2. Tải ảnh lên qua `POST /api/checkin/proof`.
- **Kết quả Kỳ vọng:**
  1. Máy chủ xác thực Magic Bytes tệp ảnh thành công.
  2. Lưu trữ tệp ảnh vào thư mục riêng tư và tạo bản ghi tại `check_ins` với `method = 'proof_submission'` và `status = 'pending_review'`.
  3. Phản hồi HTTP `201 Created` thông báo hồ sơ đang chờ Ban tổ chức đối soát.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (API / Mobile Web)`
- **Rủi ro Liên quan:** Vận động viên có mặt thực tế nhưng không thể thi đấu vì lỗi phần cứng điện thoại.

---

### TC-CHK-007: Ban tổ chức đối soát tọa độ và duyệt ảnh minh chứng trên bản đồ Leaflet OSM
- **Mã Ca Kiểm thử:** `TC-CHK-007`
- **Mã Yêu cầu liên quan:** `FR-CHK-05`
- **Kịch bản Kiểm thử:** `TS-CHK-08`
- **Tầng Kiểm thử:** Web UI Testing (Playwright Desktop)
- **Kỹ thuật Thiết kế:** Kiểm thử Tương tác Giao diện & RBAC
- **Điều kiện Tiên quyết:**
  1. Tài khoản CTV thời vụ `ctv_tournament_01` đã đăng nhập và được phân công vào giải đấu trong `tournament_organizers`.
  2. Có 1 bản ghi điểm danh ở trạng thái `pending_review` với ảnh minh chứng.
- **Các bước Thực hiện:**
  1. CTV mở trang Bản đồ Giám sát Điểm danh (`/admin/tournaments/{id}/checkin-map`).
  2. Kiểm tra bản đồ Leaflet OSM đã nạp đầy đủ các điểm ghim (markers).
  3. Nhấn vào điểm ghim màu cam của thí sinh đang chờ duyệt để mở Modal xem ảnh minh chứng.
  4. Nhấn nút "Phê duyệt" (Approve).
- **Kết quả Kỳ vọng:**
  1. Giao diện gửi request `POST /api/checkin/review` kèm `status: 'approved'`.
  2. Điểm ghim trên bản đồ Leaflet chuyển ngay sang màu xanh lá cây mà không cần tải lại toàn trang.
  3. Bảng `check_ins` cập nhật `status = 'approved'`, `reviewed_by = ctv_user_id`.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (Playwright Web E2E)`
- **Rủi ro Liên quan:** Lỗi giao diện bản đồ không cập nhật trạng thái thời gian thực.

---

## 3. NHÓM CA KIỂM THỬ PHÂN QUYỀN & BẢO MẬT PII (RBAC & SECURITY)

---

### TC-SEC-001: Xác minh Tuân thủ Tuyệt đối Nguyên tắc Không CCCD (Zero CCCD Invariant)
- **Mã Ca Kiểm thử:** `TC-SEC-001`
- **Mã Yêu cầu liên quan:** `NFR-SEC-01`, `FR-KYC-01`
- **Kịch bản Kiểm thử:** `TS-SEC-01`
- **Tầng Kiểm thử:** Database / API Security
- **Kỹ thuật Thiết kế:** Kiểm thử An toàn Thông tin & Tuân thủ Pháp lý (Compliance Testing)
- **Các bước Thực hiện:**
  1. Quét lược đồ cơ sở dữ liệu `database_schema.sql` và thông tin cột trên Supabase:
     Kiểm tra sự tồn tại của các từ khóa: `cccd`, `cmnd`, `citizen_id`, `identity_card`.
  2. Gửi request đăng ký tài khoản và cập nhật hồ sơ với các trường bổ sung nhân tạo:
     `{"id_number": "048202001234", "cccd_front": "base64..."}`.
- **Kết quả Kỳ vọng:**
  1. 100% các bảng cơ sở dữ liệu KHÔNG có cột nào liên quan đến CCCD/CMND.
  2. API máy chủ phớt lờ hoàn toàn các trường dữ liệu CCCD lạ hoặc từ chối lưu vào cơ sở dữ liệu.
  3. Đảm bảo bảo vệ dữ liệu cá nhân theo đúng luật định.
- **Mức độ Ưu tiên:** `Critical`
- **Khả năng Tự động hóa:** `Yes (Database / Schema Unit)`
- **Rủi ro Liên quan:** Vi phạm pháp lý dữ liệu cá nhân và điều lệ bảo mật của Nhà trường.

---

### TC-SEC-002: Chặn CTV Thời vụ bị thu hồi quyền thực hiện thao tác duyệt (RBAC Revocation)
- **Mã Ca Kiểm thử:** `TC-SEC-002`
- **Mã Yêu cầu liên quan:** `NFR-SEC-05`, `SRS 2.2`
- **Kịch bản Kiểm thử:** `TS-CHK-09`
- **Tầng Kiểm thử:** API Security Testing
- **Kỹ thuật Thiết kế:** Kiểm thử Quyền hạn Tầng Dịch vụ (Object-level Authorization)
- **Điều kiện Tiên quyết:**
  1. CTV thời vụ `ctv_seasonal_02` sở hữu JWT token còn hạn 24 giờ.
  2. Admin vừa thực hiện xóa bản ghi phân công của `ctv_seasonal_02` trong bảng `tournament_organizers` cho Giải đấu X.
- **Các bước Thực hiện:**
  1. `ctv_seasonal_02` dùng token cũ gọi API duyệt điểm danh: `POST /api/checkin/review` cho Giải đấu X.
- **Kết quả Kỳ vọng:**
  1. Middleware `tournamentScope` và `activeStaff` truy vấn CSDL và phát hiện phân công không còn hiệu lực.
  2. Máy chủ từ chối yêu cầu với mã HTTP `403 Forbidden`.
  3. Thông điệp lỗi: `"ORGANIZER_ASSIGNMENT_REVOKED"`.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (API Security)`
- **Rủi ro Liên quan:** Rò rỉ quyền hạn khi nhân sự thời vụ đã kết thúc hợp đồng hỗ trợ.

---

## 4. NHÓM CA KIỂM THỬ HIỆU NĂNG & TẢI ĐỒNG THỜI (PERFORMANCE)

---

### TC-PRF-001: Đo lường Thời gian Phản hồi Điểm danh QR tại Phân vị 95 (p95 Latency Benchmark)
- **Mã Ca Kiểm thử:** `TC-PRF-001`
- **Mã Yêu cầu liên quan:** `NFR-PRF-01`
- **Kịch bản Kiểm thử:** `TS-CHK-10`
- **Tầng Kiểm thử:** Performance Testing
- **Kỹ thuật Thiết kế:** Kiểm thử Hiệu năng Đo lường Thời gian thực
- **Điều kiện Tiên quyết:**
  1. Backend API và cơ sở dữ liệu Supabase kết nối ổn định.
- **Dữ liệu Kiểm thử:**
  - 100 requests điểm danh hợp lệ tuần tự và song song.
- **Các bước Thực hiện:**
  1. Gửi chuỗi requests điểm danh và ghi nhận thời gian từ lúc gửi byte đầu tiên đến khi nhận toàn bộ response body (`performance.now()`).
  2. Tính toán: Thời gian trung bình, median, p90, p95, p99.
- **Kết quả Kỳ vọng:**
  1. Phân vị 95 (p95 Latency) đạt: **$< 2.0$ giây**.
  2. Tỷ lệ phản hồi thành công HTTP 200 đạt: **$100\%$**.
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (Performance Benchmark)`
- **Rủi ro Liên quan:** Ùn tắc vận động viên tại bàn điểm danh sàn đấu.

---

### TC-PRF-002: Kiểm thử Chịu tải Cao điểm 500 Yêu cầu Điểm danh Mỗi Phút (Check-in Rush Load Test)
- **Mã Ca Kiểm thử:** `TC-PRF-002`
- **Mã Yêu cầu liên quan:** `NFR-PRF-03`
- **Kịch bản Kiểm thử:** `TS-CHK-10`
- **Tầng Kiểm thử:** Concurrency / Stress Performance Testing
- **Kỹ thuật Thiết kế:** Kiểm thử Sức tải Bền vững (Load Testing)
- **Dữ liệu Kiểm thử:**
  - 50 client ảo (Virtual Users) gửi yêu cầu liên tục tạo tải 500 requests/phút trong 10 phút.
- **Các bước Thực hiện:**
  1. Kích hoạt kịch bản tải mô phỏng mở cổng check-in giải đấu.
  2. Giám sát tỷ lệ phản hồi lỗi HTTP 5xx và mức độ tiêu thụ bộ nhớ RAM máy chủ.
- **Kết quả Kỳ vọng:**
  1. Tỷ lệ lỗi máy chủ (5xx Error Rate) đạt: **$< 1.0\%$**.
  2. Hệ thống duy trì tính sẵn sàng, không bị sập kết nối (No Connection Pool Exhaustion).
- **Mức độ Ưu tiên:** `High`
- **Khả năng Tự động hóa:** `Yes (Performance Load Test)`
- **Rủi ro Liên quan:** Sập hệ thống trong 15 phút mở cổng check-in ngày khai mạc.
