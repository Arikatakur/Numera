# CHANGELOG

All notable changes to **Numera** are documented here.  
Format: newest first. Each entry maps to one meaningful commit or milestone.

---

## [0.16.2] — 2026-07-12

### Fixed
- **Insights donut center showed the pooled "Other" total for categories below the 5th.** 0.15.1 fixed the *list* highlight, but the donut center was still driven by the ring *segment* — so selecting a small slice (Shopping, Transport, …) showed the summed "Other" amount instead of that category's. The center now reads from the selected **row**, so it always shows the exact category's spend and share (the ring still pools small slices into "Other").
- **Large amounts wrapped onto two lines in the donut center.** A big value like ₪1,710.80 broke across lines inside the ring. The center amount (selected-category and default total) now scales to a single line via `lineLimit(1)` + `minimumScaleFactor(0.5)`.

---

## [0.16.1] — 2026-07-12

App Store distribution-blocker fixes (see `appstore-review.md` for the full audit).

### Added
- **Privacy manifest** (`PrivacyInfo.xcprivacy`) — declares the app's `UserDefaults` access with Apple's approved reason `CA92.1`, `NSPrivacyTracking = false`, and no tracking domains, satisfying Apple's required-reason-API rule.

### Changed
- **Account deletion warns about subscriptions.** The "Delete account?" dialog now states that deletion won't cancel an Apple subscription and offers Pro users a **Manage subscription** button (opens the system sheet) before deleting, per Apple's account-deletion guidance.
- **Paywall prices come only from StoreKit.** Removed the hard-coded `$2.99 / $24.99 / $59.99` fallbacks; a `—` placeholder shows until products load, so displayed prices always match the customer's storefront.

---

## [0.16.0] — 2026-07-12

### Added
- **Recurring & Budgeting insights (Numera Pro).** The two placeholder lock cards at the bottom of Insights are now real, data-driven cards — gated so Pro subscribers see them live and free users see a blurred preview with an unlock CTA.
  - **Recurring expenses** — the period's total recurring-expense value, a chevron into the recurring-rules manager, and (on the Monthly range) a calendar marking every day a recurring expense lands on; other ranges list the active rules. New `DataStore` helpers `recurringExpenseTotal(in:)`, `recurringExpenseDays(in:)`, `recurringDates(for:in:)`, and `activeRecurringExpenses` walk each rule's cadence out from its `nextRun`.
  - **Budget left** — how much of the overall monthly budget is left for the focused period, over a teal history bar chart (tap a bar to focus that period, scoped to the card); shows a "No data" state until an overall budget exists. New `DataStore.budgetRemaining(in:)`.
- **`PremiumGate`** — a reusable wrapper that shows real content when unlocked and a blurred, non-interactive preview with a lock + gradient unlock CTA when not, replacing the fake-placeholder `PremiumLockCard` in Insights.

---

## [0.15.2] — 2026-07-12

### Fixed
- **Buttons only responded to taps near their center.** Many tappable controls are `Button`s with `.buttonStyle(.plain)` whose label draws its shape via `.background(…)`. Without an explicit `.contentShape`, a plain button's hit area collapses toward its drawn content, so the padding, the `Spacer` gap, and (on rows with no fill) everything but the text was dead. Added `.contentShape(…)` matching each control's visible shape across the shared components (`PrimaryButton`, `FloatingAddButton`, `FloatingPillButton`, `UnlockGradientButton`, `OnboardingOptionRow`, `OnboardingSecondaryButton`, `TransactionRow`) and the paywall pricing cards, budget cards, What's New / Settings CTAs, and the currency / account / reminder / month-start rows. The whole control is now tappable.
- **Paywall "Unlock" did nothing for Monthly/Yearly when their products hadn't loaded.** `buy()` returned silently when the selected plan wasn't among the App Store products (e.g. a subscription still pending in App Store Connect), so the button looked broken while Lifetime worked. It now surfaces a clear "This plan isn't available right now" alert instead of a dead tap. (If subscriptions never load on TestFlight, the underlying cause is App Store Connect product/subscription-group status, not the app.)

---

## [0.15.1] — 2026-07-12

### Fixed
- **Insights category rows selected in bulk below the 5th item.** The list highlight was derived from the tapped row's *donut segment*, but every category past the top-5 maps to the same pooled "Other" segment — so tapping Shopping (or anything below it) lit up every row from Shopping down. Selection is now tracked by row (`selectedRow`, the single source of truth) and the donut segment is *derived* from it, so exactly one row highlights while the donut still pools the overflow into "Other". Tapping the "Other" ring maps back to a representative row.

---

## [0.15.0] — 2026-07-08

First-run onboarding: a ten-step, once-only setup that gets a new user to value
before the tabs — currency, month cycle, first account, categories, a first
transaction, an optional reminder, and a non-blocking Pro preview. Built entirely
on the existing dark/mint design system (rounded type, Liquid Glass, SF Symbols,
haptics) so every screen feels native to Numera.

### Added
- **`Features/Onboarding/` flow.** A new `OnboardingView` coordinator drives ten
  steps with a capsule progress indicator, a back button (from step 2), and calm
  slide/opacity transitions: **Welcome** (three value props), **Privacy** (trust,
  "not a banking app"), **Currency** (locale-preselected common list + full
  `CurrencyPickerView`), **Month start** (1st / Today / Custom day grid),
  **Main account** (name, emoji, optional starting balance), **Categories**
  (confirms the seeded starter set), **First transaction** (add real / use sample
  / skip), **Reminder** (Morning / Evening / Not now), **Pro preview**
  (non-blocking), and **Done**.
- **Shared onboarding primitives** (`OnboardingComponents.swift`): `OnboardingScaffold`
  (header + scrollable content + pinned CTA), `OnboardingHeader`, `OnboardingValueProp`
  (What's-New-style symbol tiles), `OnboardingOptionRow` (accent-selected cards),
  `OnboardingProgressBar`, and `OnboardingSecondaryButton`. `OnboardingModel` holds
  the transient selections.
- **Per-user onboarding flag in the database.** New migration
  `20260708000000_profile_onboarding.sql` adds `profiles.has_completed_onboarding`
  (existing users backfilled to `true`; new sign-ups default to `false`).
  `AuthManager` loads it from the profile when the session resolves and sets it
  via `markOnboardingComplete()`; `NumeraApp` routes a signed-in user to
  `OnboardingView` while it's `false`, then to the tabs. Because it lives on the
  account (not the device), onboarding follows the user across devices and a new
  login on the same device is onboarded correctly. Fails open (treated as
  completed) if the flag can't be read.
- **`DataStore.emptyPreview()`** — a seeded-but-transaction-free preview store for
  the onboarding SwiftUI previews.

### Changed
- Onboarding **reuses the real services**: currency and month-start day persist to
  `AppSettings`; the account step updates the seeded "Main account" in place (or
  creates one) via `DataStore` rather than duplicating it; the sample expense is a
  real `DataStore` transaction; the reminder schedules through `ReminderScheduler`.
- **Returning users are never gated** — the migration backfills existing accounts
  to `true`, and as a belt-and-braces the flow also marks itself complete if the
  store loads any existing transactions.
- **What's New refreshed** — the Home "What's new?" sheet leads with the guided
  welcome (new `hand.wave.fill` tile), and the TestFlight notes
  (`fastlane/changelog.txt`) are rewritten for 0.15.

### Notes
- **Notification permission** is requested only after the user picks Morning or
  Evening (via `ReminderScheduler.reschedule`); "Not now" never prompts.
- **The Pro paywall** (`PaywallView`) is presented only when the user taps
  "View Pro" — onboarding completes with everything free.
- No new permissions, product IDs, or dependencies. The only backend change is
  the additive `profiles` column above (existing RLS covers it); Home/Activity/
  Insights/Budget/Settings/StoreKit behavior is unchanged.

---

## [0.14.1] — 2026-07-07

Chart and interaction fixes reported from the 0.14 TestFlight build: the Activity day bars now render, every chart responds to taps, the pie matches Quanto, the calendar stays inside its card, and several keyboard/button annoyances are gone.

### Fixed
- **Activity day bars were invisible.** `DayBarsChart` drew its bars on a numeric x-scale with `.ratio` width, which Swift Charts rendered as zero-width. Switched to a categorical x-scale with a fixed bar width (the same pattern as the working `MonthlyBarsChart`) so bars draw again.
- **Average value wasn't tappable.** The "How we calculate the average" sheet is now opened from a button positioned on the rule via `chartOverlay` (the old `RuleMark` annotation clipped its own hit area).
- **Insights bars didn't update the card.** `MonthlyBarsChart` replaced the scrub-oriented `.chartXSelection` with a `chartOverlay` tap that maps to the nearest period (`proxy.value(atX:as:)`), so a single tap on any bar — income/expenses and income-left — updates that card's focused period.
- **Pie slices weren't selectable, especially small ones.** Insights category-breakdown rows are now buttons that select the matching donut segment (small slices pool into "Other"), so any category is one tap away and the donut center follows. Tapping a selected row again clears it.
- **Calendar spilled past its card.** `CalendarSpendGrid` now builds explicit week rows (a `VStack`/`HStack` grid) instead of a `LazyVGrid`, which under-reported its height inside the glass container — days 26–31 stayed outside the card.
- **Budget showed a value before one was set.** The budget editor's ring preview stays empty with a "—" placeholder until an amount is entered, instead of showing a negative "over" state computed against a zero limit.
- **Budget Save needed many taps.** The amount field auto-focuses, so Save sat under the keypad. Save (and Remove) are pinned below the scroll area and stay above the keyboard, plus the sheet dismisses the keyboard on scroll — Save now fires on the first tap.
- **Safe-to-spend card was narrower than Your Month.** Its content now stretches to full width so both Home cards align.
- **What's New didn't return after a TestFlight update.** The dismissal is keyed on the full version+build string instead of the marketing version (which stays "1.0.0" across builds), so a new TestFlight upload resurfaces the card.
- **New-entry keyboard shoved the page.** `ignoresSafeArea(.keyboard)` moved to the `NavigationStack` (the sheet's root, where avoidance is applied) so focusing the note field no longer pushes the fixed layout up.

### Changed
- **Charts match Quanto's flatter shapes.** Donut segments use flat (butt) ends instead of pill caps; monthly and day bars use a small corner radius instead of fully-rounded tops.
- **Month start day** selected-day circle is now the mint accent (was white) to match the app.

---

## [0.14.0] — 2026-07-06

Apple-native everywhere: SF Rounded (Quanto) type, real Swift Charts, native large titles, an Insights range selector (weekly → yearly), full activity history, glassy calendar days, budget editing inside the card, and an instant (+) button.

### Added
- **Insights range selector.** A native segmented control (Weekly / Monthly / Quarterly / Yearly) at the top of Insights drives every card. New `PeriodUnit` + unit-aware `PeriodMath.period(of:containing:)`, `shift(_:by:unit:)`, `title(_:unit:)`, `shortLabel(_:unit:)` (weeks respect the first-day-of-week setting; months keep the month-start day; quarters/years use calendar boundaries). The history charts show the last 6 weeks/months/quarters (5 years); the month picker and calendar apply to Monthly; the change badge compares against the previous week/month/quarter/year.
- **"How we calculate the average" sheet.** Tapping the average value on the Activity chart opens a Quanto-style bottom sheet (wave-over-dash glyph, one-paragraph explanation, white "Got it" pill) — `AverageInfoSheet` in `DayBarsChart.swift`. The ⓘ badge is gone; the label is just the number, per the reference screenshots.
- **Full activity history.** The Activity list now shows every month (grouped by day, lazily rendered), not just the selected one — the month picker still drives the hero total and chart. Day headers outside the current year include the year. `SelectMonthSheet` always offers years back to **2020** (further if older data exists).
- **Budget editing inside the card.** Tapping a budget card (overall or category limit) opens the editor sheet with the card itself at the top — a live ring preview that re-renders from the amount field as you type — plus the amount, Save, and Remove inside. Pencil badges/buttons removed everywhere; the overall card is now fully tappable with an edit/remove context menu.

### Changed
- **SF Pro Rounded everywhere (the Quanto look).** `AppTypography` switched from the `PlusJakartaSans` custom fonts — which were never registered and silently fell back to plain SF — to the system **rounded** design. Every `.system(size:)` call in the app now passes `design: .rounded`, the root view sets `.fontDesign(.rounded)`, and `UINavigationBar` large/inline titles adopt SF Rounded via appearance attributes (fonts only — bar backgrounds untouched so iOS 26 keeps its automatic glass).
- **Native Swift Charts.** All graphs rebuilt on Apple's Charts framework, themed to Numera only:
  - `DayBarsChart` — `BarMark` day bars (rounded, thin, dimmed stubs on empty days), dashed `RuleMark` average with its value as a trailing annotation, clean right-axis `0` / niced-max labels, sparse single-line day labels.
  - `MonthlyBarsChart` — grouped income/expense `BarMark` pairs (`.position(by:)`), native `.chartXSelection` bar taps, the selected period's axis label highlighted in a capsule, explicit category-order domain.
  - `DonutChart` — `SectorMark` ring with rounded caps and angular insets, native `.chartAngleSelection` segment taps, and the empty track drawn in `chartBackground` aligned to the plot frame. The Insights donut hole absorbs taps (clears the selection) so center taps can't select a slice.
- **Native large titles.** Insights, Budget, and Settings use `.navigationTitle` large titles that collapse into the system (glass on iOS 26) bar on scroll, like stock Apple apps.
- **Glassy calendar days.** `CalendarSpendGrid` cells are interactive Liquid Glass blended in one `LiquidGlassGroup`; today is accent-tinted glass. The calendar card container switched to a solid subtle card (glass must not stack on glass).
- **What's New card refresh.** Emoji tiles (🚀 ✨ 🔁 …) replaced with SF Symbols on mint tiles; contents updated for 0.14. Home's mini-donut ✨ fallback is now an SF sparkles symbol.
- TestFlight notes (`fastlane/changelog.txt`) rewritten for this build.

### Fixed
- **Laggy floating (+).** The add sheet's state moved into a tiny `AddTransactionFAB` view, so tapping (+) no longer re-renders the whole `TabView` tree first — on Insights that recomputation delayed the sheet noticeably.
- **Calendar day numbers overflowing.** Day cells are fixed-height with scaling amount text (min 0.5×), so a day gaining data can no longer grow the card or push digits out of bounds.
- **Wrapping axis day labels.** Two-digit day labels (16 / 23 / 30) can no longer wrap vertically — native `AxisValueLabel`s render on one line (replaces the old manual `fixedSize` workaround).

### Removed
- `Components/PageTitle.swift` — replaced by native large titles.
- `PlusJakartaSans` font references (dead: fonts were never bundled/registered).

---

## [0.13.0] — 2026-07-06

Native Apple chrome + chart interactivity: system tab bar, interactive Liquid Glass on controls, per-card month focus in Insights, and alignment/percent fixes.

### Added
- **Donut segment tap.** Tapping a slice of the Insights summary donut dims the others and swaps the center to that category's spend — emoji, name, amount, and share. Tap the slice again (or off the ring) to return to the month total.
- **Per-card month focus in Insights.** Tapping a bar in "Income vs expenses" or "Income left" focuses that month inside that card only — the legend/title and a small month tag follow along; the page period no longer changes.
- **Average-line explainer.** The average value on the Activity chart is now a tappable ⓘ label that opens a popover explaining the calculation (this month's total ÷ days elapsed so far; past months ÷ all their days).
- **Edit affordance on category limits.** Each Budget limit card now shows a pencil badge and a context menu (**Edit limit** / **Remove limit**); tapping the card opens the editor as before.
- `Components/PageTitle.swift` — shared 34pt in-content page title.

### Changed
- **Native Apple tab bar (HIG).** Replaced the custom floating pill + paged `TabView` with the system `TabView` and SF Symbol tab items — the bar adopts real Liquid Glass automatically on iOS 26, tab switching is smooth (the page-style `TabView` was the lag), and pushed screens hide it the system way (`.toolbar(.hidden, for: .tabBar)`). `GlassTabBar` removed; `AppTab` now lives in `App/AppTab.swift` with native icons (house / list.bullet / chart.pie / wallet.pass / gearshape).
- **Interactive Liquid Glass on controls.** New `liquidGlassControl(_:tint:fallbackFill:)` and `LiquidGlassGroup` (Apple's `GlassEffectContainer`) in `Components/LiquidGlass.swift`, adopted by the Activity filter chips + search, the Home month pill, Select-month year pills and month cells, `PrimaryButton` and the floating (+) (accent-tinted glass), `CategoryChip`, the Budget limit cards, and the budget editor's category picker. iOS 17–25 keeps the previous solid surfaces as the fallback. Controls nested inside glass cards stay non-glass (no glass on glass).
- **Page titles aligned.** Insights, Budget, and Settings titles moved in-content so they align with the 20pt content margin like Home, instead of hugging the screen edge on the system large-title margin.
- **Average line lighter.** The dashed average line is dimmer (white 25%) with a tertiary label so it reads as a guide, not data.
- Bottom scroll spacers trimmed to 80pt — the native tab bar insets scroll content automatically.

### Fixed
- **"Income left" percent clamps at 0%.** Overspending (or a month with no income) shows 0% instead of a negative percentage or a dash.
- **Wrong-looking numbers after tapping a chart bar.** A bar tap used to switch the entire page's month, so a 5,000 spend in May could suddenly read as a different month's small value elsewhere on the page; bar selection is now scoped to its own card (see Added).

---

## [0.12.0] — 2026-07-06

App Store submission prep + Liquid Glass groundwork — the three review blockers, recurring transactions, the glass design system, the What's New card, and UX fixes. First TestFlight build with release notes (1.0.0 build 20).

### Added
- **"Numera just got better" card + What's New sheet.** Quanto-style status card on Home (`Features/Home/WhatsNew.swift`): 🚀 tile, headline, X to dismiss, and a white **What's new?** pill that opens a release-highlights sheet. Dismissal is stored per app version (`whatsNewDismissedVersion`), so the card returns on the next release.
- **TestFlight release notes.** `fastlane/changelog.txt` holds the "What to Test" notes; the `beta` lane now waits for build processing (`skip_waiting_for_build_processing: false`) and attaches `changelog` (from that file), `beta_app_description`, and `beta_app_feedback_email`.
- **Recurring transactions (Numera Pro).** `Models/RecurringRule.swift` (weekly/monthly/yearly), `supabase/migrations/20260706000000_create_recurring_rules.sql` (table + RLS), `RecurringRuleDTO`, `Services/DataStore+Recurring.swift` (CRUD + `materializeDueRecurring()` which generates due transactions on launch and advances `next_run` idempotently), a Pro-gated **Repeat** option on the Add Transaction screen, and `Features/Settings/RecurringView.swift` to pause/resume/delete rules. Loading is resilient — if the migration hasn't been applied yet, recurring is skipped rather than breaking data load.
- **In-app account deletion** (Apple requirement). Settings → **Delete account** with a destructive confirmation; `supabase/functions/delete-account/` Edge Function (service-role `admin.deleteUser`, cascades all data) and `AuthManager.deleteAccount()`.
- **Real Privacy / Terms / Support pages** hosted on the ClientVault-Web site at `clientvault.org/numera/{privacy,terms,support}`, written to reflect Numera's actual behavior (Supabase account + cloud data, StoreKit purchases, reminders, CSV, in-app deletion; no analytics/ads/tracking). Linked from Settings and the paywall.
- `Components/TabBarVisibility.swift` — `TabBarVisibility` + `.hidesTabBar()` to hide the floating tab bar / add button on pushed detail screens.
- Sign in with Apple entitlement is now generated by XcodeGen from a proper `project.yml` `entitlements` block.
- **Tap a calendar day → day transactions.** Tapping a cell in the Insights calendar opens `Features/Insights/DayTransactionsSheet.swift` — a per-day income/expense summary and the day's rows (tap to edit, long-press to delete), or a "No transactions" empty state. `CalendarSpendGrid` gained an optional `onSelectDay` handler that turns each cell into a button.
- **Support & feedback settings section** — Rate on App Store (App Store write-review link once `AppInfo.appStoreID` is set, otherwise the in-app review prompt), plus Help us improve / Report a bug / Feature request, each opening the new Numera feedback forum (`clientvault.org/numera/feedback`) with the composer pre-set to that post type.
- **"Other" settings section** — "Follow creator on IG", opening the Instagram app (deep link) with a web fallback. `instagram` added to `LSApplicationQueriesSchemes`.
- **`App/AppInfo.swift`** — central metadata (Instagram handle, App Store ID, forum URLs, version string). Placeholders (`instagramHandle`, `appStoreID`) are marked with TODOs to fill before release.
- **Import template flow.** `Features/Settings/ImportTransactionsView.swift` — the Import row now opens a dedicated screen with **Download template** (a ready-to-fill CSV using your own account/categories/currency) and **Import data**, plus a "dates as DD/MM/YYYY" hint. `DataStore.templateCSVFile()` generates the template; the app version now also appears under the Settings footer tagline.
- `Components/ShareSheet.swift` — extracted the share wrapper so both export and template download reuse it.
- **Instagram brand glyph** — added `instagram.logo` (template-rendered, 1x/2x/3x) to `Assets.xcassets` since SF Symbols has no Instagram logo, and a `SettingsRow(assetIcon:)` variant so brand rows can use custom glyphs. The "Follow creator on IG" row now shows the real Instagram mark instead of a camera symbol.
- **Notification permission alert** — setting a reminder now surfaces an actionable "Turn on notifications" alert with an **Open Settings** button when permission is denied (authorization is requested with `[.alert, .sound, .badge]` before scheduling, and the reminder is only scheduled once granted).

### Changed
- **Toolchain pinned to Xcode 26.** `project.yml` sets `xcodeVersion: "26.0"` (deployment target stays iOS 17.0) and both workflows (`ci.yml`, `deploy.yml`) select `xcode-version: '26.0'`, so builds always use the iOS 26 SDK that real Liquid Glass requires.
- **Glass gating centralized in `Components/LiquidGlass.swift`.** `glassSurface`/`materialSurface` are replaced by `liquidGlass(cornerRadius:tintFallback:)` — real `.glassEffect(.regular, in:)` behind `#available(iOS 26, *)`, `.ultraThinMaterial` + hairline as the iOS 17–25 fallback. `NumeraCard`, `NumeraCardSmall`, `SettingsCard`, `PremiumLockCard`, the `GlassTabBar` pill, and the error toast all route through it; the toast's manual hairline stroke now exists only in the fallback (real glass draws its own edge). `PremiumLockCard` clips its blurred placeholder to the card shape, which the iOS 26 path no longer does implicitly.
- **Home header simplified.** The greeting no longer shows the account name — just "Good morning/afternoon/evening" and the tagline.
- **Liquid Glass (iOS 26+), gated.** `glassSurface(...)` now applies real `.glassEffect(.regular, in: .rect(...))` on iOS 26 and keeps the `.ultraThinMaterial` treatment as the iOS 17–25 fallback — double-gated with `#if compiler(>=6.2)` (SDK) and `#available(iOS 26, *)` (runtime) so it builds on any Xcode. Flows to every card, chart card, and the floating tab bar. Chart data keeps a plain (non-glass) background for legibility, per the design skill.
- **Follow creator on IG** now opens the Instagram app via `UIApplication.canOpenURL`/`open` (handle constant `AppInfo.instagramHandle = "saleemyousef"`), with a web fallback only when the app isn't installed.

- **App Store–style glass cards.** Added a shared `View.glassSurface(cornerRadius:)` modifier (translucent `.ultraThinMaterial` + dark brand tint + hairline highlight) and adopted it in every card container — `NumeraCard`, `NumeraCardSmall`, `SettingsCard`, and `PremiumLockCard` — so cards across the app read as one frosted-glass system.
- **CSV import/export now uses DD/MM/YYYY** to match the import template and hint. Import still accepts older `YYYY-MM-DD` exports and ISO timestamps (`DataStore.parseCSVDate`); export rows switched to `dd/MM/yyyy`.
- Renamed the monthly/yearly Pro subscription product IDs to
  `org.clientvault.numera.pro.monthly.v2` / `...yearly.v2` (App Store Connect
  now uses `.v2` IDs for these two; lifetime is unchanged). Updated
  `PremiumManager`, `Numera.storekit`, `HANDOFF.md`, and `appstore-review.md`
  to match.
- Home's **Safe to Spend** card is now Pro-gated, matching the Budget tab it
  reports on: free users see a blurred `PremiumLockCard` ("Unlock
  safe-to-spend") instead of real budget data; Pro users see the card
  unchanged.
- **Recurring transactions is now a shipping Pro feature** — removed the "SOON" badge from the paywall and the "coming soon" alert in Settings; the Settings row opens the real manager.
- **Accounts are Pro-gated past the first** — free users get one account; a second opens the paywall. A Premium tag appears under the accounts list for free users.
- Paywall + Settings now link to the real `clientvault.org/numera/*` legal URLs instead of the GitHub repo.
- Settings sub-pages (Categories, Accounts, Currency, Reminder, Month start, Recurring) hide the floating tab bar + add button while pushed, so it no longer overlaps their content.

### Fixed
- **"Follow creator on IG" cancel bug** — cancelling the system "Open in Instagram?" prompt no longer opened the web profile. Root cause was the old `openURL(completion:)` fallback firing the web URL on a cancelled/failed app-open; replaced with an up-front `canOpenURL` decision.
- **Activity chart date labels** — two-digit day labels (16, 23, 30) no longer wrap onto a second line; they render on one line at natural width.
- **Home Safe-to-Spend card** is now hidden entirely until Budget is unlocked (Pro), instead of showing a locked placeholder; it animates back in when Pro is active.
- **"Income left this month" red dash.** When no income was recorded for the period, the percentage view rendered a bare `—` in expense-red that read as a stray line. The income-left value is now always white in both currency and % modes, matching the rest of the hero numbers.
- **Add Transaction keyboard.** Focusing the title field no longer shoves the whole screen up and misaligns the keypad — keyboard avoidance is disabled on the fixed layout so the field stays put above the keyboard.
- **`project.yml` entitlements** — corrected malformed YAML (duplicate `path`/`properties` keys nested under `info`) that would have broken `xcodegen generate` in CI and silently dropped the Sign in with Apple entitlement.

### Removed
- **Eye (privacy) toggles in page headers.** The eye button is gone from Home, Activity, Insights, and Budget — **Hide balances** now lives only in Settings → Privacy & security, so balances can't be un-hidden with a stray tap.

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
