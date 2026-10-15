# REQUIREMENT TRACEABILITY MATRIX
## DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md v1.1
> **Last Updated:** 2026-09-29
> **Status Legend:** NOT_STARTED | IN_PROGRESS | IMPLEMENTED | VERIFIED

> [!NOTE]
> Status is NOT_STARTED unless repository evidence (not just filenames) proves otherwise.

---

| Requirement | Domain | Business Rule | RBAC | Workflow | API/UI Area | Acceptance Criteria | Status |
|---|---|---|---|---|---|---|---|
| **FR-AUTH-01** Email registration, verification, login, password reset, account lock | DOMAIN-USER-001 | BR-AUTH-001, BR-AUTH-002, BR-AUTH-003 | RBAC-001 to RBAC-004 | WF-001 Steps 1-3 | POST /auth/register, /auth/login, /auth/verify-email, /auth/reset-password | AC-AUTH-001, AC-AUTH-002, AC-AUTH-003 | COMPLIANT |
| **FR-KYC-01** KYC submission with 2 student card images | DOMAIN-PARTICIPANT-001 | BR-KYC-001, BR-KYC-002 | RBAC-008 | WF-001 Steps 4-8 | POST /participants/kyc | AC-KYC-001 | COMPLIANT |
| **FR-KYC-02** Account type classification \(internal/external\) | DOMAIN-PARTICIPANT-001 | BR-KYC-005 | RBAC-008 | WF-001 Step 5 | Automatic on KYC submit | AC-KYC-003 | COMPLIANT |
| **FR-KYC-03** KYC review by CTV/Admin | DOMAIN-PARTICIPANT-001 | BR-KYC-003 | RBAC-009, RBAC-010 | WF-001 Steps 9-10b | GET /admin/kyc/pending, POST /admin/kyc/:id/approve, /reject | AC-KYC-002 | COMPLIANT |
| **FR-KYC-04** KYC image access control \(signed URLs, 403 on direct access\) | DOMAIN-PARTICIPANT-001 | BR-KYC-004 | RBAC-009 | WF-001 | GET /admin/kyc/:id/image \(signed URL\) | AC-KYC-002 \(image access scenarios\) | OUTDATED_IMPLEMENTATION |
| **FR-TEAM-01** Team creation and recruitment flag | DOMAIN-REGISTRATION-001 | BR-TEAM-001 | RBAC-019, RBAC-021 | WF-003 Steps 1-4 | POST /registrations, PATCH /registrations/:id/recruiting | AC-TEAM-001 | COMPLIANT |
| **FR-TEAM-02** Public recruitment board with filters | DOMAIN-REGISTRATION-001 | BR-TEAM-001 | RBAC-014 | WF-003 Step 4 | GET /tournaments/:id/recruiting | AC-TEAM-001 | COMPLIANT |
| **FR-TEAM-03** Team join requests \(send, accept, reject\) | DOMAIN-REGISTRATION-001 | BR-TEAM-002 | RBAC-022, RBAC-023 | WF-003 Steps 5-7b | POST /registrations/:id/join-requests, PATCH /join-requests/:id | AC-TEAM-002 | COMPLIANT |
| **FR-TRN-01** Dynamic form schema for tournament registration | DOMAIN-TOURNAMENT-001 | — | RBAC-013 | WF-002 | POST /tournaments (form_schema field), GET /tournaments/:id/register-form | — | COMPLIANT |
| **FR-TRN-02** Tournament lifecycle management | DOMAIN-TOURNAMENT-001 | BR-TRN-001, BR-TRN-002 | RBAC-013, RBAC-015 | WF-002 full state machine | PATCH /tournaments/:id/status | AC-TRN-001 | PARTIALLY_COMPLIANT |
| **FR-TRN-03** Bracket generation (Single/Double Elimination) | DOMAIN-BRACKET-001 | — | RBAC-029 | WF-002 (closed_registration → ongoing) | POST /tournaments/:id/brackets/generate | — | NOT_STARTED |
| **FR-TRN-04** TFT room partitioning algorithm | DOMAIN-BRACKET-001 | BR-TFT-001 | RBAC-029 | WF-002 | POST /tournaments/:id/tft-rooms/generate | AC-TFT-001, AC-TFT-001 | NOT_STARTED |
| **FR-TRN-05** Match result entry, confirmation, dispute, locked result override | DOMAIN-BRACKET-001 | — | RBAC-031, RBAC-032, RBAC-033, RBAC-034 | WF-007 full | POST /matches/:id/results, POST /matches/:id/dispute, PATCH /matches/:id/resolve | AC-MATCH-001 | NOT_STARTED |
| **FR-CHK-01** QR Code check-in with token validation | DOMAIN-CHECKIN-001 | BR-CHK-001, BR-CHK-003 | RBAC-024 | WF-004 Path A | POST /checkin/qr | AC-CHK-001, AC-CHK-003 | COMPLIANT |
| **FR-CHK-02** GPS geofence validation | DOMAIN-CHECKIN-001 | BR-CHK-002 | RBAC-024 | WF-004 Path A | POST /checkin/qr (GPS component) | AC-CHK-001 | COMPLIANT |
| **FR-CHK-03** Device fingerprinting (IP, User-Agent, GPS) | DOMAIN-CHECKIN-001 | BR-CHK-004 | RBAC-024 | WF-004 | POST /checkin/* (server-side) | AC-CHK-001 | NOT_STARTED |
| **FR-CHK-04** Proof image submission fallback | DOMAIN-CHECKIN-001 | BR-CHK-003 | RBAC-025 | WF-004 Path B | POST /checkin/proof | AC-CHK-002 | PARTIALLY_COMPLIANT |
| **FR-CHK-05** Manual check-in review on Leaflet/OSM map | DOMAIN-CHECKIN-001 | — | RBAC-026, RBAC-027, RBAC-028 | WF-004 Path B Steps 4-7 | GET /staff/checkin-map, PATCH /checkin/:id/review | AC-CHK-002 | NOT_STARTED |
| **FR-CRT-01** Event-driven certificate trigger on tournament completion | DOMAIN-CERTIFICATE-001 | BR-CRT-001 | RBAC-043 (template) | WF-005 Steps 1-3 | POST /tournaments/:id/complete (emits event) | AC-CRT-001 | NOT_STARTED |
| **FR-CRT-02** Athlete E-Certificate generation (PDF + QR) | DOMAIN-CERTIFICATE-001 | BR-CRT-001, BR-CRT-002 | — (worker) | WF-005 Steps 4-6 | Background worker | AC-CRT-001 | NOT_STARTED |
| **FR-CRT-03** Organizer/CTV certificate generation | DOMAIN-CERTIFICATE-001 | BR-CRT-001 | RBAC-035 | WF-005 Steps 4-6 | Background worker + GET /certificates/mine | AC-CRT-001 | NOT_STARTED |
| **FR-CRT-04** Public certificate verification portal | DOMAIN-CERTIFICATE-001 | BR-CRT-003 | RBAC-036 | WF-005 Step 7-8 | GET /verify-certificate?code=... | AC-CRT-002 | NOT_STARTED |
| **FR-CRT-05** Certificate template configuration by Admin | DOMAIN-CERTIFICATE-001 | — | RBAC-043 | — | POST /admin/certificate-templates | — | NOT_STARTED |
| **FR-REP-01** Create export task (idempotent, returns task_id < 2s) | DOMAIN-REPORT-001 | BR-REP-001 | RBAC-037 | WF-006 Steps 1-3 | POST /reports/export | AC-REP-001 | PARTIALLY_COMPLIANT |
| **FR-REP-02** Background export worker with streaming download | DOMAIN-REPORT-001 | — | RBAC-038 | WF-006 Steps 4-9 | Background worker + GET /reports/export/:id/download | AC-REP-001 | PARTIALLY_COMPLIANT |
| **FR-REP-03** PII masking in exported files | DOMAIN-REPORT-001 | BR-REP-002 | RBAC-037, RBAC-038 | WF-006 Step 7 | Worker masking logic | AC-REP-002 | NOT_STARTED |
| **FR-AUD-01** Automatic audit logging for sensitive operations | DOMAIN-AUDIT-001 | BR-AUD-001 | RBAC-040 | All workflows | POST audit_logs (system) | AC-AUD-001 | COMPLIANT |
| **FR-AUD-02** Audit log append-only \(no UPDATE/DELETE\) | DOMAIN-AUDIT-001 | BR-AUD-001 | RBAC-040 | — | DB permission constraint | AC-AUD-001 | COMPLIANT |
| **NFR-SEC-01** Data minimization \(no CCCD/CMND\) | DOMAIN-PARTICIPANT-001 | BR-KYC-002 | All | All | All forms and DB | AC-KYC-001 (CCCD scenario) | COMPLIANT |
| **NFR-SEC-02** KYC image private storage | DOMAIN-PARTICIPANT-001 | BR-KYC-004 | RBAC-009 | WF-001 | Storage layer + signed URL API | AC-KYC-002 (image access) | NOT_STARTED |
| **NFR-SEC-03** Data masking for non-admin roles | DOMAIN-REPORT-001 | BR-REP-002 | RBAC-012 | — | All API responses + exports | AC-REP-002 | NOT_STARTED |
| **NFR-SEC-04** UUID primary keys | DOMAIN-USER-001 through all | — | — | database_schema.sql | — | COMPLIANT |
| **NFR-SEC-05** RBAC enforcement | All | — | All RBAC IDs | All | All API endpoints | All RBAC scenarios | COMPLIANT |
| **NFR-SEC-06** Auth security \(Argon2id, session expiry, rate limiting\) | DOMAIN-USER-001 | BR-AUTH-002, BR-AUTH-003 | RBAC-001 to RBAC-004 | WF-001 | Auth endpoints | AC-AUTH-002, AC-AUTH-003 | OUTDATED_IMPLEMENTATION |
| **NFR-SEC-07** Data retention policy | All | BR-SEC-001 | — | — | Scheduled cleanup jobs | — | NOT_STARTED |
| **NFR-PRF-01** QR check-in response < 2s at p95 | DOMAIN-CHECKIN-001 | — | — | WF-004 | POST /checkin/qr | AC-CHK-001 (< 2s) | NOT_STARTED |
| **NFR-PRF-02** Export worker peak RSS ≤ 256 MiB | DOMAIN-REPORT-001 | — | — | WF-006 | Background worker | AC-REP-001 (memory) | NOT_STARTED |
| **NFR-PRF-03** 500 concurrent check-ins/min | DOMAIN-CHECKIN-001 | — | — | WF-004 | POST /checkin/* | AC-CHK-001 | NOT_STARTED |
| **NFR-REL-01** EDA isolation (worker failures don't affect check-in) | DOMAIN-REPORT-001, DOMAIN-CERTIFICATE-001 | — | — | WF-005, WF-006 | Architecture | — | NOT_STARTED |
| **NFR-REL-02** Match state cache (Redis) with PostgreSQL as source of truth | DOMAIN-BRACKET-001 | — | — | WF-007 | Match service | — | NOT_STARTED |

---

## NEEDS_STAKEHOLDER_CONFIRMATION Items

| ID | Requirement Area | Question |
|---|---|---|
| NSC-001 | UP-001 (RBAC.md) | Can a lead_organizer CTV assign other CTVs to the same tournament, or is this Admin-only? |
| NSC-002 | UP-002 (RBAC.md) | What is the exact workflow for seasonal_staff when entering match results? Are they limited to referee role only? |
| NSC-003 | UP-003 (RBAC.md) | Must a tournament be in `completed` status before CTV Thời vụ can self-export their organizer certificate? |
| NSC-004 | BR-TFT-001 | For N < 7 (very small TFT tournaments), what is the rule? SRS states special case exists but doesn't define it. |
| NSC-005 | FR-TEAM-01 | Can a participant be captain of multiple registrations across different tournaments simultaneously? SRS is silent on cross-tournament captaincy limits. |

---

## REQUIREMENT_CONFLICT Items

| ID | Source A | Source B | Description |
|---|---|---|---|
| RC-SCHEMA-001 | database_schema.sql: participants.id is TEXT type | SRS 6.4 DDL: participants.id is UUID | The existing SQL schema uses TEXT for participants.id while the SRS DDL defines it as UUID. **The SRS DDL is authoritative.** Migration required. |
| RC-ENUM-001 | database_schema.sql: users.role CHECK ('admin', 'ctv') | SRS 6.4 DDL: users.role CHECK ('participant', 'admin', 'ctv', 'seasonal_staff') | The existing schema does not include 'participant' and 'seasonal_staff' roles. **The SRS DDL is authoritative.** Migration required. |
| RC-ENUM-002 | database_schema.sql: tournaments.status includes 'pending', 'approved', 'rejected', 'registration_opened', 'registration_closed' | SRS 6.4 DDL: status is 'draft', 'open_registration', 'closed_registration', 'ongoing', 'completed', 'cancelled' | Status enum values differ between existing schema and SRS. **The SRS DDL is authoritative.** Migration required to align status values. |

---

*This matrix was generated from SRS.md v1.1 on 2026-09-29.*
*Status must be updated by Developer Agent as tasks are completed.*

