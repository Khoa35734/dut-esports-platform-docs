# BUSINESS RULES — DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md v1.1
> **Last Updated:** 2026-09-29

Do NOT implement any business rule not listed here. If a new rule is needed, it must be added to the SRS first.

---

## BR-AUTH-001
**Name:** Email Verification Before Tournament Registration
**Description:** A user account must have a verified email before being able to register for any tournament.
**Trigger:** User attempts to register for a tournament.
**Preconditions:** User is logged in.
**Rule:** If `users.email_verified_at IS NULL`, block registration and return 403.
**Result:** Registration blocked; user directed to verify email.
**Exceptions:** None.
**Affected entities:** `users`, `registrations`
**Affected roles:** participant
**Source:** FR-AUTH-01

---

## BR-AUTH-002
**Name:** One-Time Token Expiry
**Description:** Email verification and password reset tokens are single-use and expire after 30 minutes.
**Trigger:** User submits a verification or reset token.
**Preconditions:** Token exists in `auth_tokens`.
**Rule:** If `expires_at < NOW()` OR `used_at IS NOT NULL`, reject and return 400.
**Result:** Token rejected; user must request a new token.
**Exceptions:** None.
**Affected entities:** `auth_tokens`
**Affected roles:** participant, ctv, admin, seasonal_staff
**Source:** FR-AUTH-01, NFR-SEC-06

---

## BR-AUTH-003
**Name:** Login Rate Limiting
**Description:** After 5 consecutive failed login attempts for an account within 15 minutes, further attempts are blocked.
**Trigger:** Login attempt.
**Preconditions:** Account exists.
**Rule:** Track failed attempts per account. Block after threshold; return 429.
**Result:** Account temporarily locked; rate limit persists for 15-minute window.
**Exceptions:** Admin manual unlock via `is_active = false → true`.
**Affected entities:** `users`
**Affected roles:** All
**Source:** NFR-SEC-06

---

## BR-KYC-001
**Name:** Dual Image KYC Requirement
**Description:** KYC submission requires exactly 2 images: (1) student card front, (2) selfie holding student card.
**Trigger:** Participant submits KYC form.
**Preconditions:** User account exists and is email-verified.
**Rule:** Both images must be present, ≤ 5MB each, format in [jpg, jpeg, png]. Reject if either is missing.
**Result:** KYC record created with `kyc_status = 'pending'`; tournament registration blocked.
**Exceptions:** None.
**Affected entities:** `participants`
**Affected roles:** participant
**Source:** FR-KYC-01

---

## BR-KYC-002
**Name:** CCCD/CMND Absolute Prohibition
**Description:** Under no circumstances shall any CCCD/CMND number or image be collected, stored, or processed.
**Trigger:** Any data collection flow.
**Preconditions:** N/A.
**Rule:** No field, form element, API parameter, or database column may accept CCCD/CMND data.
**Result:** Any such field discovered must be immediately removed.
**Exceptions:** None.
**Affected entities:** All
**Affected roles:** All
**Source:** NFR-SEC-01, SRS 1.2, SRS 9.3

---

## BR-KYC-003
**Name:** KYC Status Controls Tournament Access
**Description:** Only participants with `kyc_status = 'approved'` may register for tournaments.
**Trigger:** Participant attempts tournament registration or team join.
**Preconditions:** Participant record exists.
**Rule:** If `kyc_status != 'approved'`, reject registration with 403.
**Result:** Access denied until KYC is approved.
**Exceptions:** None.
**Affected entities:** `participants`, `registrations`
**Affected roles:** participant
**Source:** FR-KYC-01, FR-KYC-03

---

## BR-KYC-004
**Name:** KYC Image Access Control
**Description:** KYC images are accessible only to CTV Thường trực and Admin via time-limited signed URLs.
**Trigger:** Any request to view KYC images.
**Preconditions:** User is authenticated.
**Rule:** Generate signed URL with max 5-minute validity. Direct static path access returns 403.
**Result:** Controlled access with full audit trail.
**Exceptions:** None.
**Affected entities:** `participants` (image URLs)
**Affected roles:** ctv (assigned), admin
**Source:** FR-KYC-04, NFR-SEC-02

---

## BR-KYC-005
**Name:** Account Type Classification
**Description:** Participants are automatically classified as internal (DUT) or external based on their university name.
**Trigger:** KYC profile creation.
**Preconditions:** Participant selects university from Admin-managed canonical list.
**Rule:** If university = 'Đại học Bách khoa Đà Nẵng' → `account_type = 'internal'`; else → `account_type = 'external'`.
**Result:** `account_type` stored and used for team composition rules.
**Exceptions:** Admin may update the canonical university list.
**Affected entities:** `participants`
**Affected roles:** participant (submission), admin (university list management)
**Source:** FR-KYC-02

---

## BR-TEAM-001
**Name:** Recruitment Flag Rules
**Description:** A team may only set `is_recruiting = true` if current member count < `max_team_size` and registration is still open.
**Trigger:** Captain toggles recruitment flag.
**Preconditions:** Registration is in `approved` or `pending` status; tournament is in `open_registration`.
**Rule:** Enforce member count check in transaction. If team reaches `max_team_size` after a join, auto-set `is_recruiting = false`.
**Result:** Recruitment board updated immediately.
**Exceptions:** None.
**Affected entities:** `registrations`, `registration_members`
**Affected roles:** participant (captain role)
**Source:** FR-TEAM-01, FR-TEAM-03

---

## BR-TEAM-002
**Name:** Join Request Transaction Integrity
**Description:** Accepting a join request must atomically: (1) verify player not already in another team in same tournament, (2) verify team not at max size, (3) verify registration still open.
**Trigger:** Captain accepts a `team_join_requests` record.
**Preconditions:** Request in `pending` status.
**Rule:** Execute all checks within a single DB transaction. If any check fails, rollback and return 409.
**Result:** Member added to `registration_members`; request marked `accepted`; `is_recruiting` updated if needed.
**Exceptions:** None.
**Affected entities:** `team_join_requests`, `registration_members`, `registrations`
**Affected roles:** participant (captain)
**Source:** FR-TEAM-03

---

## BR-TRN-001
**Name:** Tournament Prerequisites Before Opening Registration
**Description:** A tournament cannot open registration unless all mandatory configuration fields are set.
**Trigger:** Admin/CTV attempts to transition tournament to `open_registration`.
**Preconditions:** Tournament exists in `draft` or `closed_registration` state.
**Rule:** Validate: game_category, format, min/max_participants, min/max_team_size, registration window. If GPS check-in enabled: checkin_lat, checkin_lng, geofence_radius_meters must be valid.
**Result:** Transition blocked if prerequisites not met; error details returned.
**Exceptions:** None.
**Affected entities:** `tournaments`
**Affected roles:** ctv, admin
**Source:** FR-TRN-02, SRS 6.3 Table 3

---

## BR-TRN-002
**Name:** Registration Gate Control
**Description:** No new registrations accepted when tournament status is not `open_registration`.
**Trigger:** Participant submits registration.
**Preconditions:** Tournament exists.
**Rule:** If `tournaments.status != 'open_registration'`, reject with 409.
**Result:** Registration denied.
**Exceptions:** None.
**Affected entities:** `tournaments`, `registrations`
**Affected roles:** participant
**Source:** FR-TRN-02

---

## BR-TFT-001
**Name:** TFT Room Partitioning Algorithm
**Description:** Rooms for TFT tournaments must have exactly 7 or 8 players each.
**Trigger:** Admin/CTV generates TFT lobby rooms.
**Preconditions:** Tournament format = `tft_rooms`; participants list is finalized.
**Rule:** Given N players:
- Find m such that ceil(N/8) ≤ m ≤ floor(N/7).
- If valid m exists: use m = ceil(N/8). Rooms of 8: N−7m. Rooms of 7: 8m−N.
- If no valid m: do NOT create rooms. Return error with explanation.
- Create all rooms in a single transaction; any failure → full rollback.
**Result:** Rooms created or error returned; no partial state.
**Exceptions:** If N < 7, special case — NEEDS_STAKEHOLDER_CONFIRMATION on rules for very small N.
**Affected entities:** `matches`, `match_participants`, `brackets`, `bracket_rounds`
**Affected roles:** ctv, admin
**Source:** FR-TRN-04, SRS 3.3, SRS 9.4

---

## BR-CHK-001
**Name:** QR Token Validity Rules
**Description:** A check-in QR token is valid only if: not expired (issued within 30s), not revoked, tournament matches, same participant hasn't already used it.
**Trigger:** Participant submits QR check-in.
**Preconditions:** Token submitted with check-in request.
**Rule:** Validate: `expires_at > NOW()`, `revoked_at IS NULL`, `tournament_id` matches, no existing `check_ins` record for this participant + tournament.
**Result:** If valid and GPS passes → auto-approve. If invalid → reject with specific reason.
**Exceptions:** None.
**Affected entities:** `checkin_qr_tokens`, `check_ins`
**Affected roles:** participant
**Source:** FR-CHK-01, AC-12

---

## BR-CHK-002
**Name:** GPS Geofence Validation
**Description:** GPS-based check-in requires device coordinates within the configured geofence radius AND GPS accuracy ≤ 100m.
**Trigger:** GPS coordinates submitted with QR check-in.
**Preconditions:** Tournament has checkin_lat, checkin_lng, geofence_radius_meters set.
**Rule:** Compute Haversine distance. Accept if: distance ≤ geofence_radius_meters AND gps_accuracy_meters ≤ 100.
**Result:** Accepted → `status = 'approved'`. Rejected → prompt proof submission fallback.
**Exceptions:** Geofence radius is configurable by Admin before check-in opens (audited).
**Affected entities:** `check_ins`, `tournaments`
**Affected roles:** participant (submission), admin (config)
**Source:** FR-CHK-02

---

## BR-CHK-003
**Name:** Single Check-in Per Participant Per Tournament
**Description:** Each participant may have exactly one check-in record per tournament.
**Trigger:** Any check-in submission.
**Preconditions:** Participant is registered for the tournament.
**Rule:** UNIQUE(tournament_id, participant_id) enforced at DB level. If record exists, return current status; do not create duplicate.
**Result:** No duplicate check-ins possible.
**Exceptions:** CTV/Admin can update the existing record's status (with audit).
**Affected entities:** `check_ins`
**Affected roles:** participant (submit), ctv/admin (update)
**Source:** FR-CHK-01, AC-12, SRS 10.3

---

## BR-CHK-004
**Name:** Server-Side IP Address Recording
**Description:** The IP address recorded in check_ins and audit_logs must be determined by the server, not submitted by the client.
**Trigger:** Any check-in request.
**Preconditions:** HTTP request received.
**Rule:** Extract IP from server-determined source (X-Forwarded-For with trusted proxy, or REMOTE_ADDR). Ignore any client-submitted IP field.
**Result:** Tamper-resistant device fingerprint for fraud investigation.
**Exceptions:** None.
**Affected entities:** `check_ins`, `audit_logs`
**Affected roles:** System
**Source:** FR-CHK-03

---

## BR-CRT-001
**Name:** Certificate Worker Idempotency
**Description:** The certificate rendering worker must not create duplicate certificates even if triggered multiple times.
**Trigger:** `tournament.completed` event received by worker.
**Preconditions:** Tournament status = 'completed'.
**Rule:** Use UNIQUE constraints and INSERT ... ON CONFLICT DO NOTHING (or equivalent). One athlete certificate per (tournament_id, participant_id); one organizer certificate per (tournament_id, user_id).
**Result:** Exactly one certificate per eligible person.
**Exceptions:** None.
**Affected entities:** `certificates`
**Affected roles:** System (worker)
**Source:** FR-CRT-01, AC-07, SRS 10.3

---

## BR-CRT-002
**Name:** Certificate Eligibility
**Description:** Athlete certificates issued only to participants with approved check-in for that tournament.
**Trigger:** Certificate worker processing.
**Preconditions:** Tournament status = 'completed'.
**Rule:** SELECT participants WHERE check_ins.tournament_id = tournament AND check_ins.status = 'approved'.
**Result:** Only verified attendees receive certificates.
**Exceptions:** None.
**Affected entities:** `certificates`, `check_ins`
**Affected roles:** System (worker)
**Source:** FR-CRT-02

---

## BR-CRT-003
**Name:** Public Certificate Verification Privacy
**Description:** The public verification portal must not expose PII beyond what is explicitly allowed.
**Trigger:** GET /verify-certificate?code=...
**Preconditions:** Certificate code submitted.
**Rule:** Show: certificate validity status, tournament name, achievement/role, issuing organization. Show recipient name ONLY if `public_name_allowed = true`. NEVER show: email, phone, student_id, KYC images, GPS location.
**Result:** Privacy-compliant public verification.
**Exceptions:** None.
**Affected entities:** `certificates`, `participants`
**Affected roles:** Public (unauthenticated)
**Source:** FR-CRT-04

---

## BR-REP-001
**Name:** Report Scope Restriction for CTV
**Description:** CTV may only export reports for tournaments they are assigned to.
**Trigger:** CTV requests report export.
**Preconditions:** CTV is authenticated.
**Rule:** Verify `tournament_organizers` has entry for (user_id, tournament_id). If not assigned, return 403.
**Result:** Access denied for unassigned tournaments.
**Exceptions:** Admin may export any tournament's data.
**Affected entities:** `report_exports`, `tournament_organizers`
**Affected roles:** ctv, admin
**Source:** FR-REP-01, FR-REP-03

---

## BR-REP-002
**Name:** PII Masking in Exports
**Description:** Non-Admin exports always mask phone and email fields.
**Trigger:** Report file generation.
**Preconditions:** Export task is processing.
**Rule:** If requester role != 'admin': mask phone as `090****123` pattern, email as `ngu***@gmail.com` pattern.
**Result:** CTV and other non-admins never receive raw PII in exported files.
**Exceptions:** Admin receives full data.
**Affected entities:** `report_exports`
**Affected roles:** ctv, admin
**Source:** FR-REP-03, NFR-SEC-03

---

## BR-AUD-001
**Name:** Audit Log Append-Only
**Description:** Audit logs may never be modified or deleted.
**Trigger:** Any attempt to UPDATE or DELETE audit_log records.
**Preconditions:** N/A.
**Rule:** Application role has only INSERT and SELECT on `audit_logs`. Any UPDATE/DELETE attempt is rejected at DB permission level.
**Result:** Tamper-evident audit trail.
**Exceptions:** Infrastructure-level log rotation per documented retention policy only.
**Affected entities:** `audit_logs`
**Affected roles:** All (restricted to INSERT/SELECT)
**Source:** FR-AUD-02, SRS 9.1

---

## BR-SEC-001
**Name:** Data Retention Policy
**Description:** Different data types have specific retention periods that must be automatically enforced.
**Trigger:** Scheduled cleanup process.
**Preconditions:** Data age exceeds retention period.
**Rule:**
- Rejected KYC images: delete after 90 days.
- Approved KYC images: delete within 12 months of last login with no active disputes.
- GPS coordinates: delete or anonymize after 90 days.
- Audit logs: retain 24 months.
- Certificates: retain 5 years or per CLB policy.
- User deletion requests: process within 30 days (anonymize PII fields; retain audit/certificate skeleton).
**Result:** Automated PII minimization compliance.
**Exceptions:** Legal hold may extend retention with documented justification.
**Affected entities:** `participants`, `check_ins`, `audit_logs`, `certificates`
**Affected roles:** System (scheduler), admin
**Source:** NFR-SEC-07
