# ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS) — BẢN THẢO CẢI TIẾN (REVISED DRAFT)
## NỀN TẢNG QUẢN LÝ GIẢI ĐẤU THỂ THAO ĐIỆN TỬ DUT ESPORTS
**Tham chiếu cấu trúc:** IEEE Std 830-1998  
**Phiên bản tài liệu gốc:** 1.1 (29/09/2026)  
**Phiên bản dự thảo cải tiến:** **1.2-DRAFT** (15/10/2026)  
**Tổ chức phát triển:** Câu lạc bộ Thể thao Điện tử - Trường Đại học Bách khoa (DUT)  
**Người biên soạn đề xuất:** Senior Software Engineer & QA Testing Architect (Solo Developer)  
**Trạng thái pháp lý:** *Bản thảo kỹ thuật tích hợp các cải tiến nghiệp vụ, khóa trạng thái và an toàn dữ liệu từ kết quả kiểm toán Phase 1 & 2. Các phần cải tiến được gắn nhãn `[PROPOSED IMPROVEMENT - REV-1.2]` và ghi nhận trong `DECISION_LOG.md`.*

---

## MỤC LỤC TỔNG QUAN
1. [Phần 1: Giới thiệu & Định danh Hệ thống](#phần-1-giới-thiệu--định-danh-hệ-thống)
2. [Phần 2: Mô tả Tổng quan & Kiến trúc EDA](#phần-2-mô-tả-tổng-quan--kiến-trúc-eda)
3. [Phần 3: Yêu cầu Chức năng (Functional Requirements)](#phần-3-yêu-cầu-chức-năng-functional-requirements)
4. [Phần 4: Yêu cầu Giao diện Bên ngoài (External Interfaces)](#phần-4-yêu-cầu-giao-diện-bên-ngoài-external-interfaces)
5. [Phần 5: Yêu cầu Phi chức năng (Non-Functional Requirements)](#phần-5-yêu-cầu-phi-chức-năng-non-functional-requirements)
6. [Phần 6: Mô hình Dữ liệu Chuẩn hóa 18 Bảng (Data Model)](#phần-6-mô-hình-dữ-liệu-chuẩn-hóa-18-bảng-data-model)
7. [Phần 7: Ma trận Chuyển trạng thái Hình thức (State Transition Tables)](#phần-7-ma-trận-chuyển-trạng-thái-hình-thức)
8. [Phần 8: Tiêu chí Chấp nhận & Kịch bản Gherkin Mở rộng](#phần-8-tiêu-chí-chấp-nhận--kịch-bản-gherkin-mở-rộng)
9. [Phần 9: Các Ràng buộc Hệ thống & Phụ lục Phân tích Rủi ro](#phần-9-các-ràng-buộc-hệ-thống--phụ-lục-phân-tích-rủi-ro)

---

## Phần 1: Giới thiệu & Định danh Hệ thống

### 1.1 Mục đích (Purpose)
Tài liệu SRS 1.2-DRAFT đóng vai trò là khung tham chiếu kỹ thuật và cơ sở kiểm thử chính xác cho Nền tảng Quản lý Giải đấu DUT ESPORTS. Bản dự thảo này bảo toàn 100% mục tiêu ban đầu:
- Tự động hóa khâu đăng ký, tuyển quân, sinh nhánh đấu, check-in và cấp phát chứng chỉ số.
- Bảo vệ dữ liệu cá nhân theo nguyên tắc tối thiểu hóa (Triệt tiêu 100% việc thu thập CCCD/CMND).
- Tối ưu hóa chi phí bằng cách sử dụng nền tảng bản đồ số nguồn mở OpenStreetMap kết hợp Leaflet.js.

### 1.2 Ranh giới Phạm vi Sản phẩm (Product Scope)
Bảo toàn bảng ranh giới phạm vi hệ thống của bản 1.1:
- **Định danh người dùng:** Xác thực sinh viên nội bộ DUT và trường ngoài qua mã số sinh viên (`student_id`) kết hợp 02 ảnh thẻ SV. Tuyệt đối Out-of-Scope đối với CCCD và VNeID.
- **Bản đồ & Vị trí:** Leaflet.js với OSM tile server; hiển thị vị trí cho CTV được giao giải.
- **Nhánh đấu & Check-in:** Nhánh Single/Double Elimination, chia phòng TFT ($N \bmod 8$), QR Code động 30s + GPS Geofencing + Minh chứng ảnh.

---

## Phần 2: Mô tả Tổng quan & Kiến trúc EDA

Hệ thống tuân thủ kiến trúc Event-Driven Architecture (EDA) phân tách 2 luồng:
1. **Luồng Đồng bộ (Synchronous):** API Gateway (Express 5.0), Xác thực JWT, Kiểm tra Geofencing thời gian thực, Duyệt hồ sơ.
2. **Luồng Bất đồng bộ (Asynchronous):** Xử lý hàng đợi tác vụ nền (Background Worker) cho các sự kiện:
   - `checkin.approved`: Kích hoạt trạng thái sẵn sàng thi đấu.
   - `tournament.completed`: Render hàng loạt E-Certificate PDF có mã QR độc bản.
   - `report.export_requested`: Xuất báo cáo streaming dung lượng lớn chống tràn bộ nhớ RAM.

---

## Phần 3: Yêu cầu Chức năng (Functional Requirements)

### 3.1 Phân hệ Tài khoản & Xác thực KYC
- **FR-AUTH-01 (Tạo và bảo vệ tài khoản):** Lưu hash mật khẩu bằng bcrypt (cost $\ge 10$) hoặc Argon2id; token email verify/reset mật khẩu lưu hash và hết hạn sau 30 phút.
- **FR-KYC-01 (Đăng ký hồ sơ & 02 ảnh thẻ SV):** Bắt buộc 02 ảnh: (1) Mặt trước thẻ SV; (2) Chân dung cầm thẻ SV. Dung lượng $\le 5MB$, định dạng `.jpg`, `.jpeg`, `.png`, kiểm tra Magic Bytes ở header tệp.
- **FR-KYC-02 (Phân loại đối tượng sinh viên):** Tự động phân loại `account_type` thành `internal` (ĐH Bách khoa) và `external` (Trường ngoài) dựa trên tên trường.

> [!NOTE]
> **[PROPOSED IMPROVEMENT - REV-1.2 / BR-KYC-REVOCATION] Thu hồi KYC Hậu Đăng ký**  
> Khi tài khoản thí sinh bị chuyển từ `kyc_status = 'approved'` sang `'rejected'` do phát hiện gian lận sau khi đã đăng ký thi đấu:
> 1. Hệ thống tự động thu hồi tư cách của thí sinh tại toàn bộ các giải đấu đang `open_registration` hoặc `closed_registration`.
> 2. Đơn đăng ký đội có thí sinh bị loại có thời hạn 24 giờ để tuyển thành viên thay thế nếu vi phạm điều kiện $sĩ\_số < min\_team\_size$.
> 3. Nếu giải đấu đã bắt đầu thi đấu (`ongoing`): Mọi trận đấu tiếp theo có sự tham gia của thí sinh đó bị xử thua tự động (Walkover).

---

### 3.2 Phân hệ Tuyển quân & Quản lý Đội (Recruitment & Team Join)
- **FR-TEAM-01 (Khởi tạo Đội & Tuyển quân):** Đội trưởng (đã duyệt KYC) tạo đơn; bật cờ `is_recruiting = true` khi chưa đủ sĩ số.
- **FR-TEAM-02 (Bảng tin Tuyển quân Real-time):** Tìm kiếm và lọc đội theo game, vị trí trống.
- **FR-TEAM-03 (Yêu cầu gia nhập đội):** VĐV tự do gửi yêu cầu, Đội trưởng Chấp nhận hoặc Từ chối.

> [!IMPORTANT]
> **[PROPOSED IMPROVEMENT - REV-1.2 / BR-TEAM-CONCURRENCY] Kiểm soát Xung đột Đồng thời khi Gia nhập Đội**  
> Thao tác Chấp nhận Yêu cầu Gia nhập đội (`POST /api/team-requests/:id/accept`) bắt buộc thực thi trong một Giao dịch CSDL khóa hàng (Row-level Lock):
> ```sql
> -- 1. Khóa tài khoản thí sinh để ngăn chặn việc được đội khác chấp nhận cùng lúc
> SELECT id FROM participants WHERE id = $participant_id FOR UPDATE;
> -- 2. Kiểm tra thí sinh đã thuộc bất kỳ đội nào khác trong cùng giải đấu hay chưa
> -- 3. Kiểm tra sĩ số hiện tại của đội: nếu số thành viên đã đạt max_team_size -> Throw 409 Conflict
> -- 4. Thêm thành viên vào đội
> INSERT INTO registration_members (registration_id, participant_id, is_captain, ingame_id) ...
> -- 5. Nếu sĩ số mới đạt max_team_size: Tự động cập nhật is_recruiting = false
> -- 6. Tự động chuyển toàn bộ các join requests pending khác của thí sinh này sang status = 'rejected'
> ```

---

### 3.3 Phân hệ Quản lý Giải đấu & Nhánh đấu (Tournaments & Brackets)
- **FR-TRN-01 (Cấu hình Biểu mẫu Động):** Lưu trữ cấu hình `form_schema` dạng JSONB.

> [!WARNING]
> **[PROPOSED IMPROVEMENT - REV-1.2 / BR-TRN-LOCK] Khóa Cấu hình khi Mở Đăng ký**  
> Ngay khi giải đấu chuyển sang trạng thái `open_registration`:
> 1. Hệ thống **khóa bất biến** các trường: `game_category`, `min_team_size`, `max_team_size`, `form_schema`.
> 2. Mọi cố gắng thay đổi các trường trên qua API trả về mã lỗi HTTP `400 Bad Request` kèm thông báo `"TOURNAMENT_LOCKED_CANNOT_MODIFY_STRUCTURE"`.

- **FR-TRN-02 (Vòng đời Giải đấu):** Quản lý nghiêm ngặt qua 6 trạng thái chuẩn: `draft`, `open_registration`, `closed_registration`, `ongoing`, `completed`, `cancelled` (Chi tiết tại Phần 7).
- **FR-TRN-03 (Tự động sinh nhánh đấu):** Hỗ trợ Single Elimination và Double Elimination.

> [!NOTE]
> **[PROPOSED IMPROVEMENT - REV-1.2 / BR-BRACKET-DOUBLE-RESET] Quy tắc Trận đấu Phụ Grand Final Reset**  
> Trong thể thức Double Elimination: Trận Chung kết Tổng có thêm 1 trận đấu phụ điều kiện (`is_bracket_reset = true`).
> - Nếu Đội Vô địch Nhánh Thắng (WB Winner) thắng trận 1: WB Winner đăng quang, trận Reset bị hủy (`status = 'cancelled'`).
> - Nếu Đội Vô địch Nhánh Thua (LB Winner) thắng trận 1: Kích hoạt trận Reset (`status = 'scheduled'`) để thi đấu phân định ngôi vô địch.

- **FR-TRN-04 (Thuật toán Chia phòng TFT):** Số phòng $m = \lceil N/8 \rceil$ thỏa mãn $\lceil N/8 \rceil \le m \le \lfloor N/7 \rfloor$. Số phòng 8 người: $N - 7m$; Số phòng 7 người: $8m - N$.

> [!TIP]
> **[PROPOSED IMPROVEMENT - REV-1.2 / BR-TFT-FEEDBACK] Gợi ý Bù trừ Thí sinh khi Chia phòng TFT Không hợp lệ**  
> Đối với các giá trị $N \in \{1..6, 9..13, 17..20, 25..27, 33..34, 41\}$, API trả về thông tin gợi ý bù trừ cụ thể: `add_needed` (số thí sinh cần bổ sung để đạt mốc hợp lệ tiếp theo) và `remove_needed` (số thí sinh cần bớt) để Ban tổ chức dễ dàng xử lý danh sách.

---

### 3.4 Phân hệ Check-in Đa phương thức (Multi-modal Check-in)
- **FR-CHK-01 (Mã QR động 30s):** Mã QR xoay vòng chứa `token_hash` giải đấu, thời hạn 30 giây. Cho phép nhiều thí sinh tại sàn đấu cùng quét trong 30 giây; mỗi thí sinh chỉ được điểm danh 01 lần duy nhất trên bảng `check_ins` (`UNIQUE(tournament_id, participant_id)`).
- **FR-CHK-02 (Xác thực Geofencing):** Thu thập tọa độ GPS. Điều kiện hợp lệ: $Khoảng\_cách \le geofence\_radius$ (mặc định 100m, giới hạn cấu hình $30m \le r \le 500m$) VÀ sai số $gps\_accuracy \le 100m$.
- **FR-CHK-03 (Nhật ký Thiết bị):** Thu thập IP, User-Agent, GPS accuracy để phát hiện gian lận.
- **FR-CHK-04 (Nộp Minh chứng Dự phòng):** Cho phép nộp ảnh minh chứng phòng chờ game hoặc ảnh tại sàn đấu khi lỗi GPS. Bản ghi tạo với trạng thái `pending_review`.
- **FR-CHK-05 (Bản đồ Giám sát Leaflet/OSM):** CTV theo dõi tọa độ thí sinh theo cụm (Marker Cluster) trên bản đồ OpenStreetMap và duyệt các ca nộp minh chứng.

---

### 3.5 Phân hệ E-Certificate, Báo cáo & Audit Logs
- **FR-CRT-01..04:** Tự động kích hoạt render PDF khi giải `completed`. Tra cứu công khai tại `/verify-certificate?code={certificate_code}`. Che mờ tên nếu `public_name_allowed = false`.
- **FR-REP-01..03:** Tác vụ xuất nền dạng Streaming Response chống tràn RAM (đáp ứng tiêu chuẩn NFR-PRF-02: Peak RSS không tăng quá 256 MiB với 10.000 dòng CSV). Che mờ SĐT và Email đối với tài khoản không phải Admin.
- **FR-AUD-01..02:** Bảng `audit_logs` bất biến Append-Only ghi vết mọi thay đổi dữ liệu nhạy cảm.

---

## Phần 4 & 5: Giao diện & Yêu cầu Phi chức năng (NFR)

Toàn bộ các tiêu chuẩn bảo mật PII (NFR-SEC-01..07), ngân sách bản đồ OSM (NFR-CST-01), hiệu năng p95 < 2s cho điểm danh (NFR-PRF-01) và độ sẵn sàng EDA (NFR-REL-01) được bảo toàn nguyên vẹn như bản SRS 1.1.

---

## Phần 6: Lược đồ Cơ sở Dữ liệu Chuẩn hóa 18 Bảng (Reconciled DDL)

Cơ sở dữ liệu vật lý bao gồm 18 bảng cốt lõi với khóa chính UUID và các ràng buộc toàn vẹn:
1. `users` (Tài khoản người dùng toàn hệ thống)
2. `participants` (Hồ sơ KYC sinh viên - Zero CCCD)
3. `auth_tokens` (Mã xác thực email & mật khẩu có hạn)
4. `tournaments` (Giải đấu, cấu hình Geofencing & JSONB form)
5. `tournament_organizers` (Phân quyền CTV theo giải đấu)
6. `registrations` (Đơn đăng ký giải đấu)
7. `registration_members` (Danh sách thành viên đội - Đề xuất thêm cột `tournament_id`)
8. `team_join_requests` (Yêu cầu xin gia nhập đội tuyển quân)
9. `checkin_qr_tokens` (Mã QR động 30s)
10. `check_ins` (Nhật ký điểm danh sàn đấu)
11. `brackets` (Nhánh đấu)
12. `bracket_rounds` (Vòng đấu)
13. `matches` (Trận đấu & Phòng đấu)
14. `match_participants` (Thí sinh / Đội tham gia trận)
15. `match_games` (Chi tiết từng ván BO)
16. `certificates` (Chứng chỉ số E-Certificate)
17. `report_exports` (Tác vụ xuất báo cáo nền)
18. `audit_logs` (Nhật ký kiểm toán bất biến)

---

## Phần 7: Ma trận Chuyển trạng thái Hình thức

*Toàn bộ chi tiết các điều kiện bảo vệ (Guard Conditions) và các chuyển đổi bị cấm được quy định chính thức tại tệp [STATE_TRANSITION_MATRIX.md](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/testing/srs-audit/STATE_TRANSITION_MATRIX.md).*

---

## Phần 8: Kịch bản Chấp nhận Gherkin Mở rộng

### Kịch bản Tuyển quân Đồng thời
```gherkin
Feature: Kiểm soát Đồng thời khi Tuyển quân (Concurrency Team Join)
  Scenario: Chặn thí sinh được nhận vào 2 đội cùng lúc
    Given Thí sinh "Lê Văn D" gửi yêu cầu gia nhập tới Đội Alpha và Đội Beta trong Giải đấu Liên Quân
    And Cả 2 đội đều đang mở cờ is_recruiting = true
    When Đội trưởng Đội Alpha và Đội trưởng Đội Beta cùng bấm "Chấp nhận" tại thời điểm t0
    Then Hệ thống phải thực thi tuần tự có khóa hàng (FOR UPDATE)
    And Đúng 1 đội nhận thông báo "Thành công" và thí sinh được thêm vào registration_members
    And Đội còn lại nhận thông báo lỗi "Thí sinh đã thuộc về đội khác trong giải đấu"
    And Sĩ số Đội Alpha và Đội Beta được cập nhật chính xác
```

### Kịch bản Điểm danh Đa phương thức
```gherkin
Feature: Điểm danh Đa phương thức tại Sàn đấu
  Scenario: Điểm danh thành công với QR động 30s và GPS hợp lệ
    Given Thí sinh "Nguyễn Văn E" có mặt tại Hội trường F trường ĐH Bách khoa
    And Tọa độ GPS của thiết bị cách tâm sàn đấu 45 mét (sai số 15 mét)
    When Thí sinh quét mã QR động hợp lệ (còn hạn 18 giây)
    Then Hệ thống ghi nhận bản ghi điểm danh với status = "approved"
    And Trả về phản hồi HTTP 200 trong thời gian < 2 giây tại p95
    And Bản đồ OSM của CTV cập nhật điểm ghim màu xanh lá cây
```
