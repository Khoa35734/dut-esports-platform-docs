TASK-ID: TASK-FE-FOUND-001
Title: Implement Core Cyber Design System & CSS Token Foundation

Goal:
Establish the frontend global CSS design tokens, typography, color variables, and the 8 core reusable UI components defined in the Figma Design System (`#20:2`) without adding business logic.

Requirements:
SRS Section 4.1 (User Interface), NFR-USB-01 (Responsive Design)

Conflict IDs:
NONE

Current Behavior:
The frontend has basic initial styling but lacks the standardized dark cyber-esports design tokens and reusable component library matching the Figma Design System.

Target Behavior:
`DUT_esports_frontend` contains:
1. Global CSS variables matching the Figma tokens in `src/styles/tokens.css` (Background `#0C0C0F`, Surface `#141419`, Brand `#C9233E`, Status Good `#2DD4BF`, Warn `#F59E0B`, Error `#EF4444`, 8px spacing scale, Montserrat typography).
2. The 8 standardized, typed React components matching Figma Component Sets with variants:
   - `SRS/Button` (`Primary`, `Secondary`, `Danger`, `Disabled`)
   - `SRS/Input` (`Default`, `Focus`, `Error`, `Disabled`)
   - `SRS/Badge` (`Success`, `Pending`, `Error`, `Neutral`)
   - `SRS/Navigation` (`Default`, `Active`, `Disabled`)
   - `SRS/Table` (`Header`, `Default`, `Selected`)
   - `SRS/Modal` (`Confirm`, `Reason`, `Error`)
   - `SRS/TournamentCard` (`Open`, `Upcoming`, `Completed`)
   - `SRS/Feedback` (`Loading`, `Empty`, `Error`, `Success`, `Pending`)
3. Zero Tailwind CSS dependency; pure CSS Modules / Vanilla CSS.

Scope:
- `DUT_esports_frontend/src/styles/`
- `DUT_esports_frontend/src/components/ui/` (or equivalent component structure)

Out of Scope:
- Backend API integration.
- Business page views (Auth, KYC, Check-in, Bracket, etc.).
- Modifying backend code.

Affected Modules:
`DUT_esports_frontend`

Likely Files:
- `DUT_esports_frontend/src/styles/tokens.css`
- `DUT_esports_frontend/src/styles/globals.css`
- `DUT_esports_frontend/src/components/ui/Button.tsx`
- `DUT_esports_frontend/src/components/ui/Input.tsx`
- `DUT_esports_frontend/src/components/ui/Badge.tsx`
- `DUT_esports_frontend/src/components/ui/Navigation.tsx`
- `DUT_esports_frontend/src/components/ui/Table.tsx`
- `DUT_esports_frontend/src/components/ui/Modal.tsx`
- `DUT_esports_frontend/src/components/ui/TournamentCard.tsx`
- `DUT_esports_frontend/src/components/ui/Feedback.tsx`

Dependencies:
NONE

Business Rules:
BR-KYC-002 (Zero CCCD — verify no CCCD input types or defaults)

RBAC Rules:
NONE (UI component library only)

Workflow:
NONE

Schema Impact:
NONE

API Impact:
NONE

Implementation Steps:
1. Create `src/styles/tokens.css` with CSS custom properties matching Figma Design System `#20:2`.
2. Ensure Montserrat font is configured in Next.js layout (`src/app/layout.tsx`).
3. Implement `Button` component with variant props (`variant`: `'primary' | 'secondary' | 'danger' | 'disabled'`).
4. Implement `Input` component with state props (`state`: `'default' | 'focus' | 'error' | 'disabled'`, `errorMessage?: string`).
5. Implement `Badge` component with status variants (`status`: `'success' | 'pending' | 'error' | 'neutral'`).
6. Implement `Navigation` component with active state handling.
7. Implement `Table` component wrapper with dark cyber borders.
8. Implement `Modal` component with backdrop, close trigger, and `reason` input support.
9. Implement `TournamentCard` component with game tag, title, dates, and status badge.
10. Implement `Feedback` alert/callout component for loading/empty/error/success states.
11. Run `npm run lint` and `tsc --noEmit` in `DUT_esports_frontend` to verify type safety.

Constraints:
- Strictly NO Tailwind CSS. Use CSS Modules (`.module.css`).
- Must adhere to the 8px grid system.
- Components must be strictly typed with TypeScript.

Tests Required:
- Unit / component rendering checks for variants and disabled states.
- Type check: `tsc --noEmit` passes with zero errors.

Acceptance Criteria:
- Given any of the 8 UI components, When rendered in story/test mode with each variant, Then the DOM matches the Figma visual styles and colors.
- Given `Input` with `errorMessage`, Then the red border and error message caption are displayed.
- Given `Button` with `disabled` prop, Then clicking does not trigger `onClick`.

Status: DONE

Definition of Done:
- [x] CSS design tokens match Figma hex colors and typography exactly.
- [x] All 8 components implemented with typed variants.
- [x] Responsive design verified (Desktop 1440, Tablet 768, Mobile 390).
- [x] `tsc --noEmit` passes cleanly.

Rollback / Safety:
NONE (Isolated UI library components)
