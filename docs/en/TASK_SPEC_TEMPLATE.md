# Developer Task Specification Template

Every executable Developer task must use this format:

```markdown
TASK-ID: [e.g., TASK-FOUND-001A]
Title: [Concise Title]

Goal:
[One concise behavioral outcome]

Requirements:
[Exact SRS requirement IDs]

Conflict IDs:
[Relevant RC-* IDs only, or NONE]

Current Behavior:
[What the repository currently does]

Target Behavior:
[What it must do after this task]

Scope:
[Exactly what may be changed]

Out of Scope:
[Explicitly list nearby work that must NOT be changed]

Affected Modules:
[List modules]

Likely Files:
[List concrete file paths when they can be determined]

Dependencies:
[Completed tasks required first, or NONE]

Business Rules:
[Relevant BR-* IDs, or NONE]

RBAC Rules:
[Relevant RBAC-* IDs, or NONE]

Workflow:
[Relevant workflow IDs / allowed state transitions, or NONE]

Schema Impact:
[NONE / READ_ONLY / MIGRATION_REQUIRED]

API Impact:
[NONE / INTERNAL / PUBLIC]

Implementation Steps:
1. [Concrete step]
2. [Concrete step]

Constraints:
[Rules the Developer must not violate]

Tests Required:
[Exact test behaviors to add/update/run]

Acceptance Criteria:
[Explicit Given/When/Then or objective checks]

Definition of Done:
- [ ] Implementation matches Target Behavior
- [ ] Required Tests pass
- [ ] No regression introduced
- [ ] Code reviewed and approved

Rollback / Safety:
[Required only when schema/data behavior changes, or NONE]
```
