TASK-ID: TASK-FOUND-001F
Title: Deprecate legacy AI check-in dependencies (ai_checkin_sessions, ai_checkin_detections)

Goal:
Mark legacy AI check-in types, tables, and validator references (`ai_checkin_sessions`, `ai_checkin_detections`) as deprecated per NSC-FOUND-003, verify that no application routes or controllers depend on them, and document migration safety so that no premature table drops occur before full dependency verification.

Requirements:
NSC-FOUND-003, SRS 4.5, SRS 6.2 (Tables 14 & 15).

Conflict IDs:
RC-SCHEMA-003

Current Behavior:
1. `src/types/index.ts` contains `AiCheckinSourceType`, `AiCheckinStatus`, `AiCheckinSession`, and `AiCheckinDetection` without explicit `@deprecated` markers.
2. `src/utils/enumValidators.ts` exports `AI_SOURCE_TYPES`, `AI_SESSION_STATUSES`, `isValidAiSourceType`, and `isValidAiSessionStatus`.
3. Database tables `ai_checkin_sessions` and `ai_checkin_detections` exist in the PostgreSQL schema.
4. Decision NSC-FOUND-003 dictates: DEPRECATE `ai_checkin_sessions` and `ai_checkin_detections`, but DO NOT drop tables until dependency/data safety is verified.

Target Behavior:
1. Deprecation Annotations:
   - Add `@deprecated` JSDoc annotations to `AiCheckinSourceType`, `AiCheckinStatus`, `AiCheckinSession`, and `AiCheckinDetection` in `src/types/index.ts`.
   - Add `@deprecated` JSDoc annotations to AI checkin validators in `src/utils/enumValidators.ts`.
2. Verification:
   - Verify zero runtime route/controller dependencies on `ai_checkin_sessions` or `ai_checkin_detections`.
   - Verify that primary check-in mechanism (`check_ins` table with `qr_scan`, `proof_submission`, `manual_admin`) functions independently.
3. Database Safety:
   - Tables remain intact in database; no DROP TABLE statements executed during this task.
4. Tests:
   - All 79 tests continue to pass 100%.

Scope:
- `Web-giai-dau/backend/src/types/index.ts`
- `Web-giai-dau/backend/src/utils/enumValidators.ts`
- `docs/tasks/TASK-FOUND-001F.md`

Out of Scope:
- Dropping `ai_checkin_sessions` or `ai_checkin_detections` tables from database (prohibited by NSC-FOUND-003).
- Modifying `check_ins` table or `checkin.controller.ts`.

Affected Modules:
`backend/types`, `backend/utils`

Dependencies:
`TASK-FOUND-001E` (COMPLETED & ACCEPTED)

Business Rules:
- NSC-FOUND-003: Deprecate `ai_checkin_sessions` and `ai_checkin_detections`.
- DOMAIN-CHECKIN-001: Multi-modal check-in uses `check_ins` table.

RBAC Rules:
- RBAC-016: Check-in processing.

Workflow:
- WF-004: Multi-modal Check-in.

Schema Impact:
`NONE` (No DDL drops executed).

API Impact:
`NONE` (Internal types deprecated, no active endpoints affected).

Implementation Steps:
1. Add `@deprecated` annotations in `src/types/index.ts`.
2. Add `@deprecated` annotations in `src/utils/enumValidators.ts`.
3. Verify that `checkin.controller.ts` and `checkin.repository.ts` operate exclusively on `check_ins`.
4. Run `tsc --noEmit` and `npm test` to confirm zero regression.

Constraints:
- Strictly DO NOT drop `ai_checkin_sessions` or `ai_checkin_detections` tables (NSC-FOUND-003).
- Zero CCCD Invariant strictly maintained.

Acceptance Criteria:
- All AI checkin types and validators annotated with `@deprecated [NSC-FOUND-003]`.
- No active controllers or routes depend on deprecated AI checkin tables.
- Database tables remain intact and accessible for historical auditing.
- `tsc --noEmit` and `npm test` pass with 0 errors.

Definition of Done:
- [x] Task specification reviewed and approved.
- [x] `@deprecated` annotations added in `src/types/index.ts`.
- [x] `@deprecated` annotations added in `src/utils/enumValidators.ts`.
- [x] Codebase verified free of runtime dependencies on deprecated AI check-in.
- [x] `npm test` and `tsc --noEmit` pass 100%.
- [x] Manual test guide and acceptance record documented.
