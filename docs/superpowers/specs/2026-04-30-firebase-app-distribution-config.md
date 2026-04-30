# Firebase App Distribution — CI Configuration

**Date:** 2026-04-30
**Scope:** CI/CD only. No Dart, Kotlin, or Swift code changes.
**Goal:** Make the already-laid-out Firebase App Distribution path in `staging.yml` actually succeed by injecting iOS Firebase config at build time, mirroring the Android pattern.

## Context

The Flutter app at `ui/` already has:

- A Firebase project (`stawi-chat`, project number `571227893327`).
- An Android Firebase app registered for package `org.stawi.chat`, with `google-services.json` injected into `ui/android/app/` from the `GOOGLE_SERVICES_JSON` GitHub secret in `ui/.github/workflows/build.yml`.
- `firebase_core` and `firebase_messaging` Flutter plugins.
- A staging deploy chain in `ui/.github/workflows/staging.yml` that uploads APK and IPA artifacts to Firebase App Distribution via `wzieba/Firebase-Distribution-Github-Action@v1`, expecting GitHub secrets `FIREBASE_APP_ID_ANDROID`, `FIREBASE_APP_ID_IOS`, and `FIREBASE_SERVICE_ACCOUNT`, plus a `internal-testers` tester group.

Two gaps prevent iOS deploy from succeeding today:

1. The iOS Firebase app does not exist yet in the `stawi-chat` project, so there is no `FIREBASE_APP_ID_IOS` and no `GoogleService-Info.plist`.
2. `ui/.github/workflows/build.yml` does not inject `GoogleService-Info.plist` into the iOS build. iOS Xcode projects are regenerated each CI run via `flutter create --platforms=ios .`, so any plist placed at `ios/Runner/GoogleService-Info.plist` must also be added to the Runner target's "Copy Bundle Resources" build phase to ship inside the IPA.

The user has already created the `IOS_GOOGLE_SERVICES_PLIST` GitHub secret containing the base64-encoded plist, leaving only the CI wiring to be done in this codebase.

## Design

### Change 1 — `ui/.github/workflows/build.yml`

Declare a new optional secret `IOS_GOOGLE_SERVICES_PLIST` alongside the existing `GOOGLE_SERVICES_JSON`.

In the `build-ios` job, after the existing **Setup iOS project** step (which regenerates `ios/Runner.xcodeproj` if missing) and before **Install CocoaPods**, add a step **Setup iOS Firebase config** that:

1. Decodes `IOS_GOOGLE_SERVICES_PLIST` to `ios/Runner/GoogleService-Info.plist` when the secret is set; skips otherwise.
2. Uses the `xcodeproj` Ruby gem (preinstalled on `macos-latest` runners) to add `GoogleService-Info.plist` to the Runner target's resources build phase. The script is idempotent — if the file is already in resources, it does nothing.

The step is conditional on `env.IOS_GOOGLE_SERVICES_PLIST != ''` so builds without Firebase configured continue to work.

### Change 2 — `ui/.github/workflows/staging.yml`

In the `build:` job's `secrets:` block, pass `IOS_GOOGLE_SERVICES_PLIST: ${{ secrets.IOS_GOOGLE_SERVICES_PLIST }}` through to the reusable build workflow.

### Change 3 — `ui/.github/workflows/production.yml`

Same passthrough as staging, so production IPAs also bundle the iOS Firebase config (FCM in production builds requires the plist).

## Out of Scope (User-Owned Setup)

These items are tracked separately and must be completed for the chain to actually succeed at runtime:

- Register the iOS app for bundle `org.stawi.chat` in the `stawi-chat` Firebase project; capture `FIREBASE_APP_ID_IOS`.
- Create the App Distribution service account, grant role `roles/firebaseappdistro.admin`, generate a JSON key.
- Set the GitHub Actions secrets `FIREBASE_APP_ID_ANDROID`, `FIREBASE_APP_ID_IOS`, `FIREBASE_SERVICE_ACCOUNT` (and confirm `IOS_GOOGLE_SERVICES_PLIST` scope is `staging` + `production` environments or repository-wide).
- Create the `internal-testers` tester group in Firebase App Distribution and add tester emails.

## Verification

- `gh secret list --env staging` shows the four Firebase secrets.
- A manual `workflow_dispatch` of `Deploy to Staging` produces `Build` artifacts for both `android-apk-staging` and `ios-ipa-staging`, and the `Deploy iOS` / `Deploy Android` jobs complete with `success`.
- A new release shows up under Firebase Console → App Distribution for both apps, visible to members of `internal-testers`.

## Non-Goals

- Migrating `Firebase.initializeApp()` to use a generated `firebase_options.dart` (FlutterFire CLI). The existing bundled-config approach is consistent across Android and iOS and matches the staged secret design.
- Changing the production deploy targets (Play Store, TestFlight remain primary; Firebase App Distribution is staging-only per existing CI design).
