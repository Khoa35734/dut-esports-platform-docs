# SCHEMA MISMATCH INVENTORY & CLASSIFICATION REPORT
## DUT ESPORTS TOURNAMENT PLATFORM

> **Authority:** SRS.md v1.1 Section 6.3 & 6.4 | Final Stakeholder Decisions (NSC-FOUND-001 to 005)
> **Task:** TASK-FOUND-001A
> **Date:** 2026-10-02
> **Classification Framework:**
> - `SRS_REQUIRED`: Column or table specified in SRS DDL / functional requirements that must be present.
> - `TECHNICAL_SUPPORT`: Technical infrastructure or column needed for operational runtime and EDA behavior (retained).
> - `LEGACY_UNUSED`: Deprecated or obsolete column/table not in SRS and safe to decommission after data verification.
> - `CONFLICTING`: Column, data type, or constraint that directly contradicts SRS invariants or canonical models.

---

## 1. Executive Summary

| Category | Table Count | Column / Constraint Items | Resolution Strategy |
|---|---|---|---|
| **SRS_REQUIRED (Missing in Schema)** | 3 tables | ~35 columns | Add via forward migration in TASK-FOUND-001B |
| **TECHNICAL_SUPPORT (Retained)** | 1 table (`notifications`) | ~12 columns | Retain as operational technical infrastructure (NSC-FOUND-003) |
| **LEGACY_UNUSED (Scheduled for Deprecation)** | 2 tables (`ai_checkin_*`) | ~8 columns | Mark DEPRECATED; quarantine and safely decommission (NSC-FOUND-003) |
| **CONFLICTING (Requires Migration)** | 6 tables | ~18 type / enum / PK mismatches | Align data types to UUID, fix CHECK constraints, unify users/participants (NSC-FOUND-001, 004, 005) |

---

## 2. Table-by-Table Inventory & Classification

### Table: `users`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `username` | `TEXT NOT NULL UNIQUE` | `VARCHAR(50) UNIQUE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `password_hash` | `CHARACTER VARYING NOT NULL` | `VARCHAR(255) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `full_name` | `CHARACTER VARYING NOT NULL` | `VARCHAR(100) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `email` | `TEXT UNIQUE` | `VARCHAR(254) UNIQUE NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `phone_number` (Extra) | `CHARACTER VARYING` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `role` | `CHARACTER VARYING NOT NULL DEFAULT 'ctv', -- 'admin', 'ctv'` | `VARCHAR(20) NOT NULL CHECK (role IN ('participant', 'admin', 'ctv', 'seasonal_staff'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `is_active` | `BOOLEAN NOT NULL DEFAULT true` | `BOOLEAN DEFAULT TRUE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `updated_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain for ORM/audit change tracking triggers. |
| `email_verified_at` (Missing) | *(None)* | `TIMESTAMP WITH TIME ZONE` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `last_login_at` (Missing) | *(None)* | `TIMESTAMP WITH TIME ZONE` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|
| `role` CHECK | `('admin', 'ctv')` | `('participant', 'admin', 'ctv', 'seasonal_staff')` | `CONFLICTING` | **RC-ENUM-001**: Align CHECK constraint to include all 4 canonical roles per SRS 6.4 & NSC-FOUND-001. |

---

### Table: `participants`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `TEXT NOT NULL, -- Mã SV hoặc UUID dạng text` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `CONFLICTING` | **RC-SCHEMA-001**: Type mismatch. Convert TEXT PK/FK to UUID using `gen_random_uuid()`. |
| `username` (Extra) | `TEXT` | *(None)* | `CONFLICTING` | NSC-FOUND-001: Drop username from participants; unified username resides in users table. |
| `password_hash` (Extra) | `TEXT NOT NULL` | *(None)* | `CONFLICTING` | NSC-FOUND-001: Drop password_hash from participants; authenticate exclusively via users.id. |
| `full_name` | `TEXT NOT NULL` | `VARCHAR(100) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `student_id` | `TEXT UNIQUE, -- Mã số sinh viên` | `VARCHAR(50) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `email` | `TEXT UNIQUE` | `VARCHAR(100) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `phone_number` (Extra) | `CHARACTER VARYING` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `university_name` | `CHARACTER VARYING` | `VARCHAR(150) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `faculty_name` (Extra) | `TEXT` | *(None)* | `LEGACY_UNUSED` | Legacy form fields not required by SRS. Maintain nullable or schedule for cleanup. |
| `class_name` (Extra) | `TEXT` | *(None)* | `LEGACY_UNUSED` | Legacy form fields not required by SRS. Maintain nullable or schedule for cleanup. |
| `account_type` | `TEXT NOT NULL DEFAULT 'external', -- 'internal' (DUT), 'external'` | `VARCHAR(20) NOT NULL CHECK (account_type IN ('internal', 'external'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `student_card_url` (Extra) | `TEXT, -- Ảnh mặt trước thẻ sinh viên` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `selfie_with_student_card_url` (Extra) | `TEXT, -- Ảnh chân dung và tay cầm thẻ sinh viên` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `status` (Extra) | `TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `approved_by` (Extra) | `TEXT, -- ID tài khoản duyệt` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `approved_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `rejection_reason` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `rejected_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `updated_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain for ORM/audit change tracking triggers. |
| `user_id` (Missing) | *(None)* | `UUID UNIQUE NOT NULL REFERENCES users(id)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `phone` (Missing) | *(None)* | `VARCHAR(20) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `kyc_status` (Missing) | *(None)* | `VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'approved', 'rejected'))` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `student_card_front_url` (Missing) | *(None)* | `VARCHAR(500) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `student_card_portrait_url` (Missing) | *(None)* | `VARCHAR(500) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `kyc_reviewed_by` (Missing) | *(None)* | `UUID REFERENCES users(id)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `kyc_rejected_reason` (Missing) | *(None)* | `TEXT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `tournaments`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `code` (Extra) | `CHARACTER VARYING NOT NULL UNIQUE, -- Mã định danh giải (VD: DUT-TFT-2026)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `name` (Extra) | `CHARACTER VARYING NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `game_name` (Extra) | `CHARACTER VARYING NOT NULL, -- 'TFT', 'Liên Quân Mobile', 'LMHT', 'Valorant'...` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `game_logo_url` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain: UI asset and dynamic registration support. |
| `banner_url` (Extra) | `TEXT NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain: UI asset and dynamic registration support. |
| `participation_type` (Extra) | `CHARACTER VARYING NOT NULL, -- 'individual', 'team'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `max_participants` | `INTEGER NOT NULL, -- Số lượng người chơi hoặc đội tối đa` | `INT CHECK (max_participants IS NULL OR max_participants >= COALESCE(min_participants, 1))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `min_team_size` | `INTEGER DEFAULT 1, -- Số thành viên tối thiểu/đội (VD: 5 cho LQ)` | `INT NOT NULL DEFAULT 1` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `max_team_size` | `INTEGER DEFAULT 1, -- Số thành viên tối đa/đội (VD: 7 cho LQ)` | `INT NOT NULL DEFAULT 1 CHECK (max_team_size >= min_team_size)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `registration_open_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `registration_close_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `start_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `end_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `checkin_open_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `checkin_close_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `checkin_qr_secret` (Extra) | `TEXT, -- Khóa sinh mã QR Check-in động cho BTC` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `certificate_template_url` | `TEXT, -- Mẫu phôi giấy chứng nhận điện tử (SVG/HTML/PNG)` | `VARCHAR(500)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `location` (Extra) | `TEXT, -- Địa điểm thi đấu (VD: Hội trường F, Cyber Game, Online Discord...)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `description` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `use_external_link` (Extra) | `BOOLEAN NOT NULL DEFAULT false` | *(None)* | `TECHNICAL_SUPPORT` | Retain: UI asset and dynamic registration support. |
| `external_registration_url` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain: UI asset and dynamic registration support. |
| `form_schema` | `JSONB NOT NULL DEFAULT '[]'::jsonb, -- Định nghĩa các trường động tùy biến` | `JSONB NOT NULL DEFAULT '{}'::jsonb` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `created_by` (Extra) | `UUID, -- CTV hoặc Admin tạo giải` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `approved_by` (Extra) | `UUID, -- Admin duyệt giải` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `status` | `CHARACTER VARYING NOT NULL DEFAULT 'pending'` | `VARCHAR(30) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'open_registration', 'closed_registration', 'ongoing', 'completed', 'cancelled'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `approved_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `updated_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain for ORM/audit change tracking triggers. |
| `title` (Missing) | *(None)* | `VARCHAR(200) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `game_category` (Missing) | *(None)* | `VARCHAR(50) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `min_participants` (Missing) | *(None)* | `INT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `registration_opens_at` (Missing) | *(None)* | `TIMESTAMPTZ` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `registration_closes_at` (Missing) | *(None)* | `TIMESTAMPTZ` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `checkin_opens_at` (Missing) | *(None)* | `TIMESTAMPTZ` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `checkin_closes_at` (Missing) | *(None)* | `TIMESTAMPTZ` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `event_starts_at` (Missing) | *(None)* | `TIMESTAMPTZ` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `event_ends_at` (Missing) | *(None)* | `TIMESTAMPTZ` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `checkin_lat` (Missing) | *(None)* | `DECIMAL(10,8)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `checkin_lng` (Missing) | *(None)* | `DECIMAL(11,8)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `geofence_radius_meters` (Missing) | *(None)* | `INT DEFAULT 100` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|
| `status` CHECK | `('draft', 'pending', 'approved', 'rejected', 'registration_opened', 'registration_closed', 'ongoing', 'completed', 'cancelled')` | `('draft', 'open_registration', 'closed_registration', 'ongoing', 'completed', 'cancelled')` | `CONFLICTING` | **RC-ENUM-002**: Align CHECK constraint to canonical tournament lifecycle states. |

---

### Table: `tournament_organizers`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `tournament_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `organizer_type` | `CHARACTER VARYING NOT NULL DEFAULT 'permanent', -- 'permanent' (CTV thường trực), 'seasonal' (CTV thời vụ)` | `VARCHAR(20) NOT NULL CHECK (organizer_type IN ('permanent', 'seasonal'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `user_id` | `UUID, -- Liên kết users (Admin/CTV thường trực)` | `UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `participant_id` (Extra) | `TEXT, -- Liên kết participants (Sinh viên làm CTV thời vụ)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `role` (Extra) | `CHARACTER VARYING NOT NULL DEFAULT 'co_organizer', -- 'lead_organizer', 'co_organizer', 'referee', 'seasonal_staff', 'support_staff'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `custom_title` (Extra) | `CHARACTER VARYING, -- Tên hiển thị vai trò (VD: 'CTV Điều phối & Điểm danh', 'Trọng tài bàn', 'Ban Kỹ thuật')` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `assigned_by` (Extra) | `UUID, -- Admin hoặc CTV thường trực phụ trách giải gán quyền` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `assigned_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `(organizer_type` (Extra) | `= 'seasonal' AND participant_id IS NOT NULL AND user_id IS NULL)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `role_title` (Missing) | *(None)* | `VARCHAR(50) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `registrations`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `tournament_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES tournaments(id)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `captain_id` | `TEXT NOT NULL, -- Đội trưởng hoặc cá nhân đăng ký` | `UUID NOT NULL REFERENCES participants(id)` | `CONFLICTING` | **RC-SCHEMA-001**: Type mismatch. Convert TEXT PK/FK to UUID using `gen_random_uuid()`. |
| `team_name` | `CHARACTER VARYING, -- Tên đội (áp dụng game đồng đội)` | `VARCHAR(100) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `team_avatar_url` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain: UI asset and dynamic registration support. |
| `ingame_id` (Extra) | `CHARACTER VARYING` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `is_recruiting` | `BOOLEAN NOT NULL DEFAULT false, -- Đang bật tuyển quân (VD: 4/7 người)` | `BOOLEAN NOT NULL DEFAULT FALSE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `recruitment_notes` (Extra) | `TEXT, -- Ghi chú tuyển vị trí (VD: Cần 1 Mid, 1 SP rank Cao thủ)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `submitted_data` (Extra) | `JSONB NOT NULL DEFAULT '{}'::jsonb, -- Dữ liệu các trường động` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `status` | `CHARACTER VARYING NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'cancelled'` | `VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `rejection_reason` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `reviewed_by` (Extra) | `UUID` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `reviewed_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `registered_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `updated_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain for ORM/audit change tracking triggers. |
| `seed_number` (Missing) | *(None)* | `INT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `recruiting_note` (Missing) | *(None)* | `TEXT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `form_data` (Missing) | *(None)* | `JSONB NOT NULL DEFAULT '{}'::jsonb` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `created_at` (Missing) | *(None)* | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|
| `status` CHECK | `('pending', 'approved', 'rejected', 'cancelled')` | `('pending', 'approved', 'rejected')` | `CONFLICTING` | **NSC-FOUND-005**: Remove 'cancelled' from CHECK constraint. |

---

### Table: `registration_members`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `registration_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES registrations(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `participant_id` | `TEXT NOT NULL` | `UUID NOT NULL REFERENCES participants(id)` | `CONFLICTING` | **RC-SCHEMA-001**: Type mismatch. Convert TEXT PK/FK to UUID using `gen_random_uuid()`. |
| `is_captain` (Extra) | `BOOLEAN NOT NULL DEFAULT false` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `ingame_id` (Extra) | `CHARACTER VARYING, -- Ingame ID chính xác của thành viên này` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `role_in_team` | `CHARACTER VARYING, -- Vị trí thi đấu: 'Top', 'Jungle', 'Mid', 'AD', 'SP', 'Sub'...` | `VARCHAR(50) DEFAULT 'member'` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `joined_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `id` (Missing) | *(None)* | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `team_join_requests`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `registration_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES registrations(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `participant_id` | `TEXT NOT NULL, -- Sinh viên muốn xin vào đội` | `UUID NOT NULL REFERENCES participants(id)` | `CONFLICTING` | **RC-SCHEMA-001**: Type mismatch. Convert TEXT PK/FK to UUID using `gen_random_uuid()`. |
| `ingame_id` (Extra) | `CHARACTER VARYING NOT NULL, -- Ingame ID của ứng viên` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `message` (Extra) | `TEXT, -- Lời nhắn / thông tin rank, lane sở trường` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `status` | `CHARACTER VARYING NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'cancelled'` | `VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `processed_by` (Extra) | `TEXT, -- Đội trưởng xử lý` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `processed_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `rejection_reason` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `updated_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain for ORM/audit change tracking triggers. |
| `desired_role` (Missing) | *(None)* | `VARCHAR(50)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|
| `status` CHECK | `('pending', 'accepted', 'rejected', 'cancelled')` | `('pending', 'accepted', 'rejected')` | `CONFLICTING` | **NSC-FOUND-004**: Remove 'cancelled' from CHECK constraint. |

---

### Table: `brackets`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `tournament_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `name` | `CHARACTER VARYING NOT NULL, -- 'Vòng loại', 'Vòng bảng', 'Playoffs Nhánh thắng - thua', 'TFT Vòng 1'` | `VARCHAR(100) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `format` (Extra) | `CHARACTER VARYING NOT NULL, -- 'single_elimination', 'double_elimination', 'round_robin', 'tft_lobbies'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `status` (Extra) | `CHARACTER VARYING NOT NULL DEFAULT 'draft', -- 'draft', 'published', 'in_progress', 'completed'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `settings` (Extra) | `JSONB NOT NULL DEFAULT '{}'::jsonb, -- Cấu hình: { "default_bo": 3, "advance_per_lobby": 4, "tft_points": [8,7,6,5,4,3,2,1] }` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `created_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `updated_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain for ORM/audit change tracking triggers. |
| `bracket_type` (Missing) | *(None)* | `VARCHAR(50) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `bracket_rounds`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `bracket_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES brackets(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `round_number` | `INTEGER NOT NULL, -- 1, 2, 3, 4...` | `INT NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `name` | `CHARACTER VARYING NOT NULL, -- 'Vòng 1/16', 'Tứ kết', 'Bán kết', 'Chung kết', 'Lobby Round 1'` | `VARCHAR(100) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `bo_type` (Extra) | `INTEGER NOT NULL DEFAULT 1, -- BO1, BO3, BO5, BO7` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `order_index` (Extra) | `INTEGER NOT NULL DEFAULT 0` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `created_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `matches`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `bracket_id` (Extra) | `UUID NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `round_id` (Extra) | `UUID NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `match_code` (Extra) | `CHARACTER VARYING NOT NULL, -- Mã trận: 'M01', 'QF1', 'TFT-R1-L1'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `match_type` (Extra) | `CHARACTER VARYING NOT NULL DEFAULT 'head_to_head', -- 'head_to_head' (1v1), 'tft_lobby' (8 người)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `scheduled_at` | `TIMESTAMP WITH TIME ZONE` | `TIMESTAMP WITH TIME ZONE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `started_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `ended_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `status` | `CHARACTER VARYING NOT NULL DEFAULT 'scheduled', -- 'scheduled', 'ready', 'in_progress', 'completed', 'cancelled'` | `VARCHAR(20) NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `winner_registration_id` (Extra) | `UUID, -- Đội/người chiến thắng (đối với 1v1)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `next_match_id` (Extra) | `UUID, -- Trận kế tiếp nhánh thắng` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `loser_next_match_id` | `UUID, -- Trận kế tiếp nhánh thua (Double Elimination)` | `UUID REFERENCES matches(id)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `referee_id` (Extra) | `UUID, -- Trọng tài / CTV giám sát` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `custom_room_info` (Extra) | `JSONB DEFAULT '{}'::jsonb, -- Thông tin phòng Custom (Room name, Pass, Link room)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `notes` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `created_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `updated_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain for ORM/audit change tracking triggers. |
| `bracket_round_id` (Missing) | *(None)* | `UUID NOT NULL REFERENCES bracket_rounds(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `match_order` (Missing) | *(None)* | `INT NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `bo_format` (Missing) | *(None)* | `VARCHAR(10) NOT NULL DEFAULT 'BO1'` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `winner_next_match_id` (Missing) | *(None)* | `UUID REFERENCES matches(id)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `winner_next_slot` (Missing) | *(None)* | `SMALLINT CHECK (winner_next_slot IN (1,2))` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `loser_next_slot` (Missing) | *(None)* | `SMALLINT CHECK (loser_next_slot IN (1,2))` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|
| `status` CHECK | `('scheduled', 'ready', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled')` | `('scheduled', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled')` | `CONFLICTING` | **RC-ENUM-003**: Remove 'ready' from match status CHECK constraint. |

---

### Table: `match_participants`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `match_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `registration_id` | `UUID NOT NULL` | `UUID REFERENCES registrations(id)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `slot_number` (Extra) | `INTEGER NOT NULL DEFAULT 1, -- Vị trí slot (1 hoặc 2 cho 1v1; 1..8 cho TFT)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `score` | `INTEGER NOT NULL DEFAULT 0, -- Số ván thắng trong BO hoặc tổng điểm` | `INT DEFAULT 0` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `rank_position` (Extra) | `INTEGER, -- Thứ hạng trong phòng TFT (1 đến 8)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `is_winner` (Extra) | `BOOLEAN NOT NULL DEFAULT false` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `evidence_url` (Extra) | `TEXT, -- Ảnh chụp màn hình kết quả trận đấu làm bằng chứng` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `points_awarded` (Extra) | `INTEGER NOT NULL DEFAULT 0, -- Điểm tích lũy được cộng` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `created_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `participant_id` (Missing) | *(None)* | `UUID REFERENCES participants(id)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `rank_placement` (Missing) | *(None)* | `INT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `result` (Missing) | *(None)* | `VARCHAR(20) CHECK (result IN ('win', 'loss', 'draw', 'pending'))` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `match_games`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `match_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `game_number` | `INTEGER NOT NULL, -- 1, 2, 3...` | `INT NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `duration_seconds` | `INTEGER` | `INT` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `winner_registration_id` | `UUID` | `UUID REFERENCES registrations(id)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `result_details` (Extra) | `JSONB DEFAULT '{}'::jsonb, -- Chi tiết MVP, tỉ số kill, bans/picks` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `created_at` (Extra) | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `winner_participant_id` (Missing) | *(None)* | `UUID REFERENCES participants(id)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `game_metadata` (Missing) | *(None)* | `JSONB DEFAULT '{}'::jsonb` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `notes` (Missing) | *(None)* | `TEXT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `check_ins`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `tournament_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES tournaments(id)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `registration_id` (Extra) | `UUID NOT NULL` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `participant_id` | `TEXT NOT NULL` | `UUID NOT NULL REFERENCES participants(id)` | `CONFLICTING` | **RC-SCHEMA-001**: Type mismatch. Convert TEXT PK/FK to UUID using `gen_random_uuid()`. |
| `checkin_method` (Extra) | `CHARACTER VARYING NOT NULL DEFAULT 'qr_scan', -- 'qr_scan', 'proof_submission', 'ai_ocr', 'manual_admin'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `status` | `CHARACTER VARYING NOT NULL DEFAULT 'approved', -- 'approved', 'pending_review', 'rejected'` | `VARCHAR(20) NOT NULL DEFAULT 'pending_review' CHECK (status IN ('approved', 'rejected', 'pending_review'))` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `proof_url` (Extra) | `TEXT, -- Ảnh minh chứng nếu thí sinh submit ảnh` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `latitude` | `DOUBLE PRECISION` | `DECIMAL(10,8)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `longitude` | `DOUBLE PRECISION` | `DECIMAL(11,8)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `location_accuracy` (Extra) | `DOUBLE PRECISION, -- mét` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `ip_address` | `CHARACTER VARYING` | `VARCHAR(45)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `device_info` (Extra) | `TEXT, -- Trình duyệt, User-Agent, Fingerprint` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `checked_in_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `reviewed_by` | `UUID, -- Admin hoặc CTV duyệt minh chứng / xác nhận AI OCR` | `UUID REFERENCES users(id)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `reviewed_at` (Extra) | `TIMESTAMP WITH TIME ZONE` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `notes` (Extra) | `TEXT` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `method` (Missing) | *(None)* | `VARCHAR(30) NOT NULL CHECK (method IN ('qr_scan', 'proof_submission', 'manual_admin'))` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `qr_token_id` (Missing) | *(None)* | `UUID` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `distance_meters` (Missing) | *(None)* | `DECIMAL(8,2)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `user_agent` (Missing) | *(None)* | `TEXT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `gps_accuracy_meters` (Missing) | *(None)* | `DECIMAL(8,2)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `proof_image_url` (Missing) | *(None)* | `VARCHAR(500)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `ai_checkin_sessions`

**Status:** EXTRA TABLE IN EXISTING SCHEMA (`LEGACY_UNUSED`)

**Classification Rationale:** Deprecated per NSC-FOUND-003. Scheduled for safe removal after verifying no active dependencies.

| Column | Existing Definition | Classification | Action |
|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `tournament_id` | `UUID NOT NULL` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `match_id` | `UUID` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `created_by` | `UUID NOT NULL, -- CTV hoặc Admin tải ảnh lên` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `source_type` | `CHARACTER VARYING NOT NULL DEFAULT 'congdong_lienquan', -- 'congdong_lienquan', 'custom_lobby'` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `status` | `CHARACTER VARYING NOT NULL DEFAULT 'pending_review', -- 'processing', 'pending_review', 'confirmed', 'cancelled'` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `total_detected` | `INTEGER DEFAULT 0` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `total_matched` | `INTEGER DEFAULT 0` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `image_purged` | `BOOLEAN NOT NULL DEFAULT false, -- Đánh dấu ảnh tạm đã bị xóa vĩnh viễn` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `confirmed_by` | `UUID` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `confirmed_at` | `TIMESTAMP WITH TIME ZONE` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `LEGACY_UNUSED` | Quarantine / Deprecate |

---

### Table: `ai_checkin_detections`

**Status:** EXTRA TABLE IN EXISTING SCHEMA (`LEGACY_UNUSED`)

**Classification Rationale:** Deprecated per NSC-FOUND-003. Scheduled for safe removal after verifying no active dependencies.

| Column | Existing Definition | Classification | Action |
|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `session_id` | `UUID NOT NULL` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `raw_text` | `TEXT NOT NULL, -- Text chữ xanh trích xuất` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `ocr_confidence` | `DOUBLE PRECISION, -- Độ tin cậy OCR (0.0 - 1.0)` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `bounding_box` | `JSONB DEFAULT '{}'::jsonb, -- Tọa độ khung chữ trên ảnh {x, y, w, h}` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `matched_participant_id` | `TEXT, -- Thí sinh hệ thống nhận diện khớp` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `matched_registration_id` | `UUID, -- Đội của thí sinh` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `similarity_score` | `DOUBLE PRECISION, -- Điểm tương đồng Fuzzy Match (0.0 - 1.0)` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `is_manually_adjusted` | `BOOLEAN NOT NULL DEFAULT false, -- Trọng tài đã sửa tay` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `is_confirmed` | `BOOLEAN NOT NULL DEFAULT true, -- Được chọn check-in` | `LEGACY_UNUSED` | Quarantine / Deprecate |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `LEGACY_UNUSED` | Quarantine / Deprecate |

---

### Table: `certificates`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `tournament_id` | `UUID NOT NULL` | `UUID NOT NULL REFERENCES tournaments(id)` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `certificate_type` (Extra) | `CHARACTER VARYING NOT NULL DEFAULT 'participant', -- 'participant', 'organizer'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `participant_id` | `TEXT NOT NULL, -- Sinh viên nhận chứng chỉ (VĐV hoặc CTV thời vụ)` | `UUID REFERENCES participants(id)` | `CONFLICTING` | **RC-SCHEMA-001**: Type mismatch. Convert TEXT PK/FK to UUID using `gen_random_uuid()`. |
| `registration_id` (Extra) | `UUID, -- Đơn đăng ký thi đấu (Bắt buộc với VĐV, NULL với CTV)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `organizer_id` (Extra) | `UUID, -- Liên kết vị trí trong ban tổ chức (Dành cho CTV thời vụ / BTC)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `certificate_code` | `CHARACTER VARYING NOT NULL UNIQUE, -- Mã tra cứu duy nhất: DUT-CERT-2026-TFT-08492` | `VARCHAR(64) UNIQUE NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `title` | `CHARACTER VARYING NOT NULL, -- 'Giấy Chứng Nhận Tham Gia Giải Đấu', 'Giấy Chứng Nhận Ban Tổ Chức', 'Giấy Khen Vô Địch'` | `VARCHAR(150) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `achievement_title` (Extra) | `CHARACTER VARYING, -- 'Vô Địch', 'Á Quân', 'Top 4', 'Vận Động Viên', 'Cộng Tác Viên Tổ Chức', 'Trọng Tài Giải Đấu'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `certificate_url` (Extra) | `TEXT NOT NULL, -- URL file PDF hoặc ảnh PNG kết xuất` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `qr_verify_url` (Extra) | `TEXT, -- Link tra cứu xác thực công khai` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `metadata` (Extra) | `JSONB NOT NULL DEFAULT '{}'::jsonb, -- Thông tin snapshot lúc cấp (Họ tên, MSSV, Điểm/Vai trò)` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `is_revoked` (Extra) | `BOOLEAN NOT NULL DEFAULT false, -- Trạng thái thu hồi nếu gian lận` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `issued_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `(certificate_type` (Extra) | `= 'organizer')` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `recipient_type` (Missing) | *(None)* | `VARCHAR(20) NOT NULL CHECK (recipient_type IN ('athlete', 'organizer'))` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `user_id` (Missing) | *(None)* | `UUID REFERENCES users(id)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `rank_placement` (Missing) | *(None)* | `INT` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `public_name_allowed` (Missing) | *(None)* | `BOOLEAN NOT NULL DEFAULT FALSE` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `pdf_file_url` (Missing) | *(None)* | `VARCHAR(500) NOT NULL` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `(recipient_type` (Missing) | *(None)* | `= 'organizer' AND user_id IS NOT NULL AND participant_id IS NULL)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `notifications`

**Status:** EXTRA TABLE IN EXISTING SCHEMA (`TECHNICAL_SUPPORT`)

**Classification Rationale:** Retained per NSC-FOUND-003 as technical infrastructure supporting SRS notification behavior.

| Column | Existing Definition | Classification | Action |
|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `TECHNICAL_SUPPORT` | Retain in database |
| `recipient_type` | `CHARACTER VARYING NOT NULL, -- 'user', 'participant'` | `TECHNICAL_SUPPORT` | Retain in database |
| `recipient_id` | `TEXT NOT NULL, -- ID người nhận` | `TECHNICAL_SUPPORT` | Retain in database |
| `title` | `TEXT NOT NULL` | `TECHNICAL_SUPPORT` | Retain in database |
| `message` | `TEXT NOT NULL` | `TECHNICAL_SUPPORT` | Retain in database |
| `type` | `CHARACTER VARYING NOT NULL, -- 'kyc_status', 'team_request', 'match_schedule', 'checkin_status', 'certificate_issued', 'system'` | `TECHNICAL_SUPPORT` | Retain in database |
| `metadata` | `JSONB DEFAULT '{}'::jsonb, -- Link, ID trận, ID giải...` | `TECHNICAL_SUPPORT` | Retain in database |
| `is_read` | `BOOLEAN NOT NULL DEFAULT false` | `TECHNICAL_SUPPORT` | Retain in database |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TECHNICAL_SUPPORT` | Retain in database |

---

### Table: `audit_logs`

**Status:** PRESENT IN BOTH (Mismatches Analyzed Below)

| Column / Attribute | Existing Schema | SRS 6.4 DDL | Classification | Analysis & Recommended Migration Action |
|---|---|---|---|---|
| `id` | `UUID NOT NULL DEFAULT uuid_generate_v4()` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `actor_id` (Extra) | `TEXT NOT NULL, -- User/Participant ID thực hiện hành động` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `actor_role` (Extra) | `CHARACTER VARYING NOT NULL, -- 'admin', 'ctv', 'participant', 'system'` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `action` | `CHARACTER VARYING NOT NULL, -- 'APPROVE_STUDENT', 'CREATE_BRACKET', 'APPROVE_CHECKIN', 'ISSUE_CERTIFICATE', 'ADD_SEASONAL_STAFF'...` | `VARCHAR(50) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `target_table` | `CHARACTER VARYING NOT NULL` | `VARCHAR(50) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `target_id` | `TEXT` | `UUID` | `CONFLICTING` | **RC-SCHEMA-001**: Type mismatch. Convert TEXT PK/FK to UUID using `gen_random_uuid()`. |
| `payload` (Extra) | `JSONB DEFAULT '{}'::jsonb` | *(None)* | `TECHNICAL_SUPPORT` | Retain as supplementary runtime metadata. |
| `ip_address` | `CHARACTER VARYING` | `VARCHAR(45) NOT NULL` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `created_at` | `TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP` | `TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Matches intent. Align exact type/length if needed. |
| `user_id` (Missing) | *(None)* | `UUID REFERENCES users(id)` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `old_values` (Missing) | *(None)* | `JSONB` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |
| `new_values` (Missing) | *(None)* | `JSONB` | `SRS_REQUIRED` | Add missing column via migration in TASK-FOUND-001B. |

**Constraints & Enum Values:**

| Constraint Type | Existing Schema | SRS 6.4 DDL | Classification | Notes |
|---|---|---|---|---|

---

### Table: `auth_tokens`

**Status:** MISSING IN EXISTING SCHEMA (`SRS_REQUIRED`)

This table is defined in SRS 6.4 DDL but does not exist in `database_schema.sql`.

| Column / Constraint | SRS Definition | Classification | Recommended Action |
|---|---|---|---|
| `id` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Create table in forward migration |
| `user_id` | `UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Create table in forward migration |
| `token_hash` | `VARCHAR(128) UNIQUE NOT NULL` | `SRS_REQUIRED` | Create table in forward migration |
| `purpose` | `VARCHAR(30) NOT NULL CHECK (purpose IN ('email_verify', 'password_reset'))` | `SRS_REQUIRED` | Create table in forward migration |
| `expires_at` | `TIMESTAMPTZ NOT NULL` | `SRS_REQUIRED` | Create table in forward migration |
| `used_at` | `TIMESTAMPTZ` | `SRS_REQUIRED` | Create table in forward migration |
| `created_at` | `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Create table in forward migration |

---

### Table: `checkin_qr_tokens`

**Status:** MISSING IN EXISTING SCHEMA (`SRS_REQUIRED`)

This table is defined in SRS 6.4 DDL but does not exist in `database_schema.sql`.

| Column / Constraint | SRS Definition | Classification | Recommended Action |
|---|---|---|---|
| `id` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Create table in forward migration |
| `tournament_id` | `UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE` | `SRS_REQUIRED` | Create table in forward migration |
| `token_hash` | `VARCHAR(128) UNIQUE NOT NULL` | `SRS_REQUIRED` | Create table in forward migration |
| `issued_at` | `TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Create table in forward migration |
| `expires_at` | `TIMESTAMPTZ NOT NULL` | `SRS_REQUIRED` | Create table in forward migration |
| `revoked_at` | `TIMESTAMPTZ` | `SRS_REQUIRED` | Create table in forward migration |

---

### Table: `report_exports`

**Status:** MISSING IN EXISTING SCHEMA (`SRS_REQUIRED`)

This table is defined in SRS 6.4 DDL but does not exist in `database_schema.sql`.

| Column / Constraint | SRS Definition | Classification | Recommended Action |
|---|---|---|---|
| `id` | `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | `SRS_REQUIRED` | Create table in forward migration |
| `requested_by` | `UUID NOT NULL REFERENCES users(id)` | `SRS_REQUIRED` | Create table in forward migration |
| `idempotency_key` | `UUID NOT NULL` | `SRS_REQUIRED` | Create table in forward migration |
| `tournament_id` | `UUID REFERENCES tournaments(id)` | `SRS_REQUIRED` | Create table in forward migration |
| `report_type` | `VARCHAR(40) NOT NULL` | `SRS_REQUIRED` | Create table in forward migration |
| `status` | `VARCHAR(20) NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'expired'))` | `SRS_REQUIRED` | Create table in forward migration |
| `file_url` | `VARCHAR(500)` | `SRS_REQUIRED` | Create table in forward migration |
| `expires_at` | `TIMESTAMPTZ` | `SRS_REQUIRED` | Create table in forward migration |
| `error_code` | `VARCHAR(50)` | `SRS_REQUIRED` | Create table in forward migration |
| `created_at` | `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP` | `SRS_REQUIRED` | Create table in forward migration |
| `completed_at` | `TIMESTAMPTZ` | `SRS_REQUIRED` | Create table in forward migration |
| Constraint | `UNIQUE (requested_by, idempotency_key)` | `SRS_REQUIRED` | Apply constraint in migration |

---

## 3. Migration Roadmap for Phase 0 (Foundation)

Based on this inventory, the execution plan for schema reconciliation is structured as follows:

1. **TASK-FOUND-001A (Current Task):** Complete inventory and classification (this document).
2. **TASK-FOUND-001B:** Author forward migration `001_reconcile_srs_schema.sql`:
   - Create missing tables: `auth_tokens`, `checkin_qr_tokens`, `report_exports`.
   - Add `user_id UUID REFERENCES users(id)` to `participants`.
   - Convert all `TEXT` primary keys and foreign keys referencing `participants(id)` to `UUID`.
   - Update CHECK constraints for `users.role`, `tournaments.status`, `registrations.status`, `team_join_requests.status`, `matches.status`.
   - Add missing SRS columns (`tournaments.checkin_lat`, `tournaments.checkin_lng`, `participants.kyc_status`, etc.).
3. **TASK-FOUND-001C:** Update backend repository queries and TypeScript types in `Web-giai-dau/backend/src/types/` and `repositories/`.
4. **TASK-FOUND-001D:** Update authentication controller & service to route all user logins through `users` table.
5. **TASK-FOUND-001E:** Deprecate legacy AI tables (`ai_checkin_sessions`, `ai_checkin_detections`) without data loss.
6. **TASK-FOUND-001F:** Run end-to-end schema migration test & regression verification.

