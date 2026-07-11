# App Store Submission Review

Date: 2026-07-05

This is a working checklist for preparing Numera for App Store submission. The app is already in TestFlight, but the items below should be addressed before submitting for public App Review.

## Distribution audit — 2026-07-12

Seven potential blockers were found. Status below (✅ = fixed in the app repo,
⏳ = needs your action in App Store Connect / the ClientVault-Web legal pages).

1. **✅ Missing privacy manifest.** Added `Numera/Resources/PrivacyInfo.xcprivacy`
   declaring `NSPrivacyAccessedAPICategoryUserDefaults` with approved reason
   **`CA92.1`** (AppSettings persists only the app's own preferences), plus
   `NSPrivacyTracking = false` and empty tracking domains. No other required-reason
   APIs are used directly by the app (verified: no file-timestamp / disk-space /
   system-boot-time / `mach_absolute_time` calls). Third-party SDKs (Supabase) ship
   their own manifests.
2. **✅ Account deletion vs. subscriptions.** The "Delete account?" dialog now warns
   that deletion does **not** cancel an Apple subscription, and shows a **Manage
   subscription** button (for Pro users) that opens the system manage-subscriptions
   sheet before deleting. (`SettingsView.swift`)
3. **✅ Hard-coded fallback paywall prices.** Removed the `$2.99 / $24.99 / $59.99`
   fallbacks. Prices now come from StoreKit only; a `—` placeholder shows until
   products load (the CTA is already disabled in that state). (`PaywallView.swift`,
   `PremiumBadge`/spec)
4. **⏳ Reviewer access.** Create a stable demo account (email + password), seed it
   with realistic data, ensure email confirmation doesn't block reviewer login, and
   fill the App Review notes (template in "Reviewer Access" below). Numera repo can't
   do this — it's App Store Connect + a seeded Supabase user.
5. **⏳ EULA clauses.** Either switch App Store Connect to Apple's **Standard EULA**,
   or add these clauses to the Terms page (ClientVault-Web, `clientvault.org/numera/terms`):
   the agreement is between **you and the user, not Apple**; **Apple is a third-party
   beneficiary** entitled to enforce it; **you (not Apple) provide all support and
   maintenance**; **you (not Apple) are responsible for product warranties and any
   product/IP/legal claims**; and a **developer contact address**. Using Apple's
   Standard EULA is the lowest-effort path.
6. **⏳ Contact-email inconsistency.** The **app doesn't hard-code a support email**
   (it links to `clientvault.org/numera/support`), so there's nothing to change in
   Swift. Three addresses exist across the project: legal pages use
   `saleem.y.work@hotmail.com`, App Store Connect/support uses `support@clientvault.org`,
   and `fastlane/Fastfile` sets `beta_app_feedback_email: saleempay@hotmail.com`
   (TestFlight only). Pick **one canonical support address** (recommend
   `support@clientvault.org`) and use it in the legal pages, App Store Connect, and
   optionally the Fastfile.
7. **⏳ Canonical URL form.** The app already uses **non-www** `clientvault.org/numera/*`
   consistently (`AppInfo.swift`, `PaywallView.swift`, `SettingsView.swift`). Make the
   site redirect `www` → non-www (or vice-versa) and use the same form in App Store
   Connect so links never bounce between forms.

## Likely Blockers

### 1. In-app account deletion is missing

Numera supports account creation through email/password and Sign in with Apple, but Settings currently exposes only:

- Sign out
- Erase data

`Erase data` deletes financial rows and restores defaults, but it does not delete the user auth account. Apple generally expects apps that allow account creation to also provide account deletion inside the app.

Relevant files:

- `Numera/Features/Settings/SettingsView.swift`
- `Numera/Services/AuthManager.swift`
- `Numera/Services/DataStore+CSV.swift`

Recommended fix:

- Add a destructive `Delete account` action in Settings.
- Confirm the user clearly before deletion.
- Delete user-owned Supabase rows.
- Delete the Supabase auth user through a secure server-side function or admin endpoint.
- Sign the user out and reset local state.

Notes:

- A Supabase anon client usually should not directly delete auth users.
- This likely needs a Supabase Edge Function or backend endpoint using service-role privileges.

### 2. Privacy policy is not ready

The paywall currently contains this TODO and links Privacy Policy to the GitHub repo:

- `Numera/Features/Premium/PaywallView.swift`

Current issue:

- `privacyURL` points to `https://github.com/Arikatakur/Numera`
- The code comment says to replace it before App Store review.

Recommended fix:

- Publish a real privacy policy page.
- Replace the GitHub URL in the app.
- Add Privacy Policy and Support links in Settings, not only inside the paywall.
- Add the same Privacy Policy URL in App Store Connect.

The policy should cover:

- Account email / identifier
- User-entered financial data
- Subscription / purchase state
- Local notification preferences
- CSV import/export behavior
- Data deletion process
- Third-party services, especially Supabase and Apple StoreKit

### 3. Premium paywall advertises a "coming soon" paid feature

The paywall and Settings mention `Recurring transactions` as a Pro feature, but it is marked as soon / coming soon.

Relevant files:

- `Numera/Features/Premium/PaywallView.swift`
- `Numera/Features/Settings/SettingsView.swift`

Risk:

- Apple may consider this incomplete or misleading if a paid subscription advertises a feature that is not actually available in the submitted build.

Recommended fix:

- Ship recurring transactions before submission, or
- Remove it from Pro marketing until it is live, or
- Reword clearly so it is not part of the current paid entitlement.

## Fix Before Submit

- [ ] Add in-app account deletion.
- [ ] Publish a real privacy policy.
- [ ] Replace the paywall privacy link.
- [ ] Add Privacy Policy and Support links to Settings.
- [ ] Remove or reword the `Recurring transactions` paid feature until it is actually available.
- [ ] Confirm App Store Connect privacy labels match the app's behavior.
- [ ] Confirm App Store Connect IAP products match the product IDs in code.
- [ ] Confirm Sign in with Apple capability/entitlements are enabled for `org.clientvault.numera`.
- [ ] Confirm backend services are live and accessible during review.
- [ ] Provide App Review with either a demo account or clear test instructions.

## App Store Privacy Labels

Based on the current code, expected disclosures likely include:

- Email address / user identifier
- User-entered financial data
- Purchase / subscription status
- Diagnostics only if collected outside the code seen here

No obvious tracking, ads, location, contacts, camera, microphone, HealthKit, or analytics SDK usage was found in the repo during this static review.

## In-App Purchases

StoreKit product IDs in code:

- `org.clientvault.numera.pro.monthly.v2`
- `org.clientvault.numera.pro.yearly.v2`
- `org.clientvault.numera.pro.lifetime`

Relevant files:

- `Numera/Services/PremiumManager.swift`
- `Numera/Features/Premium/PaywallView.swift`
- `Numera/Resources/Numera.storekit`

Checklist:

- [ ] Monthly product exists in App Store Connect.
- [ ] Yearly product exists in App Store Connect.
- [ ] Lifetime non-consumable product exists in App Store Connect.
- [ ] Prices and localizations are final.
- [ ] Subscription group is configured.
- [ ] Introductory offer matches the app copy.
- [ ] Products are submitted with the app if this is the first public release.
- [ ] Restore purchases works in TestFlight.
- [ ] Manage subscriptions opens correctly for subscribed users.

## Build And Metadata

Things that looked good in static review:

- App icon includes a 1024 universal asset.
- `ITSAppUsesNonExemptEncryption` is set to `false`.
- Fastlane has a TestFlight upload lane.
- StoreKit 2 purchase, restore, entitlement refresh, and subscription management support are present.
- Supabase RLS migrations appear scoped to each user's own rows.

Things to verify in App Store Connect / Xcode:

- [ ] Bundle ID is `org.clientvault.numera`.
- [ ] App name, subtitle, description, keywords, category, and age rating are final.
- [ ] Screenshots match the current production UI.
- [ ] Support URL is live.
- [ ] Marketing URL is either live or omitted.
- [ ] Privacy Policy URL is live.
- [ ] Copyright and contact information are accurate.
- [ ] Export compliance is answered consistently with the plist value.
- [ ] App Review notes explain login, test account, subscriptions, and any non-obvious behavior.

## Reviewer Access

Apple asks account-based apps to provide full review access.

Before submission:

- [ ] Create a demo account with stable credentials.
- [ ] Seed the demo account with realistic sample data.
- [ ] Make sure email confirmation does not block reviewer login.
- [ ] Confirm Supabase is live and not rate-limiting reviewer actions.
- [ ] Include review notes for testing purchases and premium areas.

Suggested App Review note:

```text
Numera is a personal finance tracker with optional Numera Pro purchases.

Demo account:
Email: [demo email]
Password: [demo password]

The reviewer can test adding transactions, budgets, categories, accounts, CSV import/export, reminders, and the Pro paywall. In-app purchases use StoreKit products configured in App Store Connect.
```

## Submission References

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App Store Connect submission help: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/overview-of-submitting-for-review
- App privacy details: https://developer.apple.com/help/app-store-connect/reference/app-privacy-details/

## Verification Limits

This review was static source inspection from a Windows workspace. It did not include:

- A local Xcode archive
- On-device UI testing
- TestFlight runtime testing
- App Store Connect configuration inspection
- Supabase production dashboard inspection

