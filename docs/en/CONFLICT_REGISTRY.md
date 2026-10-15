# CONFLICT REGISTRY — DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md v1.1
> **Last Updated:** 2026-09-29
> **Purpose:** Single canonical registry for all REQUIREMENT_CONFLICT items.
> **Authority:** This file is the ONLY place where RC-IDs are defined. All other documents MUST reference this registry.

> [!IMPORTANT]
> Each RC-ID is unique and uses a categorized prefix:
> - `RC-SCHEMA-xxx` — Database schema conflicts (table structure, column types, PKs, FKs)
> - `RC-ENUM-xxx` — Enum/CHECK constraint value mismatches
> - `RC-AUTH-xxx` — Authentication and authorization model conflicts
> - `RC-API-xxx` — API contract and routing conflicts
> - `RC-SEC-xxx` — Security requirement violations

---

## Schema Conflicts

| ID | Source A (Current) | Source B (SRS DDL §6.4) | Description | Severity | Stakeholder Decision | Resolved By |
|---|---|---|---|---|---|---|
| **RC-SCHEMA-001** | `database_schema.sql`: `participants.id` is `TEXT` (MSSV) | SRS §6.4: `participants.id` is `UUID PRIMARY KEY DEFAULT gen_random_uuid()` | PK type mismatch. SRS mandates UUID for all 18 tables. | CRITICAL | **APPROVED** — Migrate to UUID. Unified auth model via `users` table. | TASK-FOUND-001 |
| **RC-SCHEMA-002** | `database_schema.sql`: `participants` has `password_hash`, `username`, standalone auth | SRS §6.4: `participants` links to `users(id)` via `user_id UUID`; no standalone auth | Participants authenticate through unified `users` table, not separate auth. | CRITICAL | **APPROVED** — Full migration to SRS unified identity model. | TASK-FOUND-001 |
| **RC-SCHEMA-003** | `database_schema.sql`: `participants.student_card_url`, `selfie_with_student_card_url` | SRS §6.4: `student_card_front_url`, `student_card_portrait_url` | KYC image column names differ. | HIGH | SRS is authoritative — rename columns. | TASK-FOUND-001 |
| **RC-SCHEMA-004** | `database_schema.sql`: `participants.status` (approval field) | SRS §6.4: `participants.kyc_status` | KYC status column named differently. | HIGH | SRS is authoritative — rename column. | TASK-FOUND-001 |
| **RC-SCHEMA-005** | `database_schema.sql`: `tournament_organizers` has `participant_id TEXT`, `role` (enum), `custom_title` | SRS §6.4: Only `user_id UUID NOT NULL`, `role_title VARCHAR(50)` (free-text) | Tournament organizers structure differs; SRS uses unified `users` for all staff. | HIGH | SRS is authoritative — restructure table. | TASK-FOUND-001 |
| **RC-SCHEMA-006** | `database_schema.sql`: `matches` uses `bracket_id`, `round_id`, `match_code`, etc. | SRS §6.4: Uses `bracket_round_id`, `match_order INT`, `bo_format`, etc. | Match table column names and structure differ. | MEDIUM | SRS is authoritative — align columns. | TASK-FOUND-001 |
| **RC-SCHEMA-007** | `database_schema.sql`: Missing `auth_tokens`, `checkin_qr_tokens`, `report_exports` tables | SRS §6.4: All three defined | Three SRS tables not present in current schema. | HIGH | Create all three tables. | TASK-FOUND-001 |

## Enum/Status Conflicts

| ID | Source A (Current) | Source B (SRS DDL §6.4) | Description | Severity | Stakeholder Decision | Resolved By |
|---|---|---|---|---|---|---|
| **RC-ENUM-001** | `users.role` CHECK `('admin', 'ctv')` | SRS §6.4: CHECK `('participant', 'admin', 'ctv', 'seasonal_staff')` | Missing `participant` and `seasonal_staff` roles. | CRITICAL | SRS is authoritative — expand CHECK constraint. | TASK-FOUND-001 |
| **RC-ENUM-002** | `tournaments.status`: `'pending', 'approved', 'rejected', 'active', 'registration_opened', 'registration_closed'` (mixed) | SRS §6.4: `'draft', 'open_registration', 'closed_registration', 'ongoing', 'completed', 'cancelled'` | Tournament status enum values completely different. | CRITICAL | SRS is authoritative — map and migrate. | TASK-FOUND-001 |
| **RC-ENUM-003** | `matches.status`: `('scheduled', 'ready', 'in_progress', 'completed', 'cancelled', 'disputed')` | SRS §6.4: `('scheduled', 'in_progress', 'awaiting_confirmation', 'disputed', 'completed', 'cancelled')` | Match status missing `awaiting_confirmation`; has `ready` not in SRS. | HIGH | SRS is authoritative — align CHECK. | TASK-FOUND-001 |
| **RC-ENUM-004** | `team_join_requests.status`: `('pending', 'accepted', 'rejected', 'cancelled')` | SRS §6.4: `('pending', 'accepted', 'rejected')` | Extra `'cancelled'` value not in SRS DDL. | MEDIUM | **REJECTED** — Drop `'cancelled'`. WF-003 updated. | TASK-FOUND-001 |
| **RC-ENUM-005** | `registrations.status`: `('pending', 'approved', 'rejected', 'cancelled')` | SRS §6.4: `('pending', 'approved', 'rejected')` | Extra `'cancelled'` value not in SRS DDL. | MEDIUM | **REJECTED** — Drop `'cancelled'`. DOMAIN_RULES updated. | TASK-FOUND-001 |

## Authentication & Security Conflicts

| ID | Source A (Current) | Source B (SRS/AGENTS.md) | Description | Severity | Stakeholder Decision | Resolved By |
|---|---|---|---|---|---|---|
| **RC-SEC-001** | bcryptjs cost 10 | SRS NFR-SEC-06: bcrypt cost ≥ 12 or Argon2id | Password hashing below minimum security threshold. | HIGH | Fix required. | TASK-SEC-001 |
| **RC-SEC-002** | KYC images served via direct static URL | SRS FR-KYC-04: Signed URLs (max 5 min); direct → 403 | KYC image access control missing. | HIGH | Implement signed URLs. | TASK-SEC-002 |

## API & Routing Conflicts

| ID | Source A (Current) | Source B (Expected) | Description | Severity | Stakeholder Decision | Resolved By |
|---|---|---|---|---|---|---|
| **RC-API-001** | `registration.routes.ts`: `/my-registrations` after `/:id` | Specific routes must precede parameterized routes | Route ordering bug causes `/my-registrations` to be captured by `/:id`. | MEDIUM | Fix route ordering. | TASK-BUG-001 |

## Deprecated Items

| ID | Item | Status | Notes |
|---|---|---|---|
| **RC-DEPR-001** | `ai_checkin_sessions` table | DEPRECATED | Not in SRS DDL §6.4. Keep in DB; do NOT drop immediately. Verify data/code dependencies first. Separate cleanup migration later. |
| **RC-DEPR-002** | `ai_checkin_detections` table | DEPRECATED | Not in SRS DDL §6.4. Same treatment as RC-DEPR-001. |

---

## Legacy RC-ID Mapping

The following table maps old RC-IDs (which were duplicated across documents) to the new canonical IDs:

| Old ID (REQUIREMENT_TRACEABILITY.md) | Old ID (GAP_ANALYSIS.md) | New Canonical ID | Description |
|---|---|---|---|
| RC-001 | RC-005 | **RC-SCHEMA-001** | `participants.id` TEXT vs UUID |
| RC-002 | — | **RC-ENUM-001** | `users.role` CHECK mismatch |
| RC-003 | RC-008 | **RC-ENUM-002** | `tournaments.status` enum mismatch |
| — | RC-001 | **RC-ENUM-003** | `matches.status` enum mismatch |
| — | RC-002 | **RC-DEPR-001** | `ai_checkin_sessions` enum (deprecated table) |
| — | RC-003 | **RC-ENUM-004** | `team_join_requests.status` 'cancelled' |
| — | RC-004 | **RC-SEC-001** | bcrypt cost < 12 |
| — | RC-006 | **RC-SEC-002** | KYC signed URLs missing |
| — | RC-007 | **RC-API-001** | Route ordering bug |

---

*This registry was created on 2026-09-29 per stakeholder directive.*
*All documents referencing old RC-IDs must be updated to use canonical IDs from this registry.*
