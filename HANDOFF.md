# HANDOFF

## Current Status

This project is a Stitch-generated design export for a premium iOS expense tracker.

The project currently contains:
- design screenshots
- several HTML prototypes
- a Stitch-generated design system file
- documentation files for future AI/developer handoff

There is not yet a full SwiftUI/Xcode app inside this export.

---

## Current Design Direction

The app should become a premium manual expense tracker inspired by:

- Quanto-style simple expense tracking
- Nike-style editorial/personalized app experience
- Apple Wallet / Apple Fitness / Apple Health polish
- SwiftUI-native interaction patterns

The product should feel:
- premium
- private
- clean
- dark-first
- fast
- personal
- App Store ready

---

## Important Files

```text
CLAUDE.md
CHANGELOG.md
HANDOFF.md
docs/GITHUB_WORKFLOW.md
docs/CHANGELOG_GUIDE.md
luminous_ledger/DESIGN.md
```

Visual/reference folders:

```text
home_dashboard_nike_editorial/
add_transaction_premium/
insights_analytics_editorial/
home_dashboard/
add_transaction/
insights_analytics/
activity_feed/
```

---

## What Exists Now

### Screens
- Home dashboard
- Nike/editorial home dashboard
- Add transaction
- Premium add transaction
- Insights analytics
- Editorial insights analytics
- Activity feed

### Design system
- Dark-first palette
- Mint/volt accent
- rounded cards
- glassmorphism borders
- money typography
- transaction row guidelines
- chart color tokens

### Documentation
- Claude instructions
- changelog instructions
- handoff instructions
- GitHub workflow instructions

---

## What Does Not Exist Yet

The project does not yet include:
- Xcode project
- native SwiftUI implementation
- Swift data models
- SwiftData persistence
- local database
- real import/export
- subscription/paywall implementation
- AI voice entry
- iCloud sync
- automated tests

---

## Recommended Next Tasks

### Step 1 — Review Design
- Open all screen PNGs.
- Choose the preferred direction between the original dashboard and the Nike/editorial dashboard.
- Decide final app name:
  - Numera
  - Clario
  - Lumio
  - Finora
  - or another name

### Step 2 — Create SwiftUI Project
- Create a new iOS app in Xcode.
- Minimum recommended target: iOS 17+.
- Use SwiftUI.
- Add folders:
  - `DesignSystem`
  - `Features`
  - `Models`
  - `Services`
  - `Resources`

### Step 3 — Implement Design System
Start with:
- colors
- typography
- spacing
- radius
- reusable cards
- money text
- buttons
- category chips
- transaction rows

### Step 4 — Build Core Screens
Recommended order:
1. Home
2. Add Transaction
3. Activity
4. Insights
5. Budget
6. Settings
7. Premium Paywall

### Step 5 — Add Data
Start with mock data.
Then add local persistence with SwiftData.

---

## Known Issues / Risks

- Stitch HTML is a design reference, not production SwiftUI.
- Current design name may still be temporary.
- App Store legal/privacy copy is not finalized.
- Premium plan pricing is placeholder.
- Some screens exist only as images and may not have matching HTML.
- No automated tests exist yet.
- No Git remote status is known from this export.

---

## Session Checklist

Before ending every work session, update this file with:

```md
## Latest Session - YYYY-MM-DD

### Changed
- ...

### Files Touched
- ...

### Tested / Checked
- ...

### Incomplete
- ...

### Next
- ...

### Git Status
- Branch:
- Last commit:
- Pushed:
```

---

## Latest Session - 2026-06-30

### Changed
- Created full SwiftUI source code structure under `Numera/`.
- Decided app name: **Numera**, visual direction: **Nike editorial**.
- Implemented design system (colors, typography, spacing, radius).
- Implemented shared components (MoneyText, TransactionRow, NumeraCard, PrimaryButton, FloatingAddButton, CategoryChip).
- Implemented data models (Transaction, Category, Account) + MockData.
- Implemented Home screen (Nike editorial — greeting, month donut card, safe-to-spend card, latest activity).
- Implemented Add Transaction screen (type toggle, large amount, category grid, keypad).
- Implemented Activity screen (search, filter chips, date-grouped list).
- Implemented Insights screen (editorial insight, weekly trend bar chart, distribution donut, cash flow, top categories).
- Implemented root ContentView with custom tab bar + floating Add button.
- Settings screen is a placeholder.

### Files Touched
- `Numera/App/NumeraApp.swift` (new)
- `Numera/App/ContentView.swift` (new)
- `Numera/DesignSystem/AppColors.swift` (new)
- `Numera/DesignSystem/AppTypography.swift` (new)
- `Numera/DesignSystem/AppSpacing.swift` (new)
- `Numera/Components/MoneyText.swift` (new)
- `Numera/Components/TransactionRow.swift` (new)
- `Numera/Components/NumeraCard.swift` (new)
- `Numera/Components/PrimaryButton.swift` (new)
- `Numera/Models/Transaction.swift` (new)
- `Numera/Models/Account.swift` (new)
- `Numera/Models/MockData.swift` (new)
- `Numera/Features/Home/HomeView.swift` (new)
- `Numera/Features/AddTransaction/AddTransactionView.swift` (new)
- `Numera/Features/Activity/ActivityView.swift` (new)
- `Numera/Features/Insights/InsightsView.swift` (new)
- `CHANGELOG.md` (updated)
- `HANDOFF.md` (updated)

### Tested / Checked
- All Swift files written; not compiled (Windows environment — Xcode required on Mac).
- File structure matches CLAUDE.md architecture spec.
- Design tokens match `luminous_ledger/DESIGN.md`.
- Privacy mode wired through `isPrivate` flag on MoneyText and TransactionRow.

### Incomplete
- No Xcode `.xcodeproj` or `Package.swift` file (these must be created in Xcode on a Mac).
- Plus Jakarta Sans font must be added to Xcode project Resources and `Info.plist`.
- `@AppStorage` or SwiftData persistence not wired — all screens read from `MockData`.
- Settings screen is placeholder only.
- Budget screen not yet built.
- Transaction detail / edit flow not built.
- Onboarding / splash not built.
- Privacy Face ID lock not built.
- Xcode Cloud CI/CD not yet connected (see `docs/CI_CD_SETUP.md`).

### Next
1. Open `Numera/` folder in Xcode on a Mac and create a new iOS App project pointing at this source.
2. Add Plus Jakarta Sans font files to `Resources/` and register in `Info.plist`.
3. Build and verify all four screens compile and render correctly.
4. Wire add transaction sheet to actually create `Transaction` objects (needs `@State` store or `@Observable` model).
5. Set up Xcode Cloud (see `docs/CI_CD_SETUP.md`).
6. Build Settings screen.
7. Build Budget screen.
8. Replace MockData reads with a `TransactionStore` `@Observable` class.

### Git Status
- Branch: main (no feature branch created yet)
- Last commit: initial Stitch export
- Pushed: no

---

## Latest Session - 2026-06-29

### Changed
- Added documentation workflow files.
- Added Claude project instructions.
- Added changelog instructions.
- Added handoff instructions.
- Added GitHub push and commit instructions.

### Files Touched
- `CLAUDE.md`
- `CHANGELOG.md`
- `HANDOFF.md`
- `docs/GITHUB_WORKFLOW.md`
- `docs/CHANGELOG_GUIDE.md`

### Tested / Checked
- Verified the Stitch zip contains screen PNGs, HTML prototypes, and `luminous_ledger/DESIGN.md`.
- No code build or app runtime test was performed because this is not yet a SwiftUI/Xcode project.

### Incomplete
- Final app name not decided.
- SwiftUI project not created.
- Native implementation not started.
- App architecture not yet committed to GitHub.

### Next
- Choose final name.
- Review exported screens.
- Create SwiftUI project.
- Implement design system.
- Build Home and Add Transaction first.

### Git Status
- Branch: unknown
- Last commit: none in this exported zip
- Pushed: no
