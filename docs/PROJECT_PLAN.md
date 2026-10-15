# PROJECT PLAN — DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md
> **Planning Authority:** Planner Agent

This plan reflects the CURRENT implementation status. It is an alignment and completion plan, not a greenfield roadmap.

## Allowed Statuses
- `DONE` (Fully compliant and verified)
- `COMPLIANT` (Existing code matches SRS without changes needed)
- `IN_PROGRESS` (Currently being worked on)
- `NEEDS_ALIGNMENT` (Existing code requires changes to match SRS)
- `BLOCKED` (Waiting on dependencies or stakeholder decisions)
- `NOT_STARTED` (Feature not yet implemented)
- `DEPRECATED_PENDING_REMOVAL` (Legacy code scheduled for removal)

---

## Phase 0 — Reconciliation / Foundation Fixes
**Status:** `DONE`

**Objective:** Apply Final Stakeholder Decisions (NSC-FOUND-001 to 005) and resolve schema/identity mismatches.

**Tasks:**
- `TASK-FOUND-001A` [DONE]: Inventory and classify schema differences (classified in docs/SCHEMA_MISMATCH_INVENTORY.md).
- `TASK-FOUND-001B` [DONE]: Create unified users/participants migration (`participants` linked 1:1 by `user_id`).
- `TASK-FOUND-001C` [DONE]: Update ORM/domain mappings for identity.
- `TASK-FOUND-001D` [DONE]: Update authentication references to use unified identity.
- `TASK-FOUND-001E` [DONE]: Normalize status constraints (`team_join_requests` canonical values, `registrations` canonical values).
- `TASK-FOUND-001F` [DONE]: Deprecate legacy AI check-in dependencies (`ai_checkin_sessions`, `ai_checkin_detections`).
- `TASK-FOUND-001G` [DONE]: Run migration/regression verification.
- `TASK-FE-FOUND-001` [DONE]: Implement Core Cyber Design System & CSS Token Foundation.

---

## Phase 1 — Authentication / Identity Alignment
**Status:** `DONE`

**Objective:** Ensure auth flows correctly use the new unified `users` table and properly handle participant profiles.

**Tasks:**
- `TASK-AUTH-001` [DONE]: Align authentication endpoints and profile retrieval with unified identity.
- `TASK-AUTH-002` [DONE]: Ensure JWT payload matches unified identity structure.
- `TASK-AUTH-003` [DONE]: Verify password hashing Argon2id/bcrypt ≥12 requirement.

---

## Phase 2 — RBAC / Authorization Alignment
**Status:** `NEEDS_ALIGNMENT`

**Objective:** Align existing authorization logic with `docs/RBAC.md`.

**Tasks:**
- `TASK-RBAC-001` [IMPLEMENTED / READY_FOR_REVIEW]: Ensure middleware checks `users.role` (admin/ctv/seasonal_staff/participant).
- `TASK-RBAC-002`: Enforce CTV tournament-scope authorization (`tournament_organizers`).
- `TASK-RBAC-003`: Ensure secure static asset access (signed URLs for KYC images).

---

## Phase 3 — Core Domain Alignment
**Status:** `NEEDS_ALIGNMENT`

**Objective:** Align core entities (Tournaments, Participants) with `docs/DOMAIN_RULES.md` and `docs/BUSINESS_RULES.md`.

**Tasks:**
- `TASK-DOM-001`: Ensure Zero CCCD Invariant across all endpoints/models.
- `TASK-DOM-002`: Verify tournament status transitions.

---

## Phase 4 — Tournament / Registration / Team Flows
**Status:** `NEEDS_ALIGNMENT`

**Objective:** Implement missing registration features or align existing ones to SRS workflows.

**Tasks:**
- `TASK-REG-001`: Enforce canonical `registrations.status` ('pending', 'approved', 'rejected').
- `TASK-REG-002`: Enforce canonical `team_join_requests.status` ('pending', 'accepted', 'rejected').

---

## Phase 5 — Check-in
**Status:** `NEEDS_ALIGNMENT`

**Objective:** Standardize QR/GPS check-in and proof-based check-in.

**Tasks:**
- `TASK-CHK-001`: Verify QR token generation and validation constraints.
- `TASK-CHK-002`: Verify Geofence calculation (Haversine).
- `TASK-CHK-003`: Ensure duplicate check-in prevention.

---

## Phase 6 — Bracket / Match / Results
**Status:** `NEEDS_ALIGNMENT`

**Objective:** Align bracket generation, TFT partitioning, and result disputes.

**Tasks:**
- `TASK-BRK-001`: Implement/verify TFT room partitioning algorithm.
- `TASK-MATCH-001`: Ensure match status transitions and dispute workflows are correct.

---

## Phase 7 — Certificate / Notification / Supporting Infrastructure
**Status:** `NEEDS_ALIGNMENT` / `NOT_STARTED`

**Objective:** Background workers for certificates and notifications.

**Tasks:**
- `TASK-CRT-001`: Implement event-driven certificate PDF generation.
- `TASK-CRT-002`: Set up idempotent worker architecture for certificates.
- `TASK-NOTIF-001`: Align `notifications` table usage as technical infrastructure.

---

## Phase 8 — Admin / CTV Operations
**Status:** `NEEDS_ALIGNMENT`

**Objective:** Reporting, manual overrides, and audit logs.

**Tasks:**
- `TASK-OPS-001`: Implement report export background workers.
- `TASK-OPS-002`: Enforce PII masking in exports.
- `TASK-OPS-003`: Verify `audit_logs` immutability (INSERT/SELECT only).

---

## Phase 9 — Integration / Regression
**Status:** `NOT_STARTED`

**Objective:** End-to-end tests for all major flows.

**Tasks:**
- `TASK-INT-001`: E2E Participant Flow (Reg -> KYC -> Team -> Check-in -> Match -> Cert).
- `TASK-INT-002`: E2E Admin/CTV Flow (Create Tourney -> Review KYC -> Manage Bracket -> Export).

---

## Phase 10 — Hardening / Release Readiness
**Status:** `NOT_STARTED`

**Objective:** Performance, security testing, and final compliance.

**Tasks:**
- `TASK-REL-001`: Run penetration test simulations (RBAC scope).
- `TASK-REL-002`: Load test critical paths (check-in, report export).
- `TASK-REL-003`: Final verify Zero CCCD Invariant.

