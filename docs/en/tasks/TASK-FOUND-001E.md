TASK-ID: TASK-FOUND-001E
Title: Normalize status constraints (team_join_requests & registrations canonical values)

Goal:
Normalize and enforce canonical status values for `team_join_requests` ('pending', 'accepted', 'rejected' per NSC-FOUND-004) and `registrations` ('pending', 'approved', 'rejected' per NSC-FOUND-005) across TypeScript types, validation middleware/utilities, repository operations, and tests, completely eliminating the legacy/unauthorized 'cancelled' state from domain and workflow rules.

Requirements:
SRS 3.1 (SV-05, SV-06, SV-07), SRS 6.2 (Table 5 registrations, Table 7 team_join_requests), SRS 6.4 (DDL CHECK constraints), NSC-FOUND-004, NSC-FOUND-005.

Conflict IDs:
RC-ENUM-004, RC-WORKFLOW-001

Current Behavior:
1. `RegistrationStatus` in `backend/src/types/index.ts` is defined as `CanonicalRegistrationStatus | 'cancelled'`.
2. `TeamJoinRequestStatus` in `backend/src/types/index.ts` is defined as `CanonicalTeamJoinRequestStatus | 'cancelled'`.
3. `enumValidators.ts` includes `'cancelled'` in registration status validation.
4. `registration.controller.ts` and `registration.repository.ts` attempt to set status to `'cancelled'`, which directly conflicts with the operational DB CHECK constraint `chk_registration_status` (`CHECK (status IN ('pending', 'approved', 'rejected'))`).
5. Tests in `tests/phase2.test.ts` assert that `'cancelled'` is a valid registration status.

Target Behavior:
1. Canonical Types:
   - `export type RegistrationStatus = 'pending' | 'approved' | 'rejected';`
   - `export type TeamJoinRequestStatus = 'pending' | 'accepted' | 'rejected';`
   - Deprecated aliases cleaned up.
2. Status Validators:
   - `enumValidators.ts` validates `RegistrationStatus` strictly as `['pending', 'approved', 'rejected']`.
   - `enumValidators.ts` validates `TeamJoinRequestStatus` strictly as `['pending', 'accepted', 'rejected']`.
3. Repository & Controller Alignment:
   - Replace any `status = 'cancelled'` assignment on registrations or team_join_requests with canonical lifecycle handling (e.g. deletion/hard cleanup for pre-deadline cancellation, or status rejection per SRS 3.1 / NSC-FOUND-004/005).
   - In queries filtering active registrations, ensure condition matches canonical statuses (`status IN ('pending', 'approved')` or `status != 'rejected'`).
4. Tests:
   - Update tests in `tests/phase2.test.ts` to assert canonical statuses strictly according to SRS.
   - All tests pass 100% (tsc --noEmit and npm test).

Scope:
- `Web-giai-dau/backend/src/types/index.ts`
- `Web-giai-dau/backend/src/utils/enumValidators.ts`
- `Web-giai-dau/backend/src/controllers/registration.controller.ts`
- `Web-giai-dau/backend/src/repositories/registration.repository.ts`
- `Web-giai-dau/backend/tests/phase2.test.ts`

Out of Scope:
- Modifying `tournaments.status` or `matches.status` (these legitimately contain 'cancelled' in SRS).
- Frontend UI alterations (handled in subsequent frontend alignment tasks).

Affected Modules:
`backend/types`, `backend/utils`, `backend/controllers/registration`, `backend/repositories/registration`, `backend/tests`

Dependencies:
`TASK-FOUND-001D` (COMPLETED & ACCEPTED)

Business Rules:
- NSC-FOUND-004: Canonical `team_join_requests.status` ('pending', 'accepted', 'rejected').
- NSC-FOUND-005: Canonical `registrations.status` ('pending', 'approved', 'rejected').
- BR-TRN-001, BR-TEAM-001: Registration window validation.

RBAC Rules:
- RBAC-011, RBAC-012: Registration creation and management.
- RBAC-022, RBAC-023: Team join requests.

Workflow:
- WF-003: Team Registration & Recruitment.

Schema Impact:
`NONE` (Live database CHECK constraints `chk_registration_status` and `chk_tjr_status` already enforce canonical values).

API Impact:
`COMPATIBLE_NORMALIZED` (Removes unsupported 'cancelled' enum value from status endpoints).

Implementation Steps:
1. Update `RegistrationStatus` and `TeamJoinRequestStatus` in `src/types/index.ts` to only include canonical values.
2. Update `src/utils/enumValidators.ts` to enforce canonical array for registration and join request statuses.
3. Update `src/controllers/registration.controller.ts` and `src/repositories/registration.repository.ts` to eliminate `status = 'cancelled'` writes.
4. Align `tests/phase2.test.ts` and any affected test files to validate canonical statuses.
5. Run `npx tsc --noEmit` and `npm test` to verify 100% compliance.

Constraints:
- Strict zero-tolerance for `'cancelled'` in `registrations.status` and `team_join_requests.status`.
- Zero CCCD Invariant strictly maintained.
- All existing test suites pass.

Acceptance Criteria:
- `RegistrationStatus` type and validator accept only `'pending'`, `'approved'`, `'rejected'`.
- `TeamJoinRequestStatus` type and validator accept only `'pending'`, `'accepted'`, `'rejected'`.
- No queries attempt to write `'cancelled'` to `registrations.status` or `team_join_requests.status`.
- `npm test` and `tsc --noEmit` pass with 0 errors.

Definition of Done:
- [x] Task specification reviewed and approved.
- [x] Canonical types updated in `src/types/index.ts`.
- [x] Validators updated in `src/utils/enumValidators.ts`.
- [x] Repository and controller updated to eliminate invalid status writes.
- [x] Tests updated and all test suites pass 100%.
- [x] Manual test guide and acceptance record documented.
