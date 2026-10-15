# ACCEPTANCE CRITERIA — DUT ESPORTS TOURNAMENT PLATFORM

> **Source of Truth:** SRS.md v1.1 | Section 8 (Gherkin Scenarios)
> **Last Updated:** 2026-09-29

All acceptance criteria are mapped from SRS Section 8 and referenced functional requirements. Every scenario must be run for a feature to be considered complete.

---

## AC-AUTH-001: User Registration

**Requirement:** FR-AUTH-01

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path: new email | Email not yet registered; valid password | User submits registration form | Account created with email_verified_at = NULL; verification email sent with one-time link |
| Duplicate email | Email already registered | User submits registration with same email | 409 Conflict; no new account created |
| Invalid password | Password too weak | User submits registration | 400 Bad Request; no account created |

## AC-AUTH-002: Email Verification Token

**Requirement:** FR-AUTH-01

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path | Valid, unexpired, unused token | User submits token | email_verified_at set; token marked used |
| Expired token | Token past expires_at | User submits token | 400 rejected; no change; user prompted to request new token |
| Already used token | Token used_at is set | User submits token | 400 rejected; no change |

## AC-AUTH-003: Login Rate Limiting

**Requirement:** NFR-SEC-06

| Scenario | Given | When | Then |
|---|---|---|---|
| Threshold breach | 5 failed logins for account within 15 min | 6th login attempt | 429 Too Many Requests; further attempts blocked for 15 min |

## AC-KYC-001: KYC Image Submission

**Requirement:** FR-KYC-01 | SRS AC-01

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path | 2 valid images, each ≤ 5MB, jpg/jpeg/png | Participant submits KYC form | participants record created with kyc_status = pending; images in private storage |
| Missing image | Only 1 image uploaded | Participant submits | Form submission blocked; no record created; error shown |
| Image too large | Image > 5MB | Participant uploads | 400; form blocked; no record created |
| Wrong format | Image is PDF or BMP | Participant uploads | 400; rejected; no record created |
| CCCD field attempt | Any field named CCCD/CMND present | Developer adds field | FAIL - ZERO CCCD invariant violated |

## AC-KYC-002: KYC Review by CTV

**Requirement:** FR-KYC-03 | SRS AC-02

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path approval | KYC record in pending; images match | CTV clicks Approve | kyc_status = approved; audit_log created; participant can register |
| Rejection with reason | KYC record in pending; image blurry | CTV enters reason and clicks Reject | kyc_status = rejected; notification sent; audit_log created |
| Rejection without reason | KYC record in pending | CTV tries to reject without entering reason | Rejection blocked; UI requires reason |
| Unauthorized access | seasonal_staff role | Staff tries to approve KYC | 403 Forbidden |
| Image access direct URL | CTV has image URL | CTV tries direct static URL | 403 Forbidden |
| Image access signed URL | CTV is authorized reviewer | CTV accesses via API signed URL | Image delivered; URL expires in ≤ 5 min |

## AC-KYC-003: Account Type Classification

**Requirement:** FR-KYC-02

| Scenario | Given | When | Then |
|---|---|---|---|
| DUT student | university_name = 'Đại học Bách khoa Đà Nẵng' | KYC submitted | account_type = internal |
| Other university | university_name != DUT | KYC submitted | account_type = external |
| Non-canonical university | university_name not in Admin list | Participant tries to select | University not available; must use Admin-approved list |

## AC-TEAM-001: Recruitment Flag

**Requirement:** FR-TEAM-01 | SRS AC-03

| Scenario | Given | When | Then |
|---|---|---|---|
| Enable recruiting | Team has 4/7 members; registration open | Captain sets is_recruiting = true | registrations.is_recruiting = true; team appears on recruitment board |
| Team full auto-disable | Team at 6/7; 7th member joins | Join accepted | is_recruiting auto-set to false |
| Non-captain toggle | Participant is a member but not captain | Tries to set is_recruiting | 403 Forbidden |

## AC-TEAM-002: Team Join Request

**Requirement:** FR-TEAM-03

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path | Free agent KYC approved; team recruiting | Agent sends join request; captain accepts | Agent added to registration_members; member count updated; is_recruiting updated if full |
| Already in team | Player already in another team same tournament | Captain tries to accept | 409; transaction rolled back; join request remains pending |
| Team full at accept | Team reached max_size between request and accept | Captain accepts | 409; transaction rolled back |
| Registration closed | Tournament no longer open | Captain tries to accept | 409; join rejected |
| Unauthorized accept | Participant is not captain | Tries to accept join request | 403 Forbidden |

## AC-TRN-001: Tournament Status Transition

**Requirement:** FR-TRN-02

| Scenario | Given | When | Then |
|---|---|---|---|
| Open without config | Tournament in draft; no checkin coords | Admin tries to open registration with GPS enabled | 400; transition blocked; error lists missing fields |
| Block registration after close | Tournament in closed_registration | Participant tries to register | 409; registration rejected |
| Unauthorized transition | participant role | Tries to change tournament status | 403 Forbidden |

## AC-TFT-001: TFT Room Partitioning

**Requirement:** FR-TRN-04 | SRS AC-04, AC-11

| N | Expected Result |
|---|---|
| 8 | Create 1 room of 8 |
| 14 | Create 2 rooms of 7 |
| 16 | Create 2 rooms of 8 |
| 17 | Reject; explain cannot divide into 7–8-person rooms |
| 22 | Create 1 room of 8 + 2 rooms of 7 |
| 25 | Reject; explain cannot divide into 7–8-person rooms |

**Additional invariants:**
- Rooms created in single DB transaction; any failure → full rollback, no partial state.
- No room may have fewer than 7 players.

## AC-CHK-001: QR + GPS Check-in

**Requirement:** FR-CHK-01, FR-CHK-02 | SRS AC-05

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path | Valid QR; GPS 35m from center (geofence 100m); accuracy 20m | Participant scans | check_ins created: status=approved, method=qr_scan; checkin.approved event emitted; response < 2s |
| Outside geofence | Valid QR; GPS 150m from center | Participant scans | Rejected; prompted to submit proof |
| GPS accuracy too low | Valid QR; GPS accuracy 150m | Participant scans | Rejected; prompted to submit proof |
| Expired QR | Token past expires_at | Participant scans | 400; no check-in created |
| Revoked QR | Token revoked_at set | Participant scans | 400; no check-in created |
| Wrong tournament QR | QR from different tournament | Participant scans | 400; no check-in created |
| Replay attack | Same participant, same token, already used | Participant re-submits | 400; duplicate rejected |

## AC-CHK-002: Proof Submission Fallback

**Requirement:** FR-CHK-04, FR-CHK-05 | SRS AC-06

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path | GPS unavailable | Participant uploads venue image | check_ins: status=pending_review, method=proof_submission; CTV notified |
| CTV approves on map | Pending review record visible on Leaflet map | CTV clicks Approve | status=approved; reviewed_by=CTV user_id; audited |
| CTV rejects | Proof image does not show venue | CTV clicks Reject | status=rejected; audited |
| Unauthorized approval | seasonal_staff not assigned to tournament | Tries to approve | 403 Forbidden |

## AC-CHK-003: Duplicate Check-in Prevention

**Requirement:** FR-CHK-01 | SRS AC-12

| Scenario | Given | When | Then |
|---|---|---|---|
| Second check-in attempt | Participant already has approved check-in | Participant tries again | Returns existing status; no new record created |
| Second proof after pending | Participant has pending_review check-in | Participant submits again | Returns existing pending status; no duplicate |

## AC-CRT-001: Automatic Certificate Generation

**Requirement:** FR-CRT-01, FR-CRT-02 | SRS AC-07

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path | Tournament with approved check-ins and organizers | Admin marks tournament completed | tournament.completed event emitted; worker creates certificates for all eligible; certificates table populated |
| Idempotent worker | Worker triggered twice | Second trigger | No duplicate certificates created (ON CONFLICT DO NOTHING) |
| Athlete without check-in | Participant registered but check-in status != approved | Worker runs | No certificate created for that participant |
| Worker runs async | Tournament has many participants | Worker runs | Main API not blocked; certificate progress tracked |

## AC-CRT-002: Public Certificate Verification

**Requirement:** FR-CRT-04 | SRS AC-08

| Scenario | Given | When | Then |
|---|---|---|---|
| Valid cert, name allowed | public_name_allowed = true | Third party scans QR | Shows: recipient name, tournament name, achievement, validity status; NOT: email, phone, student_id |
| Valid cert, name private | public_name_allowed = false | Third party scans QR | Shows: tournament name, achievement, validity status; NOT recipient name or any PII |
| Invalid cert code | Code does not exist in certificates | Third party accesses URL | Warning: certificate does not exist or is counterfeit |
| Revoked cert | is_revoked = true | Third party accesses URL | Warning: certificate has been revoked |

## AC-REP-001: Report Export Task

**Requirement:** FR-REP-01, FR-REP-02 | SRS AC-09, AC-13

| Scenario | Given | When | Then |
|---|---|---|---|
| Happy path | Admin authenticated | Admin requests export | task_id returned within 2s; status = queued or processing |
| Idempotent request | Same idempotency_key already used | Admin resubmits | Returns existing task_id; no duplicate task created |
| CTV unassigned | CTV not in tournament_organizers for tournament | CTV requests export | 403 Forbidden |
| File download by owner | Task status = completed; requester = task owner | Download request | File streamed via signed URL |
| File expired | expires_at passed | Download attempt | 404 or 410; file no longer available |
| Memory constraint | 10,000-row CSV | Worker runs | Peak RSS increase ≤ 256 MiB |

## AC-REP-002: PII Masking in Reports

**Requirement:** FR-REP-03 | SRS AC-10

| Scenario | Given | When | Then |
|---|---|---|---|
| CTV export | role = ctv | CTV downloads report | Phone shows 090****123 pattern; email shows ngu***@gmail.com pattern |
| Admin export | role = admin | Admin downloads report | Phone and email shown in full, unmasked |
| seasonal_staff export | role = seasonal_staff | Staff requests export | 403 Forbidden |

## AC-AUD-001: Audit Log Integrity

**Requirement:** FR-AUD-01, FR-AUD-02

| Scenario | Given | When | Then |
|---|---|---|---|
| KYC approval logged | CTV approves KYC | System processes | audit_logs record created with: actor_id, action=KYC_APPROVE, target_table=participants, old/new values, ip_address |
| Log tampering attempt | Any role including admin | UPDATE or DELETE on audit_logs | DB permission error; operation rejected |
| Result change logged | Admin modifies locked match result | System processes | audit_logs record with old/new scores, actor, reason |

## AC-MATCH-001: Match Result and Dispute

**Requirement:** FR-TRN-05 | SRS AC-14

| Scenario | Given | When | Then |
|---|---|---|---|
| Normal result flow | Referee enters score; match in_progress | Referee submits | match.status = awaiting_confirmation; bracket not yet advanced |
| Captain confirms | Match awaiting_confirmation | Captain confirms | match.status = completed; bracket advances |
| Captain disputes | Match awaiting_confirmation; within dispute deadline | Captain submits dispute | match.status = disputed; bracket does NOT advance; CTV/Admin notified |
| Dispute resolution | Match in disputed | Admin/CTV decides | match.status = completed; decision, actor, timestamp in audit_logs |
| Admin override locked result | Match completed | Admin modifies score | Allowed with reason; audit_logs records all details |
| Participant override locked result | Match completed | Participant tries to modify | 403 Forbidden |

---

## Definition of Done

A task is complete ONLY when ALL of the following are satisfied:

- [ ] Requirements implemented per SRS
- [ ] Business rules satisfied (per BUSINESS_RULES.md)
- [ ] RBAC satisfied (per RBAC.md)
- [ ] Workflow transitions valid (per WORKFLOWS.md)
- [ ] Input validation implemented
- [ ] All error cases handled with correct HTTP status codes
- [ ] All relevant acceptance criteria scenarios pass
- [ ] Tests added for happy path, error paths, and RBAC scenarios
- [ ] No unrelated scope change introduced
- [ ] No BLOCKER/HIGH review findings unresolved
- [ ] Reviewer and Tester have signed off independently
