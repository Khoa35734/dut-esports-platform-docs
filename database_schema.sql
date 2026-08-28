-- =============================================================================
-- DUT ESPORTS TOURNAMENT PLATFORM - DATABASE SCHEMA
-- Hệ quản trị cơ sở dữ liệu: PostgreSQL (13+) / Supabase
-- Phiên bản: 1.1 (Cập nhật chuẩn hóa KYC Thẻ SV, Nhánh đấu, Tuyển quân, Phân quyền CTV)
-- =============================================================================

-- Kích hoạt tiện ích tạo UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 0. HÀM TRIGGER TỰ ĐỘNG CẬP NHẬT updated_at
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 1. BẢNG users (Tài khoản Quản trị & CTV)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    username TEXT NOT NULL UNIQUE,
    password_hash CHARACTER VARYING NOT NULL,
    full_name CHARACTER VARYING NOT NULL,
    email TEXT UNIQUE,
    phone_number CHARACTER VARYING,
    role CHARACTER VARYING NOT NULL DEFAULT 'ctv', -- 'admin', 'ctv'
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT chk_user_role CHECK (role IN ('admin', 'ctv'))
);

COMMENT ON TABLE public.users IS 'Tài khoản quản trị cấp cao (Admin) và Cộng tác viên (CTV)';
COMMENT ON COLUMN public.users.role IS 'Vai trò: admin (toàn quyền) hoặc ctv (quản lý giải phân công)';

-- =============================================================================
-- 2. BẢNG participants (Tài khoản Sinh viên / Người chơi - ĐÃ LOẠI BỎ CCCD)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.participants (
    id TEXT NOT NULL, -- Mã SV hoặc UUID dạng text
    username TEXT,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,
    student_id TEXT UNIQUE, -- Mã số sinh viên
    email TEXT UNIQUE,
    phone_number CHARACTER VARYING,
    university_name CHARACTER VARYING,
    faculty_name TEXT,
    class_name TEXT,
    account_type TEXT NOT NULL DEFAULT 'external', -- 'internal' (DUT), 'external'
    
    -- Hồ sơ xác thực KYC Sinh viên (Chỉ dùng 2 ảnh thẻ SV, không dùng CCCD)
    student_card_url TEXT, -- Ảnh mặt trước thẻ sinh viên
    selfie_with_student_card_url TEXT, -- Ảnh chân dung và tay cầm thẻ sinh viên
    
    -- Trạng thái phê duyệt
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    approved_by TEXT, -- ID tài khoản duyệt
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    rejected_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT participants_pkey PRIMARY KEY (id),
    CONSTRAINT chk_participant_status CHECK (status IN ('pending', 'approved', 'rejected')),
    CONSTRAINT chk_account_type CHECK (account_type IN ('internal', 'external'))
);

COMMENT ON TABLE public.participants IS 'Tài khoản sinh viên và người tham gia thi đấu (KYC qua 2 ảnh thẻ SV)';
COMMENT ON COLUMN public.participants.student_card_url IS 'Ảnh chụp mặt trước thẻ sinh viên';
COMMENT ON COLUMN public.participants.selfie_with_student_card_url IS 'Ảnh chụp khuôn mặt và tay cầm thẻ sinh viên';

-- =============================================================================
-- 3. BẢNG tournaments (Giải đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.tournaments (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    code CHARACTER VARYING NOT NULL UNIQUE, -- Mã định danh giải (VD: DUT-TFT-2026)
    name CHARACTER VARYING NOT NULL,
    game_name CHARACTER VARYING NOT NULL, -- 'TFT', 'Liên Quân Mobile', 'LMHT', 'Valorant'...
    game_logo_url TEXT,
    banner_url TEXT NOT NULL,
    participation_type CHARACTER VARYING NOT NULL, -- 'individual', 'team'
    max_participants INTEGER NOT NULL, -- Số lượng người chơi hoặc đội tối đa
    min_team_size INTEGER DEFAULT 1, -- Số thành viên tối thiểu/đội (VD: 5 cho LQ)
    max_team_size INTEGER DEFAULT 1, -- Số thành viên tối đa/đội (VD: 7 cho LQ)
    
    registration_open_at TIMESTAMP WITH TIME ZONE NOT NULL,
    registration_close_at TIMESTAMP WITH TIME ZONE NOT NULL,
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Cấu hình Check-in Ngày thi đấu & Giấy chứng nhận
    checkin_open_at TIMESTAMP WITH TIME ZONE,
    checkin_close_at TIMESTAMP WITH TIME ZONE,
    checkin_qr_secret TEXT, -- Khóa sinh mã QR Check-in động cho BTC
    certificate_template_url TEXT, -- Mẫu phôi giấy chứng nhận điện tử (SVG/HTML/PNG)
    
    description TEXT,
    use_external_link BOOLEAN NOT NULL DEFAULT false,
    external_registration_url TEXT,
    form_schema JSONB NOT NULL DEFAULT '[]'::jsonb, -- Định nghĩa các trường động tùy biến
    
    created_by UUID, -- CTV hoặc Admin tạo giải
    approved_by UUID, -- Admin duyệt giải
    status CHARACTER VARYING NOT NULL DEFAULT 'pending', 
    -- 'draft', 'pending', 'approved', 'rejected', 'registration_opened', 'registration_closed', 'ongoing', 'completed', 'cancelled'
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT tournaments_pkey PRIMARY KEY (id),
    CONSTRAINT tournaments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT tournaments_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_participation_type CHECK (participation_type IN ('individual', 'team'))
);

COMMENT ON TABLE public.tournaments IS 'Bảng thông tin các giải đấu esports';

-- =============================================================================
-- 4. BẢNG tournament_organizers (Phân quyền CTV Đồng tổ chức giải)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.tournament_organizers (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role CHARACTER VARYING NOT NULL DEFAULT 'co_organizer', -- 'lead_organizer', 'co_organizer', 'referee'
    assigned_by UUID, -- Admin thực hiện thêm CTV
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT tournament_organizers_pkey PRIMARY KEY (id),
    CONSTRAINT uq_tournament_user UNIQUE (tournament_id, user_id),
    CONSTRAINT fk_to_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_to_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_to_assigned_by FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_organizer_role CHECK (role IN ('lead_organizer', 'co_organizer', 'referee'))
);

COMMENT ON TABLE public.tournament_organizers IS 'Danh sách CTV được Admin phân quyền đồng tổ chức hoặc làm trọng tài giải đấu';

-- =============================================================================
-- 5. BẢNG registrations (Đơn đăng ký tham gia giải đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.registrations (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    captain_id TEXT NOT NULL, -- Đội trưởng hoặc cá nhân đăng ký
    team_name CHARACTER VARYING, -- Tên đội (áp dụng game đồng đội)
    team_avatar_url TEXT,
    
    -- Chuẩn hóa Ingame ID của đội trưởng/thí sinh cá nhân (Riot ID / Tên kiện tướng)
    ingame_id CHARACTER VARYING,
    
    -- Cơ chế tìm kiếm và tuyển thêm thành viên
    is_recruiting BOOLEAN NOT NULL DEFAULT false, -- Đang bật tuyển quân (VD: 4/7 người)
    recruitment_notes TEXT, -- Ghi chú tuyển vị trí (VD: Cần 1 Mid, 1 SP rank Cao thủ)
    
    submitted_data JSONB NOT NULL DEFAULT '{}'::jsonb, -- Dữ liệu các trường động
    status CHARACTER VARYING NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'cancelled'
    rejection_reason TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    registered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT registrations_pkey PRIMARY KEY (id),
    CONSTRAINT registrations_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT registrations_captain_id_fkey FOREIGN KEY (captain_id) REFERENCES public.participants(id) ON DELETE RESTRICT,
    CONSTRAINT registrations_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_registration_status CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'))
);

COMMENT ON TABLE public.registrations IS 'Đơn đăng ký tham gia giải đấu (cá nhân hoặc đại diện đội)';
COMMENT ON COLUMN public.registrations.is_recruiting IS 'Đánh dấu đội đang tìm kiếm thêm thành viên trên hệ thống';
COMMENT ON COLUMN public.registrations.ingame_id IS 'Tên nhân vật / Riot ID / Ingame ID chính xác trong game';

-- =============================================================================
-- 6. BẢNG registration_members (Danh sách thành viên trong đội)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.registration_members (
    registration_id UUID NOT NULL,
    participant_id TEXT NOT NULL,
    is_captain BOOLEAN NOT NULL DEFAULT false,
    ingame_id CHARACTER VARYING, -- Ingame ID chính xác của thành viên này
    role_in_team CHARACTER VARYING, -- Vị trí thi đấu: 'Top', 'Jungle', 'Mid', 'AD', 'SP', 'Sub'...
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT registration_members_pkey PRIMARY KEY (registration_id, participant_id),
    CONSTRAINT fk_rm_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_rm_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE RESTRICT
);

COMMENT ON TABLE public.registration_members IS 'Thành viên thuộc một đội đăng ký thi đấu';

-- =============================================================================
-- 7. BẢNG team_join_requests (Yêu cầu xin gia nhập đội đang thiếu slot)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.team_join_requests (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    registration_id UUID NOT NULL,
    participant_id TEXT NOT NULL, -- Sinh viên muốn xin vào đội
    ingame_id CHARACTER VARYING NOT NULL, -- Ingame ID của ứng viên
    message TEXT, -- Lời nhắn / thông tin rank, lane sở trường
    status CHARACTER VARYING NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'cancelled'
    
    processed_by TEXT, -- Đội trưởng xử lý
    processed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT team_join_requests_pkey PRIMARY KEY (id),
    CONSTRAINT fk_tjr_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_tjr_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tjr_processed_by FOREIGN KEY (processed_by) REFERENCES public.participants(id) ON DELETE SET NULL,
    CONSTRAINT chk_tjr_status CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled'))
);

COMMENT ON TABLE public.team_join_requests IS 'Yêu cầu xin vào đội của người chơi tự do gửi tới đội trưởng';

-- =============================================================================
-- 8. BẢNG brackets (Nhánh đấu / Giai đoạn giải đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.brackets (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    name CHARACTER VARYING NOT NULL, -- 'Vòng loại', 'Vòng bảng', 'Playoffs Nhánh thắng - thua', 'TFT Vòng 1'
    format CHARACTER VARYING NOT NULL, -- 'single_elimination', 'double_elimination', 'round_robin', 'tft_lobbies'
    status CHARACTER VARYING NOT NULL DEFAULT 'draft', -- 'draft', 'published', 'in_progress', 'completed'
    settings JSONB NOT NULL DEFAULT '{}'::jsonb, -- Cấu hình: { "default_bo": 3, "advance_per_lobby": 4, "tft_points": [8,7,6,5,4,3,2,1] }
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT brackets_pkey PRIMARY KEY (id),
    CONSTRAINT fk_brackets_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT chk_bracket_format CHECK (format IN ('single_elimination', 'double_elimination', 'round_robin', 'tft_lobbies', 'swiss')),
    CONSTRAINT chk_bracket_status CHECK (status IN ('draft', 'published', 'in_progress', 'completed'))
);

COMMENT ON TABLE public.brackets IS 'Cấu trúc các nhánh đấu hoặc giai đoạn thi đấu trong giải';

-- =============================================================================
-- 9. BẢNG bracket_rounds (Các Vòng thi đấu trong Nhánh)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.bracket_rounds (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    bracket_id UUID NOT NULL,
    round_number INTEGER NOT NULL, -- 1, 2, 3, 4...
    name CHARACTER VARYING NOT NULL, -- 'Vòng 1/16', 'Tứ kết', 'Bán kết', 'Chung kết', 'Lobby Round 1'
    bo_type INTEGER NOT NULL DEFAULT 1, -- BO1, BO3, BO5, BO7
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT bracket_rounds_pkey PRIMARY KEY (id),
    CONSTRAINT fk_rounds_bracket FOREIGN KEY (bracket_id) REFERENCES public.brackets(id) ON DELETE CASCADE
);

COMMENT ON TABLE public.bracket_rounds IS 'Các vòng đấu trong một nhánh (Vòng 1, Tứ kết, Bán kết...)';

-- =============================================================================
-- 10. BẢNG matches (Trận đấu / Phòng đấu TFT)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    bracket_id UUID NOT NULL,
    round_id UUID NOT NULL,
    match_code CHARACTER VARYING NOT NULL, -- Mã trận: 'M01', 'QF1', 'TFT-R1-L1'
    match_type CHARACTER VARYING NOT NULL DEFAULT 'head_to_head', -- 'head_to_head' (1v1), 'tft_lobby' (8 người)
    
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    
    status CHARACTER VARYING NOT NULL DEFAULT 'scheduled', -- 'scheduled', 'ready', 'in_progress', 'completed', 'cancelled'
    winner_registration_id UUID, -- Đội/người chiến thắng (đối với 1v1)
    
    -- Cây tiến trình nhánh đấu
    next_match_id UUID, -- Trận kế tiếp nhánh thắng
    loser_next_match_id UUID, -- Trận kế tiếp nhánh thua (Double Elimination)
    
    referee_id UUID, -- Trọng tài / CTV giám sát
    custom_room_info JSONB DEFAULT '{}'::jsonb, -- Thông tin phòng Custom (Room name, Pass, Link room)
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT matches_pkey PRIMARY KEY (id),
    CONSTRAINT fk_matches_bracket FOREIGN KEY (bracket_id) REFERENCES public.brackets(id) ON DELETE CASCADE,
    CONSTRAINT fk_matches_round FOREIGN KEY (round_id) REFERENCES public.bracket_rounds(id) ON DELETE CASCADE,
    CONSTRAINT fk_matches_winner FOREIGN KEY (winner_registration_id) REFERENCES public.registrations(id) ON DELETE SET NULL,
    CONSTRAINT fk_matches_next FOREIGN KEY (next_match_id) REFERENCES public.matches(id) ON DELETE SET NULL,
    CONSTRAINT fk_matches_loser_next FOREIGN KEY (loser_next_match_id) REFERENCES public.matches(id) ON DELETE SET NULL,
    CONSTRAINT fk_matches_referee FOREIGN KEY (referee_id) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_match_type CHECK (match_type IN ('head_to_head', 'tft_lobby')),
    CONSTRAINT chk_match_status CHECK (status IN ('scheduled', 'ready', 'in_progress', 'completed', 'cancelled', 'disputed'))
);

COMMENT ON TABLE public.matches IS 'Các trận đấu đối kháng 1v1 hoặc phòng thi đấu TFT nhiều người';

-- =============================================================================
-- 11. BẢNG match_participants (Đội/VĐV trong Trận đấu & Phòng TFT)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.match_participants (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL,
    registration_id UUID NOT NULL,
    
    slot_number INTEGER NOT NULL DEFAULT 1, -- Vị trí slot (1 hoặc 2 cho 1v1; 1..8 cho TFT)
    score INTEGER NOT NULL DEFAULT 0, -- Số ván thắng trong BO hoặc tổng điểm
    rank_position INTEGER, -- Thứ hạng trong phòng TFT (1 đến 8)
    is_winner BOOLEAN NOT NULL DEFAULT false,
    
    evidence_url TEXT, -- Ảnh chụp màn hình kết quả trận đấu làm bằng chứng
    points_awarded INTEGER NOT NULL DEFAULT 0, -- Điểm tích lũy được cộng
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT match_participants_pkey PRIMARY KEY (id),
    CONSTRAINT uq_match_participant UNIQUE (match_id, registration_id),
    CONSTRAINT fk_mp_match FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_mp_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE
);

COMMENT ON TABLE public.match_participants IS 'Danh sách người chơi / đội trong một trận đấu hoặc phòng đấu TFT';

-- =============================================================================
-- 12. BẢNG match_games (Chi tiết từng ván trong trận BO3/BO5)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.match_games (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL,
    game_number INTEGER NOT NULL, -- 1, 2, 3...
    duration_seconds INTEGER,
    winner_registration_id UUID,
    result_details JSONB DEFAULT '{}'::jsonb, -- Chi tiết MVP, tỉ số kill, bans/picks
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT match_games_pkey PRIMARY KEY (id),
    CONSTRAINT uq_match_game_number UNIQUE (match_id, game_number),
    CONSTRAINT fk_mg_match FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_mg_winner FOREIGN KEY (winner_registration_id) REFERENCES public.registrations(id) ON DELETE SET NULL
);

COMMENT ON TABLE public.match_games IS 'Chi tiết kết quả từng ván đấu của trận BO3/BO5';

-- =============================================================================
-- 13. BẢNG notifications (Thông báo hệ thống cho Sinh viên & Quản trị)
-- =============================================================================
-- 13. BẢNG check_ins (Điểm danh Ngày thi đấu - QR/GPS/Minh chứng)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.check_ins (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    registration_id UUID NOT NULL,
    participant_id TEXT NOT NULL,
    
    checkin_method CHARACTER VARYING NOT NULL DEFAULT 'qr_scan', -- 'qr_scan', 'proof_submission', 'ai_ocr', 'manual_admin'
    status CHARACTER VARYING NOT NULL DEFAULT 'approved', -- 'approved', 'pending_review', 'rejected'
    proof_url TEXT, -- Ảnh minh chứng nếu thí sinh submit ảnh
    
    -- Thu thập dữ liệu Geolocation & Device Fingerprint
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_accuracy DOUBLE PRECISION, -- mét
    ip_address CHARACTER VARYING,
    device_info TEXT, -- Trình duyệt, User-Agent, Fingerprint
    
    checked_in_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_by UUID, -- Admin hoặc CTV duyệt minh chứng / xác nhận AI OCR
    reviewed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    
    CONSTRAINT check_ins_pkey PRIMARY KEY (id),
    CONSTRAINT uq_tournament_participant_checkin UNIQUE (tournament_id, participant_id),
    CONSTRAINT fk_checkin_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_checkin_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_checkin_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_checkin_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_checkin_method CHECK (checkin_method IN ('qr_scan', 'proof_submission', 'ai_ocr', 'manual_admin')),
    CONSTRAINT chk_checkin_status CHECK (status IN ('approved', 'pending_review', 'rejected'))
);

COMMENT ON TABLE public.check_ins IS 'Điểm danh ngày thi đấu qua Quét QR kèm GPS, Submit ảnh minh chứng hoặc AI OCR';

-- =============================================================================
-- 14. BẢNG ai_checkin_sessions (Phiên phân tích AI Check-in Liên Quân Mobile)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.ai_checkin_sessions (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    match_id UUID,
    created_by UUID NOT NULL, -- CTV hoặc Admin tải ảnh lên
    source_type CHARACTER VARYING NOT NULL DEFAULT 'congdong_lienquan', -- 'congdong_lienquan', 'custom_lobby'
    status CHARACTER VARYING NOT NULL DEFAULT 'pending_review', -- 'processing', 'pending_review', 'confirmed', 'cancelled'
    total_detected INTEGER DEFAULT 0,
    total_matched INTEGER DEFAULT 0,
    image_purged BOOLEAN NOT NULL DEFAULT false, -- Đánh dấu ảnh tạm đã bị xóa vĩnh viễn
    confirmed_by UUID,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT ai_checkin_sessions_pkey PRIMARY KEY (id),
    CONSTRAINT fk_aics_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_aics_match FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE SET NULL,
    CONSTRAINT fk_aics_created_by FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_aics_confirmed_by FOREIGN KEY (confirmed_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_aics_source_type CHECK (source_type IN ('congdong_lienquan', 'custom_lobby')),
    CONSTRAINT chk_aics_status CHECK (status IN ('processing', 'pending_review', 'confirmed', 'cancelled'))
);

COMMENT ON TABLE public.ai_checkin_sessions IS 'Phiên phân tích nhận diện chữ xanh check-in Liên Quân Mobile qua AI';

-- =============================================================================
-- 15. BẢNG ai_checkin_detections (Chi tiết Bounding Box & Đề xuất Thí sinh Khớp)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.ai_checkin_detections (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL,
    raw_text TEXT NOT NULL, -- Text chữ xanh trích xuất
    ocr_confidence DOUBLE PRECISION, -- Độ tin cậy OCR (0.0 - 1.0)
    bounding_box JSONB DEFAULT '{}'::jsonb, -- Tọa độ khung chữ trên ảnh {x, y, w, h}
    matched_participant_id TEXT, -- Thí sinh hệ thống nhận diện khớp
    matched_registration_id UUID, -- Đội của thí sinh
    similarity_score DOUBLE PRECISION, -- Điểm tương đồng Fuzzy Match (0.0 - 1.0)
    is_manually_adjusted BOOLEAN NOT NULL DEFAULT false, -- Trọng tài đã sửa tay
    is_confirmed BOOLEAN NOT NULL DEFAULT true, -- Được chọn check-in
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT ai_checkin_detections_pkey PRIMARY KEY (id),
    CONSTRAINT fk_aicd_session FOREIGN KEY (session_id) REFERENCES public.ai_checkin_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_aicd_participant FOREIGN KEY (matched_participant_id) REFERENCES public.participants(id) ON DELETE SET NULL,
    CONSTRAINT fk_aicd_registration FOREIGN KEY (matched_registration_id) REFERENCES public.registrations(id) ON DELETE SET NULL
);

COMMENT ON TABLE public.ai_checkin_detections IS 'Chi tiết các vị trí chữ xanh và đề xuất thí sinh tương ứng';

-- =============================================================================
-- 16. BẢNG certificates (Giấy chứng nhận Điện tử E-Certificate Tự Động Cấp)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.certificates (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    participant_id TEXT NOT NULL,
    registration_id UUID NOT NULL,
    
    certificate_code CHARACTER VARYING NOT NULL UNIQUE, -- Mã tra cứu duy nhất: DUT-CERT-2026-TFT-08492
    title CHARACTER VARYING NOT NULL, -- 'Giấy Chứng Nhận Tham Gia Giải Đấu', 'Giấy Khen Vô Địch'
    achievement_title CHARACTER VARYING, -- 'Vô Địch', 'Á Quân', 'Top 4', 'Vận Động Viên'
    certificate_url TEXT NOT NULL, -- URL file PDF hoặc ảnh PNG kết xuất
    qr_verify_url TEXT, -- Link tra cứu xác thực công khai
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb, -- Thông tin snapshot lúc cấp (Họ tên, MSSV, Điểm)
    
    is_revoked BOOLEAN NOT NULL DEFAULT false, -- Trạng thái thu hồi nếu gian lận
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT certificates_pkey PRIMARY KEY (id),
    CONSTRAINT uq_tournament_participant_cert UNIQUE (tournament_id, participant_id),
    CONSTRAINT fk_cert_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_cert_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_cert_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE
);

COMMENT ON TABLE public.certificates IS 'Giấy chứng nhận điện tử tự động xuất cho thí sinh đã hoàn thành check-in';

-- =============================================================================
-- 15. BẢNG notifications (Thông báo hệ thống cho Sinh viên & Quản trị)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    recipient_type CHARACTER VARYING NOT NULL, -- 'user', 'participant'
    recipient_id TEXT NOT NULL, -- ID người nhận
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type CHARACTER VARYING NOT NULL, -- 'kyc_status', 'team_request', 'match_schedule', 'checkin_status', 'certificate_issued', 'system'
    metadata JSONB DEFAULT '{}'::jsonb, -- Link, ID trận, ID giải...
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT notifications_pkey PRIMARY KEY (id),
    CONSTRAINT chk_recipient_type CHECK (recipient_type IN ('user', 'participant'))
);

COMMENT ON TABLE public.notifications IS 'Hệ thống thông báo đẩy phục vụ kiến trúc Event-Driven';

-- =============================================================================
-- 16. BẢNG audit_logs (Nhật ký thao tác hệ thống)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    actor_id TEXT NOT NULL, -- User/Participant ID thực hiện hành động
    actor_role CHARACTER VARYING NOT NULL, -- 'admin', 'ctv', 'participant', 'system'
    action CHARACTER VARYING NOT NULL, -- 'APPROVE_STUDENT', 'CREATE_BRACKET', 'APPROVE_CHECKIN', 'ISSUE_CERTIFICATE'...
    target_table CHARACTER VARYING NOT NULL,
    target_id TEXT,
    payload JSONB DEFAULT '{}'::jsonb,
    ip_address CHARACTER VARYING,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT audit_logs_pkey PRIMARY KEY (id)
);

COMMENT ON TABLE public.audit_logs IS 'Nhật ký kiểm tra phục vụ bảo mật và audit hành vi quản trị';

-- =============================================================================
-- 17. THIẾT LẬP TẤT CẢ TRIGGERS TỰ ĐỘNG CẬP NHẬT updated_at
-- =============================================================================
DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_participants_updated_at ON public.participants;
CREATE TRIGGER trg_participants_updated_at BEFORE UPDATE ON public.participants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_tournaments_updated_at ON public.tournaments;
CREATE TRIGGER trg_tournaments_updated_at BEFORE UPDATE ON public.tournaments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_registrations_updated_at ON public.registrations;
CREATE TRIGGER trg_registrations_updated_at BEFORE UPDATE ON public.registrations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_team_join_requests_updated_at ON public.team_join_requests;
CREATE TRIGGER trg_team_join_requests_updated_at BEFORE UPDATE ON public.team_join_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_brackets_updated_at ON public.brackets;
CREATE TRIGGER trg_brackets_updated_at BEFORE UPDATE ON public.brackets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_matches_updated_at ON public.matches;
CREATE TRIGGER trg_matches_updated_at BEFORE UPDATE ON public.matches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 18. CHỈ MỤC TỐI ƯU HIỆU NĂNG TRUY VẤN (INDEXES)
-- =============================================================================
-- Participants
CREATE INDEX IF NOT EXISTS idx_participants_status ON public.participants(status);
CREATE INDEX IF NOT EXISTS idx_participants_student_id ON public.participants(student_id);
CREATE INDEX IF NOT EXISTS idx_participants_email ON public.participants(email);

-- Tournaments
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON public.tournaments(status);
CREATE INDEX IF NOT EXISTS idx_tournaments_code ON public.tournaments(code);
CREATE INDEX IF NOT EXISTS idx_tournaments_created_by ON public.tournaments(created_by);

-- Tournament Organizers
CREATE INDEX IF NOT EXISTS idx_to_tournament_id ON public.tournament_organizers(tournament_id);
CREATE INDEX IF NOT EXISTS idx_to_user_id ON public.tournament_organizers(user_id);

-- Registrations & Members
CREATE INDEX IF NOT EXISTS idx_registrations_tournament ON public.registrations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_registrations_captain ON public.registrations(captain_id);
CREATE INDEX IF NOT EXISTS idx_registrations_status ON public.registrations(status);
CREATE INDEX IF NOT EXISTS idx_registrations_recruiting ON public.registrations(is_recruiting) WHERE is_recruiting = true;
CREATE INDEX IF NOT EXISTS idx_rm_participant ON public.registration_members(participant_id);

-- Team Join Requests
CREATE INDEX IF NOT EXISTS idx_tjr_registration ON public.team_join_requests(registration_id);
CREATE INDEX IF NOT EXISTS idx_tjr_participant ON public.team_join_requests(participant_id);
CREATE INDEX IF NOT EXISTS idx_tjr_status ON public.team_join_requests(status);

-- Brackets, Rounds, Matches
CREATE INDEX IF NOT EXISTS idx_brackets_tournament ON public.brackets(tournament_id);
CREATE INDEX IF NOT EXISTS idx_bracket_rounds_bracket ON public.bracket_rounds(bracket_id);
CREATE INDEX IF NOT EXISTS idx_matches_bracket ON public.matches(bracket_id);
CREATE INDEX IF NOT EXISTS idx_matches_round ON public.matches(round_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status);
CREATE INDEX IF NOT EXISTS idx_mp_match ON public.match_participants(match_id);
CREATE INDEX IF NOT EXISTS idx_mp_registration ON public.match_participants(registration_id);
CREATE INDEX IF NOT EXISTS idx_mg_match ON public.match_games(match_id);

-- Check-ins
CREATE INDEX IF NOT EXISTS idx_checkins_tournament ON public.check_ins(tournament_id);
CREATE INDEX IF NOT EXISTS idx_checkins_participant ON public.check_ins(participant_id);
CREATE INDEX IF NOT EXISTS idx_checkins_status ON public.check_ins(status);
CREATE INDEX IF NOT EXISTS idx_checkins_method ON public.check_ins(checkin_method);

-- AI Check-in Sessions & Detections
CREATE INDEX IF NOT EXISTS idx_aics_tournament ON public.ai_checkin_sessions(tournament_id);
CREATE INDEX IF NOT EXISTS idx_aics_match ON public.ai_checkin_sessions(match_id);
CREATE INDEX IF NOT EXISTS idx_aics_status ON public.ai_checkin_sessions(status);
CREATE INDEX IF NOT EXISTS idx_aicd_session ON public.ai_checkin_detections(session_id);
CREATE INDEX IF NOT EXISTS idx_aicd_participant ON public.ai_checkin_detections(matched_participant_id);

-- Certificates
CREATE INDEX IF NOT EXISTS idx_certs_tournament ON public.certificates(tournament_id);
CREATE INDEX IF NOT EXISTS idx_certs_participant ON public.certificates(participant_id);
CREATE INDEX IF NOT EXISTS idx_certs_code ON public.certificates(certificate_code);

-- Notifications & Audit
CREATE INDEX IF NOT EXISTS idx_notif_recipient ON public.notifications(recipient_id, is_read);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON public.audit_logs(actor_id, action);
