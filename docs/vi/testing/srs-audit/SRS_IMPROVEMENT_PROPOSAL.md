# ĐỀ XUẤT CẢI TIẾN ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS IMPROVEMENT PROPOSAL)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Tài liệu đề xuất cải tiến:** SRS 1.1 (29/09/2026) -> SRS 1.2 Draft  
**Tác giả:** QA Testing Architect & Senior Systems Analyst (Solo Developer)  
**Ngày phát hành:** 15/10/2026  

---

## 1. MỤC TIÊU VÀ NGUYÊN TẮC CẢI TIẾN

Đề xuất này nhằm hoàn thiện hóa tài liệu SRS 1.1 để đạt tiêu chuẩn cao nhất về tính kiểm thử được, tính toàn vẹn dữ liệu và tính khả thi trong môi trường một lập trình viên duy nhất (Solo Developer).

**Nguyên tắc cốt lõi:**
1. **Không thay đổi tùy tiện yêu cầu nghiệp vụ gốc:** Giữ nguyên các định hướng cốt lõi của Ban Chủ nhiệm CLB (Zero CCCD, OSM Leaflet, QR động 30s, Thuật toán TFT 7-8 người).
2. **Loại bỏ triệt để các khoảng trống gây lỗi dữ liệu (Data Integrity Gaps):** Bổ sung ràng buộc cho các tình huống đồng thời (Concurrency) và điều kiện biên.
3. **Mã hóa các quy tắc thành các tiêu chí có thể kiểm thử tự động (Automated Verification Criteria):** Chuyển các mô tả định tính thành tiêu chí nghiệm thu định lượng (Acceptance Criteria dạng EARS và Gherkin).

---

## 2. NỘI DUNG CHI TIẾT CÁC ĐỀ XUẤT CẢI TIẾN

### Đề xuất 1: Bổ sung Quy tắc Khóa Cấu hình Giải đấu (BR-TRN-LOCK)
- **Mã yêu cầu điều chỉnh:** `FR-TRN-02`
- **Nội dung bổ sung vào SRS:**
  > Khi giải đấu chuyển từ trạng thái `draft` sang `open_registration`, hệ thống bắt buộc kích hoạt cơ chế Khóa cấu hình (Configuration Lock).
  > - Các thuộc tính bị khóa bất biến: `game_category`, `min_team_size`, `max_team_size`, `form_schema`.
  > - API chỉnh sửa giải đấu (`PUT /api/tournaments/:id`) phải trả về lỗi `400 Bad Request` kèm thông điệp `"TOURNAMENT_LOCKED_CANNOT_MODIFY_STRUCTURE"` nếu cố tình thay đổi các trường trên khi giải đấu đã mở hoặc đã có ít nhất 1 đơn đăng ký.
- **Tiêu chí nghiệm thu bổ sung (AC):**
  - Gửi request sửa `max_team_size` từ 5 thành 3 khi giải đấu đang `open_registration` -> Nhận phản hồi HTTP `400`.
  - Toàn bộ giá trị trong CSDL được bảo toàn.

---

### Đề xuất 2: Bổ sung Cơ chế Kiểm soát Đồng thời khi Tuyển quân (BR-TEAM-CONCURRENCY)
- **Mã yêu cầu điều chỉnh:** `FR-TEAM-03`
- **Nội dung bổ sung vào SRS:**
  > Thao tác Chấp nhận Yêu cầu Gia nhập đội (`POST /api/team-requests/:id/accept`) bắt buộc phải thực thi trong một giao dịch CSDL với cơ chế Khóa hàng (Row-level Lock):
  > 1. Hệ thống thực hiện: `SELECT id FROM participants WHERE id = $1 FOR UPDATE`.
  > 2. Kiểm tra xem thí sinh đã thuộc bất kỳ đội nào khác trong cùng giải đấu hay chưa.
  > 3. Kiểm tra sĩ số hiện tại của đội: nếu số thành viên đã đạt `max_team_size`, từ chối thao tác và trả về lỗi `409 Conflict`.
  > 4. Chèn bản ghi vào `registration_members`.
  > 5. Nếu sĩ số sau khi chèn bằng `max_team_size`, tự động cập nhật `registrations.is_recruiting = false` và tự động chuyển toàn bộ các yêu cầu xin gia nhập còn lại của đội sang `rejected`.
- **Kịch bản Gherkin bổ sung:**
  ```gherkin
  Scenario: Ngăn chặn thí sinh gia nhập 2 đội khi 2 đội trưởng cùng duyệt đồng thời
    Given Thí sinh "Trần Văn C" gửi yêu cầu gia nhập tới Đội 1 và Đội 2 trong Giải đấu X
    When Đội trưởng Đội 1 và Đội trưởng Đội 2 cùng lúc nhấn "Chấp nhận" tại thời điểm t0
    Then Chỉ có duy nhất 1 yêu cầu thành công với mã phản hồi HTTP 200
    And Yêu cầu còn lại phải nhận mã phản hồi HTTP 409 với lỗi "PARTICIPANT_ALREADY_IN_ANOTHER_TEAM"
    And Thí sinh "Trần Văn C" chỉ xuất hiện trong duy nhất 1 đội trên bảng registration_members
  ```

---

### Đề xuất 3: Chuẩn hóa Thuật toán Gợi ý Bù trừ Thí sinh trong Chia phòng TFT
- **Mã yêu cầu điều chỉnh:** `FR-TRN-04`
- **Nội dung bổ sung vào SRS:**
  > Thuật toán chia phòng TFT khi nhận số lượng thí sinh $N$ không thỏa mãn $\lceil N/8 \rceil \le \lfloor N/7 \rfloor$ (thuộc tập không khả thi $\{1..6, 9..13, 17..20, 25..27, 33..34, 41\}$):
  > Hệ thống không chỉ từ chối mà bắt buộc phải trả về payload JSON có cấu trúc gợi ý:
  > ```json
  > {
  >   "valid": false,
  >   "current_participants": 25,
  >   "reason": "Không thể chia thành các phòng 7 hoặc 8 người",
  >   "suggestion": {
  >     "add_needed": 3,
  >     "target_add": 28,
  >     "rooms_if_added": 4,
  >     "remove_needed": 1,
  >     "target_remove": 24,
  >     "rooms_if_removed": 3
  >   }
  > }
  > ```

---

### Đề xuất 4: Đặc tả Trận đấu Phụ Reset Nhánh Chung kết Double Elimination
- **Mã yêu cầu điều chỉnh:** `FR-TRN-03`
- **Nội dung bổ sung vào SRS:**
  > Trong sơ đồ thi đấu Double Elimination:
  > - Trận Chung kết Tổng (Grand Final) gồm 2 cặp đấu tiềm năng:
  >   - `Match GF-1`: Đội Nhánh Thắng (WB Winner) đấu với Đội Nhánh Thua (LB Winner).
  >   - `Match GF-Reset`: Trận đấu phụ có điều kiện (`is_bracket_reset = true`).
  > - Logic kích hoạt:
  >   - Nếu WB Winner thắng Match GF-1: WB Winner chính thức vô địch giải đấu. Match GF-Reset được đánh dấu `status = 'cancelled'` (Không cần thi đấu).
  >   - Nếu LB Winner thắng Match GF-1: Cả hai đội lúc này đều có 1 trận thua. Hệ thống tự động chuyển Match GF-Reset sang trạng thái `scheduled` để hai đội thi đấu trận quyết định.

---

### Đề xuất 5: Quy định Giới hạn Bán kính Geofencing & Tối ưu Điểm danh
- **Mã yêu cầu điều chỉnh:** `FR-CHK-02`
- **Nội dung bổ sung vào SRS:**
  > - Giới hạn cấu hình bán kính tâm sàn đấu: $30m \le geofence\_radius\_meters \le 500m$. Giá trị mặc định là $100m$.
  > - Giới hạn sai số cảm biến GPS: $gps\_accuracy \le 100m$. Mọi tọa độ có sai số $> 100m$ bị hệ thống coi là không tin cậy và tự động dẫn hướng sang màn hình Nộp ảnh minh chứng (`FR-CHK-04`).
  > - Kiểm soát Replay Attack: Một mã QR động có hạn 30 giây được phép cho nhiều thí sinh tại sàn đấu quét cùng lúc, nhưng mỗi thí sinh chỉ được hệ thống ghi nhận thành công 01 lần duy nhất trên bảng `check_ins` (`UNIQUE(tournament_id, participant_id)`).

---

## 3. LỘ TRÌNH ÁP DỤNG VÀO BẢN THẢO SRS_REVISED_DRAFT.MD

Toàn bộ 5 đề xuất trên sẽ được tích hợp trực tiếp vào tệp **`docs/testing/srs-audit/SRS_REVISED_DRAFT.md`**, đồng thời đóng vai trò làm Tiêu chuẩn Đánh giá (Evaluation Baseline) cho toàn bộ các kịch bản kiểm thử tự động tại Phase 4 và Phase 6.
