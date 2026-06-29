# GitHub Workflow — Commit and Push Instructions

Use this guide when turning the Stitch export into a GitHub project.

---

## 1. First-Time Setup

Open a terminal inside the project folder:

```bash
cd stitch_project_genesis
```

Check files:

```bash
ls
git status
```

If this is not yet a Git repo:

```bash
git init
```

Add the remote repository:

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
```

Check remote:

```bash
git remote -v
```

---

## 2. Branch Workflow

Do not work directly on `main` unless the user explicitly asks.

Create a feature branch:

```bash
git checkout -b feature/project-docs
```

Branch naming examples:

```bash
feature/swiftui-design-system
feature/home-dashboard
feature/add-transaction-flow
feature/insights-screen
feature/premium-paywall
fix/activity-row-alignment
docs/update-handoff
```

---

## 3. Check Status Before Changes

Always run:

```bash
git status
```

Use this to see:
- modified files
- untracked files
- current branch
- staged changes

---

## 4. Stage Files

Stage all changes:

```bash
git add .
```

Or stage specific files:

```bash
git add CLAUDE.md CHANGELOG.md HANDOFF.md docs/
```

Check staged files:

```bash
git status
```

---

## 5. Commit Message Rules

Use Conventional Commits.

Format:

```bash
git commit -m "type: short description"
```

Types:

```text
feat:     new feature
fix:      bug fix
docs:     documentation only
style:    UI/style formatting only
refactor: code restructure
chore:    maintenance
test:     tests
```

Examples:

```bash
git commit -m "docs: add Claude project workflow"
git commit -m "feat: add SwiftUI design system"
git commit -m "feat: build premium home dashboard"
git commit -m "fix: align transaction amounts with tabular digits"
git commit -m "style: update dashboard card spacing"
git commit -m "chore: add gitignore for SwiftUI project"
```

---

## 6. Push to GitHub

First push for a new branch:

```bash
git push -u origin feature/project-docs
```

After that, use:

```bash
git push
```

---

## 7. Pull Before Working

Before starting work on an existing repo:

```bash
git checkout main
git pull origin main
```

Then create a branch:

```bash
git checkout -b feature/new-work
```

---

## 8. Merge / Pull Request Flow

Recommended:
1. Push feature branch.
2. Open Pull Request on GitHub.
3. Review changes.
4. Merge into `main`.
5. Delete branch after merge.

Commands after merge:

```bash
git checkout main
git pull origin main
git branch -d feature/project-docs
```

---

## 9. Safety Checklist Before Commit

Before every commit:

```bash
git status
git diff
```

Check:
- no secrets
- no `.env`
- no API keys
- no Apple signing files
- no private certificates
- no personal financial data
- changelog updated
- handoff updated

---

## 10. Safety Checklist Before Push

Before every push:

```bash
git status
```

Make sure:
- working tree is clean or intentionally dirty
- commit message is clear
- branch name is correct
- files are reviewed
- no secret files are included
- `CHANGELOG.md` is updated
- `HANDOFF.md` is updated

Push:

```bash
git push
```

---

## 11. If You Accidentally Commit to Main

If not pushed yet:

```bash
git checkout -b feature/recover-work
git checkout main
git reset --hard origin/main
```

If already pushed, do not force push unless you fully understand the consequences.

Safer option:
- create a new branch from current state
- open a PR
- ask before rewriting history

---

## 12. Useful Commands

See recent commits:

```bash
git log --oneline --decorate --graph -10
```

See changed files:

```bash
git diff --name-only
```

See unstaged diff:

```bash
git diff
```

See staged diff:

```bash
git diff --cached
```

Undo unstaged changes to a file:

```bash
git restore path/to/file
```

Unstage a file:

```bash
git restore --staged path/to/file
```

Rename current branch:

```bash
git branch -m new-branch-name
```

---

## 13. Recommended First Commit

After adding these docs:

```bash
git checkout -b docs/project-workflow
git add CLAUDE.md CHANGELOG.md HANDOFF.md docs/
git commit -m "docs: add project workflow and handoff instructions"
git push -u origin docs/project-workflow
```

---

## 14. Recommended `.gitignore`

Use a `.gitignore` suitable for SwiftUI, Stitch exports, and general development.

Do not commit:
- `.DS_Store`
- Xcode DerivedData
- build folders
- `.env`
- secrets
- signing files
- temporary archives
- dependency folders

See the root `.gitignore` if included.
