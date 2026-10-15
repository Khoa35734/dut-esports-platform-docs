# Developer Task Specification: TASK-RBAC-001

TASK-ID: TASK-RBAC-001
Title: Align Authentication & Authorization Middleware with Canonical users.role Matrix (admin, ctv, seasonal_staff, participant)
Status: IMPLEMENTED / READY_FOR_REVIEW

Goal:
Enforce the 4 canonical user roles (`admin`, `ctv`, `seasonal_staff`, `participant`) across backend authentication and authorization middleware per SRS Section 2.2, Section 5.1 (NFR-SEC-05), and docs/RBAC.md (RBAC-001 through RBAC-012), resolving legacy token-type bifurcation, securing unprotected routes, granting CTV access to KYC review, and returning standard 401/403 status codes with consistent error envelopes.

Requirements:
- SRS Section 2.2: User Classes and Characteristics (Admin, CTV Thường trực / ctv, CTV Thời vụ / seasonal_staff, Sinh viên / participant)
- SRS Section 5.1: NFR-SEC-05 (Role-Based Access Control - RBAC multi-tier enforcement)
- SRS Section 10.3.1: Data Permission Matrix
- FR-AUTH-01: Authentication and Role Boundaries
- FR-KYC-03: KYC Review and Approval by CTV Thường trực and Admin
- NFR-SEC-05: Strict role verification at middleware layer; unauthorized requests rejected immediately

Conflict IDs:
- RC-ENUM-001: Legacy DB schema restricted `users.role` to ('admin', 'ctv'), whereas SRS 6.4 DDL and docs/RBAC.md establish 4 canonical roles ('participant', 'admin', 'ctv', 'seasonal_staff'). (Schema resolved in Phase 0; middleware and routing require alignment).

Current Behavior:
1. `backend/src/middleware/auth.ts`:
   - `verifyToken` checks `decoded.kind === 'participant'` and rejects with 403, but never verifies whether `decoded.role` is valid or active in `users.role`.
   - `verifyParticipantToken` checks `decoded.kind !== 'participant'`, ignoring unified user identity where `users.role = 'participant'`.
   - `verifyAdmin`, `verifyCTV`, and `verifyStaff` check `req.user?.role`, but lack a reusable, composable role checking utility (`requireRoles`).
   - `verifyAnyToken` branches on `decoded.kind === 'participant'`, leaving `req.user` undefined for participant tokens and causing inconsistency for shared routes.
2. Route Protection Gaps:
   - `admin.routes.ts`: `router.use(verifyToken, verifyAdmin)` locks the entire router to Admin-only. This erroneously blocks CTV Thường trực (`role = 'ctv'`) from accessing KYC review and approval endpoints (`/participants`, `/participants/:id/approve`, `/participants/:id/reject`, `/participants/review`), directly violating SRS Section 2.2 and RBAC-010.
   - `tournament.routes.ts`: `POST /` (`tournamentController.create`), `PUT /:id`, and `DELETE /:id` only use `verifyToken` without checking `req.user.role`. A user with role `seasonal_staff` or unverified role can execute tournament creation/updates (violating RBAC-013, RBAC-015).
   - `registration.routes.ts`: `DELETE /:id` and staff operations (`/tournament/:id/participants-management`, `/confirm-participation`, `/export-participants-excel`) only use `verifyToken` without role checks.
   - `checkin.routes.ts`: `GET /` (`checkinController.listByTournament`) uses `verifyToken` without requiring staff role (`admin`, `ctv`, `seasonal_staff`).
   - `upload.routes.ts`: `POST /banner` uses `verifyToken` without verifying that the caller is `admin` or `ctv`.
3. Token Signing:
   - `signParticipantToken` in `backend/src/controllers/auth.ts` does not explicitly include `role: 'participant'`, perpetuating token payload bifurcation.

Target Behavior:
1. Composable and Robust RBAC Middleware:
   - Introduce `requireRoles(...roles: UserRole[])`:
     - Checks authentication (`req.user` or `req.participant`). If missing, returns `401 Unauthorized` (`{ success: false, message: 'Yêu cầu đăng nhập' }`).
     - Resolves user's effective role (`req.user?.role || req.participant?.role || (req.participant ? 'participant' : undefined)`).
     - If effective role is not included in `roles`, returns `403 Forbidden` (`{ success: false, message: 'Quyền hạn không đủ để thực hiện thao tác này' }`).
   - Refactor `verifyAdmin` as `requireRoles('admin')`.
   - Refactor `verifyCTV` as `requireRoles('admin', 'ctv')`.
   - Refactor `verifyStaff` as `requireRoles('admin', 'ctv', 'seasonal_staff')`.
   - Update `verifyToken` to populate `req.user` with decoded token, verifying valid JWT structure and canonical role.
   - Update `verifyParticipantToken` to accept tokens where `role === 'participant'` or `kind === 'participant'`, populating both `req.participant` and `req.user` for unified handling.
   - Update `verifyAnyToken` to ensure `req.user` is always populated for all authenticated roles (`admin`, `ctv`, `seasonal_staff`, `participant`), while `req.participant` is also populated when the role is `participant`.
2. Aligned Route Security:
   - `admin.routes.ts`:
     - Keep `verifyAdmin` for system administration (`/dashboard`, `/stats`, `/ctvs/*`, `/users/*`, and account locking `PATCH /participants/:id/status`).
     - Apply `verifyCTV` (allowing both Admin and CTV) to KYC endpoints (`GET /participants`, `GET /participants/:id`, `POST /participants/:id/approve`, `POST /participants/:id/reject`, `POST /participants/review`) per SRS 2.2 and RBAC-009/RBAC-010.
   - `tournament.routes.ts`:
     - Secure `POST /` with `verifyCTV` (Admin + CTV only per RBAC-013).
     - Secure `PUT /:id` and `DELETE /:id` with `verifyCTV` (Admin + CTV only per RBAC-015).
     - Secure `GET /:id/registrations` with `verifyStaff` (Admin, CTV, seasonal_staff).
   - `registration.routes.ts`:
     - Secure `DELETE /:id` with `verifyCTV`.
     - Secure `/tournament/:id/participants-management` and `/confirm-participation` with `verifyStaff`.
     - Secure `/tournament/:id/export-participants-excel` with `verifyCTV`.
   - `checkin.routes.ts`:
     - Secure `GET /` with `verifyStaff` (RBAC-026).
   - `upload.routes.ts`:
     - Secure `POST /banner` with `verifyCTV`.
3. Standardized Error Envelope:
   - Missing / invalid token returns `401 Unauthorized` with `{ success: false, message: '...' }`.
   - Insufficient permissions returns `403 Forbidden` with `{ success: false, message: '...' }`.

Scope:
- `backend/src/middleware/auth.ts`: Add `requireRoles`, align `verifyToken`, `verifyParticipantToken`, `verifyAdmin`, `verifyCTV`, `verifyStaff`, `verifyAnyToken`.
- `backend/src/routes/admin.routes.ts`: Split admin-only routes vs KYC review routes (allow CTV for KYC).
- `backend/src/routes/tournament.routes.ts`: Secure unprotected tournament routes with `verifyCTV` / `verifyStaff`.
- `backend/src/routes/registration.routes.ts`: Secure staff/admin participant management endpoints.
- `backend/src/routes/checkin.routes.ts`: Secure check-in listing with `verifyStaff`.
- `backend/src/routes/upload.routes.ts`: Secure banner upload with `verifyCTV`?.
- `backend/src/controllers/auth.ts`: Ensure `signParticipantToken` sets `role: 'participant'`.
- `backend/tests/`: Add comprehensive tests covering 4 roles and route authorization.

Out of Scope:
- Tournament-specific staff assignment validation (checking if CTV/seasonal staff is assigned to the specific tournament via `tournament_organizers`) → `TASK-RBAC-002`.
- Secure static asset access, file shielding, and signed URL generation (max 5 min) for KYC images → `TASK-RBAC-003`.
- Tournament state machine validations (e.g. draft → open_registration prerequisite checks) → `TASK-DOM-002`.
- Database DDL / migration changes (already completed in Phase 0).

Affected Modules:
- `backend/src/middleware/`
- `backend/src/routes/`
- `backend/src/controllers/`
- `backend/src/types/`
- `backend/tests/`

Likely Files:
- `Web-giai-dau/backend/src/middleware/auth.ts`
- `Web-giai-dau/backend/src/routes/admin.routes.ts`
- `Web-giai-dau/backend/src/routes/tournament.routes.ts`
- `Web-giai-dau/backend/src/routes/registration.routes.ts`
- `Web-giai-dau/backend/src/routes/checkin.routes.ts`
- `Web-giai-dau/backend/src/routes/upload.routes.ts`
- `Web-giai-dau/backend/src/controllers/auth.ts`
- `Web-giai-dau/backend/src/types/index.ts`
- `Web-giai-dau/backend/tests/auth.test.ts`
- `Web-giai-dau/backend/tests/rbac.test.ts`

Dependencies:
- `TASK-AUTH-002` [DONE]: JWT payload structure matches unified identity.
- `TASK-AUTH-003` [DONE]: Password hashing and confidentiality verified.
- `TASK-FOUND-001B` [DONE]: Unified schema with 4 canonical roles.

Business Rules:
- `BR-AUTH-001`: Email verification before tournament registration
- `BR-KYC-002`: Zero CCCD Invariant
- `BR-KYC-003`: KYC status controls tournament access
- `BR-KYC-004`: KYC image access control

RBAC Rules:
- `RBAC-001` to `RBAC-004`: Public auth endpoints (/auth/register, /auth/login, /auth/verify-email, /auth/reset-password)
- `RBAC-005`: Read own profile (all authenticated roles)
- `RBAC-006`: List all user accounts (Admin only)
- `RBAC-007`: Lock/unlock accounts (Admin only)
- `RBAC-008`: Submit KYC (Participant only)
- `RBAC-009`: View KYC images (Admin, CTV)
- `RBAC-010`: Approve/Reject KYC (Admin, CTV)
- `RBAC-011`: Read full contact data (Admin, CTV assigned)
- `RBAC-012`: Read masked contact data (CTV, seasonal_staff)
- `RBAC-013`: Create tournament (Admin, CTV)
- `RBAC-015`: Tournament status change (Admin, CTV)
- `RBAC-026`: Review check-in on map (Admin, CTV, seasonal_staff)

Workflow:
- `WF-001`: User Registration & KYC (Steps 9-10b: CTV Thường trực and Admin can review, approve, or reject KYC submissions).

Schema Impact:
- NONE

API Impact:
- COMPATIBLE_EXTENDED:
  - Valid client requests with proper role tokens retain existing contract and responses.
  - Endpoints previously lacking role checks now reject unauthorized roles with `403 Forbidden`.
  - CTV accounts gain access to KYC review and approval endpoints as specified in SRS 2.2.

Implementation Steps:
1. In `backend/src/controllers/auth.ts`, update `signParticipantToken` to include `role: 'participant'` in the JWT payload so that participant tokens contain canonical role information.
2. In `backend/src/middleware/auth.ts`:
   - Implement `requireRoles(...roles: UserRole[])`:
     - Checks if caller is authenticated (via `req.user` or `req.participant`); returns `401 Unauthorized` `{ success: false, message: 'Yêu cầu đăng nhập' }` if missing.
     - Determines `userRole = req.user?.role || req.participant?.role || (req.participant ? 'participant' : undefined)`.
     - Validates `userRole && roles.includes(userRole)`. If false, returns `403 Forbidden` `{ success: false, message: 'Quyền hạn không đủ để thực hiện thao tác này' }`.
     - Ensures `req.user` is normalized with decoded identity.
   - Refactor `verifyAdmin` to `requireRoles('admin')`.
   - Refactor `verifyCTV` to `requireRoles('admin', 'ctv')`.
   - Refactor `verifyStaff` to `requireRoles('admin', 'ctv', 'seasonal_staff')`.
   - Update `verifyParticipantToken` to accept either `kind === 'participant'` or `role === 'participant'`, populating both `req.participant` and `req.user`.
   - Update `verifyAnyToken` to attach decoded user info to `req.user` regardless of role, and to `req.participant` if `role === 'participant'`.
3. In `backend/src/routes/admin.routes.ts`:
   - Remove blanket `router.use(verifyToken, verifyAdmin)`.
   - Group admin-only routes (`/dashboard`, `/stats`, `/ctvs/*`, `/users/*`, `PATCH /participants/:id/status`) under `verifyToken, verifyAdmin`.
   - Group KYC review routes (`GET /participants`, `GET /participants/:id`, `POST /participants/:id/approve`, `POST /participants/:id/reject`, `POST /participants/review`) under `verifyToken, verifyCTV` (allowing both Admin and CTV).
4. In `backend/src/routes/tournament.routes.ts`:
   - Add `verifyCTV` to `POST /` (`tournamentController.create`).
   - Add `verifyCTV` to `PUT /:id` (`tournamentController.update`) and `DELETE /:id` (`tournamentController.remove`).
   - Add `verifyStaff` to `GET /:id/registrations` (`registrationController.listByTournament`).
5. In `backend/src/routes/registration.routes.ts`:
   - Add `verifyCTV` to `DELETE /:id`.
   - Add `verifyStaff` to `/tournament/:id/participants-management`, `/tournaments/:id/participants-management`, `/confirm-participation`.
   - Add `verifyCTV` to `/tournament/:id/export-participants-excel`, `/tournaments/:id/export-participants-excel`.
6. In `backend/src/routes/checkin.routes.ts`:
   - Add `verifyStaff` to `GET /` (`checkinController.listByTournament`).
7. In `backend/src/routes/upload.routes.ts`:
   - Add `verifyCTV` to `POST /banner` (`uploadController.uploadBanner`).
8. Add tests in `backend/tests/rbac.test.ts` verifying all role permissions and boundary rejections (401 and 403). Run `npm run typecheck` and `npm test`.

Constraints:
- ZERO CCCD Invariant: Absolute prohibition on any CCCD/CMND fields or parameters (AGENTS.md § 2.1).
- HTTP Status Codes:
  - `401 Unauthorized` for missing or invalid JWT tokens.
  - `403 Forbidden` for authenticated tokens with insufficient role privileges.
  - Consistent error envelope `{ success: false, message: string }`.
- Layered Architecture: All authorization logic belongs in middleware/routes; no raw SQL in controllers/middleware.
- Backward Compatibility: Tokens issued with legacy `kind: 'participant'` must continue to pass participant checks.

Tests Required:
- Unit tests for `requireRoles`:
  - Grants access when user role is in the allowed list.
  - Returns 403 when user role is authenticated but not in the allowed list.
  - Returns 401 when no token/user payload exists.
- Unit tests for role middlewares:
  - `verifyAdmin`: Allows `admin`; blocks `ctv`, `seasonal_staff`, `participant` with 403.
  - `verifyCTV`: Allows `admin` and `ctv`; blocks `seasonal_staff` and `participant` with 403.
  - `verifyStaff`: Allows `admin`, `ctv`, and `seasonal_staff`; blocks `participant` with 403.
  - `verifyParticipantToken`: Allows `participant`; blocks `admin`, `ctv`, `seasonal_staff` with 403.
- Route authorization integration tests:
  - `POST /api/tournaments`: 201/200 for `admin` & `ctv`; 403 for `seasonal_staff` & `participant`; 401 for unauthenticated.
  - `POST /api/admin/participants/:id/approve`: Accessible by `admin` & `ctv`; 403 for `seasonal_staff` & `participant`.
  - `GET /api/admin/users`: Accessible by `admin` only; 403 for `ctv`, `seasonal_staff`, `participant`.
  - `GET /api/checkins`: Accessible by `admin`, `ctv`, and `seasonal_staff`; 403 for `participant`.
  - `POST /api/upload/banner`: Accessible by `admin` & `ctv`; 403 for `seasonal_staff` & `participant`.

Acceptance Criteria:
- Given an unauthenticated request, When calling any protected route, Then API responds with 401 Unauthorized `{ success: false, message: '...' }`.
- Given a user with role `participant`, When calling `POST /api/tournaments` or `GET /api/admin/users`, Then API responds with 403 Forbidden.
- Given a user with role `seasonal_staff`, When calling `POST /api/tournaments` or `POST /api/admin/participants/:id/approve`, Then API responds with 403 Forbidden.
- Given a user with role `seasonal_staff`, When calling staff routes (e.g. `GET /api/checkins`), Then request is authorized and passes middleware.
- Given a user with role `ctv`, When calling KYC approval (`POST /api/admin/participants/:id/approve`) or tournament creation (`POST /api/tournaments`), Then request is authorized and passes middleware.
- Given a user with role `ctv`, When calling Admin-only routes (`GET /api/admin/users`, `POST /api/admin/ctvs`, `PATCH /api/admin/participants/:id/status`), Then API responds with 403 Forbidden.
- Given a user with role `admin`, When calling any admin, CTV, tournament, KYC, or staff route, Then request is authorized.
- Given a participant token (both new with `role: 'participant'` and legacy with `kind: 'participant'`), When accessing participant routes, Then request is authorized.

Definition of Done:
- [ ] Requirements SRS Section 2.2, Section 5.1 (NFR-SEC-05), and docs/RBAC.md RBAC-001 through RBAC-012 implemented
- [ ] `requireRoles` utility created and all role middlewares (`verifyAdmin`, `verifyCTV`, `verifyStaff`, `verifyParticipantToken`, `verifyToken`, `verifyAnyToken`) aligned
- [ ] KYC review/approval endpoints in `admin.routes.ts` permit both `admin` and `ctv`, while user and CTV management remains strictly `admin`-only
- [ ] Unprotected routes in `tournament.routes.ts`, `registration.routes.ts`, `checkin.routes.ts`, and `upload.routes.ts` secured with appropriate role guards
- [ ] All error responses return standard JSON envelope with 401 or 403 status codes
- [ ] Required unit and integration tests pass (`npm run test`)
- [ ] TypeScript strict mode passes (`npm run typecheck`)
- [ ] No regression introduced to existing authentication or participant flows
- [ ] Code reviewed and approved by Reviewer agent

Rollback / Safety:
- Changes are strictly confined to TypeScript middleware and Express route declarations; no database schema or persistent data modifications are involved.
- In case of unexpected issues, the commit can be cleanly reverted without database rollback.
