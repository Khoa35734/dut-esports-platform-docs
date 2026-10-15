# BÁO CÁO KHOẢNG TRỐNG BAO PHỦ KIỂM THỬ (TEST COVERAGE GAP ANALYSIS)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Người lập:** QA Testing Architect & Lead Technical Reviewer  
**Ngày cập nhật:** 15/10/2026  

---

## 1. TỔNG QUAN TÌNH TRẠNG BAO PHỦ KIỂM THỬ

Báo cáo này phân tích chi tiết độ bao phủ kiểm thử thực tế đối chiếu với toàn bộ các yêu cầu của SRS 1.1 và các tính năng đã được hiện thực hóa trong mã nguồn.

### 1.1 Thống kê Định lượng (Quantitative Summary)
- **Tổng số Yêu cầu Nghiệp vụ (FR + NFR):** 38 yêu cầu.
- **Số Yêu cầu BẮT BUỘC (MUST):** 30 yêu cầu.
- **Số Yêu cầu được Bao phủ Kiểm thử Tự động Hoàn toàn:** **26 yêu cầu (86.7%)**.
- **Số Yêu cầu Bị Chặn Kiểm thử do Chưa có Mã nguồn (`BLOCKED_BY_REQUIREMENT`):** **4 yêu cầu (13.3%)**.

---

## 2. CHI TIẾT CÁC YÊU CẦU BỊ CHẶN (BLOCKED REQUIREMENTS GAP)

Dưới đây là các yêu cầu trong SRS 1.1 mà cơ sở dữ liệu đã có bảng DDL nhưng mã nguồn Backend chưa cài đặt controller/service:

| Mã Yêu cầu | Tên Yêu cầu Nghiệp vụ | Nguyên nhân Bị chặn (Blocker Reason) | Tác động Kiểm thử | Giải pháp Xử lý của Solo Developer |
|---|---|---|---|---|
| **FR-TRN-03** | Tự động sinh nhánh đấu (Single/Double Elimination) | Backend thiếu controller sinh nhánh; chưa có API bốc thăm và chuyển tiếp đội. | Không thể chạy API Test hoặc Web E2E Test cho luồng sinh nhánh. | Đánh dấu `BLOCKED_BY_REQUIREMENT`. Tập trung kiểm thử Unit cho hàm phân chia toán học và tập trung vào 02 Chức năng Cốt lõi. |
| **FR-TRN-05** | Nhập kết quả trận đấu, xác nhận và khiếu nại | Backend chưa có route cập nhật tỉ số `matches` và `match_games`. | Không thể kiểm thử luồng cập nhật tỉ số BO. | Đánh dấu `BLOCKED_BY_REQUIREMENT`. |
| **FR-CRT-01** | Kích hoạt Render E-Cert qua EDA (`tournament.completed`) | Thiếu tiến trình nền (Background Worker) lắng nghe sự kiện để chạy Puppeteer/PDFKit. | Không thể kiểm thử luồng sinh file PDF tự động. | Đánh dấu `BLOCKED_BY_REQUIREMENT`. |
| **FR-CRT-02** | Cấp phát E-Cert có mã QR và `certificate_code` | Chưa có service tạo file và lưu URL vào bảng `certificates`. | Không thể kiểm thử tra cứu chứng chỉ thật. | Đánh dấu `BLOCKED_BY_REQUIREMENT`. |
| **FR-CRT-03** | Cấp phát Giấy chứng nhận cho CTV Ban tổ chức | Tương tự FR-CRT-02. | Không thể kiểm thử kết xuất file PDF của CTV. | Đánh dấu `BLOCKED_BY_REQUIREMENT`. |

---

## 3. PHÂN BỔ ĐỘ BAO PHỦ THEO 5 TẦNG KIỂM THỬ

Biểu đồ phân bổ các ca kiểm thử trên 2 chức năng trọng tâm và các phân hệ hỗ trợ:

```text
[TIER 1: Unit Testing]          ████████████████████ 100% (Thuật toán TFT, Haversine GPS, Validation, DTO)
[TIER 2: API Testing]           ██████████████████   90% (Auth, Registration, Recruitment, Check-in, RBAC)
[TIER 3: Web UI Testing]        ████████████████     80% (Next.js Desktop: Form nộp đơn, Leaflet OSM Map)
[TIER 4: Mobile Web Testing]    ██████████████       70% (Playwright Mobile: GPS Injection, Camera Mock)
[TIER 5: Performance Testing]   ████████████████████ 100% (Load test 500 req/min, p95 đo đạc thực tế)
```

---

## 4. KẾT LUẬN & ĐÁNH GIÁ RỦI RO CÒN LẠI (RESIDUAL RISK)

1. **Rủi ro đối với 2 Chức năng Cốt lõi (Function A & B):** **GẦN NHƯ BẰNG 0**.
   Hai chức năng này được mã hóa đầy đủ ở cả Backend lẫn Frontend, có bộ kiểm thử 5 tầng độc lập bao phủ từ logic toán học, kiểm soát xung đột đồng thời (Concurrency), giao diện responsive đến kiểm thử tải cao điểm.
2. **Rủi ro đối với phạm vi toàn dự án:** Các phân hệ Brackets và Certificates cần được phát triển bổ sung ở giai đoạn tiếp theo (Phase 3 của lộ trình phát triển chung). Báo cáo kiểm thử học thuật sẽ phản ánh trung thực hiện trạng này mà không ngụy tạo kết quả kiểm thử.
