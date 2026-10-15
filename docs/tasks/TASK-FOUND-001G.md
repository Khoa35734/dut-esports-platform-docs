TASK-ID: TASK-FOUND-001G
Title: Run Phase 0 migration and regression verification

Goal:
Perform end-to-end regression and migration verification across the full scope of Phase 0 Foundation Fixes (NSC-FOUND-001 through NSC-FOUND-005, NFR-SEC-01, NFR-SEC-06), verifying live database schema consistency, unified authentication, canonical status constraints, zero CCCD compliance, and test suite health before closing Phase 0.

Requirements:
NSC-FOUND-001 to NSC-FOUND-005, NFR-SEC-01 (Zero CCCD), NFR-SEC-06 (Bcrypt cost >= 12), SRS 6.2, SRS 6.4.

Conflict IDs:
RC-TEST-001

Current Behavior:
Phase 0 tasks TASK-FOUND-001A through TASK-FOUND-001F have implemented and verified individual foundation changes:
- 001A: Schema difference inventory.
- 001B: Migration `001_reconcile_srs_schema.sql` applied to live PostgreSQL.
- 001C: Updated ORM / domain mappings and types for identity.
- 001D: Updated authentication references to unified identity.
- 001E: Normalized status constraints for registrations and team join requests.
- 001F: Deprecated legacy AI check-in dependencies without premature table drops.

Target Behavior:
1. End-to-end verification script executing against live Supabase PostgreSQL:
   - Validates live schema tables and foreign keys (users 1:1 participants).
   - Validates live CHECK constraints (`chk_registration_status`, `chk_tjr_status`).
   - Verifies deprecation safety (AI tables present, not referenced by active flows).
   - Verifies Bcrypt cost >= 12 on all new password operations.
   - Verifies strict absence of CCCD fields/endpoints across all modules.
2. Full test suite execution:
   - All 79 tests across all 23 test suites pass 100%.
   - `tsc --noEmit` exits 0 with no errors.
3. Phase 0 milestone completion documentation.

Scope:
- Verification script in `Web-giai-dau/backend/`
- Full test suite run (`npm test`)
- Full TypeScript check (`tsc --noEmit`)
- Phase 0 status update in `docs/PROJECT_PLAN.md`

Out of Scope:
- Modifying Phase 1+ features (handled in subsequent phases).

Affected Modules:
All backend modules (verification only).

Dependencies:
`TASK-FOUND-001F` (COMPLETED & ACCEPTED)

Business Rules:
- NSC-FOUND-001 through NSC-FOUND-005.
- NFR-SEC-01, NFR-SEC-06.

RBAC Rules:
- All RBAC rules maintained.

Workflow:
- WF-001 through WF-004 foundation validation.

Schema Impact:
`NONE` (Verification only, no DDL modifications).

API Impact:
`NONE` (Verification only).

Implementation Steps:
1. Create and execute an end-to-end verification script against live database.
2. Run `tsc --noEmit` and `npm test` across all suites.
3. Verify that Phase 0 can be marked `DONE`.
4. Document acceptance record and manual verification steps.

Constraints:
- Zero CCCD Invariant strictly maintained.
- All 79 tests must pass without failures.

Acceptance Criteria:
- Live database schema complies with SRS v1.3 and NSC-FOUND-001..005.
- Zero CCCD fields exist across DB schema, models, DTOs, and API responses.
- `tsc --noEmit` passes with 0 errors.
- `npm test` passes with 100% success rate (79/79 tests).

Definition of Done:
- [x] Task specification reviewed and approved.
- [x] Comprehensive verification script executed successfully against live DB.
- [x] All 79 unit/integration tests pass.
- [x] TypeScript typecheck passes with 0 errors.
- [x] Phase 0 status updated in `docs/PROJECT_PLAN.md`.
- [x] Manual test guide and acceptance record documented.
