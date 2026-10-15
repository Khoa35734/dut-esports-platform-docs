# QUY CHUẨN DỮ LIỆU KIỂM THỬ NHÂN TẠO (TEST DATA SPECIFICATION)
**Dự án:** Nền tảng Quản lý Giải đấu Thể thao Điện tử DUT ESPORTS  
**Quy tắc:** Sử dụng 100% dữ liệu nhân tạo (Synthetic Data), Không sử dụng PII hoặc ảnh thẻ thật của sinh viên  
**Người lập:** QA Data Engineer & Test Specialist  
**Ngày cập nhật:** 15/10/2026  

---

## 1. NGUYÊN TẮC BẢO MẬT VÀ TẠO DỮ LIỆU NHÂN TẠO

1. **Tuyệt đối Không sử dụng Dữ liệu Thật:** Không truy cập, sao chép hoặc kiểm thử trên ảnh thẻ sinh viên thật, số điện thoại hoặc email cá nhân có thật của sinh viên Đại học Bách khoa Đà Nẵng.
2. **Tính Tái tạo và Cô lập (Deterministic & Isolated):** Mọi bộ dữ liệu kiểm thử đều có thể khởi tạo lại từ đầu thông qua các script seed; sử dụng tiền tố chuẩn `test_` hoặc domain giả định `example.dut.udn.vn`.
3. **Quy trình Thu dọn Tự động (Teardown & Cleanup):** Toàn bộ dữ liệu sinh ra trong quá trình chạy kiểm thử phải được xóa sạch hoặc dọn dẹp sau khi bài test hoàn tất để không làm ô nhiễm cơ sở dữ liệu Supabase.

---

## 2. BẢNG QUY CHUẨN TÀI KHOẢN NGƯỜI DÙNG NHÂN TẠO (SYNTHETIC USER ACCOUNTS)

| Định danh Người dùng (User Key) | Vai trò (Role) | Email Nhân tạo | Mật khẩu Chuẩn | Trạng thái KYC | Mục đích Kiểm thử |
|---|---|---|---|:---:|---|
| `user_admin_test` | `admin` | `admin.qa@dutesports.local` | `AdminPass@2026!` | N/A | Kiểm thử toàn quyền hệ thống, phê duyệt cấu hình và audit log. |
| `user_ctv_perm_test` | `ctv` | `ctv.core@dutesports.local` | `CTVCore@2026!` | N/A | Kiểm thử duyệt hồ sơ KYC toàn hệ thống, tạo giải và mở đăng ký. |
| `user_ctv_seasonal_test` | `seasonal_staff` | `ctv.seasonal@dutesports.local` | `CTVSeason@2026!` | N/A | Kiểm thử điểm danh bàn, đối soát bản đồ Leaflet OSM theo giải phân công. |
| `user_dut_captain_test` | `participant` | `captain.dut@sv.dut.udn.vn` | `StudentPass@2026!` | `approved` | Kiểm thử tạo đội, nộp biểu mẫu JSONB, bật tuyển quân và duyệt thành viên. |
| `user_dut_member_test` | `participant` | `member.dut@sv.dut.udn.vn` | `StudentPass@2026!` | `approved` | Kiểm thử gửi yêu cầu gia nhập đội tuyển quân và quét mã QR điểm danh. |
| `user_ext_student_test` | `participant` | `student.ext@ute.udn.vn` | `StudentPass@2026!` | `approved` | Kiểm thử thí sinh trường ngoài (`account_type = 'external'`). |
| `user_unverified_test` | `participant` | `unverified@sv.dut.udn.vn` | `StudentPass@2026!` | `pending` | Kiểm thử kịch bản chặn tài khoản chưa duyệt KYC tham gia giải đấu. |

---

## 3. QUY CHUẨN TỌA ĐỘ VÀ VÙNG GEOFENCING SÀN ĐẤU

Tọa độ sàn đấu giả lập: **Hội trường F — Trường Đại học Bách khoa (ĐH Đà Nẵng)**  
- **Tâm sàn đấu (Center):** Vĩ độ `16.074800° N`, Kinh độ `108.149900° E`
- **Bán kính Geofence cấu hình:** `100 mét`

### Bộ Tọa độ Kiểm thử Phân vùng & Giá trị Biên (Test Coordinate Matrix)

| Mã Điểm (Point ID) | Vĩ độ (Latitude) | Kinh độ (Longitude) | Khoảng cách đến Tâm (Distance) | Sai số GPS (Accuracy) | Kết quả Kỳ vọng (Expected Verdict) |
|---|---|---|:---:|:---:|:---:|
| `COORD_CENTER` | `16.074800` | `108.149900` | $0.0\text{ m}$ | $\pm 5\text{ m}$ | **HỢP LỆ (APPROVED)** — Tâm sàn đấu |
| `COORD_NEAR_25M` | `16.075000` | `108.150000` | $\approx 24.5\text{ m}$ | $\pm 10\text{ m}$ | **HỢP LỆ (APPROVED)** — Giữa khán phòng |
| `COORD_BOUND_95M` | `16.075600` | `108.149900` | $\approx 88.9\text{ m}$ | $\pm 15\text{ m}$ | **HỢP LỆ (APPROVED)** — Cửa ra vào Hội trường F |
| `COORD_BOUND_101M`| `16.075750` | `108.149900` | $\approx 105.6\text{ m}$ | $\pm 15\text{ m}$ | **TỪ CHỐI (OUTSIDE GEOFENCE)** — Ngoài cửa |
| `COORD_FAR_250M` | `16.077000` | `108.150500` | $\approx 252.0\text{ m}$ | $\pm 20\text{ m}$ | **TỪ CHỐI (OUTSIDE GEOFENCE)** — Khu Giảng đường A |
| `COORD_HOME_1000M`| `16.084000` | `108.155000` | $\approx 1,150.0\text{ m}$ | $\pm 15\text{ m}$ | **TỪ CHỐI (OUTSIDE GEOFENCE)** — Ở nhà / Quán Net |
| `COORD_BAD_ACC` | `16.074900` | `108.149950` | $\approx 12.0\text{ m}$ | $\pm 150\text{ m}$ | **TỪ CHỐI (ACCURACY TOO LOW)** — Sai số GPS $> 100m$ |

---

## 4. QUY CHUẨN TỆP ẢNH MINH CHỨNG & CHỮ KÝ NHỊ PHÂN (MAGIC BYTES FIXTURES)

Toàn bộ các tệp ảnh kiểm thử được tạo tự động qua script (Synthetic Buffer Generation) với đúng Magic Bytes:

| Loại Tệp (Fixture Name) | Định dạng (Format) | Header Magic Bytes | Dung lượng | Hành vi Kỳ vọng |
|---|---|---|:---:|---|
| `valid_student_card.jpg` | JPEG | `FF D8 FF E0` | 240 KB | **HỢP LỆ** — Vượt qua kiểm tra định dạng |
| `valid_portrait.png` | PNG | `89 50 4E 47 0D 0A 1A 0A` | 450 KB | **HỢP LỆ** — Vượt qua kiểm tra định dạng |
| `valid_proof.webp` | WebP | `52 49 46 46 ... 57 45 42 50` | 180 KB | **HỢP LỆ** — Điểm danh nộp ảnh |
| `spoofed_script.jpg` | Text / Script | `3C 3F 70 68 70` (`<?php`) | 2 KB | **TỪ CHỐI (400 Bad File Signature)** |
| `oversized_photo.jpg` | JPEG | `FF D8 FF E0` | 6.2 MB | **TỪ CHỐI (413 Payload Too Large - Vượt 5MB)** |

---

## 5. BỘ DỮ LIỆU ĐĂNG KÝ VÀ FORM SCHEMA JSONB GIẢ LẬP

```json
{
  "tournament_code": "DUT-ARENA-TEST-2026",
  "game_category": "Liên Quân Mobile",
  "min_team_size": 5,
  "max_team_size": 7,
  "form_schema": [
    {
      "name": "open_id",
      "label": "OpenID / Tên kiện tướng",
      "type": "text",
      "required": true
    },
    {
      "name": "rank_tier",
      "label": "Bậc xếp hạng hiện tại",
      "type": "select",
      "options": ["Kim Cương", "Tinh Anh", "Cao Thủ", "Thách Đấu"],
      "required": true
    }
  ]
}
```
