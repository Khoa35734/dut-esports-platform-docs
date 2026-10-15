# DANH MỤC LỖI VÀ BẤT THƯỜNG TRONG SRS (SRS DEFECT & ISSUE REGISTRY)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Tài liệu tham chiếu:** SRS 1.1 (29/09/2026), `database_schema.sql` (v2.0)  
**Người lập:** QA Automation Architect & Test Specialist  
**Ngày cập nhật:** 15/10/2026  

---

## BẢNG TỔNG HỢP DANH MỤC PHÁT HIỆN

| Mã Lỗi (Issue ID) | Phân loại (Category) | Mức độ (Severity) | Mã Yêu cầu (Req ID) | Phân hệ (Subsystem) | Trạng thái (Status) |
|---|---|:---:|---|---|:---:|
| **ISSUE-SRS-001** | BUSINESS_LOGIC_RISK | **Critical** | FR-TEAM-03 | Đăng ký & Tuyển quân | OPEN |
| **ISSUE-SRS-002** | DATABASE_DESIGN_RISK | **Critical** | FR-TEAM-01, 03 | Cơ sở Dữ liệu & Đăng ký | OPEN |
| **ISSUE-SRS-003** | MISSING_REQUIREMENT | **High** | FR-TRN-03 | Quản lý Nhánh đấu | OPEN |
| **ISSUE-SRS-004** | BUSINESS_LOGIC_RISK | **High** | FR-TRN-02 | Vòng đời Giải đấu | OPEN |
| **ISSUE-SRS-005** | AMBIGUOUS_REQUIREMENT | **Medium** | FR-TRN-04 | Chia bảng TFT | OPEN |
| **ISSUE-SRS-006** | SECURITY_RISK | **High** | FR-CHK-01..03 | Điểm danh Multi-modal | OPEN |
| **ISSUE-SRS-007** | IMPLEMENTATION_DEFECT | **Critical** | FR-TRN-03, 04 | Nhánh đấu & Thuật toán | CONFIRMED |
| **ISSUE-SRS-008** | IMPROVEMENT_SUGGESTION| **Medium** | FR-CRT-01..04 | E-Certificate & EDA | OPEN |
| **ISSUE-SRS-009** | DATABASE_DESIGN_RISK | **High** | FR-TRN-02 | Toàn vẹn Dữ liệu Xóa tầng | OPEN |
| **ISSUE-SRS-010** | BUSINESS_LOGIC_RISK | **Medium** | FR-KYC-03 | Xét duyệt KYC & Hủy giải | OPEN |

---

## CHI TIẾT TỪNG PHÁT HIỆN (DETAILED DEFECT SPECIFICATIONS)

---

### ISSUE-SRS-001: Race Condition khi duyệt gia nhập đội đồng thời
- **Phân loại:** `BUSINESS_LOGIC_RISK`
- **Mức độ nghiêm trọng:** `Critical`
- **Mã Yêu cầu liên quan:** `FR-TEAM-03`
- **Mục SRS:** Mục 3.2 — Bảng FR-TEAM-03 & Tiêu chí nghiệm thu cốt lõi
- **Mô tả vấn đề:**
  SRS 1.1 yêu cầu: "Hệ thống kiểm tra trong một giao dịch: người chơi chưa thuộc đội khác trong cùng giải... Nếu đủ điều kiện thì thêm thành viên". Tuy nhiên, SRS không chỉ rõ cấp độ cô lập giao dịch (Transaction Isolation Level) hoặc kỹ thuật khóa hàng (Row-level Locking) tại cơ sở dữ liệu.
- **Bằng chứng & Phản ví dụ logic (Counterexample):**
  - Giả sử VĐV tự do X gửi 2 yêu cầu gia nhập tới Đội A và Đội B trong cùng giải đấu T.
  - Cả 2 đội trưởng của Đội A và Đội B cùng lúc mở Dashboard và nhấn nút "Chấp nhận" (Accept) tại thời điểm $t_0$.
  - Cả 2 luồng API đều thực hiện câu lệnh:
    `SELECT COUNT(*) FROM registration_members rm JOIN registrations r ON ... WHERE rm.participant_id = X AND r.tournament_id = T;`
  - Vì cả 2 giao dịch đều đọc tại thời điểm X chưa được thêm vào đội nào, kết quả trả về `0`.
  - Cả 2 giao dịch cùng thực hiện lệnh `INSERT INTO registration_members` thành công.
  - **Hậu quả:** VĐV X thuộc về cả 2 đội thi đấu trong cùng một giải, gây phá vỡ nhánh đấu và sai lệch kết quả.
- **Hành vi mong muốn:**
  Hệ thống bắt buộc phải sử dụng mức cô lập `SERIALIZABLE` hoặc áp dụng khóa bi quan `SELECT id FROM participants WHERE id = X FOR UPDATE` trước khi kiểm tra trạng thái đội của VĐV.
- **Đề xuất khắc phục:** Bổ sung quy tắc nghiệp vụ `BR-TEAM-CONCURRENCY` vào SRS và cập nhật mã nguồn backend với cơ chế khóa hàng.
- **Phân tích tác động:** Tác động trực tiếp đến tính toàn vẹn của danh sách thi đấu và bảng kết quả.
- **Kịch bản kiểm thử hồi quy:** `TC-API-REG-CONCURRENT-JOIN-001` (Gửi đồng thời 2 request Accept cho cùng 1 thí sinh).
- **Trạng thái:** `OPEN` (Đã có đề xuất xử lý).

---

### ISSUE-SRS-002: Bảng `registration_members` thiếu khóa ngoại và ràng buộc duy nhất theo giải đấu
- **Phân loại:** `DATABASE_DESIGN_RISK`
- **Mức độ nghiêm trọng:** `Critical`
- **Mã Yêu cầu liên quan:** `FR-TEAM-01`, `FR-TEAM-03`, Phần 6 (Data Model)
- **Mục SRS:** Mục 6.2 (ERD) và `database_schema.sql` (Bảng 6)
- **Mô tả vấn đề:**
  Trong `database_schema.sql`, bảng `registration_members` có cấu trúc:
  ```sql
  CREATE TABLE public.registration_members (
      id UUID PRIMARY KEY,
      registration_id UUID NOT NULL REFERENCES registrations(id),
      participant_id UUID NOT NULL REFERENCES participants(id),
      ...
      CONSTRAINT uq_reg_member UNIQUE (registration_id, participant_id)
  );
  ```
  Ràng buộc `uq_reg_member` chỉ đảm bảo một thí sinh không bị thêm 2 lần vào CÙNG MỘT ĐỘI (`registration_id`). Nó hoàn toàn BỎ NGỎ khả năng một thí sinh bị thêm vào 2 đội khác nhau (`registration_id_1` và `registration_id_2`) của cùng một giải đấu.
- **Bằng chứng:** Bảng `registration_members` không có cột `tournament_id`, do đó không thể tạo chỉ mục duy nhất `UNIQUE(tournament_id, participant_id)` ở tầng cơ sở dữ liệu vật lý.
- **Hành vi mong muốn:**
  Cơ sở dữ liệu phải bảo vệ dữ liệu ở mức vật lý (Physical DB Constraint), không phụ thuộc 100% vào mã ứng dụng.
- **Đề xuất khắc phục:**
  Thêm cột `tournament_id UUID NOT NULL REFERENCES tournaments(id)` vào bảng `registration_members`, kèm chỉ mục:
  `CREATE UNIQUE INDEX uq_participant_per_tournament ON registration_members(tournament_id, participant_id);`
- **Phân tích tác động:** Cần migration CSDL để thêm cột và đồng bộ dữ liệu lịch sử.
- **Kịch bản kiểm thử hồi quy:** `TC-DB-MEMBER-UNIQUENESS-001`.
- **Trạng thái:** `OPEN`.

---

### ISSUE-SRS-003: Thiếu đặc tả kịch bản Reset Nhánh Chung kết Tổng (Grand Final Reset) trong Double Elimination
- **Phân loại:** `MISSING_REQUIREMENT`
- **Mức độ nghiêm trọng:** `High`
- **Mã Yêu cầu liên quan:** `FR-TRN-03`
- **Mục SRS:** Mục 3.3 — Bảng FR-TRN-03 và Tiêu chí nghiệm thu
- **Mô tả vấn đề:**
  SRS 1.1 yêu cầu hỗ trợ thể thức Nhánh thắng - Nhánh thua (Double Elimination). Tuy nhiên, đặc tả không mô tả quy tắc xử lý khi Đội vô địch Nhánh Thua thắng Đội vô địch Nhánh Thắng tại trận Chung kết đầu tiên (Match 1).
- **Phản ví dụ logic:**
  Theo luật thể thao điện tử chuẩn quốc tế (Double Elimination Rulebook):
  - Đội nhánh thắng chưa thua trận nào (0 trận thua).
  - Đội nhánh thua đã thua 1 trận (1 trận thua).
  - Nếu Đội nhánh thua thắng Chung kết 1: Đội nhánh thắng lúc này mới nhận 1 trận thua. Cả hai đội đều có 1 trận thua, do đó BẮT BUỘC phải kích hoạt Trận đấu thứ 2 (Grand Final Reset Match) để phân định ngôi vô địch.
  - SRS 1.1 hoàn toàn không có thuộc tính hoặc trạng thái nào trong bảng `matches` để đại diện cho trận Reset tiềm năng này.
- **Hành vi mong muốn:**
  Cấu hình nhánh Double Elimination phải cho phép định nghĩa trước một trận đấu điều kiện (`is_reset_match = TRUE`) liên kết với trận chung kết chính.
- **Đề xuất khắc phục:** Bổ sung quy tắc nghiệp vụ `BR-BRACKET-DOUBLE-RESET` vào SRS 1.1 và cập nhật ERD.
- **Kịch bản kiểm thử hồi quy:** `TC-UNIT-BRACKET-DOUBLE-ELIM-RESET-001`.
- **Trạng thái:** `OPEN`.

---

### ISSUE-SRS-004: Cho phép thay đổi cấu hình thể thức sau khi đã mở cổng đăng ký
- **Phân loại:** `BUSINESS_LOGIC_RISK`
- **Mức độ nghiêm trọng:** `High`
- **Mã Yêu cầu liên quan:** `FR-TRN-02`
- **Mục SRS:** Mục 3.3 — Vận hành Vòng đời Giải đấu
- **Mô tả vấn đề:**
  SRS không quy định cấm cập nhật các trường cốt lõi của giải đấu (`game_category`, `min_team_size`, `max_team_size`, `form_schema`) khi giải đã chuyển sang trạng thái `open_registration` và đã có đơn nộp.
- **Phản ví dụ logic:**
  Giải đấu đang ở trạng thái `open_registration` cho bộ môn Liên Quân Mobile (`min_team_size = 5`, `max_team_size = 7`). Có 10 đội đã nộp đơn với 6 thành viên mỗi đội. Admin gọi API cập nhật giải đấu, đổi `max_team_size = 4`. Lúc này dữ liệu của 10 đội đã nộp rơi vào trạng thái vi phạm điều lệ mà không có cơ chế cảnh báo hoặc xử lý chuyển tiếp.
- **Hành vi mong muốn:**
  Khi `tournaments.status != 'draft'`, hệ thống phải khóa (chặn sửa) các thuộc tính: `game_category`, `min_team_size`, `max_team_size`, `form_schema`. Chỉ cho phép chỉnh sửa thông tin mô tả, banner, thời gian đóng cổng (gia hạn).
- **Đề xuất khắc phục:** Thêm kiểm tra điều kiện bảo vệ (Guard Check) tại controller cập nhật giải đấu.
- **Trạng thái:** `OPEN`.

---

### ISSUE-SRS-005: Khoảng trống toán học trong chia phòng TFT (Gaps in TFT Room Allocation)
- **Phân loại:** `AMBIGUOUS_REQUIREMENT`
- **Mức độ nghiêm trọng:** `Medium`
- **Mã Yêu cầu liên quan:** `FR-TRN-04`
- **Mục SRS:** Mục 3.3 — Bảng FR-TRN-04 và Quy tắc chia phòng TFT
- **Mô tả vấn đề:**
  SRS nêu: "Với mọi N, hệ thống chia phòng 7–8 người theo quy tắc... Nếu không tồn tại m phù hợp, hệ thống không sinh phòng và hiển thị lý do để BTC chọn thể thức khác hoặc điều chỉnh danh sách".
  Tuy nhiên, SRS không chỉ rõ giao diện hoặc hệ thống có tự động đề xuất số lượng cần bù/loại bỏ để đạt trạng thái hợp lệ hay không.
- **Bằng chứng toán học:**
  Các giá trị $N \in \{1..6, 9..13, 17..20, 25..27, 33..34, 41\}$ là các giá trị không thể phân bổ thành tổng của các số 7 và 8 (Frobenius Problem for {7, 8}).
  Ví dụ với $N = 25$: Hệ thống báo lỗi và dừng lại, khiến người dùng không biết phải thêm bao nhiêu vận động viên dự bị để giải đấu có thể tiếp tục.
- **Đề xuất khắc phục:**
  Thuật toán chia phòng cần trả về:
  1. `status: 'INVALID_CAPACITY'`
  2. `delta_to_next_valid`: Số lượng thí sinh cần bổ sung ít nhất để hợp lệ (ví dụ với $N=25$, cần thêm 3 thí sinh để đạt $N=28$ với 4 phòng 7 người).
  3. `delta_to_prev_valid`: Số lượng thí sinh cần cắt giảm (với $N=25$, giảm 1 thí sinh để đạt $N=24$ với 3 phòng 8 người).
- **Trạng thái:** `OPEN`.

---

### ISSUE-SRS-006: Nguy cơ gian lận giả lập vị trí GPS (Mock Location Spoofing)
- **Phân loại:** `SECURITY_RISK`
- **Mức độ nghiêm trọng:** `High`
- **Mã Yêu cầu liên quan:** `FR-CHK-01`, `FR-CHK-02`, `FR-CHK-03`
- **Mục SRS:** Mục 3.4 — Check-in Đa phương thức & Giám sát Tọa độ
- **Mô tả vấn đề:**
  SRS phụ thuộc vào Geolocation API của trình duyệt. Trên hệ điều hành Android, thí sinh ở nhà có thể sử dụng ứng dụng "Fake GPS / Mock Location" kết hợp với việc nhờ người ở sàn đấu chụp ảnh mã QR động gửi về qua Zalo/Telegram. Thí sinh ở nhà quét mã ảnh từ thư viện hoặc màn hình máy tính, trình duyệt gửi tọa độ giả mạo khớp với tâm sàn đấu.
- **Bằng chứng:** W3C Geolocation API trên trình duyệt không cung cấp cờ `isFromMockProvider` đáng tin cậy như native Android SDK.
- **Hành vi mong muốn & Giảm thiểu rủi ro:**
  SRS đã trung thực ghi nhận: "QR/GPS là tín hiệu kiểm tra và không được mô tả là ngăn chặn tuyệt đối việc gian lận".
  Tuy nhiên cần bổ sung biện pháp kỹ thuật giảm thiểu:
  1. Kiểm tra IP Client: Nếu IP của thí sinh không thuộc dải mạng Wi-Fi tại sàn đấu trường Bách khoa (DUT Campus Wi-Fi IP Subnet), đánh dấu bản ghi điểm danh là `flagged_suspicious = TRUE` để CTV trên bản đồ OSM kiểm tra lại.
  2. Ngăn tải ảnh mã QR từ album: Camera Stream HTML5 chỉ cho phép quét trực tiếp từ luồng video thực, không hỗ trợ nút "Chọn ảnh từ máy".
- **Trạng thái:** `OPEN`.

---

### ISSUE-SRS-007: Phân hệ Nhánh đấu và Chia phòng TFT chưa được hiện thực hóa trong Mã nguồn
- **Phân loại:** `IMPLEMENTATION_DEFECT`
- **Mức độ nghiêm trọng:** `Critical`
- **Mã Yêu cầu liên quan:** `FR-TRN-03`, `FR-TRN-04`
- **Mục SRS:** Mục 3.3
- **Mô tả vấn đề:**
  Khảo sát mã nguồn backend (`Web-giai-dau/backend/src`) cho thấy: CSDL có các bảng `brackets`, `bracket_rounds`, `matches`, `match_participants`. Tuy nhiên, hoàn toàn KHÔNG có controller hoặc service nào thực hiện thuật toán sinh nhánh Single/Double Elimination hoặc thuật toán chia phòng TFT.
- **Hậu quả:** Hệ thống hiện tại không thể chuyển giải đấu sang giai đoạn thi đấu tự động bằng phần mềm.
- **Khuyến nghị cho Đồ án / Solo Developer:**
  Do thời lượng dự án và định hướng kiểm thử hàn lâm, chọn chính xác **02 chức năng trọng tâm đã hoàn thiện đầy đủ**:
  - **Function A:** Tournament Registration & Team Recruitment
  - **Function B:** Multi-modal Tournament Check-in
  Hai tính năng này có đầy đủ mã nguồn backend, frontend và kiểm thử tự động.
- **Trạng thái:** `CONFIRMED`.

---

### ISSUE-SRS-008: Worker sinh E-Certificate chưa có cơ chế bù trừ Idempotency
- **Phân loại:** `IMPROVEMENT_SUGGESTION`
- **Mức độ nghiêm trọng:** `Medium`
- **Mã Yêu cầu liên quan:** `FR-CRT-01`, `FR-CRT-02`
- **Mô tả vấn đề:**
  Khi Admin đóng giải (`tournament.completed`), Worker nền render hàng loạt chứng chỉ PDF. Nếu worker gặp sự cố sập giữa chừng tại chứng chỉ thứ 50/100 và hệ thống tự động khởi động lại (Worker Retry), worker sẽ quét lại danh sách và cố gắng ghi đè chứng chỉ của 50 người đầu tiên.
- **Đề xuất khắc phục:** Câu lệnh chèn chứng chỉ phải áp dụng:
  `ON CONFLICT (tournament_id, participant_id) WHERE recipient_type = 'athlete' DO NOTHING;`
- **Trạng thái:** `OPEN`.

---

### ISSUE-SRS-009: Nguy cơ mất dấu vết kiểm toán khi xóa tầng (ON DELETE CASCADE)
- **Phân loại:** `DATABASE_DESIGN_RISK`
- **Mức độ nghiêm trọng:** `High`
- **Mã Yêu cầu liên quan:** `FR-AUD-01`, `FR-AUD-02`, Phần 6 (Data Model)
- **Mô tả vấn đề:**
  Trong `database_schema.sql`, bảng `registrations` thiết lập `ON DELETE CASCADE` theo `tournaments(id)`. Nếu Admin xóa nhầm một giải đấu trong CSDL, toàn bộ lịch sử đăng ký của hàng trăm sinh viên sẽ bị xóa sạch khỏi đĩa mà không thể khôi phục.
- **Đề xuất khắc phục:** Áp dụng mô hình Xóa mềm (Soft Delete) với trường `deleted_at TIMESTAMP WITH TIME ZONE` hoặc chuyển thành `ON DELETE RESTRICT` khi giải đấu đã có đăng ký.
- **Trạng thái:** `OPEN`.

---

### ISSUE-SRS-010: Thí sinh bị từ chối KYC nhưng đã lỡ đăng ký đội trưởng giải đấu
- **Phân loại:** `BUSINESS_LOGIC_RISK`
- **Mức độ nghiêm trọng:** `Medium`
- **Mã Yêu cầu liên quan:** `FR-KYC-03`, `FR-TEAM-01`
- **Mô tả vấn đề:**
  Theo luồng thông thường: Sinh viên phải có `kyc_status = 'approved'` mới được tạo đội. Nhưng nếu sinh viên nộp lại ảnh thẻ sai hoặc có hành vi gian lận danh tính sau đó bị Admin thu hồi KYC (`kyc_status -> 'rejected'`), thì các đơn đăng ký giải mà sinh viên đó đang làm Đội trưởng sẽ được xử lý ra sao?
- **Đề xuất khắc phục:** Bổ sung quy tắc nghiệp vụ `BR-KYC-REVOCATION`: Khi một tài khoản bị thu hồi hoặc từ chối KYC, hệ thống tự động chuyển trạng thái các đội do thí sinh đó làm đội trưởng sang `flagged_kyc_invalid`, đồng thời gửi thông báo yêu cầu đội bầu đội trưởng mới trong vòng 48 giờ.
- **Trạng thái:** `OPEN`.
