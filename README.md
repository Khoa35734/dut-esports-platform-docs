# NỀN TẢNG QUẢN LÝ GIẢI ĐẤU THỂ THAO ĐIỆN TỬ DUT ESPORTS
## DUT ESPORTS Tournament Management Platform — Documentation & Software Testing Architecture

[![Status: Active](https://img.shields.io/badge/Status-Active-brightgreen.svg)]()
[![Specification: SRS 1.1 / 1.2-Draft](https://img.shields.io/badge/Specification-SRS%201.1%20%2F%201.2--Draft-blue.svg)]()
[![Architecture: Event--Driven](https://img.shields.io/badge/Architecture-EDA%20%2B%20RESTful-orange.svg)]()
[![Testing: ISO%2029119](https://img.shields.io/badge/Testing-ISO%2F%2FIEC%2F%2FIEEE%2029119-purple.svg)]()
[![Data Security: Zero CCCD](https://img.shields.io/badge/Data%20Security-Zero%20CCCD%20Invariant-red.svg)]()

Tài nguyên đặc tả kỹ thuật, lược đồ cơ sở dữ liệu và kiến trúc kiểm thử tự động toàn diện của **Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS** — phát triển và vận hành bởi **Câu lạc bộ Thể thao Điện tử, Trường Đại học Bách khoa — Đại học Đà Nẵng (DUT)**.

---

## 1. TỔNG QUAN DỰ ÁN (PROJECT OVERVIEW)

Trong môi trường thể thao điện tử học đường với hàng trăm vận động viên tham gia mỗi mùa giải, quy trình tổ chức thủ công trước đây (Google Forms, bảng tính rời rạc, đối soát giấy tờ) đã tạo ra "điểm nghẽn giấy tờ", tiêu tốn hàng trăm giờ vận hành và tiềm ẩn nguy cơ sai sót dữ liệu vận động viên nghiêm trọng.

**DUT ESPORTS Tournament Management Platform** được xây dựng nhằm giải quyết triệt để bài toán trên, thiết lập nền tảng tự động hóa từ khâu tiền giải đấu, trong giải đấu đến hậu giải đấu:
- **Định danh & Xác thực Sinh viên (KYC):** Chuẩn hóa quy trình xác thực danh tính sinh viên dựa trên mã số sinh viên (`student_id`) kết hợp đối soát 02 ảnh thẻ SV (mặt trước và chân dung cầm thẻ).
- **Tuyển quân & Thị trường Chuyển nhượng Đội:** Bảng tin tuyển quân thời gian thực hỗ trợ đội trưởng tìm kiếm vị trí còn thiếu và vận động viên tự do nộp đơn gia nhập.
- **Vận hành Giải đấu Đa thể thức:** Hỗ trợ linh hoạt các nội dung từ cá nhân (Đấu Trường Chân Lý - TFT) đến đồng đội (MOBA, FPS) với biểu mẫu JSONB động.
- **Điểm danh Đa phương thức (Multi-modal Check-in):** Kết hợp mã QR Code động xoay vòng 30 giây, định vị Geofencing GPS (bán kính sàn đấu Hội trường F $\le 100m$) và quy trình nộp ảnh minh chứng dự phòng đối soát trên bản đồ tập trung Leaflet OpenStreetMap.
- **Cấp phát Chứng chỉ Số (E-Certificate):** Tự động hóa kết xuất chứng nhận có mã định danh độc bản và mã QR xác thực công khai cho VĐV và Ban tổ chức.
- **Bảo mật Thông tin Cá nhân (PII):** Tuân thủ tuyệt đối nguyên tắc **Không CCCD (Zero CCCD Invariant)**, che mờ dữ liệu (Data Masking) và quản lý phân quyền RBAC 4 vai trò chặt chẽ.

---

## 2. KIẾN TRÚC HỆ SINH THÁI (MULTI-REPO ECOSYSTEM)

Hệ sinh thái nền tảng DUT ESPORTS được phân tách thành 3 phân hệ liên kết:

```text
D:\DUT ESPORTS\
├── Web-giai-dau-docs/           # [REPOSITORY NÀY] Đặc tả Nghiệp vụ, Thiết kế CSDL & Kiểm thử
│   ├── SRS.md                   # Đặc tả Yêu cầu Phần mềm phiên bản 1.1 (IEEE Std 830-1998)
│   ├── database_schema.sql      # Lược đồ DDL PostgreSQL 18 bảng chuẩn hóa (v2.0)
│   ├── migrations.sql           # Tập lệnh Migration và đồng bộ chỉ mục toàn vẹn
│   ├── docs/                    # HỆ THỐNG TÀI LIỆU DỰ ÁN TOÀN DIỆN
│   │   ├── BUSINESS_RULES.md    # 30+ Quy tắc nghiệp vụ chi tiết (BR-AUTH, BR-KYC, BR-TRN...)
│   │   ├── WORKFLOWS.md         # Quy trình nghiệp vụ 8 luồng vận hành (WF-001 -> WF-008)
│   │   ├── DOMAIN_RULES.md      # Quy tắc miền Esports (Elimination, TFT, Byes, BOx)
│   │   ├── ACCEPTANCE_CRITERIA.md # Tiêu chuẩn nghiệm thu chức năng
│   │   ├── RBAC.md              # Ma trận phân quyền truy cập 4 vai trò
│   │   ├── FIGMA_*.md           # Đặc tả Handoff UI/UX & Traceability từ thiết kế
│   │   ├── tasks/               # 12 Hồ sơ đặc tả tác vụ kỹ thuật chi tiết
│   │   └── testing/             # Bộ hồ sơ Kiểm toán SRS, Kế hoạch & Kịch bản Kiểm thử
│   └── tests/                   # Khung tự động hóa kiểm thử 5 tầng (Node.js Native + Playwright)
│
├── Web-giai-dau/                # [BACKEND REPOSITORY] API Server
│   └── backend/                 # Express 5.0 + TypeScript 5.9 + PostgreSQL (Supabase Cloud)
│       ├── src/controllers/     # admin, auth, checkin, participant, registration, tournament...
│       ├── src/repositories/    # user, participant, registration, tournament, checkin, stats
│       ├── src/middleware/      # auth, rbac, activeStaff, tournamentScope, upload
│       └── tests/               # 132 tests kiểm thử hồi quy Backend
│
└── DUT_esports_frontend/        # [FRONTEND REPOSITORY] Client Web Application
    ├── src/app/                 # Next.js 15.3 (App Router, Turbopack) + React 19.2
    ├── src/components/          # Cyber UI Library, SoloCheckinModal, LeafletCheckinMap...
    ├── src/features/            # auth, tournaments, dashboard, checkin-simulation
    └── tests/                   # 24 unit/integration tests + Playwright E2E Specs
```

---

## 3. HAI CHỨC NĂNG CỐT LÕI (TWO CORE FUNCTIONS UNDER TEST)

Dự án tập trung kiểm định chuyên sâu vào **02 Chức năng Cốt lõi** đã hoàn thiện mã nguồn:

### Chức năng A: Quản lý Đăng ký Giải đấu & Tuyển quân (Tournament Registration & Team Recruitment)
- Đăng ký giải đấu cá nhân và đồng đội kèm biểu mẫu động JSONB (`form_schema`).
- Cơ chế bật/tắt chế độ tuyển quân (`is_recruiting`) thời gian thực.
- Gửi yêu cầu gia nhập (`team_join_requests`), đội trưởng duyệt/từ chối.
- Kiểm soát sĩ số tối đa (`max_team_size`) và tự động tắt tuyển quân khi đủ người.
- Ngăn chặn một thí sinh đăng ký tham gia 2 đội khác nhau trong cùng giải đấu.
- Kiểm soát xung đột đồng thời (Concurrency Race Condition) khi 2 đội trưởng cùng duyệt 1 thí sinh.
- Khóa cấu hình giải đấu (`BR-TRN-LOCK`) khi giải đã mở đăng ký.

### Chức năng B: Điểm danh Giải đấu Đa phương thức (Tournament Multi-modal Check-in)
- Sinh mã QR động xoay vòng 30 giây gắn với giải đấu (`checkin_qr_tokens`).
- Xác thực định vị Geofencing GPS theo công thức Haversine (Hội trường F ĐHBK: 100m, sai số $\le 100m$).
- Điểm danh dự phòng: nộp ảnh minh chứng phòng chờ/sàn đấu khi lỗi cảm biến GPS hoặc từ chối cấp quyền.
- Bản đồ đối soát tập trung Leaflet OpenStreetMap dành cho Ban tổ chức duyệt thủ công.
- Chặn điểm danh trùng lặp (`UNIQUE(tournament_id, participant_id)`).
- Xử lý tải đồng thời: 50 thí sinh cùng quét 1 mã QR hiển thị trên màn chiếu trong 30 giây.
- Kiểm thử tải cao điểm 500 yêu cầu/phút đạt thời gian phản hồi $p95 < 50ms$ (yêu cầu $< 2,000ms$).

---

## 4. CHIẾN LƯỢC KIỂM THỬ THỐNG NHẤT 5 TẦNG (5-TIER TEST STRATEGY)

Áp dụng mô hình Kim tự tháp Kiểm thử Thống nhất dành cho Solo Developer:

```text
▲ TẦNG 5: PERFORMANCE TESTING (Tải 500 req/min, đo đạc p95 latency, throughput)
├── TẦNG 4: MOBILE WEB TESTING (Playwright Mobile: Viewport di động, Giả lập GPS & Camera QR)
├── TẦNG 3: WEB UI TESTING (Playwright Desktop: Hành trình nộp đơn, Bản đồ Leaflet OSM)
├── TẦNG 2: API TESTING (Node.js Native Test Suite: Endpoints Express 5.0 + PostgreSQL Live)
└── TẦNG 1: UNIT TESTING (Node.js Native Runner: Thuật toán TFT, Haversine, Magic Bytes, State Machine)
```

| Tầng Kiểm thử (Tier) | Phạm vi & Trọng tâm | Công nghệ Thực thi | Số lượng Tests | Trạng thái |
|---|---|---|:---:|:---:|
| **Tier 1: Unit Testing** | Thuật toán chia phòng TFT 7-8 người, Công thức Haversine, Chữ ký Magic Bytes ảnh, Máy trạng thái giải đấu | Node.js Native Runner (`node --test`) | **39 tests** | **100% PASS** |
| **Tier 2: API Testing** | Đăng ký giải, Tuyển quân, Race condition, Check-in QR 30s, GPS, Nộp ảnh minh chứng, RBAC Security | Node.js Native Runner (`node --test`) | **17 tests** | **100% PASS** |
| **Tier 3: Web UI Testing** | Hành trình nộp đơn tạo đội trên Desktop, Giao diện bản đồ Leaflet OSM | Playwright Desktop (`@playwright/test`) | 2 specs | **READY** |
| **Tier 4: Mobile Web Testing** | Giả lập di động (Pixel 7 / iPhone 14 Pro), Bơm tọa độ GPS nhân tạo, Cấp quyền camera | Playwright Mobile Emulation | 2 specs | **READY** |
| **Tier 5: Performance Testing** | Kiểm thử tải cao điểm 500 yêu cầu điểm danh/phút, đo lường p95 latency | Node.js Benchmark Runner (`performance.now()`) | 500 reqs | **100% PASS** (p95: 47ms) |

---

## 5. CẤU TRÚC HỆ THỐNG TÀI LIỆU DỰ ÁN (DOCUMENTATION SITEMAP)

Toàn bộ hệ thống tài liệu đặc tả, phân tích thiết kế và kiểm thử được tổ chức quy chuẩn tại thư mục `docs/`:

### 5.1. Bộ Hồ sơ Phân tích, Nghiệp vụ & Thiết kế Sản phẩm (`docs/`)
- [`docs/BUSINESS_RULES.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/BUSINESS_RULES.md): Tập hợp 30+ quy tắc nghiệp vụ cốt lõi định danh chi tiết (`BR-AUTH`, `BR-KYC`, `BR-TEAM`, `BR-TRN`, `BR-CHK`, `BR-CERT`...).
- [`docs/WORKFLOWS.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/WORKFLOWS.md): 08 quy trình luồng nghiệp vụ chuẩn (`WF-001` đến `WF-008`: Đăng ký, Duyệt KYC, Mở giải đấu, Ghép đội, Chia bảng, Điểm danh, Xử lý khiếu nại, Cấp phát chứng chỉ).
- [`docs/DOMAIN_RULES.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/DOMAIN_RULES.md): Quy tắc miền Thể thao Điện tử (Thể thức Single/Double Elimination, BO1/3/5, Thuật toán phòng TFT 7-8 người, Xếp hạt giống Bye).
- [`docs/ACCEPTANCE_CRITERIA.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/ACCEPTANCE_CRITERIA.md): Tiêu chuẩn nghiệm thu chức năng theo mô hình BDD / Given-When-Then.
- [`docs/RBAC.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/RBAC.md): Ma trận phân quyền ma trận 4 vai trò (Participant, Seasonal Staff, Permanent Staff, Super Admin).
- [`docs/FIGMA_HANDOFF.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/FIGMA_HANDOFF.md) & [`docs/FIGMA_TRACEABILITY.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/FIGMA_TRACEABILITY.md): Đặc tả thiết kế giao diện UI/UX từ Figma, hệ thống Design Tokens Cyberpunk, liên kết màn hình và truy vết sang SRS.
- [`docs/SCHEMA_MISMATCH_INVENTORY.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/SCHEMA_MISMATCH_INVENTORY.md): Bảng đối soát chi tiết độ lệch giữa tài liệu SRS và Schema CSDL vật lý.
- [`docs/SRS_IMPLEMENTATION_GAP_ANALYSIS.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/SRS_IMPLEMENTATION_GAP_ANALYSIS.md) & [`docs/SRS_RECONCILIATION_PLAN.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/SRS_RECONCILIATION_PLAN.md): Phân tích khoảng cách triển khai mã nguồn và kế hoạch điều chỉnh tương thích.
- [`docs/CONFLICT_REGISTRY.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/CONFLICT_REGISTRY.md): Sổ đăng ký xử lý các xung đột yêu cầu nghiệp vụ giữa các bên liên quan.
- [`docs/tasks/`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/tasks/): 12 hồ sơ phân rã tác vụ kỹ thuật chi tiết (`TASK-AUTH-001` đến `TASK-RBAC-001`, `TASK-FOUND-001A-G`...).

### 5.2. Bộ Hồ sơ Kiểm toán SRS & Kiến trúc Kiểm thử Phần mềm (`docs/testing/`)
- **Khảo sát & Quản lý Dự án:** `REPOSITORY_AUDIT.md`, `PROJECT_PLAN.md`, `TASK_BOARD.md`, `WORK_LOG.md`.
- **Hồ sơ Kiểm toán SRS 1.1 (`docs/testing/srs-audit/`):**
  - `SRS_AUDIT_REPORT.md`: Báo cáo kiểm toán chuyên sâu 8 vùng rủi ro logic.
  - `SRS_ISSUES.md`: Danh mục 10 lỗi SRS kèm phản ví dụ toán học/logic.
  - `SRS_IMPROVEMENT_PROPOSAL.md`: Đề xuất cải tiến kỹ thuật đồng bộ.
  - `BUSINESS_RULE_GAPS.md`: Phân tích 6 khoảng trống quy tắc nghiệp vụ.
  - `DATABASE_CONSISTENCY_REPORT.md`: Báo cáo đối soát 18 bảng CSDL vật lý.
  - `STATE_TRANSITION_MATRIX.md`: Ma trận chuyển trạng thái hình thức giải đấu và trận đấu.
  - `DECISION_LOG.md`: Nhật ký quyết định kiến trúc và kỹ thuật.
  - `SRS_REVISED_DRAFT.md`: Bản thảo cải tiến SRS 1.2 Draft.
- **Bộ Thiết kế Kiểm thử Chuẩn ISO/IEC/IEEE 29119 (`docs/testing/test-design/`):**
  - `TEST_PLAN.md`: Kế hoạch kiểm thử tổng thể (Master Test Plan).
  - `TEST_STRATEGY.md`: Chiến lược kiểm thử thống nhất 5 tầng cho Solo Developer.
  - `TEST_SCENARIOS.md`: Danh mục 23 kịch bản kiểm thử bao phủ.
  - `TEST_CASES.md`: Đặc tả 17 ca kiểm thử chi tiết.
  - `REQUIREMENT_TRACEABILITY_MATRIX.md`: Ma trận truy vết RTM 100% yêu cầu MUST.
  - `TEST_DATA_SPECIFICATION.md`: Quy chuẩn 100% dữ liệu thử nghiệm nhân tạo (Zero CCCD).
  - `TEST_COVERAGE_GAP.md`: Báo cáo phân tích khoảng trống bao phủ.
- **Hồ sơ Báo cáo Học thuật (`docs/testing/reports/`):**
  - `SOFTWARE_TESTING_DOCUMENT.md`: Tài liệu Kiểm thử Phần mềm Tổng thể 15 phần chuẩn học thuật.

---

## 6. HƯỚNG DẪN THỰC THI KIỂM THỬ (QUICKSTART & EXECUTION)

Yêu cầu môi trường: **Node.js v24.x trở lên** (hỗ trợ native `--experimental-strip-types`). Không cần cài thêm dependencies nặng nề.

```bash
# 1. Chạy toàn bộ 56 ca kiểm thử Unit & API:
npm test

# 2. Chạy riêng tầng Kiểm thử Đơn vị (Unit Tests):
npm run test:unit

# 3. Chạy riêng tầng Kiểm thử Giao diện Lập trình (API Tests):
npm run test:api

# 4. Chạy kịch bản Kiểm thử Hiệu năng & Tải cao điểm:
npm run test:perf
```

---

## 7. CÁC NGUYÊN TẮC KỸ THUẬT BẤT BIẾN (CORE INVARIANTS)

1. **Tuân thủ Tuyệt đối Không CCCD (Zero CCCD Invariant):** 100% cơ sở dữ liệu và giao diện không tồn tại trường nhập số CCCD/CMND hoặc ảnh CCCD. Xác thực danh tính sinh viên độc quyền dựa trên thẻ sinh viên và mã số sinh viên.
2. **Khóa Chính UUID (100% UUID PKs):** Toàn bộ 18 bảng CSDL sử dụng `uuid` ngẫu nhiên (`gen_random_uuid()`) làm khóa chính, ngăn chặn tấn công vét cạn ID Enumeration.
3. **Định danh Hợp nhất (Unified Users Identity):** Bảng `users` quản trị mọi tài khoản đăng nhập (Admin, CTV Thường trực, CTV Thời vụ, Sinh viên); bảng `participants` là hồ sơ KYC mở rộng liên kết 1:1.
4. **Bản đồ Mở & Tối ưu Ngân sách:** Ứng dụng OpenStreetMap kết hợp Leaflet.js, thay thế hoàn toàn Google Maps API có chi phí cao.

---

## 8. THÔNG TIN BẢN QUYỀN & TỔ CHỨC PHÁT TRIỂN

- **Đơn vị chủ quản:** Ban Chủ nhiệm Câu lạc bộ Thể thao Điện tử — Trường Đại học Bách khoa, Đại học Đà Nẵng (DUT Esports Club).
- **Địa chỉ:** Số 54 Nguyễn Lương Bằng, Phường Hòa Khánh Bắc, Quận Liên Chiểu, Thành phố Đà Nẵng.
- **Giấy phép phần mềm:** Tài liệu nội bộ phục vụ nghiên cứu, phát triển và nghiệm thu học thuật.
