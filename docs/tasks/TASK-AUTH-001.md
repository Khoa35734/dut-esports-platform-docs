TASK-ID: TASK-AUTH-001
Title: Align authentication endpoints and profile retrieval with unified identity

Goal:
Ensure that all authentication and profile endpoints (`/api/auth/me`, `/api/auth/participant/me`, `/api/auth/participant/profile`) seamlessly resolve identity across the unified `users` and linked `participants` model per NSC-FOUND-001, providing consistent user profile data without exposing password hashes or violating the Zero CCCD Invariant.

Requirements:
SRS 3.1 (SV-01, SV-02, SV-03, SV-04), SRS 5.1 (Auth Security & JWT), NFR-SEC-01 (Zero CCCD), NFR-SEC-06 (Bcrypt cost >= 12), NSC-FOUND-001 (Unified Identity).

Conflict IDs:
RC-AUTH-001, RC-RBAC-001

Current Behavior:
1. `TASK-FOUND-001D` successfully updated `studentRegister`, `studentLogin`, and password hashing to unified `users`.
2. `getParticipantMe` and `getMe` retrieve profile data from `participants` and `users` respectively.
3. Need to ensure `getParticipantMe` returns linked `users` metadata (e.g. `user_id`, `role = 'participant'`, `is_active`) and vice-versa if a participant queries `/api/auth/me`.
4. Ensure no password hash or sensitive field leaks into profile responses.

Target Behavior:
1. Profile Resolution:
   - `/api/auth/participant/me` returns combined participant profile with canonical `user_id`, `username`, `email`, `role = 'participant'`, `status`, and KYC URLs.
   - If an authenticated participant calls `/api/auth/me`, response returns unified user details safely.
2. Zero Leaks:
   - Zero CCCD fields, zero password hashes in all auth responses.
3. Tests & Verification:
   - Type check and test suite pass 100%.

Scope:
- `Web-giai-dau/backend/src/controllers/auth.ts`
- `Web-giai-dau/backend/src/routes/auth.routes.ts`
- `Web-giai-dau/backend/src/middleware/auth.ts`

Out of Scope:
- Modifying tournament or bracket controllers.
- Modifying database schema.

Affected Modules:
`backend/controllers/auth`, `backend/middleware/auth`, `backend/routes/auth`

Dependencies:
`TASK-FOUND-001G` (COMPLETED & ACCEPTED)

Business Rules:
- BR-AUTH-001, BR-AUTH-002, NSC-FOUND-001.

RBAC Rules:
- RBAC-001 through RBAC-004.

Workflow:
- WF-001: Registration, Login, Profile Management.

Schema Impact:
`NONE`.

API Impact:
`COMPATIBLE_EXTENDED` (Adds canonical user details to profile endpoints).

Constraints:
- Zero CCCD Invariant strictly maintained.
- Bcrypt cost >= 12 maintained.

Acceptance Criteria:
- `/api/auth/participant/me` returns linked `user_id` and profile status.
- No password hashes or sensitive fields exposed.
- All test suites pass 100%.

Definition of Done:
- [x] Task specification reviewed and approved.
- [x] Profile endpoints verified with unified identity.
- [x] All unit/integration tests pass.
- [x] `tsc --noEmit` exits 0.
- [x] Manual test guide and acceptance record documented.
