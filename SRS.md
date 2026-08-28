# SOFTWARE REQUIREMENTS SPECIFICATION (SRS)
# Website Quản lý Giải đấu CLB DUT ESPORTS

**Phiên bản:** 1.0
**Ngày cập nhật:** 28/08/2026
**Trạng thái:** Draft

---

## 1. Giới thiệu

### 1.1 Mục đích tài liệu
Tài liệu này mô tả các yêu cầu chức năng và phi chức năng của hệ thống website quản lý giải đấu thể thao điện tử (esports) cho CLB DUT ESPORTS. Hệ thống phục vụ việc đăng ký thành viên, tổ chức giải đấu, quản lý đội/cá nhân tham gia, tạo và vận hành nhánh đấu (bracket).

### 1.2 Phạm vi hệ thống
Hệ thống là một nền tảng web cho phép:
- Sinh viên đăng ký tài khoản, tham gia các giải đấu esports do CLB tổ chức.
- CTV (cộng tác viên) tổ chức và vận hành giải đấu.
- Admin quản trị toàn bộ hệ thống: người dùng, CTV, giải đấu.

### 1.3 Định nghĩa, từ viết tắt
| Từ viết tắt | Ý nghĩa |
|---|---|
| SRS | Software Requirements Specification |
| CTV | Cộng tác viên (Content Collaborator/Organizer) |
| BO | Best Of (VD: BO1, BO3, BO5) |
| TFT | Teamfight Tactics – game đấu trường chân lý |
| LOL | League of Legends |
| Bracket | Nhánh đấu / sơ đồ thi đấu |
| EDA | Event-Driven Architecture |

---

## 2. Tổng quan hệ thống

### 2.1 Đối tượng sử dụng (Actors)

| Actor | Vai trò trong hệ thống (bảng `users`/`participants`) |
|---|---|
| **Sinh viên (Participant)** | Người tham gia thi đấu, lưu tại bảng `participants`, `role` mặc định gắn với tài khoản loại người chơi |
| **Admin** | Tài khoản `users.role = 'admin'`, toàn quyền quản trị hệ thống |
| **CTV** | Tài khoản `users.role = 'ctv'` (mặc định), quản lý giải đấu do mình tổ chức hoặc tham gia tổ chức |

> Ghi chú: `users` là bảng tài khoản quản trị (Admin/CTV) dùng `username` + `password_hash`; `participants` là bảng tài khoản người chơi, dùng `id` (có thể là mã sinh viên) + `password_hash`, có `account_type` phân biệt tài khoản nội bộ (`internal`, ví dụ sinh viên DUT) và `external` (sinh viên ngoài trường).

### 2.2 Kiến trúc tổng quan
Kiến trúc đề xuất: **Event-Driven Architecture (EDA)** kết hợp **Asynchronous Ingestion** cho các luồng xử lý tốn thời gian hoặc cần tách rời (decouple), ví dụ:
- Xử lý đăng ký sinh viên (upload ảnh thẻ SV/CCCD → OCR/validate → cập nhật trạng thái).
- Duyệt đăng ký giải đấu.
- Sinh nhánh đấu (bracket generation) khi giải đấu đóng đăng ký.
- Gửi thông báo (email/notification) khi có thay đổi trạng thái.

Các event tiêu biểu: `participant.registered`, `participant.approved`, `participant.rejected`, `registration.submitted`, `registration.approved`, `tournament.registration_closed`, `bracket.generated`, `match.result_updated`.

---

## 3. Yêu cầu chức năng

### 3.1 Chức năng dành cho Sinh viên (Participant)

| Mã | Chức năng | Mô tả |
|---|---|---|
| SV-01 | Đăng ký tài khoản | Nhập thông tin cá nhân, upload ảnh thẻ sinh viên (`student_card_url`), ảnh selfie cầm thẻ SV (`selfie_with_student_card_url`), CCCD mặt trước/sau (`cccd_front_url`, `cccd_back_url`). Trạng thái khởi tạo `status = 'pending'` |
| SV-02 | Đăng nhập | Chỉ đăng nhập được khi `status = 'approved'` |
| SV-03 | Quản lý thông tin cá nhân | Xem/sửa `full_name`, `phone_number`, `university_name`, `class_name`, `faculty_name`, email, các ảnh giấy tờ |
| SV-04 | Cập nhật lại thông tin khi bị từ chối | Khi `status = 'rejected'`, hệ thống hiển thị `rejection_reason` và cho phép sinh viên chỉnh sửa, gửi lại để duyệt (chuyển `status` về `pending`) |
| SV-05 | Đăng ký tham gia giải đấu | Tạo bản ghi `registrations` (đối với đội trưởng/cá nhân) và `registration_members` (đối với thành viên đội); điền `submitted_data` theo `form_schema` của giải đấu |
| SV-06 | Xin gia nhập đội (chỉ game đồng đội) | Xem danh sách các đội đang thiếu slot (do đội trưởng bật cơ chế "tìm thành viên"), gửi yêu cầu tham gia đội |
| SV-07 | Quản lý đăng ký tham gia | Xem trạng thái đăng ký (`status` của `registrations`), rút đăng ký (nếu còn trong thời gian cho phép) |
| SV-08 | Xem nhánh đấu | Xem bracket, lịch thi đấu, kết quả của giải đấu đã tham gia hoặc giải công khai |
| SV-09 | Xem ID game của đối thủ/đồng đội (riêng TFT) | Sau khi chia bảng, các player trong cùng bảng xem được ID game của nhau (dữ liệu lấy từ `submitted_data` lúc đăng ký) |

### 3.2 Chức năng dành cho Admin

| Mã | Chức năng | Mô tả |
|---|---|---|
| AD-01 | CRUD Sinh viên | Xem, thêm, sửa, xoá/khoá (`is_active`) tài khoản `participants` |
| AD-02 | Duyệt đăng ký sinh viên | Duyệt (`status = 'approved'`, ghi `approved_by`, `approved_at`) hoặc từ chối (`status = 'rejected'`, ghi `rejection_reason`, `rejected_at`) |
| AD-03 | CRUD Giải đấu | Tạo/sửa/xoá `tournaments`: tên, game, banner, thể loại tham gia (cá nhân/đội), số lượng tối đa, thời gian mở/đóng đăng ký, thời gian thi đấu, `form_schema` (trường đăng ký tùy biến) |
| AD-04 | Duyệt giải đấu | Duyệt giải đấu do CTV tạo (`status: pending -> approved`, ghi `approved_by`, `approved_at`) |
| AD-05 | Tạo nhánh đấu | Sinh bracket cho bất kỳ giải đấu nào trong hệ thống |
| AD-06 | CRUD CTV | Thêm/sửa/xoá/khoá tài khoản `users.role = 'ctv'` |
| AD-07 | Duyệt đăng ký tổ chức giải đấu của CTV | Duyệt giải đấu do CTV đề xuất tổ chức (tương tự AD-04, nhưng nhấn mạnh vai trò CTV là người khởi tạo `created_by`) |
| AD-08 | Xem báo cáo/thống kê tổng quan | Số lượng giải đấu, sinh viên, tỉ lệ duyệt, v.v. |

### 3.3 Chức năng dành cho CTV

| Mã | Chức năng | Mô tả |
|---|---|---|
| CTV-01 | Duyệt đăng ký sinh viên | Tương tự AD-02, CTV có quyền duyệt sinh viên (dùng chung hàng đợi duyệt với Admin) |
| CTV-02 | Tạo giải đấu | Tạo `tournaments` mới với `created_by = <ctv.id>`, trạng thái khởi tạo `pending`, chờ Admin duyệt |
| CTV-03 | Quản lý giải đấu mình tổ chức | CRUD giải đấu mà `created_by = <ctv.id>` hoặc CTV được gán là đồng tổ chức |
| CTV-04 | Tạo/quản lý nhánh đấu | Với các giải mình tổ chức hoặc tham gia tổ chức: tạo bracket, cập nhật kết quả trận đấu, điều chỉnh lịch |
| CTV-05 | Duyệt đăng ký tham gia giải đấu | Duyệt/từ chối các bản ghi `registrations` cho giải đấu mình quản lý |
| CTV-06 | Xem danh sách đội/cá nhân tham gia | Xem chi tiết `registration_members`, thông tin liên hệ, `submitted_data` |

> **Ghi chú phân quyền đồng tổ chức:** Schema hiện tại chưa có bảng liên kết CTV ↔ Tournament dạng nhiều-nhiều cho vai trò "đồng tổ chức". Đề xuất bổ sung bảng `tournament_organizers (tournament_id, user_id, role)` để hỗ trợ nhiều CTV cùng quản lý một giải đấu.

---

## 4. Luồng nghiệp vụ chính (Business Flow)

### 4.1 Luồng đăng ký & duyệt tài khoản sinh viên
```
Sinh viên điền form đăng ký (kèm ảnh thẻ SV, CCCD, selfie)
        │
        ▼
   status = 'pending'  ──► [Async Job] Kiểm tra ảnh / trùng lặp student_id, email
        │
        ▼
 Admin/CTV xem danh sách chờ duyệt
        │
   ┌────┴─────┐
   ▼          ▼
Duyệt       Từ chối
(status=     (status='rejected',
'approved',  rejection_reason,
approved_by, rejected_at)
approved_at)     │
   │             ▼
   ▼        Sinh viên xem lý do,
Đăng nhập    cập nhật lại thông tin
được         → status quay về 'pending'
```

### 4.2 Luồng tạo và duyệt giải đấu
```
CTV tạo giải đấu (status='pending', created_by=ctv.id)
        │
        ▼
Admin duyệt giải đấu (status='approved', approved_by, approved_at)
        │
        ▼
Giải đấu hiển thị công khai, mở đăng ký theo registration_open_at
```

### 4.3 Luồng đăng ký tham gia giải đấu
```
Sinh viên chọn giải đấu đang mở đăng ký
        │
        ▼
[Game cá nhân - TFT]                [Game đồng đội - Liên Quân/LOL/Valorant]
Tạo registration, captain_id =       Đội trưởng tạo registration + team_name
chính sinh viên đó                   → mời/duyệt thành viên vào registration_members
        │                                     │
        │                          (tuỳ chọn) Bật cơ chế "tìm thành viên":
        │                          hiển thị công khai đội đang thiếu slot,
        │                          sinh viên khác gửi yêu cầu tham gia
        ▼                                     ▼
   CTV/Admin duyệt registration (status: pending -> approved/rejected)
        │
        ▼
   Khi registration_close_at đến hạn → hệ thống khoá đăng ký (event: tournament.registration_closed)
```

### 4.4 Luồng tạo nhánh đấu (Bracket Generation)
Chia theo 3 nhóm cơ chế:

**a) TFT (cá nhân, chia bảng cố định 8 người/bảng)**
- Lấy danh sách `registrations` đã `approved` của giải TFT.
- Chia ngẫu nhiên/seed thành các bảng 8 người.
- Nếu tổng số người không chia hết cho 8: thuật toán tối ưu để **hạn chế tối đa số bảng bị thiếu người** (ví dụ ưu tiên dồn vào ít bảng thiếu nhất thay vì rải đều thiếu ở nhiều bảng).
- Sau khi chia bảng, kích hoạt cơ chế cho phép các player trong cùng bảng xem ID game của nhau (ID game lấy từ trường tương ứng trong `submitted_data`, bắt buộc nhập lúc đăng ký).

**b) Game đồng đội (Liên Quân, LOL, Valorant)**
- Hỗ trợ 3 thể thức, admin/CTV chọn khi tạo bracket:
  1. **Loại trực tiếp (Single Elimination)**
  2. **Chia bảng (Group Stage)** — có thể kết hợp vòng bảng + vòng loại trực tiếp
  3. **Nhánh thắng/thua (Double Elimination)**
- Với mỗi thể thức, cho phép cấu hình số trận thắng mỗi cặp đấu: **BO1 / BO3 / BO5...** (tuỳ chọn theo từng vòng nếu cần).

### 4.5 Trường phụ tùy biến của giải đấu
- Mỗi giải đấu có `form_schema` (jsonb) định nghĩa các trường phụ động, ví dụ: ảnh bill chuyển lệ phí, ghi chú, ID Discord, ID game, v.v.
- Dữ liệu người dùng nhập tương ứng lưu tại `registrations.submitted_data` (jsonb).

---

## 5. Yêu cầu phi chức năng

| Mã | Yêu cầu | Mô tả |
|---|---|---|
| NFR-01 | Kiến trúc | Event-Driven Architecture (EDA) kết hợp Asynchronous Ingestion cho các tác vụ: xử lý ảnh đăng ký, duyệt tài khoản, sinh bracket, gửi thông báo |
| NFR-02 | Tính sẵn sàng (Availability) | Hệ thống hoạt động ổn định, uptime mục tiêu tối thiểu 99% trong thời gian diễn ra giải đấu |
| NFR-03 | Hiệu năng | Thời gian phản hồi trang < 2s trong điều kiện tải thông thường; xử lý bất đồng bộ cho tác vụ nặng (upload ảnh, sinh bracket hàng trăm người) |
| NFR-04 | Bảo mật | Mật khẩu lưu dạng hash (`password_hash`), phân quyền theo `role`; giới hạn truy cập dữ liệu nhạy cảm (CCCD, ảnh thẻ SV) |
| NFR-05 | Khả năng mở rộng | Kiến trúc cho phép thêm game mới, thể thức bracket mới mà không phá vỡ luồng hiện tại |
| NFR-06 | Khả năng bảo trì | Tách biệt rõ module theo domain (Auth, Tournament, Registration, Bracket) để dễ bảo trì, phù hợp mô hình event-driven |
| NFR-07 | Khả năng theo dõi (Observability) | Log lại các event quan trọng (đăng ký, duyệt, sinh bracket) phục vụ audit |
| NFR-08 | Khả năng tương thích | Giao diện responsive, hoạt động tốt trên trình duyệt desktop và mobile |

---

## 6. Mô hình dữ liệu (dựa trên schema hiện có)

### 6.1 Sơ đồ quan hệ (tóm tắt)
```
users (Admin/CTV) ──< tournaments (created_by, approved_by)
participants ──< registrations (captain_id)
registrations ──< registration_members >── participants
tournaments ──< registrations
```

### 6.2 Diễn giải các bảng chính

**`users`** — Tài khoản quản trị (Admin/CTV)
- `role`: `'admin'` | `'ctv'` (mặc định `'ctv'`)
- `is_active`: khoá/mở tài khoản

**`participants`** — Tài khoản sinh viên/người chơi
- `status`: `'pending'` | `'approved'` | `'rejected'`
- `account_type`: `'internal'` | `'external'`
- Giấy tờ xác minh: `student_card_url`, `selfie_with_student_card_url`, `cccd_front_url`, `cccd_back_url`, `cccd_number`
- `approved_by`, `approved_at`, `rejection_reason`, `rejected_at`: phục vụ luồng duyệt

**`tournaments`** — Giải đấu
- `participation_type`: cá nhân | đội (map với game: TFT = cá nhân; Liên Quân/LOL/Valorant = đội)
- `min_team_size`, `max_team_size`: áp dụng cho game đồng đội
- `form_schema` (jsonb): định nghĩa trường phụ động
- `use_external_link`, `external_registration_url`: hỗ trợ giải đấu dùng form đăng ký ngoài
- `status`: `'pending'` | `'approved'` (và có thể mở rộng `'rejected'`, `'closed'`, `'completed'`)
- `created_by`: CTV/Admin tạo giải
- `approved_by`: Admin duyệt giải

**`registrations`** — Đăng ký tham gia (đại diện đội hoặc cá nhân)
- `captain_id`: đội trưởng (hoặc chính người chơi với game cá nhân)
- `team_name`: chỉ áp dụng game đồng đội
- `submitted_data` (jsonb): dữ liệu form đăng ký, bao gồm cả trường phụ và ID game
- `status`: `'pending'` | `'approved'` | `'rejected'`

**`registration_members`** — Thành viên trong đội đăng ký
- Khóa chính kép `(registration_id, participant_id)`
- `is_captain`: đánh dấu đội trưởng

### 6.3 Đề xuất bổ sung bảng (ngoài phạm vi schema hiện tại)
Để hỗ trợ đầy đủ các chức năng mô tả ở trên, đề xuất bổ sung (không nằm trong schema gốc, cần xác nhận thêm):
- `brackets` / `bracket_groups` / `matches`: lưu cấu trúc nhánh đấu, bảng đấu, trận đấu và kết quả.
- `tournament_organizers`: liên kết nhiều CTV với một giải đấu (đồng tổ chức).
- `team_join_requests`: yêu cầu xin gia nhập đội khi đội trưởng bật cơ chế tìm thành viên.
- `notifications`: lưu/gửi thông báo cho sinh viên/CTV (phục vụ kiến trúc event-driven).

---

## 7. Ma trận phân quyền (tóm tắt)

| Chức năng | Sinh viên | CTV | Admin |
|---|:---:|:---:|:---:|
| Đăng ký / đăng nhập tài khoản SV | ✅ | ❌ | ❌ |
| Quản lý thông tin cá nhân SV | ✅ (của mình) | ❌ | ❌ |
| Đăng ký tham gia giải đấu | ✅ | ❌ | ❌ |
| Xem nhánh đấu | ✅ | ✅ | ✅ |
| Duyệt đăng ký sinh viên | ❌ | ✅ | ✅ |
| CRUD sinh viên | ❌ | ❌ | ✅ |
| Tạo giải đấu | ❌ | ✅ (chờ duyệt) | ✅ |
| Duyệt giải đấu | ❌ | ❌ | ✅ |
| Quản lý giải đấu mình (tham gia) tổ chức | ❌ | ✅ | ✅ (mọi giải) |
| Tạo/quản lý nhánh đấu | ❌ | ✅ (giải mình tổ chức) | ✅ (mọi giải) |
| CRUD CTV | ❌ | ❌ | ✅ |

---

## 8. Câu hỏi/vấn đề cần làm rõ thêm (Open Issues)
1. Cơ chế xác định "CTV tham gia tổ chức" một giải đấu (đồng tổ chức) chưa có bảng lưu trữ trong schema — cần bổ sung `tournament_organizers`.
2. Cấu trúc lưu trữ nhánh đấu (bracket/match) chưa có trong schema — cần thiết kế thêm bảng `matches`, `brackets`.
3. Cơ chế "xin vào đội" cho game đồng đội cần bảng riêng để lưu yêu cầu và trạng thái duyệt của đội trưởng.
4. Quy tắc chia bảng TFT khi số người không chia hết cho 8 cần định nghĩa thuật toán cụ thể (VD: ưu tiên giảm số bảng thiếu người xuống mức tối thiểu, chấp nhận một số bảng 7 người thay vì nhiều bảng 6-7 người).
5. Trường "ID game" trong `submitted_data` cần được chuẩn hoá tên field để hệ thống có thể tự động trích xuất và hiển thị cho cùng bảng đấu.

---

*Hết tài liệu.*
