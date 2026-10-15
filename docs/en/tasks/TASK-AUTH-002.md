TASK-ID: TASK-AUTH-002
Title: Ensure JWT payload matches unified identity structure across all token generation and verification points

Goal:
Standardize and verify JWT token generation, decoding, and verification middleware across all actors (Admin, CTV, Seasonal Staff, and Participants) to guarantee consistent payload structure, preventing privilege escalation while supporting dual-referencing (`id` and `user_id`) for participants per NSC-FOUND-001.

Requirements:
SRS 5.1 (Auth Security & JWT Structure), SRS 3.1 (SV-02), SRS 3.2 (AD-05), NSC-FOUND-001 (Unified Identity).

Conflict IDs:
RC-AUTH-002, RC-RBAC-002

Current Behavior:
1. `signParticipantToken` in `auth.ts` signs a token with `kind: 'participant'`, `id`, `user_id`, `username`, `full_name`, `account_type`, `status`.
2. `signToken` signs a token with `kind: 'user'`, `id`, `username`, `full_name`, `role`.
3. `verifyParticipantToken` verifies `kind === 'participant'`.
4. `verifyToken` verifies `kind !== 'participant'`.
5. `verifyAnyToken` supports both.
6. Need to ensure `seasonal_staff` role is recognized in `signToken` and RBAC middleware, and token expiration / secret configs are centralized.

Target Behavior:
1. JWT Payload Specification:
   - For Staff (`users`): `{ kind: 'user', id: string, username: string, full_name: string, role: 'admin' | 'ctv' | 'seasonal_staff' }`.
   - For Athletes (`participants`): `{ kind: 'participant', id: string, user_id: string, username: string, full_name: string, account_type: 'internal' | 'external', status: ParticipantStatus }`.
2. Token Verification & Middleware:
   - `verifyToken` allows `admin`, `ctv`, and `seasonal_staff` (with appropriate role checks).
   - `verifyParticipantToken` attaches `req.participant` with complete identity fields.
   - `verifyAnyToken` safely handles both types for shared endpoints (e.g. upload).
3. Unit & Integration Tests:
   - Dedicated unit tests validating token expiration, signature integrity, role discrimination, and tampering rejection.
   - 100% test pass rate.

Scope:
- `Web-giai-dau/backend/src/middleware/auth.ts`
- `Web-giai-dau/backend/src/controllers/auth.ts`
- `Web-giai-dau/backend/tests/auth.test.ts`

Out of Scope:
- Modifying tournament or bracket controllers.
- Modifying database schema.

Affected Modules:
`backend/middleware/auth`, `backend/controllers/auth`, `backend/types`

Dependencies:
`TASK-AUTH-001` (COMPLETED & ACCEPTED)

Business Rules:
- BR-AUTH-001, NSC-FOUND-001.

RBAC Rules:
- RBAC-001 through RBAC-005.

Workflow:
- WF-001: Authentication & Token Management.

Schema Impact:
`NONE`.

API Impact:
`COMPATIBLE_EXTENDED`.

Constraints:
- Zero CCCD Invariant strictly maintained.
- Secret keys never exposed in logs or API responses.

Acceptance Criteria:
- All generated tokens match canonical structure.
- Privilege escalation attempts between user and participant tokens are blocked (403 Forbidden).
- `tsc --noEmit` and `npm test` pass with 0 errors.

Definition of Done:
- [x] Task specification reviewed and approved.
- [x] Token payloads verified for all roles.
- [x] Role segregation verified.
- [x] All unit/integration tests pass.
- [x] `tsc --noEmit` exits 0.
- [x] Manual test guide and acceptance record documented.
