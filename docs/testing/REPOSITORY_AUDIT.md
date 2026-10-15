# BÁO CÁO KHẢO SÁT VÀ KIỂM KÊ KHO MÃ NGUỒN (REPOSITORY RECONNAISSANCE AUDIT)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Người thực hiện:** Kỹ sư Trưởng / QA Automation Architect (Solo Developer)  
**Ngày thực hiện:** 15/10/2026  
**Nhánh làm việc an toàn:** `test/solo-srs-audit-automation`  
**Môi trường phần cứng & OS:** Windows 11 x64, Node.js v24.x  

---

## 1. TỔNG QUAN KIẾN TRÚC VÀ CẤU TRÚC KHO LƯU TRỮ

Hệ sinh thái DUT ESPORTS Tournament Platform được tổ chức theo mô hình Multi-repo / Workspace liên kết chặt chẽ gồm 3 phân hệ chính:

```text
D:\DUT ESPORTS\
├── Web-giai-dau-docs/           [WORKSPACE HIỆN TẠI - Nhánh: test/solo-srs-audit-automation]
│   ├── SRS.md                   (Tài liệu đặc tả yêu cầu phiên bản 1.1 - 1,687 dòng)
│   ├── database_schema.sql      (Lược đồ DDL PostgreSQL chuẩn hóa v2.0 - 18 bảng)
│   ├── migrations.sql           (Tập lệnh di chuyển dữ liệu và đồng bộ chỉ mục)
│   ├── master-plan.md           (Kế hoạch phát triển kiến trúc dự án)
│   ├── EXECUTABLE_AGENT_SPEC.md (Đặc tả tác tử thực thi kỹ thuật)
│   ├── docs/testing/            (Thư mục tài liệu kiểm thử và kết quả đánh giá - Mới khởi tạo)
│   └── tests/                   (Bộ tự động hóa kiểm thử độc lập đa tầng - Mới khởi tạo)
├── Web-giai-dau/                [PHÂN HỆ BACKEND API - Nhánh: feat/phase2]
│   └── backend/
│       ├── src/                 (Express 5.0 + TypeScript 5.9 + PostgreSQL/Supabase)
│       │   ├── controllers/     (admin, auth, checkin, participant, registration, tournament,...)
│       │   ├── repositories/    (user, participant, registration, tournament, checkin, stats)
│       │   ├── middleware/      (auth, rbac, activeStaff, tournamentScope, upload, error)
│       │   └── routes/          (admin, auth, checkin, registration, tournament, upload, system)
│       └── tests/               (Bộ kiểm thử hồi quy Node.js Native Runner - 132 tests)
└── DUT_esports_frontend/        [PHÂN HỆ FRONTEND CLIENT - Nhánh: feat/phase2]
    ├── src/                     (Next.js 15.3.0 + React 19.2.5 + TypeScript + Zustand + Leaflet)
    │   ├── app/                 (App Router: admin, login, my-tournaments, tournament/[id],...)
    │   ├── components/          (SoloCheckinModal, LeafletCheckinMap, MyRegistrationModal,...)
    │   └── features/            (auth, tournaments, dashboard, checkin-simulation)
    └── tests/                   (Bộ kiểm thử Component TSX + Playwright E2E Specs)
```

---

## 2. NGĂN XẾP CÔNG NGHỆ HIỆN TRẠNG (TECHNOLOGY STACK INVENTORY)

| Thành phần | Công nghệ / Thư viện chính | Phiên bản | Ghi chú vận hành |
|---|---|---|---|
| **Backend Runtime** | Node.js (ES Modules) | >= 24.0.0 | Hỗ trợ Native Strip Types (`--experimental-strip-types`) |
| **Backend Web Framework** | Express.js | 5.0.0 | Kiến trúc RESTful, xử lý Route Async nguyên bản |
| **Cơ sở dữ liệu** | PostgreSQL (Supabase Cloud) | 15.x | AWS AP-Southeast-1 Pooler (Port 6543, SSL Transaction Mode) |
| **Database Driver** | `pg` (node-postgres) | 8.11.0 | Kết hợp connection pooling tối ưu tải đột biến |
| **Bảo mật & Mã hóa** | `bcryptjs`, `jsonwebtoken` | 2.4.0 / 9.0.0 | JWT thời hạn 24h, bcrypt hashing cost >= 10 |
| **Xử lý tệp & Đa phương tiện** | `multer`, `sharp`, `tesseract.js` | 2.1.1 / 0.35.4 | Kiểm tra Magic Bytes nhị phân, OCR thẻ sinh viên |
| **Frontend Framework** | Next.js (App Router, Turbopack) | 15.3.0 | React 19.2.5, TypeScript 5.9 |
| **Quản lý trạng thái & Cache** | Zustand, TanStack React Query | 5.0.6 / 5.87.0 | Tối ưu re-render và đồng bộ trạng thái server-client |
| **Bản đồ số & Tọa độ** | Leaflet.js, OpenStreetMap Tiles | 1.9.4 | Tích hợp MarkerCluster, Geofencing bán kính sàn đấu |
| **Xử lý Biểu mẫu** | React Hook Form, Zod | 7.61.0 / 3.25.0 | Schema validation phía client đồng bộ API |
| **Test Runner (Backend)** | Node.js Native Test Runner | v24 Native | `node --test --experimental-strip-types` (Không cần Jest/Vitest nặng nề) |
| **Test Runner (Frontend)** | `tsx` + Playwright Test | 4.23.15 / 1.64.0 | Chạy kiểm thử Component trực tiếp và kịch bản E2E |

---

## 3. HIỆN TRẠNG KẾT NỐI VÀ KIỂM THỬ BAN ĐẦU (BASELINE TEST EXECUTION)

### 3.1. Kết quả kiểm tra Backend (`Web-giai-dau/backend`)
- **Lệnh thực thi:** `npm test`
- **Kết quả:**
  - Tổng số test suites: **32**
  - Tổng số test cases: **132**
  - **Passed:** **131** tests
  - **Skipped:** **1** test (`text and UUID login identifiers execute all exact-match lookups without a SQL type error` - bỏ qua do cơ chế đối soát UUID cụ thể)
  - **Failed:** **0** tests
  - Thời gian chạy: ~31.8 giây
- **Tính khả dụng:** Kết nối Supabase PostgreSQL Cloud thành công, các route xác thực, phân quyền RBAC đa cấp (Admin/CTV/Seasonal/Participant), logic vòng đời giải đấu, kiểm tra upload ảnh qua magic bytes hoạt động ổn định.

### 3.2. Kết quả kiểm tra Frontend (`DUT_esports_frontend`)
- **Lệnh thực thi:** `npm test`
- **Kết quả:**
  - Module địa chỉ hành chính (34 tỉnh thành, 3.321 phường xã, 13 đặc khu): **14/14 Passed**
  - Bộ linh kiện UI Cyber Design (Button, Input, Badge, Table, Modal, Feedback): **12/12 Passed**
  - Bộ lọc giải đấu công khai: **2/2 Passed**
  - Quản lý phiên và lưu trữ token: **5/5 Passed**
  - Xử lý timeout và lỗi mạng API: **6/6 Passed**
  - **Tổng kết:** 100% test unit/integration phía client đạt yêu cầu.

---

## 4. MA TRẬN ĐỐI SOÁT TRẠNG THÁI TÍNH NĂNG (IMPLEMENTATION STATUS MATRIX)

Ma trận đối chiếu giữa Đặc tả yêu cầu (SRS 1.1), Mã nguồn (Backend & Frontend), Cơ sở dữ liệu vật lý (PostgreSQL DDL) và Bộ kiểm thử hiện có:

| STT | Phân hệ / Tính năng (Feature) | Mã SRS (SRS Req) | Mã nguồn (Code) | Cơ sở dữ liệu (Database) | Kiểm thử (Tests) | Đánh giá hiện trạng (Status) | Ghi chú & Rủi ro kỹ thuật |
|:---:|---|---|---|---|---|:---:|---|
| 1 | **Xác thực tài khoản & Phân quyền RBAC** | FR-AUTH-01, NFR-SEC-05,06 | IMPLEMENTED | IMPLEMENTED (`users`, `auth_tokens`) | IMPLEMENTED (15 tests) | **IMPLEMENTED** | Phân quyền 4 vai trò rõ ràng: Admin, CTV thường trực, Seasonal Staff, Participant. |
| 2 | **Hồ sơ KYC Sinh viên & Kiểm tra 02 ảnh thẻ** | FR-KYC-01..04, NFR-SEC-01..03 | IMPLEMENTED | IMPLEMENTED (`participants`) | IMPLEMENTED (18 tests) | **IMPLEMENTED** | Tuyệt đối không CCCD; kiểm tra magic bytes tệp ảnh; hỗ trợ OCR thẻ DUT tự động. |
| 3 | **Đăng ký giải đấu & Biểu mẫu động** | FR-TRN-01, FR-TRN-02 | IMPLEMENTED | IMPLEMENTED (`tournaments`, `registrations`) | IMPLEMENTED (14 tests) | **IMPLEMENTED** | Hỗ trợ JSONB `form_schema` tùy biến trường in-game; kiểm soát trạng thái GD0 -> GD4. |
| 4 | **Thị trường Tuyển quân & Xin gia nhập đội** | FR-TEAM-01..03 | IMPLEMENTED | IMPLEMENTED (`team_join_requests`, `registration_members`) | IMPLEMENTED (12 tests) | **IMPLEMENTED** | Tự động tắt cờ `is_recruiting` khi đủ sĩ số; chống trùng lặp đăng ký trong cùng giải. |
| 5 | **Điểm danh Đa phương thức (QR Động 30s + GPS)** | FR-CHK-01..03, NFR-PRF-01,03 | IMPLEMENTED | IMPLEMENTED (`check_ins`, `checkin_qr_tokens`) | PARTIAL (Unit/API mock) | **PARTIAL** | Logic tính khoảng cách Geofencing và sinh QR xoay vòng đã có; cần bổ sung test tải đồng thời. |
| 6 | **Điểm danh Dự phòng & Đối soát Bản đồ OSM** | FR-CHK-04, FR-CHK-05, NFR-CST-01 | IMPLEMENTED | IMPLEMENTED (`check_ins.proof_image_url`) | PARTIAL (UI tests) | **PARTIAL** | Client Leaflet đã tích hợp; cần E2E test cho luồng nộp ảnh minh chứng và CTV duyệt. |
| 7 | **Tự động sinh nhánh đấu (Single/Double Elim)** | FR-TRN-03 | MISSING | IMPLEMENTED (`brackets`, `bracket_rounds`, `matches`, `match_participants`) | MISSING | **MISSING** | CSDL đã có cấu trúc bảng chuẩn nhưng Backend chưa có API thuật toán chia nhánh. |
| 8 | **Thuật toán chia phòng TFT (7-8 người)** | FR-TRN-04 | MISSING | PARTIAL (Lưu trong `matches`) | MISSING | **INCONSISTENT** | SRS có công thức $m = \lceil N/8 \rceil$; backend chưa có controller/service sinh phòng TFT. |
| 9 | **Quản lý Kết quả trận đấu & Khiếu nại** | FR-TRN-05 | MISSING | IMPLEMENTED (`matches`, `match_games`) | MISSING | **MISSING** | Chưa có API cập nhật tỉ số BO, xử lý kết quả tranh chấp (disputed) và thăng hạng. |
| 10 | **Phân công Ban tổ chức & Phạm vi quyền** | FR-AUD-01, SRS 2.2 | IMPLEMENTED | IMPLEMENTED (`tournament_organizers`) | IMPLEMENTED (8 tests) | **IMPLEMENTED** | CTV thời vụ bị giới hạn nghiêm ngặt theo giải đấu được phân công trong bảng. |
| 11 | **Cấp phát Chứng chỉ E-Certificate** | FR-CRT-01..03 | MISSING | IMPLEMENTED (`certificates`) | MISSING | **MISSING** | Chưa có Worker render PDF ngầm theo kiến trúc EDA khi giải đấu chuyển `completed`. |
| 12 | **Tra cứu Chứng chỉ Công khai (/verify-cert)** | FR-CRT-04 | PARTIAL | IMPLEMENTED (`certificates.certificate_code`) | MISSING | **PARTIAL** | Frontend có trang giao diện tra cứu; backend chưa hoàn thiện endpoint xác thực mở. |
| 13 | **Xuất Báo cáo Streaming & Che giấu PII** | FR-REP-01..03, NFR-PRF-02 | PARTIAL | IMPLEMENTED (`report_exports`) | PARTIAL (`exportService`) | **PARTIAL** | Đã có dịch vụ nền tảng `exportService.ts`; chưa hoàn tất xử lý tác vụ hàng đợi bất đồng bộ. |
| 14 | **Nhật ký Kiểm toán Bất biến (Audit Logs)** | FR-AUD-01, FR-AUD-02 | IMPLEMENTED | IMPLEMENTED (`audit_logs`) | PARTIAL (Ghi nhận ở Auth/KYC) | **IMPLEMENTED** | Bảng Append-Only ghi nhận đầy đủ actor_id, IP, old/new values khi cập nhật dữ liệu. |

---

## 5. KẾT LUẬN VÀ LỰA CHỌN PHẠM VI TRỌNG TÂM (CORE FUNCTIONS SELECTION)

Từ kết quả khảo sát thực tế:
1. **Chất lượng mã nguồn hiện có:** Rất cao đối với các phân hệ Đăng ký, Tuyển quân, Xác thực KYC, Phân quyền RBAC và Điểm danh đa phương thức. Toàn bộ 131 backend tests và 24 frontend tests đều đang PASS.
2. **Khoảng trống tính năng:** Phân hệ Sinh nhánh đấu (Brackets) và Thuật toán TFT chưa được cài đặt trong backend API; Phân hệ E-Certificate chưa có worker xử lý PDF.
3. **Lựa chọn 02 chức năng trọng tâm cho Báo cáo Kiểm thử Hàn lâm (Phase 5 - Two Core Functions):**
   - **Chức năng A (Function A):** **Quản lý Đăng ký Giải đấu & Tuyển quân (Tournament Registration & Team Recruitment)**
     - *Phạm vi bao gồm:* Đăng ký giải đấu cá nhân/đội, cấu hình biểu mẫu JSONB động, bật/tắt tuyển quân, gửi/duyệt yêu cầu gia nhập (Join Request), kiểm soát sĩ số `max_team_size`, ràng buộc không đăng ký trùng lặp và tính toàn vẹn giao dịch CSDL.
     - *Căn cứ thực tế:* Mã nguồn đã được cài đặt hoàn chỉnh và có thể kiểm thử toàn diện từ Unit, API, Web UI đến Concurrency.
   - **Chức năng B (Function B):** **Điểm danh Giải đấu Đa phương thức (Tournament Multi-modal Check-in)**
     - *Phạm vi bao gồm:* Sinh mã QR động xoay vòng 30 giây, xác thực Geofencing GPS (bán kính 100m), nộp ảnh minh chứng dự phòng (Proof Submission), giao diện đối soát bản đồ tập trung Leaflet OSM, phân quyền CTV và kiểm thử tải hiệu năng (Load Testing).
     - *Căn cứ thực tế:* Đã có đủ bảng CSDL, endpoint backend và giao diện client trên Next.js.
