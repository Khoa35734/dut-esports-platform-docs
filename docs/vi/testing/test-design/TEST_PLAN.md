# KẾ HOẠCH KIỂM THỬ PHẦN MỀM TỔNG THỂ (MASTER TEST PLAN)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Tài liệu tham chiếu:** SRS 1.1, SRS 1.2 Draft, `database_schema.sql` (v2.0)  
**Tiêu chuẩn áp dụng:** ISO/IEC/IEEE 29119-3:2013 (Test Documentation Standard)  
**Người lập:** QA Testing Architect & Senior Software Engineer (Solo Developer)  
**Ngày phê duyệt:** 15/10/2026  
**Phiên bản:** 1.0  

---

## 1. GIỚI THIỆU & MỤC TIÊU KIỂM THỬ (INTRODUCTION & OBJECTIVES)

### 1.1 Giới thiệu
Kế hoạch Kiểm thử Tổng thể này định hình toàn bộ phạm vi, chiến lược, môi trường, kỹ thuật thiết kế và quy trình thực thi kiểm thử phần mềm cho Nền tảng Quản lý Giải đấu DUT ESPORTS. Dự án vận hành theo mô hình một lập trình viên duy nhất chịu trách nhiệm toàn diện dưới sự hỗ trợ chuyên sâu của AI.

### 1.2 Mục tiêu Kiểm thử Cốt lõi
1. **Xác minh Tính đúng đắn của Nghiệp vụ:** Đảm bảo toàn bộ các quy tắc nghiệp vụ về Vòng đời giải đấu, Đăng ký đội, Tuyển quân, Điểm danh sàn đấu và Phân quyền RBAC hoạt động chính xác theo đặc tả.
2. **Ngăn ngừa Lỗi Toàn vẹn Dữ liệu và Xung đột Đồng thời (Concurrency Safety):** Kiểm tra và loại bỏ triệt để các lỗi Race Condition khi nhiều đội trưởng cùng duyệt gia nhập một thí sinh, hoặc khi hàng trăm thí sinh cùng quét mã QR điểm danh đồng thời.
3. **Bảo vệ Dữ liệu Cá nhân (PII Security):** Xác minh việc tuân thủ tuyệt đối nguyên tắc Không CCCD (Zero CCCD Invariant) và cơ chế che giấu dữ liệu (Data Masking) đối với các vai trò hạn chế.
4. **Đo lường Hiệu năng Thực tế:** Đo kiểm độ trễ phản hồi tại p95, p99 và khả năng chịu tải 500 yêu cầu điểm danh mỗi phút theo tiêu chuẩn NFR-PRF-01 và NFR-PRF-03.

---

## 2. PHẠM VI KIỂM THỬ (TESTING SCOPE)

### 2.1 Trong Phạm vi Kiểm thử (In-Scope)
Kiểm thử toàn diện 5 tầng (Unit, API, Web UI, Mobile Web, Performance) với trọng tâm là **02 Chức năng Cốt lõi (Two Core Functions)**:
1. **Chức năng A: Quản lý Đăng ký Giải đấu & Tuyển quân (Tournament Registration & Team Recruitment):**
   - Đăng ký giải đấu cá nhân và đồng đội.
   - Xử lý biểu mẫu động JSONB (`form_schema`) theo từng bộ môn game.
   - Cơ chế bật/tắt chế độ tuyển quân (`is_recruiting`).
   - Luồng gửi, chấp nhận và từ chối yêu cầu gia nhập đội (`team_join_requests`).
   - Kiểm soát sĩ số đội (`min_team_size`, `max_team_size`), ràng buộc một thí sinh không thuộc 2 đội trong cùng giải.
   - Chặn đăng ký khi giải đấu đã đóng (`closed_registration`).
2. **Chức năng B: Điểm danh Giải đấu Đa phương thức (Tournament Multi-modal Check-in):**
   - Sinh và xác thực mã QR động xoay vòng 30 giây (`checkin_qr_tokens`).
   - Xác thực tọa độ GPS Geofencing (bán kính sàn đấu mặc định 100m, sai số $\le 100m$).
   - Nộp ảnh minh chứng dự phòng (Proof Submission) khi gặp sự cố phần cứng.
   - Giao diện đối soát bản đồ tập trung Leaflet OpenStreetMap dành cho CTV/Admin.
   - Kiểm soát Replay Attack và chống điểm danh trùng lặp (`UNIQUE(tournament_id, participant_id)`).
   - Kiểm tra tải đồng thời cao điểm ngày khai mạc giải.
3. **Các Phân hệ Hỗ trợ Tích hợp (Integration Scope):**
   - Phân quyền RBAC 4 vai trò: `admin`, `ctv`, `seasonal_staff`, `participant`.
   - Xác thực tài khoản, kiểm tra 02 ảnh thẻ SV KYC (Zero CCCD).
   - Nhật ký kiểm toán bất biến (`audit_logs`).

### 2.2 Ngoài Phạm vi Kiểm thử (Out-of-Scope)
- Thuật toán sinh nhánh đấu tự động (Single/Double Elimination) và Worker render E-Certificate PDF (Do mã nguồn backend chưa cài đặt API thực thi; đánh giá trạng thái `MISSING`/`DB_READY_CODE_MISSING`).
- Tích hợp API in-game của nhà phát hành game (Riot Games, Garena).
- Nhận diện khuôn mặt sinh trắc học (FaceID).
- In ấn phôi chứng chỉ vật lý trên giấy.

---

## 3. CƠ CẤU VÀ TỔ CHỨC NHÂN SỰ ĐƠN LẬP (SOLO TEAM ROLES)

Trong mô hình Solo Developer, mọi vai trò kiểm thử và phát triển được thống nhất vào một cá nhân duy nhất (`SOLO_DEVELOPER`):

| Vai trò Kỹ thuật | Trách nhiệm Chính |
|---|---|
| **Test Architect & Planner** | Xây dựng chiến lược kiểm thử, lựa chọn công cụ, lập kế hoạch và ma trận truy vết RTM. |
| **Test Case Designer** | Áp dụng các kỹ thuật Phân vùng tương đương, Phân tích giá trị biên, Bảng quyết định để viết Test Cases. |
| **Automation Engineer** | Viết mã nguồn kiểm thử tự động (Unit, API, Playwright Web, Mobile Emulation, Load Testing). |
| **Test Executor & Defect Manager**| Chạy kiểm thử trên môi trường thực tế, ghi nhận log, phân loại và lập hồ sơ khuyết tật. |
| **Documentation Writer** | Biên soạn Báo cáo Kiểm thử Phần mềm Tổng thể và Báo cáo Nghiệm thu Học thuật. |

---

## 4. MÔI TRƯỜNG KIỂM THỬ (TEST ENVIRONMENT SPECIFICATION)

| Thành phần | Đặc tả Kỹ thuật Môi trường Kiểm thử | Ghi chú Vận hành |
|---|---|---|
| **Máy trạm Kiểm thử (Host Machine)** | Windows 11 x64, 16 GB RAM, CPU 8 Cores | Môi trường cục bộ của Solo Developer |
| **Môi trường Thực thi (Runtime)** | Node.js v24.x (Hỗ trợ Native TypeScript & Test Runner) | Tránh cài đặt thêm các runtime phụ |
| **Cơ sở Dữ liệu Kiểm thử (Test DB)** | PostgreSQL 15 (Supabase Cloud Pooler Instance) | Chạy trên schema đồng bộ v2.0, dữ liệu cô lập |
| **Backend Under Test** | Express.js 5.0 (Cổng: `http://localhost:5000`) | Chạy qua `node --watch src/index.ts` |
| **Frontend Under Test** | Next.js 15.3 (Cổng: `http://localhost:3000`) | Chạy qua Turbopack dev server |
| **Trình duyệt Kiểm thử Web** | Chromium 120+, Firefox 120+, WebKit (Safari) | Quản lý bởi Playwright Test Engine |
| **Thiết bị Di động Mô phỏng** | Google Pixel 7 (Android 13), Apple iPhone 14 Pro (iOS 16) | Giả lập Viewport, Touch, Geolocation, Camera Stream |

---

## 5. TIÊU CHÍ TIẾP NHẬN VÀ KẾT THÚC KIỂM THỬ (ENTRY & EXIT CRITERIA)

### 5.1 Tiêu chí Bắt đầu (Entry Criteria)
1. Mã nguồn Backend (`Web-giai-dau`) và Frontend (`DUT_esports_frontend`) biên dịch thành công (`typecheck` không có lỗi cú pháp TypeScript).
2. Cơ sở dữ liệu Supabase kết nối thông suốt, 18 bảng cốt lõi đã được khởi tạo và sẵn sàng nhận dữ liệu.
3. Bộ tài liệu đặc tả kiểm thử (`TEST_PLAN.md`, `TEST_CASES.md`, `RTM.md`) đã được hoàn tất và rà soát tính khả thi.

### 5.2 Tiêu chí Tạm dừng và Phục hồi (Suspension & Resumption Criteria)
- **Tạm dừng khi:** Phát hiện lỗi nghiêm trọng (Blocker) làm sập API máy chủ hoặc mất kết nối cơ sở dữ liệu khiến $> 50\%$ test cases không thể tiếp tục thực thi.
- **Phục hồi khi:** Lỗi cơ sở hạ tầng được khắc phục và bài kiểm thử Smoke Test cơ bản vượt qua thành công.

### 5.3 Tiêu chí Kết thúc (Exit Criteria)
1. **100% các Test Cases được thiết kế cho 02 Chức năng Cốt lõi** đều được thực thi trên môi trường thực tế (Không có trạng thái `NOT_RUN` giả tạo).
2. **Tỷ lệ Đạt (Pass Rate):** Đạt tối thiểu **$\ge 95\%$** đối với các ca kiểm thử chức năng mức Unit và API.
3. **Không còn lỗi nghiêm trọng loại Critical hoặc High còn mở (Open)** mà chưa có giải pháp khắc phục hoặc ghi nhận rõ trong báo cáo lỗi.
4. Toàn bộ các yêu cầu mức BẮT BUỘC (MUST) trong phạm vi 2 chức năng đều có kết quả kiểm chứng truy vết đầy đủ trong Ma trận RTM.
5. Hồ sơ Báo cáo Kiểm thử Phần mềm (`SOFTWARE_TESTING_DOCUMENT.md` và `TEST_REPORT.md`) được biên soạn hoàn chỉnh với bằng chứng thực tế.
