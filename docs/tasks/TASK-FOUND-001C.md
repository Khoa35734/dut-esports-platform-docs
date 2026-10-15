TASK-ID: TASK-FOUND-001C
Title: Update ORM/domain mappings for identity

Goal:
Update TypeScript domain types (`backend/src/types/index.ts`) and data access layer repositories (`participant.ts`, `user.ts`) to align with the unified identity model (`users 1:1 participants` via `participants.user_id`), canonical roles (`participant`, `admin`, `ctv`, `seasonal_staff`), and canonical status enums without breaking existing operational queries.

Requirements:
SRS 3.1, SRS 6.2 (Table users, participants), SRS 6.4 DDL, NSC-FOUND-001, NSC-FOUND-004, NSC-FOUND-005

Conflict IDs:
RC-AUTH-001, RC-ENUM-001, RC-ENUM-002, RC-ENUM-004

Current Behavior:
1. `UserRole` in `backend/src/types/index.ts` is only `'admin' | 'ctv'`.
2. `Participant` and `SafeParticipant` do not include the mandatory foreign key `user_id: string`.
3. `RegistrationStatus` contains non-canonical `'cancelled'`.
4. `TeamJoinRequestStatus` contains non-canonical `'cancelled'`.
5. `PARTICIPANT_SAFE_COLUMNS` in `repositories/participant.ts` omits `user_id`.
6. `participantRepository` lacks `findByUserId` and `findSafeByUserId`.
7. `participantRepository.create` does not take or store `user_id`.
8. `userRepository` lacks helper methods to retrieve user with linked participant profile.

Target Behavior:
1. `UserRole` in `types/index.ts` updated to:
   `export type UserRole = 'participant' | 'admin' | 'ctv' | 'seasonal_staff';`
2. `Participant` and `SafeParticipant` interfaces include `user_id: string`.
3. `RegistrationStatus` normalized to:
   `export type RegistrationStatus = 'pending' | 'approved' | 'rejected';`
4. `TeamJoinRequestStatus` normalized to:
   `export type TeamJoinRequestStatus = 'pending' | 'accepted' | 'rejected';`
5. `PARTICIPANT_SAFE_COLUMNS` in `repositories/participant.ts` includes `user_id`.
6. `participantRepository` provides:
   - `findByUserId(userId: string): Promise<Participant | null>`
   - `findSafeByUserId(userId: string): Promise<SafeParticipant | null>`
   - `create(data: { user_id: string; ... })` supporting `user_id`.
7. `userRepository` provides:
   - Queries handling all 4 canonical roles.
   - `findUserWithParticipant(userId: string): Promise<{ user: User; participant: Participant | null } | null>`.
8. TypeScript strict typecheck (`tsc --noEmit`) passes with 0 errors.

Scope:
- `Web-giai-dau/backend/src/types/index.ts`
- `Web-giai-dau/backend/src/repositories/participant.ts`
- `Web-giai-dau/backend/src/repositories/user.ts`

Out of Scope:
- Modifying authentication controllers, JWT middleware, or routes (`TASK-FOUND-001D`).
- Modifying database tables or executing SQL migrations (completed in `TASK-FOUND-001B`).
- Frontend source code.

Affected Modules:
`backend/types`, `backend/repositories`

Likely Files:
- `Web-giai-dau/backend/src/types/index.ts`
- `Web-giai-dau/backend/src/repositories/participant.ts`
- `Web-giai-dau/backend/src/repositories/user.ts`

Dependencies:
`TASK-FOUND-001B` (COMPLETED & ACCEPTED)

Business Rules:
- BR-KYC-002: Zero CCCD Invariant.
- NSC-FOUND-001: Unified identity model (`users 1:1 participants`).
- NSC-FOUND-004: Canonical `team_join_requests.status`.
- NSC-FOUND-005: Canonical `registrations.status`.

RBAC Rules:
- RBAC-001 to RBAC-004: Unified role definitions (`participant`, `admin`, `ctv`, `seasonal_staff`).

Workflow:
- WF-001: Participant identity lookup and profile management.

Schema Impact:
`NONE` (Schema was updated and reconciled in `TASK-FOUND-001B`).

API Impact:
`INTERNAL` (Repository and TypeScript interface level only).

Implementation Steps:
1. Update `UserRole`, `RegistrationStatus`, `TeamJoinRequestStatus` in `Web-giai-dau/backend/src/types/index.ts`.
2. Add `user_id: string` to `Participant` and `SafeParticipant` in `Web-giai-dau/backend/src/types/index.ts`.
3. Add `user_id` to `PARTICIPANT_SAFE_COLUMNS` and update queries in `repositories/participant.ts`.
4. Add `findByUserId` and `findSafeByUserId` to `participantRepository`.
5. Support `user_id` in `participantRepository.create`.
6. Add `findUserWithParticipant` in `repositories/user.ts`.
7. Verify all references compile cleanly with `npx tsc --noEmit`.

Constraints:
- Preserve Zero CCCD Invariant.
- Do not break backward compatibility for existing repository callers (keep parameters backward-compatible where appropriate).
- Strict TypeScript compliance (`noImplicitAny: true`, `strictNullChecks: true`).

Tests Required:
- `tsc --noEmit` pass with 0 errors.
- Verification script testing `findByUserId`, `findSafeByUserId`, and `findUserWithParticipant` against live database.

Acceptance Criteria:
- Given a valid `user_id`, When `participantRepository.findByUserId(userId)` is called, Then it returns the corresponding `Participant` with `user_id`.
- Given a valid `user_id`, When `userRepository.findUserWithParticipant(userId)` is called, Then it returns both the `User` and their `Participant` profile.
- All domain enums (`UserRole`, `RegistrationStatus`, `TeamJoinRequestStatus`) strictly match SRS 6.4 and NSC-FOUND-004/005.
- `npx tsc --noEmit` completes with 0 errors.

Definition of Done:
- [x] Task specification reviewed and approved.
- [x] Type definitions updated in `types/index.ts`.
- [x] Repository methods added and verified in `participant.ts` and `user.ts`.
- [x] `tsc --noEmit` passes cleanly.
- [x] Manual test guide and acceptance record documented.

Rollback / Safety:
- Changes are purely TypeScript source code in `backend/src/types/index.ts` and `backend/src/repositories/`. Git revert can safely restore previous files if needed.
