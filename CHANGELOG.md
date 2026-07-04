# CHANGELOG

All notable changes to **Numera** are documented here.  
Format: newest first. Each entry maps to one meaningful commit or milestone.

---

## [0.11.0] — 2026-07-03

Numera Pro subscriptions (StoreKit 2). Budgeting, recurring, and CSV export are premium.

### Added
- `Services/PremiumManager.swift` — StoreKit 2: loads monthly/yearly/lifetime products (`org.clientvault.numera.pro.*`), tracks entitlements via `Transaction.currentEntitlements`, listens to `Transaction.updates` for renewals/refunds, purchase + restore. Entitlements are the on-device source of truth (no server validation).
- `Features/Premium/PaywallView.swift` — Quanto-anatomy paywall in Numera identity: star badge, feature checklist (budgeting / recurring "SOON" / export / support), three pricing cards with live App Store prices and a computed "Save X%" badge on yearly, 14-day free-trial CTA when eligible, Terms / Privacy / Restore links, graceful state when products aren't configured yet.
- `Components/PremiumBadge.swift` — `PremiumBadge` capsule, `UnlockGradientButton` (teal→mint), and `PremiumLockCard` (blurred locked card, Quanto Overview style).
- `Numera/Resources/Numera.storekit` — local StoreKit configuration (3 products, 14-day free intro offer on yearly) wired into the run scheme via `project.yml`, so purchases are testable in the simulator without App Store Connect.

### Changed
- `BudgetView` — locked behind Pro: non-subscribers see the Quanto-style budgeting pitch (mock ring + "Unlock") instead of the budget UI.
- `SettingsView` — "Try Numera Pro for free!" gradient banner (free users), General → Subscription row (Free/Pro; opens paywall or manage-subscriptions sheet), new Automations section with a Recurring transactions row (Premium badge → paywall; "Soon" for subscribers), Export data row shows a Premium badge and opens the paywall for free users.
- `InsightsView` — locked "Recurring insights" and "Budgeting insights" cards (Quanto Overview style) for free users.
- `NumeraApp` — injects `PremiumManager` and starts the entitlement listener at launch.

### Notes
- No database migration needed — entitlements live on-device.
- App Store Connect setup still required before TestFlight purchases work (see HANDOFF).

---

## [0.10.0] — 2026-07-03

Quanto-parity settings suite. Every row does something real.

### Added
- `Features/Settings/SettingsView.swift` — rebuilt hub in Quanto structure (General / Preferences / Privacy & security / Data / About) using Numera card language: profile card, icon-tile rows, hairline dividers.
- `Features/Settings/CategoriesView.swift` — category manager: Expense/Income tabs, long-press drag reorder (persisted `sort_order`), tap to edit; `CategoryEditSheet` with name, 11-color palette, 40-emoji grid, delete (transactions fall back to "Other").
- `Features/Settings/AccountsView.swift` — total-balance hero, per-account computed balances (starting ± transactions), `AccountEditSheet` (name, emoji, starting balance, delete).
- `Features/Settings/CurrencyPickerView.swift` — searchable currency list (30 currencies, flags + symbols); selection reformats money app-wide.
- `Features/Settings/ReminderView.swift` — Never/Daily/Weekly/Monthly + time wheel; schedules repeating local notifications via `ReminderScheduler`; shows a hint when permission is denied.
- `Features/Settings/MonthStartDayView.swift` — 1–31 grid; every period calculation (Home, Activity, Insights, Budget) honors the chosen start day.
- Settings toggles: First day of week (Mon/Sun), Display cents, Haptic feedback, Hide balances.
- Data tools: Export CSV (share sheet), Import CSV (file picker; creates unknown categories/accounts by name), Erase data (wipes all rows, re-seeds defaults).

---

## [0.9.0] — 2026-07-03

Functional analytics and budgeting.

### Added
- `Features/Insights/InsightsView.swift` (rebuilt) — all live from DataStore: category donut with center total and "% from last month" badge, category breakdown rows (count, amount, share), income-vs-expenses 6-month paired bars (tap a month to switch periods), "Income left" card with currency/% toggle, calendar spend grid, cash flow card, highest-spending-day card. Month picker via Quanto-style Select date sheet.
- `Features/Budget/BudgetView.swift` — overall monthly budget ring ("Left this month" with spent/limit), per-category limit cards with progress rings (danger state when over), add/edit/remove via `BudgetEditSheet`; backed by the `budgets` table. Home safe-to-spend now uses the real overall budget.
- Chart components: `DonutChart`, `DayBarsChart` (dashed average line), `MonthlyBarsChart`, `BudgetRing`, `CalendarSpendGrid`.

---

## [0.8.0] — 2026-07-03

Quanto-style shell: glass tab bar, floating add, Activity rebuild.

### Added
- `Components/GlassTabBar.swift` — floating Apple-glass pill (ultraThinMaterial, soft border, sliding highlight) with 5 tabs: Home, Activity, Insights, Budget, Settings.
- Floating (+) button pinned bottom-right above the bar (Quanto placement), opens Add Transaction from every tab.
- `Components/EmojiIconTile.swift` — Quanto signature card element: emoji in a rounded square with category-colored border. Used across rows, grids, and editors.
- `Components/SelectMonthSheet.swift` — Quanto "Select date": year pills + month grid, future months disabled. Used by Home, Activity, Insights.
- Transaction editing — tap any row to open it in `AddTransactionView` (prefilled) with save/delete; context-menu delete on rows.
- Error toast — failed writes roll back optimistic state and surface a dismissible banner.

### Changed
- `ActivityView` — rebuilt in Quanto layout: centered month + big period total, per-day bars with dashed average line, filter chips (type, account, category, expanding search), day-grouped list with per-day totals and emoji rows.
- `AddTransactionView` — categories come from the user's category store (kind-aware for expense/income, hidden for transfers), accounts from the account store, amount shows the selected currency symbol, keypad haptics.
- `HomeView` — real month-over-month change badge, mini donut from live category totals, top-2 category legend, safe-to-spend from the overall budget (with set-budget CTA), month picker sheet, pull-to-refresh.
- `ContentView` / `NumeraApp` — five-tab shell, DataStore bootstrap on sign-in, store reset on sign-out.

---

## [0.7.0] — 2026-07-03

Schema v2 + real persistence. Every feature now reads and writes Supabase.

### Added
- `supabase/migrations/20260703000000_create_categories.sql` — user-editable `categories` table (name, emoji, color, expense/income kind, sort order) + RLS; seed of 11 expense + 4 income defaults on sign-up, backfilled for existing users.
- `supabase/migrations/20260703000001_rewire_category_refs.sql` — `transactions.category_id` and `budgets.category_id` uuid FKs (legacy enum values mapped by name), rebuilt budget uniqueness, drops the `transaction_category` enum.
- `supabase/migrations/20260703000002_accounts_emoji.sql` — `accounts.emoji` replaces `sf_symbol`; "Main account" seeded for every user.
- `Services/DataStore.swift` (+ `+Aggregates`, `+CSV`) — replaces TransactionStore: Supabase CRUD for transactions/categories/accounts/budgets with optimistic updates and rollback, period aggregates (totals, category breakdown, daily totals, monthly series, safe-to-spend, account balances), CSV export/import, erase-and-reseed.
- `Services/Period.swift` — budgeting-month math honoring a custom month start day (1–31, clamped per month).
- `Services/AppSettings.swift` (expanded) — persisted preferences: currency, display cents, haptics, month start day, first weekday, reminder schedule, hide balances.
- `Services/MoneyFormatter.swift`, `Services/Haptics.swift`, `Services/ReminderScheduler.swift`, `Services/SupabaseDTOs.swift`.
- Models: `UserCategory` (with palette/emoji suggestions and seed mirror), `Budget`, `CurrencyInfo`; `Transaction` and `Account` reworked to id-based references.

### Changed
- `MoneyText` / `TransactionRow` — read currency, cents, and privacy from the environment; rows render Quanto-style emoji tiles.
- `MockData` — preview-only seed with stable UUIDs (runtime data comes from Supabase).

### Removed
- `Services/TransactionStore.swift` — superseded by DataStore.
- Fixed `Category` enum — categories are user data now.

---

## [0.6.0] — 2026-07-01

Supabase database schema — tables, types, RLS, and triggers.

### Added
- `supabase/migrations/20260701000000_create_types.sql` — Postgres enums `transaction_type` and `transaction_category`, mapping 1-to-1 with `TransactionType` and `Category` in Swift.
- `supabase/migrations/20260701000001_create_profiles.sql` — `profiles` table linked to `auth.users`; trigger auto-creates a profile row on every sign-up; `set_updated_at` function shared by all tables.
- `supabase/migrations/20260701000002_create_accounts.sql` — `accounts` table (id, user_id, name, balance, sf_symbol); RLS — users see only their own accounts; indexes on `user_id`.
- `supabase/migrations/20260701000003_create_transactions.sql` — `transactions` table (id, user_id, type, amount, category, title, note, date, account_name, account_id); full RLS; composite indexes on `(user_id, date)`, `(user_id, category)`, `(user_id, type)`.
- `supabase/migrations/20260701000004_create_budgets.sql` — `budgets` table; `category = NULL` row = overall monthly budget (replaces hardcoded $3,000 in `TransactionStore`); trigger seeds a $3,000 default budget for every new user at sign-up.
- `supabase/README.md` — apply order, Swift↔Postgres enum mapping table, RLS notes, sign-up flow explanation.

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
