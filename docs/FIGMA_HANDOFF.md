# FIGMA IMPLEMENTATION HANDOFF SPECIFICATION
## DUT ESPORTS TOURNAMENT PLATFORM

> **Authority:** SRS.md v1.1 | Figma File `UEdCnSAG2lrTiD9ta9CEPW`
> **Target Audience:** Gemini 3.8 Flash High Frontend Developer & Reviewer Agents
> **Styling Mandate:** Vanilla CSS / CSS Modules | Dark Cyber-Esports Aesthetic | NO Tailwind CSS | 8px Grid | Pure Leaflet.js + OSM

---

## 1. Global Design System & Token Foundation

### 1.1 Color Tokens
- **Background (`--color-bg`):** `#0C0C0F` (Deep Cyber Black)
- **Surface (`--color-surface`):** `#141419` (Card & Sidebar Background)
- **Raised (`--color-raised`):** `#1C1C24` (Elevated Card, Modal Header, Hover Surface)
- **Border (`--color-border`):** `#2A2A36` (Divider & Outline)
- **Brand / Primary (`--color-brand`):** `#C9233E` (DUT Crimson Red)
- **Brand Hover (`--color-brand-hover`):** `#E02E4C`
- **Text Main (`--color-text`):** `#F4F4F6` (High-contrast Off-white)
- **Text Muted (`--color-text-muted`):** `#8E8EA0` (Secondary Information)
- **Accent (`--color-accent`):** `#FFD080` (Warning / Amber Accent)
- **Status Good (`--color-good`):** `#2DD4BF` / `#64E5BB` (Approved / Success Mint)
- **Status Warn (`--color-warn`):** `#F59E0B` (Pending / Action Needed)
- **Status Error (`--color-error`):** `#EF4444` (Rejected / Validation Error)

### 1.2 Typography (Montserrat)
- **Display Bold:** 42px / 48px, Weight 700
- **Heading 1:** 28px, Line-height 1.3, Weight 700
- **Heading 2:** 20px, Line-height 1.4, Weight 600
- **Title / Subheading:** 16px, Line-height 1.45, Weight 600
- **Body Regular:** 14px, Line-height 1.5, Weight 400
- **Body Medium:** 14px, Line-height 1.5, Weight 500
- **Label / Caption:** 12px, Line-height 1.45, Weight 600
- **Micro / Tag:** 10px, Line-height 1.4, Weight 600

### 1.3 Core Reusable Component Library (Figma Component Sets)
1. **`SRS/Button` (`#21:6`):**
   - Variants: `State=Primary` (Brand `#C9233E`), `State=Secondary` (Raised `#1C1C24`), `State=Danger` (Error `#EF4444`), `State=Disabled` (Opacity 0.4, cursor not-allowed).
2. **`SRS/Input` (`#21:15`):**
   - Variants: `State=Default`, `State=Focus` (Accent Border), `State=Error` (Red Border + Error Caption), `State=Disabled`.
3. **`SRS/Badge` (`#21:24`):**
   - Variants: `State=Success` (Mint), `State=Pending` (Amber), `State=Error` (Red), `State=Neutral` (Muted Grey).
4. **`SRS/Navigation` (`#21:32`):**
   - Variants: `State=Default`, `State=Active` (Brand Pill), `State=Disabled`.
5. **`SRS/Table` (`#21:39`):**
   - Variants: `State=Header`, `State=Default`, `State=Selected`.
6. **`SRS/Modal` (`#21:55`):**
   - Variants: `State=Confirm` (Action dialog), `State=Reason` (Mandatory rejection input), `State=Error`.
7. **`SRS/TournamentCard` (`#21:65`):**
   - Variants: `State=Open` (Registration Open), `State=Upcoming` (Announced), `State=Completed` (Past).
8. **`SRS/Feedback` (`#21:84`):**
   - Variants: `State=Loading` (Spinner + Skeleton), `State=Empty` (Empty illustration + CTA), `State=Error`, `State=Success`.

---

## 2. Screen Specifications & Implementation Blueprints

---

### Screen: User Authentication & Registration (A00, A01, M00, M01)
- **Requirement IDs:** `FR-AUTH-01`, `NFR-SEC-06`, `AC-AUTH-001`
- **Role:** Public / Unauthenticated
- **Figma Page/Frame:**
  - Desktop: `Athlete Portal` / `A00 · Đăng nhập` (`#22:163`), `A01 · Tạo tài khoản` (`#22:162`)
  - Mobile: `Mobile Flows` / `M00 · Đăng nhập` (`#28:882`), `M01 · Tạo tài khoản` (`#22:243`)
- **Primary Components:** `SRS/Input`, `SRS/Button`, `SRS/Feedback`
- **States:**
  - `Default`: Clean email and password fields.
  - `Loading`: Button spinner, fields disabled during submission.
  - `Validation Error`: Client-side Zod validation for email format, password complexity (>= 8 chars, 1 uppercase, 1 special).
  - `Server Error`: Invalid credentials, 429 Rate Limit warning ("Tài khoản bị tạm khóa 15 phút do nhập sai quá 5 lần").
- **Responsive Behavior:**
  - Desktop (1440px): Centered modal card (480px width) on cyber wallpaper.
  - Mobile (390px): Full-bleed layout with sticky bottom submit button.
- **API/Data Dependencies:**
  - `POST /auth/register` (email, password) -> `{ success, message }`
  - `POST /auth/login` (email, password) -> `{ success, data: { token, user } }`
- **Acceptance Criteria:**
  - Given valid credentials, When login is clicked, Then store JWT in HTTP-only cookie and redirect to dashboard.
  - Given 5 failed login attempts within 15 minutes, Then display rate limit error and disable submit.

---

### Screen: Email Verification & Password Recovery (A02, A03, A04, M02)
- **Requirement IDs:** `FR-AUTH-01`, `AC-AUTH-002`, `AC-AUTH-003`
- **Role:** Public / Unauthenticated
- **Figma Page/Frame:**
  - Desktop: `A02 · Xác minh email` (`#22:164`), `A02V` (Success), `A02E` (Expired), `A03` (Forgot PW), `A04` (New PW)
  - Mobile: `M02`, `M02V`, `M02E`, `M00R`, `M00S`, `M00N`
- **Primary Components:** `SRS/Feedback`, `SRS/Button`, `SRS/Input`
- **States:**
  - `Pending Verification`: Instruction to check inbox with 30-minute expiry notice.
  - `Verified Success`: Mint badge and CTA to complete KYC profile.
  - `Token Expired`: Red warning with "Gửi lại liên kết xác minh" button.
- **API/Data Dependencies:**
  - `POST /auth/verify-email` (token)
  - `POST /auth/forgot-password` (email)
  - `POST /auth/reset-password` (token, new_password)

---

### Screen: Student Profile & Dual-Image KYC Submission (A05, M03, T03)
- **Requirement IDs:** `FR-KYC-01`, `FR-KYC-02`, `NFR-SEC-01`, `AC-KYC-001`
- **Role:** `participant`
- **Figma Page/Frame:**
  - Desktop: `Athlete Portal` / `A05 · Hồ sơ sinh viên & KYC` (`#22:170`), `A05F` (Preview modal), `A05E` (Image missing error)
  - Mobile: `Mobile Flows` / `M03 · Hồ sơ sinh viên & KYC` (`#22:245`), `M03F`, `M03E`
  - Tablet: `T03 · Hồ sơ sinh viên & KYC` (`#22:265`)
- **Primary Components:** `SRS/Input`, File Upload Dropzone (Dual slots), `SRS/Badge`, `SRS/Modal`
- **Zero CCCD Invariant Enforcement:**
  - Top Banner: **"Bước 2/3 • Không thu thập CCCD/CMND"** (`fill_fddfea63`).
  - Slot 1: `student_card_url` (Mặt trước thẻ sinh viên).
  - Slot 2: `selfie_with_student_card_url` (Ảnh chân dung cầm thẻ sinh viên).
  - Max file size: 5MB per image. Accepted formats: JPG, JPEG, PNG.
- **States:**
  - `Form Default`: Input fields for Full Name, Student ID (MSSV), University (Dropdown from canonical list), Phone.
  - `Validation Error`: File > 5MB, unsupported format, or missing second image.
  - `Pending Review (A06 / M04)`: Submission locked, amber badge "Hồ sơ đang chờ duyệt".
  - `Approved (A07 / M04A)`: Green badge "Đã xác minh sinh viên", eligible to register tournaments.
  - `Rejected / Resubmit (A08 / M04R)`: Red warning banner displaying reviewer's rejection reason, with button "Nộp lại hồ sơ".
- **API/Data Dependencies:**
  - `GET /universities` -> Canonical university list.
  - `POST /participants/kyc` (multipart: name, student_id, university_id, phone, front_image, selfie_image).
  - `GET /participants/me` -> `{ kyc_status, rejection_reason, account_type }`.

---

### Screen: Staff KYC Audit Queue & Split Inspection (S04, S05, S05Z)
- **Requirement IDs:** `FR-KYC-03`, `FR-KYC-04`, `RBAC-009`, `RBAC-010`, `AC-KYC-002`
- **Role:** `ctv` (Permanent), `admin`
- **Figma Page/Frame:**
  - `Staff/Admin Dashboard`: `S04 · Xét duyệt KYC` (`#22:201`), `S05 · Đối soát hồ sơ` (`#22:202`), `S05Z · Ảnh KYC phóng to` (`#22:203`), `S05R · Từ chối KYC` (`#22:205`)
- **Primary Components:** `SRS/Table`, Split Comparison Viewer, `SRS/Modal` (Reject Reason), `SRS/Badge`
- **Inspection UI:**
  - Left pane: Student Card Front (high-res zoom).
  - Right pane: Selfie holding card (high-res zoom).
  - Center panel: Metadata (Full Name, MSSV, Auto-classified Account Type: Internal vs External).
- **Security Control:**
  - Images loaded via secure signed URL (5-minute TTL). Direct static image access prohibited.
- **Actions:**
  - `Approve`: Updates KYC status to `approved`, creates audit log, sends notification.
  - `Reject`: Opens `SRS/Modal` (`S05R`) requiring non-empty rejection reason text.
- **API/Data Dependencies:**
  - `GET /admin/kyc/pending?page=1&limit=20`
  - `GET /admin/kyc/:id/signed-urls` -> `{ front_url, selfie_url, expires_at }`
  - `POST /admin/kyc/:id/approve`
  - `POST /admin/kyc/:id/reject` `{ reason: string }`

---

### Screen: Public Tournament Exploration & Details (P01, P02, P03, P04)
- **Requirement IDs:** `FR-TRN-01`, `FR-TRN-02`, `AC-TRN-001`
- **Role:** Public / All Roles
- **Figma Page/Frame:**
  - `Public Website`: `P01 · Trang chủ` (`#22:2`), `P02 · Khám phá giải đấu` (`#22:3`), `P03 · VALORANT 5v5` (`#22:5`), `P04 · TFT Solo` (`#22:6`), `P03C · FC Mobile` (`#22:7`)
- **Primary Components:** `SRS/TournamentCard`, Filter Bar (Game, Format, Status), Tab Navigation (Overview, Rules, Brackets, Schedule, Teams)
- **Tournament Status Badge Rules:**
  - `draft`: Hidden from public.
  - `open_registration`: Mint badge "Đang mở đăng ký" + "Đăng ký ngay" CTA.
  - `closed_registration`: Amber badge "Đã đóng đăng ký" + "Xem danh sách đội".
  - `ongoing`: Crimson pulse badge "Đang thi đấu" + "Xem nhánh đấu trực tiếp".
  - `completed`: Muted badge "Đã kết thúc" + "Xem kết quả & vinh danh".
  - `cancelled`: Red badge "Đã hủy".
- **Responsive Behavior:**
  - Desktop: 3-column card grid.
  - Mobile: Single column list with horizontal scrolling filter chips.

---

### Screen: Team Registration & Free Agent Recruitment Board (P05, A10, A14)
- **Requirement IDs:** `FR-TEAM-01`, `FR-TEAM-02`, `FR-TEAM-03`, `AC-TEAM-001`, `AC-TEAM-002`
- **Role:** `participant` (Captain / Free Agent)
- **Figma Page/Frame:**
  - `Public Website`: `P05 · Tuyển quân` (`#22:8`)
  - `Athlete Portal`: `A10 · Đăng ký đội` (`#22:178`), `A10B · Chưa đủ điều kiện` (`#22:177`), `A13 · Yêu cầu gia nhập` (`#22:181`), `A14 · Quản lý đội` (`#22:183`)
- **Primary Components:** `SRS/Input`, Dynamic Form Fields, `SRS/Badge`, `SRS/Table`
- **Registration Constraints:**
  - Captain must have `kyc_status = 'approved'`. If not, render blocked state `A10B`.
  - Dynamic Form Fields: Render input controls specified by tournament's `form_schema` (e.g. Ingame Riot ID, Rank, Discord ID).
- **Recruitment Flag Logic:**
  - Captain can toggle "Tuyển thêm thành viên" (`is_recruiting = true`).
  - When roster reaches `max_players`, system auto-disables recruitment.
  - Join Requests Table (`A14`): Shows applicant name, ingame ID, and rank. Captain has 2 actions: `Accept` (adds to roster in atomic transaction) or `Reject`.
  - Canonical statuses: `pending`, `accepted`, `rejected` (no `cancelled`).

---

### Screen: Interactive Tournament Bracket Workbench (S09, B00–B32, A15)
- **Requirement IDs:** `FR-TRN-03`, `FR-TRN-04`, `AC-TFT-001`
- **Role:** `admin`, `ctv`, Public
- **Figma Page/Frame:**
  - Admin: `Staff/Admin Dashboard` / `S09 · Sinh nhánh` (`#22:212`), `B00–B32` (`#54:4408`–`#54:6168`)
  - Athlete/Public: `Athlete Portal` / `A15 · Nhánh đấu` (`#22:186`), `B12V`, `B22V`, `B32V`
- **Supported Formats:**
  1. `Single Elimination` (`B10`–`B12`): Traditional knockout tree with seeds and bye handling.
  2. `Double Elimination` (`B30`–`B32`): Upper (Winners) bracket, Lower (Losers) bracket, and Grand Final reset match slot.
  3. `Group Stage Round Robin` (`B20`–`B24`): Group tables, match schedules, points table, and playoff advancement selector (`B23`). Error state `B24` if tiebreak unresolved.
  4. `TFT Room Partitioning` (`S09T`, `S09TS`, `S09TE`):
     - Formula: Rooms of 8 and 7 players ($b = 8 - (N \bmod 8)$ rooms of 7, $a = \lfloor N / 8 \rfloor - b$ rooms of 8).
     - Error State (`S09TE`): Triggers when $N < 7$ ("Không thể chia phòng TFT").
- **Implementation Notes:**
  - Implement bracket tree using CSS Flexbox/Grid connectors (no heavy third-party canvas).
  - Public view is strictly read-only; admin/staff view has match configuration triggers.

---

### Screen: Gameday Multi-Modal Check-in (S10Q, M08–M19, S11)
- **Requirement IDs:** `FR-CHK-01` to `FR-CHK-05`, `AC-CHK-001`, `AC-CHK-002`, `AC-CHK-003`
- **Role:** `participant`, `ctv`, `admin`
- **Figma Page/Frame:**
  - Floor Display: `Staff/Admin Dashboard` / `S10Q · QR tại sàn` (`#22:219`)
  - Mobile Athlete: `Mobile Flows` / `M08` (Scanner) to `M19` (Duplicate guard)
  - Staff Review: `Staff/Admin Dashboard` / `S11 · Kiểm tra minh chứng` (`#22:220`), `S11P` (Leaflet Map)
- **Modality A (QR + GPS Automated Flow):**
  - Floor Screen (`S10Q`): Displays dynamic high-contrast QR code rotating every 30 seconds with animated progress ring.
  - Mobile Scanner (`M08`): HTML5 Camera QR scanner.
  - Geolocation Validation (`M09`, `M10`): Requests HTML5 Geolocation (`navigator.geolocation.getCurrentPosition`).
  - Client Validation:
    - If GPS accuracy > 100m -> Display error `M15` ("Sai số GPS quá lớn, vui lòng di chuyển ra nơi thông thoáng").
    - If distance to venue geofence > radius -> Display error `M14` ("Bạn đang ở ngoài khu vực thi đấu").
    - If QR token expired (>30s) -> Display error `M12` ("Mã QR đã hết hạn, vui lòng quét lại mã trên màn hình").
    - If already checked in -> Display error `M19` ("Bạn đã hoàn tất check-in trước đó").
  - Success State (`M11`): Mint checkmark, seat assignment, and match time countdown.
- **Modality B (Proof Image Fallback & Staff Map Review):**
  - Fallback trigger: When GPS fails or QR fails repeatedly, display CTA "Gửi minh chứng check-in" (`M16`).
  - Proof Upload (`M16`): Selfie photo at venue with tournament backdrop.
  - Pending Review (`M17`): "Minh chứng đang chờ trọng tài duyệt".
  - Staff Desk (`S11`, `S11P`): Interactive Leaflet.js + OpenStreetMap (OSM) component showing venue geofence circle, participant GPS pin, and photo proof side-by-side. 1-click Approve (`S11A`) or Reject with mandatory reason (`S11R`).

---

### Screen: Match Scoring, Captain Confirmation & Dispute Resolution (S12–S15, A16–A18)
- **Requirement IDs:** `FR-TRN-05`, `AC-MATCH-001`
- **Role:** Referee / Staff (`seasonal_staff`, `ctv`), Captain, `admin`
- **Figma Page/Frame:**
  - Referee/Staff: `S12 · Nhập kết quả` (`#22:224`), `S12W · Chờ xác nhận` (`#22:225`), `S13 · Xử lý tranh chấp` (`#22:226`), `S14 · Kết quả đã khóa` (`#22:227`), `S15 · Admin sửa kết quả khóa` (`#22:228`)
  - Athlete/Captain: `A16 · Kết quả trận` (`#22:187`), `A17 · Khiếu nại kết quả` (`#22:188`), `A17S · Tranh chấp` (`#22:189`), `A18 · Kết quả đã chốt` (`#22:190`)
- **Workflow & State Progression:**
  1. `Score Entry (S12)`: Referee enters score for each game (Game 1, Game 2, Game 3 for BO3). Submits result -> Match status becomes `awaiting_confirmation`.
  2. `Captain Confirmation Window (A16)`: Captain receives real-time notification with a 15-minute countdown clock. Two CTAs: "Xác nhận kết quả" (advances match to `completed`) or "Gửi khiếu nại" (`A17`).
  3. `Dispute Handling (A17, A17S, S13)`: If captain files dispute with explanation and screenshot proof, match status transitions to `disputed`, and bracket progression for this node is immediately frozen.
  4. `Referee Resolution (S13)`: CTV/Referee reviews dispute claims and finalizes official score -> status becomes `completed`.
  5. `Result Locking & Override (S14, S15)`: Once `completed`, result is locked (`S14`). Only `admin` can trigger `S15` ("Sửa kết quả đã khóa") requiring an explicit audit reason text field.

---

### Screen: E-Certificates & Public Verification Portal (A19, A20, P06, P07, S17–S19)
- **Requirement IDs:** `FR-CRT-01` to `FR-CRT-05`, `AC-CRT-001`, `AC-CRT-002`
- **Role:** `participant`, `seasonal_staff`, `admin`, Public
- **Figma Page/Frame:**
  - Athlete: `Athlete Portal` / `A19 · Kho chứng chỉ` (`#22:191`), `A20 · Chứng chỉ điện tử` (`#22:192`), `A20D · Tải PDF` (`#22:193`)
  - Seasonal Staff / Organizers: `Staff/Admin Dashboard` / `S19 · Chứng chỉ đóng góp của tôi` (`#22:232`)
  - Public: `Public Website` / `P06 · Tra cứu` (`#22:9`), `P07 · Hợp lệ (Công khai tên)` (`#22:10`), `P07N · Hợp lệ (Ẩn tên theo privacy)` (`#22:11`), `P08 · Không tìm thấy` (`#22:12`)
- **Key Features:**
  - Athlete E-Cert: Full canvas rendering of certificate with recipient name, tournament, achievement tier, issue date, unique alphanumeric hash (`certificate_code`), and embedded verification QR.
  - Staff E-Cert: Seasonal staff can self-export their certificate of contribution (`S19`) showing their assigned role (`role_in_tournament` / `custom_title`).
  - Privacy Toggle (`A21`): Athletes can choose to show or hide their real name on public verification. If hidden, public portal displays `P07N` ("Thí sinh đã chọn ẩn tên công khai") with verified status intact.
  - Public Portal (`P06`): Direct code input or camera QR scanner redirecting to `/verify-certificate?code=...`.

---

### Screen: Asynchronous Report Export Center & System Admin (R01–R07, S20–S22)
- **Requirement IDs:** `FR-REP-01`, `FR-REP-02`, `FR-REP-03`, `FR-AUD-01`, `FR-AUD-02`, `AC-REP-001`, `AC-REP-002`
- **Role:** `ctv`, `admin`
- **Figma Page/Frame:**
  - Reports: `R01 · Trung tâm báo cáo` (`#22:236`), `R02` (Queued), `R03` (Processing), `R04` (Complete), `R05` (Failed), `R06` (Expired 24h), `R07` (Ready to download)
  - Admin: `S20 · Phân công nhân sự` (`#22:233`), `S21 · Audit Log` (`#22:234`), `S22 · Danh mục trường chuẩn` (`#22:235`)
- **PII Masking & Role Differences:**
  - CTV Export (`R01`): Banner indicates: *"Theo chính sách bảo mật, số điện thoại và email của sinh viên sẽ được che tự động (vd: 09***123, n***@dut.udn.vn)"*.
  - Admin Export (`R01_AD`): Full unmasked data for official administrative reporting.
- **Worker State Transitions:**
  - Dispatched -> `Queued` (`R02`) -> `Processing` (`R03` with dynamic percentage bar) -> `Ready to Download` (`R07` streaming download link with 24h expiration countdown) / `Failed` (`R05` with retry button).
- **Audit Log Viewer (`S21`):**
  - Strictly append-only / read-only table with filters for actor, action type (KYC, Score, Checkin, Staff), and timestamp. No edit or delete options.

---

## 3. Developer Guidance & Implementation Task Ordering

To ensure zero ambiguity during implementation by Gemini 3.8 Flash High:
1. **Frontend Architecture:** Next.js 15 App Router (`src/app/`), CSS Modules (`src/styles/`), Typed API client (`src/services/`).
2. **First Implementation Task:** `TASK-FE-FOUND-001: Implement Core Cyber Design System & CSS Token Foundation` (Styles, Typography, and Base Components: Button, Input, Badge, Table, Modal, TournamentCard, Feedback).
3. **Execution Rule:** Follow the task specification format defined in `docs/TASK_SPEC_TEMPLATE.md` and adhere strictly to `.agents/rules/developer-execution.md`.
