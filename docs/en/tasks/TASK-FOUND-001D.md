TASK-ID: TASK-FOUND-001D
Title: Update authentication references to use unified identity

Goal:
Update authentication controllers (`auth.ts`), password hashing, JWT token generation, and profile management to authenticate all actors (students, CTVs, admins) through the unified `users` identity table while linking students 1:1 to their `participants` profile via `participants.user_id` (NSC-FOUND-001), strictly respecting the Zero CCCD Invariant and bcrypt cost >= 12 security policy.

Requirements:
SRS 3.1 (SV-01, SV-02, SV-03, SV-04), SRS 5.1 (Auth Security), SRS 6.2 (Tables users & participants), NFR-SEC-01 (Zero CCCD), NFR-SEC-06 (Bcrypt cost >= 12 / Argon2id), NSC-FOUND-001 (Unified Identity).

Conflict IDs:
RC-AUTH-001, RC-SEC-001

Current Behavior:
1. `studentRegister` creates a row in `participants` directly with its own `password_hash`, without creating or linking a `users` record.
2. `studentLogin` checks credentials directly against `participants` table (`findPasswordHashByLoginIdentifier`).
3. Bcrypt cost used in `studentRegister` is 10 instead of >= 12 (NFR-SEC-06 violation).
4. `signParticipantToken` does not include `user_id` in the JWT payload.
5. `updateParticipantProfile` modifies password only in `participants` rather than the canonical `users` table.

Target Behavior:
1. `studentRegister`:
   - Checks identifier/email uniqueness across both `users` and `participants`.
   - Hashes password using bcrypt cost >= 12.
   - Creates a transaction that:
     a) Inserts user record into `users` (`role = 'participant'`, `is_active = true`).
     b) Inserts student profile into `participants` linked 1:1 by `user_id = users.id`.
   - Returns signed JWT token including `user_id` and initial `pending-approval` status.
2. `studentLogin`:
   - Authenticates credentials against canonical `users` table (or fallback to `participants` for transitional accounts).
   - Retrieves linked `participants` profile via `participantRepository.findByUserId(user.id)`.
   - Enforces `is_active` check on both account and participant profile.
   - Signs JWT token with `user_id`, `id` (participant.id), `full_name`, `account_type`, `status`.
   - Preserves KYC redirect routing: `pending-approval` for `pending`, `rejected-info` for `rejected`, `/` for `approved`.
3. `signParticipantToken`:
   - Includes `user_id: participant.user_id` in JWT payload.
4. `updateParticipantProfile`:
   - When password is changed, updates `password_hash` with bcrypt cost >= 12 in `users` and syncs `participants`.
5. Strict backward compatibility:
   - All existing 77 tests in the backend test suite continue to pass 100%.

Scope:
- `Web-giai-dau/backend/src/controllers/auth.ts`
- `Web-giai-dau/backend/src/types/index.ts` (JwtPayload interface)
- `Web-giai-dau/backend/src/middleware/auth.ts` (if needed for user_id mapping)

Out of Scope:
- Modifying tournament, registration, or check-in controllers (handled in subsequent phases).
- Frontend UI modifications.
- Dropping any legacy columns or tables.

Affected Modules:
`backend/controllers/auth`, `backend/types`, `backend/middleware`

Likely Files:
- `Web-giai-dau/backend/src/controllers/auth.ts`
- `Web-giai-dau/backend/src/types/index.ts`
- `Web-giai-dau/backend/src/middleware/auth.ts`

Dependencies:
`TASK-FOUND-001C` (COMPLETED & ACCEPTED)

Business Rules:
- BR-AUTH-001, BR-AUTH-002: Email verification and password hashing standards.
- BR-KYC-001, BR-KYC-002: Zero CCCD Invariant.
- NSC-FOUND-001: Unified identity model (`users 1:1 participants`).

RBAC Rules:
- RBAC-001 to RBAC-004: Role segregation between admin, ctv, seasonal_staff, participant.

Workflow:
- WF-001: Registration, Login, and KYC Submission workflow.

Schema Impact:
`NONE` (Schema and migration completed in `TASK-FOUND-001B`).

API Impact:
`COMPATIBLE_EXTENDED` (Adds `user_id` to responses/tokens, retains all existing fields).

Implementation Steps:
1. Update `JwtPayload` in `backend/src/types/index.ts` to include `user_id?: string`.
2. Update `signParticipantToken` in `backend/src/controllers/auth.ts` to include `user_id: participant.user_id`.
3. Update `studentRegister` to hash passwords with cost 12 and atomically create `users` (role='participant') + `participants` (user_id=users.id).
4. Update `studentLogin` to authenticate against `users` and map to linked `participants` profile, retaining exact login status responses.
5. Update `updateParticipantProfile` to update `password_hash` in `users` table as well.
6. Run `npm test` and `npx tsc --noEmit` to verify 100% test pass rate and type correctness.

Constraints:
- Zero CCCD Invariant strictly enforced (only `student_card_url`, `selfie_with_student_card_url`).
- Bcrypt cost >= 12 enforced for all new hashes.
- Preserve existing redirect and response semantics so existing frontend and tests do not break.

Tests Required:
- Unit & integration tests in `tests/auth.test.ts` and `tests/kyc-lifecycle.test.ts`.
- `npm test` passing 100% (77/77 tests).
- `npx tsc --noEmit` passing with 0 errors.

Acceptance Criteria:
- Given student registration details, When `studentRegister` executes, Then both a `users` row (`role = 'participant'`) and a `participants` row are created with `participants.user_id = users.id`.
- Given student credentials, When `studentLogin` executes, Then credentials match `users.password_hash` and the returned JWT payload contains both `id` and `user_id`.
- Password hashes use bcrypt cost >= 12.
- All existing auth and KYC tests pass without regressions.

Definition of Done:
- [x] Task specification reviewed and approved.
- [x] `JwtPayload` and `signParticipantToken` updated.
- [x] `studentRegister` transactional user+participant creation implemented.
- [x] `studentLogin` unified authentication implemented.
- [x] Bcrypt cost >= 12 verified.
- [x] `npm test` and `tsc --noEmit` pass 100%.
- [x] Manual test guide and acceptance record documented.

Rollback / Safety:
- Changes are in `backend/src/controllers/auth.ts` and `types/index.ts`. Git revert can safely restore previous files if needed.
