# SOFTWARE REQUIREMENTS SPECIFICATION (SRS)
# Website Quản lý Giải đấu CLB DUT ESPORTS

**Phiên bản:** 1.1
**Ngày cập nhật:** 28/08/2026
**Trạng thái:** Approved Specification

---

## 1. Giới thiệu

### 1.1 Mục đích tài liệu
Tài liệu này mô tả chi tiết các yêu cầu chức năng và phi chức năng của hệ thống website quản lý giải đấu thể thao điện tử (esports) cho CLB DUT ESPORTS. Hệ thống phục vụ việc đăng ký thành viên (xác thực sinh viên), tuyển thành viên lập đội, tổ chức giải đấu, đồng tổ chức (CTV), tạo và vận hành nhánh đấu đa thể thức (bracket/matches: Single/Double Elimination, Group Stage, TFT lobbies), quản lý kết quả thi đấu.

### 1.2 Phạm vi hệ thống
Hệ thống là một nền tảng web toàn diện cho phép:
- **Sinh viên (Participant)**: Đăng ký tài khoản (xác minh qua ảnh thẻ SV và ảnh selfie cầm thẻ SV), tìm đội/tuyển quân, đăng ký tham gia giải đấu (cá nhân hoặc đội), tra cứu nhánh đấu, lịch thi đấu và Ingame ID của đối thủ trong bảng.
- **CTV (Cộng tác viên / Đồng tổ chức)**: Tạo giải đấu (chờ duyệt), được Admin phân quyền đồng tổ chức giải, quản lý danh sách đăng ký, tạo/điều hành nhánh đấu, nhập tỉ số và xác minh kết quả.
- **Admin**: Quản trị toàn diện: Người dùng (Users), Sinh viên (Participants), Giải đấu (Tournaments), phân công CTV đồng tổ chức, cấu hình hệ thống và thống kê tổng quan.

### 1.3 Định nghĩa, từ viết tắt
| Từ viết tắt | Ý nghĩa |
|---|---|
| SRS | Software Requirements Specification |
| CTV | Cộng tác viên (Co-organizer / Referee) |
| BO | Best Of (VD: BO1, BO3, BO5) |
| TFT | Teamfight Tactics – Đấu Trường Chân Lý (thể thức 8 người/phòng) |
| LOL | League of Legends (Liên Minh Huyền Thoại) |
| Bracket | Nhánh đấu / Sơ đồ thi đấu |
| Ingame ID / IGN | Tên nhân vật hoặc ID tài khoản trong game (Riot ID, Tên kiện tướng, v.v.) |
| EDA | Event-Driven Architecture |

---

## 2. Tổng quan hệ thống

### 2.1 Đối tượng sử dụng (Actors)

| Actor | Vai trò trong hệ thống (bảng `users`/`participants`) |
|---|---|
| **Sinh viên (Participant)** | Người chơi/thí sinh thi đấu, lưu tại bảng `participants`. Phân loại `account_type`: `'internal'` (sinh viên DUT) và `'external'` (sinh viên trường khác). |
| **Admin** | Tài khoản quản trị cấp cao trong bảng `users` (`role = 'admin'`), toàn quyền hệ thống. |
| **CTV (Cộng tác viên)** | Tài khoản quản trị trong bảng `users` (`role = 'ctv'`), tạo đề xuất giải đấu và tham gia đồng tổ chức các giải đấu được phân công qua bảng `tournament_organizers`. |

---

### 2.2 Kiến trúc tổng quan
Hệ thống áp dụng kiến trúc **Event-Driven Architecture (EDA)** kết hợp **Asynchronous Processing**:
- **Xử lý đăng ký sinh viên**: Upload ảnh thẻ SV & selfie $\rightarrow$ validate/nén ảnh $\rightarrow$ đẩy vào hàng đợi duyệt $\rightarrow$ gửi thông báo kết quả duyệt/từ chối.
- **Duyệt giải đấu & Đăng ký**: Thông báo real-time khi đội trưởng nhận được yêu cầu "xin vào đội" hoặc khi đơn đăng ký giải được duyệt.
- **Sinh nhánh đấu (Bracket Generation)**: Tự động hóa chia nhánh Single/Double Elimination hoặc thuật toán chia phòng TFT 8 người khi giải đóng đăng ký.
- **Sự kiện tiêu biểu**: `participant.registered`, `participant.approved`, `registration.submitted`, `team.join_requested`, `team.join_accepted`, `tournament.organizer_assigned`, `tournament.registration_closed`, `bracket.generated`, `match.score_updated`.

---

## 3. Yêu cầu chức năng chi tiết

### 3.1 Chức năng dành cho Sinh viên (Participant)

| Mã | Chức năng | Mô tả chi tiết |
|---|---|---|
| **SV-01** | **Đăng ký tài khoản (KYC Sinh viên)** | Nhập thông tin cá nhân (`full_name`, `email`, `phone_number`, `university_name`, `class_name`, `faculty_name`, `student_id`). **Chỉ yêu cầu upload 2 ảnh xác minh**: <br>1. Mặt trước thẻ sinh viên (`student_card_url`)<br>2. Ảnh chân dung và tay cầm thẻ sinh viên (`selfie_with_student_card_url`).<br>*(Không yêu cầu bất kỳ thông tin hay hình ảnh CCCD nào)*. Trạng thái khởi tạo `status = 'pending'`. |
| **SV-02** | **Đăng nhập** | Đăng nhập bằng `email`/`username`/`student_id` + mật khẩu. Chỉ đăng nhập và thao tác được khi `status = 'approved'`. |
| **SV-03** | **Quản lý hồ sơ cá nhân** | Xem và cập nhật thông tin liên hệ, xem trạng thái phê duyệt tài khoản. |
| **SV-04** | **Cập nhật lại thông tin khi bị từ chối** | Khi `status = 'rejected'`, sinh viên xem được `rejection_reason`, cập nhật lại ảnh/thông tin và gửi duyệt lại (`status` chuyển về `'pending'`). |
| **SV-05** | **Đăng ký tham gia giải đấu** | - **Giải cá nhân (TFT)**: Nhập bắt buộc `ingame_id` (Riot ID) và các trường động theo `form_schema`.<br>- **Giải đồng đội (Liên Quân, LOL...)**: Đội trưởng nhập `team_name`, `ingame_id` của bản thân, thêm các thành viên đã có tài khoản trên web hoặc đăng ký trước số lượng thành viên hiện có (VD: 4/7 người). |
| **SV-06** | **Tuyển quân & Xin gia nhập đội** | - **Đội trưởng**: Bật chế độ `is_recruiting = true`, nhập ghi chú tuyển quân `recruitment_notes` (ví dụ: *"Cần tuyển 1 Mid và 1 SP rank Cao Thủ"*). Duyệt (`accept`) hoặc Từ chối (`reject`) các yêu cầu xin vào đội.<br>- **Thành viên tự do**: Xem danh sách các đội đang thiếu người (VD: Đội X đang có 4/7 thành viên), bấm "Xin vào đội", điền Ingame ID và lời nhắn gửi đội trưởng. |
| **SV-07** | **Quản lý đơn đăng ký** | Xem trạng thái đơn đăng ký giải đấu (`pending`, `approved`, `rejected`), hủy đơn khi giải chưa đóng đăng ký. |
| **SV-08** | **Xem nhánh đấu & Lịch thi đấu** | Xem sơ đồ cây nhánh đấu (Bracket view), lịch thi đấu chi tiết từng vòng, kết quả trận đấu, link phòng stream. |
| **SV-09** | **Tra cứu Ingame ID của đối thủ** | Khi bảng đấu/phòng đấu được công bố, người chơi tự động xem được danh sách `ingame_id` của tất cả các đối thủ trong cùng phòng/cặp đấu để kết bạn và mời vào phòng Custom. |

---

### 3.2 Chức năng dành cho Admin

| Mã | Chức năng | Mô tả chi tiết |
|---|---|---|
| **AD-01** | **Quản lý Sinh viên (Participants)** | Xem danh sách, tìm kiếm, lọc theo trường/khoa, chỉnh sửa hoặc khóa tài khoản sinh viên vi phạm. |
| **AD-02** | **Duyệt đăng ký tài khoản sinh viên** | Xem hồ sơ và 2 ảnh xác thực thẻ SV. Thực hiện Duyệt (`approved`) hoặc Từ chối (`rejected` kèm lý do cụ thể). |
| **AD-03** | **Quản lý Giải đấu (Tournaments)** | Toàn quyền tạo mới, chỉnh sửa thông tin, cấu hình số lượng đội (`min_team_size`, `max_team_size`, `max_participants`), thời gian mở/đóng đăng ký, tùy biến `form_schema`. |
| **AD-04** | **Phê duyệt giải đấu do CTV tạo** | Xem xét và Duyệt (`approved`) hoặc Từ chối (`rejected`) giải đấu do CTV đề xuất. |
| **AD-05** | **Phân quyền Đồng tổ chức (Co-organizers)** | Gán/thêm một hoặc nhiều CTV vào giải đấu thông qua bảng `tournament_organizers` (vai trò: `lead_organizer`, `co_organizer`, `referee`). |
| **AD-06** | **Quản lý CTV (Users)** | Tạo mới, cấp tài khoản, phân quyền `role = 'ctv'`, khóa/mở khóa tài khoản CTV. |
| **AD-07** | **Tạo và điều hành Nhánh đấu** | Tạo bracket đa thể thức, chạy thuật toán xếp cặp tự động hoặc xếp thủ công, cập nhật tỉ số, xử lý khiếu nại. |
| **AD-08** | **Báo cáo & Thống kê** | Thống kê số lượng giải đấu, số lượng VĐV tham gia, tỉ lệ hoàn thành trận đấu. |

---

### 3.3 Chức năng dành cho CTV (Cộng tác viên / Đồng tổ chức)

| Mã | Chức năng | Mô tả chi tiết |
|---|---|---|
| **CTV-01** | **Duyệt đăng ký sinh viên** | Xem hồ sơ chờ duyệt và phê duyệt thẻ sinh viên (dùng chung hàng đợi kiểm duyệt với Admin). |
| **CTV-02** | **Đề xuất tạo giải đấu mới** | Tạo giải đấu với `created_by = ctv.id`, trạng thái `pending`, chờ Admin phê duyệt trước khi công bố. |
| **CTV-03** | **Quản lý giải đấu được phân công** | Quản lý các giải đấu do mình tạo hoặc được Admin gán quyền đồng tổ chức trong `tournament_organizers`. |
| **CTV-04** | **Duyệt đơn đăng ký giải đấu** | Duyệt (`approved`) hoặc từ chối (`rejected`) đơn đăng ký cá nhân/đội tham gia giải đấu mình phụ trách. |
| **CTV-05** | **Vận hành Nhánh đấu & Trận đấu** | Sinh nhánh đấu khi đóng đăng ký, phân phòng TFT theo thuật toán, cập nhật lịch thi đấu, nhập tỉ số ván đấu và ảnh chụp bằng chứng kết quả. |
| **CTV-06** | **Xuất danh sách VĐV & Ingame ID** | Xuất bảng danh sách VĐV hợp lệ kèm Ingame ID và số điện thoại liên hệ phục vụ công tác điều phối giải. |

---

## 4. Luồng nghiệp vụ chính (Business Flow)

### 4.1 Luồng đăng ký & duyệt tài khoản sinh viên (KYC thẻ SV)
```
Sinh viên điền thông tin + Upload 2 ảnh:
(1) Mặt trước thẻ SV + (2) Ảnh mặt và tay cầm thẻ SV
                     │
                     ▼
             status = 'pending'
                     │
                     ▼
          Admin/CTV kiểm tra hồ sơ
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
        Duyệt                 Từ chối
 (status = 'approved',  (status = 'rejected',
  approved_by,           rejection_reason,
  approved_at)           rejected_at)
          │                     │
          ▼                     ▼
 Sinh viên đăng nhập     Sinh viên xem lý do từ chối,
 & tham gia giải đấu     sửa ảnh/thông tin gửi duyệt lại (status -> pending)
```

---

### 4.2 Luồng phân quyền CTV Đồng tổ chức giải đấu
```
Admin tạo giải HOẶC Admin duyệt giải do CTV tạo
                     │
                     ▼
  Admin vào mục "Quản lý Ban Tổ Chức" của giải
                     │
                     ▼
    Chọn các CTV từ danh sách tài khoản
                     │
                     ▼
 Thêm vào bảng `tournament_organizers` (role: co_organizer / referee)
                     │
                     ▼
Các CTV được gán có đầy đủ quyền: duyệt đơn đăng ký, tạo nhánh đấu, nhập tỉ số giải đấu đó
```

---

### 4.3 Luồng đăng ký giải & Tuyển quân / Xin gia nhập đội
```
              Sinh viên xem giải đấu đang mở đăng ký
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
 [Giải cá nhân: TFT]                   [Giải đồng đội: Liên Quân/LOL]
Điền Ingame ID (Riot ID)             Đội trưởng tạo đơn + Tên đội + Ingame ID
+ Thông tin bổ sung                  + Thêm thành viên hiện có (VD: 4/7)
            │                                     │
            │                         (Tuỳ chọn) Bật `is_recruiting = true`
            │                         kèm ghi chú vị trí cần tuyển
            │                                     │
            │                         Các sinh viên khác thấy đội 4/7
            │                         bấm "Xin vào đội" (kèm Ingame ID)
            │                                     │
            │                         Đội trưởng Duyệt (Accept) / Từ chối
            │                         -> Hệ thống tự thêm vào danh sách đội
            │                                     │
            └──────────────────┬──────────────────┘
                               ▼
        Gửi đơn đăng ký: status = 'pending'
                               ▼
        Admin/CTV duyệt: status = 'approved'
```

---

### 4.4 Luồng Nhánh đấu & Thuật toán chia bảng TFT

#### a) Thuật toán chia phòng TFT khi số thí sinh $N$ không chia hết cho 8
- **Mục tiêu**: Tối đa hóa số bảng 8 người, giảm thiểu tối đa số bảng bị thiếu người; bảng thiếu người sẽ có 7 người (không để xuất hiện bảng $\le 6$ người trừ khi $N < 7$).
- **Công thức xác định số bảng**:
  Gọi:
  - $N$: Tổng số thí sinh đã được duyệt tham gia ($N \ge 7$).
  - $a$: Số phòng thi đấu chuẩn 8 người ($a \ge 0$).
  - $b$: Số phòng thi đấu 7 người ($b \ge 0$, tối thiểu hóa $b$).
  - $k = \lfloor N / 8 \rfloor$, $r = N \bmod 8$.

  **Quy tắc tính**:
  - Nếu $r = 0 \implies a = k, \; b = 0$ (Toàn bộ là phòng 8 người).
  - Nếu $r > 0 \implies b = 8 - r, \; a = k - (7 - r)$.

  **Bảng ví dụ đối chiếu**:
  | Số lượng $N$ | Số phòng 8 người ($a$) | Số phòng 7 người ($b$) | Tổng số phòng | Kiểm tra tổng thí sinh |
  |:---:|:---:|:---:|:---:|:---:|
  | **32** | 4 | 0 | 4 | $4 \times 8 = 32$ |
  | **31** | 3 | 1 | 4 | $3 \times 8 + 1 \times 7 = 31$ |
  | **30** | 2 | 2 | 4 | $2 \times 8 + 2 \times 7 = 30$ |
  | **29** | 1 | 3 | 4 | $1 \times 8 + 3 \times 7 = 29$ |
  | **28** | 0 | 4 | 4 | $0 \times 8 + 4 \times 7 = 28$ |
  | **24** | 3 | 0 | 3 | $3 \times 8 = 24$ |
  | **23** | 2 | 1 | 3 | $2 \times 8 + 1 \times 7 = 23$ |
  | **15** | 1 | 1 | 2 | $1 \times 8 + 1 \times 7 = 15$ |

- **Cơ chế hiển thị Ingame ID**: Ngay khi hệ thống tạo phòng, toàn bộ 7 hoặc 8 tuyển thủ trong phòng sẽ thấy danh sách Ingame ID của nhau để chủ phòng tạo custom lobby và gửi lời mời.

#### b) Thể thức cho Game đồng đội (Liên Quân, LOL, Valorant)
- Hỗ trợ các thể thức:
  1. **Loại trực tiếp (Single Elimination)**: Thua 1 trận bị loại ngay.
  2. **Nhánh thắng - Nhánh thua (Double Elimination)**: Thua ở nhánh thắng chuyển xuống nhánh thua (Losers Bracket).
  3. **Vòng bảng (Round Robin / Group Stage)**: Chia nhiều bảng đấu vòng tròn tính điểm, chọn top đầu mỗi bảng vào vòng Playoff loại trực tiếp.
- Cấu hình từng trận/vòng: **BO1 / BO3 / BO5 / BO7**.

---

## 5. Yêu cầu phi chức năng

| Mã | Yêu cầu | Mô tả |
|---|---|---|
| **NFR-01** | **Bảo mật & Quyền riêng tư** | Tuyệt đối không lưu trữ CCCD. Ảnh thẻ sinh viên được lưu trữ trên Cloud Storage an toàn, có chữ ký URL có thời hạn (Signed URLs). Mật khẩu mã hóa bằng `bcrypt` / `argon2`. |
| **NFR-02** | **Hiệu năng & Tải đồng thời** | Xử lý mượt mà khi đóng cổng đăng ký và sinh bracket đồng loạt cho hàng trăm VĐV. Thời gian render nhánh đấu < 1.5s. |
| **NFR-03** | **Tính toàn vẹn dữ liệu** | Ràng buộc toàn vẹn khóa ngoại (Foreign Key Constraints) có `ON DELETE CASCADE` hoặc `ON DELETE RESTRICT` hợp lý, đảm bảo không mồ côi dữ liệu trận đấu và đăng ký. |
| **NFR-04** | **Tính sẵn sàng & Khả năng mở rộng** | Schema thiết kế theo mô hình chuẩn hóa 3NF, mở rộng dễ dàng sang các tựa game esports mới mà không cần thay đổi cấu trúc bảng chính. |

---

## 6. Mô hình Dữ liệu Cơ sở dữ liệu (Database Schema)

### 6.1 Sơ đồ thực thể quan hệ (ERD Overview)

```
       ┌───────────────────┐               ┌───────────────────────────┐
       │       users       │──────────────<│   tournament_organizers   │
       │ (Admin / CTV)     │               └─────────────┬─────────────┘
       └─────────┬─────────┘                             │
                 │                                       │
                 │ 1:N (created_by / approved_by)        │ M:N
                 ▼                                       ▼
       ┌───────────────────┐ 1:N (tournament_id)  ┌───────────────────────────┐
       │    tournaments    │──────────────────────>│          brackets         │
       └─────────┬─────────┘                       └─────────────┬─────────────┘
                 │                                               │ 1:N
                 │ 1:N                                           ▼
                 ▼                                 ┌───────────────────────────┐
       ┌───────────────────┐                       │       bracket_rounds      │
       │   registrations   │                       └─────────────┬─────────────┘
       │  (Cá nhân / Đội)  │                                     │ 1:N
       └────┬─────────┬────┘                                     ▼
            │         │ 1:N                        ┌───────────────────────────┐
            │         ├───────────────────────────>│          matches          │
            │         │                            └─────────────┬─────────────┘
            │         │ 1:N                                      │ 1:N
            │         ▼                                          ▼
            │  ┌───────────────────────────┐       ┌───────────────────────────┐
            │  │    team_join_requests     │       │     match_participants    │
            │  │   (Xin vào đội 4/7)       │       │(Slots 1..8, scores, rank) │
            │  └───────────────────────────┘       └───────────────────────────┘
            │ 1:N
            ▼
┌───────────────────────────┐
│   registration_members    │
│  (Thành viên & Ingame ID) │
└───────────┬───────────────┘
            │ N:1
            ▼
┌───────────────────────────┐
│       participants        │
│ (Sinh viên - Thẻ SV KYC)  │
└───────────────────────────┘
```

---

### 6.2 Chi tiết các bảng trong CSDL (PostgreSQL)

#### 1. Bảng `users` (Tài khoản Quản trị & CTV)
- `id` (`uuid`, PK): Khóa chính ngẫu nhiên (`uuid_generate_v4()`).
- `username` (`text`, Unique): Tên đăng nhập.
- `password_hash` (`character varying`): Mật khẩu băm.
- `full_name` (`character varying`): Họ và tên.
- `role` (`character varying`): `'admin'` hoặc `'ctv'` (mặc định `'ctv'`).
- `is_active` (`boolean`): Trạng thái tài khoản hoạt động/bị khóa.
- `created_at`, `updated_at` (`timestamp with time zone`).

#### 2. Bảng `participants` (Tài khoản Sinh viên / VĐV - Đã loại bỏ CCCD)
- `id` (`text`, PK): Mã định danh hoặc mã sinh viên.
- `username` (`text`): Tên tài khoản hiển thị.
- `password_hash` (`text`): Mật khẩu băm.
- `full_name` (`text`): Họ và tên sinh viên.
- `student_id` (`text`, Unique): Mã số sinh viên (VD: 102210xxx).
- `email` (`text`, Unique): Email sinh viên.
- `phone_number` (`character varying`): Số điện thoại liên hệ.
- `university_name` (`character varying`): Tên trường đại học (VD: ĐH Bách Khoa - ĐHĐN).
- `faculty_name` (`text`): Tên khoa.
- `class_name` (`text`): Tên lớp sinh hoạt.
- `account_type` (`text`): `'internal'` (DUT) hoặc `'external'` (ngoài trường).
- **Hồ sơ xác minh thẻ SV**:
  - `student_card_url` (`text`): URL ảnh mặt trước thẻ sinh viên.
  - `selfie_with_student_card_url` (`text`): URL ảnh chụp mặt và tay cầm thẻ sinh viên.
- **Trạng thái kiểm duyệt**:
  - `status` (`text`): `'pending'`, `'approved'`, `'rejected'`.
  - `approved_by` (`text`): ID người duyệt.
  - `approved_at` (`timestamp with time zone`).
  - `rejection_reason` (`text`): Lý do từ chối.
  - `rejected_at` (`timestamp with time zone`).
- `created_at`, `updated_at` (`timestamp with time zone`).

#### 3. Bảng `tournaments` (Giải đấu)
- `id` (`uuid`, PK).
- `code` (`character varying`, Unique): Mã giải đấu (VD: `DUT-TFT-S1`, `DUT-LQ-2026`).
- `name` (`character varying`): Tên giải đấu.
- `game_name` (`character varying`): Tên game (TFT, Liên Quân Mobile, LMHT, Valorant...).
- `game_logo_url`, `banner_url` (`text`): Ảnh đại diện và banner giải.
- `participation_type` (`character varying`): `'individual'` (cá nhân) hoặc `'team'` (đồng đội).
- `max_participants` (`integer`): Số lượng tối đa cá nhân hoặc đội.
- `min_team_size`, `max_team_size` (`integer`): Số thành viên tối thiểu/tối đa trong 1 đội (VD: 5 đến 7 người).
- `registration_open_at`, `registration_close_at` (`timestamp with time zone`).
- `start_at`, `end_at` (`timestamp with time zone`).
- `description` (`text`): Mô tả, thể lệ và giải thưởng.
- `use_external_link` (`boolean`), `external_registration_url` (`text`).
- `form_schema` (`jsonb`): Định nghĩa trường động cho form đăng ký.
- `created_by` (`uuid`, FK $\rightarrow$ `users.id`): Người tạo giải (Admin hoặc CTV).
- `approved_by` (`uuid`, FK $\rightarrow$ `users.id`): Admin phê duyệt giải.
- `status` (`character varying`): `'pending'`, `'approved'`, `'rejected'`, `'registration_opened'`, `'registration_closed'`, `'ongoing'`, `'completed'`, `'cancelled'`.
- `created_at`, `approved_at`, `updated_at` (`timestamp with time zone`).

#### 4. Bảng `tournament_organizers` (Phân quyền CTV Đồng tổ chức - Mới)
- `id` (`uuid`, PK).
- `tournament_id` (`uuid`, FK $\rightarrow$ `tournaments.id` ON DELETE CASCADE).
- `user_id` (`uuid`, FK $\rightarrow$ `users.id` ON DELETE CASCADE).
- `role` (`character varying`): `'lead_organizer'`, `'co_organizer'`, `'referee'`.
- `assigned_by` (`uuid`, FK $\rightarrow$ `users.id`): Admin thực hiện gán quyền.
- `assigned_at` (`timestamp with time zone`).
- Ràng buộc: `UNIQUE(tournament_id, user_id)`.

#### 5. Bảng `registrations` (Đơn đăng ký tham gia giải)
- `id` (`uuid`, PK).
- `tournament_id` (`uuid`, FK $\rightarrow$ `tournaments.id` ON DELETE CASCADE).
- `captain_id` (`text`, FK $\rightarrow$ `participants.id`): Đội trưởng hoặc chính cá nhân thi đấu.
- `team_name` (`character varying`): Tên đội (đối với game đồng đội).
- `ingame_id` (`character varying`): Ingame ID của đội trưởng/thí sinh cá nhân (Riot ID / Tên kiện tướng).
- **Cơ chế tuyển thành viên (Recruitment)**:
  - `is_recruiting` (`boolean`, Default `false`): Đang bật tìm thành viên còn thiếu.
  - `recruitment_notes` (`text`): Ghi chú yêu cầu vị trí tuyển (VD: "Cần 1 Mid Cao thủ").
- `submitted_data` (`jsonb`): Dữ liệu các trường động phụ theo `form_schema`.
- `status` (`character varying`): `'pending'`, `'approved'`, `'rejected'`, `'cancelled'`.
- `registered_at`, `updated_at` (`timestamp with time zone`).

#### 6. Bảng `registration_members` (Danh sách thành viên trong đội)
- `registration_id` (`uuid`, FK $\rightarrow$ `registrations.id` ON DELETE CASCADE).
- `participant_id` (`text`, FK $\rightarrow$ `participants.id` ON DELETE CASCADE).
- `is_captain` (`boolean`, Default `false`): Đánh dấu đội trưởng.
- `ingame_id` (`character varying`): Ingame ID chính xác của thành viên.
- `role_in_team` (`character varying`): Vị trí thi đấu (VD: Top, Jungle, Mid, AD, SP, Sub).
- `created_at` (`timestamp with time zone`).
- Khóa chính kép: `PRIMARY KEY (registration_id, participant_id)`.

#### 7. Bảng `team_join_requests` (Yêu cầu xin gia nhập đội - Mới)
- `id` (`uuid`, PK).
- `registration_id` (`uuid`, FK $\rightarrow$ `registrations.id` ON DELETE CASCADE).
- `participant_id` (`text`, FK $\rightarrow$ `participants.id` ON DELETE CASCADE).
- `ingame_id` (`character varying`): Ingame ID của người xin vào.
- `message` (`text`): Lời nhắn gửi đội trưởng (vị trí sở trường, mức rank).
- `status` (`character varying`): `'pending'`, `'accepted'`, `'rejected'`, `'cancelled'`.
- `processed_by` (`text`, FK $\rightarrow$ `participants.id`): Đội trưởng xử lý.
- `processed_at` (`timestamp with time zone`).
- `created_at`, `updated_at` (`timestamp with time zone`).

#### 8. Bảng `brackets` (Cấu trúc Nhánh đấu / Giai đoạn giải đấu - Mới)
- `id` (`uuid`, PK).
- `tournament_id` (`uuid`, FK $\rightarrow$ `tournaments.id` ON DELETE CASCADE).
- `name` (`character varying`): Tên nhánh đấu (VD: "Vòng bảng", "Nhánh thắng - Nhánh thua", "Vòng chung kết", "TFT Vòng 1").
- `format` (`character varying`): `'single_elimination'`, `'double_elimination'`, `'round_robin'`, `'tft_lobbies'`.
- `status` (`character varying`): `'draft'`, `'published'`, `'in_progress'`, `'completed'`.
- `settings` (`jsonb`): Cấu hình nâng cao (VD: điểm số TFT `[8,7,6,5,4,3,2,1]`, số người thăng hạng, default BO).
- `created_at`, `updated_at` (`timestamp with time zone`).

#### 9. Bảng `bracket_rounds` (Các Vòng đấu trong Nhánh - Mới)
- `id` (`uuid`, PK).
- `bracket_id` (`uuid`, FK $\rightarrow$ `brackets.id` ON DELETE CASCADE).
- `round_number` (`integer`): Thứ tự vòng (1, 2, 3, 4...).
- `name` (`character varying`): Tên hiển thị (VD: "Vòng 1/16", "Tứ kết", "Bán kết", "Chung kết", "Lobby Round 1").
- `bo_type` (`integer`, Default `1`): BO1, BO3, BO5, BO7.
- `order_index` (`integer`): Thứ tự sắp xếp hiển thị.
- `created_at` (`timestamp with time zone`).

#### 10. Bảng `matches` (Trận đấu / Phòng đấu TFT - Mới)
- `id` (`uuid`, PK).
- `bracket_id` (`uuid`, FK $\rightarrow$ `brackets.id` ON DELETE CASCADE).
- `round_id` (`uuid`, FK $\rightarrow$ `bracket_rounds.id` ON DELETE CASCADE).
- `match_code` (`character varying`): Mã trận (VD: `M01`, `QF-1`, `TFT-R1-LOBBY1`).
- `match_type` (`character varying`): `'head_to_head'` (1v1 đội/người) hoặc `'tft_lobby'` (phòng 8 người).
- `scheduled_at`, `started_at`, `ended_at` (`timestamp with time zone`).
- `status` (`character varying`): `'scheduled'`, `'ready'`, `'in_progress'`, `'completed'`, `'cancelled'`.
- `winner_registration_id` (`uuid`, FK $\rightarrow$ `registrations.id`, Nullable): Đội/Người thắng cuộc.
- `next_match_id` (`uuid`, FK $\rightarrow$ `matches.id`, Nullable): ID trận tiếp theo ở nhánh thắng.
- `loser_next_match_id` (`uuid`, FK $\rightarrow$ `matches.id`, Nullable): ID trận tiếp theo ở nhánh thua (Double Elimination).
- `referee_id` (`uuid`, FK $\rightarrow` `users.id`, Nullable): CTV/Trọng tài giám sát trận đấu.
- `custom_room_info` (`jsonb`): Thông tin phòng đấu (Tên phòng, Pass, Host Ingame ID).
- `created_at`, `updated_at` (`timestamp with time zone`).

#### 11. Bảng `match_participants` (VĐV/Đội trong Trận đấu & Phòng TFT - Mới)
- `id` (`uuid`, PK).
- `match_id` (`uuid`, FK $\rightarrow$ `matches.id` ON DELETE CASCADE).
- `registration_id` (`uuid`, FK $\rightarrow$ `registrations.id` ON DELETE CASCADE).
- `slot_number` (`integer`): Vị trí slot (1 hoặc 2 cho 1v1; 1 đến 8 cho phòng TFT).
- `score` (`integer`, Default `0`): Tỉ số ván thắng (BO) hoặc tổng điểm tích lũy.
- `rank_position` (`integer`, Nullable): Thứ hạng đạt được trong phòng TFT (1 đến 8).
- `is_winner` (`boolean`, Default `false`).
- `evidence_url` (`text`): URL ảnh chụp màn hình kết quả trận đấu làm bằng chứng.
- `points_awarded` (`integer`, Default `0`): Điểm thưởng cộng vào bảng tổng sắp.
- Ràng buộc: `UNIQUE(match_id, registration_id)`.

#### 12. Bảng `match_games` (Chi tiết từng ván đấu trong trận BO3/BO5 - Mới)
- `id` (`uuid`, PK).
- `match_id` (`uuid`, FK $\rightarrow$ `matches.id` ON DELETE CASCADE).
- `game_number` (`integer`): Ván 1, Ván 2, Ván 3...
- `duration_seconds` (`integer`): Thời lượng ván đấu.
- `winner_registration_id` (`uuid`, FK $\rightarrow$ `registrations.id`).
- `result_details` (`jsonb`): Chi tiết mạng hạ gục, MVP, trang bị.
- `created_at` (`timestamp with time zone`).

---

## 7. Ma trận phân quyền (Role-Based Access Control)

| Chức năng | Sinh viên | CTV | Admin |
|---|:---:|:---:|:---:|
| Đăng ký & upload 2 ảnh xác minh thẻ SV | ✅ | ❌ | ❌ |
| Đăng nhập tài khoản sinh viên | ✅ (khi duyệt) | ❌ | ❌ |
| Tuyển quân / Xin gia nhập đội còn thiếu | ✅ | ❌ | ❌ |
| Đăng ký tham gia giải đấu | ✅ | ❌ | ❌ |
| Tra cứu Ingame ID đối thủ cùng bảng | ✅ | ✅ | ✅ |
| Duyệt tài khoản sinh viên (KYC) | ❌ | ✅ | ✅ |
| CRUD tài khoản sinh viên | ❌ | ❌ | ✅ |
| Tạo đề xuất giải đấu mới | ❌ | ✅ (chờ duyệt) | ✅ |
| Phê duyệt giải đấu công khai | ❌ | ❌ | ✅ |
| Phân quyền CTV đồng tổ chức giải đấu | ❌ | ❌ | ✅ |
| Quản lý giải mình (đồng) tổ chức | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Tạo nhánh đấu, điều hành trận đấu | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Nhập tỉ số & xác minh bằng chứng | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Quản lý tài khoản CTV (`users`) | ❌ | ❌ | ✅ |

---

## 8. Kết quả giải quyết các vấn đề mở (Resolved Issues)

1. **Cơ chế xác định CTV tham gia tổ chức**:
   - **Giải pháp**: Bổ sung bảng `tournament_organizers`. Admin có thể thêm CTV vào giải đấu bất kỳ lúc nào với vai trò `co_organizer` hoặc `referee`. CTV được thêm sẽ sở hữu đầy đủ quyền kiểm duyệt đơn đăng ký, vận hành nhánh đấu, xếp lịch và cập nhật tỉ số cho giải đấu đó.
2. **Cấu trúc lưu trữ Nhánh đấu & Trận đấu**:
   - **Giải pháp**: Thiết kế hệ thống bảng `brackets`, `bracket_rounds`, `matches`, `match_participants`, `match_games`. Hỗ trợ toàn diện cả thể thức đối đầu 1v1 (Single/Double Elimination, Round Robin theo BO1/BO3/BO5) và thể thức phòng thi đấu nhiều người (TFT 8 người/phòng).
3. **Cơ chế "Xin vào đội" (Tuyển thành viên)**:
   - **Giải pháp**: Bổ sung cột `is_recruiting`, `recruitment_notes` trong bảng `registrations` và bảng `team_join_requests`. Cho phép đội trưởng đăng ký đội khi chưa đủ số người tối đa (VD: 4/7 người), mở tuyển công khai trên hệ thống để sinh viên tự do gửi yêu cầu gia nhập và đội trưởng xét duyệt.
4. **Quy tắc chia bảng TFT khi số người không chia hết cho 8**:
   - **Giải pháp**: Ứng dụng thuật toán phân chia phòng tối ưu: Luôn ưu tiên tối đa số lượng phòng 8 người ($a$) và giảm thiểu số phòng thiếu người ($b$ phòng 7 người). Số phòng 7 người $b = (8 - (N \bmod 8)) \bmod 8$. Đảm bảo không có phòng $\le 6$ người nếu $N \ge 7$.
5. **Chuẩn hóa trường "Ingame ID"**:
   - **Giải pháp**: Bổ sung trường `ingame_id` chuẩn hóa trong cả `registrations` (đối với cá nhân/đội trưởng) và `registration_members` (đối với từng thành viên). Bắt buộc nhập đối với các giải đấu yêu cầu kết nối ingame (như TFT, LMHT), tự động trích xuất và hiển thị danh sách Ingame ID cho tất cả các đối thủ trong cùng phòng đấu ngay khi công bố lịch thi đấu.
6. **Xác minh danh tính (KYC)**:
   - **Giải pháp**: Loại bỏ 100% các trường liên quan đến CCCD. Quy trình KYC đăng ký tài khoản chỉ yêu cầu 2 ảnh: Mặt trước thẻ sinh viên (`student_card_url`) và Ảnh chụp khuôn mặt cùng tay cầm thẻ sinh viên (`selfie_with_student_card_url`).

---

*Hết tài liệu.*

