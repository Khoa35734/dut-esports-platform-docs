# SRS Implementation Gap Analysis

> **Date:** 2026-09-29
> **Status:** Drafted based on existing code review
> **Purpose:** Reconcile the current implementation state against the latest SRS v1.1.

## 1. Requirement Implementation Matrix

| Requirement | Latest SRS Behavior | Current Implementation | Status | Impact | Risk | Recommended Action |
|---|---|---|---|---|---|---|
| **SV-01..04** | Student registration, login, profile, KYC resubmit | Complete and operational | COMPLIANT | N/A | Low | Preserve implementation |
| **SV-05..07** | Tournament registration, recruiting market, cancel | Complete and operational | COMPLIANT | N/A | Low | Preserve implementation |
| **SV-08** | Bracket view | Displays tournament branches and schedules | Missing routes, controllers, and UI components | MISSING_IMPLEMENTATION | Blocks tournament progression | High | Implement bracket features |
| **SV-09** | Match results | VĐV dispute match results | Missing endpoints | MISSING_IMPLEMENTATION | Blocks match progression | High | Implement match endpoints |
| **SV-10** | Check-in (QR+GPS) | QR+GPS and proof channel | QR+GPS implemented, proof channel and map UI incomplete | PARTIALLY_COMPLIANT | Missing fallback | Medium | Finish proof logic and map UI |
| **SV-11** | E-Cert for athlete | Auto-generates E-cert for athlete upon completion | Missing entirely | MISSING_IMPLEMENTATION | Blocks post-tournament | High | Implement E-Cert worker |
| **SV-12** | Export data | Export data with streaming and rate limits | ExcelJS exists, but rate limiter missing | PARTIALLY_COMPLIANT | Missing rate limits | Medium | Add rate limiter middleware |
| **SV-13** | CTV self-cert | CTV can self-generate E-certs | Missing entirely | MISSING_IMPLEMENTATION | Blocks post-tournament | Medium | Implement CTV E-Cert |
| **AD-01..02** | KYC admin approval/reject | Implemented with audit logging | COMPLIANT | N/A | Low | Preserve implementation |
| **AD-03..05** | Tournaments CRUD | Implemented for CTV/Admin | COMPLIANT | N/A | Low | Preserve implementation |
| **AD-06** | Lock CTV accounts | Implemented | COMPLIANT | N/A | Low | Preserve implementation |
| **AD-07** | Bracket management | Generate branches (Single/Double/TFT) | Missing entirely | MISSING_IMPLEMENTATION | Blocks tournament operations | High | Implement bracket generation |
| **AD-08** | Admin Export | Export data | ExcelJS exists | PARTIALLY_COMPLIANT | Missing rate limits | Medium | Add rate limiter middleware |
| **AD-09..10** | Admin Check-in review | Map view and manual override | Map view missing, manual override exists | PARTIALLY_COMPLIANT | Hard to review proofs | Medium | Implement map view |
| **AD-11** | Certificate admin | Configure cert templates | Missing entirely | MISSING_IMPLEMENTATION | Blocks cert generation | High | Implement cert config endpoints |
| **AD-12** | Admin Report | Reports | Implemented partially via Export | PARTIALLY_COMPLIANT | Incomplete | Medium | Finish report logic |
| **AD-13** | AI OCR Check-in | AI OCR Liên Quân pipeline | Missing entirely | MISSING_IMPLEMENTATION | Missing fast check-in | Medium | Implement AI OCR pipeline |
| **TFT Algorithm (§4.4)** | Partition TFT lobbies (N/8 and N/7) | Missing entirely | MISSING_IMPLEMENTATION | Blocks TFT tournaments | High | Implement TFT partitioning |
| **Check-in (§4.5)** | Multi-modal check-in | QR+GPS works, proof and map missing | PARTIALLY_COMPLIANT | Incomplete workflow | Medium | Finish Check-in workflow |
| **Certificate (§4.6)** | Automated E-Certificate issuance | Missing entirely | MISSING_IMPLEMENTATION | Incomplete workflow | High | Implement Cert issuance |
| **Export (§4.7)** | Streaming Export & Rate Limiting | Streaming works, rate limiting missing | PARTIALLY_COMPLIANT | API Abuse risk | Medium | Add Rate Limiter |
| **AI OCR (§4.8)** | AI OCR pipeline | Missing entirely | MISSING_IMPLEMENTATION | Missing feature | Medium | Implement OCR logic |
| **Security (§5)** | Security requirements (Argon2id/bcrypt >=12, signed URL) | Uses bcrypt cost 10, direct file serve | OUTDATED_IMPLEMENTATION | Security non-negotiable failure | Blocker | Fix hashing and implement signed URLs |

## 2. Breaking Change Analysis

### Breaking Changes
- **Change:** `matches` table status enum mismatch
- **Classification:** BREAKING
- **Requirements:** RC-ENUM-003
- **Current Behavior:** Operational DB uses `('scheduled', 'live', 'completed', 'cancelled')`
- **Target Behavior:** Target SRS uses `('scheduled', 'ready', 'in_progress', 'completed', 'cancelled', 'disputed')`
- **Impact:** Any code or data using 'live' will break or be invalid.
- **Migration Required:** YES (Update enum values, map existing 'live' to 'in_progress' or similar).
- **Backward Compatibility Risk:** High if frontend relies on 'live'.
- **Recommended Handling:** Perform a schema migration and align TypeScript types.

- **Change:** `team_join_requests` status enum mismatch
- **Classification:** BREAKING
- **Requirements:** RC-ENUM-004
- **Current Behavior:** Operational DB missing `'cancelled'`
- **Target Behavior:** DB should include `'cancelled'`
- **Impact:** Users cannot cancel join requests properly.
- **Migration Required:** YES.
- **Backward Compatibility Risk:** Low.
- **Recommended Handling:** Perform a schema migration to add 'cancelled'.

### Potentially Breaking Changes
- **Change:** `ai_checkin_sessions` enum mismatch
- **Classification:** POTENTIALLY_BREAKING
- **Requirements:** RC-DEPR-001
- **Current Behavior:** Operational DB has 3 values for source type and 5 for status.
- **Target Behavior:** SRS has 2 values for source type and 4 for status.
- **Impact:** Depends on whether the extra states are actively used.
- **Migration Required:** YES (If stakeholder decides to align strictly).
- **Backward Compatibility Risk:** Medium.
- **Recommended Handling:** Ask stakeholder if the extra values are needed.

## 3. Reconciliation Conflicts

- **Conflict ID:** RC-ENUM-003
  - **Related Requirement(s):** Match workflow
  - **Current Behavior:** `matches.status` uses `('scheduled', 'live', 'completed', 'cancelled')`
  - **Expected Behavior:** `matches.status` should use `('scheduled', 'ready', 'in_progress', 'completed', 'cancelled', 'disputed')`
  - **Affected Modules:** Match logic, DB schema
  - **Severity:** BLOCKER
  - **Recommended Resolution:** Schema migration to align with SRS.
  - **Needs Stakeholder Confirmation:** NO

- **Conflict ID:** RC-DEPR-001
  - **Related Requirement(s):** AI OCR Workflow
  - **Current Behavior:** `ai_checkin_sessions` has extra enums compared to SRS.
  - **Expected Behavior:** Align with SRS.
  - **Affected Modules:** DB schema, AI OCR logic.
  - **Severity:** MEDIUM
  - **Recommended Resolution:** Stakeholder clarification to confirm if extra enums are valid additions.
  - **Needs Stakeholder Confirmation:** YES

- **Conflict ID:** RC-ENUM-004
  - **Related Requirement(s):** Team Registration (FR-TEAM-03)
  - **Current Behavior:** `team_join_requests` missing 'cancelled' in operational DB.
  - **Expected Behavior:** DB should include 'cancelled'.
  - **Affected Modules:** DB schema, `teamRequest.controller.ts`
  - **Severity:** BLOCKER
  - **Recommended Resolution:** Schema migration.
  - **Needs Stakeholder Confirmation:** NO

- **Conflict ID:** RC-SEC-001
  - **Related Requirement(s):** Security (NFR-SEC-06)
  - **Current Behavior:** bcryptjs cost 10 is used.
  - **Expected Behavior:** bcryptjs cost >= 12 or Argon2id.
  - **Affected Modules:** `auth.ts`, `participant.controller.ts`
  - **Severity:** HIGH
  - **Recommended Resolution:** Update hashing cost and force password reset or handle re-hashing.
  - **Needs Stakeholder Confirmation:** NO

- **Conflict ID:** RC-SCHEMA-001
  - **Related Requirement(s):** Data Integrity Invariants (AGENTS.md § 2.3)
  - **Current Behavior:** `participants.id` is TEXT (MSSV).
  - **Expected Behavior:** AGENTS.md mandates UUID primary keys for all tables.
  - **Affected Modules:** DB schema, relationships.
  - **Severity:** MEDIUM
  - **Recommended Resolution:** Clarify if TEXT is a deliberate exception to the UUID rule.
  - **Needs Stakeholder Confirmation:** YES

- **Conflict ID:** RC-SEC-002
  - **Related Requirement(s):** Security (FR-KYC-04)
  - **Current Behavior:** KYC images served directly.
  - **Expected Behavior:** Served via signed URLs (max 5 mins).
  - **Affected Modules:** `upload.ts`, File storage.
  - **Severity:** HIGH
  - **Recommended Resolution:** Implement signed URL generation.
  - **Needs Stakeholder Confirmation:** NO

- **Conflict ID:** RC-API-001
  - **Related Requirement(s):** Routing functionality
  - **Current Behavior:** Route ordering bug in `registration.routes.ts` (`/my-registrations` after `/:id`).
  - **Expected Behavior:** Specific routes must precede parameterized routes.
  - **Affected Modules:** `registration.routes.ts`
  - **Severity:** MEDIUM
  - **Recommended Resolution:** Fix route ordering.
  - **Needs Stakeholder Confirmation:** NO

- **Conflict ID:** RC-ENUM-002
  - **Related Requirement(s):** Tournament lifecycle (FR-TRN-02)
  - **Current Behavior:** Tournament status 'active' is present, 'BRACKET_GENERATED' missing.
  - **Expected Behavior:** Align with SRS and EXECUTABLE_AGENT_SPEC.
  - **Affected Modules:** Tournament logic, Types.
  - **Severity:** MEDIUM
  - **Recommended Resolution:** Reconcile status transitions.
  - **Needs Stakeholder Confirmation:** NO

## 4. Undocumented Implementation Analysis
- **checkin-simulation page:** Exists in frontend but undocumented in SRS. Needs stakeholder confirmation on whether to keep it as an internal tool or remove it.
- **Zustand stores:** Used for auth-store and ui-store in frontend, but not mentioned in SRS/GEMINI.md. This is acceptable as a technical choice, but should be documented as the state management strategy.
- **Vietnam administrative units utility:** Present in frontend, undocumented in SRS. Useful for check-in location logic, keep as internal technical infrastructure.

## 5. Needs Stakeholder Confirmation
- **NSC-001:** `ai_checkin_sessions` extra enums (RC-DEPR-001).
- **NSC-002:** `participants.id` TEXT exception vs UUID rule (RC-SCHEMA-001).
- **NSC-003:** `checkin-simulation` page.
