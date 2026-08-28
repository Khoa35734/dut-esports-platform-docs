# SOFTWARE REQUIREMENTS SPECIFICATION (SRS)
# Website Quản lý Giải đấu CLB DUT ESPORTS

**Phiên bản:** 1.3  
**Ngày cập nhật:** 29/08/2026  
**Trạng thái:** Approved Specification  

---

## 1. Giới thiệu

### 1.1 Mục đích tài liệu
Tài liệu này mô tả chi tiết các yêu cầu chức năng và phi chức năng của hệ thống website quản lý giải đấu thể thao điện tử (esports) cho CLB DUT ESPORTS. Hệ thống phục vụ việc đăng ký thành viên (xác thực sinh viên), tuyển thành viên lập đội, tổ chức giải đấu, đồng tổ chức (CTV), tạo và vận hành nhánh đấu đa thể thức (bracket/matches: Single/Double Elimination, Group Stage, TFT lobbies), quản lý kết quả thi đấu, **hệ thống Check-in ngày thi đấu (QR code + GPS/Minh chứng)**, **mô-đun AI OCR Check-in thông minh cho game Liên Quân Mobile (nhận diện chữ màu xanh lá từ web congdong.lienquan.garena.vn / sảnh phòng lobby)**, **công cụ Xuất danh sách thành viên tham gia (Excel/CSV/PDF)** và **tự động xuất Giấy chứng nhận điện tử (E-Certificate)**.

### 1.2 Phạm vi hệ thống
Hệ thống là một nền tảng web toàn diện cho phép:
- **Sinh viên (Participant)**: Đăng ký tài khoản (xác minh qua ảnh thẻ SV và ảnh selfie cầm thẻ SV), tìm đội/tuyển quân, đăng ký tham gia giải đấu (cá nhân hoặc đội), tra cứu nhánh đấu, lịch thi đấu, Ingame ID của đối thủ trong bảng, **thực hiện Check-in ngày thi đấu (quét QR code kèm định vị GPS hoặc nộp ảnh minh chứng)**, xuất danh sách thành viên đội của mình, và **tải Giấy chứng nhận điện tử tự động khi hoàn thành giải đấu**.
- **CTV (Cộng tác viên / Đồng tổ chức)**: Tạo giải đấu (chờ duyệt), được Admin phân quyền đồng tổ chức giải, quản lý danh sách đăng ký, tạo/điều hành nhánh đấu, nhập tỉ số, giám sát và duyệt check-in của thí sinh, **sử dụng AI OCR tự động đề xuất check-in Liên Quân Mobile qua ảnh chụp màn hình web congdong.lienquan.garena.vn**, và **xuất danh sách VĐV/bảng điểm danh phục vụ điều phối giải**.
- **Admin**: Quản trị toàn diện: Người dùng (Users), Sinh viên (Participants), Giải đấu (Tournaments), phân công CTV đồng tổ chức, cấu hình hệ thống, quản lý check-in (xem bản đồ vị trí, duyệt minh chứng, ghi đè check-in thủ công, quản lý công cụ AI OCR Check-in), **xuất báo cáo và danh sách VĐV toàn hệ thống**, quản lý mẫu phôi và tự động phát hành Giấy chứng nhận.

### 1.3 Định nghĩa, từ viết tắt
| Từ viết tắt | Ý nghĩa |
|---|---|
| SRS | Software Requirements Specification |
| CTV | Cộng tác viên (Co-organizer / Referee) |
| BO | Best Of (VD: BO1, BO3, BO5, BO7) |
| TFT | Teamfight Tactics – Đấu Trường Chân Lý (thể thức 8 người/phòng) |
| LOL | League of Legends (Liên Minh Huyền Thoại) |
| AOV / LQ | Arena of Valor – Liên Quân Mobile |
| Bracket | Nhánh đấu / Sơ đồ thi đấu |
| Ingame ID / IGN | Tên nhân vật hoặc ID tài khoản trong game (Riot ID, Tên kiện tướng, v.v.) |
| KYC | Know Your Customer – Quy trình xác thực danh tính sinh viên |
| E-Certificate | Giấy chứng nhận điện tử có mã định danh và QR xác thực |
| OSM | OpenStreetMap (Giải pháp bản đồ mã nguồn mở miễn phí thay thế Google Maps API) |
| EDA | Event-Driven Architecture |
| OCR | Optical Character Recognition – Công nghệ nhận dạng quang học ký tự từ hình ảnh |
| HSV Masking | Phân đoạn và lọc dải màu sắc (xanh lá cây) trong không gian màu HSV |
| Fuzzy Matching | Thuật toán so khớp chuỗi gần đúng (Levenshtein Distance) giữa text nhận dạng và CSDL |
| congdong.lienquan.garena.vn | Trang quản lý giải đấu cộng đồng chính thức của Garena Liên Quân Mobile |
| Ephemeral Storage | Lưu trữ tạm thời tự động xóa sau khi xử lý (bảo mật & tiết kiệm tài nguyên) |

---

## 2. Tổng quan hệ thống

### 2.1 Đối tượng sử dụng (Actors)

| Actor | Vai trò trong hệ thống (bảng `users`/`participants`) |
|---|---|
| **Sinh viên (Participant)** | Người chơi/thí sinh thi đấu, lưu tại bảng `participants`. Phân loại `account_type`: `'internal'` (sinh viên DUT) và `'external'` (sinh viên trường khác). Thực hiện check-in, xuất danh sách đội và nhận giấy chứng nhận. |
| **Admin** | Tài khoản quản trị cấp cao trong bảng `users` (`role = 'admin'`), toàn quyền hệ thống: quản trị check-in, AI OCR, xuất báo cáo toàn diện, cấu hình phôi và cấp phát chứng chỉ. |
| **CTV (Cộng tác viên)** | Tài khoản quản trị trong bảng `users` (`role = 'ctv'`), tạo đề xuất giải đấu và tham gia đồng tổ chức các giải đấu được phân công qua bảng `tournament_organizers` (bao gồm quản lý check-in, vận hành AI OCR và xuất danh sách VĐV). |

---

### 2.2 Kiến trúc tổng quan
Hệ thống áp dụng kiến trúc **Event-Driven Architecture (EDA)** kết hợp **Asynchronous Processing**:
- **Xử lý đăng ký sinh viên**: Upload ảnh thẻ SV & selfie $\rightarrow$ validate/nén ảnh $\rightarrow$ đẩy vào hàng đợi duyệt $\rightarrow$ gửi thông báo kết quả duyệt/từ chối.
- **Duyệt giải đấu & Đăng ký**: Thông báo real-time khi đội trưởng nhận được yêu cầu "xin vào đội" hoặc khi đơn đăng ký giải được duyệt.
- **Sinh nhánh đấu (Bracket Generation)**: Tự động hóa chia nhánh Single/Double Elimination hoặc thuật toán chia phòng TFT 8 người khi giải đóng đăng ký.
- **Check-in Ngày thi đấu (Đa phương thức)**:
  1. *QR Scan + GPS Geolocation*: Sinh viên quét QR $\rightarrow$ lấy tọa độ GPS / nộp ảnh minh chứng $\rightarrow$ Admin/CTV đối soát trên bản đồ OpenStreetMap.
  2. *AI OCR Check-in (Liên Quân Mobile)*: Trọng tài/CTV upload ảnh chụp bảng điểm danh trên web `congdong.lienquan.garena.vn` (hoặc sảnh phòng lobby) $\rightarrow$ AI Worker phân tích dải màu chữ xanh lá $\rightarrow$ Nhận diện Ingame ID $\rightarrow$ So khớp mờ (Fuzzy Matching) với danh sách đội $\rightarrow$ Trả về bảng đề xuất trực quan (cho phép chỉnh sửa) $\rightarrow$ Trọng tài xác nhận 1-click $\rightarrow$ Cập nhật check-in và **tự động xóa ảnh tạm** khỏi bộ nhớ.
- **Xuất dữ liệu & Báo cáo (Data Export Worker)**: Xử lý xuất file Excel/CSV/PDF theo cơ chế stream bất đồng bộ, hỗ trợ lọc đa tiêu chí và áp dụng Data Masking bảo vệ PII.
- **Tự động cấp E-Certificate**: Khi giải đấu chuyển sang trạng thái `completed`, background worker tự động quét các thí sinh đã check-in hợp lệ $\rightarrow$ sinh file Giấy chứng nhận (PDF/Image) theo mẫu phôi có mã xác thực $\rightarrow$ gửi thông báo tải chứng nhận.
- **Sự kiện tiêu biểu**: `participant.registered`, `participant.approved`, `registration.submitted`, `team.join_requested`, `team.join_accepted`, `tournament.organizer_assigned`, `tournament.registration_closed`, `bracket.generated`, `match.score_updated`, `checkin.qr_scanned`, `checkin.proof_submitted`, `ai_checkin.image_uploaded`, `ai_checkin.processed`, `ai_checkin.confirmed`, `ai_checkin.image_purged`, `report.export_requested`, `tournament.completed`, `certificate.issued`.

---

## 3. Yêu cầu chức năng chi tiết

### 3.1 Chức năng dành cho Sinh viên (Participant)

| Mã | Chức năng | Mô tả chi tiết |
|---|---|---|
| **SV-01** | **Đăng ký tài khoản (KYC Sinh viên)** | Nhập thông tin cá nhân (`full_name`, `email`, `phone_number`, `university_name`, `class_name`, `faculty_name`, `student_id`). **Chỉ yêu cầu upload 2 ảnh xác minh**: <br>1. Mặt trước thẻ sinh viên (`student_card_url`)<br>2. Ảnh chân dung và tay cầm thẻ sinh viên (`selfie_with_student_card_url`).<br>*(Không yêu cầu bất kỳ thông tin hay hình ảnh CCCD nào)*. Trạng thái khởi tạo `status = 'pending'`. |
| **SV-02** | **Đăng nhập** | Đăng nhập bằng `email`/`username`/`student_id` + mật khẩu. Chỉ đăng nhập và thao tác được khi `status = 'approved'`. |
| **SV-03** | **Quản lý hồ sơ cá nhân** | Xem và cập nhật thông tin liên hệ, xem trạng thái phê duyệt tài khoản. |
| **SV-04** | **Cập nhật lại thông tin khi bị từ chối** | Khi `status = 'rejected'`, sinh viên xem được `rejection_reason`, cập nhật lại ảnh/thông tin và gửi duyệt lại (`status` chuyển về `'pending'`). |
| **SV-05** | **Đăng ký tham gia giải đấu** | - **Giải cá nhân (TFT)**: Nhập bắt buộc `ingame_id` (Riot ID) và các trường động theo `form_schema`.<br>- **Giải đồng đội (Liên Quân, LOL...)**: Đội trưởng nhập `team_name`, `ingame_id` của bản thân, thêm các thành viên đã có tài khoản trên web hoặc đăng ký trước số lượng thành viên hiện có (VD: 4/7 người). |
| **SV-06** | **Tuyển quân & Xin gia nhập đội** | - **Đội trưởng**: Bật chế độ `is_recruiting = true`, nhập ghi chú tuyển quân `recruitment_notes` (ví dụ: *"Cần tuyển 1 Mid và 1 SP rank Cao Thủ"*). Duyệt (`accept`) hoặc Từ chối (`reject`) các yêu cầu xin vào đội.<br>- **Thành viên tự do**: Xem danh sách các đội đang thiếu người (VD: Đội X đang có 4/7 thành viên), bấm "Xin vào đội", điền Ingame ID và lời nhắn gửi đội trưởng. |
| **SV-07** | **Quản lý đơn đăng ký** | Xem trạng thái đơn đăng ký giải đấu (`pending`, `approved`, `rejected`), hủy đơn khi giải chưa đóng đăng ký. |
| **SV-08** | **Xem nhánh đấu & Lịch thi đấu** | Xem sơ đồ cây nhánh đấu (Bracket view), lịch thi đấu chi tiết từng vòng, kết quả trận đấu, link phòng stream. |
| **SV-09** | **Tra cứu Ingame ID của đối thủ** | Khi bảng đấu/phòng đấu được công bố, người chơi tự động xem được danh sách `ingame_id` của tất cả các đối thủ trong cùng phòng/cặp đấu để kết bạn và mời vào phòng Custom. |
| **SV-10** | **Check-in Ngày thi đấu** | Đến ngày thi đấu, thí sinh thực hiện một trong hai hình thức check-in:<br>1. **Quét mã QR của BTC**: Bật quyền truy cập vị trí (GPS Geolocation), hệ thống ghi nhận tọa độ + thiết bị và xác nhận check-in thành công.<br>2. **Nộp minh chứng (Proof Upload)**: Dành cho thí sinh gặp sự cố camera/check-in từ xa; upload ảnh chụp tại phòng máy/địa điểm thi đấu hoặc ảnh màn hình phòng custom $\rightarrow$ chờ Admin/CTV phê duyệt. |
| **SV-11** | **Xem & Tải Giấy chứng nhận (E-Certificate)** | Sau khi giải đấu kết thúc, nếu thí sinh đã check-in hợp lệ, hệ thống tự động hiển thị Giấy chứng nhận tham gia/đạt giải. Thí sinh có thể xem trực tuyến, tải file PDF/PNG chất lượng cao và chia sẻ liên kết xác thực công khai. |
| **SV-12** | **Xuất danh sách đội cá nhân** | Đội trưởng có quyền xuất file danh sách các thành viên trong đội của mình (PDF/Excel) kèm Ingame ID và vai trò để đối chiếu và nộp cho BTC khi cần thiết. |

---

### 3.2 Chức năng dành cho Admin

| Mã | Chức năng | Mô tả chi tiết |
|---|---|---|
| **AD-01** | **Quản lý Sinh viên (Participants)** | Xem danh sách, tìm kiếm, lọc theo trường/khoa, chỉnh sửa hoặc khóa tài khoản sinh viên vi phạm. |
| **AD-02** | **Duyệt đăng ký tài khoản sinh viên** | Xem hồ sơ và 2 ảnh xác thực thẻ SV. Thực hiện Duyệt (`approved`) hoặc Từ chối (`rejected` kèm lý do cụ thể). |
| **AD-03** | **Quản lý Giải đấu (Tournaments)** | Toàn quyền tạo mới, chỉnh sửa thông tin, cấu hình số lượng đội (`min_team_size`, `max_team_size`, `max_participants`), thời gian mở/đóng đăng ký, tùy biến `form_schema`. |
| **AD-04** | **Phê duyệt giải đấu do CTV tạo** | Xem xét và Duyệt (`approved`) hoặc Từ chối (`rejected`) giải đấu do CTV đề xuất. |
| **AD-05** | **Phân quyền Đồng tổ chức (Co-organizers)** | Gán/thêm một hoặc nhiều CTV vào giải đấu thông qua bảng `tournament_organizers` (vai trò: `lead_organizer`, `co_organizer`, `referee`). |
| **AD-06** | **Quản lý CTV (Users)** | Tạo mới, cấp tài khoản, phân quyền `role = 'ctv'`, khóa/mở khóa tài khoản CTV. |
| **AD-07** | **Tạo và điều hành Nhánh đấu** | Tạo bracket đa thể thức, chạy thuật toán xếp cặp tự động hoặc xếp thủ công, cập nhật tỉ số, xử lý khiếu nại. |
| **AD-08** | **Báo cáo & Thống kê** | Thống kê số lượng giải đấu, số lượng VĐV tham gia, tỉ lệ hoàn thành trận đấu, tỉ lệ check-in qua QR/Minh chứng/AI OCR. |
| **AD-09** | **Quản lý Check-in & Bản đồ Vị trí** | - Xem danh sách thí sinh đã/chưa check-in theo thời gian thực.<br>- Xem thông tin tọa độ GPS, địa chỉ IP, User-Agent/Device info của thí sinh.<br>- **Xem trực quan trên Bản đồ**: Tích hợp OpenStreetMap / Leaflet (miễn phí) hoặc điều hướng xem trên Google Maps (không mất phí API $200/tháng). |
| **AD-10** | **Duyệt Minh chứng & Xác nhận tham gia thủ công** | - Duyệt (`approved`) hoặc từ chối (`rejected`) các đơn nộp ảnh minh chứng check-in.<br>- **Ghi đè thủ công (Manual Check-in Override)**: Admin có quyền xác nhận tham gia trực tiếp cho bất kỳ thí sinh/đội nào ngay trên hệ thống. |
| **AD-11** | **Cấu hình & Tự động phát hành Giấy chứng nhận** | - Cấu hình mẫu phôi Giấy chứng nhận (tiêu đề, chữ ký, logo CLB, layout).<br>- Tự động kích hoạt cấp phát E-Certificate cho tất cả thí sinh đã check-in khi giải hoàn thành.<br>- Hỗ trợ cấp phát bổ sung, chỉnh sửa danh hiệu hoặc thu hồi (Revoke) giấy chứng nhận khi phát hiện gian lận. |
| **AD-12** | **Xuất danh sách VĐV & Báo cáo giải đấu toàn diện** | - Xuất file Excel (`.xlsx`), CSV hoặc PDF in danh sách VĐV.<br>- **Đa dạng bộ lọc**: Toàn giải, theo từng Bảng đấu / Nhánh đấu / Phòng đấu, theo Trạng thái Check-in (Đã check-in QR, Minh chứng, AI OCR, Chưa check-in), phân loại sinh viên (`internal`/`external`).<br>- Đầy đủ thông tin: Họ tên, MSSV, Trường/Khoa, SĐT, Email, Tên đội, Ingame ID, Thời gian điểm danh, Tọa độ GPS. |
| **AD-13** | **AI OCR Check-in Thông minh Liên Quân Mobile (Nhận diện chữ xanh)** | - Tiếp nhận ảnh chụp màn hình hiển thị danh sách check-in từ trang web `congdong.lienquan.garena.vn` (hoặc ảnh chụp sảnh phòng lobby in-game).<br>- **Model AI Vision & OCR**: Phân đoạn dải màu xanh lá cây (HSV Green Filter) để nhận diện các dòng trạng thái / tên người chơi có màu xanh lá (đại diện cho người chơi đã check-in / sẵn sàng).<br>- Tự động bóc tách Ingame ID / Tên và chạy thuật toán so khớp mờ (**Fuzzy String Matching** $\ge 80\%$) với danh sách thí sinh 2 đội trong CSDL.<br>- Hiển thị **bảng đề xuất đối chiếu thông minh** trên giao diện: cho phép Admin/Trọng tài **chỉnh sửa thủ công** (thêm/bớt/chọn lại người tương ứng) trước khi lưu.<br>- Cung cấp nút **"Xác nhận toàn bộ (1-Click Approve)"**.<br>- **Cơ chế Tự động Xóa ảnh tạm (Auto-delete Ephemeral Image)**: Ngay sau khi bấm xác nhận check-in, hệ thống tự động xóa vĩnh viễn file ảnh đã upload khỏi server/storage để tối ưu dung lượng và bảo mật quyền riêng tư. |

---

### 3.3 Chức năng dành cho CTV (Cộng tác viên / Đồng tổ chức)

| Mã | Chức năng | Mô tả chi tiết |
|---|---|---|
| **CTV-01** | **Duyệt đăng ký sinh viên** | Xem hồ sơ chờ duyệt và phê duyệt thẻ sinh viên (dùng chung hàng đợi kiểm duyệt với Admin). |
| **CTV-02** | **Đề xuất tạo giải đấu mới** | Tạo giải đấu với `created_by = ctv.id`, trạng thái `pending`, chờ Admin phê duyệt trước khi công bố. |
| **CTV-03** | **Quản lý giải đấu được phân công** | Quản lý các giải đấu do mình tạo hoặc được Admin gán quyền đồng tổ chức trong `tournament_organizers`. |
| **CTV-04** | **Duyệt đơn đăng ký giải đấu** | Duyệt (`approved`) hoặc từ chối (`rejected`) đơn đăng ký cá nhân/đội tham gia giải đấu mình phụ trách. |
| **CTV-05** | **Vận hành Nhánh đấu & Trận đấu** | Sinh nhánh đấu khi đóng đăng ký, phân phòng TFT theo thuật toán, cập nhật lịch thi đấu, nhập tỉ số ván đấu và ảnh chụp bằng chứng kết quả. |
| **CTV-06** | **Xuất danh sách VĐV & Bảng điểm danh giải phụ trách** | Xuất bảng danh sách VĐV hợp lệ kèm Ingame ID, số điện thoại, tên đội và danh sách phân phòng ra file Excel/PDF phục vụ công tác điều phối tại bàn BTC. |
| **CTV-07** | **Điều hành Check-in Ngày thi đấu** | - Hiển thị/Trình chiếu mã QR Check-in của giải đấu tại bàn BTC hoặc phòng thi đấu.<br>- Giám sát danh sách thí sinh điểm danh, kiểm tra ảnh minh chứng và duyệt check-in cho các thí sinh giải mình phụ trách. |
| **CTV-08** | **Xuất báo cáo kết quả thi đấu & Check-in** | Xuất bảng tổng kết danh sách các bạn đã check-in thành công, danh sách vắng mặt, và bảng điểm từng vòng đấu của giải đấu được phân công. |
| **CTV-09** | **Sử dụng AI OCR Check-in Liên Quân Mobile** | - Upload ảnh chụp danh sách điểm danh trên `congdong.lienquan.garena.vn` hoặc phòng lobby cho trận đấu mình điều phối.<br>- Xem bảng đề xuất nhận diện chữ xanh của AI, chỉnh sửa sai sót nếu có (đổi tên, chọn lại VĐV) và bấm nút xác nhận 1-click để hệ thống tự động hoàn tất check-in và xóa ảnh tạm. |

---

## 4. Luồng nghiệp vụ chính (Business Flow)

### 4.1 Luồng đăng ký & duyệt tài khoản sinh viên (KYC thẻ SV)
```
Sinh viên điền thông tin + Upload 2 ảnh:
(1) Mặt trước thẻ SV + (2) Ảnh mặt và tay cầm thẻ SV
                     │
                     ▼
             status = 'pending'
                     │
                     ▼
          Admin/CTV kiểm tra hồ sơ
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
        Duyệt                 Từ chối
 (status = 'approved',  (status = 'rejected',
  approved_by,           rejection_reason,
  approved_at)           rejected_at)
          │                     │
          ▼                     ▼
 Sinh viên đăng nhập     Sinh viên xem lý do từ chối,
 & tham gia giải đấu     sửa ảnh/thông tin gửi duyệt lại (status -> pending)
```

---

### 4.2 Luồng phân quyền CTV Đồng tổ chức giải đấu
```
Admin tạo giải HOẶC Admin duyệt giải do CTV tạo
                     │
                     ▼
  Admin vào mục "Quản lý Ban Tổ Chức" của giải
                     │
                     ▼
    Chọn các CTV từ danh sách tài khoản
                     │
                     ▼
 Thêm vào bảng `tournament_organizers` (role: co_organizer / referee)
                     │
                     ▼
Các CTV được gán có đầy đủ quyền: duyệt đơn đăng ký, tạo nhánh đấu, nhập tỉ số,
sử dụng AI OCR Check-in, xuất danh sách VĐV giải đấu đó
```

---

### 4.3 Luồng đăng ký giải & Tuyển quân / Xin gia nhập đội
```
              Sinh viên xem giải đấu đang mở đăng ký
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
 [Giải cá nhân: TFT]                   [Giải đồng đội: Liên Quân/LOL]
Điền Ingame ID (Riot ID)             Đội trưởng tạo đơn + Tên đội + Ingame ID
+ Thông tin bổ sung                  + Thêm thành viên hiện có (VD: 4/7)
            │                                     │
            │                         (Tuỳ chọn) Bật `is_recruiting = true`
            │                         kèm ghi chú vị trí cần tuyển
            │                                     │
            │                         Các sinh viên khác thấy đội 4/7
            │                         bấm "Xin vào đội" (kèm Ingame ID)
            │                                     │
            │                         Đội trưởng Duyệt (Accept) / Từ chối
            │                         -> Hệ thống tự thêm vào danh sách đội
            │                                     │
            └──────────────────┬──────────────────┘
                               ▼
        Gửi đơn đăng ký: status = 'pending'
                               ▼
        Admin/CTV duyệt: status = 'approved'
```

---

### 4.4 Luồng Nhánh đấu & Thuật toán chia bảng TFT

#### a) Thuật toán chia phòng TFT khi số thí sinh $N$ không chia hết cho 8
- **Mục tiêu**: Tối đa hóa số bảng 8 người, giảm thiểu tối đa số bảng bị thiếu người; bảng thiếu người sẽ có 7 người (không để xuất hiện bảng $\le 6$ người trừ khi $N < 7$).
- **Công thức xác định số bảng**:
  Gọi $N$ là tổng số thí sinh đã được duyệt ($N \ge 7$), $a$ là số phòng 8 người, $b$ là số phòng 7 người.
  - Đặt $k = \lfloor N / 8 \rfloor$, $r = N \bmod 8$.
  - Nếu $r = 0 \implies a = k, \; b = 0$.
  - Nếu $r > 0 \implies b = 8 - r, \; a = k - (7 - r)$.

#### b) Thể thức cho Game đồng đội (Liên Quân, LOL, Valorant)
- Hỗ trợ: Single Elimination, Double Elimination, Group Stage + Playoff (BO1 / BO3 / BO5 / BO7).

---

### 4.5 Luồng Check-in Ngày thi đấu Tổng thể (QR Scan, Minh chứng & AI OCR)

```
                       Đến ngày thi đấu giải
         (Hệ thống kích hoạt cổng check-in & sinh mã QR BTC)
                                 │
     ┌───────────────────────────┼───────────────────────────┐
     ▼                           ▼                           ▼
[HÌNH THỨC 1: QUÉT QR]   [HÌNH THỨC 2: MINH CHỨNG]   [HÌNH THỨC 3: AI OCR (LQ)]
Thí sinh quét QR BTC     Thí sinh upload ảnh chụp    Trọng tài upload ảnh chụp từ
kèm cấp quyền vị trí GPS  tại sàn đấu/phòng máy      congdong.lienquan.garena.vn
     │                           │                   hoặc phòng lobby in-game
     │                           ▼                           │
Lưu GPS + Device Info    Tạo bản ghi:                        ▼
-> Tự động Approved      status = 'pending_review'   AI nhận diện chữ xanh lá
     │                           │                   + So khớp Ingame ID
     │                           ▼                           │
     │                   Admin/CTV duyệt ảnh         Hiện bảng đề xuất đối soát
     │                   -> Approved / Rejected      (Trọng tài sửa & 1-click Approve)
     │                           │                           │
     │                           │                   Tự động Xóa Ảnh Tạm
     │                           │                   -> status = 'approved'
     └───────────────────────────┼───────────────────────────┘
                                 │
               (ĐẶC QUYỀN ADMIN / MANUAL OVERRIDE)
     Admin có thể bấm "Xác nhận tham gia" trực tiếp cho bất kỳ ai
                                 │
                                 ▼
         Admin/CTV xem bản đồ vị trí điểm danh của các thí sinh
   (Sử dụng Leaflet/OpenStreetMap MIỄN PHÍ hoặc mở link Google Maps)
```

---

### 4.6 Luồng Tự động Xuất & Tra cứu Giấy Chứng Nhận (E-Certificate)

```
                   Giải đấu kết thúc (status = 'completed')
                                 │
                                 ▼
             [Async Worker] Quét toàn bộ thí sinh của giải
                                 │
              Thí sinh đã check-in hợp lệ (status = 'approved')?
                     ┌───────────┴───────────┐
                     ▼                       ▼
                   [CÓ]                    [KHÔNG]
          Hệ thống sinh tự động          Không cấp chứng nhận
          Giấy chứng nhận (E-Certificate)
          theo Template phôi có sẵn
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
- Gắn mã code xác nhận    - Render file PDF/PNG
  duy nhất & QR Code        chất lượng cao
          │                     │
          └──────────┬──────────┘
                     ▼
  Lưu vào bảng `certificates`, gửi thông báo đến thí sinh
                     │
  ┌──────────────────┴──────────────────┐
  ▼                                     ▼
Thí sinh xem & tải chứng chỉ         Bên thứ 3 quét QR trên chứng chỉ
trong trang cá nhân / giải đấu        để tra cứu tính hợp lệ công khai
```

---

### 4.7 Luồng Xuất danh sách thành viên & Báo cáo dữ liệu (Data Export Flow)

```
Admin / CTV / Đội trưởng chọn chức năng "Xuất dữ liệu"
                        │
                        ▼
       Chọn phạm vi và bộ lọc xuất dữ liệu:
       - Phạm vi: Toàn giải / Bảng đấu / Phòng đấu / Đội của tôi
       - Bộ lọc: Trạng thái Check-in (Tất cả / Đã check-in / Chưa check-in)
       - Loại sinh viên: Nội bộ DUT (`internal`) / Trường ngoài (`external`)
       - Định dạng file: Excel (.xlsx) / CSV / PDF In ấn
                        │
                        ▼
       Kiểm tra quyền hạn & Áp dụng Data Masking:
       - Admin/CTV phụ trách giải: Xuất đầy đủ Họ tên, MSSV, SĐT, Email, GPS, Ingame ID.
       - Đội trưởng/User: Chỉ xuất danh sách thành viên đội mình (ẩn SĐT/Email đối thủ).
                        │
                        ▼
            [Streaming Export Worker]
      Tạo file theo cấu trúc chuẩn hoá, đẩy về
      trình duyệt dưới dạng File Download trực tiếp
```

---

### 4.8 Luồng AI OCR Nhận diện Chữ xanh & Tự động Đề xuất Check-in Liên Quân Mobile

```
   Trọng tài / CTV chụp ảnh màn hình bảng điểm danh trên trang
     congdong.lienquan.garena.vn (hoặc ảnh sảnh phòng Custom LQ)
                                │
                                ▼
         Upload ảnh vào màn hình "AI Check-in Liên Quân" của Trận đấu
                                │
                                ▼
               ┌─────────────────────────────────┐
               │    AI VISION & OCR PIPELINE     │
               ├─────────────────────────────────┤
               │ 1. Image Preprocessing:         │
               │    - Chuyển đổi không gian HSV  │
               │    - Lọc dải màu Xanh Lá Cây:   │
               │      H ∈ [35°, 85°], S, V ≥ 40% │
               │                                 │
               │ 2. Text Bounding Box Detection: │
               │    - Tách contour các vùng chữ  │
               │      màu xanh (đã check-in)     │
               │                                 │
               │ 3. OCR Text Recognition:        │
               │    - Bóc tách ký tự Ingame ID/  │
               │      Tên kiện tướng từ vùng xanh│
               │                                 │
               │ 4. Fuzzy String Matching:       │
               │    - So khớp với Ingame ID của  │
               │      2 đội trong CSDL trận đấu  │
               │      (Levenshtein Score ≥ 80%)  │
               └────────────────┬────────────────┘
                                │
                                ▼
               [GIAO DIỆN ĐỀ XUẤT ĐỐI SOÁT TRỰC QUAN]
   - Hiển thị ảnh gốc kèm Bounding Box xanh bao quanh các tên phát hiện
   - Bảng danh sách gợi ý:
     ┌──────────────────┬─────────────────────┬──────────────────┬────────┐
     │ Text AI nhận diện│ VĐV khớp trong CSDL │ Tên Đội          │ Check  │
     ├──────────────────┼─────────────────────┼──────────────────┼────────┤
     │ DUT_Flash        │ Nguyễn Văn A (MSSV) │ Bách Khoa Stars  │  [x]   │
     │ Pro_Gamer26      │ Trần Văn B (MSSV)   │ Bách Khoa Stars  │  [x]   │
     │ ...              │ ...                 │ ...              │  [x]   │
     └──────────────────┴─────────────────────┴──────────────────┴────────┘
                                │
                                ▼
         Trọng tài kiểm tra nhanh & Chỉnh sửa thủ công nếu cần:
         - Bỏ chọn nếu nhận diện nhầm
         - Chọn lại VĐV tương ứng từ dropdown nếu tên ingame viết tắt/ký tự lạ
                                │
                                ▼
            Trọng tài bấm "XÁC NHẬN TOÀN BỘ CHECK-IN" (1-Click)
                                │
            ┌───────────────────┴───────────────────┐
            ▼                                       ▼
Ghi nhận check-in vào CSDL:             [XỬ LÝ DỌN DẸP BỘ NHỚ]
`check_ins`:                             Tự động XÓA VĨNH VIỄN file ảnh
- checkin_method = 'ai_ocr'              tạm thời khỏi server/storage
- status = 'approved'                    (Bảo mật PII & Tối ưu 100% dung lượng)
```

---

## 5. Yêu cầu phi chức năng

| Mã | Yêu cầu | Mô tả |
|---|---|---|
| **NFR-01** | **Bảo mật & Quyền riêng tư** | Tuyệt đối không lưu trữ CCCD. Ảnh thẻ sinh viên được mã hóa đường dẫn. Tọa độ GPS chỉ thu thập khi người dùng đồng ý cấp quyền trên trình duyệt phục vụ đối soát gian lận. |
| **NFR-02** | **Hiệu năng & Xử lý bất đồng bộ** | Việc render Giấy chứng nhận (PDF/Canvas), xử lý xuất file Excel hàng nghìn thí sinh và quét QR check-in đồng thời được xử lý qua hàng đợi bất đồng bộ (Queue Worker), không gây nghẽn luồng chính. |
| **NFR-03** | **Tối ưu Chi phí Bản đồ (Map API Optimization)** | Giao diện quản trị vị trí check-in sử dụng thư viện **Leaflet.js kết hợp OpenStreetMap (OSM)** hoàn toàn **MIỄN PHÍ** để hiển thị bản đồ trực quan các điểm check-in. Đối với tùy chọn Google Maps, chỉ sử dụng liên kết điều hướng ngoài (`https://maps.google.com/?q={lat},{lng}`) nhằm **bảo toàn 100% hạn mức $200 miễn phí hàng tháng của Google Maps API**. |
| **NFR-04** | **Tính toàn vẹn & Chống giả mạo chứng nhận** | Mỗi Giấy chứng nhận điện tử được cấp một mã băm `certificate_code` ngẫu nhiên và mã QR liên kết trang xác minh công khai, ngăn chặn triệt để hành vi photoshop làm giả giấy khen/chứng nhận. |
| **NFR-05** | **Hiệu năng, Độ chính xác & Xóa ảnh tạm của AI OCR Model** | - **Thời gian suy luận (Inference Time)**: $\le 2.5$ giây/ảnh.<br>- **Độ chính xác nhận diện chữ xanh**: Đạt $\ge 95\%$ trên ảnh chụp màn hình rõ nét từ `congdong.lienquan.garena.vn` hoặc sảnh phòng game.<br>- **Thuật toán Fuzzy Match**: Chấp nhận sai số khoảng cách Levenshtein tối đa 2 ký tự hoặc độ tương đồng $\ge 80\%$ để xử lý tốt font chữ đặc thù và ký tự đặc biệt của game thủ.<br>- **Chính sách Tự hủy Ảnh Tạm (Ephemeral Retention)**: File ảnh tải lên để AI nhận diện chỉ lưu tạm trong bộ nhớ đệm (hoặc temp storage) và **bắt buộc bị xóa vĩnh viễn ngay lập tức sau khi trọng tài bấm nút xác nhận** (hoặc tự hủy sau 30 phút nếu phiên bị hủy bỏ), đảm bảo tối ưu 100% không gian lưu trữ và bảo vệ dữ liệu. |
| **NFR-06** | **Bảo mật xuất dữ liệu & Tối ưu RAM (Data Export Optimization)** | - **Streaming Response**: Sử dụng cơ chế stream dữ liệu khi xuất các file Excel/CSV lớn, không nạp toàn bộ dữ liệu vào RAM máy chủ cùng lúc.<br>- **Chống lạm dụng (Rate Limiting)**: Giới hạn tối đa 10 lượt xuất file/phút/tài khoản nhằm ngăn ngừa tấn công làm cạn kiệt tài nguyên hệ thống.<br>- **Data Masking**: Tự động che giấu (mask) thông tin SĐT và Email đối với các tài khoản không có quyền quản trị giải đấu. |

---

## 6. Mô hình Dữ liệu Cơ sở dữ liệu (Database Schema)

### 6.1 Sơ đồ thực thể quan hệ (ERD Overview)

```
       ┌───────────────────┐               ┌───────────────────────────┐
       │       users       │──────────────<│   tournament_organizers   │
       │ (Admin / CTV)     │               └─────────────┬─────────────┘
       └─────────┬─────────┘                             │
                 │                                       │
                 │ 1:N                                   │ M:N
                 ▼                                       ▼
       ┌───────────────────┐ 1:N (tournament_id)  ┌───────────────────────────┐
       │    tournaments    │──────────────────────>│          brackets         │
       └────┬─────────┬────┘                       └─────────────┬─────────────┘
            │         │ 1:N (tournament_id)                      │ 1:N
            │         ├──────────────────────────┐               ▼
            │         │                          │ ┌───────────────────────────┐
            │         │ 1:N                      │ │       bracket_rounds      │
            │         ▼                          │ └─────────────┬─────────────┘
            │  ┌───────────────────┐             │               │ 1:N
            │  │    check_ins      │             │               ▼
            │  │(QR/GPS/Minh chứng/│             │ ┌───────────────────────────┐
            │  │      AI OCR)      │             ├>│          matches          │
            │  └───────────────────┘             │ └─────────────┬─────────────┘
            │                                    │               │ 1:N
            │ 1:N                                │ ┌─────────────┴─────────────┐
            ▼                                    │ │    ai_checkin_sessions    │
       ┌───────────────────┐                     │ │ (Phiên quét AI & Xóa ảnh) │
       │   registrations   │─────────────────────┤ └─────────────┬─────────────┘
       │  (Cá nhân / Đội)  │                     │               │ 1:N
       └────┬─────────┬────┘                     │ ┌─────────────┴─────────────┐
            │         │ 1:N                      │ │   ai_checkin_detections   │
            │         ▼                          │ │(Bounding box & Gợi ý tên) │
            │  ┌───────────────────────────┐     │ └───────────────────────────┘
            │  │    team_join_requests     │     │               │
            │  │   (Xin vào đội 4/7)       │     │               │ 1:N
            │  └───────────────────────────┘     │               ▼
            │ 1:N                                │ ┌───────────────────────────┐
            ▼                                    │ │     match_participants    │
┌───────────────────────────┐                    │ └───────────────────────────┘
│   registration_members    │                    │
│  (Thành viên & Ingame ID) │                    │
└───────────┬───────────────┘                    │
            │ N:1                                │
            ▼                                    │
┌───────────────────────────┐                    │
│       participants        │────────────────────┘
│ (Sinh viên - Thẻ SV KYC)  │ 1:N
└───────────┬───────────────┘
            │ 1:N
            ▼
┌───────────────────────────┐
│       certificates        │
│(E-Certificate tự động cấp)│
└───────────────────────────┘
```

---

### 6.2 Chi tiết các bảng trong CSDL (PostgreSQL)

#### 1. Bảng `users` (Tài khoản Quản trị & CTV)
- `id` (`uuid`, PK): Khóa chính ngẫu nhiên (`uuid_generate_v4()`).
- `username` (`text`, Unique): Tên đăng nhập.
- `password_hash` (`character varying`): Mật khẩu băm.
- `full_name` (`character varying`): Họ và tên.
- `role` (`character varying`): `'admin'` hoặc `'ctv'` (mặc định `'ctv'`).
- `is_active` (`boolean`): Trạng thái tài khoản.
- `created_at`, `updated_at` (`timestamp with time zone`).

#### 2. Bảng `participants` (Tài khoản Sinh viên / VĐV - Đã loại bỏ CCCD)
- `id` (`text`, PK): Mã định danh hoặc mã sinh viên.
- `username` (`text`): Tên tài khoản hiển thị.
- `password_hash` (`text`): Mật khẩu băm.
- `full_name` (`text`): Họ và tên sinh viên.
- `student_id` (`text`, Unique): Mã số sinh viên.
- `email` (`text`, Unique): Email sinh viên.
- `phone_number` (`character varying`), `university_name`, `faculty_name`, `class_name`.
- `account_type` (`text`): `'internal'` hoặc `'external'`.
- **Hồ sơ xác minh thẻ SV**: `student_card_url` (mặt trước), `selfie_with_student_card_url` (mặt và tay cầm thẻ).
- **Trạng thái kiểm duyệt**: `status` (`'pending'`, `'approved'`, `'rejected'`), `approved_by`, `approved_at`, `rejection_reason`, `rejected_at`.
- `created_at`, `updated_at` (`timestamp with time zone`).

#### 3. Bảng `tournaments` (Giải đấu)
- `id` (`uuid`, PK).
- `code` (`character varying`, Unique): Mã giải đấu (VD: `DUT-LQ-2026-S1`).
- `name`, `game_name`, `game_logo_url`, `banner_url`.
- `participation_type` (`character varying`): `'individual'` hoặc `'team'`.
- `max_participants`, `min_team_size`, `max_team_size`.
- `registration_open_at`, `registration_close_at`, `start_at`, `end_at`.
- `checkin_open_at`, `checkin_close_at` (`timestamp with time zone`): Thời gian mở/đóng check-in ngày thi đấu.
- `checkin_qr_secret` (`text`): Khóa bí mật sinh mã QR Check-in động cho BTC.
- `certificate_template_url` (`text`): URL file mẫu phôi chứng chỉ (SVG/HTML/PNG).
- `form_schema` (`jsonb`), `status` (`character varying`).
- `created_by` (`uuid`, FK $\rightarrow$ `users.id`), `approved_by` (`uuid`, FK $\rightarrow$ `users.id`).
- `created_at`, `approved_at`, `updated_at` (`timestamp with time zone`).

#### 4. Bảng `tournament_organizers` (Phân quyền CTV Đồng tổ chức)
- `id` (`uuid`, PK), `tournament_id` (`uuid`, FK), `user_id` (`uuid`, FK), `role`, `assigned_by`, `assigned_at`.

#### 5. Bảng `registrations` (Đơn đăng ký tham gia giải)
- `id` (`uuid`, PK), `tournament_id` (`uuid`, FK), `captain_id` (`text`, FK), `team_name`, `ingame_id`.
- `is_recruiting` (`boolean`), `recruitment_notes` (`text`), `submitted_data` (`jsonb`), `status`.
- `registered_at`, `updated_at` (`timestamp with time zone`).

#### 6. Bảng `registration_members` (Danh sách thành viên trong đội)
- `registration_id` (`uuid`, FK), `participant_id` (`text`, FK), `is_captain`, `ingame_id`, `role_in_team`, `joined_at`.
- Khóa chính kép: `PRIMARY KEY (registration_id, participant_id)`.

#### 7. Bảng `team_join_requests` (Yêu cầu xin gia nhập đội)
- `id` (`uuid`, PK), `registration_id` (`uuid`, FK), `participant_id` (`text`, FK), `ingame_id`, `message`, `status`, `processed_by`, `processed_at`.

#### 8. Bảng `check_ins` (Điểm danh Ngày thi đấu - Đa phương thức)
- `id` (`uuid`, PK): Khóa chính ngẫu nhiên (`uuid_generate_v4()`).
- `tournament_id` (`uuid`, FK $\rightarrow$ `tournaments.id` ON DELETE CASCADE).
- `registration_id` (`uuid`, FK $\rightarrow$ `registrations.id` ON DELETE CASCADE): Đơn đăng ký.
- `participant_id` (`text`, FK $\rightarrow$ `participants.id` ON DELETE CASCADE): Thí sinh điểm danh.
- `checkin_method` (`character varying`):
  - `'qr_scan'`: Quét mã QR tại điểm thi đấu.
  - `'proof_submission'`: Nộp ảnh minh chứng (chờ duyệt).
  - `'ai_ocr'`: Tự động nhận diện qua AI OCR chữ xanh (web `congdong.lienquan.garena.vn` / lobby).
  - `'manual_admin'`: Admin/BTC xác nhận thủ công.
- `status` (`character varying`): `'approved'` (hợp lệ), `'pending_review'` (chờ duyệt minh chứng), `'rejected'`.
- `proof_url` (`text`): URL ảnh chụp phòng máy / bằng chứng check-in (nếu có).
- **Dữ liệu Định vị & Thiết bị (Geolocation & Device Info)**:
  - `latitude` (`double precision`): Vĩ độ GPS.
  - `longitude` (`double precision`): Kinh độ GPS.
  - `location_accuracy` (`double precision`): Bán kính sai số GPS (mét).
  - `ip_address` (`character varying`): Địa chỉ IP của thiết bị.
  - `device_info` (`text`): Thông tin trình duyệt / User-Agent / Device Fingerprint.
- `checked_in_at` (`timestamp with time zone` NOT NULL DEFAULT `CURRENT_TIMESTAMP`).
- `reviewed_by` (`uuid`, FK $\rightarrow$ `users.id`): Admin/CTV duyệt minh chứng hoặc xác nhận AI đề xuất.
- `reviewed_at` (`timestamp with time zone`).
- `notes` (`text`): Ghi chú của trọng tài/admin.
- Ràng buộc: `UNIQUE(tournament_id, participant_id)`.

#### 9. Bảng `certificates` (Giấy chứng nhận Điện tử E-Certificate)
- `id` (`uuid`, PK): Khóa chính ngẫu nhiên (`uuid_generate_v4()`).
- `tournament_id` (`uuid`, FK $\rightarrow$ `tournaments.id` ON DELETE CASCADE).
- `participant_id` (`text`, FK $\rightarrow$ `participants.id` ON DELETE CASCADE).
- `registration_id` (`uuid`, FK $\rightarrow$ `registrations.id` ON DELETE CASCADE).
- `certificate_code` (`character varying` NOT NULL UNIQUE): Mã định danh duy nhất (VD: `DUT-CERT-2026-LQ-08492`).
- `title` (`character varying` NOT NULL): Tiêu đề giấy chứng nhận (VD: "Giấy Chứng Nhận Tham Gia Giải Đấu", "Giấy Khen Vô Địch").
- `achievement_title` (`character varying`): Danh hiệu (VD: "Vô Địch", "Á Quân", "Top 4", "Vận Động Viên").
- `certificate_url` (`text` NOT NULL): URL file PDF / ảnh PNG chất lượng cao đã render.
- `qr_verify_url` (`text`): Link tra cứu tính hợp lệ công khai (VD: `https://esports.dut.udn.vn/verify/DUT-CERT-2026-LQ-08492`).
- `metadata` (`jsonb`): Thông tin snapshot lúc cấp (Họ tên, MSSV, Tên đội, Điểm số, Game).
- `is_revoked` (`boolean` NOT NULL DEFAULT `false`): Trạng thái thu hồi chứng chỉ nếu gian lận.
- `issued_at` (`timestamp with time zone` NOT NULL DEFAULT `CURRENT_TIMESTAMP`).
- Ràng buộc: `UNIQUE(tournament_id, participant_id)`.

#### 10. Bảng `brackets` (Cấu trúc Nhánh đấu)
- `id` (`uuid`, PK), `tournament_id` (`uuid`, FK), `name`, `format`, `status`, `settings` (`jsonb`).

#### 11. Bảng `bracket_rounds` (Các Vòng đấu trong Nhánh)
- `id` (`uuid`, PK), `bracket_id` (`uuid`, FK), `round_number`, `name`, `bo_type`, `order_index`.

#### 12. Bảng `matches` (Trận đấu / Phòng đấu TFT)
- `id` (`uuid`, PK), `bracket_id` (`uuid`, FK), `round_id` (`uuid`, FK), `match_code`, `match_type` (`'head_to_head'`, `'tft_lobby'`), `scheduled_at`, `status`, `winner_registration_id`, `next_match_id`, `referee_id`, `custom_room_info`.

#### 13. Bảng `match_participants` (VĐV trong Trận đấu & Phòng TFT)
- `id` (`uuid`, PK), `match_id` (`uuid`, FK), `registration_id` (`uuid`, FK), `slot_number`, `score`, `rank_position`, `is_winner`, `evidence_url`, `points_awarded`.

#### 14. Bảng `match_games` (Chi tiết từng ván trong BO3/BO5)
- `id` (`uuid`, PK), `match_id` (`uuid`, FK), `game_number`, `duration_seconds`, `winner_registration_id`, `result_details`.

#### 15. Bảng `ai_checkin_sessions` (Phiên phân tích AI Check-in Liên Quân Mobile - Mới)
- `id` (`uuid`, PK): Khóa chính ngẫu nhiên (`uuid_generate_v4()`).
- `tournament_id` (`uuid`, FK $\rightarrow$ `tournaments.id` ON DELETE CASCADE).
- `match_id` (`uuid`, FK $\rightarrow$ `matches.id` ON DELETE SET NULL): Trận đấu tương ứng được check-in.
- `created_by` (`uuid`, FK $\rightarrow$ `users.id`): Trọng tài / CTV tải ảnh lên.
- `source_type` (`character varying` NOT NULL DEFAULT `'congdong_lienquan'`): Loại ảnh nguồn (`'congdong_lienquan'`, `'custom_lobby'`).
- `status` (`character varying` NOT NULL DEFAULT `'pending_review'`): Trạng thái phiên (`'processing'`, `'pending_review'`, `'confirmed'`, `'cancelled'`).
- `total_detected` (`integer` DEFAULT 0): Tổng số chữ xanh / tên phát hiện được.
- `total_matched` (`integer` DEFAULT 0): Số lượng VĐV khớp thành công với CSDL giải đấu.
- `image_purged` (`boolean` NOT NULL DEFAULT `false`): Cờ đánh dấu file ảnh tải lên tạm thời đã bị xóa vĩnh viễn sau khi xác nhận.
- `confirmed_by` (`uuid`, FK $\rightarrow$ `users.id`): Người bấm xác nhận.
- `confirmed_at` (`timestamp with time zone`): Thời gian xác nhận.
- `created_at` (`timestamp with time zone` NOT NULL DEFAULT `CURRENT_TIMESTAMP`).

#### 16. Bảng `ai_checkin_detections` (Chi tiết Từng đối tượng nhận diện trong Phiên AI - Mới)
- `id` (`uuid`, PK): Khóa chính ngẫu nhiên (`uuid_generate_v4()`).
- `session_id` (`uuid`, FK $\rightarrow$ `ai_checkin_sessions.id` ON DELETE CASCADE).
- `raw_text` (`text` NOT NULL): Chuỗi ký tự text nhận dạng được từ vùng chữ xanh.
- `ocr_confidence` (`double precision`): Độ tin cậy của thuật toán OCR (0.0 - 1.0).
- `bounding_box` (`jsonb`): Tọa độ khung chữ trên ảnh `{"x": 120, "y": 340, "width": 150, "height": 30}` phục vụ hiển thị highlight trực quan.
- `matched_participant_id` (`text`, FK $\rightarrow$ `participants.id` ON DELETE SET NULL): Thí sinh trong hệ thống được đề xuất khớp.
- `matched_registration_id` (`uuid`, FK $\rightarrow$ `registrations.id` ON DELETE SET NULL): Đội của thí sinh.
- `similarity_score` (`double precision`): Tỷ lệ tương đồng chuỗi ký tự theo Fuzzy Matching (0.0 - 1.0).
- `is_manually_adjusted` (`boolean` NOT NULL DEFAULT `false`): Đánh dấu nếu trọng tài đã chỉnh sửa/chọn lại VĐV bằng tay.
- `is_confirmed` (`boolean` NOT NULL DEFAULT `true`): Trạng thái chọn check-in của mục này khi bấm lưu.
- `created_at` (`timestamp with time zone` NOT NULL DEFAULT `CURRENT_TIMESTAMP`).

#### 17. Bảng `notifications` & `audit_logs`
- Lưu thông báo sự kiện (check-in thành công, phát hành chứng chỉ, export file) và lịch sử thao tác kiểm duyệt của Admin/CTV.

---

## 7. Ma trận phân quyền (Role-Based Access Control)

| Chức năng | Sinh viên | CTV | Admin |
|---|:---:|:---:|:---:|
| Đăng ký & upload 2 ảnh xác minh thẻ SV | ✅ | ❌ | ❌ |
| Đăng nhập tài khoản sinh viên | ✅ (khi duyệt) | ❌ | ❌ |
| Tuyển quân / Xin gia nhập đội còn thiếu | ✅ | ❌ | ❌ |
| Đăng ký tham gia giải đấu | ✅ | ❌ | ❌ |
| Tra cứu Ingame ID đối thủ cùng bảng | ✅ | ✅ | ✅ |
| Quét QR Check-in (GPS) & Nộp minh chứng | ✅ | ❌ | ❌ |
| Xuất danh sách thành viên đội cá nhân | ✅ (Đội trưởng) | ❌ | ❌ |
| Xem & Tải Giấy chứng nhận (E-Certificate) | ✅ | ✅ | ✅ |
| Duyệt tài khoản sinh viên (KYC) | ❌ | ✅ | ✅ |
| CRUD tài khoản sinh viên | ❌ | ❌ | ✅ |
| Tạo đề xuất giải đấu mới | ❌ | ✅ (chờ duyệt) | ✅ |
| Phê duyệt giải đấu công khai | ❌ | ❌ | ✅ |
| Phân quyền CTV đồng tổ chức giải đấu | ❌ | ❌ | ✅ |
| Quản lý giải mình (đồng) tổ chức | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Trình chiếu QR Check-in cho thí sinh | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Duyệt minh chứng check-in | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Xem bản đồ vị trí check-in của thí sinh | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Sử dụng AI OCR Check-in Liên Quân (Web/Lobby) | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Chỉnh sửa đề xuất AI & Xác nhận Check-in 1-Click | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Xuất danh sách VĐV & Báo cáo giải đấu (Excel/CSV/PDF) | ❌ | ✅ (giải phân công) | ✅ (tất cả) |
| Xác nhận tham gia thủ công (Manual Check-in) | ❌ | ❌ | ✅ |
| Cấu hình phôi & Phát hành E-Certificate | ❌ | ❌ | ✅ |
| Thu hồi / Cấp lại Giấy chứng nhận | ❌ | ❌ | ✅ |
| Quản lý tài khoản CTV (`users`) | ❌ | ❌ | ✅ |

---

## 8. Kết quả giải quyết các vấn đề & Cơ chế mở rộng (Resolved Specifications)

1. **Cơ chế xác định CTV tham gia tổ chức**: Bổ sung bảng `tournament_organizers` cho phép Admin gán CTV đồng tổ chức/làm trọng tài cho giải.
2. **Cấu trúc Nhánh đấu & Trận đấu**: Hệ thống bảng `brackets`, `bracket_rounds`, `matches`, `match_participants`, `match_games` hỗ trợ đối kháng 1v1 (Single/Double Elimination, Group Stage) và phòng TFT 8 người.
3. **Cơ chế "Xin vào đội" (Tuyển thành viên)**: Quản lý tuyển quân qua `registrations.is_recruiting` và bảng `team_join_requests`.
4. **Thuật toán chia bảng TFT ($N \bmod 8 \ne 0$)**: Tối đa hóa số phòng 8 người ($a$) và giảm thiểu số phòng 7 người ($b = (8 - (N \bmod 8)) \bmod 8$).
5. **Chuẩn hóa Ingame ID**: Bổ sung trường `ingame_id` trong `registrations` và `registration_members`, tự động trích xuất hiển thị cho toàn phòng thi đấu.
6. **Xác minh danh tính (KYC)**: Loại bỏ 100% CCCD; chỉ yêu cầu mặt trước thẻ sinh viên (`student_card_url`) và ảnh mặt + tay cầm thẻ sinh viên (`selfie_with_student_card_url`).
7. **Cơ chế Check-in Ngày thi đấu**:
   - Tích hợp đa hình thức: (1) Quét QR code kèm Geolocation GPS + Device metadata; (2) Nộp ảnh minh chứng nộp để Admin/CTV duyệt; (3) AI OCR Check-in tự động đề xuất.
   - Admin có quyền xác nhận tham gia trực tiếp (Manual Check-in).
   - Tối ưu chi phí hiển thị bản đồ bằng OpenStreetMap / Leaflet (miễn phí) kết hợp link điều hướng Google Maps, tiết kiệm trọn vẹn quota $200 API mỗi tháng.
8. **Tự động xuất Giấy chứng nhận (E-Certificate)**:
   - Tự động sinh chứng chỉ theo mẫu phôi khi giải kết thúc cho tất cả thí sinh đã check-in hợp lệ.
   - Mỗi chứng chỉ có mã băm duy nhất và QR Code tra cứu tính xác thực công khai chống giả mạo.
9. **Cơ chế Xuất danh sách thành viên & Báo cáo đa chiều**:
   - Hỗ trợ xuất file Excel (`.xlsx`), CSV và PDF theo nhiều tiêu chí (toàn giải, theo bảng, theo trạng thái điểm danh, theo phân loại sinh viên `internal`/`external`).
   - Tích hợp cơ chế Streaming Data tránh tràn RAM máy chủ và Data Masking ẩn PII theo phân quyền RBAC.
10. **Mô hình AI OCR Check-in Liên Quân Mobile (Nhận diện chữ xanh & Tự hủy ảnh tạm)**:
    - Tiếp nhận ảnh chụp màn hình từ cổng `congdong.lienquan.garena.vn` hoặc sảnh phòng tùy chọn (custom lobby).
    - Pipeline AI lọc dải màu HSV Green $\rightarrow$ trích xuất tên Ingame $\rightarrow$ so khớp mờ (Fuzzy Matching $\ge 80\%$) với danh sách VĐV của trận đấu trong CSDL.
    - Cung cấp giao diện trực quan hiển thị bounding box và danh sách đề xuất cho phép trọng tài chỉnh sửa linh hoạt trước khi bấm xác nhận 1-click.
    - **Cơ chế Tự động Xóa ảnh tạm (Auto Purge)**: Ngay sau khi xác nhận check-in, file ảnh upload được xóa vĩnh viễn khỏi hệ thống lưu trữ, giải quyết triệt để vấn đề dung lượng ổ đĩa và bảo vệ quyền riêng tư người dùng.

---

*Hết tài liệu.*
