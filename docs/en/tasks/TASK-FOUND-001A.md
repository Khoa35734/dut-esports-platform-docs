TASK-ID: TASK-FOUND-001A
Title: Inventory and classify schema differences

Goal:
Identify all database columns/tables in the codebase that do not perfectly align with the SRS DDL, and classify each mismatch into a canonical category without dropping anything yet.

Requirements:
SRS 6.4 (Database Schema)

Conflict IDs:
RC-SCHEMA-001, RC-ENUM-001, RC-ENUM-002, RC-ENUM-003, RC-DEPR-001, RC-ENUM-004

Current Behavior:
The current `database_schema.sql` and application code contain legacy columns and tables (like `ai_checkin_sessions`) that deviate from the SRS. 

Target Behavior:
A generated report file (`docs/SCHEMA_MISMATCH_INVENTORY.md`) classifying every single extra, missing, or mismatched column/table as one of: SRS_REQUIRED, TECHNICAL_SUPPORT, LEGACY_UNUSED, or CONFLICTING. No application code or SQL files are modified in this step.

Scope:
Read-only analysis of `Web-giai-dau-docs/database_schema.sql` and `Web-giai-dau-docs/SRS.md`. Creation of one markdown report.

Out of Scope:
Writing migrations. Modifying application code. Dropping tables. Modifying the SRS.

Affected Modules:
Documentation / Planning

Likely Files:
docs/SCHEMA_MISMATCH_INVENTORY.md (to be created)

Dependencies:
NONE

Business Rules:
NONE

RBAC Rules:
NONE

Workflow:
NONE

Schema Impact:
NONE

API Impact:
NONE

Implementation Steps:
1. Compare `Web-giai-dau-docs/database_schema.sql` line by line with the DDL in `Web-giai-dau-docs/SRS.md`.
2. List all discrepancies (data types, missing columns, extra columns, constraint differences).
3. Classify each discrepancy according to the Stakeholder Decisions (NSC-FOUND-002, NSC-FOUND-003).
4. Save the result to `docs/SCHEMA_MISMATCH_INVENTORY.md`.

Constraints:
Do not write or modify any `.sql` or `.ts` files.

Tests Required:
None

Acceptance Criteria:
- All discrepancies between current DDL and SRS DDL are documented.
- Every discrepancy is classified as SRS_REQUIRED, TECHNICAL_SUPPORT, LEGACY_UNUSED, or CONFLICTING.

Definition of Done:
- [ ] Implementation matches Target Behavior
- [ ] Required Tests pass
- [ ] No regression introduced
- [ ] Code reviewed and approved

Rollback / Safety:
NONE
