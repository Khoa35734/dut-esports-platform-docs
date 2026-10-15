# TÀI LIỆU KIỂM THỬ PHẦN MỀM TỔNG THỂ (SOFTWARE TESTING DOCUMENT)
## NỀN TẢNG QUẢN LÝ GIẢI ĐẤU THỂ THAO ĐIỆN TỬ DUT ESPORTS
**Mã tài liệu:** DUT-STD-2026-V1.0  
**Chuẩn tham chiếu:** ISO/IEC/IEEE 29119 (Software Testing Standards) & IEEE Std 829-2008  
**Đơn vị thực hiện:** Senior Software Engineer, Test Architect & QA Automation Specialist (Solo Developer)  
**Ngày phát hành:** 15/10/2026  
**Ngôn ngữ tài liệu:** Tiếng Việt (Thuật ngữ chuyên môn và định danh kỹ thuật giữ nguyên Tiếng Anh)  

---

## MỤC LỤC TÀI LIỆU
1. [Phần 1: Giới thiệu Chung (Introduction)](#phần-1-giới-thiệu-chung-introduction)
2. [Phần 2: Phần mềm Được Kiểm thử (Software Under Test - SUT)](#phần-2-phần-mềm-được-kiểm-thử-software-under-test---sut)
3. [Phần 3: Mục tiêu Kiểm thử (Test Objectives)](#phần-3-mục-tiêu-kiểm-thử-test-objectives)
4. [Phần 4: Phạm vi Kiểm thử (Testing Scope)](#phần-4-phạm-vi-kiểm-thử-testing-scope)
5. [Phần 5: Chiến lược Kiểm thử Thống nhất 5 Tầng (Test Strategy)](#phần-5-chiến-lược-kiểm-thử-thống-nhất-5-tầng-test-strategy)
6. [Phần 6: Kỹ thuật Thiết kế Ca Kiểm thử (Test Design Techniques)](#phần-6-kỹ-thuật-thiết-kế-ca-kiểm-thử-test-design-techniques)
7. [Phần 7: Môi trường Kiểm thử (Test Environment)](#phần-7-môi-trường-kiểm-thử-test-environment)
8. [Phần 8: Đặc tả Bộ Ca Kiểm thử Chi tiết (Test Case Specification)](#phần-8-đặc-tả-bộ-ca-kiểm-thử-chi-tiết-test-case-specification)
9. [Phần 9: Ma trận Truy vết Yêu cầu (Requirement Traceability Matrix)](#phần-9-ma-trận-truy-vết-yêu-cầu-requirement-traceability-matrix)
10. [Phần 10: Kiến trúc Tự động hóa Kiểm thử (Automation Architecture)](#phần-10-kiến-trúc-tự-động-hóa-kiểm-thử-automation-architecture)
11. [Phần 11: Dữ liệu Kiểm thử Nhân tạo (Test Data Specification)](#phần-11-dữ-liệu-kiểm-thử-nhân-tạo-test-data-specification)
12. [Phần 12: Đánh giá Rủi ro và Biện pháp Giảm thiểu (Risk Assessment)](#phần-12-đánh-giá-rủi-ro-và-biện-pháp-giảm-thiểu-risk-assessment)
13. [Phần 13: Tiêu chí Tiếp nhận và Kết thúc Kiểm thử (Entry & Exit Criteria)](#phần-13-tiêu-chí-tiếp-nhận-và-kết-thúc-kiểm-thử-entry--exit-criteria)
14. [Phần 14: Kế hoạch Triển khai 3 Tuần cho Solo Developer (Three-Week Schedule)](#phần-14-kế-hoạch-triển-khai-3-tuần-cho-solo-developer-three-week-schedule)
15. [Phần 15: Hướng dẫn Vận hành và Thực thi Tự động hóa (Execution Instructions)](#phần-15-hướng-dẫn-vận-hành-và-thực-thi-tự-động-hóa-execution-instructions)

---

## Phần 1: Giới thiệu Chung (Introduction)

Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS là hệ thống phần mềm chuyên nghiệp hóa công tác tổ chức và điều hành các giải đấu thể thao điện tử quy mô lớn tại môi trường đại học (Đại học Bách khoa - Đại học Đà Nẵng).

Tài liệu này là hồ sơ kỹ thuật toàn diện định hình toàn bộ kế hoạch, chiến lược, thiết kế kịch bản và kiến trúc kiểm thử tự động của hệ thống. Dự án được triển khai và bảo trì độc lập bởi **01 lập trình viên duy nhất (Solo Developer)** dưới sự trợ giúp của AI thế hệ mới, đảm bảo đáp ứng các tiêu chuẩn công nghiệp khắt khe về độ tin cậy, an toàn thông tin cá nhân (PII) và khả năng chịu tải cao điểm.

---

## Phần 2: Phần mềm Được Kiểm thử (Software Under Test - SUT)

Hệ thống được kiểm thử bao gồm các phân hệ kiến trúc:
1. **Phân hệ Backend API (`Web-giai-dau`):**
   - Nền tảng: Node.js (v24 LTS) + Express.js 5.0 + TypeScript 5.9.
   - Cơ sở dữ liệu: PostgreSQL 15 (Supabase Cloud Pooler, Transaction Mode).
   - Mô hình định danh: 100% Khóa chính UUID (`gen_random_uuid()`), bảng `users` hợp nhất liên kết 1:1 với `participants`.
   - Các dịch vụ chính: `auth`, `participant` (KYC), `tournament`, `registration`, `teamRequest`, `checkin`, `admin`.
2. **Phân hệ Frontend Client (`DUT_esports_frontend`):**
   - Nền tảng: Next.js 15.3.0 (App Router, Turbopack) + React 19.2.5 + TypeScript 5.9.
   - Thư viện giao diện: Tailwind CSS, CSS Modules, Leaflet 1.9.4 (OpenStreetMap Tiles), React Hook Form, Zod.
   - Quản lý trạng thái: Zustand 5.0, TanStack React Query 5.87.
3. **Phân hệ Tài liệu & Quản lý Yêu cầu (`Web-giai-dau-docs`):**
   - Đặc tả yêu cầu phần mềm: SRS 1.1 (IEEE Std 830-1998) và Bản thảo SRS 1.2 Draft.
   - Lược đồ cơ sở dữ liệu: `database_schema.sql` (v2.0 - 18 bảng cốt lõi) và `migrations.sql`.

---

## Phần 3: Mục tiêu Kiểm thử (Test Objectives)

1. **Kiểm định Tính Đúng đắn của Nghiệp vụ:** Xác minh 100% các luồng nghiệp vụ trong phạm vi đã cài đặt, bao gồm Vòng đời giải đấu (GD0 - GD4), tạo đội, bật/tắt tuyển quân, duyệt thành viên, quét QR động 30s và Geofencing GPS.
2. **Loại trừ Rủi ro Xung đột Đồng thời (Concurrency Safety):** Kiểm tra cơ chế chống Race Condition khi nhiều đội trưởng cùng duyệt nhận một vận động viên tại cùng mili-giây, hoặc khi 50 thí sinh cùng quét 1 mã QR động trên màn chiếu.
3. **Bảo mật Định danh & Quyền Riêng tư (PII & Zero CCCD):** Đảm bảo tuyệt đối không thu thập hoặc lưu trữ bất kỳ trường dữ liệu nào liên quan đến CCCD/CMND; kiểm tra cơ chế che mờ dữ liệu (Data Masking) đối với email và số điện thoại.
4. **Kiểm soát Phân quyền RBAC Đa tầng:** Xác minh tính cách ly quyền lực giữa 4 vai trò: Admin, CTV thường trực, CTV thời vụ (giới hạn theo giải) và Thí sinh.
5. **Đo lường Hiệu năng Thực tế:** Đo đạc độ trễ phản hồi tại phân vị 95 ($p95 < 2.0s$) và sức chịu tải 500 yêu cầu điểm danh mỗi phút theo tiêu chuẩn NFR-PRF-01 và NFR-PRF-03.

---

## Phần 4: Phạm vi Kiểm thử (Testing Scope)

### 4.1 Phạm vi Trọng tâm (Two Core Business Functions)
Dự án tập trung kiểm thử chuyên sâu vào **02 Chức năng Cốt lõi**:
- **Chức năng A: Quản lý Đăng ký Giải đấu & Tuyển quân (Tournament Registration & Team Recruitment):**
  - Đăng ký giải đấu cá nhân và đồng đội.
  - Xử lý biểu mẫu động JSONB (`form_schema`) theo từng bộ môn game.
  - Bật/tắt cờ tuyển quân (`is_recruiting`).
  - Gửi, chấp nhận và từ chối yêu cầu gia nhập đội (`team_join_requests`).
  - Kiểm soát sĩ số tối đa (`max_team_size`) và tự động đóng tuyển quân khi đủ người.
  - Ngăn chặn một thí sinh đăng ký nhiều đội trong cùng một giải.
  - Chặn đăng ký khi giải đấu đã đóng (`closed_registration`).
- **Chức năng B: Điểm danh Giải đấu Đa phương thức (Tournament Multi-modal Check-in):**
  - Sinh mã QR động xoay vòng 30 giây (`checkin_qr_tokens`).
  - Xác thực tọa độ GPS Geofencing (bán kính sàn đấu 100m, sai số $\le 100m$).
  - Nộp ảnh minh chứng dự phòng (Proof Submission) khi lỗi cảm biến định vị.
  - Bản đồ đối soát tập trung Leaflet OpenStreetMap cho Ban tổ chức.
  - Chặn điểm danh trùng lặp và xử lý tải đồng thời.

### 4.2 Các Tính năng Hỗ trợ Nền tảng
- Xác thực tài khoản, kiểm tra 02 ảnh thẻ SV KYC (Zero CCCD).
- Kiểm tra tính bất biến của bảng `audit_logs`.

### 4.3 Giới hạn Ngoài Phạm vi (Out-of-Scope)
- Thuật toán tự động sinh nhánh đấu (Single/Double Elimination) và Worker render E-Certificate PDF (Do mã nguồn backend chưa triển khai; được đánh giá minh bạch là `BLOCKED_BY_REQUIREMENT`).

---

## Phần 5: Chiến lược Kiểm thử Thống nhất 5 Tầng (Test Strategy)

Chiến lược áp dụng mô hình Kim tự tháp Kiểm thử Thống nhất (Unified Test Pyramid) tối ưu cho Solo Developer:

```text
▲ TẦNG 5: PERFORMANCE TESTING (Kiểm thử tải đồng thời 500 req/min, đo đạc p95 latency)
├── TẦNG 4: MOBILE WEB TESTING (Playwright Mobile: Viewport di động, Giả lập GPS & Camera QR)
├── TẦNG 3: WEB UI TESTING (Playwright Desktop: Hành trình nộp đơn, Bản đồ Leaflet OSM)
├── TẦNG 2: API TESTING (Node.js Native Test Suite: Endpoints Express 5.0 + PostgreSQL Supabase)
└── TẦNG 1: UNIT TESTING (Node.js Native Runner: Thuật toán TFT, Haversine, Magic Bytes, State Machine)
```

1. **Tầng 1 (Unit Testing):** Sử dụng Node.js Native Runner (`node --test`) kiểm thử các hàm tính toán thuần túy. Thời gian chạy $< 500ms$.
2. **Tầng 2 (API Testing):** Kiểm thử các endpoints tích hợp logic, cơ chế khóa hàng CSDL và phản hồi HTTP status codes.
3. **Tầng 3 (Web UI Testing):** Sử dụng Playwright Desktop kiểm tra các modal, form nhập liệu và bản đồ số Leaflet.
4. **Tầng 4 (Mobile Web Testing):** Sử dụng Playwright Device Emulation mô phỏng Pixel 7 và iPhone 14 Pro, bơm tọa độ GPS nhân tạo để kiểm tra phản ứng của hệ thống.
5. **Tầng 5 (Performance Testing):** Sử dụng kịch bản tải Node.js đo đạc phân vị thời gian thực `performance.now()`.

---

## Phần 6: Kỹ thuật Thiết kế Ca Kiểm thử (Test Design Techniques)

Áp dụng 8 kỹ thuật thiết kế ca kiểm thử chuẩn quốc tế:
1. **Phân vùng Tương đương (Equivalence Partitioning - EP):** Chia khoảng cách Geofencing thành $\le 100m$ (Hợp lệ) và $> 100m$ (Ngoài vùng).
2. **Phân tích Giá trị Biên (Boundary Value Analysis - BVA):** Đo kiểm tại $99m$, $100m$, $101m$; thời gian QR token tại $29s$, $30s$, $31s$; sĩ số đội tại $max\_team\_size - 1$, $max\_team\_size$, $max\_team\_size + 1$.
3. **Kiểm thử Bảng Quyết định (Decision Tables):** Đánh giá tổ hợp điều kiện điểm danh: Token QR + Tọa độ GPS + Trạng thái đã điểm danh.
4. **Kiểm thử Chuyển trạng thái (State Transition Testing):** Kiểm tra tính hợp lệ của các chuyển đổi trạng thái giải đấu theo `STATE_TRANSITION_MATRIX.md`.
5. **Kiểm thử Tiêu cực & Ngoại lệ (Negative Testing):** Thử nghiệm gửi dữ liệu sai schema, KYC chưa duyệt, giải đã đóng cổng.
6. **Kiểm thử Xung đột Đồng thời (Concurrency Testing):** Đua luồng 2 đội trưởng cùng duyệt 1 thí sinh tại cùng thời điểm.
7. **Kiểm thử An toàn & Bảo mật (Security Testing):** Thử nghiệm leo quyền RBAC, kiểm tra Zero CCCD và che mờ dữ liệu cá nhân.
8. **Kiểm thử Hồi quy (Regression Testing):** Chạy lại toàn bộ test suite sau mỗi lần sửa đổi logic.

---

## Phần 7: Môi trường Kiểm thử (Test Environment)

- **Phần cứng máy trạm:** CPU 8 Cores, 16 GB RAM, OS Windows 11 x64.
- **Runtime:** Node.js v24.19.0 (Hỗ trợ Native TypeScript & Test Runner).
- **Cơ sở dữ liệu:** PostgreSQL 15 trên nền tảng Supabase Cloud (AWS AP-Southeast-1, SSL Mode).
- **Backend API:** Express.js 5.0 (Cổng 5000).
- **Frontend Client:** Next.js 15.3 (Cổng 3000, Turbopack).
- **Trình duyệt kiểm thử:** Chromium, Firefox, WebKit (Apple Safari) và Microsoft Edge.

---

## Phần 8: Đặc tả Bộ Ca Kiểm thử Chi tiết (Test Case Specification)

Toàn bộ 17 ca kiểm thử chính thức cho 2 chức năng trọng tâm, bảo mật và hiệu năng được quy định tại tệp [TEST_CASES.md](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/testing/test-design/TEST_CASES.md).

*Tóm tắt danh mục ca kiểm thử:*
- `TC-REG-001`: Đăng ký đội hợp lệ kèm dữ liệu biểu mẫu động JSONB.
- `TC-REG-002`: Chặn đăng ký khi thí sinh chưa hoàn tất duyệt KYC.
- `TC-REG-003`: Chặn đăng ký khi giải đấu đã đóng cổng (`closed_registration`).
- `TC-REG-004`: Chặn một thí sinh tham gia 2 đội khác nhau trong cùng một giải.
- `TC-REG-005`: Tự động tắt cờ tuyển quân khi đội đạt sĩ số tối đa (`max_team_size`).
- `TC-REG-006`: Xử lý đua luồng đồng thời khi 2 đội trưởng cùng duyệt 1 thí sinh.
- `TC-CHK-001`: Điểm danh thành công với QR động hợp lệ và tọa độ GPS trong Geofence.
- `TC-CHK-002`: Từ chối điểm danh khi mã QR động đã hết hạn 30 giây.
- `TC-CHK-003`: Tọa độ GPS ngoài bán kính Geofence -> Chuyển sang nộp minh chứng.
- `TC-CHK-004`: Chặn điểm danh trùng lặp (Duplicate Check-in Prevention).
- `TC-CHK-005`: 50 thí sinh quét cùng 1 mã QR động hiển thị trên màn chiếu sàn đấu.
- `TC-CHK-006`: Điểm danh dự phòng bằng nộp ảnh minh chứng khi lỗi cảm biến GPS.
- `TC-CHK-007`: Ban tổ chức đối soát tọa độ và duyệt ảnh minh chứng trên bản đồ Leaflet OSM.
- `TC-SEC-001`: Tuân thủ tuyệt đối nguyên tắc Không CCCD (Zero CCCD Invariant).
- `TC-SEC-002`: Chặn CTV thời vụ bị thu hồi quyền thực hiện thao tác duyệt.
- `TC-PRF-001`: Đo lường thời gian phản hồi quét QR tại phân vị 95 ($p95 < 2.0s$).
- `TC-PRF-002`: Kiểm thử chịu tải cao điểm 500 yêu cầu điểm danh mỗi phút.

---

## Phần 9: Ma trận Truy vết Yêu cầu (Requirement Traceability Matrix)

Ma trận truy vết 100% các yêu cầu MUST từ SRS 1.1 đến các ca kiểm thử tự động được quy định chi tiết tại tệp [REQUIREMENT_TRACEABILITY_MATRIX.md](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/testing/test-design/REQUIREMENT_TRACEABILITY_MATRIX.md).

*Tóm tắt độ bao phủ:*
- Tổng số yêu cầu MUST: 30 yêu cầu.
- Số yêu cầu đã kiểm thử đạt (PASS): 26 yêu cầu (86.7%).
- Số yêu cầu bị chặn do chưa có mã nguồn backend (`BLOCKED_BY_REQUIREMENT`): 4 yêu cầu (13.3%).
- **Độ bao phủ cho 02 Chức năng Cốt lõi: 100% ĐẠT**.

---

## Phần 10: Kiến trúc Tự động hóa Kiểm thử (Automation Architecture)

Khung kiểm thử tự động hóa độc lập được tổ chức trong thư mục `tests/`:

```text
tests/
├── unit/                        # Kiểm thử đơn vị logic thuần túy
│   ├── tft-allocation.test.ts   # Thuật toán TFT 7-8 người & Frobenius gaps
│   ├── geofence-haversine.test.ts # Tính khoảng cách Haversine & Geofence bounds
│   ├── tournament-lifecycle.test.ts # Máy trạng thái giải đấu & Khóa cấu hình
│   └── image-magic-bytes.test.ts# Nhận diện chữ ký tệp nhị phân ảnh
├── api/                         # Kiểm thử tích hợp Endpoints API
│   ├── registration-recruitment.api.test.ts # Function A (Đăng ký, Tuyển quân, Concurrency)
│   ├── checkin-multimodal.api.test.ts       # Function B (QR 30s, GPS, Nộp ảnh, 50 users)
│   └── rbac-security.api.test.ts            # Bảo mật RBAC, Zero CCCD, Data Masking
├── web/                         # Kiểm thử giao diện Web máy tính (Playwright)
│   ├── registration-flow.web.spec.ts
│   └── checkin-osm-map.web.spec.ts
├── mobile-web/                  # Kiểm thử Web di động & Giả lập GPS (Playwright Mobile)
│   └── mobile-checkin.spec.ts
├── performance/                 # Kịch bản kiểm thử tải & đo lường p95 latency
│   └── checkin-load.perf.ts
├── fixtures/                    # Dữ liệu nhân tạo & Hằng số kiểm thử
│   ├── test-constants.ts
│   └── synthetic-data.ts
└── helpers/                     # Các hàm tiện ích bổ trợ
    ├── geo.ts
    ├── tft-algorithm.ts
    └── lifecycle.ts
```

---

## Phần 11: Dữ liệu Kiểm thử Nhân tạo (Test Data Specification)

Toàn bộ dữ liệu kiểm thử tuân thủ nguyên tắc: **100% Nhân tạo (Synthetic Data), Không sử dụng PII thật**.
- Chi tiết quy chuẩn tài khoản nhân tạo, tọa độ sàn đấu Hội trường F và buffer ảnh giả định được quy định tại tệp [TEST_DATA_SPECIFICATION.md](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/testing/test-design/TEST_DATA_SPECIFICATION.md).

---

## Phần 12: Đánh giá Rủi ro và Biện pháp Giảm thiểu (Risk Assessment)

| Rủi ro Kỹ thuật (Technical Risk) | Mức độ | Khả năng | Biện pháp Giảm thiểu đã Triển khai |
|---|:---:|:---:|---|
| **Xung đột Race Condition khi tuyển quân** | Critical | High | Sử dụng khóa hàng CSDL `FOR UPDATE` và kiểm tra ràng buộc trước khi chèn. |
| **Giả mạo vị trí GPS (Mock Location)** | High | Medium | Kết hợp kiểm tra sai số GPS $\le 100m$; cơ chế nộp ảnh minh chứng dự phòng đối soát thủ công. |
| **Rò rỉ quyền hạn khi thu hồi phân công CTV** | High | Low | Triển khai middleware `activeStaff` và `tournamentScope` kiểm tra CSDL thời gian thực thay vì chỉ dựa vào Stateless JWT. |
| **Quá tải ngày khai mạc mở cổng check-in** | High | Medium | Tối ưu hóa truy vấn CSDL, kiểm thử tải 500 req/min đạt throughput 538 RPS và p95 latency ~47ms. |

---

## Phần 13: Tiêu chí Tiếp nhận và Kết thúc Kiểm thử (Entry & Exit Criteria)

- **Tiêu chí Tiếp nhận:** Mã nguồn sạch, biên dịch không lỗi TypeScript, CSDL Supabase sẵn sàng kết nối.
- **Tiêu chí Kết thúc:** 100% test cases cho 2 chức năng trọng tâm được thực thi thực tế; tỷ lệ Đạt $\ge 95\%$; không có lỗi Blocker/Critical còn mở; hoàn thành đầy đủ báo cáo hàn lâm.

---

## Phần 14: Kế hoạch Triển khai 3 Tuần cho Solo Developer (Three-Week Schedule)

- **Tuần 1:** Khảo sát kho lưu trữ, kiểm toán chuyên sâu SRS 1.1, lập danh mục khuyết tật và thiết kế Test Cases / RTM.
- **Tuần 2:** Thiết lập khung tự động hóa `tests/`, hiện thực hóa Unit, API, Web UI, Mobile Web và Performance tests.
- **Tuần 3:** Thực thi kiểm thử thực tế, thu thập bằng chứng khách quan, đo lường hiệu năng và biên soạn báo cáo học thuật.
*(Chi tiết tại tệp [PROJECT_PLAN.md](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/testing/PROJECT_PLAN.md)).*

---

## Phần 15: Hướng dẫn Vận hành và Thực thi Tự động hóa (Execution Instructions)

Các câu lệnh thực thi kiểm thử độc lập dành cho Solo Developer:

```bash
# 1. Chạy toàn bộ Test Suite Thống nhất (56 ca kiểm thử Unit & API):
npm test

# 2. Chỉ chạy tầng Kiểm thử Đơn vị (Unit Tests):
npm run test:unit

# 3. Chỉ chạy tầng Kiểm thử Giao diện Lập trình (API Tests):
npm run test:api

# 4. Chạy kịch bản Đo lường Hiệu năng & Tải đồng thời 500 req/min:
npm run test:perf
```
