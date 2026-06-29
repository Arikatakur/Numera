# CHANGELOG

All notable changes to this project should be documented in this file.

Use this changelog to track design, code, documentation, and project-structure changes.

The format follows a simplified version of [Keep a Changelog], and commit messages should follow Conventional Commits.

---

## [Unreleased]

### Added
- Created `Numera/` SwiftUI project folder structure (App, DesignSystem, Components, Models, Features, Services, Resources).
- Added `DesignSystem/AppColors.swift` — full color palette with hex init extension.
- Added `DesignSystem/AppTypography.swift` — Plus Jakarta Sans scale + `moneyStyle` / `labelCapsStyle` view modifiers.
- Added `DesignSystem/AppSpacing.swift` — 8pt spacing scale and corner radius tokens.
- Added `Models/Transaction.swift` — `Transaction`, `TransactionType`, `Category` models.
- Added `Models/Account.swift` — `Account` model.
- Added `Models/MockData.swift` — sample transactions, accounts, computed month totals and safe-to-spend.
- Added `Components/MoneyText.swift` — privacy-aware money display with tabular digits.
- Added `Components/TransactionRow.swift` — icon, title, category/date, signed amount row.
- Added `Components/NumeraCard.swift` — `NumeraCard` and `NumeraCardSmall` glass-border containers.
- Added `Components/PrimaryButton.swift` — `PrimaryButton`, `FloatingAddButton`, `CategoryChip`.
- Added `Features/Home/HomeView.swift` — Nike-editorial Home: greeting, month card with donut, safe-to-spend card, latest activity.
- Added `Features/AddTransaction/AddTransactionView.swift` — type toggle, large amount display, note field, category grid, numeric keypad.
- Added `Features/Activity/ActivityView.swift` — search bar, filter chips, date-grouped transaction list.
- Added `Features/Insights/InsightsView.swift` — editorial insight card, weekly bar chart, distribution donut, cash flow, top categories.
- Added `App/NumeraApp.swift` — SwiftUI `@main` entry point.
- Added `App/ContentView.swift` — `TabView` with custom tab bar and floating Add button.
- Added `docs/CI_CD_SETUP.md` — Xcode Cloud setup guide.
- Decided final app name: **Numera**.
- Committed to Nike-editorial visual direction.
- Decided on **Xcode Cloud** for CI/CD (over GitHub Actions + Fastlane).

### Changed
- Added project documentation workflow.
- Added `CLAUDE.md` with project context, assistant rules, changelog rules, handoff rules, and GitHub workflow.
- Added `HANDOFF.md` for session-to-session project continuity.
- Added `docs/GITHUB_WORKFLOW.md` with commit, push, and branch instructions.
- Added `docs/CHANGELOG_GUIDE.md` with changelog maintenance rules.

### Fixed
- Nothing fixed yet.

### Removed
- Removed GitHub Actions + Fastlane approach in favour of Xcode Cloud.

---

## [0.1.0] - 2026-06-29

### Added
- Initial Stitch export for premium expense tracker design.
- Added visual screens for:
  - Home dashboard
  - Nike/editorial home dashboard
  - Add transaction
  - Premium add transaction
  - Insights and analytics
  - Editorial insights and analytics
  - Activity feed
- Added Stitch-generated `luminous_ledger/DESIGN.md`.
- Added screen previews and HTML prototype files where available.

---

## Changelog Instructions

Every meaningful change must update this file.

Update `CHANGELOG.md` when:
- a new screen is created
- a screen is redesigned
- a component is added
- design tokens change
- naming/branding changes
- SwiftUI code is added
- models/services are added
- files are moved or renamed
- documentation changes
- GitHub/project workflow changes
- bugs are fixed
- incomplete work is finished

Use these sections:

```md
### Added
- New files, features, screens, components, docs.

### Changed
- Updates to existing behavior, UI, structure, or content.

### Fixed
- Bugs, broken layouts, wrong copy, broken code.

### Removed
- Deleted files, removed features, deprecated screens.
```

Keep entries short and clear.

Example:

```md
## [Unreleased]

### Added
- Added SwiftUI `HeroCard` component for dashboard sections.

### Changed
- Updated Home dashboard spacing to match Apple-style safe areas.

### Fixed
- Fixed transaction row amount alignment using tabular digits.
```

Before every commit, check whether the changelog needs an update.
