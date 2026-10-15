# NỀN TẢNG QUẢN LÝ GIẢI ĐẤU THỂ THAO ĐIỆN TỬ DUT ESPORTS
## DUT ESPORTS Tournament Management Platform — Documentation & Software Testing Architecture

[![Status: Active](https://img.shields.io/badge/Status-Active-brightgreen.svg)]()
[![Specification: SRS 1.1 / 1.2-Draft](https://img.shields.io/badge/Specification-SRS%201.1%20%2F%201.2--Draft-blue.svg)]()
[![Architecture: Event--Driven](https://img.shields.io/badge/Architecture-EDA%20%2B%20RESTful-orange.svg)]()
[![Testing: ISO%2029119](https://img.shields.io/badge/Testing-ISO%2F%2FIEC%2F%2FIEEE%2029119-purple.svg)]()
[![Data Security: Zero CCCD](https://img.shields.io/badge/Data%20Security-Zero%20CCCD%20Invariant-red.svg)]()

Tài nguyên đặc tả kỹ thuật, lược đồ cơ sở dữ liệu và kiến trúc kiểm thử tự động toàn diện của **Nền tảng Quản lý và vận hành Giải đấu Esports DUT ESPORTS** — phát triển và vận hành bởi **Câu lạc bộ Thể thao Điện tử, Trường Đại học Bách khoa — Đại học Đà Nẵng - DUT ESPORTS**.

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
├── Web-giai-dau-docs/           # [REPOSITORY NÀY] Tài liệu Đặc tả, CSDL & Kiến trúc Kiểm thử
│   ├── SRS.md                   # Đặc tả Yêu cầu Phần mềm phiên bản 1.1 (IEEE Std 830-1998)
│   ├── database_schema.sql      # Lược đồ DDL PostgreSQL 18 bảng chuẩn hóa (v2.0)
│   ├── migrations.sql           # Tập lệnh Migration và đồng bộ chỉ mục toàn vẹn
│   ├── docs/testing/            # Bộ hồ sơ Kiểm toán SRS, Kế hoạch & Kịch bản Kiểm thử
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

## 5. CẤU TRÚC THƯ MỤC TÀI LIỆU KIỂM THỬ (DOCUMENTATION SITEMAP)

Toàn bộ các tài liệu kỹ thuật và học thuật được tổ chức bài bản tại `docs/testing/`:

```text
docs/testing/
├── REPOSITORY_AUDIT.md                              # Khảo sát kho mã nguồn & Ma trận tính năng
├── PROJECT_PLAN.md                                  # Kế hoạch dự án 3 tuần độc lập cho Solo Developer
├── TASK_BOARD.md                                    # Bảng Kanban theo dõi công việc
├── WORK_LOG.md                                      # Nhật ký tiến trình chi tiết theo mốc thời gian
├── srs-audit/                                       # HỒ SƠ KIỂM TOÁN SRS 1.1 & KHUYẾT TẬT
│   ├── SRS_AUDIT_REPORT.md                          # Báo cáo kiểm toán chuyên sâu 8 vùng rủi ro
│   ├── SRS_ISSUES.md                                # Danh mục 10 lỗi & phản ví dụ logic
│   ├── SRS_IMPROVEMENT_PROPOSAL.md                  # Đề xuất cải tiến kỹ thuật
│   ├── BUSINESS_RULE_GAPS.md                        # Phân tích 6 khoảng trống quy tắc nghiệp vụ
│   ├── DATABASE_CONSISTENCY_REPORT.md               # Đối soát 18 bảng CSDL vật lý
│   ├── STATE_TRANSITION_MATRIX.md                   # Ma trận chuyển trạng thái hình thức
│   ├── DECISION_LOG.md                              # Nhật ký quyết định kỹ thuật
│   └── SRS_REVISED_DRAFT.md                         # Bản thảo cải tiến SRS 1.2 Draft
├── test-design/                                     # BỘ THIẾT KẾ KIỂM THỬ PHẦN MỀM
│   ├── TEST_PLAN.md                                 # Master Test Plan ISO 29119
│   ├── TEST_STRATEGY.md                             # Chiến lược kiểm thử thống nhất 5 tầng
│   ├── TEST_SCENARIOS.md                            # Danh mục 23 kịch bản kiểm thử
│   ├── TEST_CASES.md                                # Đặc tả 17 ca kiểm thử chi tiết
│   ├── REQUIREMENT_TRACEABILITY_MATRIX.md           # Ma trận truy vết RTM 100% yêu cầu MUST
│   ├── TEST_DATA_SPECIFICATION.md                   # Quy chuẩn 100% dữ liệu nhân tạo (Zero CCCD)
│   └── TEST_COVERAGE_GAP.md                         # Báo cáo khoảng trống bao phủ
├── defects/                                         # HỒ SƠ KHUYẾT TẬT PHẦN MỀM
│   └── DEFECT_REPORTS.md                            # Chi tiết 6 khuyết tật phần mềm và giải pháp
└── reports/                                         # BỘ HỒ SƠ KIỂM THỬ HÀN LÂM
    ├── SOFTWARE_TESTING_DOCUMENT.md                 # Tài liệu Kiểm thử Phần mềm Tổng thể 15 phần
    └── TEST_REPORT.md                               # Báo cáo Kiểm thử Thực tế cho 2 Chức năng Cốt lõi
```

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
