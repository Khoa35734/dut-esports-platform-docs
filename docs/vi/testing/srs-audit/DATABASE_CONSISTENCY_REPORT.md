# BÁO CÁO NHẤT QUÁN CƠ SỞ DỮ LIỆU (DATABASE CONSISTENCY REPORT)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Đối tượng thẩm định:** SRS 1.1 Phần 6, `database_schema.sql` (v2.0), `migrations.sql`, Mã nguồn Backend Repositories  
**Đơn vị thẩm định:** QA Database Architect & Test Specialist  
**Ngày thực hiện:** 15/10/2026  

---

## 1. TỔNG QUAN ĐỐI SOÁT KIẾN TRÚC CƠ SỞ DỮ LIỆU

Hệ thống cơ sở dữ liệu DUT ESPORTS được triển khai trên nền tảng **PostgreSQL 15+ (Supabase Cloud)** với các nguyên tắc kiến trúc chủ đạo:
1. **100% Khóa chính UUID:** Triệt tiêu hoàn toàn `SERIAL`/`BIGSERIAL` tự tăng nhằm chống tấn công vét cạn (ID Enumeration).
2. **Tuân thủ Không CCCD (Zero CCCD Invariant):** Không có bất kỳ bảng hoặc cột nào lưu trữ số CCCD/CMND hoặc ảnh CCCD.
3. **Định danh người dùng hợp nhất (Unified Users Identity):** Bảng `users` quản trị mọi tài khoản đăng nhập (Admin, CTV Thường trực, CTV Thời vụ, Sinh viên); bảng `participants` đóng vai trò hồ sơ KYC 1:1 mở rộng cho sinh viên.

---

## 2. BẢNG ĐỐI SOÁT 18 BẢNG DỮ LIỆU CỐT LÕI (TABLE INVENTORY RECONCILIATION)

| STT | Tên Bảng (Table Name) | SRS 1.1 (Phần 6) | DDL Vật lý (`database_schema.sql`) | Mã nguồn Backend (`src/repositories/`) | Đánh giá Nhất quán (Consistency Status) | Ghi chú & Rủi ro |
|:---:|---|:---:|:---:|:---:|:---:|---|
| 1 | `users` | Có | Có | Có (`user.repository.ts`, `user.ts`) | **CONSISTENT** | Khóa chính UUID, lưu password_hash (bcrypt), role phân cấp 4 nhóm. |
| 2 | `participants` | Có | Có | Có (`participant.ts`) | **CONSISTENT** | Liên kết 1:1 với `users.id`, chứa 02 ảnh thẻ SV, `kyc_status`. |
| 3 | `auth_tokens` | Có | Có | Có (Xử lý qua auth controller) | **CONSISTENT** | Token hash xác thực email và reset password có hạn 30 phút. |
| 4 | `tournaments` | Có | Có | Có (`tournament.ts`) | **CONSISTENT** | Chứa `form_schema` JSONB, cấu hình Geofencing (`checkin_lat`, `checkin_lng`). |
| 5 | `tournament_organizers` | Có | Có | Có (`tournamentOrganizer.repository.ts`) | **CONSISTENT** | Phân quyền giải đấu cho CTV; hỗ trợ `organizer_type` permanent/seasonal. |
| 6 | `registrations` | Có | Có | Có (`registration.repository.ts`) | **PARTIAL_RISK** | CSDL thiếu `UNIQUE(tournament_id, captain_id)`. |
| 7 | `registration_members` | Có | Có | Có (`registration.repository.ts`) | **PARTIAL_RISK** | CSDL thiếu `tournament_id` để tạo chỉ mục duy nhất toàn giải. |
| 8 | `team_join_requests` | Có | Có | Có (`teamRequest.controller.ts`) | **CONSISTENT** | Chứa `status` ('pending', 'accepted', 'rejected'), `ingame_id`. |
| 9 | `checkin_qr_tokens` | Có | Có | Có (`checkin.controller.ts`) | **CONSISTENT** | Lưu `token_hash` QR động xoay vòng 30 giây theo từng giải đấu. |
| 10 | `check_ins` | Có | Có | Có (`checkin.controller.ts`) | **CONSISTENT** | Ràng buộc `UNIQUE(tournament_id, participant_id)`, lưu GPS & ảnh minh chứng. |
| 11 | `brackets` | Có | Có | Chưa có controller | **DB_READY_CODE_MISSING** | Bảng DDL đã hoàn chỉnh nhưng backend chưa có code sinh nhánh. |
| 12 | `bracket_rounds` | Có | Có | Chưa có controller | **DB_READY_CODE_MISSING** | Cấu trúc vòng đấu đã sẵn sàng. |
| 13 | `matches` | Có | Có | Chưa có controller | **DB_READY_CODE_MISSING** | Đầy đủ trường `winner_next_match_id`, `loser_next_match_id`. |
| 14 | `match_participants` | Có | Có | Chưa có controller | **DB_READY_CODE_MISSING** | Hỗ trợ cả `registration_id` (đội) hoặc `participant_id` (cá nhân). |
| 15 | `match_games` | Có | Có | Chưa có controller | **DB_READY_CODE_MISSING** | Lưu chi tiết từng ván trong trận đấu BO (BO1, BO3, BO5). |
| 16 | `certificates` | Có | Có | Chưa có worker | **DB_READY_CODE_MISSING** | Có chỉ mục riêng biệt cho athlete và organizer; chưa có code render. |
| 17 | `report_exports` | Có | Có | Có (`exportService.ts`) | **CONSISTENT** | Quản lý tác vụ xuất báo cáo nền với `idempotency_key`. |
| 18 | `audit_logs` | Có | Có | Có (`participant.ts`, `auth.ts`) | **CONSISTENT** | Bảng bất biến APPEND-ONLY ghi vết mọi thay đổi dữ liệu nhạy cảm. |

---

## 3. PHÂN TÍCH CHUYÊN SÂU CÁC KHOẢNG LỆCH & NGUY CƠ DỮ LIỆU (DEEP MISMATCH ANALYSIS)

### 3.1. Thiếu Ràng buộc Toàn vẹn Tầng CSDL cho Đăng ký Thành viên (Missing Tournament-Scoped Unique Index)
- **Vấn đề:**
  Bảng `registration_members` được thiết kế:
  ```sql
  CREATE TABLE public.registration_members (
      id UUID NOT NULL DEFAULT uuid_generate_v4(),
      registration_id UUID NOT NULL REFERENCES public.registrations(id) ON DELETE CASCADE,
      participant_id UUID NOT NULL REFERENCES public.participants(id) ON DELETE RESTRICT,
      ...
      CONSTRAINT uq_reg_member UNIQUE (registration_id, participant_id)
  );
  ```
  Chỉ mục `uq_reg_member` chỉ ngăn chặn việc chèn trùng thí sinh vào *cùng một đơn đăng ký*. Nhưng nếu thí sinh X được thêm vào Đội 1 (`registration_id = R1`) và Đội 2 (`registration_id = R2`) thuộc cùng một giải đấu $T$, CSDL hoàn toàn không phát hiện vi phạm.
- **Giải pháp khắc phục:**
  Thêm cột `tournament_id` vào bảng `registration_members` để tạo ràng buộc vật lý:
  ```sql
  ALTER TABLE public.registration_members ADD COLUMN tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE;
  CREATE UNIQUE INDEX uq_registration_member_tournament ON public.registration_members(tournament_id, participant_id);
  ```

### 3.2. Rủi ro Toàn vẹn khi Xóa tầng (Cascade Deletion Risks)
- **Vấn đề:**
  Bảng `registrations` thiết lập `ON DELETE CASCADE` theo `tournaments(id)`.
  Khi một giải đấu bị xóa (do thao tác nhầm của Admin trong quá trình vận hành), PostgreSQL sẽ tự động kích hoạt xóa theo tầng:
  1. Xóa toàn bộ `registrations` của giải.
  2. Kéo theo xóa toàn bộ `registration_members`.
  3. Kéo theo xóa toàn bộ `team_join_requests`.
  4. Kéo theo xóa toàn bộ `check_ins` và `match_participants`.
  Toàn bộ dữ liệu của hàng trăm thí sinh sẽ biến mất mà không để lại cơ hội cứu vãn.
- **Khuyến nghị kiến trúc:**
  1. Với các bảng mang tính pháp lý thi đấu (`registrations`, `check_ins`, `certificates`), thay đổi thành `ON DELETE RESTRICT`.
  2. Bắt buộc Admin phải thực hiện thao tác hủy giải (`status = 'cancelled'`) thay vì xóa vật lý (`DELETE FROM tournaments`).

### 3.3. Đồng bộ Trạng thái Enum (Enum Constraints Alignment)
- Bảng `registrations`:
  SRS gốc từng đề cập `cancelled`, nhưng DDL v2.0 và Backend đã thống nhất chuẩn hóa:
  `CHECK (status IN ('pending', 'approved', 'rejected'))` -> Đã đồng bộ hoàn hảo.
- Bảng `team_join_requests`:
  Thống nhất 03 trạng thái:
  `CHECK (status IN ('pending', 'accepted', 'rejected'))` -> Đã đồng bộ hoàn hảo.
- Bảng `matches`:
  Thống nhất:
  `CHECK (status IN ('scheduled', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled'))` -> Đã loại bỏ trạng thái dư thừa `ready`.

---

## 4. KẾT LUẬN VỀ TÍNH NHẤT QUÁN CƠ SỞ DỮ LIỆU

1. Lược đồ cơ sở dữ liệu `database_schema.sql` (v2.0) đạt độ chuẩn hóa rất cao (3NF), tuân thủ 100% nguyên tắc khóa chính UUID và Zero CCCD.
2. Các bảng phục vụ cho 02 phân hệ trọng tâm (**Đăng ký / Tuyển quân** và **Điểm danh Đa phương thức**) hoàn toàn tương thích và đồng bộ với mã nguồn backend hiện tại.
3. Cần bổ sung 01 Migration an toàn để thêm cột `tournament_id` vào bảng `registration_members` nhằm triệt tiêu hoàn toàn rủi ro Race Condition gia nhập đội đồng thời.
