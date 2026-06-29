# Changelog Guide

This project uses `CHANGELOG.md` to track all meaningful changes.

The changelog is important because this project may move between:
- Stitch
- Claude
- ChatGPT
- GitHub
- SwiftUI/Xcode
- future developers

A clean changelog prevents confusion.

---

## When to Update the Changelog

Update `CHANGELOG.md` whenever you:

- add a screen
- redesign a screen
- add a component
- change colors
- change typography
- update navigation
- add SwiftUI code
- add a model
- add a service
- add persistence
- add import/export
- change app name/branding
- fix a bug
- remove a file
- rename a file
- add documentation
- change GitHub workflow
- update handoff instructions

---

## Required Format

Use:

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

Keep newest changes at the top.

---

## Section Meanings

### Added
Use for new:
- files
- screens
- components
- features
- documentation

Example:
```md
### Added
- Added `HeroCard` SwiftUI component for dashboard highlights.
```

### Changed
Use for updates to existing:
- UI
- design system
- navigation
- layouts
- copy
- architecture

Example:
```md
### Changed
- Updated Home dashboard to use Nike-style editorial cards.
```

### Fixed
Use for bugs or mistakes.

Example:
```md
### Fixed
- Fixed transaction amount alignment by using monospaced digits.
```

### Removed
Use for deleted or deprecated items.

Example:
```md
### Removed
- Removed unused Stitch placeholder screen.
```

---

## Before Commit Checklist

Before each commit, ask:

1. Did I add/change/fix/remove anything meaningful?
2. Did I update `CHANGELOG.md`?
3. Did I update `HANDOFF.md` if the session is ending?
4. Is the changelog clear enough for another person to understand?

---

## Example Entry

```md
## [Unreleased]

### Added
- Added SwiftUI `MoneyText` component.
- Added mock transaction model.

### Changed
- Updated dashboard hero card spacing.
- Renamed app placeholder from Luminous Ledger to Numera.

### Fixed
- Fixed category chart legend contrast in dark mode.

### Removed
- Removed duplicate exported HTML prototype.
```
