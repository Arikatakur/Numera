# CHANGELOG

All notable changes to this project should be documented in this file.

Use this changelog to track design, code, documentation, and project-structure changes.

The format follows a simplified version of [Keep a Changelog], and commit messages should follow Conventional Commits.

---

## [Unreleased]

### Added
- Added `Services/TransactionStore.swift` — `@MainActor @Observable` store; holds transactions in memory (seeded from MockData); add/delete; computed `totalSpent`, `totalIncome`, `safeToSpend` per month; `recentTransactions`.
- Added `Services/AppSettings.swift` — `@MainActor @Observable` shared settings; `isPrivate: Bool` controls balance visibility across all views.
- Added `Features/Settings/SettingsView.swift` — full settings screen: user avatar + email (from AuthManager), Hide Balances toggle (AppSettings), app version, sign-out with confirmation dialog.
- Added Supabase Swift SDK (`supabase-swift 2.x`) via Swift Package Manager in `project.yml`.
- Added `App/SupabaseConfig.swift` — project URL + anon key constants (placeholders, user must fill in).
- Added `Services/SupabaseManager.swift` — `SupabaseClient` singleton.
- Added `Services/AuthManager.swift` — `@MainActor @Observable` class managing session state via `authStateChanges` stream; methods for sign-in, sign-up, Apple sign-in, sign-out.
- Added `Features/Auth/WelcomeView.swift` — launch landing screen with Sign in with Apple button (native `SignInWithAppleButton`) and Continue with Email button. Includes SHA256 nonce generation for Apple auth.
- Added `Features/Auth/EmailAuthView.swift` — sheet with Sign In / Create Account toggle, email + password fields, confirm-password for sign-up, email confirmation card.
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
- Added `App/ContentView.swift` — `TabView` with custom tab bar and floating Add button.
- Decided final app name: **Numera**.
- Committed to Nike-editorial visual direction.

### Changed
- Updated all views to use `TransactionStore` from environment instead of static `MockData`. Adding a transaction now immediately reflects in Home and Activity.
- Updated all views to use `AppSettings.isPrivate` from environment — privacy toggle is now global and synchronized across Home, Activity, Insights, Settings.
- Updated `HomeView` — "View Insights" and "Details" navigate to Insights tab; "SEE ALL" navigates to Activity tab; month picker opens a sheet with last 6 months; reads live data from `TransactionStore`; greets user by name from `AuthManager`.
- Updated `AddTransactionView` — Save button creates a real `Transaction` and calls `TransactionStore.add()`; account pill opens account picker sheet (seeded from MockData.accounts); date pill opens `DatePicker` in a sheet; "VIEW ALL" opens all-category grid sheet. Amount is properly parsed as `Decimal`.
- Updated `ActivityView` — reads transactions from `TransactionStore`; shows empty state when no results; privacy toggle is global.
- Updated `InsightsView` — "View spending details" and "VIEW ALL" navigate to Activity tab.
- Updated `ContentView` — removed `SettingsPlaceholderView`; replaced with real `SettingsView`; passes navigation closures to `HomeView` and `InsightsView`.
- Updated `App/NumeraApp.swift` — now routes after launch animation: `WelcomeView` if no session, `ContentView` if signed in. Auth state driven by `AuthManager.session` via `authStateChanges` stream.
- Updated `.github/workflows/ci.yml` — replaced broken `fastlane test` (no test targets) with `xcodebuild build` compile-check using `CODE_SIGNING_ALLOWED=NO` on iOS Simulator. Removed unnecessary Ruby/Gemfile step from CI.
- Added project documentation workflow (`CLAUDE.md`, `HANDOFF.md`, `docs/`).

### Fixed
- Fixed CI workflow that was failing because `fastlane test` had no test targets to run.

### Removed
- Removed GitHub Actions + Fastlane approach in favour of Xcode Cloud.
- Removed Ruby/Bundler setup from CI (no longer needed for compile check).

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
