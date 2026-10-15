-- =============================================================================
-- DUT ESPORTS TOURNAMENT PLATFORM - DATABASE SCHEMA
-- Hệ quản trị cơ sở dữ liệu: PostgreSQL (13+) / Supabase
-- Phiên bản: 2.0 (Reconciled with SRS 6.4 DDL & Final Stakeholder Decisions NSC-FOUND-001 to 005)
-- Quy chuẩn Invariants: Zero CCCD, UUID Primary Keys, Unified Users Identity
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
-- 1. BẢNG users (Tài khoản Toàn hệ thống — Định danh hợp nhất)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(254) UNIQUE,
    phone_number VARCHAR(20),
    email_verified_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    role VARCHAR(20) NOT NULL DEFAULT 'participant', -- 'participant', 'admin', 'ctv', 'seasonal_staff'
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT chk_user_role CHECK (role IN ('participant', 'admin', 'ctv', 'seasonal_staff'))
);

COMMENT ON TABLE public.users IS 'Tài khoản người dùng toàn hệ thống (Admin, CTV thường trực, CTV thời vụ, Sinh viên)';
COMMENT ON COLUMN public.users.role IS 'Vai trò: admin, ctv (thường trực), seasonal_staff (thời vụ), participant (vận động viên)';

-- =============================================================================
-- 2. BẢNG participants (Hồ sơ Sinh viên / KYC — Liên kết 1:1 với users.id, ZERO CCCD)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.participants (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL, -- Liên kết 1:1 với users (NSC-FOUND-001)
    student_id VARCHAR(50) NOT NULL, -- Mã số sinh viên
    full_name VARCHAR(100) NOT NULL,
    university_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(20) NOT NULL DEFAULT 'external', -- 'internal' (DUT), 'external'
    phone VARCHAR(20),
    email VARCHAR(100),
    
    -- Hồ sơ xác thực KYC Sinh viên (CHỈ DÙNG 2 ẢNH THẺ SV - TUYỆT ĐỐI KHÔNG CCCD)
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    student_card_front_url VARCHAR(500), -- Ảnh mặt trước thẻ sinh viên
    student_card_portrait_url VARCHAR(500), -- Ảnh chân dung cầm thẻ sinh viên
    kyc_reviewed_by UUID, -- ID người duyệt (users.id)
    kyc_rejected_reason TEXT,
    
    -- Trường kỹ thuật bổ trợ (TECHNICAL_SUPPORT)
    faculty_name TEXT,
    class_name TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT participants_pkey PRIMARY KEY (id),
    CONSTRAINT fk_participants_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_participants_reviewer FOREIGN KEY (kyc_reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_participant_kyc_status CHECK (kyc_status IN ('pending', 'approved', 'rejected')),
    CONSTRAINT chk_participant_account_type CHECK (account_type IN ('internal', 'external'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_participant_student ON public.participants(student_id, university_name);

COMMENT ON TABLE public.participants IS 'Hồ sơ KYC sinh viên tham gia thi đấu (Liên kết 1:1 với users, Zero CCCD)';
COMMENT ON COLUMN public.participants.student_card_front_url IS 'Ảnh chụp mặt trước thẻ sinh viên';
COMMENT ON COLUMN public.participants.student_card_portrait_url IS 'Ảnh chụp chân dung cầm thẻ sinh viên';

-- =============================================================================
-- 3. BẢNG tournaments (Giải đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.tournaments (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE, -- Mã định danh giải (VD: DUT-TFT-2026)
    title VARCHAR(200) NOT NULL,
    game_category VARCHAR(50) NOT NULL, -- 'TFT', 'Liên Quân Mobile', 'LMHT', 'Valorant'...
    status VARCHAR(30) NOT NULL DEFAULT 'draft', -- 'draft', 'open_registration', 'closed_registration', 'ongoing', 'completed', 'cancelled'
    
    min_participants INT,
    max_participants INT,
    min_team_size INT NOT NULL DEFAULT 1,
    max_team_size INT NOT NULL DEFAULT 1,
    
    registration_opens_at TIMESTAMP WITH TIME ZONE,
    registration_closes_at TIMESTAMP WITH TIME ZONE,
    checkin_opens_at TIMESTAMP WITH TIME ZONE,
    checkin_closes_at TIMESTAMP WITH TIME ZONE,
    event_starts_at TIMESTAMP WITH TIME ZONE,
    event_ends_at TIMESTAMP WITH TIME ZONE,
    
    -- Cấu hình Check-in Geofencing & QR Code
    checkin_lat DECIMAL(10,8),
    checkin_lng DECIMAL(11,8),
    geofence_radius_meters INT DEFAULT 100,
    checkin_qr_secret TEXT,
    
    -- Form tùy biến & Phôi chứng nhận
    form_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
    certificate_template_url VARCHAR(500),
    
    -- Trường giao diện bổ trợ (TECHNICAL_SUPPORT)
    banner_url TEXT,
    game_logo_url TEXT,
    location TEXT,
    description TEXT,
    use_external_link BOOLEAN NOT NULL DEFAULT false,
    external_registration_url TEXT,
    
    created_by UUID,
    approved_by UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT tournaments_pkey PRIMARY KEY (id),
    CONSTRAINT tournaments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT tournaments_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_tournament_status CHECK (status IN ('draft', 'open_registration', 'closed_registration', 'ongoing', 'completed', 'cancelled'))
);

COMMENT ON TABLE public.tournaments IS 'Bảng thông tin các giải đấu esports và cấu hình geofence';

-- =============================================================================
-- 4. BẢNG tournament_organizers (Phân quyền Ban tổ chức & CTV)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.tournament_organizers (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    user_id UUID, -- Liên kết users (Admin/CTV thường trực)
    participant_id UUID, -- Liên kết participants (Sinh viên làm CTV thời vụ)
    organizer_type VARCHAR(20) NOT NULL DEFAULT 'permanent', -- 'permanent', 'seasonal'
    role VARCHAR(50) NOT NULL DEFAULT 'co_organizer', -- 'lead_organizer', 'co_organizer', 'referee', 'seasonal_staff', 'support_staff'
    custom_title VARCHAR(100), -- Tên vai trò hiển thị trên chứng chỉ
    assigned_by UUID,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT tournament_organizers_pkey PRIMARY KEY (id),
    CONSTRAINT fk_to_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_to_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_to_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_to_assigned_by FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_organizer_type CHECK (organizer_type IN ('permanent', 'seasonal')),
    CONSTRAINT chk_organizer_target CHECK (
        (organizer_type = 'permanent' AND user_id IS NOT NULL AND participant_id IS NULL) OR
        (organizer_type = 'seasonal' AND participant_id IS NOT NULL AND user_id IS NULL)
    ),
    CONSTRAINT chk_organizer_role CHECK (role IN ('lead_organizer', 'co_organizer', 'referee', 'seasonal_staff', 'support_staff'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_to_user ON public.tournament_organizers(tournament_id, user_id) WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_to_participant ON public.tournament_organizers(tournament_id, participant_id) WHERE participant_id IS NOT NULL;

-- =============================================================================
-- 5. BẢNG registrations (Đơn đăng ký tham gia giải đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.registrations (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    captain_id UUID NOT NULL, -- Đội trưởng hoặc cá nhân đăng ký (UUID)
    team_name VARCHAR(100) NOT NULL,
    team_avatar_url TEXT,
    ingame_id VARCHAR(100),
    is_recruiting BOOLEAN NOT NULL DEFAULT false,
    recruitment_notes TEXT,
    seed_number INT,
    submitted_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected' (BỎ CANCELLED)
    rejection_reason TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    registered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT registrations_pkey PRIMARY KEY (id),
    CONSTRAINT registrations_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT registrations_captain_id_fkey FOREIGN KEY (captain_id) REFERENCES public.participants(id) ON DELETE RESTRICT,
    CONSTRAINT registrations_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT chk_registration_status CHECK (status IN ('pending', 'approved', 'rejected'))
);

-- =============================================================================
-- 6. BẢNG registration_members (Danh sách thành viên đội)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.registration_members (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    registration_id UUID NOT NULL,
    participant_id UUID NOT NULL,
    is_captain BOOLEAN NOT NULL DEFAULT false,
    ingame_id VARCHAR(100),
    role_in_team VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT registration_members_pkey PRIMARY KEY (id),
    CONSTRAINT fk_rm_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_rm_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE RESTRICT,
    CONSTRAINT uq_reg_member UNIQUE (registration_id, participant_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_registration_member_per_tournament 
    ON public.registration_members(participant_id, registration_id);

-- =============================================================================
-- 7. BẢNG team_join_requests (Yêu cầu xin gia nhập đội tuyển quân)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.team_join_requests (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    registration_id UUID NOT NULL,
    participant_id UUID NOT NULL,
    ingame_id VARCHAR(100) NOT NULL,
    message TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'rejected' (BỎ CANCELLED)
    processed_by UUID,
    processed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT team_join_requests_pkey PRIMARY KEY (id),
    CONSTRAINT fk_tjr_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_tjr_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tjr_processed_by FOREIGN KEY (processed_by) REFERENCES public.participants(id) ON DELETE SET NULL,
    CONSTRAINT chk_tjr_status CHECK (status IN ('pending', 'accepted', 'rejected')),
    CONSTRAINT uq_tjr_registration_participant UNIQUE (registration_id, participant_id)
);

-- =============================================================================
-- 8. BẢNG brackets (Nhánh đấu / Giai đoạn giải đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.brackets (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    bracket_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT brackets_pkey PRIMARY KEY (id),
    CONSTRAINT fk_brackets_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE
);

-- =============================================================================
-- 9. BẢNG bracket_rounds (Vòng thi đấu trong nhánh)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.bracket_rounds (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    bracket_id UUID NOT NULL,
    round_number INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT bracket_rounds_pkey PRIMARY KEY (id),
    CONSTRAINT fk_rounds_bracket FOREIGN KEY (bracket_id) REFERENCES public.brackets(id) ON DELETE CASCADE
);

-- =============================================================================
-- 10. BẢNG matches (Trận đấu / Phòng đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    bracket_round_id UUID NOT NULL,
    match_order INT NOT NULL,
    bo_format VARCHAR(10) NOT NULL DEFAULT 'BO1',
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled', 
    -- 'scheduled', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled' (BỎ READY)
    scheduled_at TIMESTAMP WITH TIME ZONE,
    winner_next_match_id UUID,
    loser_next_match_id UUID,
    winner_next_slot SMALLINT CHECK (winner_next_slot IN (1, 2)),
    loser_next_slot SMALLINT CHECK (loser_next_slot IN (1, 2)),
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT matches_pkey PRIMARY KEY (id),
    CONSTRAINT fk_matches_round FOREIGN KEY (bracket_round_id) REFERENCES public.bracket_rounds(id) ON DELETE CASCADE,
    CONSTRAINT fk_matches_winner_next FOREIGN KEY (winner_next_match_id) REFERENCES public.matches(id) ON DELETE SET NULL,
    CONSTRAINT fk_matches_loser_next FOREIGN KEY (loser_next_match_id) REFERENCES public.matches(id) ON DELETE SET NULL,
    CONSTRAINT chk_match_status CHECK (status IN ('scheduled', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled')),
    CONSTRAINT uq_round_match_order UNIQUE (bracket_round_id, match_order)
);

-- =============================================================================
-- 11. BẢNG match_participants (Thí sinh / Đội tham gia trận)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.match_participants (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL,
    registration_id UUID,
    participant_id UUID,
    score INT DEFAULT 0,
    rank_placement INT,
    result VARCHAR(20) CHECK (result IN ('win', 'loss', 'draw', 'pending')),
    
    CONSTRAINT match_participants_pkey PRIMARY KEY (id),
    CONSTRAINT fk_mp_match FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_mp_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_mp_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT chk_match_subject CHECK (
        (registration_id IS NOT NULL AND participant_id IS NULL) OR 
        (registration_id IS NULL AND participant_id IS NOT NULL)
    )
);

-- =============================================================================
-- 12. BẢNG match_games (Chi tiết từng ván trong trận BO)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.match_games (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL,
    game_number INT NOT NULL,
    winner_registration_id UUID,
    winner_participant_id UUID,
    duration_seconds INT,
    game_metadata JSONB DEFAULT '{}'::jsonb,
    notes TEXT,
    
    CONSTRAINT match_games_pkey PRIMARY KEY (id),
    CONSTRAINT fk_mg_match FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_mg_winner_reg FOREIGN KEY (winner_registration_id) REFERENCES public.registrations(id) ON DELETE SET NULL,
    CONSTRAINT fk_mg_winner_part FOREIGN KEY (winner_participant_id) REFERENCES public.participants(id) ON DELETE SET NULL,
    CONSTRAINT chk_game_winner CHECK (winner_registration_id IS NULL OR winner_participant_id IS NULL),
    CONSTRAINT uq_match_game_number UNIQUE (match_id, game_number)
);

-- =============================================================================
-- 13. BẢNG check_ins (Điểm danh ngày thi đấu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.check_ins (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    participant_id UUID NOT NULL,
    method VARCHAR(30) NOT NULL CHECK (method IN ('qr_scan', 'proof_submission', 'manual_admin')),
    qr_token_id UUID,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    distance_meters DECIMAL(8,2),
    ip_address VARCHAR(45),
    user_agent TEXT,
    gps_accuracy_meters DECIMAL(8,2),
    proof_image_url VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'pending_review' CHECK (status IN ('approved', 'rejected', 'pending_review')),
    reviewed_by UUID REFERENCES public.users(id),
    checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_ins_pkey PRIMARY KEY (id),
    CONSTRAINT fk_ci_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_ci_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT uq_checkin_per_participant UNIQUE (tournament_id, participant_id)
);

-- =============================================================================
-- 14. BẢNG checkin_qr_tokens (Mã QR động xoay vòng 30s)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.checkin_qr_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
    token_hash VARCHAR(128) UNIQUE NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ
);

ALTER TABLE public.check_ins ADD CONSTRAINT fk_checkin_qr_token 
    FOREIGN KEY (qr_token_id) REFERENCES public.checkin_qr_tokens(id) ON DELETE SET NULL;

-- =============================================================================
-- 15. BẢNG certificates (Giấy chứng nhận điện tử)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_code VARCHAR(64) UNIQUE NOT NULL,
    tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
    recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('athlete', 'organizer')),
    participant_id UUID REFERENCES public.participants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    rank_placement INT,
    public_name_allowed BOOLEAN NOT NULL DEFAULT FALSE,
    pdf_file_url VARCHAR(500) NOT NULL,
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_cert_recipient CHECK (
        (recipient_type = 'athlete' AND participant_id IS NOT NULL AND user_id IS NULL) OR
        (recipient_type = 'organizer' AND user_id IS NOT NULL AND participant_id IS NULL)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_certificate_athlete 
    ON public.certificates(tournament_id, participant_id) WHERE recipient_type = 'athlete';

CREATE UNIQUE INDEX IF NOT EXISTS uq_certificate_organizer 
    ON public.certificates(tournament_id, user_id) WHERE recipient_type = 'organizer';

-- =============================================================================
-- 16. BẢNG auth_tokens (Mã xác thực email & Đặt lại mật khẩu)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.auth_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token_hash VARCHAR(128) UNIQUE NOT NULL,
    purpose VARCHAR(30) NOT NULL CHECK (purpose IN ('email_verify', 'password_reset')),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 17. BẢNG report_exports (Tác vụ xuất báo cáo bất đồng bộ)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.report_exports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requested_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    idempotency_key UUID NOT NULL,
    tournament_id UUID REFERENCES public.tournaments(id) ON DELETE SET NULL,
    report_type VARCHAR(40) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'expired')),
    file_url VARCHAR(500),
    expires_at TIMESTAMPTZ,
    error_code VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    UNIQUE (requested_by, idempotency_key)
);

-- =============================================================================
-- 18. BẢNG audit_logs (Nhật ký kiểm toán — Bất biến APPEND-ONLY)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    target_table VARCHAR(50) NOT NULL,
    target_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 19. BẢNG notifications (Hạ tầng kỹ thuật hỗ trợ thông báo thời gian thực — NSC-FOUND-003)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'system',
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 20. BẢNG ai_checkin_sessions & ai_checkin_detections (DEPRECATED — NSC-FOUND-003)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.ai_checkin_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.ai_checkin_detections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.ai_checkin_sessions(id) ON DELETE CASCADE,
    detected_text TEXT,
    similarity_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
