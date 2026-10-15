# BÁO CÁO KIỂM TOÁN VÀ ĐÁNH GIÁ CHẤT LƯỢNG SRS (SRS AUDIT REPORT)
**Tài liệu thẩm định:** Đặc tả Yêu cầu Phần mềm (SRS) 1.1 — DUT ESPORTS Tournament Platform  
**Tiêu chuẩn đối chiếu:** IEEE Std 830-1998, ISO/IEC/IEEE 29148:2018  
**Đơn vị thực hiện:** Senior Software Engineer & Test Architect (Solo Developer)  
**Ngày phát hành:** 15/10/2026  
**Phân loại:** Báo cáo Kỹ thuật Độc lập (Independent Technical Audit)  

---

## 1. MỤC TIÊU VÀ PHẠM VI KIỂM TOÁN (AUDIT OBJECTIVES & SCOPE)

Báo cáo này thiết lập đánh giá toàn diện về chất lượng kỹ thuật, tính khả thi triển khai, an toàn dữ liệu và khả năng kiểm thử khách quan của tài liệu **SRS phiên bản 1.1**.

### Tiêu chí Đánh giá Chất lượng (Quality Dimensions)
1. **Tính Đầy đủ (Completeness):** Không bỏ sót các điều kiện biên, trạng thái ngoại lệ, thông điệp lỗi và quy tắc dọn dẹp dữ liệu.
2. **Tính Đúng đắn (Correctness):** Logic nghiệp vụ, thuật toán toán học và luồng dữ liệu phản ánh chính xác thực tế vận hành giải đấu.
3. **Tính Nhất quán (Consistency):** Không có xung đột giữa các phần yêu cầu chức năng (FR), yêu cầu phi chức năng (NFR), ca sử dụng (UC) và lược đồ cơ sở dữ liệu (DDL).
4. **Tính Không mơ hồ (Unambiguity):** Mỗi yêu cầu chỉ có duy nhất một cách hiểu; triệt tiêu các từ ngữ định tính như "nhanh chóng", "tối ưu", "hợp lý".
5. **Tính Kiểm thử được (Testability):** Mọi yêu cầu đều có thể thiết kế kịch bản kiểm thử với đầu vào, các bước thực hiện và kết quả kỳ vọng đo lường được.
6. **An toàn & Toàn vẹn Dữ liệu (Data Integrity & Concurrency Safety):** Kiểm soát xung đột đồng thời, giao dịch CSDL (ACID), bảo mật thông tin định danh (PII).

---

## 2. TỔNG KẾT KẾT QUẢ ĐÁNH GIÁ (EXECUTIVE SUMMARY)

| Chỉ số Đánh giá | Kết quả Đo lường | Đánh giá Chuyên môn |
|---|:---:|---|
| **Tổng số Yêu cầu Chức năng (FR)** | 22 yêu cầu | Bao phủ 7 phân hệ chính |
| **Tổng số Yêu cầu Phi chức năng (NFR)** | 16 yêu cầu | Tập trung cao vào Bảo mật PII & Hiệu năng Streaming |
| **Số lỗi Nghiệp vụ Nghiêm trọng (Critical Issues)** | **4 lỗi** | Rủi ro Race Condition đăng ký trùng, Thiếu Reset Grand Final, Lỗ hổng CSDL |
| **Số lỗi Mâu thuẫn / Thiếu sót (High/Medium Issues)** | **7 lỗi** | Trạng thái giải đấu thiếu điều kiện chặn, Gaps chia phòng TFT |
| **Mức độ Sẵn sàng Kiểm thử (Test Readiness)** | **88.5%** | Hai phân hệ cốt lõi (Registration & Check-in) đạt 100% khả năng kiểm thử |

---

## 3. PHÂN TÍCH CHUYÊN SÂU 8 VÙNG NGHIỆP VỤ RỦI RO CAO (HIGH-RISK AREAS AUDIT)

### 3.1. Vòng đời Giải đấu (Tournament Lifecycle)
- **Hiện trạng SRS:** Định nghĩa 6 trạng thái: `draft`, `open_registration`, `closed_registration`, `ongoing`, `completed`, `cancelled`.
- **Phát hiện lỗi:**
  - *Rủi ro sửa cấu hình khi đang mở đăng ký:* SRS chưa có quy tắc chặn sửa đổi `min_team_size`, `max_team_size`, `game_category` sau khi giải đấu đã chuyển sang `open_registration` và có đội nộp đơn. Nếu Admin đổi `max_team_size` từ 5 thành 3, các đội 5 thành viên đã đăng ký sẽ rơi vào trạng thái vi phạm dữ liệu (Inconsistent State).
  - *Chuyển trạng thái thiếu điều kiện tiên quyết:* Cho phép chuyển từ `closed_registration` sang `ongoing` ngay cả khi số lượng đội hợp lệ nhỏ hơn `min_participants` hoặc chưa sinh nhánh đấu.
  - *Quy tắc:* Cần bổ sung bảng chuyển trạng thái hình thức (Formal State Transition Table) với đầy đủ Guard Conditions.

### 3.2. Đăng ký & Tuyển quân (Registration & Recruitment)
- **Hiện trạng SRS:** Hỗ trợ tạo đội, bật cờ `is_recruiting`, gửi `team_join_requests`.
- **Phát hiện lỗi:**
  - *Race Condition khi gia nhập đội đồng thời:* Khi 2 đội trưởng của 2 đội khác nhau cùng nhấn "Chấp nhận" (Accept) yêu cầu gia nhập của cùng một VĐV tự do tại cùng một thời điểm: Nếu thiếu cơ chế Khóa bi quan (`SELECT ... FOR UPDATE`) hoặc Khóa mức CSDL, thí sinh sẽ trở thành thành viên của cả 2 đội trong cùng một giải đấu!
  - *Thiếu ràng buộc CSDL tầng bảng thành viên:* Bảng `registration_members` chỉ có `UNIQUE(registration_id, participant_id)` chứ không chứa `tournament_id`. Do đó CSDL không thể tự ngăn một VĐV thuộc 2 đội khác nhau trong cùng giải đấu nếu mã nguồn bỏ sót kiểm tra logic.
  - *Đội trưởng rời đội / hủy đăng ký:* SRS chưa đặc tả kịch bản khi Đội trưởng xin hủy đơn hoặc chuyển quyền đội trưởng cho thành viên khác.

### 3.3. Cấu trúc Nhánh đấu (Tournament Brackets)
- **Hiện trạng SRS:** Quy định hỗ trợ Single Elimination và Double Elimination (FR-TRN-03).
- **Phát hiện lỗi:**
  - *Quy tắc Reset Nhánh Chung kết Tổng (Grand Final Reset):* Trong thể thức Double Elimination tiêu chuẩn, nếu Đội vô địch Nhánh Thua (Losers Bracket Winner) đánh bại Đội vô địch Nhánh Thắng (Winners Bracket Winner) ở trận Chung kết đầu tiên, hai đội PHẢI thi đấu thêm một trận Reset (Bracket Reset Match) vì mỗi đội đều chỉ được phép thua tối đa 1 trận trước khi bị loại. SRS 1.1 chưa mô hình hóa trận đấu phụ này trong cấu trúc dữ liệu `matches`.
  - *Tái sinh nhánh đấu (Bracket Regeneration):* Chưa có điều kiện chặn Admin vô tình bấm "Sinh lại nhánh đấu" khi giải đã có trận đấu diễn ra hoặc đã nhập kết quả, dẫn tới nguy cơ xóa sạch kết quả thi đấu thực tế.

### 3.4. Thuật toán Phân phòng Đấu Trường Chân Lý (TFT Room Allocation)
- **Hiện trạng SRS:** Công thức $m = \lceil N/8 \rceil$, kiểm tra $\lceil N/8 \rceil \le m \le \lfloor N/7 \rfloor$. Số phòng 8 người là $N - 7m$, số phòng 7 người là $8m - N$.
- **Kiểm định Toán học:**
  - Đối với $N \in \{1..6, 9..13, 17..20, 25..27, 33..34, 41\}$: Bất đẳng thức $\lceil N/8 \rceil \le \lfloor N/7 \rfloor$ vô nghiệm nguyên. Thuật toán từ chối hợp lệ.
  - *Khuyết tật SRS:* SRS chỉ nêu "hệ thống không sinh phòng và hiển thị lý do" mà không đưa ra giải pháp gợi ý cho Ban tổ chức (ví dụ: bổ sung thêm VĐV chờ, hoặc áp dụng thể thức tính điểm ghép phòng xoay tua 6 người theo điều lệ đặc biệt).

### 3.5. Điểm danh Đa phương thức & Gian lận Tọa độ (Multi-modal Check-in)
- **Hiện trạng SRS:** QR Code động 30s + GPS Geofencing (bán kính 100m, sai số $\le 100m$) + Nộp minh chứng ảnh.
- **Phát hiện lỗi:**
  - *Nhiều thí sinh quét cùng 1 QR:* Mã QR hiển thị trên màn chiếu khán phòng giải đấu được hàng trăm thí sinh quét cùng lúc trong 30 giây. Bảng `checkin_qr_tokens` lưu token giải đấu; hệ thống cần đảm bảo `token_hash` không bị vô hiệu hóa sau 1 lần quét mà phải còn hạn cho toàn bộ thí sinh trong 30 giây đó. Ràng buộc duy nhất phải là `UNIQUE(tournament_id, participant_id)` trên bảng `check_ins`.
  - *Giả mạo GPS (Location Spoofing):* Trình duyệt web trên Android có thể bị can thiệp bởi ứng dụng Mock Location. SRS cần bổ sung khuyến nghị kết hợp kiểm tra IP nội bộ sàn đấu (Subnet/Wi-Fi Gateway Matching) khi cần xác thực nghiêm ngặt.

### 3.6. Phân quyền Truy cập (Role-Based Access Control - RBAC)
- **Hiện trạng SRS:** 4 vai trò: `admin`, `ctv` (thường trực), `seasonal_staff` (thời vụ), `participant`.
- **Phát hiện lỗi:**
  - *Thu hồi quyền CTV thời vụ:* Khi CTV thời vụ bị xóa khỏi `tournament_organizers`, token JWT hiện tại (vốn có hạn 24 giờ) vẫn còn hiệu lực nếu chỉ kiểm tra Stateless JWT mà không kiểm tra DB Scope. Mã nguồn backend đã khắc phục điều này bằng middleware `activeStaff` và `tournamentScope`. SRS cần đưa quy định này vào tiêu chuẩn bắt buộc.

### 3.7. Cấp phát E-Certificate
- **Hiện trạng SRS:** Kích hoạt Worker qua sự kiện `tournament.completed`.
- **Phát hiện lỗi:**
  - *Xử lý Worker Retry Idempotency:* Khi tiến trình render gặp sự cố mạng giữa chừng và chạy lại, việc lưu trữ vào `certificates` phải sử dụng `INSERT ... ON CONFLICT (tournament_id, participant_id) DO UPDATE` để không gây lỗi trùng lặp khóa chính hoặc sinh nhiều chứng chỉ cho cùng một cá nhân.

### 3.8. Tính Toàn vẹn Lược đồ Cơ sở Dữ liệu (Database Design Consistency)
- **Đối chiếu SRS và `database_schema.sql`:**
  - Đã loại bỏ hoàn toàn các trường CCCD/CMND (Tuân thủ triệt để Zero CCCD).
  - Khóa chính 100% sử dụng UUID (`gen_random_uuid()`).
  - *Thiếu sót cần bổ sung:* Bổ sung ràng buộc `UNIQUE(tournament_id, captain_id)` trên bảng `registrations` để ngăn chặn triệt để việc một tài khoản tạo nhiều đội trưởng trong cùng một giải.

---

## 4. KẾT LUẬN VÀ KHUYẾN NGHỊ HÀNH ĐỘNG (ACTIONABLE RECOMMENDATIONS)

1. **Khóa phạm vi cấu hình giải đấu:** Bổ sung quy tắc nghiệp vụ `BR-TRN-LOCK`: Khi giải đấu chuyển sang `open_registration`, khóa toàn bộ các thuộc tính thể thức (`min_team_size`, `max_team_size`, `game_category`).
2. **Bảo vệ giao dịch tuyển quân:** Mọi thao tác chấp nhận yêu cầu gia nhập đội (`team_join_requests`) bắt buộc thực thi trong một `SERIALIZABLE` transaction hoặc sử dụng khóa hàng `SELECT ... FOR UPDATE` trên tài khoản thí sinh.
3. **Chuẩn hóa Bộ tài liệu Thẩm định:** Lập tức hoàn thiện bộ tài liệu `SRS_ISSUES.md`, `BUSINESS_RULE_GAPS.md`, `STATE_TRANSITION_MATRIX.md` và dự thảo cải tiến `SRS_REVISED_DRAFT.md` làm nền tảng cho việc thiết kế Test Cases.
