# DUT ESPORTS — Product Analysis, Business Rules & Design Specifications

🌐 **Language / Ngôn ngữ:** **[English](README.md)** | **[Tiếng Việt](../vi/README.md)**

This directory contains the English technical documentation for the **DUT ESPORTS Tournament Management Platform**, focusing on domain specifications, business rules, system workflows, and task decompositions.

---

## Directory Contents

| Document | Description |
|---|---|
| [`BUSINESS_RULES.md`](BUSINESS_RULES.md) | 30+ core business rules indexed by identifier (`BR-AUTH`, `BR-KYC`, `BR-TEAM`, `BR-TRN`, `BR-CHK`, `BR-CERT`...) |
| [`WORKFLOWS.md`](WORKFLOWS.md) | 8 standardized operational workflows (`WF-001` through `WF-008`: User Registration, KYC, Tournament, Brackets, Check-in, etc.) |
| [`DOMAIN_RULES.md`](DOMAIN_RULES.md) | Collegiate Esports rules: Single/Double Elimination brackets, BO1/3/5 scoring, TFT 7-8 room math, Bye seed assignment |
| [`ACCEPTANCE_CRITERIA.md`](ACCEPTANCE_CRITERIA.md) | Feature acceptance criteria formulated in BDD / Given-When-Then structure |
| [`RBAC.md`](RBAC.md) | 4-tier access control matrix (Participant, Seasonal Staff, Permanent Staff, Super Admin) |
| [`FIGMA_HANDOFF.md`](FIGMA_HANDOFF.md) | UI/UX handoff specifications and Cyberpunk design tokens |
| [`FIGMA_TRACEABILITY.md`](FIGMA_TRACEABILITY.md) | Traceability matrix from Figma screen designs to SRS requirements |
| [`SCHEMA_MISMATCH_INVENTORY.md`](SCHEMA_MISMATCH_INVENTORY.md) | Detailed reconciliation between SRS schema descriptions and physical PostgreSQL DDL definitions |
| [`SRS_IMPLEMENTATION_GAP_ANALYSIS.md`](SRS_IMPLEMENTATION_GAP_ANALYSIS.md) | Gap analysis comparing SRS requirements against existing backend/frontend code |
| [`SRS_RECONCILIATION_PLAN.md`](SRS_RECONCILIATION_PLAN.md) | Strategic reconciliation plan to harmonize specifications with codebase |
| [`CONFLICT_REGISTRY.md`](CONFLICT_REGISTRY.md) | Registry of stakeholder requirement conflict resolutions |
| [`PROJECT_PLAN.md`](PROJECT_PLAN.md) | High-level roadmap and architectural milestones |
| [`DEV_AUDIT_2026-10-10.md`](DEV_AUDIT_2026-10-10.md) | Engineer development audit report |
| [`TASK_SPEC_TEMPLATE.md`](TASK_SPEC_TEMPLATE.md) | Standardized task specification template |
| [`tasks/`](tasks/) | Directory containing 12 technical task specifications (`TASK-AUTH-001` to `TASK-RBAC-001`) |

---

For Software Testing Architecture and Formal SRS Audit reports, refer to the Vietnamese documentation suite at [`../vi/testing/`](../vi/testing/).
