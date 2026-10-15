TASK-ID: TASK-FOUND-001B
Title: Create unified users and participants migration

Goal:
Author and execute a robust PostgreSQL migration (`001_reconcile_srs_schema.sql`) that aligns the database schema with SRS 6.4 DDL and final stakeholder decisions (NSC-FOUND-001 to NSC-FOUND-005) without losing existing administrative data.

Requirements:
SRS 6.4 (PostgreSQL DDL), NFR-SEC-04 (UUID PKs)

Conflict IDs:
RC-SCHEMA-001, RC-ENUM-001, RC-ENUM-002, RC-ENUM-003, RC-ENUM-004

Current Behavior:
1. `participants.id` is `TEXT` instead of `UUID`.
2. `participants` has separate authentication credentials (`password_hash`, `username`) instead of linking 1:1 to `users.id`.
3. Foreign keys referencing `participants.id` in 8 downstream tables are `TEXT`.
4. `users.role` CHECK constraint only permits `('admin', 'ctv')`.
5. `tournaments.status`, `registrations.status`, `team_join_requests.status`, and `matches.status` have non-canonical enum values.
6. 3 tables from SRS 6.4 are missing: `auth_tokens`, `checkin_qr_tokens`, `report_exports`.

Target Behavior:
1. Migration `001_reconcile_srs_schema.sql` runs idempotently.
2. `users.role` allows `('participant', 'admin', 'ctv', 'seasonal_staff')`.
3. `participants` has `user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE`.
4. All primary keys across all 18 tables use `UUID DEFAULT gen_random_uuid()`.
5. All foreign keys referencing `participants(id)` are converted to `UUID`.
6. Missing tables `auth_tokens`, `checkin_qr_tokens`, `report_exports` created per SRS 6.4 DDL.
7. Constraints normalized:
   - `tournaments.status`: `('draft', 'open_registration', 'closed_registration', 'ongoing', 'completed', 'cancelled')`
   - `registrations.status`: `('pending', 'approved', 'rejected')` (no `cancelled`)
   - `team_join_requests.status`: `('pending', 'accepted', 'rejected')` (no `cancelled`)
   - `matches.status`: `('scheduled', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled')` (no `ready`)
8. `notifications` table retained (`TECHNICAL_SUPPORT`).
9. `ai_checkin_sessions` and `ai_checkin_detections` left intact but marked deprecated (`LEGACY_UNUSED`).

Scope:
- `Web-giai-dau/backend/migrations/001_reconcile_srs_schema.sql` (to be created)
- `Web-giai-dau-docs/database_schema.sql` (to be updated to match authoritative DDL)

Out of Scope:
- Backend TypeScript repository and controller updates (handled in `TASK-FOUND-001C` and `TASK-FOUND-001D`).
- Dropping `ai_checkin_*` tables (handled in `TASK-FOUND-001F`).
- Frontend UI modifications.

Affected Modules:
`backend/migrations`, `database`

Likely Files:
- `Web-giai-dau/backend/migrations/001_reconcile_srs_schema.sql`
- `Web-giai-dau-docs/database_schema.sql`

Dependencies:
`TASK-FOUND-001A` (COMPLETED & ACCEPTED)

Business Rules:
- BR-KYC-002: Zero CCCD Invariant.
- NSC-FOUND-001: Unified identity through `users`.
- NSC-FOUND-002: No bulk-dropping of extra columns.
- NSC-FOUND-004: Canonical `team_join_requests.status`.
- NSC-FOUND-005: Canonical `registrations.status`.

RBAC Rules:
- RBAC-001 to RBAC-004: Unified role definitions (`participant`, `admin`, `ctv`, `seasonal_staff`).

Workflow:
- WF-001: User creation with linked participant profile.

Schema Impact:
`MIGRATION_REQUIRED`

API Impact:
`INTERNAL`

Implementation Steps:
1. Create migration file `Web-giai-dau/backend/migrations/001_reconcile_srs_schema.sql`.
2. Expand `users.role` CHECK constraint.
3. Migrate existing `participants` data: for each existing participant, ensure a matching record in `users` with `role = 'participant'`, and link `participants.user_id = users.id`.
4. Alter `participants.id` from `TEXT` to `UUID` and update all referencing FK columns.
5. Create missing tables `auth_tokens`, `checkin_qr_tokens`, `report_exports`.
6. Update enum CHECK constraints on `tournaments`, `registrations`, `team_join_requests`, `matches`.
7. Add missing SRS columns (`tournaments.checkin_lat`, `tournaments.checkin_lng`, `participants.kyc_status`, etc.).
8. Update `Web-giai-dau-docs/database_schema.sql` to reflect the reconciled state.

Constraints:
- Must run inside a single transaction (`BEGIN ... COMMIT`).
- Must not lose existing admin/ctv credentials or tournament data.
- Must preserve Zero CCCD Invariant.

Tests Required:
- Migration dry-run on PostgreSQL.
- Foreign key integrity verification.
- Constraint boundary tests (invalid role, invalid status).

Acceptance Criteria:
- Given existing database, When migration executes, Then all tables, UUID PKs, FKs, and constraints match SRS 6.4 DDL.
- Given a participant, When queried, Then it links 1:1 to a `users` row.
- Given an insert with status `'cancelled'` into `registrations` or `team_join_requests`, Then the DB rejects it with a CHECK constraint error.

Definition of Done:
- [X] Migration script authored and validated.
- [X] All 18 tables have UUID primary keys.
- [X] Unified identity link (`participants.user_id -> users.id`) established.
- [X] No regression on existing data.

Rollback / Safety:
- Include reversible `DOWN` migration or transaction rollback script.
