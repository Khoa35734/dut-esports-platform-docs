# BÁO CÁO KHOẢNG TRỐNG QUY TẮC NGHIỆP VỤ (BUSINESS RULE GAPS ANALYSIS)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Tài liệu gốc:** SRS 1.1 (Cập nhật 29/09/2026)  
**Tác giả phân tích:** Senior Business Analyst & QA Architect  
**Ngày cập nhật:** 15/10/2026  

---

## 1. TỔNG QUAN

Tài liệu này xác định các "vùng xám" (Grey Areas) và các khoảng trống quy tắc nghiệp vụ (Business Rule Gaps) trong tài liệu SRS 1.1. Đây là những tình huống phát sinh trong thực tế vận hành giải đấu thể thao điện tử tại môi trường Đại học Bách khoa nhưng chưa được tài liệu quy định rõ ràng hoặc chưa có cơ chế xử lý ngoại lệ.

Mỗi khoảng trống được phân tích theo mô hình:
- **Ngữ cảnh nghiệp vụ (Context)**
- **Khoảng trống quy tắc (The Gap)**
- **Rủi ro vận hành & Dữ liệu (Risk & Impact)**
- **Quy tắc Nghiệp vụ Đề xuất (Proposed Canonical Business Rule)**

---

## 2. CHI TIẾT CÁC KHOẢNG TRỐNG NGHIỆP VỤ

### GAP-BR-001: Khóa cấu hình Giải đấu khi đã có dữ liệu đăng ký (Tournament Configuration Lock)
- **Ngữ cảnh:** Admin hoặc CTV Thường trực tạo giải đấu ở trạng thái `draft`, sau đó chuyển sang `open_registration`. Các đội bắt đầu nộp hồ sơ.
- **Khoảng trống:** SRS 1.1 không quy định rõ những trường nào trong bảng `tournaments` được phép và không được phép chỉnh sửa sau khi cổng đăng ký đã mở.
- **Rủi ro:** Nếu Admin hạ `max_team_size` từ 7 xuống 5 khi đã có các đội đủ 7 người đăng ký, hoặc thay đổi `game_category` từ Valorant sang LMHT, toàn bộ dữ liệu in-game (`ingame_id`, `submitted_data`) của thí sinh trở nên vô nghĩa và phá vỡ cấu trúc giải đấu.
- **Quy tắc đề xuất (BR-TRN-LOCK):**
  > **Quy tắc BR-TRN-LOCK:**
  > Ngay khi giải đấu chuyển từ `draft` sang `open_registration`:
  > 1. Hệ thống **khóa vĩnh viễn (Read-only)** các trường: `game_category`, `min_team_size`, `max_team_size`, `form_schema`.
  > 2. Các trường được phép chỉnh sửa: `title`, `description`, `banner_url`, `location`, `registration_closes_at` (gia hạn thời gian đăng ký), `checkin_lat`, `checkin_lng`, `geofence_radius_meters`.
  > 3. Mọi thao tác cập nhật khi giải đấu đã mở phải được ghi lại trong `audit_logs`.

---

### GAP-BR-002: Tỷ lệ Sinh viên Nội bộ DUT và Sinh viên Trường ngoài (Internal / External Ratio Rule)
- **Ngữ cảnh:** SRS Mục 1.2 và FR-KYC-02 phân loại sinh viên thành `internal` (ĐH Bách khoa Đà Nẵng) và `external` (Trường ngoài) làm căn cứ tính tỷ lệ thành viên trong đội.
- **Khoảng trống:** SRS 1.1 **hoàn toàn không đưa ra con số tỷ lệ phần trăm cụ thể** (Ví dụ: Đội tối thiểu phải có bao nhiêu % sinh viên DUT?). Khi nào hệ thống từ chối đơn đăng ký vì vi phạm tỷ lệ?
- **Rủi ro:** Các đội gồm toàn sinh viên trường ngoài đăng ký ồ ạt, làm mất đi tính chất của giải đấu cấp trường do CLB Esports ĐH Bách khoa tổ chức, dẫn tới khiếu nại từ sinh viên Bách khoa.
- **Quy tắc đề xuất (BR-TEAM-RATIO):**
  > **Quy tắc BR-TEAM-RATIO:**
  > Trong bảng `tournaments`, bổ sung trường `min_internal_student_percentage INT DEFAULT 60` (Mặc định tối thiểu 60% thành viên trong đội phải là sinh viên nội bộ DUT).
  > - Với giải đấu cá nhân (TFT): Nếu giải đấu cấu hình `is_internal_only = true`, chỉ tài khoản có `account_type = 'internal'` mới được nộp đơn.
  > - Với giải đấu đồng đội (5 người): Đội bắt buộc phải có ít nhất $\lceil 5 \times 0.6 \rceil = 3$ thành viên nội bộ DUT.
  > - Kiểm tra tỷ lệ này tại 2 thời điểm: (1) Khi Đội trưởng nộp đơn; (2) Khi Đội trưởng chấp nhận thành viên mới qua tuyển quân.

---

### GAP-BR-003: Cơ chế Chuyển nhượng Đội trưởng và Rút đơn Đăng ký (Captain Resignation & Withdrawal)
- **Ngữ cảnh:** Đội trưởng là người đại diện nộp đơn thi đấu và bật tuyển quân. Trong quá trình chờ thi đấu, Đội trưởng gặp sự cố cá nhân (ốm, bận thi cử) hoặc muốn rút khỏi giải.
- **Khoảng trống:** SRS 1.1 không có use case cho phép Đội trưởng nhượng quyền cho thành viên khác trong đội, cũng như không quy định điều gì xảy ra nếu Đội trưởng rời đội.
- **Rủi ro:** Đơn đăng ký bị "mồ côi" (Orphaned Registration), không ai có quyền xác nhận kết quả trận đấu hoặc check-in cho đội.
- **Quy tắc đề xuất (BR-TEAM-CAPTAIN):**
  > **Quy tắc BR-TEAM-CAPTAIN:**
  > 1. Đội trưởng chỉ được phép rút lui khỏi đội nếu chuyển giao quyền đội trưởng (`is_captain = true`) cho một thành viên hợp lệ khác trong đội trước khi rời đi.
  > 2. Đơn đăng ký chỉ được phép Hủy (Withdraw) khi giải đấu đang ở trạng thái `open_registration`. Một khi giải đấu đã chuyển sang `closed_registration` hoặc `ongoing`, đội không thể tự hủy đơn mà phải qua thủ tục Xử thua / Bỏ cuộc (Walkover) do BTC phân xử.

---

### GAP-BR-004: Xử lý Thí sinh Gian lận Danh tính / Thu hồi KYC sau khi Đã Đăng ký (Post-Registration KYC Revocation)
- **Ngữ cảnh:** Thí sinh nộp ảnh thẻ SV giả mạo qua mắt được CTV ở lượt đầu. Sau đó qua đối soát định kỳ, Admin phát hiện và chuyển `kyc_status` từ `approved` sang `rejected`.
- **Khoảng trống:** SRS chưa quy định tác động của việc thu hồi KYC đối với các giải đấu mà thí sinh này đã đăng ký và nhánh đấu đã được bốc thăm.
- **Rủi ro:** Thí sinh bị cấm thi đấu nhưng tên vẫn nằm trong nhánh đấu đã sinh, gây nhầm lẫn khi xếp lịch trận.
- **Quy tắc đề xuất (BR-KYC-DISQUALIFY):**
  > **Quy tắc BR-KYC-DISQUALIFY:**
  > Khi tài khoản thí sinh bị chuyển `kyc_status = 'rejected'` hoặc bị khóa tài khoản (`users.is_active = false`):
  > 1. Hệ thống tự động tước tư cách thành viên của thí sinh trong toàn bộ các đơn đăng ký ở các giải đấu chưa kết thúc.
  > 2. Nếu đội thiếu người dẫn tới $< min\_team\_size$, đội có 24 giờ để tuyển bổ sung thành viên thay thế (với điều kiện giải chưa sinh nhánh).
  > 3. Nếu giải đã diễn ra: Toàn bộ các trận đấu tiếp theo của đội/thí sinh đó được tự động chấm điểm xử thua (`result = 'loss'`, đối thủ nhận `win` theo diện Walkover).

---

### GAP-BR-005: Quy tắc Hạn định Khiếu nại và Tự động Khóa Kết quả Trận (Dispute Window & Auto-Lock)
- **Ngữ cảnh:** Trọng tài bàn nhập kết quả trận đấu BO3 vào hệ thống (`matches.status = 'awaiting_confirmation'`).
- **Khoảng trống:** SRS ghi: "đội trưởng xác nhận hoặc gửi khiếu nại trong khoảng thời gian do Điều lệ giải quy định". Nhưng SRS không quy định giá trị mặc định là bao nhiêu phút và điều gì xảy ra nếu cả 2 đội trưởng không ai bấm xác nhận.
- **Rủi ro:** Nhánh đấu bị tắc nghẽn vô thời hạn (Deadlock) vì chờ đội trưởng bấm nút, làm chậm tiến độ toàn bộ giải đấu trong ngày.
- **Quy tắc đề xuất (BR-MATCH-TIMEOUT):**
  > **Quy tắc BR-MATCH-TIMEOUT:**
  > 1. Cửa sổ khiếu nại kết quả mặc định là **15 phút** kể từ thời điểm Trọng tài nhập kết quả.
  > 2. Sau 15 phút, nếu không có khiếu nại (`disputed`) nào được tạo, hệ thống tự động khóa kết quả và chuyển trạng thái trận sang `completed`.
  > 3. Đội thắng lập tức được hệ thống tự động đẩy sang trận đấu kế tiếp (`winner_next_match_id`).

---

### GAP-BR-006: Giới hạn Điều chỉnh Bán kính Check-in Geofencing của Admin
- **Ngữ cảnh:** Ban tổ chức cấu hình tọa độ sân trường Bách khoa và bán kính cho phép điểm danh (`geofence_radius_meters`).
- **Khoảng trống:** SRS cho phép Admin thay đổi bán kính, nhưng không đặt ngưỡng chặn trên/dưới.
- **Rủi ro:** Admin cấu hình bán kính quá nhỏ (ví dụ 5 mét - sai số GPS điện thoại thường từ 10-20m) khiến 100% sinh viên bị từ chối; hoặc cấu hình bán kính 50,000 mét khiến sinh viên ở tỉnh khác vẫn check-in được.
- **Quy tắc đề xuất (BR-CHK-BOUNDS):**
  > **Quy tắc BR-CHK-BOUNDS:**
  > 1. Bán kính Geofencing bắt buộc nằm trong giới hạn: **$30m \le geofence\_radius\_meters \le 500m$** (Giá trị mặc định khuyến nghị: $100m$).
  > 2. Ngưỡng sai số định vị thiết bị tối đa cho phép: **$gps\_accuracy\_meters \le 100m$**. Nếu thiết bị báo sai số $> 100m$, hệ thống tự động coi tín hiệu không đáng tin cậy và yêu cầu nộp minh chứng ảnh.
