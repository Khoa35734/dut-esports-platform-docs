# WORKFLOWS — DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md v1.1 | Sections 3, 7, 8
> **Last Updated:** 2026-09-29 (WF-003: removed 'cancelled' from team_join_requests per SRS DDL §6.4, NSC-FOUND-004)

---

## WF-001: User Registration & KYC

**Workflow ID:** WF-001
**Actors:** Participant (Sinh viên/VĐV), CTV Thường trực, Admin
**Trigger:** New user accesses registration page.
**Preconditions:** User does not yet have an account.
**Initial State:** Unauthenticated

**Steps:**
1. User submits email + password → account created with `email_verified_at = NULL`.
2. System sends one-time verification link (token hash stored; expires 30 min).
3. User clicks link → `email_verified_at` set.
4. User creates participant profile: name, student_id, university, phone.
5. System auto-sets `account_type` (internal/external).
6. User uploads 2 KYC images (student card front + selfie holding card).
7. System validates: 2 images, each ≤ 5MB, format in [jpg/jpeg/png].
8. System stores images in private storage, creates `participants` record with `kyc_status = 'pending'`.
9. CTV/Admin reviews KYC on split-view interface.
10a. CTV approves → `kyc_status = 'approved'` → tournament access unlocked → audit log.
10b. CTV rejects (reason required) → `kyc_status = 'rejected'` → notification sent → user may resubmit.

**State Machine:**
```
USER.email_verified_at = NULL
  → email_verified_at IS NOT NULL
    Actor: User (via email link)
    Condition: Valid, unexpired, unused token
    Requirement: FR-AUTH-01

PARTICIPANT.kyc_status = 'pending'
  → 'approved'
    Actor: CTV Thường trực or Admin
    Condition: 2 images verified, identity confirmed
    Requirement: FR-KYC-03
  → 'rejected'
    Actor: CTV Thường trực or Admin
    Condition: Images invalid or identity not confirmed; reason must be entered
    Requirement: FR-KYC-03

PARTICIPANT.kyc_status = 'rejected'
  → 'pending'
    Actor: Participant (re-submits images)
    Condition: New valid images uploaded
    Requirement: FR-KYC-03
```

**Error Paths:**
- Token expired: user must request new token.
- Image too large/wrong format: form blocked, no record created.
- Email already exists: registration rejected with 409.

**Final State:** `kyc_status = 'approved'` (tournament access enabled)
**Requirements:** FR-AUTH-01, FR-KYC-01, FR-KYC-02, FR-KYC-03, FR-KYC-04

---

## WF-002: Tournament Lifecycle

**Workflow ID:** WF-002
**Actors:** CTV Thường trực, Admin
**Trigger:** Admin/CTV creates a new tournament.
**Preconditions:** Actor is authenticated with role admin or ctv.
**Initial State:** Tournament does not exist.

**State Machine:**
```
draft
  → open_registration
    Actor: Admin or CTV
    Condition: game_category, format, min/max participants, team sizes, registration window all set; if GPS check-in: venue coordinates set
    Requirement: FR-TRN-02, BR-TRN-001
  → cancelled
    Actor: Admin
    Condition: Any time before ongoing
    Requirement: FR-TRN-02

open_registration
  → closed_registration
    Actor: Admin/CTV or auto at registration_closes_at
    Condition: N/A
    Requirement: FR-TRN-02
  → cancelled
    Actor: Admin
    Requirement: FR-TRN-02

closed_registration
  → ongoing
    Actor: Admin or CTV
    Condition: Bracket generated and published; check-in may begin
    Requirement: FR-TRN-02
  → cancelled
    Actor: Admin
    Requirement: FR-TRN-02

ongoing
  → completed
    Actor: Admin
    Condition: Final match completed; triggers tournament.completed event
    Requirement: FR-TRN-02, FR-CRT-01
  → cancelled
    Actor: Admin
    Requirement: FR-TRN-02

completed [terminal — triggers certificate worker]
cancelled [terminal]
```

**Requirements:** FR-TRN-01, FR-TRN-02

---

## WF-003: Team Registration & Recruitment

**Workflow ID:** WF-003
**Actors:** Participant (Captain), Participant (Free agent)
**Trigger:** KYC-approved participant initiates team registration.
**Preconditions:** Tournament in `open_registration`; captain has `kyc_status = 'approved'`.

**Steps:**
1. Captain creates registration → `registrations.status = 'pending'`.
2. Captain fills `form_data` per `form_schema`.
3. Captain optionally sets `is_recruiting = true` + `recruiting_note`.
4. Registration appears on public recruitment board.
5. Free agent sends `team_join_requests` record → `status = 'pending'`.
6. Captain receives notification.
7a. Captain accepts (in transaction): verify player not in another team same tournament, verify team < max_team_size, verify registration still open → add to `registration_members` → update `is_recruiting` if full.
7b. Captain rejects → `team_join_requests.status = 'rejected'`.

**State Machine (team_join_requests.status):**
```
pending
  → accepted
    Actor: Team captain
    Condition: Atomic transaction checks pass
    Requirement: FR-TEAM-03
  → rejected
    Actor: Team captain
    Requirement: FR-TEAM-03
```

**Requirements:** FR-TEAM-01, FR-TEAM-02, FR-TEAM-03

---

## WF-004: Check-in (Multi-modal)

**Workflow ID:** WF-004
**Actors:** Participant, CTV (map monitor), Admin
**Trigger:** Participant arrives at tournament venue during check-in window.
**Preconditions:** Tournament in `ongoing` or check-in window open; participant registered and KYC approved.

**Path A: QR + GPS (primary)**
1. BTC displays rotating QR code (30-second expiry).
2. Participant opens browser, scans QR.
3. Browser requests GPS permission.
4. If GPS granted: coordinates sent with QR token + device metadata.
5. Server validates: token not expired/revoked, not replayed by same participant, tournament matches, GPS within geofence (≤ radius) and accuracy ≤ 100m.
6. Pass → `check_ins.status = 'approved'`, method = 'qr_scan'; emit `checkin.approved` event.
7. Fail (GPS out of range) → redirect to proof submission.

**Path B: Proof Submission (fallback)**
1. Participant selects proof submission (GPS unavailable/denied).
2. Participant uploads image (venue selfie or game lobby screenshot).
3. System creates `check_ins` with `status = 'pending_review'`, method = 'proof_submission'.
4. CTV sees pending marker on Leaflet/OSM map dashboard.
5. CTV reviews image + map position.
6. CTV approves → `status = 'approved'`; `reviewed_by` set; audited.
7. CTV rejects → `status = 'rejected'`; audited.

**Path C: Admin Manual Override**
1. Admin manually sets check-in status with reason.
2. Audit log records actor, reason, old/new values.

**State Machine (check_ins.status):**
```
[submitted]
  → approved  (auto: QR+GPS valid)
  → rejected  (auto: GPS out of range or invalid token)
  → pending_review (auto: proof submission)

pending_review
  → approved  (Actor: CTV/Admin; Audited)
  → rejected  (Actor: CTV/Admin; Audited)
```

**Requirements:** FR-CHK-01 through FR-CHK-05

---

## WF-005: E-Certificate Issuance

**Workflow ID:** WF-005
**Actors:** Admin (trigger), System worker (process), Participant/CTV (download)
**Trigger:** Admin transitions tournament to `completed` status.
**Preconditions:** All matches complete; Admin authorized.

**Steps:**
1. Admin sets `tournaments.status = 'completed'`.
2. System emits `tournament.completed` event to message queue.
3. Certificate worker receives event.
4. Worker queries eligible athletes: `check_ins.status = 'approved'` for tournament.
5. Worker queries eligible organizers: all records in `tournament_organizers` for tournament.
6. For each eligible person (idempotent INSERT):
   a. Generate unique `certificate_code` (UUID-based hash).
   b. Generate QR code pointing to `/verify-certificate?code=...`.
   c. Load certificate template.
   d. Render PDF with dynamic fields (name, tournament, achievement, code, QR).
   e. Store PDF in private storage.
   f. INSERT into `certificates`; ON CONFLICT DO NOTHING.
7. Participant/CTV logs in → views and downloads own certificate.
8. Third party scans QR → hits public `/verify-certificate` → sees filtered info.

**Requirements:** FR-CRT-01 through FR-CRT-05

---

## WF-006: Report Export (Background Task)

**Workflow ID:** WF-006
**Actors:** Admin or CTV
**Trigger:** Admin/CTV requests report export.
**Preconditions:** Actor authenticated; CTV must be assigned to tournament.

**Steps:**
1. Actor submits export request with `idempotency_key`.
2. System checks UNIQUE(requested_by, idempotency_key): if exists, return existing task_id.
3. Create `report_exports` record with `status = 'queued'`; return `task_id` within 2 seconds.
4. System emits `report.export_requested` event.
5. Worker picks up task → sets `status = 'processing'`.
6. Worker reads data in cursor/batches (no full load into RAM).
7. Worker applies PII masking if requester is not Admin.
8. Worker writes CSV/XLSX to private storage.
9. Worker sets `status = 'completed'`; sets `file_url` and `expires_at` (24h).
10. Actor polls status or receives notification → downloads via signed URL (max 5 min validity).

**State Machine (report_exports.status):**
```
queued → processing → completed
                   → failed
completed → expired (after 24h)
```

**Requirements:** FR-REP-01, FR-REP-02, FR-REP-03

---

## WF-007: Match Result & Dispute

**Workflow ID:** WF-007
**Actors:** Referee/CTV, Team Captain (participant), Admin
**Trigger:** Match concludes.
**Preconditions:** Match in `in_progress` status.

**Steps:**
1. Referee enters scores for each game in the BO series.
2. Match transitions to `awaiting_confirmation`.
3a. Team captain confirms → `completed`; bracket advances.
3b. Team captain disputes (within deadline): match → `disputed`; bracket does NOT advance.
4. CTV/Admin reviews dispute with evidence.
5. Decision made → `completed`; result locked; audit log records actor, decision, old/new values.
6. Locked result can only be modified by Admin (with reason, audited).

**State Machine (matches.status):**
```
scheduled
  → in_progress  (Actor: Referee; when match starts)

in_progress
  → awaiting_confirmation  (Actor: Referee; after score entry)
  → cancelled              (Actor: Admin)

awaiting_confirmation
  → completed  (Actor: Captain confirmation or timeout)
  → disputed   (Actor: Captain dispute within Dieu Le deadline)

disputed
  → completed  (Actor: CTV/Admin decision; audited)

completed [result locked; Admin override only with audit]
cancelled [terminal]
```

**Requirements:** FR-TRN-05, AC-14
