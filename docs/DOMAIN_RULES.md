# DOMAIN RULES — DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md v1.1 | database_schema.sql v1.1
> **Last Updated:** 2026-09-29

All domain identifiers below are stable internal references.

---

## DOMAIN-USER-001 — User Account

**Entity:** `users`
**Purpose:** Single sign-on account for all human actors (Admin, CTV Thường trực, CTV Thời vụ, Sinh viên/VĐV).

**Fields relevant to business logic:**
| Field | Meaning |
|---|---|
| `role` | Enumerated: `participant`, `admin`, `ctv`, `seasonal_staff` |
| `is_active` | Account lock/unlock; locked accounts cannot log in |
| `email_verified_at` | NULL = unverified; unverified accounts cannot register for tournaments |
| `password_hash` | Argon2id or bcrypt cost ≥ 12; never returned in any API response |

**Relationships:**
- One-to-one → `participants` (athlete profile)
- One-to-many → `tournament_organizers` (staff assignments)
- One-to-many → `auth_tokens` (one-time verification/reset tokens)
- One-to-many → `audit_logs` (actor reference)

**Allowed states:**
- `is_active = true` / `is_active = false`
- `email_verified_at IS NULL` / `email_verified_at IS NOT NULL`

**Invariants:**
- Email is globally unique and immutable for login identity.
- Password hash MUST NOT appear in any API response or log.
- Max 5 failed login attempts per account per 15 minutes → rate-limit.
- Session expires after 30 min inactivity or 12 hours absolute.

**Related requirements:** FR-AUTH-01, NFR-SEC-06

---

## DOMAIN-PARTICIPANT-001 — Participant (KYC Profile)

**Entity:** `participants`
**Purpose:** Athlete/student KYC profile linked one-to-one to a `users` record.

**Fields relevant to business logic:**
| Field | Meaning |
|---|---|
| `kyc_status` | `pending` / `approved` / `rejected` |
| `account_type` | `internal` (DUT students) / `external` (other universities) |
| `student_card_front_url` | Required KYC image 1 — front of student card |
| `student_card_portrait_url` | Required KYC image 2 — selfie holding student card |
| `kyc_reviewed_by` | FK to `users(id)` — CTV/Admin who reviewed |
| `university_name` | From Admin-managed canonical list; used in UNIQUE(student_id, university_name) |

**Relationships:**
- One-to-one ← `users`
- One-to-many → `registrations` (as captain)
- One-to-many → `registration_members`
- One-to-many → `team_join_requests`
- One-to-many → `check_ins`
- One-to-many → `certificates` (athlete type)

**Allowed states (kyc_status):**
```
pending → approved (by CTV/Admin)
pending → rejected (by CTV/Admin, reason required)
rejected → pending (re-submission allowed)
```

**Invariants:**
- ZERO CCCD/CMND fields permitted anywhere in this entity.
- Exactly 2 images required: student card front + selfie holding card.
- Each image ≤ 5MB; formats: .jpg, .jpeg, .png only.
- UNIQUE(student_id, university_name) across the system.
- Only `kyc_status = 'approved'` participants may register for tournaments.
- KYC images stored in private storage; accessible only via time-limited signed URLs (max 5 min) to CTV/Admin.

**Related requirements:** FR-KYC-01, FR-KYC-02, FR-KYC-03, FR-KYC-04, NFR-SEC-01, NFR-SEC-02

---

## DOMAIN-TOURNAMENT-001 — Tournament

**Entity:** `tournaments`
**Purpose:** Central configuration for each esports tournament event.

**Fields relevant to business logic:**
| Field | Meaning |
|---|---|
| `status` | Tournament lifecycle state |
| `format` | `single_elimination` / `double_elimination` / `tft_rooms` / `other` |
| `form_schema` | JSONB — game-specific registration fields |
| `geofence_radius_meters` | Default 100m; configurable before check-in opens |
| `checkin_lat`, `checkin_lng` | Venue center for GPS validation |
| `certificate_template_url` | Template for E-Certificate rendering |

**Relationships:**
- One-to-many → `tournament_organizers`
- One-to-many → `registrations`
- One-to-many → `brackets`
- One-to-many → `check_ins`
- One-to-many → `certificates`
- One-to-many → `checkin_qr_tokens`
- One-to-many → `report_exports`

**Allowed states:**
```
draft
 → open_registration  (Admin/CTV, prerequisites met)
 → cancelled          (Admin)
open_registration
 → closed_registration (Admin/CTV or auto at deadline)
 → cancelled          (Admin)
closed_registration
 → ongoing            (Admin/CTV)
 → cancelled          (Admin)
ongoing
 → completed          (Admin)
 → cancelled          (Admin)
completed            [terminal — triggers certificate worker]
cancelled            [terminal]
```

**Invariants (must be configured before open_registration):**
- Must have: game_category, format, min/max participants, min/max team_size, registration window.
- If GPS check-in is enabled: checkin_lat, checkin_lng, geofence_radius_meters must be set.
- Registrations are blocked once status ≠ `open_registration`.
- Only Admin/CTV Thường trực may transition tournament status.

**Related requirements:** FR-TRN-01, FR-TRN-02

---

## DOMAIN-REGISTRATION-001 — Registration

**Entity:** `registrations`
**Purpose:** Team or individual competition entry for a tournament.

**Fields relevant to business logic:**
| Field | Meaning |
|---|---|
| `status` | `pending` / `approved` / `rejected` |
| `is_recruiting` | Flag that exposes this team on the public recruitment board |
| `captain_id` | FK participants — team captain or individual competitor |
| `form_data` | JSONB — tournament-specific ingame data |

**Relationships:**
- Many-to-one → `tournaments`
- Many-to-one (captain) → `participants`
- One-to-many → `registration_members`
- One-to-many → `team_join_requests`
- One-to-many → `match_participants`

**Invariants:**
- Captain must have `kyc_status = 'approved'`.
- A participant cannot be captain of two registrations in the same tournament.
- `is_recruiting` may only be `true` if team size < `max_team_size` and registration is open.
- When team reaches `max_team_size`, `is_recruiting` must be set to `false`.
- UNIQUE(tournament_id, team_name).

**Related requirements:** FR-TRN-02, FR-TEAM-01, FR-TEAM-03

---

## DOMAIN-CHECKIN-001 — Check-in

**Entity:** `check_ins`
**Purpose:** Records attendance verification for each participant at a tournament venue.

**Fields relevant to business logic:**
| Field | Meaning |
|---|---|
| `method` | `qr_scan` / `proof_submission` / `manual_admin` |
| `status` | `approved` / `pending_review` / `rejected` |
| `latitude`, `longitude` | GPS coordinates submitted by device |
| `distance_meters` | Computed distance from venue center |
| `gps_accuracy_meters` | Device-reported GPS accuracy |
| `proof_image_url` | Fallback image proof |
| `reviewed_by` | FK users — CTV/Admin who manually approved |

**Relationships:**
- Many-to-one → `tournaments`
- Many-to-one → `participants`
- Many-to-one → `checkin_qr_tokens`

**Allowed states:**
```
qr_scan path:
  submitted → approved  (auto, if GPS within geofence)
  submitted → rejected  (auto, GPS outside geofence or invalid token)

proof_submission path:
  submitted → pending_review (auto)
  pending_review → approved  (CTV/Admin manual review)
  pending_review → rejected  (CTV/Admin manual review)

manual_admin path:
  submitted → approved  (Admin override, audited)
```

**Invariants:**
- UNIQUE(tournament_id, participant_id) — one check-in record per participant per tournament.
- QR token: random, hash-stored only, expires 30 seconds, tournament-scoped, replay by same participant rejected.
- GPS accepted only if distance ≤ geofence_radius_meters AND gps_accuracy_meters ≤ 100.
- Server determines IP address; client-submitted IP must not be trusted.
- Device metadata (IP, User-Agent) collected for fraud detection only; access is restricted.
- Every manual approval/rejection records `reviewed_by` and is audited.

**Related requirements:** FR-CHK-01, FR-CHK-02, FR-CHK-03, FR-CHK-04, FR-CHK-05

---

## DOMAIN-CERTIFICATE-001 — E-Certificate

**Entity:** `certificates`
**Purpose:** Digital certificate issued to eligible athletes and tournament organizers.

**Fields relevant to business logic:**
| Field | Meaning |
|---|---|
| `certificate_code` | Globally unique, non-sequential hash code for public verification |
| `recipient_type` | `athlete` / `organizer` |
| `participant_id` | Set when recipient_type = 'athlete' |
| `user_id` | Set when recipient_type = 'organizer' |
| `public_name_allowed` | Consent flag; if false, name not shown on public verify portal |
| `rank_placement` | Finalized placement for achievement printing |
| `is_revoked` | Revocation flag for fraud cases |

**Relationships:**
- Many-to-one → `tournaments`
- Many-to-one → `participants` (athlete type)
- Many-to-one → `users` (organizer type)

**Invariants:**
- Exactly one of `participant_id` or `user_id` is set (enforced by CHECK constraint).
- Worker is idempotent: UNIQUE(tournament_id, participant_id) for athlete type, UNIQUE(tournament_id, user_id) for organizer type.
- Triggered by `tournament.completed` event; runs asynchronously.
- Eligible athletes: `check_ins.status = 'approved'` for that tournament.
- Eligible organizers: all records in `tournament_organizers` for that tournament.
- Public verify portal: shows name only if `public_name_allowed = true`; NEVER shows email, phone, student_id, or KYC images.
- Certificates retained 5 years or per CLB policy.

**Related requirements:** FR-CRT-01, FR-CRT-02, FR-CRT-03, FR-CRT-04, FR-CRT-05

---

## DOMAIN-BRACKET-001 — Bracket & Match System

**Entities:** `brackets`, `bracket_rounds`, `matches`, `match_participants`, `match_games`
**Purpose:** Manages the competition structure, scheduling, and result tracking.

**Bracket formats:**
- `single_elimination`
- `double_elimination`
- `round_robin`
- `tft_lobbies`
- `swiss`

**Match statuses:**
```
scheduled → in_progress → awaiting_confirmation → completed
                        → disputed              → completed (after Admin/CTV resolution)
         → cancelled
```

**TFT Room Algorithm (FR-TRN-04):**
Given N players, find m such that ceil(N/8) ≤ m ≤ floor(N/7).
- If valid m exists: choose m = ceil(N/8) (fewest rooms)
  - Rooms of 8 players: N − 7m
  - Rooms of 7 players: 8m − N
- If no valid m: DO NOT create rooms; report reason to BTC.
- Test cases: N=8→1×8; N=14→2×7; N=16→2×8; N=17→reject; N=22→1×8+2×7; N=25→reject
- All rooms created in a single DB transaction; any failure → full rollback.

**Double Elimination invariants:**
- `next_match_id` (winner path) and `loser_next_match_id` (loser path) must be configured before bracket is published.
- `winner_next_slot` and `loser_next_slot` (1 or 2) must be set.
- Disputed match status does NOT advance bracket automatically.

**Bye handling:**
- Byes recorded explicitly; team receiving bye advances without counting as a BO win.

**Result modification:**
- Finalized results can only be modified by Admin.
- All result changes, status changes, and the actor are recorded in `audit_logs`.

**Related requirements:** FR-TRN-03, FR-TRN-04, FR-TRN-05

---

## DOMAIN-REPORT-001 — Report Export

**Entity:** `report_exports`
**Purpose:** Tracks asynchronous report generation tasks.

**States:**
```
queued → processing → completed → [file available for 24h]
                   → failed
completed → expired (after expires_at)
```

**Invariants:**
- UNIQUE(requested_by, idempotency_key) — prevents duplicate tasks.
- Worker reads data in cursor/batch mode; peak RAM ≤ 256 MiB for 10,000-row CSV.
- File is private; download URL is signed with max 5-minute validity.
- CTV reports always have PII masked (phone: `090****123`, email: `ngu***@gmail.com`).
- Admin reports receive full unmasked data.
- CTV can only export data for tournaments they are assigned to.
- Rate limit: max 10 export requests per minute per account.

**Related requirements:** FR-REP-01, FR-REP-02, FR-REP-03

---

## DOMAIN-AUDIT-001 — Audit Log

**Entity:** `audit_logs`
**Purpose:** Append-only tamper-evident log of all sensitive data operations.

**Invariants:**
- INSERT and SELECT only; UPDATE/DELETE/TRUNCATE permissions REVOKED for all application roles.
- Must capture: `actor_id`, `action`, `target_table`, `target_id`, `old_values`, `new_values`, `ip_address`, `created_at`.
- Retained for 24 months.

**Audited events (minimum):**
- KYC approve/reject
- Manual check-in approve/reject
- Match result change
- Bracket reconfiguration
- Report export
- Tournament status change
- Staff assignment/revocation

**Related requirements:** FR-AUD-01, FR-AUD-02
