# CLAUDE.md

## Project Name

**Luminous Ledger / Numera-style Expense Tracker**

This project is a Stitch-generated iOS design prototype for a premium expense tracking app inspired by:
- Quanto-style manual expense tracking
- Nike-app-style editorial/personalized UX
- Apple-native SwiftUI polish
- Apple Wallet / Apple Fitness / Apple Health clarity

The app should feel premium, private, calm, fast, and App Store-ready.

---

## Current Project Contents

This repository currently contains a Stitch export with visual screens and HTML prototypes.

Important folders:

```text
home_dashboard_nike_editorial/
add_transaction_premium/
insights_analytics_editorial/
home_dashboard/
add_transaction/
insights_analytics/
activity_feed/
luminous_ledger/DESIGN.md
```

Current source of truth for design tokens:
```text
luminous_ledger/DESIGN.md
```

Before making changes, read:
1. `CLAUDE.md`
2. `luminous_ledger/DESIGN.md`
3. `CHANGELOG.md`
4. `HANDOFF.md`

---

## Product Direction

This is not a banking app.

It is a manual-first premium expense tracker for users who want to:
- add expenses quickly
- understand spending clearly
- view insights and trends
- manage budgets
- manage accounts
- track recurring transactions
- keep financial data private

Core promise:

> Track expenses fast. Understand money clearly. Stay in control privately.

---

## Design Direction

The design should combine:

### Nike-inspired UX
Use:
- bold editorial cards
- personalized “For You” sections
- curated insights
- story-like money summaries
- premium membership / Pro feeling
- confident spacing and hierarchy

Do **not** make the app sporty.

### Apple-native UX
Use:
- SwiftUI-first thinking
- `NavigationStack`
- `TabView`
- native sheets
- native search
- native settings-style lists
- SF Symbols
- large titles
- haptics
- Face ID privacy
- blur/material tab bars
- rounded Apple-like cards

### Finance-specific UX
Use:
- large readable money amounts
- tabular digits
- clean charts
- category breakdowns
- clear transaction lists
- safe-to-spend cards
- budget progress
- privacy/hide balances mode

---

## Main App Screens

Preserve and improve these screens:

1. Splash / launch
2. Onboarding
3. Home dashboard
4. Activity feed / transactions
5. Add transaction
6. Transaction detail
7. Insights / analytics
8. Category breakdown
9. Budget
10. Accounts
11. Recurring transactions
12. Import / export
13. Settings
14. Premium paywall
15. Privacy / hide balances state

---

## Naming Direction

Current Stitch name: **Luminous Ledger**

Preferred final product name direction:
- **Numera**
- **Clario**
- **Lumio**
- **Finora**

Until final branding is decided, avoid hardcoding the final name in too many places. Use a central app name constant when implementation begins.

---

## Visual Rules

Use:
- dark-first UI
- near-black / deep navy background
- mint/volt accent
- premium rounded cards
- soft borders
- subtle glow
- clean spacing
- large numbers
- short text
- story cards
- Apple-like tab/navigation patterns

Avoid:
- generic fintech templates
- cluttered dashboards
- heavy accounting UI
- too many colors
- cheap gradients
- tiny unreadable charts
- long paragraphs inside the app UI

---

## SwiftUI Implementation Rules

When converting this design into SwiftUI:

### Architecture
Use a clean feature-based structure:

```text
App/
Core/
DesignSystem/
Features/
  Home/
  Activity/
  AddTransaction/
  Insights/
  Budget/
  Accounts/
  Settings/
Models/
Services/
Resources/
```

### Design System
Create reusable design primitives:
- `AppColors`
- `AppTypography`
- `AppSpacing`
- `AppRadius`
- `MoneyText`
- `MetricCard`
- `HeroCard`
- `StoryCard`
- `TransactionRow`
- `CategoryChip`
- `ChartCard`
- `PrimaryButton`
- `FloatingAddButton`

### Navigation
Use:
- `TabView` for main navigation
- `NavigationStack` per tab
- `.sheet` or `.fullScreenCover` for Add Transaction
- native swipe actions for transaction rows

### Data
Start with mock data.
Do not add cloud/backend until local UX works.

Suggested progression:
1. Static SwiftUI screens
2. Mock data models
3. Local persistence with SwiftData
4. Import/export
5. iCloud sync optional
6. AI voice optional

---

## Code Quality Rules

When writing code:
- keep files small and focused
- avoid giant views
- split UI into reusable components
- use descriptive names
- avoid hardcoded magic values when they belong in the design system
- support dark mode first
- keep accessibility in mind
- use `monospacedDigit()` for money values
- support RTL later; avoid layout decisions that break Arabic/Hebrew

---

## Privacy Rules

This is a finance app. Treat privacy as a core feature.

Do:
- hide amounts when privacy mode is enabled
- support Face ID lock later
- avoid tracking by default
- avoid sending financial data to third parties
- keep local-first mode as default

Do not:
- store secrets in the repo
- commit API keys
- commit `.env` files
- log real financial data
- add analytics before privacy policy is clear

---

## Changelog Rules

Every meaningful change must update `CHANGELOG.md`.

Update the changelog when:
- screens are added
- screens are redesigned
- components are added
- UX flows change
- design tokens change
- files are renamed/moved
- bugs are fixed
- project structure changes
- documentation changes

Use this format:

```md
## [Unreleased]

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Removed
- ...
```

Never leave changelog updates for “later.”

---

## Handoff Rules

Before ending a work session, update `HANDOFF.md`.

The handoff must include:
- current status
- what changed
- files touched
- what works
- what is incomplete
- known issues
- next recommended tasks
- testing/checking performed
- Git branch/commit status if available

A good handoff lets another developer or AI assistant continue immediately without guessing.

---

## Git Rules

Use Git for every meaningful step.

Before coding:
```bash
git status
```

Create a branch:
```bash
git checkout -b feature/<short-feature-name>
```

Stage changes:
```bash
git add .
```

Commit with a clear message:
```bash
git commit -m "feat: add premium home dashboard documentation"
```

Push:
```bash
git push -u origin feature/<short-feature-name>
```

Use Conventional Commits:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `style:` visual/style-only change
- `refactor:` code restructure
- `chore:` project maintenance
- `test:` tests

Do not push directly to `main` unless the user explicitly asks.

---

## GitHub Safety Checklist

Before every push:
- run `git status`
- check changed files
- make sure no secrets are included
- make sure generated junk files are not included
- update `CHANGELOG.md`
- update `HANDOFF.md`
- use a clear commit message
- push to a feature branch when possible

Never commit:
- `.env`
- API keys
- private certificates
- Apple signing files
- Google service secrets
- real user financial data
- temporary build folders
- Xcode DerivedData
- `.DS_Store`

---

## Current Priority

The immediate priority is to turn this Stitch export into a strong design/implementation base.

Recommended next steps:
1. review the exported screens
2. decide final app name
3. choose final visual direction
4. improve DESIGN.md if needed
5. create SwiftUI project
6. implement design system
7. build Home, Add Transaction, Activity, and Insights first

---

## Assistant Behavior

When working on this project:
- be direct and practical
- preserve existing files unless asked to replace them
- explain file changes clearly
- create downloadable artifacts when useful
- do not invent unavailable repo state
- do not claim tests passed unless actually checked
- ask before destructive actions
