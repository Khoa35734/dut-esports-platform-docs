-- =============================================================================
-- DUT ESPORTS PLATFORM - MIGRATION SCRIPT (NÂNG CẤP TỪ DATABASE HIỆN TẠI)
-- Dành cho database đã có sẵn các bảng users, participants, tournaments, registrations, registration_members
-- =============================================================================

BEGIN;

-- 1. XÓA BỎ HOÀN TOÀN CÁC CỘT CCCD TRONG BẢNG participants
ALTER TABLE public.participants DROP COLUMN IF EXISTS cccd_number;
ALTER TABLE public.participants DROP COLUMN IF EXISTS cccd_front_url;
ALTER TABLE public.participants DROP COLUMN IF EXISTS cccd_back_url;

-- Đảm bảo có đầy đủ 2 cột thẻ SV
ALTER TABLE public.participants ADD COLUMN IF NOT EXISTS student_card_url TEXT;
ALTER TABLE public.participants ADD COLUMN IF NOT EXISTS selfie_with_student_card_url TEXT;

-- 2. CẬP NHẬT BẢNG registrations (Thêm Ingame ID & Tuyển quân)
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS ingame_id CHARACTER VARYING;
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS is_recruiting BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS recruitment_notes TEXT;
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;

-- 3. CẬP NHẬT BẢNG registration_members (Thêm Ingame ID & Vị trí thi đấu)
ALTER TABLE public.registration_members ADD COLUMN IF NOT EXISTS ingame_id CHARACTER VARYING;
ALTER TABLE public.registration_members ADD COLUMN IF NOT EXISTS role_in_team CHARACTER VARYING;

-- 4. TẠO BẢNG tournament_organizers (Đồng tổ chức giải đấu)
CREATE TABLE IF NOT EXISTS public.tournament_organizers (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role CHARACTER VARYING NOT NULL DEFAULT 'co_organizer',
    assigned_by UUID,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tournament_organizers_pkey PRIMARY KEY (id),
    CONSTRAINT uq_tournament_user UNIQUE (tournament_id, user_id),
    CONSTRAINT fk_to_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_to_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_to_assigned_by FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL
);

-- 5. TẠO BẢNG team_join_requests (Xin vào đội)
CREATE TABLE IF NOT EXISTS public.team_join_requests (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    registration_id UUID NOT NULL,
    participant_id TEXT NOT NULL,
    ingame_id CHARACTER VARYING NOT NULL,
    message TEXT,
    status CHARACTER VARYING NOT NULL DEFAULT 'pending',
    processed_by TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT team_join_requests_pkey PRIMARY KEY (id),
    CONSTRAINT fk_tjr_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_tjr_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tjr_processed_by FOREIGN KEY (processed_by) REFERENCES public.participants(id) ON DELETE SET NULL
);

-- 6. TẠO HỆ THỐNG BẢNG NHÁNH ĐẤU & TRẬN ĐẤU (Brackets & Matches)
CREATE TABLE IF NOT EXISTS public.brackets (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    name CHARACTER VARYING NOT NULL,
    format CHARACTER VARYING NOT NULL,
    status CHARACTER VARYING NOT NULL DEFAULT 'draft',
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT brackets_pkey PRIMARY KEY (id),
    CONSTRAINT fk_brackets_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.bracket_rounds (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    bracket_id UUID NOT NULL,
    round_number INTEGER NOT NULL,
    name CHARACTER VARYING NOT NULL,
    bo_type INTEGER NOT NULL DEFAULT 1,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT bracket_rounds_pkey PRIMARY KEY (id),
    CONSTRAINT fk_rounds_bracket FOREIGN KEY (bracket_id) REFERENCES public.brackets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.matches (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    bracket_id UUID NOT NULL,
    round_id UUID NOT NULL,
    match_code CHARACTER VARYING NOT NULL,
    match_type CHARACTER VARYING NOT NULL DEFAULT 'head_to_head',
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    status CHARACTER VARYING NOT NULL DEFAULT 'scheduled',
    winner_registration_id UUID,
    next_match_id UUID,
    loser_next_match_id UUID,
    referee_id UUID,
    custom_room_info JSONB DEFAULT '{}'::jsonb,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT matches_pkey PRIMARY KEY (id),
    CONSTRAINT fk_matches_bracket FOREIGN KEY (bracket_id) REFERENCES public.brackets(id) ON DELETE CASCADE,
    CONSTRAINT fk_matches_round FOREIGN KEY (round_id) REFERENCES public.bracket_rounds(id) ON DELETE CASCADE,
    CONSTRAINT fk_matches_winner FOREIGN KEY (winner_registration_id) REFERENCES public.registrations(id) ON DELETE SET NULL,
    CONSTRAINT fk_matches_next FOREIGN KEY (next_match_id) REFERENCES public.matches(id) ON DELETE SET NULL,
    CONSTRAINT fk_matches_loser_next FOREIGN KEY (loser_next_match_id) REFERENCES public.matches(id) ON DELETE SET NULL,
    CONSTRAINT fk_matches_referee FOREIGN KEY (referee_id) REFERENCES public.users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.match_participants (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL,
    registration_id UUID NOT NULL,
    slot_number INTEGER NOT NULL DEFAULT 1,
    score INTEGER NOT NULL DEFAULT 0,
    rank_position INTEGER,
    is_winner BOOLEAN NOT NULL DEFAULT false,
    evidence_url TEXT,
    points_awarded INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT match_participants_pkey PRIMARY KEY (id),
    CONSTRAINT uq_match_participant UNIQUE (match_id, registration_id),
    CONSTRAINT fk_mp_match FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_mp_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.match_games (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL,
    game_number INTEGER NOT NULL,
    duration_seconds INTEGER,
    winner_registration_id UUID,
    result_details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT match_games_pkey PRIMARY KEY (id),
    CONSTRAINT uq_match_game_number UNIQUE (match_id, game_number),
    CONSTRAINT fk_mg_match FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE,
    CONSTRAINT fk_mg_winner FOREIGN KEY (winner_registration_id) REFERENCES public.registrations(id) ON DELETE SET NULL
);

-- 7. CẬP NHẬT BẢNG tournaments (Cấu hình Check-in & Chứng nhận)
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS checkin_open_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS checkin_close_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS checkin_qr_secret TEXT;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS certificate_template_url TEXT;

-- 8. TẠO BẢNG check_ins (Điểm danh Ngày thi đấu - QR/GPS/Minh chứng)
CREATE TABLE IF NOT EXISTS public.check_ins (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    registration_id UUID NOT NULL,
    participant_id TEXT NOT NULL,
    checkin_method CHARACTER VARYING NOT NULL DEFAULT 'qr_scan',
    status CHARACTER VARYING NOT NULL DEFAULT 'approved',
    proof_url TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_accuracy DOUBLE PRECISION,
    ip_address CHARACTER VARYING,
    device_info TEXT,
    checked_in_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    CONSTRAINT check_ins_pkey PRIMARY KEY (id),
    CONSTRAINT uq_tournament_participant_checkin UNIQUE (tournament_id, participant_id),
    CONSTRAINT fk_checkin_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_checkin_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE,
    CONSTRAINT fk_checkin_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE
);

-- 9. TẠO BẢNG certificates (Giấy chứng nhận Điện tử E-Certificate Tự Động Cấp)
CREATE TABLE IF NOT EXISTS public.certificates (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL,
    participant_id TEXT NOT NULL,
    registration_id UUID NOT NULL,
    certificate_code CHARACTER VARYING NOT NULL UNIQUE,
    title CHARACTER VARYING NOT NULL,
    achievement_title CHARACTER VARYING,
    certificate_url TEXT NOT NULL,
    qr_verify_url TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_revoked BOOLEAN NOT NULL DEFAULT false,
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT certificates_pkey PRIMARY KEY (id),
    CONSTRAINT uq_tournament_participant_cert UNIQUE (tournament_id, participant_id),
    CONSTRAINT fk_cert_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE,
    CONSTRAINT fk_cert_participant FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_cert_registration FOREIGN KEY (registration_id) REFERENCES public.registrations(id) ON DELETE CASCADE
);

-- 10. TẠO BẢNG notifications & audit_logs
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    recipient_type CHARACTER VARYING NOT NULL,
    recipient_id TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type CHARACTER VARYING NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT notifications_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    actor_id TEXT NOT NULL,
    actor_role CHARACTER VARYING NOT NULL,
    action CHARACTER VARYING NOT NULL,
    target_table CHARACTER VARYING NOT NULL,
    target_id TEXT,
    payload JSONB DEFAULT '{}'::jsonb,
    ip_address CHARACTER VARYING,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT audit_logs_pkey PRIMARY KEY (id)
);

COMMIT;
