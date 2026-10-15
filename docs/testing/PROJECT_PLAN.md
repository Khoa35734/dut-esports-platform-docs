# KẾ HOẠCH DỰ ÁN KIỂM THỬ 3 TUẦN (THREE-WEEK SOLO PROJECT PLAN)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Quy mô:** Dự án 01 Kỹ sư Lập trình & QA Độc lập (Solo Developer Assisted by AI)  
**Thời gian thực hiện:** 3 Tuần liên tục  
**Khung thời gian chuẩn:** Tuần 1 đến Tuần 3  
**Người chịu trách nhiệm duy nhất:** `SOLO_DEVELOPER`  

---

## 1. MỤC TIÊU VÀ NGUYÊN TẮC QUẢN LÝ DỰ ÁN

1. **Phân phối Trách nhiệm Độc lập:** Không có quy trình phê duyệt nhóm, không phân chia ban bệ. Toàn bộ các vai trò (BA, Architect, QA, Tester, Documentation Writer) đều do một kỹ sư đảm nhiệm dưới sự hỗ trợ chuyên sâu của AI.
2. **Ưu tiên Tính thực chất (Substance over Ceremony):** Bám sát mã nguồn và cơ sở dữ liệu thực tế, không ngụy tạo kết quả kiểm thử, không viết tài liệu đối phó.
3. **Độ bao phủ Toàn diện 5 Tầng Kiểm thử:**
   - Unit Testing (Kiểm thử đơn vị logic thuần túy)
   - API Testing (Kiểm thử tích hợp giao diện lập trình)
   - Web UI Testing (Kiểm thử giao diện máy tính để bàn)
   - Mobile Web Testing (Kiểm thử mô phỏng thiết bị di động & phần cứng)
   - Performance Testing (Kiểm thử tải đồng thời & độ trễ p95)

---

## 2. KẾ HOẠCH CHI TIẾT THEO TỪNG TUẦN (THREE-WEEK SCHEDULE)

### TUẦN 1: KHẢO SÁT, THẨM ĐỊNH SRS & THIẾT KẾ TEST CASES
**Mục tiêu chính:** Nắm bắt toàn bộ hiện trạng mã nguồn, phát hiện lỗ hổng nghiệp vụ trong SRS 1.1, thiết kế chi tiết bộ kịch bản kiểm thử và ma trận truy vết yêu cầu.

| Ngày (Day) | Đầu việc Thực hiện (Tasks) | Đầu ra Dự kiến (Deliverables) | Trạng thái |
|:---:|---|---|:---:|
| **Day 1** | Khảo sát kho lưu trữ, kiểm tra Git, phân tích package.json Backend/Frontend | `docs/testing/REPOSITORY_AUDIT.md` | **HOÀN THÀNH** |
| **Day 2** | Thẩm định chi tiết 8 vùng rủi ro SRS 1.1 (Vòng đời giải, Tuyển quân, Nhánh đấu, TFT, Check-in, RBAC, Cert, CSDL) | `docs/testing/srs-audit/SRS_AUDIT_REPORT.md` | **HOÀN THÀNH** |
| **Day 3** | Lập danh mục 10 lỗi SRS, phân tích khoảng trống nghiệp vụ và mâu thuẫn CSDL | `SRS_ISSUES.md`, `BUSINESS_RULE_GAPS.md`, `DATABASE_CONSISTENCY_REPORT.md` | **HOÀN THÀNH** |
| **Day 4** | Xây dựng ma trận chuyển trạng thái hình thức và soạn thảo bản cải tiến SRS 1.2 Draft | `STATE_TRANSITION_MATRIX.md`, `SRS_REVISED_DRAFT.md`, `DECISION_LOG.md` | **HOÀN THÀNH** |
| **Day 5** | Xây dựng Kế hoạch Kiểm thử Tổng thể & Chiến lược Kiểm thử 5 tầng cho 1 lập trình viên | `docs/testing/test-design/TEST_PLAN.md`, `TEST_STRATEGY.md` | **ĐANG TIẾN HÀNH** |
| **Day 6** | Thiết kế bộ Test Cases chi tiết cho 2 chức năng trọng tâm (Registration & Multi-modal Check-in) | `docs/testing/test-design/TEST_SCENARIOS.md`, `TEST_CASES.md` | **ĐANG TIẾN HÀNH** |
| **Day 7** | Lập Ma trận Truy vết Yêu cầu (RTM) và Quy chuẩn Dữ liệu Kiểm thử (Test Data Spec) | `REQUIREMENT_TRACEABILITY_MATRIX.md`, `TEST_DATA_SPECIFICATION.md` | **ĐANG TIẾN HÀNH** |

---

### TUẦN 2: THIẾT LẬP FRAMEWORK & TRIỂN KHAI MÃ NGUỒN TỰ ĐỘNG HÓA
**Mục tiêu chính:** Xây dựng khung kiểm thử tự động độc lập (`tests/`), hiện thực hóa toàn bộ các test script cho 5 tầng kiểm thử.

| Ngày (Day) | Đầu việc Thực hiện (Tasks) | Đầu ra Dự kiến (Deliverables) |
|:---:|---|---|
| **Day 8** | Khởi tạo cấu trúc thư mục kiểm thử thống nhất `tests/` (unit, api, web, mobile-web, performance, fixtures, helpers) | Thư mục `tests/` sẵn sàng thực thi |
| **Day 9** | Hiện thực hóa Unit Tests: Thuật toán TFT, State Transitions, Geofencing Haversine, Validation biểu mẫu | `tests/unit/*.test.ts` |
| **Day 10** | Hiện thực hóa API Tests: Đăng ký giải đấu, Tuyển quân, Join requests, QR token rotation, Check-in approval | `tests/api/*.test.ts` |
| **Day 11** | Hiện thực hóa Web UI Tests: Playwright kịch bản tạo đội, nộp đơn, đối soát bản đồ Leaflet OSM | `tests/web/*.spec.ts` |
| **Day 12** | Hiện thực hóa Mobile Web Tests: Playwright giả lập thiết bị (Pixel 7 / iPhone 14 Pro), Camera & GPS Geolocation | `tests/mobile-web/*.spec.ts` |
| **Day 13** | Hiện thực hóa Performance Tests: Kịch bản tải cao điểm check-in (500 req/min), đo đạc p95 latency, throughput | `tests/performance/*.ts` |
| **Day 14** | Chạy thử nghiệm smoke test toàn bộ các script kiểm thử tự động, tinh chỉnh độ ổn định (Eliminate Flakiness) | Báo cáo tích hợp thử nghiệm |

---

### TUẦN 3: THỰC THI KIỂM THỬ TOÀN DIỆN, BÁO CÁO LỖI & HOÀN THIỆN TÀI LIỆU HÀN LÂM
**Mục tiêu chính:** Chạy kiểm thử thực tế trên môi trường live, thu thập bằng chứng khách quan, lập báo cáo khuyết tật và hoàn tất bộ hồ sơ kiểm thử phần mềm hàn lâm.

| Ngày (Day) | Đầu việc Thực hiện (Tasks) | Đầu ra Dự kiến (Deliverables) |
|:---:|---|---|
| **Day 15** | Thực thi chính thức toàn bộ Test Suite Unit & API trên môi trường Supabase PostgreSQL | `test-results/unit-api-results.json` |
| **Day 16** | Thực thi Web E2E & Mobile Web E2E Tests, chụp ảnh bằng chứng (Screenshots/Logs) | `test-results/e2e-evidence/` |
| **Day 17** | Thực thi kịch bản Kiểm thử Hiệu năng (Performance Benchmarks), thu thập biểu đồ p95, p99, throughput | `test-results/performance-metrics.json` |
| **Day 18** | Phân loại kết quả kiểm thử (PASS/FAIL/BLOCKED/NOT_RUN), lập hồ sơ khuyết tật phần mềm | `docs/testing/defects/DEFECT_REPORTS.md` |
| **Day 19** | Biên soạn Tài liệu Kiểm thử Phần mềm Tổng thể (Academic Software Testing Document) | `docs/testing/reports/SOFTWARE_TESTING_DOCUMENT.md` |
| **Day 20** | Biên soạn Báo cáo Kiểm thử Thực tế tập trung vào 2 chức năng trọng tâm (Academic Test Report) | `docs/testing/reports/TEST_REPORT.md` |
| **Day 21** | Rà soát toàn bộ tài liệu, kiểm kê tệp tin, nghiệm thu và kết thúc quy trình kiểm toán tự động | Hồ sơ hoàn chỉnh bàn giao cho Solo Developer |
