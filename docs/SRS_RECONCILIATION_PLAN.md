# SRS Reconciliation Plan

> **Date:** 2026-09-29
> **Status:** Drafted
> **Goal:** Provide a prioritized list of remediation tasks to align the existing codebase with the latest SRS v1.1.

## Priority Definitions
- **P0:** Blocks safe development, correctness, or causes data corruption/schema breakage.
- **P1:** Core alignment with critical functional or non-functional requirements (e.g., security, primary workflow).
- **P2:** Supporting work, minor fixes, or secondary functional requirements.
- **P3:** Cleanup, documentation, or technical debt.

## Remediation Tasks

### TASK-FOUND-001: Schema Reconciliation (P0)
- **Requirement IDs:** RC-SCHEMA-001, RC-ENUM-001, RC-ENUM-002, RC-ENUM-003, RC-DEPR-001, RC-ENUM-004
- **Conflict IDs:** RC-SCHEMA-001, RC-ENUM-001, RC-ENUM-002, RC-ENUM-003, RC-DEPR-001, RC-ENUM-004
- **Current Behavior:** Schema enums for `matches.status`, `team_join_requests.status`, and `ai_checkin_sessions` do not match the authoritative `database_schema.sql` and SRS. Tournament statuses also have discrepancies.
- **Target Behavior:** Generate and apply a migration to align the operational database schema exactly with `database_schema.sql`. Update TypeScript types to match.
- **Affected Modules:** DB schema, `types/index.ts`.
- **Dependencies:** None.
- **Risk:** High (Schema migration on potentially live/staging data).
- **Acceptance Criteria:** `database_schema.sql` perfectly matches the operational schema via `\d` inspection.
- **Definition of Done:** Migration script created, run, and verified. Types updated.

### TASK-SEC-001: Fix Password Hashing Security Violation (P0)
- **Requirement IDs:** NFR-SEC-06
- **Conflict IDs:** RC-SEC-001
- **Current Behavior:** Passwords are hashed using bcrypt cost 10.
- **Target Behavior:** Hash passwords using Argon2id or bcrypt cost >= 12.
- **Affected Modules:** `auth.ts`, `participant.controller.ts`
- **Dependencies:** None.
- **Risk:** High (Authentication logic modification).
- **Acceptance Criteria:** New accounts use cost 12+. Existing accounts are either forced to reset or re-hashed upon next login.
- **Definition of Done:** Tests pass, code reviewed, security non-negotiable satisfied.

### TASK-SEC-002: Implement Signed URLs for KYC Images (P1)
- **Requirement IDs:** FR-KYC-04
- **Conflict IDs:** RC-SEC-002
- **Current Behavior:** KYC images served directly.
- **Target Behavior:** KYC images served via signed URLs with 5-minute expiry.
- **Affected Modules:** `upload.ts`, Frontend image fetching.
- **Dependencies:** None.
- **Risk:** Medium.
- **Acceptance Criteria:** Direct access to images returns 403. Signed URLs expire in 5 minutes.
- **Definition of Done:** Middleware updated, tests pass.

### TASK-BUG-001: Fix Route Ordering in Registration (P2)
- **Requirement IDs:** N/A
- **Conflict IDs:** RC-API-001
- **Current Behavior:** `/my-registrations` defined after `/:id`.
- **Target Behavior:** Define specific routes before parameterized routes.
- **Affected Modules:** `registration.routes.ts`
- **Dependencies:** None.
- **Risk:** Low.
- **Acceptance Criteria:** Both routes work correctly.
- **Definition of Done:** Code updated, tests pass.

## Next Steps
After P0 tasks are completed, the team should proceed with implementing the missing features outlined in the `SRS_IMPLEMENTATION_GAP_ANALYSIS.md`, prioritizing the Bracket System (Phase 3) and Check-in features (Phase 4).
