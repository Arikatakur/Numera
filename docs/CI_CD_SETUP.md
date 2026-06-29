# CI/CD Setup Guide — Numera → TestFlight via GitHub Actions

This guide walks through the one-time setup required to make the GitHub Actions
deploy pipeline work. After this you never touch it again — every merge to `main`
automatically builds and pushes a new TestFlight build.

---

## Overview

```
Push to main
  → CI job: build + test         (.github/workflows/ci.yml)
  → Deploy job: archive + upload  (.github/workflows/deploy.yml)
      → Fastlane match  (downloads cert + profile from private certs repo)
      → xcodebuild archive
      → upload_to_testflight (via App Store Connect API)
```

---

## Step 1 — Create a Private Certs Repo

Fastlane Match stores encrypted certificates and provisioning profiles in a
private Git repo. Create one now:

1. Go to GitHub → New repository
2. Name it `numera-certs` (or anything you like)
3. Set it to **Private**
4. Do not add a README or `.gitignore`
5. Copy the SSH URL: `git@github.com:YOUR_USERNAME/numera-certs.git`

---

## Step 2 — Create an App Store Connect API Key

This key lets Fastlane talk to Apple without a username/password.

1. Go to [App Store Connect → Users and Access → Integrations → API Keys](https://appstoreconnect.apple.com/access/api)
2. Click **+** to create a new key
3. Name it `Numera CI`
4. Role: **App Manager** (minimum required for TestFlight uploads)
5. Download the `.p8` file — **you can only download it once**
6. Note the **Key ID** and **Issuer ID** shown on the page

---

## Step 3 — Generate an SSH Key for the Certs Repo

The deploy job needs to clone the private certs repo. Use a deploy key.

```bash
# On your Mac, generate a new key pair (no passphrase)
ssh-keygen -t ed25519 -C "numera-ci" -f ~/.ssh/numera_ci_deploy -N ""

# Print the public key — you'll add this to the certs repo
cat ~/.ssh/numera_ci_deploy.pub

# Print the private key — you'll add this as a GitHub secret
cat ~/.ssh/numera_ci_deploy
```

Add the **public key** to the certs repo:
- `numera-certs` → Settings → Deploy keys → Add deploy key
- Title: `GitHub Actions`
- Key: paste the public key
- Allow write access: **yes** (match may need to push new certs on first run)

---

## Step 4 — Initialize Match (run once, locally on your Mac)

```bash
# In the Numera repo root
bundle install

# Set up env vars for this one-time run
export MATCH_GIT_URL="git@github.com:YOUR_USERNAME/numera-certs.git"
export MATCH_PASSWORD="choose-a-strong-passphrase"
export APPLE_TEAM_ID="YOUR10CHARID"

# This creates and uploads your App Store distribution cert + profile
bundle exec fastlane match appstore
```

Match will ask for your Apple ID and password to create the certificate via
the Developer Portal, then encrypt and push everything to the certs repo.

> **Save the MATCH_PASSWORD somewhere safe.** You'll need it as a GitHub secret
> and whenever you run match locally.

---

## Step 5 — Add GitHub Secrets

Go to your Numera repo on GitHub → **Settings → Secrets and variables → Actions → New repository secret**.

Add all of these:

| Secret name | Where to get it |
|---|---|
| `APPLE_TEAM_ID` | [developer.apple.com/account](https://developer.apple.com/account) → Membership → Team ID (10 chars) |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → API Keys page → Key ID column |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect → API Keys page → Issuer ID (top of page) |
| `APP_STORE_CONNECT_KEY_P8` | Contents of the `.p8` file you downloaded, **base64-encoded**: `base64 -i AuthKey_XXXXXXXX.p8 \| tr -d '\n'` |
| `MATCH_GIT_URL` | SSH URL of your certs repo, e.g. `git@github.com:YOUR_USERNAME/numera-certs.git` |
| `MATCH_PASSWORD` | The passphrase you chose in Step 4 |
| `MATCH_SSH_PRIVATE_KEY` | The private key from Step 3 (`cat ~/.ssh/numera_ci_deploy`) |

---

## Step 6 — Register the App in App Store Connect

Before the first upload can succeed, the app must exist:

1. [App Store Connect → My Apps → +](https://appstoreconnect.apple.com/apps)
2. Click **New App**
3. Platforms: iOS
4. Name: `Numera`
5. Bundle ID: `com.numera.app` (must match `fastlane/Appfile` and your Xcode project)
6. SKU: `numera` (any unique string)
7. User Access: Full Access
8. Click **Create**

---

## Step 7 — Set Signing in Xcode

Once you have the Xcode project open on a Mac:

1. Select the `Numera` target → Signing & Capabilities
2. Uncheck **Automatically manage signing**
3. Team: select your team
4. Provisioning Profile: the one Match created will be named
   `match AppStore com.numera.app` — select it
5. Bundle Identifier: `com.numera.app`

Commit the updated `.xcodeproj` settings.

---

## Step 8 — Create the `testflight` GitHub Environment (optional but recommended)

This lets you require a manual approval before any deploy proceeds.

1. Repo → Settings → Environments → New environment
2. Name: `testflight`
3. Enable **Required reviewers** → add yourself
4. Save

The deploy workflow references `environment: testflight`, so every deploy will
pause and wait for your thumbs-up before uploading.

To skip the gate (fully automatic), remove the `environment:` line from
`.github/workflows/deploy.yml`.

---

## Local Development

For running Fastlane lanes on your Mac without polluting your shell env, create
a `.env.local` file in the repo root (it is already in `.gitignore`):

```bash
# .env.local — never commit this file
APPLE_TEAM_ID=YOUR10CHARID
MATCH_GIT_URL=git@github.com:YOUR_USERNAME/numera-certs.git
MATCH_PASSWORD=your-match-passphrase
APP_STORE_CONNECT_KEY_ID=XXXXXXXXXX
APP_STORE_CONNECT_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_STORE_CONNECT_KEY_P8=<base64 encoded .p8 content>
```

Fastlane reads `.env.local` automatically.

---

## Build Numbers

The deploy workflow sets the Xcode build number to `GITHUB_RUN_NUMBER` (a
monotonically incrementing integer unique to the repo). This means:

- Build 1 = first ever deploy run
- Build 2 = second run, etc.

Apple requires each uploaded build to have a higher build number than the
previous one. As long as you don't reorder or skip GitHub Actions runs, this is
always satisfied automatically.

---

## Typical Flow After Setup

```
# Feature work
git checkout -b feature/my-screen
# ... code ...
git push
# → CI job runs: build + test

# Ship it
git checkout main
git merge feature/my-screen
git push
# → CI job runs: build + test
# → Deploy job runs: match → archive → TestFlight upload
# (if testflight environment is enabled, you approve first)
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `match` can't clone the certs repo | Check `MATCH_SSH_PRIVATE_KEY` secret and that the deploy key is added to the certs repo with write access |
| `No provisioning profile` | Run `bundle exec fastlane match appstore` locally to generate; commit certs repo |
| `Invalid API key` | Re-check `APP_STORE_CONNECT_KEY_P8` is base64 encoded with no newlines |
| Build number not incrementing | Ensure `increment_build_number` is pointing at the correct `.xcodeproj` path in `Fastfile` |
| `No such scheme "Numera"` | Open the Xcode project and make sure the scheme is set to **Shared** |
