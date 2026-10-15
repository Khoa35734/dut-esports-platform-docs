# DUT ESPORTS — Hồ Sơ Kiểm Toán SRS & Kiến Trúc Kiểm Thử Phần Mềm

🌐 **Ngôn ngữ / Language:** **[Tiếng Việt](README.md)** | **[English](../en/README.md)**

Thư mục này chứa toàn bộ hệ thống tài liệu tiếng Việt phục vụ công tác kiểm toán yêu cầu (SRS Audit), thiết kế kiểm thử chuẩn quốc tế ISO/IEC/IEEE 29119 và báo cáo kiểm định thực tế của dự án **Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS**.

---

## Cấu Trúc Phân Hệ Tài Liệu Tiếng Việt

Tất cả các tài liệu được tập trung tại phân hệ [`testing/`](testing/):

### 1. Khảo sát & Quản lý Tiến độ
- [`testing/REPOSITORY_AUDIT.md`](testing/REPOSITORY_AUDIT.md): Báo cáo khảo sát toàn diện kho mã nguồn, phân loại công nghệ và ma trận trạng thái tính năng.
- [`testing/PROJECT_PLAN.md`](testing/PROJECT_PLAN.md): Kế hoạch dự án 3 tuần dành riêng cho Solo Developer.
- [`testing/TASK_BOARD.md`](testing/TASK_BOARD.md): Bảng Kanban theo dõi công việc chi tiết.
- [`testing/WORK_LOG.md`](testing/WORK_LOG.md): Nhật ký tiến trình theo từng mốc thời gian.

### 2. Hồ sơ Kiểm toán SRS 1.1 & Khuyết tật ([`testing/srs-audit/`](testing/srs-audit/))
- [`testing/srs-audit/SRS_AUDIT_REPORT.md`](testing/srs-audit/SRS_AUDIT_REPORT.md): Báo cáo kiểm toán chuyên sâu 8 vùng rủi ro nghiệp vụ.
- [`testing/srs-audit/SRS_ISSUES.md`](testing/srs-audit/SRS_ISSUES.md): Danh mục 10 khuyết tật SRS kèm phản ví dụ toán học và logic.
- [`testing/srs-audit/SRS_IMPROVEMENT_PROPOSAL.md`](testing/srs-audit/SRS_IMPROVEMENT_PROPOSAL.md): Đề xuất cải tiến kỹ thuật đồng bộ.
- [`testing/srs-audit/BUSINESS_RULE_GAPS.md`](testing/srs-audit/BUSINESS_RULE_GAPS.md): Phân tích 6 khoảng trống quy tắc nghiệp vụ.
- [`testing/srs-audit/DATABASE_CONSISTENCY_REPORT.md`](testing/srs-audit/DATABASE_CONSISTENCY_REPORT.md): Báo cáo đối soát 18 bảng CSDL PostgreSQL vật lý.
- [`testing/srs-audit/STATE_TRANSITION_MATRIX.md`](testing/srs-audit/STATE_TRANSITION_MATRIX.md): Ma trận chuyển trạng thái hình thức giải đấu và trận đấu.
- [`testing/srs-audit/DECISION_LOG.md`](testing/srs-audit/DECISION_LOG.md): Nhật ký các quyết định kiến trúc và kỹ thuật.
- [`testing/srs-audit/SRS_REVISED_DRAFT.md`](testing/srs-audit/SRS_REVISED_DRAFT.md): Bản thảo cải tiến đặc tả SRS 1.2 Draft.

### 3. Bộ Thiết kế Kiểm thử Chuẩn ISO/IEC/IEEE 29119 ([`testing/test-design/`](testing/test-design/))
- [`testing/test-design/TEST_PLAN.md`](testing/test-design/TEST_PLAN.md): Kế hoạch kiểm thử tổng thể (Master Test Plan).
- [`testing/test-design/TEST_STRATEGY.md`](testing/test-design/TEST_STRATEGY.md): Chiến lược kiểm thử thống nhất 5 tầng cho Solo Developer.
- [`testing/test-design/TEST_SCENARIOS.md`](testing/test-design/TEST_SCENARIOS.md): Danh mục 23 kịch bản kiểm thử bao phủ toàn diện.
- [`testing/test-design/TEST_CASES.md`](testing/test-design/TEST_CASES.md): Đặc tả 17 ca kiểm thử chi tiết.
- [`testing/test-design/REQUIREMENT_TRACEABILITY_MATRIX.md`](testing/test-design/REQUIREMENT_TRACEABILITY_MATRIX.md): Ma trận truy vết RTM đạt 100% yêu cầu MUST.
- [`testing/test-design/TEST_DATA_SPECIFICATION.md`](testing/test-design/TEST_DATA_SPECIFICATION.md): Quy chuẩn 100% dữ liệu nhân tạo (Zero CCCD Invariant).
- [`testing/test-design/TEST_COVERAGE_GAP.md`](testing/test-design/TEST_COVERAGE_GAP.md): Báo cáo phân tích khoảng trống bao phủ.

### 4. Báo cáo Kiểm thử Học thuật ([`testing/reports/`](testing/reports/))
- [`testing/reports/SOFTWARE_TESTING_DOCUMENT.md`](testing/reports/SOFTWARE_TESTING_DOCUMENT.md): Tài liệu Kiểm thử Phần mềm Tổng thể 15 phần chuẩn học thuật.

---

Đối với các tài liệu Phân tích Nghiệp vụ và Đặc tả Tác vụ Kỹ thuật bằng Tiếng Anh, vui lòng xem tại thư mục [`../en/`](../en/).
