# CI/CD Setup — Numera via Xcode Cloud

Xcode Cloud is Apple's built-in CI/CD. It handles code signing automatically,
runs on Apple Silicon, and pushes directly to TestFlight. No certs repo, no
secrets to manage, no third-party tooling.

---

## How it works

```
Push to main (or open a PR)
  → Xcode Cloud picks up the change
  → ci_scripts/ci_post_clone.sh       (install tools / log env)
  → xcodebuild test                   (runs unit/UI tests)
  → ci_scripts/ci_pre_xcodebuild.sh  (set build number)
  → xcodebuild archive                (Release build, App Store signing)
  → ci_scripts/ci_post_xcodebuild.sh (log result)
  → Upload to TestFlight              (automatic, managed by Apple)
```

The `ci_scripts/` folder in this repo contains the hook scripts.
All workflow config (triggers, schemes, environments) lives in App Store Connect.

---

## One-time setup (do this once on a Mac)

### 1. Register the app in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → **+**
2. Platform: iOS
3. Name: `Numera`
4. Bundle ID: `org.clientvault.numera`
5. SKU: `numera`
6. Click **Create**

### 2. Open the Xcode project

Create (or open) the `Numera.xcodeproj` in Xcode.
Make sure:
- Bundle identifier is `org.clientvault.numera`
- Deployment target is iOS 17.0+
- The scheme `Numera` is marked as **Shared** (Product → Scheme → Manage Schemes → tick Shared)

### 3. Connect Xcode Cloud

In Xcode:
1. Product → Xcode Cloud → **Create Workflow**
2. Sign in with your Apple ID if prompted
3. Select the `Numera` product
4. Xcode will link the GitHub repo automatically (you'll need to authorise GitHub OAuth once)

### 4. Configure the workflow in App Store Connect

After the initial connection, manage workflows at:
**App Store Connect → Xcode Cloud → Numera → Manage Workflows**

#### Workflow: CI (runs on every PR)

| Setting | Value |
|---|---|
| Name | CI |
| Start condition | Pull Request changes — target branch: `main` |
| Environment | Xcode: latest release, macOS: latest release |
| Actions | **Test** — scheme: `Numera`, destination: any iOS simulator |
| Post-actions | None |

#### Workflow: Deploy to TestFlight (runs on merge to main)

| Setting | Value |
|---|---|
| Name | Deploy |
| Start condition | Branch changes — branch: `main` |
| Environment | Xcode: latest release, macOS: latest release |
| Actions 1 | **Test** — scheme: `Numera`, destination: any iOS simulator |
| Actions 2 | **Archive** — scheme: `Numera`, distribution: App Store, signing: Automatic |
| Post-actions | **TestFlight (Internal Testing)** — add yourself as tester |

Xcode Cloud manages provisioning profiles and certificates entirely —
no manual cert management required.

---

## ci_scripts explained

Xcode Cloud runs scripts from the `ci_scripts/` folder at fixed points.
All three scripts are in this repo:

| Script | When it runs |
|---|---|
| `ci_post_clone.sh` | Once per build, after repo clone. Good for tool installs. |
| `ci_pre_xcodebuild.sh` | Before each xcodebuild call. Sets `CFBundleVersion` to `$CI_BUILD_NUMBER`. |
| `ci_post_xcodebuild.sh` | After each xcodebuild call. Logs result paths. |

Scripts must be executable (`chmod +x`) — already set via `git update-index`.

### Useful Xcode Cloud environment variables

| Variable | Description |
|---|---|
| `CI_BUILD_NUMBER` | Monotonically incrementing integer per workflow run |
| `CI_COMMIT` | Current commit SHA |
| `CI_BRANCH` | Branch name |
| `CI_WORKFLOW` | Name of the running workflow |
| `CI_XCODEBUILD_ACTION` | `test`, `archive`, or `build` |
| `CI_ARCHIVE_PATH` | Path to the .xcarchive (archive runs only) |
| `CI_RESULT_BUNDLE_PATH` | Path to test result bundle (test runs only) |
| `CI_PRIMARY_REPOSITORY_PATH` | Root of the cloned repo |

---

## Build numbers

`ci_pre_xcodebuild.sh` sets `CFBundleVersion` to `$CI_BUILD_NUMBER` before
every archive. Xcode Cloud increments this automatically — you never touch it
manually.

`CFBundleShortVersionString` (the marketing version shown in the App Store,
e.g. `1.0.0`) stays in the Xcode project and is changed manually when you
are ready to release a new version.

---

## Promoting a TestFlight build to the App Store

Xcode Cloud does not auto-submit to App Store review. To ship:

1. Go to App Store Connect → TestFlight → find the build
2. Test it on your device
3. App Store Connect → App Store → select the build → **Submit for Review**

---

## Adding environment variables / secrets

If you later need API keys or feature flags in the build (e.g. a RevenueCat
key), add them in:

**App Store Connect → Xcode Cloud → Numera → Manage Workflows → Environment**
→ **Environment Variables**

They are injected as shell environment variables and available in `ci_scripts/`.
They are never stored in the repo.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `ci_scripts` not running | Scripts must have execute permission — already set with `git update-index --chmod=+x` |
| Build number not updating | Check that `ci_pre_xcodebuild.sh` can find `Info.plist` — path may differ once `.xcodeproj` exists |
| Scheme not found | Open Xcode → Product → Scheme → Manage Schemes → ensure `Numera` is ticked as Shared |
| GitHub not connecting | Re-authorise under App Store Connect → Xcode Cloud → Settings → Source Control Providers |
| Signing failure | Xcode Cloud uses automatic signing — ensure the bundle ID is registered in the Developer Portal |
