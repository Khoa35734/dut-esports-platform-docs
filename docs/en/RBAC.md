# RBAC — ROLE-BASED ACCESS CONTROL
## DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md v1.1 | Section 7.1 Use Case Matrix | Section 10.3.1 Data Permission Matrix
> **Last Updated:** 2026-09-29

---

## Roles

| Role ID | Role Name | Description | Source |
|---|---|---|---|
| `admin` | Quản trị viên | Full system access; can override any operation | SRS 2.2 |
| `ctv` | CTV Thường trực | Manages tournaments; reviews KYC; scoped to assigned tournaments | SRS 2.2 |
| `seasonal_staff` | CTV Thời vụ | Assists at specific tournament; very limited scope | SRS 2.2 |
| `participant` | Sinh viên / VĐV | Registers, competes, checks in, downloads own certificate | SRS 2.2 |
| `public` | Khách (unauthenticated) | Public tournament info and certificate verification only | SRS 2.2 |

---

## RBAC Permission Table

| RBAC ID | Resource | Action | admin | ctv | seasonal_staff | participant | public | Conditions | Source |
|---|---|---|---|---|---|---|---|---|---|
| RBAC-001 | `/auth/register` | POST | ✓ | ✓ | ✓ | ✓ | ✓ | No auth required | FR-AUTH-01 |
| RBAC-002 | `/auth/login` | POST | ✓ | ✓ | ✓ | ✓ | ✓ | No auth required | FR-AUTH-01 |
| RBAC-003 | `/auth/verify-email` | POST | ✓ | ✓ | ✓ | ✓ | ✓ | Valid one-time token | FR-AUTH-01 |
| RBAC-004 | `/auth/reset-password` | POST | ✓ | ✓ | ✓ | ✓ | ✓ | Valid one-time token | FR-AUTH-01 |
| RBAC-005 | `users` | Read own profile | ✓ | ✓ | ✓ | ✓ | ✗ | Own account only | SRS 10.3.1 |
| RBAC-006 | `users` | List all accounts | ✓ | ✗ | ✗ | ✗ | ✗ | Admin only | NFR-SEC-05 |
| RBAC-007 | `users` | Lock/unlock account | ✓ | ✗ | ✗ | ✗ | ✗ | Admin only | FR-AUTH-01 |
| RBAC-008 | `participants` | Submit KYC | ✗ | ✗ | ✗ | ✓ | ✗ | Own profile | FR-KYC-01 |
| RBAC-009 | `participants` KYC images | View | ✓ | ✓* | ✗ | ✗ | ✗ | *CTV: only pending review; signed URL max 5 min | FR-KYC-04 |
| RBAC-010 | `participants` | Approve/Reject KYC | ✓ | ✓ | ✗ | ✗ | ✗ | Audit logged | FR-KYC-03 |
| RBAC-011 | `participants` | Read full contact data | ✓ | ✓* | ✗ | ✗ | ✗ | *CTV: assigned tournament only, audited | SRS 10.3.1 |
| RBAC-012 | `participants` | Read masked contact | ✗ | ✓ | ✓ | ✗ | ✗ | Masked phone/email | NFR-SEC-03 |
| RBAC-013 | `tournaments` | Create | ✓ | ✓ | ✗ | ✗ | ✗ | CTV creates, Admin approves | FR-TRN-02 |
| RBAC-014 | `tournaments` | Read public info | ✓ | ✓ | ✓ | ✓ | ✓ | Public tournament listing | SRS 4.1 |
| RBAC-015 | `tournaments` | Change status | ✓ | ✓ | ✗ | ✗ | ✗ | CTV scope: assigned only | FR-TRN-02 |
| RBAC-016 | `tournaments` | Configure geofence | ✓ | ✓* | ✗ | ✗ | ✗ | *Assigned tournament; changes audited | FR-CHK-02 |
| RBAC-017 | `tournament_organizers` | Assign staff | ✓ | ✓* | ✗ | ✗ | ✗ | *CTV: only for their assigned tournament | SRS 2.2 |
| RBAC-018 | `tournament_organizers` | Revoke staff | ✓ | ✗ | ✗ | ✗ | ✗ | Admin only | SRS 10.3 |
| RBAC-019 | `registrations` | Create (register) | ✗ | ✗ | ✗ | ✓ | ✗ | KYC approved; tournament open | FR-TRN-02 |
| RBAC-020 | `registrations` | Approve/Reject | ✓ | ✓* | ✗ | ✗ | ✗ | *CTV: assigned tournament only | FR-TRN-02 |
| RBAC-021 | `registrations` | Set is_recruiting | ✗ | ✗ | ✗ | ✓* | ✗ | *Captain of that registration only | FR-TEAM-01 |
| RBAC-022 | `team_join_requests` | Send request | ✗ | ✗ | ✗ | ✓ | ✗ | KYC approved; target team recruiting | FR-TEAM-03 |
| RBAC-023 | `team_join_requests` | Accept/Reject | ✗ | ✗ | ✗ | ✓* | ✗ | *Captain of the receiving team only | FR-TEAM-03 |
| RBAC-024 | `check_ins` | Submit QR+GPS | ✗ | ✗ | ✗ | ✓ | ✗ | Registered for tournament; check-in window open | FR-CHK-01 |
| RBAC-025 | `check_ins` | Submit proof image | ✗ | ✗ | ✗ | ✓ | ✗ | Registered for tournament; check-in window open | FR-CHK-04 |
| RBAC-026 | `check_ins` | Review/Approve on map | ✓ | ✓* | ✓* | ✗ | ✗ | *Assigned tournament only; audited | FR-CHK-05 |
| RBAC-027 | `check_ins` | Admin manual override | ✓ | ✗ | ✗ | ✗ | ✗ | Audited; reason required | FR-CHK-05 |
| RBAC-028 | GPS location data | View on map | ✓ | ✓* | ✓* | ✗ | ✗ | *Assigned tournament only | SRS 10.3.1 |
| RBAC-029 | `brackets` | Generate/Configure | ✓ | ✓* | ✗ | ✗ | ✗ | *Assigned tournament only | FR-TRN-03 |
| RBAC-030 | `brackets` | View | ✓ | ✓ | ✓ | ✓ | ✓ | Public bracket view | FR-TRN-03 |
| RBAC-031 | `matches` | Enter results | ✓ | ✓* | ✓* | ✗ | ✗ | *Assigned tournament; referee only for seasonal | FR-TRN-05 |
| RBAC-032 | `matches` | Override locked result | ✓ | ✗ | ✗ | ✗ | ✗ | Admin only; reason + audit | FR-TRN-05 |
| RBAC-033 | `matches` | Submit dispute | ✗ | ✗ | ✗ | ✓* | ✗ | *Team captain of match participant only | FR-TRN-05 |
| RBAC-034 | `matches` | Resolve dispute | ✓ | ✓* | ✗ | ✗ | ✗ | *Assigned tournament | FR-TRN-05 |
| RBAC-035 | `certificates` | Download own | ✓ | ✓ | ✓ | ✓ | ✗ | Own certificate only | FR-CRT-02 |
| RBAC-036 | `/verify-certificate` | Public lookup | ✓ | ✓ | ✓ | ✓ | ✓ | No auth; PII filtered | FR-CRT-04 |
| RBAC-037 | `report_exports` | Create task | ✓ | ✓* | ✗ | ✗ | ✗ | *CTV: assigned tournament only | FR-REP-01 |
| RBAC-038 | `report_exports` | Download file | ✓ | ✓* | ✗ | ✗ | ✗ | *Own task; within expires_at | FR-REP-02 |
| RBAC-039 | `audit_logs` | Read | ✓ | ✓* | ✗ | ✗ | ✗ | *CTV: only logs in assigned scope | FR-AUD-01 |
| RBAC-040 | `audit_logs` | Write (INSERT) | ✓ | ✓ | ✓ | ✓ | ✗ | System-level; app cannot UPDATE/DELETE | FR-AUD-02 |
| RBAC-041 | `checkin_qr_tokens` | Generate/Display | ✓ | ✓* | ✓* | ✗ | ✗ | *Assigned tournament | FR-CHK-01 |
| RBAC-042 | `checkin_qr_tokens` | Revoke manually | ✓ | ✓* | ✗ | ✗ | ✗ | *Assigned tournament | FR-CHK-01 |
| RBAC-043 | Certificate template | Configure | ✓ | ✗ | ✗ | ✗ | ✗ | Admin only | FR-CRT-05 |
| RBAC-044 | University canonical list | Manage | ✓ | ✗ | ✗ | ✗ | ✗ | Admin only | FR-KYC-02 |

---

## UNRESOLVED_PERMISSION Records

| ID | Area | Issue |
|---|---|---|
| UP-001 | `tournament_organizers` - staff assignment by CTV | SRS states CTV can assign seasonal staff to their tournament, but does not specify if a lead_organizer CTV can assign co_organizer CTVs. NEEDS_STAKEHOLDER_CONFIRMATION |
| UP-002 | `match_games` result entry by seasonal_staff | SRS states seasonal staff assist with check-in; referee role in match result entry is implied but exact workflow steps NEED_STAKEHOLDER_CONFIRMATION |
| UP-003 | Self-service certificate for CTV Thời vụ | SRS FR-CRT-03 says CTV Thời vụ can self-export their BTC certificate. It is unclear if this requires the tournament to be in `completed` status first. NEEDS_STAKEHOLDER_CONFIRMATION |

---

## Key RBAC Enforcement Rules

1. **Deny by default:** If a permission is not listed as explicitly granted, it is DENIED.
2. **Server-side enforcement required:** Frontend visibility does not constitute authorization.
3. **Never trust client role claims:** Role must be extracted from server-side JWT/session only.
4. **Scope restriction for CTV:** All CTV permissions are scoped to tournaments where a `tournament_organizers` record exists for their `user_id`.
5. **Ownership verification:** For participant-level actions (recruiting, join requests, disputes), verify the participant ID from the authenticated session matches the resource owner.
6. **IDOR prevention:** UUID primary keys alone do not prevent IDOR; authorization checks must verify ownership/assignment on every request.
