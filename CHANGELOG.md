# CHANGELOG

All notable changes to **Numera** are documented here.  
Format: newest first. Each entry maps to one meaningful commit or milestone.

---

## [0.5.0] — 2026-07-01

Functional UI wiring. Every button in the app now does something real.

### Added
- `Services/TransactionStore.swift` — `@Observable` in-memory store seeded from MockData. Supports add/delete and per-month aggregates (`totalSpent`, `totalIncome`, `safeToSpend`, `recentTransactions`). All views now read from this store so newly added transactions appear immediately.
- `Services/AppSettings.swift` — `@Observable` shared `isPrivate` flag. Privacy toggle is now global and synchronized across Home, Activity, Insights, and Settings.
- `Features/Settings/SettingsView.swift` — Real settings screen: user initials avatar, email from `AuthManager`, Hide Balances toggle, app version, sign-out with confirmation dialog.

### Changed
- `HomeView` — "View Insights" and "Details" navigate to Insights tab; "SEE ALL" navigates to Activity tab; month picker opens a 6-month selection sheet; data reads from `TransactionStore`; greeting uses signed-in user's name from `AuthManager`.
- `AddTransactionView` — Save button creates a real `Transaction` in `TransactionStore`; account pill opens account picker sheet; date pill opens `DatePicker` sheet; "VIEW ALL" opens full category grid. Amount correctly parsed as `Decimal`.
- `ActivityView` — reads from `TransactionStore`; shows empty state when no results; privacy toggle is global.
- `InsightsView` — "View spending details" and "VIEW ALL" navigate to Activity tab.
- `ContentView` — replaced `SettingsPlaceholderView` with real `SettingsView`; passes navigation closures to `HomeView` and `InsightsView`.
- `NumeraApp` — injects `TransactionStore` and `AppSettings` into the environment alongside `AuthManager`.

---

## [0.4.0] — 2026-07-01

Supabase authentication: email/password and Sign in with Apple.

### Added
- `supabase-swift 2.x` added as Swift Package Manager dependency in `project.yml`.
- `App/SupabaseConfig.swift` — project URL and anon key constants (placeholders; user must fill in).
- `Services/SupabaseManager.swift` — `SupabaseClient` singleton.
- `Services/AuthManager.swift` — `@MainActor @Observable` class; listens to `authStateChanges` async stream; exposes `signIn`, `signUp`, `signInWithApple`, `signOut`.
- `Features/Auth/WelcomeView.swift` — landing screen with native `SignInWithAppleButton` (SHA256 nonce/`CryptoKit`) and Continue with Email button.
- `Features/Auth/EmailAuthView.swift` — sheet with Sign In / Create Account toggle, email + password fields, confirm-password for sign-up, email-confirmation card.

### Changed
- `NumeraApp` — routes after launch animation based on auth state: `WelcomeView` if no session, `ContentView` if signed in. Auth state resolved from Supabase local session cache within ~200 ms.

### Fixed
- CI (`ci.yml`) — replaced broken `fastlane test` lane (no test targets) with `xcodebuild build` compile check (`CODE_SIGNING_ALLOWED=NO`). Removed unnecessary Ruby/Bundler step.

---

## [0.3.3] — 2026-06-30

TestFlight validation fixes: iPhone-only target and manual deploy trigger.

### Fixed
- `ITMS-90474` (iPad orientation error from Apple Validation) — `TARGETED_DEVICE_FAMILY: "1"` moved to target-level `settings.base` in `project.yml` (was incorrectly at project level, ignored by XcodeGen).
- Design-assets folder renamed from `Numera app icons` to `design-assets` to avoid spaces in path.

### Changed
- Deploy workflow (`deploy.yml`) — changed trigger from `push` to `workflow_dispatch` (manual only); prevents accidental TestFlight deployments on every push.

---

## [0.3.2] — 2026-06-30

Real app icon and first-launch animation.

### Added
- `Numera/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — 1024×1024 universal icon sourced from the design handoff package (dark background, green N+wave).
- `Numera/Resources/Assets.xcassets/numera-mark.imageset/` — transparent N+wave glyph used in the launch animation.
- `Features/Launch/LaunchAnimationView.swift` — ~4.6 s branded intro: glyph fades in at center → slides left → letters reveal A→N → tagline fades in → calls `onFinished`.
- `App/NumeraApp.swift` — overlays `LaunchAnimationView` on top of app root; fades out after animation completes.
- `design-assets/` — design handoff package: README, icon PNGs at all sizes, reference HTML animation.

### Fixed
- `CFBundleIconName: AppIcon` added to `Info.plist` via `project.yml` (was missing, causing App Store upload error).
- `Contents.json` for `AppIcon.appiconset` set to single universal 1024×1024 format (fixes icon validation).

---

## [0.3.1] — 2026-06-30

GitHub Actions + Fastlane + Match CI/CD pipeline fully operational.

### Added
- `.github/workflows/deploy.yml` — GitHub Actions deploy job on `macos-15`; installs XcodeGen, generates project, runs `fastlane beta`.
- `.github/workflows/ci.yml` — compile-check job on every push to `main`.
- `fastlane/Fastfile` — `beta` lane: Match cert fetch → `update_code_signing_settings` → increment build → `build_app` → `upload_to_testflight`.
- `fastlane/Matchfile` — HTTPS git storage, app identifier, team ID.
- `fastlane/Appfile` — bundle ID and team ID.
- `Gemfile` / `Gemfile.lock` — Fastlane gem.
- `project.yml` — XcodeGen spec; generates `Numera.xcodeproj` in CI. `TARGETED_DEVICE_FAMILY: "1"` at target level.

### Fixed
- Null-byte error in `app_store_connect_api_key` — P8 key written to `/tmp/AuthKey.p8` file; `key_filepath:` used instead of `key_content:`.
- `undefined method 'apple_team_id'` in Appfile — changed to `team_id(ENV["APPLE_TEAM_ID"])`.
- `match readonly: true` blocked cert creation on first run — overridden with `readonly: false`.
- Missing `DEVELOPMENT_TEAM` / `CODE_SIGN_IDENTITY` — added to xcargs in `build_app`.
- `update_code_signing_settings` — added to patch `.xcodeproj` before build (mirrors working `clientvault-app` pattern). Resolved "no signing certificate found" error.
- Switched to `maxim-lobanov/setup-xcode@v1` with `latest-stable` (Xcode 26 SDK).

---

## [0.2.0] — 2026-06-30

Initial SwiftUI app: design system, data models, and all core screens.

### Added
- `DesignSystem/AppColors.swift` — full dark-first palette with `Color(hex:)` initializer.
- `DesignSystem/AppTypography.swift` — Plus Jakarta Sans type scale; `moneyStyle` and `labelCapsStyle` view modifiers.
- `DesignSystem/AppSpacing.swift` — 8pt spacing scale and `AppRadius` corner radius tokens.
- `Models/Transaction.swift` — `Transaction`, `TransactionType`, `Category` with SF Symbol mapping.
- `Models/Account.swift` — `Account` model.
- `Models/MockData.swift` — sample transactions and accounts with computed month totals.
- `Components/MoneyText.swift` — privacy-aware money display with tabular digits.
- `Components/TransactionRow.swift` — icon, title, category/date, signed amount row.
- `Components/NumeraCard.swift` — `NumeraCard` and `NumeraCardSmall` glass-border containers.
- `Components/PrimaryButton.swift` — `PrimaryButton`, `FloatingAddButton`, `CategoryChip`.
- `Features/Home/HomeView.swift` — Nike-editorial Home: time-based greeting, month donut card, safe-to-spend card, recent activity.
- `Features/AddTransaction/AddTransactionView.swift` — type toggle, large amount display, category grid, numeric keypad.
- `Features/Activity/ActivityView.swift` — search bar, filter chips, date-grouped transaction list.
- `Features/Insights/InsightsView.swift` — editorial insight card, weekly bar chart, distribution donut, cash flow, top categories.
- `App/ContentView.swift` — `TabView` with custom tab bar and floating Add button.
- `App/NumeraApp.swift` — `@main` entry point.
- Decided final product name: **Numera**. Committed to Nike-editorial + Apple-native visual direction.

---

## [0.1.0] — 2026-06-29

Initial commit — Stitch design export and project documentation.

### Added
- Stitch-exported design screens: Home dashboard, Nike/editorial Home, Add Transaction, premium Add Transaction, Insights, editorial Insights, Activity feed.
- `luminous_ledger/DESIGN.md` — design tokens and screen specs from Stitch.
- `CLAUDE.md` — project context, assistant rules, design direction, code standards.
- `HANDOFF.md` — session-to-session handoff template.
- `CHANGELOG.md` — this file.
- `docs/GITHUB_WORKFLOW.md` — commit and push instructions.
- `docs/CHANGELOG_GUIDE.md` — changelog maintenance guide.
