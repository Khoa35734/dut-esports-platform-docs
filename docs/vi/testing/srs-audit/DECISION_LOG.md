# NHẬT KÝ QUYẾT ĐỊNH KỸ THUẬT & KIẾN TRÚC (DECISION LOG)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Người quyết định:** Solo Developer & QA Testing Architect  
**Môi trường:** Solo-developer Academic & Production-grade Environment  
**Ngày cập nhật:** 15/10/2026  

---

## 1. TỔNG QUAN

Tài liệu này ghi nhận toàn bộ các quyết định kiến trúc, giải pháp xử lý vùng xám nghiệp vụ và các thỏa hiệp kỹ thuật (Technical Trade-offs) trong quá trình thẩm định SRS và tự động hóa kiểm thử phần mềm. Mỗi quyết định đều tuân thủ nguyên tắc: **Khách quan, có bằng chứng thực tế từ mã nguồn/CSDL, và tối ưu cho mô hình một lập trình viên duy nhất**.

---

## 2. DANH SÁCH CÁC QUYẾT ĐỊNH (DECISION RECORDS)

---

### DEC-001: Chiến lược Phân nhánh và Bảo toàn Mã nguồn Hiện trạng
- **Ngày quyết định:** 15/10/2026
- **Trạng thái:** `APPROVED`
- **Ngữ cảnh:** Repo hiện tại đang có các thay đổi chưa commit của người dùng trên `main` (`SRS.md`, `database_schema.sql`, `migrations.sql`).
- **Quyết định:** Tạo và chuyển sang nhánh độc lập: `test/solo-srs-audit-automation`.
- **Lý do (Rationale):**
  - Tuyệt đối không can thiệp, không overwrite các thay đổi của người dùng.
  - Cho phép thực hiện toàn bộ công tác thẩm định tài liệu, viết test và chạy tự động hóa mà không gây xung đột Git (Merge Conflicts).
- **Phương án thay thế đã bác bỏ:** `git stash` hoặc commit trực tiếp lên `main` (rủi ro làm xáo trộn lịch sử git của dự án gốc).

---

### DEC-002: Lựa chọn 02 Chức năng Trọng tâm cho Báo cáo Kiểm thử Hàn lâm (Core Functions Selection)
- **Ngày quyết định:** 15/10/2026
- **Trạng thái:** `APPROVED`
- **Ngữ cảnh:** Đồ án kiểm thử hàn lâm yêu cầu chọn chính xác 02 chức năng nghiệp vụ cốt lõi để xây dựng báo cáo chuyên sâu, chạy toàn diện 5 tầng kiểm thử (Unit, API, Web UI, Mobile Web, Performance).
- **Quyết định:**
  - **Chức năng 1 (Function A):** Quản lý Đăng ký Giải đấu & Tuyển quân (Tournament Registration & Team Recruitment).
  - **Chức năng 2 (Function B):** Điểm danh Giải đấu Đa phương thức (Tournament Multi-modal Check-in).
- **Lý do (Rationale):**
  - Khảo sát mã nguồn thực tế tại Phase 0 cho thấy 2 chức năng này đã được cài đặt hoàn chỉnh từ Backend API (Express + Postgres) đến Frontend Web (Next.js 15 + Leaflet + Camera QR).
  - Có sẵn dữ liệu bảng CSDL (`registrations`, `team_join_requests`, `check_ins`, `checkin_qr_tokens`).
  - Các chức năng như Sinh nhánh đấu (Brackets) hoặc Cấp phát E-Certificate hiện chỉ mới có cấu trúc bảng DDL nhưng chưa có mã nguồn xử lý thuật toán ở backend, nếu chọn sẽ vi phạm nguyên tắc "Không báo cáo PASS khi chưa chạy kiểm thử thực tế".

---

### DEC-003: Lựa chọn Công cụ Kiểm thử Tối ưu cho Mô hình Một Lập trình viên
- **Ngày quyết định:** 15/10/2026
- **Trạng thái:** `APPROVED`
- **Ngữ cảnh:** Cần triển khai 5 tầng kiểm thử mà không làm phình to dependencies hoặc gây chậm trễ môi trường phát triển cục bộ.
- **Quyết định công nghệ:**
  1. **Unit Testing:** Sử dụng **Node.js Native Test Runner** (`node --test --experimental-strip-types`) cho Backend và `tsx` cho Frontend. Tận dụng tối đa Node 24 native, không cần cài thêm Jest/Vitest.
  2. **API Testing:** Bộ kiểm thử tự động API viết bằng Node.js script tương tác HTTP chuẩn với database seed.
  3. **Web UI Testing:** Sử dụng **Playwright** (`@playwright/test`) - đã có sẵn cấu hình và dependencies trong frontend.
  4. **Mobile Web Testing:** Sử dụng **Playwright Device Emulation** (Mô phỏng thiết bị di động chuẩn: Pixel 7, iPhone 14 Pro, giả lập GPS Geolocation và Camera Permissions). Không cài Appium do hệ thống là Responsive Web App, không có Native Mobile App.
  5. **Performance Testing:** Viết kịch bản đo kiểm tải đồng thời (Concurrency Load Test) đo lường chính xác các chỉ số: p95, p99 latency, throughput (req/sec), error rate.
- **Lý do (Rationale):** Tối giản hóa công cụ, không phát sinh xung đột gói, thời gian chạy cực nhanh.

---

### DEC-004: Xử lý Vùng xám Thuật toán Chia phòng TFT
- **Ngày quyết định:** 15/10/2026
- **Trạng thái:** `APPROVED`
- **Ngữ cảnh:** Thuật toán $m = \lceil N/8 \rceil$ với điều kiện $\lceil N/8 \rceil \le \lfloor N/7 \rfloor$ sẽ vô nghiệm với $N \in \{1..6, 9..13, 17..20, 25..27, 33..34, 41\}$.
- **Quyết định:** Giữ nguyên quy tắc toán học gốc của SRS 1.1; bổ sung phản hồi API cung cấp thông tin gợi ý bù trừ (Delta to next valid / Delta to prev valid) để người dùng điều chỉnh danh sách thay vì chỉ hiển thị lỗi chung chung.
- **Lý do (Rationale):** Quy tắc 7-8 người/phòng là luật thi đấu in-game bất di bất dịch của Riot Games dành cho Đấu Trường Chân Lý. Không được phép tự ý thay đổi thành phòng 5 hoặc 6 người nếu không có phê duyệt của Ban Chủ nhiệm CLB.

---

### DEC-005: Kiểm soát Xung đột Đồng thời khi Gia nhập Đội (Team Concurrency Strategy)
- **Ngày quyết định:** 15/10/2026
- **Trạng thái:** `APPROVED`
- **Ngữ cảnh:** Hai đội trưởng cùng duyệt gia nhập một thí sinh tại cùng thời điểm $t_0$.
- **Quyết định:**
  - Ở mức CSDL: Khuyến nghị thêm cột `tournament_id` vào `registration_members` với `UNIQUE(tournament_id, participant_id)`.
  - Ở mức Ứng dụng Backend: Áp dụng cơ chế khóa hàng bi quan `SELECT id FROM participants WHERE id = $1 FOR UPDATE` trong giao dịch `READ COMMITTED` hoặc sử dụng giao dịch `SERIALIZABLE`.
- **Lý do (Rationale):** Đảm bảo triệt để tính toàn vẹn (ACID), ngăn ngừa lỗi trùng thành viên ở mức sâu nhất của hệ thống.

---

### DEC-006: Chính sách Bảo mật Thông tin Định danh (Zero CCCD Invariant)
- **Ngày quyết định:** 15/10/2026
- **Trạng thái:** `APPROVED`
- **Ngữ cảnh:** Rà soát tính pháp lý theo Luật Bảo vệ dữ liệu cá nhân.
- **Quyết định:** Tuyệt đối không thu thập, không tạo trường CSDL cho CCCD/CMND. Mọi thao tác KYC chỉ dựa trên `student_id` và 02 ảnh thẻ SV (mặt trước và chân dung cầm thẻ).
- **Lý do (Rationale):** Tuân thủ tuyệt đối nguyên tắc tối thiểu hóa dữ liệu (Data Minimization) của SRS 1.1 và bảo vệ tối đa quyền riêng tư của sinh viên.
