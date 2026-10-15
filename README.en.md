# DUT ESPORTS TOURNAMENT MANAGEMENT PLATFORM
## Technical Specification, Database Design & Software Testing Architecture

🌐 **Language / Ngôn ngữ:** **[English](README.en.md)** | **[Tiếng Việt](README.md)**

[![Status: Active](https://img.shields.io/badge/Status-Active-brightgreen.svg)]()
[![Specification: SRS 1.1 / 1.2-Draft](https://img.shields.io/badge/Specification-SRS%201.1%20%2F%201.2--Draft-blue.svg)]()
[![Architecture: Event--Driven](https://img.shields.io/badge/Architecture-EDA%20%2B%20RESTful-orange.svg)]()
[![Testing: ISO%2029119](https://img.shields.io/badge/Testing-ISO%2F%2FIEC%2F%2FIEEE%2029119-purple.svg)]()
[![Data Security: Zero CCCD](https://img.shields.io/badge/Data%20Security-Zero%20CCCD%20Invariant-red.svg)]()

Comprehensive technical specifications, PostgreSQL physical database schemas, and automated testing architecture for the **DUT ESPORTS Tournament Management Platform** — developed and operated by the **Esports Club of Danang University of Science and Technology (DUT)**.

---

## 1. PROJECT OVERVIEW

In campus collegiate esports tournaments with hundreds of student athletes participating every season, legacy manual operations (Google Forms, disparate spreadsheets, paper verification) created a severe "paperwork bottleneck," consuming hundreds of operational hours and introducing significant risks of athlete identity errors.

The **DUT ESPORTS Tournament Management Platform** was architected to eliminate this bottleneck by delivering end-to-end automation across pre-tournament, tournament, and post-tournament lifecycles:
- **Student Identity & KYC Verification:** Standardized student verification based on student ID numbers (`student_id`) and double-sided student card image verification (front side + selfie holding the card), adhering to privacy standards.
- **Team Recruitment & Free Agent Marketplace:** Real-time recruitment board empowering captains to scout missing roster positions and free agents to apply for open teams.
- **Multi-format Tournament Management:** Native support for diverse competitive disciplines ranging from solo games (Teamfight Tactics - TFT) with mathematical room allocation algorithms to team games (MOBA, FPS) with dynamic JSONB registration forms.
- **Multi-modal Tournament Check-in:** Combining dynamic 30-second rolling QR codes, Haversine GPS Geofencing (Hall F venue radius $\le 100m$), and fallback proof photo uploads audited on an interactive Leaflet OpenStreetMap dashboard.
- **Digital E-Certificates:** Automated generation of verifiable tamper-proof certificates with unique serial identifiers and public QR verification endpoints for athletes and organizing staff.
- **Personal Identifiable Information (PII) Protection:** Strict adherence to the **Zero CCCD Invariant** (no national ID collection), data masking, and 4-tier Role-Based Access Control (RBAC).

---

## 2. MULTI-REPO ECOSYSTEM

The DUT ESPORTS platform ecosystem is divided into three interconnected repositories:

```text
D:\DUT ESPORTS\
├── Web-giai-dau-docs/           # [THIS REPOSITORY] Specifications, Database & Testing Architecture
│   ├── README.md                # Project Overview & Architecture (Vietnamese Version)
│   ├── README.en.md             # Project Overview & Architecture (English Version)
│   ├── SRS.md                   # Software Requirements Specification v1.1 (IEEE Std 830-1998)
│   ├── database_schema.sql      # PostgreSQL DDL Schema with 18 normalized tables (v2.0)
│   ├── migrations.sql           # Database migration script with full indexes & constraints
│   ├── docs/                    # BILINGUAL DOCUMENTATION SYSTEM
│   │   ├── en/                  # [ENGLISH] Product Analysis, Business Rules & Task Specs
│   │   │   ├── BUSINESS_RULES.md
│   │   │   ├── WORKFLOWS.md
│   │   │   ├── DOMAIN_RULES.md
│   │   │   ├── ACCEPTANCE_CRITERIA.md
│   │   │   ├── RBAC.md
│   │   │   ├── FIGMA_*.md
│   │   │   └── tasks/           # 12 Detailed Technical Task Specifications
│   │   └── vi/                  # [VIETNAMESE] SRS Audit & Software Testing Architecture
│   │       └── testing/         # SRS 1.1 Audit, ISO 29119 Test Plans, Scenarios & Reports
│   └── tests/                   # 5-Tier Automated Testing Framework (Node.js Native + Playwright)
│
├── Web-giai-dau/                # [BACKEND REPOSITORY] API Server
│   └── backend/                 # Express 5.0 + TypeScript 5.9 + PostgreSQL (Supabase Cloud)
│       ├── src/controllers/     # admin, auth, checkin, participant, registration, tournament...
│       ├── src/repositories/    # user, participant, registration, tournament, checkin, stats
│       ├── src/middleware/      # auth, rbac, activeStaff, tournamentScope, upload
│       └── tests/               # 132 backend regression tests
│
└── DUT_esports_frontend/        # [FRONTEND REPOSITORY] Client Web Application
    ├── src/app/                 # Next.js 15.3 (App Router, Turbopack) + React 19.2
    ├── src/components/          # Cyber UI Library, SoloCheckinModal, LeafletCheckinMap...
    ├── src/features/            # auth, tournaments, dashboard, checkin-simulation
    └── tests/                   # 24 unit/integration tests + Playwright E2E Specs
```

---

## 3. TWO CORE FUNCTIONS UNDER TEST

This quality assurance and test design suite focuses deeply on **Two Core Functions** with implemented production source code:

### Core Function A: Tournament Registration & Team Recruitment
- Registration for solo and team tournaments using dynamic JSONB schemas (`form_schema`).
- Real-time recruitment mode toggling (`is_recruiting`).
- Team join request workflows (`team_join_requests`) with captain accept/reject mechanics.
- Team capacity bounds enforcement (`max_team_size`) with automatic recruitment cutoff upon reaching capacity.
- Duplicate team membership prevention across the same tournament.
- Concurrency race condition control when two captains simultaneously approve the same athlete.
- Tournament configuration locking (`BR-TRN-LOCK`) once registration opens.

### Core Function B: Multi-modal Tournament Check-in
- Dynamic 30-second rotating QR code token generation (`checkin_qr_tokens`).
- GPS Geofencing verification via Haversine spherical distance calculation (Hall F DUT: radius 100m, error tolerance $\le 100m$).
- Fallback check-in: Photo proof submission for staging/venue attendance when GPS sensors fail or permissions are denied.
- Leaflet OpenStreetMap centralized operator auditing map for tournament staff.
- Duplicate check-in prevention (`UNIQUE(tournament_id, participant_id)`).
- High concurrency load handling: 50 athletes scanning a single 30-second projection screen QR token simultaneously.
- Peak stress test: 500 requests/minute achieving response latency $p95 < 50ms$ (specification requirement $< 2,000ms$).

---

## 4. UNIFIED 5-TIER TEST STRATEGY

Applying a Unified Test Pyramid tailored for a Solo Developer assisted by AI:

```text
▲ TIER 5: PERFORMANCE TESTING (Peak load 500 req/min, p95 latency benchmark, throughput)
├── TIER 4: MOBILE WEB TESTING (Playwright Mobile: Mobile viewport, GPS spoofing, QR camera mock)
├── TIER 3: WEB UI TESTING (Playwright Desktop: Team registration journey, Leaflet OSM map)
├── TIER 2: API TESTING (Node.js Native Test Suite: Express 5.0 Endpoints + PostgreSQL Live)
└── TIER 1: UNIT TESTING (Node.js Native Runner: TFT allocation, Haversine, Magic Bytes, State Machine)
```

| Testing Tier | Scope & Focus | Technology Stack | Test Count | Status |
|---|---|---|:---:|:---:|
| **Tier 1: Unit Testing** | TFT 7-8 room allocation math, Haversine formula, Image Magic Bytes verification, Tournament state machine | Node.js Native Runner (`node --test`) | **39 tests** | **100% PASS** |
| **Tier 2: API Testing** | Registration, Recruitment, Race conditions, 30s QR check-in, GPS, Proof upload, RBAC security | Node.js Native Runner (`node --test`) | **17 tests** | **100% PASS** |
| **Tier 3: Web UI Testing** | Desktop team registration workflow, Leaflet OSM operator map rendering | Playwright Desktop (`@playwright/test`) | 2 specs | **READY** |
| **Tier 4: Mobile Web Testing** | Mobile emulation (Pixel 7 / iPhone 14 Pro), synthetic GPS injection, camera permissions | Playwright Mobile Emulation | 2 specs | **READY** |
| **Tier 5: Performance Testing** | 500 check-in requests/min peak load simulation, p95 latency benchmarking | Node.js Benchmark Runner (`performance.now()`) | 500 reqs | **100% PASS** (p95: 47ms) |

---

## 5. DOCUMENTATION SITEMAP

The complete project specification, design, and testing documentation is structured under `docs/`:

### 5.1. English Branch — Product Analysis, Business Rules & Task Specs ([`docs/en/`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/))
- [`docs/en/BUSINESS_RULES.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/BUSINESS_RULES.md): 30+ core business rules indexed by identifier (`BR-AUTH`, `BR-KYC`, `BR-TEAM`, `BR-TRN`, `BR-CHK`, `BR-CERT`...).
- [`docs/en/WORKFLOWS.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/WORKFLOWS.md): 8 standardized operational workflows (`WF-001` through `WF-008`: User Registration, KYC Approval, Tournament Creation, Team Building, Brackets, Check-in, Disputes, Certificates).
- [`docs/en/DOMAIN_RULES.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/DOMAIN_RULES.md): Collegiate Esports domain rules (Single/Double Elimination brackets, BO1/3/5 scoring, TFT 7-8 room math, Bye seed assignments).
- [`docs/en/ACCEPTANCE_CRITERIA.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/ACCEPTANCE_CRITERIA.md): Feature acceptance criteria formulated in BDD / Given-When-Then structure.
- [`docs/en/RBAC.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/RBAC.md): Access control matrix across 4 user roles (Participant, Seasonal Staff, Permanent Staff, Super Admin).
- [`docs/en/FIGMA_HANDOFF.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/FIGMA_HANDOFF.md) & [`docs/en/FIGMA_TRACEABILITY.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/FIGMA_TRACEABILITY.md): Figma UI/UX handoff specifications, Cyberpunk design token dictionary, screen flows, and SRS traceability.
- [`docs/en/SCHEMA_MISMATCH_INVENTORY.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/SCHEMA_MISMATCH_INVENTORY.md): Comprehensive inventory reconciling SRS document schemas against physical PostgreSQL DDL definitions.
- [`docs/en/SRS_IMPLEMENTATION_GAP_ANALYSIS.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/SRS_IMPLEMENTATION_GAP_ANALYSIS.md) & [`docs/en/SRS_RECONCILIATION_PLAN.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/SRS_RECONCILIATION_PLAN.md): Source code implementation gap analysis and technical alignment roadmap.
- [`docs/en/CONFLICT_REGISTRY.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/CONFLICT_REGISTRY.md): Registry of stakeholder requirement conflict resolutions.
- [`docs/en/tasks/`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/en/tasks/): 12 detailed technical task specifications (`TASK-AUTH-001` through `TASK-RBAC-001`, `TASK-FOUND-001A-G`...).

### 5.2. Vietnamese Branch — SRS Audit & Software Testing Architecture ([`docs/vi/testing/`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/))
- **Reconnaissance & Project Management:** [`REPOSITORY_AUDIT.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/REPOSITORY_AUDIT.md), [`PROJECT_PLAN.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/PROJECT_PLAN.md), [`TASK_BOARD.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/TASK_BOARD.md), [`WORK_LOG.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/WORK_LOG.md).
- **SRS 1.1 Formal Audit ([`docs/vi/testing/srs-audit/`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/)):**
  - [`SRS_AUDIT_REPORT.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/SRS_AUDIT_REPORT.md): In-depth audit report across 8 critical risk domains.
  - [`SRS_ISSUES.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/SRS_ISSUES.md): Catalog of 10 SRS defects with mathematical and logical counterexamples.
  - [`SRS_IMPROVEMENT_PROPOSAL.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/SRS_IMPROVEMENT_PROPOSAL.md): Systematic technical improvements proposal.
  - [`BUSINESS_RULE_GAPS.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/BUSINESS_RULE_GAPS.md): Analysis of 6 business rule gaps.
  - [`DATABASE_CONSISTENCY_REPORT.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/DATABASE_CONSISTENCY_REPORT.md): Physical database reconciliation report across 18 PostgreSQL tables.
  - [`STATE_TRANSITION_MATRIX.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/STATE_TRANSITION_MATRIX.md): Formal state machine transition matrices for tournaments and matches.
  - [`DECISION_LOG.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/DECISION_LOG.md): Architecture and technical decision registry.
  - [`SRS_REVISED_DRAFT.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/srs-audit/SRS_REVISED_DRAFT.md): Proposed SRS 1.2 Draft.
- **ISO/IEC/IEEE 29119 Test Design ([`docs/vi/testing/test-design/`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/)):**
  - [`TEST_PLAN.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/TEST_PLAN.md): ISO 29119 Master Test Plan.
  - [`TEST_STRATEGY.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/TEST_STRATEGY.md): Unified 5-tier test strategy for a solo developer.
  - [`TEST_SCENARIOS.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/TEST_SCENARIOS.md): Inventory of 23 test scenarios.
  - [`TEST_CASES.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/TEST_CASES.md): Detailed specifications for 17 test cases.
  - [`REQUIREMENT_TRACEABILITY_MATRIX.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/REQUIREMENT_TRACEABILITY_MATRIX.md): RTM providing 100% coverage of MUST requirements.
  - [`TEST_DATA_SPECIFICATION.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/TEST_DATA_SPECIFICATION.md): Specification for 100% synthetic test data (Zero CCCD compliant).
  - [`TEST_COVERAGE_GAP.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/test-design/TEST_COVERAGE_GAP.md): Test coverage gap analysis report.
- **Academic Testing Deliverables ([`docs/vi/testing/reports/`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/reports/)):**
  - [`SOFTWARE_TESTING_DOCUMENT.md`](file:///D:/DUT%20ESPORTS/Web-giai-dau-docs/docs/vi/testing/reports/SOFTWARE_TESTING_DOCUMENT.md): Comprehensive 15-section software testing master document.

---

## 6. TEST EXECUTION QUICKSTART

Runtime requirements: **Node.js v24.x or higher** (native support for `--experimental-strip-types`). No heavyweight third-party dependencies required.

```bash
# 1. Execute all 56 Unit & API test cases:
npm test

# 2. Run Unit Testing tier independently:
npm run test:unit

# 3. Run API Testing tier independently:
npm run test:api

# 4. Execute peak performance & load benchmark:
npm run test:perf
```

---

## 7. CORE ARCHITECTURAL INVARIANTS

1. **Strict Zero CCCD Invariant:** 100% of database tables and frontend forms contain zero national ID fields or images. Student identification relies strictly on student ID cards and university registration records.
2. **UUID Primary Keys (100% UUID PKs):** All 18 database tables utilize random UUIDs (`gen_random_uuid()`) to prevent enumeration attacks.
3. **Unified User Identity:** The `users` table handles authentication across all roles (Admin, Permanent Staff, Seasonal Staff, Participant); the `participants` table acts as a 1:1 extended KYC profile.
4. **Open-Source Mapping & Budget Optimization:** OpenStreetMap with Leaflet.js eliminates high Google Maps API costs for non-profit student organizations.

---

## 8. COPYRIGHT & CREDITS

- **Governing Body:** Management Board of DUT Esports Club — Danang University of Science and Technology (DUT).
- **Address:** 54 Nguyen Luong Bang St., Hoa Khanh Bac Ward, Lien Chieu Dist., Da Nang City, Vietnam.
- **License:** Internal academic and software testing project asset.
